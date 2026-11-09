import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';

/// Represents an incoming or outgoing signaling message for WebRTC negotiation
/// or direct warp file transfer invitations.
class SignalPayload {
  const SignalPayload({
    required this.fromUserId,
    required this.fromDisplayName,
    required this.fromAvatarId,
    required this.event,
    required this.data,
    required this.timestamp,
  });

  /// The sending node's user ID.
  final String fromUserId;

  /// The sending node's profile name.
  final String fromDisplayName;

  /// The sending node's avatar ID.
  final String fromAvatarId;

  /// The event type (e.g. `webrtc_offer`, `webrtc_answer`, `ice_candidate`, `transfer_invitation`).
  final String event;

  /// The payload data (SDP, ICE candidate details, or transfer manifest header).
  final Map<String, dynamic> data;

  /// Creation timestamp.
  final DateTime timestamp;

  factory SignalPayload.fromJson(Map<String, dynamic> json, {String? eventName}) {
    return SignalPayload(
      fromUserId: json['from_user_id'] as String? ?? '',
      fromDisplayName: json['from_display_name'] as String? ?? 'Anonymous Node',
      fromAvatarId: json['from_avatar_id'] as String? ?? 'starter_cyber_01',
      event: eventName ?? json['event'] as String? ?? 'generic_signal',
      data: (json['data'] as Map<String, dynamic>?) ??
          (json['payload'] as Map<String, dynamic>?) ??
          <String, dynamic>{},
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'from_user_id': fromUserId,
      'from_display_name': fromDisplayName,
      'from_avatar_id': fromAvatarId,
      'event': event,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Represents a peer previously engaged in P2P transfers with the current user,
/// including their Co-Op Warp Streak and live online presence.
class RecentPeer {
  const RecentPeer({
    required this.profile,
    required this.streakCount,
    required this.lastTransferAt,
    required this.totalSharedBytes,
    required this.isOnline,
  });

  /// The peer's full profile information.
  final UserProfile profile;

  /// Consecutive active warp days (`🔥 X Days`).
  final int streakCount;

  /// Timestamp of the latest transfer between these peers.
  final DateTime lastTransferAt;

  /// Cumulative bytes beamed between the pair.
  final int totalSharedBytes;

  /// Real-time live presence status.
  final bool isOnline;

  /// Formatted Co-Op Warp Streak string (e.g. `🔥 7 Days`).
  String get streakDisplay => '🔥 $streakCount Day${streakCount == 1 ? '' : 's'}';

  /// Human-readable total shared volume.
  String get formattedSharedVolume {
    if (totalSharedBytes < 1024) return '$totalSharedBytes B';
    if (totalSharedBytes < 1024 * 1024) {
      return '${(totalSharedBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (totalSharedBytes < 1024 * 1024 * 1024) {
      return '${(totalSharedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSharedBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Real-time WebRTC signaling and global presence orchestrator for AetherDrop.
class SignalingService extends ChangeNotifier {
  SignalingService._();

  static final SignalingService instance = SignalingService._();

  final StreamController<SignalPayload> _signalStreamController =
      StreamController<SignalPayload>.broadcast();

  final Set<String> _onlineUserIds = <String>{};
  RealtimeChannel? _presenceChannel;
  RealtimeChannel? _userSignalChannel;
  bool _isConnecting = false;

  /// Stream of all incoming signaling messages (offers, answers, ICE candidates, invitations).
  Stream<SignalPayload> get incomingSignals => _signalStreamController.stream;

  /// Unmodifiable set of currently active online user IDs.
  Set<String> get onlineUserIds => Set<String>.unmodifiable(_onlineUserIds);

  /// Checks whether a given [userId] is currently online on the global presence mesh.
  bool isUserOnline(String userId) {
    return _onlineUserIds.contains(userId);
  }

  /// Connects to the global presence mesh (`online-nodes`) and opens the
  /// personal listening channel (`signal:USER_ID`) for the authenticated user.
  Future<void> connect() async {
    final UserProfile? currentUser = AuthService.instance.currentProfile;
    final SupabaseClient? client = AuthService.instance.supabaseClient;

    if (currentUser == null || client == null || _isConnecting) return;
    _isConnecting = true;

    try {
      // 1. Join global presence channel 'online-nodes'
      await _subscribeToPresenceChannel(client, currentUser);

      // 2. Open listening channel 'signal:USER_ID' for WebRTC signals
      _subscribeToPersonalSignalChannel(client, currentUser.id);
    } catch (e) {
      debugPrint('Error connecting SignalingService: $e');
    } finally {
      _isConnecting = false;
    }
  }

  /// Disconnects from presence and personal signaling channels.
  Future<void> disconnect() async {
    try {
      if (_presenceChannel != null) {
        await _presenceChannel!.untrack();
        _presenceChannel!.unsubscribe();
        _presenceChannel = null;
      }
      if (_userSignalChannel != null) {
        _userSignalChannel!.unsubscribe();
        _userSignalChannel = null;
      }
      _onlineUserIds.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error disconnecting SignalingService: $e');
    }
  }

  /// Searches users in `public.profiles` by email or display name using `ilike`.
  Future<List<UserProfile>> searchUsersByEmailOrName(String query) async {
    final String cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return <UserProfile>[];

    final SupabaseClient? client = AuthService.instance.supabaseClient;
    final String currentUserId = AuthService.instance.currentProfile?.id ?? '';

    if (client == null) {
      return <UserProfile>[];
    }

    try {
      // Sanitize query to prevent pattern injection
      final String safePattern = cleanQuery.replaceAll('%', '').replaceAll('*', '');
      if (safePattern.isEmpty) return <UserProfile>[];

      final List<dynamic> rows = await client
          .from('profiles')
          .select()
          .or('email.ilike.%$safePattern%,display_name.ilike.%$safePattern%')
          .limit(25);

      final List<UserProfile> results = <UserProfile>[];
      for (final dynamic row in rows) {
        if (row is Map<String, dynamic>) {
          final UserProfile profile = UserProfile.fromJson(row);
          // Omit current user from search results
          if (profile.id != currentUserId) {
            // Overlay real-time presence mesh accuracy
            final bool liveOnline = isUserOnline(profile.id) || profile.isOnline;
            results.add(profile.copyWith(isOnline: liveOnline));
          }
        }
      }
      return results;
    } catch (e) {
      debugPrint('Error searching users: $e');
      return <UserProfile>[];
    }
  }

  /// Retrieves recent peers from `public.peer_connections` joined with `public.profiles`.
  ///
  /// Includes Co-Op Warp Streak count (`🔥 X Days`) and real-time presence indicators.
  Future<List<RecentPeer>> getRecentPeers() async {
    final SupabaseClient? client = AuthService.instance.supabaseClient;
    final String currentUserId = AuthService.instance.currentProfile?.id ?? '';

    if (client == null || currentUserId.isEmpty) {
      return <RecentPeer>[];
    }

    try {
      // 1. Fetch peer connections involving current user
      final List<dynamic> connectionRows = await client
          .from('peer_connections')
          .select()
          .or('user_a.eq.$currentUserId,user_b.eq.$currentUserId')
          .order('last_transfer_at', ascending: false)
          .limit(20);

      if (connectionRows.isEmpty) return <RecentPeer>[];

      // 2. Collect unique peer IDs
      final Set<String> peerIds = <String>{};
      for (final dynamic row in connectionRows) {
        if (row is Map<String, dynamic>) {
          final String userA = row['user_a'] as String? ?? '';
          final String userB = row['user_b'] as String? ?? '';
          final String peerId = (userA == currentUserId) ? userB : userA;
          if (peerId.isNotEmpty) {
            peerIds.add(peerId);
          }
        }
      }

      if (peerIds.isEmpty) return <RecentPeer>[];

      // 3. Batch fetch peer profiles
      final List<dynamic> profileRows = await client
          .from('profiles')
          .select()
          .filter('id', 'in', '(${peerIds.join(',')})');

      final Map<String, UserProfile> profileMap = <String, UserProfile>{};
      for (final dynamic p in profileRows) {
        if (p is Map<String, dynamic>) {
          final UserProfile profile = UserProfile.fromJson(p);
          profileMap[profile.id] = profile;
        }
      }

      // 4. Construct RecentPeer models
      final List<RecentPeer> recentPeers = <RecentPeer>[];
      for (final dynamic row in connectionRows) {
        if (row is Map<String, dynamic>) {
          final String userA = row['user_a'] as String? ?? '';
          final String userB = row['user_b'] as String? ?? '';
          final String peerId = (userA == currentUserId) ? userB : userA;
          final UserProfile? peerProfile = profileMap[peerId];

          if (peerProfile != null) {
            final int streak = (row['streak_count'] as num?)?.toInt() ?? 1;
            final int sharedBytes =
                (row['total_shared_bytes'] as num?)?.toInt() ?? 0;
            final DateTime lastTransfer = row['last_transfer_at'] != null
                ? DateTime.tryParse(row['last_transfer_at'].toString()) ??
                    DateTime.now()
                : DateTime.now();

            final bool liveOnline = isUserOnline(peerId) || peerProfile.isOnline;

            recentPeers.add(
              RecentPeer(
                profile: peerProfile.copyWith(isOnline: liveOnline),
                streakCount: streak,
                lastTransferAt: lastTransfer,
                totalSharedBytes: sharedBytes,
                isOnline: liveOnline,
              ),
            );
          }
        }
      }

      return recentPeers;
    } catch (e) {
      debugPrint('Error fetching recent peers: $e');
      return <RecentPeer>[];
    }
  }

  /// Sends a WebRTC signal or transfer invitation to [targetUserId] on channel `signal:TARGET_ID`.
  Future<void> sendSignal({
    required String targetUserId,
    required String event,
    required Map<String, dynamic> payload,
  }) async {
    final SupabaseClient? client = AuthService.instance.supabaseClient;
    final UserProfile? currentUser = AuthService.instance.currentProfile;

    if (client == null || currentUser == null || targetUserId.isEmpty) {
      throw StateError('Cannot send signal: client or user uninitialized');
    }

    try {
      final String channelName = '${AppConstants.signalChannelPrefix}$targetUserId';
      final RealtimeChannel targetChannel = client.channel(channelName);

      final Map<String, dynamic> messagePayload = <String, dynamic>{
        'from_user_id': currentUser.id,
        'from_display_name': currentUser.displayName,
        'from_avatar_id': currentUser.avatarId,
        'event': event,
        'data': payload,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await targetChannel.sendBroadcastMessage(
        event: event,
        payload: messagePayload,
      );
    } catch (e) {
      debugPrint('Error sending signal to $targetUserId ($event): $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Channel Subscriptions
  // ---------------------------------------------------------------------------

  Future<void> _subscribeToPresenceChannel(
    SupabaseClient client,
    UserProfile currentUser,
  ) async {
    if (_presenceChannel != null) {
      _presenceChannel!.unsubscribe();
    }

    _presenceChannel = client.channel(
      AppConstants.presenceChannelName,
      opts: const RealtimeChannelConfig(key: ''),
    );

    _presenceChannel!.onPresenceSync((RealtimePresenceSyncPayload _) {
      _recalculatePresence();
    });

    _presenceChannel!.onPresenceJoin((RealtimePresenceJoinPayload payload) {
      _recalculatePresence();
    });

    _presenceChannel!.onPresenceLeave((RealtimePresenceLeavePayload payload) {
      _recalculatePresence();
    });

    _presenceChannel!.subscribe();

    // Broadcast our presence on the global mesh
    await _presenceChannel!.track(<String, dynamic>{
      'user_id': currentUser.id,
      'email': currentUser.email,
      'display_name': currentUser.displayName,
      'avatar_id': currentUser.avatarId,
      'online_at': DateTime.now().toIso8601String(),
    });
  }

  void _subscribeToPersonalSignalChannel(
    SupabaseClient client,
    String userId,
  ) {
    if (_userSignalChannel != null) {
      _userSignalChannel!.unsubscribe();
    }

    final String channelName = '${AppConstants.signalChannelPrefix}$userId';
    _userSignalChannel = client.channel(channelName);

    // Register broadcast event handlers for WebRTC negotiation & invitations
    const List<String> signalEvents = <String>[
      'webrtc_offer',
      'webrtc_answer',
      'ice_candidate',
      'transfer_invitation',
      'warp_reaction',
    ];

    for (final String event in signalEvents) {
      _userSignalChannel!.onBroadcast(
        event: event,
        callback: (Map<String, dynamic> payload) {
          final SignalPayload signal = SignalPayload.fromJson(
            payload,
            eventName: event,
          );
          _signalStreamController.add(signal);
        },
      );
    }

    _userSignalChannel!.subscribe();
  }

  void _recalculatePresence() {
    if (_presenceChannel == null) return;

    final List<SinglePresenceState> states = _presenceChannel!.presenceState();
    final Set<String> updated = <String>{};

    for (final SinglePresenceState clientState in states) {
      for (final Presence presence in clientState.presences) {
        final dynamic uid = presence.payload['user_id'];
        if (uid is String && uid.isNotEmpty) {
          updated.add(uid);
        }
      }
    }

    _onlineUserIds.clear();
    _onlineUserIds.addAll(updated);
    notifyListeners();
  }

  @override
  void dispose() {
    _signalStreamController.close();
    disconnect();
    super.dispose();
  }
}
