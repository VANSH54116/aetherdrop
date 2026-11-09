import 'package:aetherdrop_app/core/gamification.dart';
import 'package:aetherdrop_app/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('serializes and deserializes matching Supabase public.profiles schema', () {
      final DateTime now = DateTime.now();
      final UserProfile profile = UserProfile(
        id: 'user-uuid-1234',
        email: 'pilot@aetherdrop.net',
        displayName: 'CyberPilot',
        avatarId: 'starter_cyber_02',
        frameId: 'frame_slate_01',
        xp: 1250,
        level: 7,
        totalBytesSent: 104857600,
        totalFilesSent: 15,
        unlockedAvatars: const <String>[
          'starter_cyber_01',
          'starter_cyber_02',
          'starter_cyber_03',
          'starter_cyber_04',
          'cyber_kitsune_05',
        ],
        unlockedBadges: const <String>['badge_first_node'],
        isOnline: true,
        lastSeen: now,
      );

      final Map<String, dynamic> json = profile.toJson();
      expect(json['id'], 'user-uuid-1234');
      expect(json['email'], 'pilot@aetherdrop.net');
      expect(json['display_name'], 'CyberPilot');
      expect(json['avatar_id'], 'starter_cyber_02');
      expect(json['xp'], 1250);
      expect(json['level'], 7);
      expect(json['total_bytes_sent'], 104857600);
      expect(json['total_files_sent'], 15);
      expect(json['is_online'], true);

      final UserProfile deserialized = UserProfile.fromJson(json);
      expect(deserialized.id, profile.id);
      expect(deserialized.email, profile.email);
      expect(deserialized.displayName, profile.displayName);
      expect(deserialized.avatarId, profile.avatarId);
      expect(deserialized.xp, profile.xp);
      expect(deserialized.level, profile.level);
      expect(deserialized.totalBytesSent, profile.totalBytesSent);
      expect(deserialized.formattedBytesSent, '100.0 MB');
      expect(deserialized.hasAvatar('cyber_kitsune_05'), isTrue);
      expect(deserialized.hasAvatar('apex_singularity_50'), isFalse);
    });

    test('copyWith properly overrides fields', () {
      final UserProfile original = UserProfile(
        id: '1',
        email: 'test@test.com',
        displayName: 'Test',
        lastSeen: DateTime.now(),
      );

      final UserProfile copy = original.copyWith(
        displayName: 'Updated Name',
        xp: 500,
        level: 4,
      );

      expect(copy.displayName, 'Updated Name');
      expect(copy.xp, 500);
      expect(copy.level, 4);
      expect(copy.email, 'test@test.com');
    });
  });

  group('Gamification System Tests', () {
    test('contains 12 procedural Cyber Avatars with 4 Starters', () {
      expect(Gamification.allAvatars.length, 12);
      expect(Gamification.starterAvatars.length, 4);

      final List<String> starterIds =
          Gamification.starterAvatars.map((CyberAvatarInfo a) => a.id).toList();
      expect(
        starterIds,
        containsAll(<String>[
          'starter_cyber_01',
          'starter_cyber_02',
          'starter_cyber_03',
          'starter_cyber_04',
        ]),
      );

      final List<String> unlockableIds = Gamification.allAvatars
          .where((CyberAvatarInfo a) => !a.isStarter)
          .map((CyberAvatarInfo a) => a.id)
          .toList();
      expect(
        unlockableIds,
        containsAll(<String>[
          'cyber_kitsune_05',
          'void_droid_08',
          'holo_samurai_10',
          'plasma_valkyrie_15',
          'chrono_phantom_20',
          'astral_phoenix_25',
          'nova_titan_35',
          'apex_singularity_50',
        ]),
      );
    });

    test('getRankTitle scales accurately with user progression levels', () {
      expect(Gamification.getRankTitle(1), 'Spark Node');
      expect(Gamification.getRankTitle(4), 'Spark Node');
      expect(Gamification.getRankTitle(5), 'Pulse Runner');
      expect(Gamification.getRankTitle(8), 'Void Pioneer');
      expect(Gamification.getRankTitle(10), 'Data Architect');
      expect(Gamification.getRankTitle(15), 'Plasma Valkyrie');
      expect(Gamification.getRankTitle(20), 'Chrono Wanderer');
      expect(Gamification.getRankTitle(25), 'Quantum Conduit');
      expect(Gamification.getRankTitle(35), 'Nova Vanguard');
      expect(Gamification.getRankTitle(50), 'Singularity Core');
      expect(Gamification.getRankTitle(99), 'Singularity Core');
    });

    test('getProgressToNextLevel computes accurate fractions and milestones', () {
      // Level 1: 0 to 100 XP (Target: Level 2 = 25 * 2^2 = 100 XP)
      final LevelProgress p0 = Gamification.getProgressToNextLevel(0);
      expect(p0.currentLevel, 1);
      expect(p0.nextLevel, 2);
      expect(p0.progress, 0.0);

      final LevelProgress p50 = Gamification.getProgressToNextLevel(50);
      expect(p50.currentLevel, 1);
      expect(p50.progress, 0.5);
      expect(p50.percentageText, '50%');

      // Level 5: 25 * 5^2 = 625 XP. Level 6 = 25 * 6^2 = 900 XP.
      final LevelProgress p625 = Gamification.getProgressToNextLevel(625);
      expect(p625.currentLevel, 5);
      expect(p625.nextLevel, 6);
      expect(p625.progress, 0.0);
    });

    test('getFrameGradient returns non-null gradient across all tiers', () {
      expect(Gamification.getFrameGradient(1), isNotNull);
      expect(Gamification.getFrameGradient(5), isNotNull);
      expect(Gamification.getFrameGradient(10), isNotNull);
      expect(Gamification.getFrameGradient(25), isNotNull);
      expect(Gamification.getFrameGradient(50), isNotNull);
    });
  });
}

