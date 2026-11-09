import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/gamification.dart';
import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../widgets/avatar_badge.dart';
import '../widgets/glass_card.dart';

/// The Cyber Avatar & Rank Vault screen showcasing all 12 procedural Cyber Avatars,
/// lifetime warp stats, and milestone progression badges.
class VaultAvatarsScreen extends StatefulWidget {
  const VaultAvatarsScreen({super.key});

  @override
  State<VaultAvatarsScreen> createState() => _VaultAvatarsScreenState();
}

class _VaultAvatarsScreenState extends State<VaultAvatarsScreen> {
  double _maxSpeedMBps = 0.0;
  int _maxStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadLifetimeStats();
  }

  Future<void> _loadLifetimeStats() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final double speed = prefs.getDouble('aetherdrop_max_speed_mbps') ?? 68.4;
      final int streak = prefs.getInt('aetherdrop_max_streak') ?? 7;
      if (mounted) {
        setState(() {
          _maxSpeedMBps = speed;
          _maxStreak = streak;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _maxSpeedMBps = 68.4;
          _maxStreak = 7;
        });
      }
    }
  }

  Future<void> _equipAvatar(String avatarId) async {
    final UserProfile? profile = AuthService.instance.currentProfile;
    if (profile == null) return;

    await AuthService.instance.updateProfile(avatarId: avatarId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AetherDropColors.elevatedObsidian,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: AetherDropColors.electricCyan,
            width: 1,
          ),
        ),
        content: Row(
          children: <Widget>[
            const Icon(
              LucideIcons.checkCircle2,
              color: AetherDropColors.electricCyan,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Equipped ${Gamification.getAvatarById(avatarId).name}!',
                style: AetherDropTheme.bodyStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (BuildContext context, _) {
        final UserProfile profile = AuthService.instance.currentProfile ??
            UserProfile(
              id: 'temp_node',
              email: 'node@aetherdrop.net',
              displayName: 'Warp Explorer',
              lastSeen: DateTime.now(),
            );

        final LevelProgress progress =
            Gamification.getProgressToNextLevel(profile.xp);
        final String rankTitle = Gamification.getRankTitle(profile.level);

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: <Widget>[
                // Slivers App Bar Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: _buildHeaderCard(context, profile, progress, rankTitle),
                      ),
                    ),
                  ),
                ),

                // Main Content
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            // Lifetime Stats Row
                            _buildLifetimeStatsSection(profile),
                            const SizedBox(height: 28),

                            // All 12 Cyber Avatars Showcase
                            _buildAvatarsSection(profile),
                            const SizedBox(height: 28),

                            // Milestone Badges Showcase
                            _buildMilestoneBadgesSection(profile),
                            const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    UserProfile profile,
    LevelProgress progress,
    String rankTitle,
  ) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: <Widget>[
          // Back button
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            tooltip: 'Return to Radar',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),

          // Active Equipped Avatar
          AvatarBadge(
            avatarId: profile.avatarId,
            level: profile.level,
            size: 60,
            isOnline: true,
            animateRing: true,
          ),
          const SizedBox(width: 18),

          // User details and rank
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        'AVATAR & RANK VAULT',
                        style: AetherDropTheme.titleStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AetherDropColors.electricCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AetherDropColors.electricCyan.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'LVL ${profile.level} — $rankTitle'.toUpperCase(),
                        style: AetherDropTheme.monoStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AetherDropColors.electricCyan,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // WXP Progress Bar to Next Level
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress.progress,
                          minHeight: 7,
                          backgroundColor: const Color(0xFF1E293B),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AetherDropColors.electricCyan,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '${profile.xp} / ${progress.nextLevelXp} WXP (${progress.percentageText})',
                      style: AetherDropTheme.monoStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AetherDropColors.electricCyan,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifetimeStatsSection(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader(
          title: 'LIFETIME WARP METRICS',
          icon: LucideIcons.activity,
          badge: 'SYNCED',
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double cardWidth = constraints.maxWidth > 700
                ? (constraints.maxWidth - 36) / 4
                : (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _buildStatMetricCard(
                  width: cardWidth,
                  icon: LucideIcons.hardDrive,
                  label: 'TOTAL DATA WARPED',
                  value: profile.formattedBytesSent,
                  color: AetherDropColors.electricCyan,
                ),
                _buildStatMetricCard(
                  width: cardWidth,
                  icon: LucideIcons.files,
                  label: 'TOTAL FILES BEAMED',
                  value: '${profile.totalFilesSent}',
                  color: AetherDropColors.hyperCobalt,
                ),
                _buildStatMetricCard(
                  width: cardWidth,
                  icon: LucideIcons.zap,
                  label: 'PEAK WARP SPEED',
                  value: '${_maxSpeedMBps.toStringAsFixed(1)} MB/s',
                  color: AetherDropColors.neonEmerald,
                ),
                _buildStatMetricCard(
                  width: cardWidth,
                  icon: LucideIcons.flame,
                  label: 'LONGEST CO-OP STREAK',
                  value: '🔥 $_maxStreak Days',
                  color: AetherDropColors.liquidGold,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatMetricCard({
    required double width,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111622),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AetherDropTheme.monoStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AetherDropColors.textSecondaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AetherDropTheme.titleStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarsSection(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader(
          title: 'CYBER AVATARS // 12 PROCEDURAL TIERS',
          icon: LucideIcons.userCheck,
          badge: '${profile.unlockedAvatars.length} / 12 UNLOCKED',
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 220,
          ),
          itemCount: Gamification.allAvatars.length,
          itemBuilder: (BuildContext context, int index) {
            final CyberAvatarInfo avatar = Gamification.allAvatars[index];
            final bool isUnlocked = avatar.isUnlockedFor(
              level: profile.level,
              unlockedAvatars: profile.unlockedAvatars,
            );
            final bool isEquipped = avatar.id == profile.avatarId;

            return _buildAvatarCard(
              avatar: avatar,
              isUnlocked: isUnlocked,
              isEquipped: isEquipped,
              currentLevel: profile.level,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAvatarCard({
    required CyberAvatarInfo avatar,
    required bool isUnlocked,
    required bool isEquipped,
    required int currentLevel,
  }) {
    return InkWell(
      onTap: isUnlocked ? () => _equipAvatar(avatar.id) : null,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isEquipped
              ? avatar.primaryColor.withValues(alpha: 0.14)
              : const Color(0xFF111622),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isEquipped
                ? avatar.primaryColor
                : (isUnlocked
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04)),
            width: isEquipped ? 2.0 : 1.0,
          ),
          boxShadow: isEquipped
              ? <BoxShadow>[
                  BoxShadow(
                    color: avatar.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Vector Avatar Emblem
                AvatarBadge(
                  avatarId: avatar.id,
                  level: avatar.requiredLevel,
                  size: 68,
                  showLevelPill: false,
                  animateRing: isEquipped,
                ),
                const SizedBox(height: 10),

                // Name
                Text(
                  avatar.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AetherDropTheme.titleStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isUnlocked
                        ? Colors.white
                        : AetherDropColors.textMutedDark,
                  ),
                ),
                const SizedBox(height: 3),

                // Lore Subtitle
                Text(
                  avatar.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AetherDropTheme.bodyStyle(
                    fontSize: 10,
                    color: AetherDropColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 8),

                // Equip / Status button
                if (isEquipped)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: avatar.primaryColor.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: avatar.primaryColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'ACTIVE EQUIPPED',
                      style: AetherDropTheme.monoStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: avatar.primaryColor,
                      ),
                    ),
                  )
                else if (isUnlocked)
                  Text(
                    'Tap to Equip',
                    style: AetherDropTheme.monoStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AetherDropColors.neonEmerald,
                    ),
                  )
                else
                  Text(
                    'Unlocks at Level ${avatar.requiredLevel}',
                    style: AetherDropTheme.monoStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AetherDropColors.crimsonPulse,
                    ),
                  ),
              ],
            ),

            // Lock Overlay if not unlocked
            if (!isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0D14).withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AetherDropColors.crimsonPulse.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.lock,
                        size: 18,
                        color: AetherDropColors.crimsonPulse,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneBadgesSection(UserProfile profile) {
    final List<_MilestoneBadgeData> badges = <_MilestoneBadgeData>[
      _MilestoneBadgeData(
        id: 'badge_first_warp',
        title: 'First Warp',
        description: 'Completed first direct peer-to-peer data beam.',
        icon: LucideIcons.zap,
        color: AetherDropColors.electricCyan,
        isUnlocked: profile.totalFilesSent > 0 ||
            profile.unlockedBadges.contains('badge_first_warp') ||
            profile.unlockedBadges.contains('badge_first_node'),
      ),
      _MilestoneBadgeData(
        id: 'badge_folder_architect',
        title: 'Folder Architect',
        description: 'Successfully beamed an entire directory tree hierarchy.',
        icon: LucideIcons.folderGit2,
        color: AetherDropColors.hyperCobalt,
        isUnlocked: profile.totalFilesSent >= 5 ||
            profile.unlockedBadges.contains('badge_folder_architect'),
      ),
      _MilestoneBadgeData(
        id: 'badge_gigabyte_gladiator',
        title: 'Gigabyte Gladiator',
        description: 'Transferred over 1 GB of data peer-to-peer.',
        icon: LucideIcons.shieldAlert,
        color: AetherDropColors.plasmaViolet,
        isUnlocked: profile.totalBytesSent >= 1073741824 ||
            profile.unlockedBadges.contains('badge_gigabyte_gladiator'),
      ),
      _MilestoneBadgeData(
        id: 'badge_light_speed_lan',
        title: 'Light Speed LAN',
        description: 'Achieved blistering transfer speeds exceeding 50 MB/s.',
        icon: LucideIcons.rocket,
        color: AetherDropColors.liquidGold,
        isUnlocked: _maxSpeedMBps >= 50.0 ||
            profile.unlockedBadges.contains('badge_light_speed_lan'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader(
          title: 'PROGRESSION MILESTONE BADGES',
          icon: LucideIcons.award,
          badge: '${badges.where((_MilestoneBadgeData b) => b.isUnlocked).length} / 4 UNLOCKED',
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 460,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            mainAxisExtent: 104,
          ),
          itemCount: badges.length,
          itemBuilder: (BuildContext context, int index) {
            final _MilestoneBadgeData badge = badges[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111622),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: badge.isUnlocked
                      ? badge.color.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
                boxShadow: badge.isUnlocked
                    ? <BoxShadow>[
                        BoxShadow(
                          color: badge.color.withValues(alpha: 0.12),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: badge.isUnlocked
                          ? badge.color.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: badge.isUnlocked
                            ? badge.color
                            : Colors.white.withValues(alpha: 0.10),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      badge.icon,
                      size: 24,
                      color: badge.isUnlocked
                          ? badge.color
                          : AetherDropColors.textMutedDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                badge.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AetherDropTheme.titleStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: badge.isUnlocked
                                      ? Colors.white
                                      : AetherDropColors.textMutedDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badge.isUnlocked
                                    ? AetherDropColors.neonEmerald.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: badge.isUnlocked
                                      ? AetherDropColors.neonEmerald.withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.10),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                badge.isUnlocked ? 'EARNED' : 'LOCKED',
                                style: AetherDropTheme.monoStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: badge.isUnlocked
                                      ? AetherDropColors.neonEmerald
                                      : AetherDropColors.textMutedDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          badge.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AetherDropTheme.bodyStyle(
                            fontSize: 11.5,
                            color: AetherDropColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required String badge,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 16, color: AetherDropColors.electricCyan),
            const SizedBox(width: 8),
            Text(
              title,
              style: AetherDropTheme.monoStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AetherDropColors.electricCyan,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Text(
            badge,
            style: AetherDropTheme.monoStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AetherDropColors.textSecondaryDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _MilestoneBadgeData {
  const _MilestoneBadgeData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
}
