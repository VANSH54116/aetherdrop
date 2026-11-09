import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../models/user_profile.dart';

/// Central authentication and session lifecycle service for AetherDrop.
///
/// Implements deterministic frictionless authentication so the user enters their
/// email, display name, and avatar once and is permanently signed in.
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String _cachedProfileKey = 'aetherdrop_cached_user_profile';
  static const String _deterministicSalt =
      'aetherdrop_warp_secret_2026_entropy_key_v1_deterministic';

  UserProfile? _currentProfile;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _lastError;

  /// The currently authenticated user's profile, if any.
  UserProfile? get currentProfile => _currentProfile;

  /// Whether a user is currently signed in and has a profile loaded.
  bool get isAuthenticated => _currentProfile != null;

  /// Whether an authentication or onboarding network operation is in flight.
  bool get isLoading => _isLoading;

  /// Last error message encountered during auth operations, if any.
  String? get lastError => _lastError;

  /// Direct handle to the underlying [SupabaseClient] if initialized.
  SupabaseClient? get supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Initializes the Supabase client (if not already done) and checks for
  /// an existing authenticated session or locally cached profile.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _lastError = null;

    try {
      // 1. Initialize Supabase if needed
      await _ensureSupabaseInitialized();

      // 2. Load locally cached profile for instantaneous startup rendering
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString(_cachedProfileKey);
      if (cachedJson != null) {
        try {
          final Map<String, dynamic> decoded =
              jsonDecode(cachedJson) as Map<String, dynamic>;
          _currentProfile = UserProfile.fromJson(decoded);
          notifyListeners();
        } catch (e) {
          debugPrint('Failed to decode cached user profile: $e');
        }
      }

      // 3. Inspect active Supabase session
      final SupabaseClient? client = supabaseClient;
      if (client != null) {
        final Session? session = client.auth.currentSession;
        if (session != null) {
          final User user = session.user;
          await _fetchAndCacheRemoteProfile(user.id);
        }

        // Listen for remote auth state transitions
        client.auth.onAuthStateChange.listen((AuthState state) async {
          final AuthChangeEvent event = state.event;
          if (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.tokenRefreshed) {
            final User? user = state.session?.user;
            if (user != null) {
              await _fetchAndCacheRemoteProfile(user.id);
            }
          } else if (event == AuthChangeEvent.signedOut) {
            _currentProfile = null;
            await _clearCachedProfile();
            notifyListeners();
          }
        });
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('AuthService initialization error: $e');
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  /// Completes first-time frictionless onboarding.
  ///
  /// Uses a deterministic client secret derived from the normalized email so
  /// the user enters only their [email], [displayName], and [avatarId] once
  /// and is seamlessly authenticated permanently.
  Future<UserProfile> completeFirstTimeOnboarding({
    required String email,
    required String displayName,
    required String avatarId,
  }) async {
    _setLoading(true);
    _lastError = null;

    final String normalizedEmail = email.trim().toLowerCase();
    final String trimmedName = displayName.trim().isEmpty
        ? normalizedEmail.split('@').first
        : displayName.trim();

    try {
      await _ensureSupabaseInitialized();
      final SupabaseClient? client = supabaseClient;

      if (client == null) {
        // Fallback demo/offline profile when remote backend is unconfigured
        final UserProfile offlineProfile = UserProfile(
          id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
          email: normalizedEmail,
          displayName: trimmedName,
          avatarId: avatarId,
          lastSeen: DateTime.now(),
        );
        await _saveProfileLocally(offlineProfile);
        _currentProfile = offlineProfile;
        notifyListeners();
        return offlineProfile;
      }

      final String deterministicPassword = _deriveSecretForEmail(normalizedEmail);

      User? authUser;
      try {
        // Step 1: Attempt password sign-in for returning users
        final AuthResponse signInRes = await client.auth.signInWithPassword(
          email: normalizedEmail,
          password: deterministicPassword,
        );
        authUser = signInRes.user;
      } on AuthException catch (e) {
        debugPrint('Sign in attempt note: ${e.message}, falling back to signUp');
      }

      // Step 2: If user not registered yet, sign up deterministically
      if (authUser == null) {
        try {
          final AuthResponse signUpRes = await client.auth.signUp(
            email: normalizedEmail,
            password: deterministicPassword,
            data: <String, dynamic>{
              'display_name': trimmedName,
              'avatar_id': avatarId,
            },
          );
          authUser = signUpRes.user;
        } catch (signUpError) {
          debugPrint('Sign up attempt note: $signUpError');
        }
      }

      final String userId = authUser?.id ??
          client.auth.currentUser?.id ??
          'node_${normalizedEmail.hashCode.abs()}';

      // Step 3: Upsert row into public.profiles and set is_online = true
      final Map<String, dynamic> profilePayload = <String, dynamic>{
        'id': userId,
        'email': normalizedEmail,
        'display_name': trimmedName,
        'avatar_id': avatarId,
        'frame_id': 'frame_slate_01',
        'is_online': true,
        'last_seen': DateTime.now().toIso8601String(),
      };

      try {
        await client.from('profiles').upsert(
              profilePayload,
              onConflict: 'id',
            );
      } catch (upsertError) {
        debugPrint('Note during profile upsert: $upsertError');
      }

      // Step 4: Retrieve and cache full profile
      final UserProfile? profile = await _fetchAndCacheRemoteProfile(userId);
      if (profile != null) {
        _currentProfile = profile;
        notifyListeners();
        return profile;
      }

      // Safe fallback profile if remote read was blocked
      final UserProfile fallback = UserProfile(
        id: userId,
        email: normalizedEmail,
        displayName: trimmedName,
        avatarId: avatarId,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
      await _saveProfileLocally(fallback);
      _currentProfile = fallback;
      notifyListeners();
      return fallback;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('completeFirstTimeOnboarding error: $e');

      // Resilient fallback node profile so offline/LAN P2P operation is never blocked
      final UserProfile fallback = UserProfile(
        id: 'node_${normalizedEmail.hashCode.abs()}',
        email: normalizedEmail,
        displayName: trimmedName,
        avatarId: avatarId,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
      await _saveProfileLocally(fallback);
      _currentProfile = fallback;
      notifyListeners();
      return fallback;
    } finally {
      _setLoading(false);
    }
  }

  /// Updates the user's online presence status flag in Supabase and locally.
  Future<void> setOnlineStatus(bool isOnline) async {
    final UserProfile? profile = _currentProfile;
    if (profile == null) return;

    _currentProfile = profile.copyWith(
      isOnline: isOnline,
      lastSeen: DateTime.now(),
    );
    notifyListeners();

    final SupabaseClient? client = supabaseClient;
    if (client != null && profile.id.isNotEmpty && !profile.id.startsWith('offline_')) {
      try {
        await client.from('profiles').update(<String, dynamic>{
          'is_online': isOnline,
          'last_seen': DateTime.now().toIso8601String(),
        }).eq('id', profile.id);
      } catch (e) {
        debugPrint('Error updating is_online: $e');
      }
    }
  }

  /// Updates the user's display name or avatar.
  Future<void> updateProfile({String? displayName, String? avatarId}) async {
    final UserProfile? profile = _currentProfile;
    if (profile == null) return;

    final UserProfile updated = profile.copyWith(
      displayName: displayName ?? profile.displayName,
      avatarId: avatarId ?? profile.avatarId,
      lastSeen: DateTime.now(),
    );

    _currentProfile = updated;
    await _saveProfileLocally(updated);
    notifyListeners();

    final SupabaseClient? client = supabaseClient;
    if (client != null && profile.id.isNotEmpty && !profile.id.startsWith('offline_')) {
      try {
        await client.from('profiles').update(<String, dynamic>{
          if (displayName != null) 'display_name': displayName,
          if (avatarId != null) 'avatar_id': avatarId,
          'last_seen': DateTime.now().toIso8601String(),
        }).eq('id', profile.id);
      } catch (e) {
        debugPrint('Error updating remote profile: $e');
      }
    }
  }

  /// Refreshes the current profile from the remote Supabase database.
  Future<UserProfile?> refreshProfile() async {
    final UserProfile? profile = _currentProfile;
    if (profile == null) return null;
    return _fetchAndCacheRemoteProfile(profile.id);
  }

  /// Signs out the user, updates their online status, and clears local caches.
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await setOnlineStatus(false);
      final SupabaseClient? client = supabaseClient;
      if (client != null) {
        await client.auth.signOut();
      }
    } catch (e) {
      debugPrint('Error during signOut: $e');
    } finally {
      _currentProfile = null;
      await _clearCachedProfile();
      _setLoading(false);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  /// Derives a cryptographically strong deterministic secret from an email.
  ///
  /// Guarantees that the secret satisfies password complexity constraints
  /// (letters, numbers, symbols, length >= 24) without requiring the user
  /// to enter or remember a password.
  String _deriveSecretForEmail(String normalizedEmail) {
    final String raw = '$normalizedEmail:$_deterministicSalt';
    final Digest digest = sha256.convert(utf8.encode(raw));
    final String hex = digest.toString();
    return 'Warp#${hex.substring(0, 24)}!Aa9';
  }

  Future<void> _ensureSupabaseInitialized() async {
    try {
      Supabase.instance.client;
    } catch (_) {
      final String url = AppConstants.supabaseUrl;
      final String anonKey = AppConstants.supabaseAnonKey;
      if (url.isNotEmpty &&
          anonKey.isNotEmpty &&
          !url.contains('YOUR_SUPABASE_URL_HERE')) {
        await Supabase.initialize(
          url: url,
          // ignore: deprecated_member_use
          anonKey: anonKey,
          debug: kDebugMode,
        );
      }
    }
  }

  Future<UserProfile?> _fetchAndCacheRemoteProfile(String userId) async {
    final SupabaseClient? client = supabaseClient;
    if (client == null) return null;

    try {
      final Map<String, dynamic>? data = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        final UserProfile profile = UserProfile.fromJson(data);
        _currentProfile = profile;
        await _saveProfileLocally(profile);
        notifyListeners();
        return profile;
      }
    } catch (e) {
      debugPrint('Error fetching remote profile for $userId: $e');
    }
    return null;
  }

  Future<void> _saveProfileLocally(UserProfile profile) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(profile.toJson());
      await prefs.setString(_cachedProfileKey, encoded);
    } catch (e) {
      debugPrint('Failed to save profile locally: $e');
    }
  }

  Future<void> _clearCachedProfile() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedProfileKey);
    } catch (e) {
      debugPrint('Failed to clear cached profile: $e');
    }
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }
}
