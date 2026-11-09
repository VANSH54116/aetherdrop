import 'package:aetherdrop_app/models/user_profile.dart';
import 'package:aetherdrop_app/services/auth_service.dart';
import 'package:aetherdrop_app/services/signaling_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  group('AuthService Tests', () {
    test('instance singleton is available and initialized', () {
      final AuthService auth = AuthService.instance;
      expect(auth, isNotNull);
      expect(auth.isLoading, isFalse);
    });

    test('deterministic onboarding generates valid offline/local profile when offline', () async {
      final AuthService auth = AuthService.instance;

      final UserProfile profile = await auth.completeFirstTimeOnboarding(
        email: 'pilot_node@aetherdrop.net',
        displayName: 'QuantumPilot',
        avatarId: 'starter_cyber_03',
      );

      expect(profile.email, 'pilot_node@aetherdrop.net');
      expect(profile.displayName, 'QuantumPilot');
      expect(profile.avatarId, 'starter_cyber_03');
      expect(profile.isOnline, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentProfile?.displayName, 'QuantumPilot');
    });

    test('online status can be toggled', () async {
      final AuthService auth = AuthService.instance;
      await auth.setOnlineStatus(false);
      expect(auth.currentProfile?.isOnline, isFalse);

      await auth.setOnlineStatus(true);
      expect(auth.currentProfile?.isOnline, isTrue);
    });
  });

  group('SignalingService Tests', () {
    test('RecentPeer streak display formats correctly', () {
      final UserProfile peerProfile = UserProfile(
        id: 'peer-1',
        email: 'friend@warp.io',
        displayName: 'WarpFriend',
        lastSeen: DateTime.now(),
      );

      final RecentPeer peer1 = RecentPeer(
        profile: peerProfile,
        streakCount: 1,
        lastTransferAt: DateTime.now(),
        totalSharedBytes: 52428800, // 50 MB
        isOnline: true,
      );

      expect(peer1.streakDisplay, '🔥 1 Day');
      expect(peer1.formattedSharedVolume, '50.0 MB');

      final RecentPeer peer7 = RecentPeer(
        profile: peerProfile,
        streakCount: 7,
        lastTransferAt: DateTime.now(),
        totalSharedBytes: 1073741824 * 3, // 3 GB
        isOnline: true,
      );

      expect(peer7.streakDisplay, '🔥 7 Days');
      expect(peer7.formattedSharedVolume, '3.00 GB');
    });

    test('SignalPayload encodes and decodes accurately', () {
      final DateTime now = DateTime.now();
      final SignalPayload payload = SignalPayload(
        fromUserId: 'sender-123',
        fromDisplayName: 'SenderNode',
        fromAvatarId: 'starter_cyber_01',
        event: 'webrtc_offer',
        data: <String, dynamic>{'sdp': 'v=0...', 'type': 'offer'},
        timestamp: now,
      );

      final Map<String, dynamic> json = payload.toJson();
      expect(json['from_user_id'], 'sender-123');
      expect(json['from_display_name'], 'SenderNode');
      expect(json['event'], 'webrtc_offer');
      expect(json['data']['type'], 'offer');

      final SignalPayload decoded = SignalPayload.fromJson(json);
      expect(decoded.fromUserId, 'sender-123');
      expect(decoded.fromDisplayName, 'SenderNode');
      expect(decoded.event, 'webrtc_offer');
      expect(decoded.data['type'], 'offer');
    });
  });
}
