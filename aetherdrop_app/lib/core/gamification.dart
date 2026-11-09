import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Metadata definition for one of AetherDrop's built-in vector Cyber Avatars.
class CyberAvatarInfo {
  const CyberAvatarInfo({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.requiredLevel,
    required this.primaryColor,
    required this.secondaryColor,
    this.isStarter = false,
  });

  /// Unique identifier (e.g. `starter_cyber_01`, `cyber_kitsune_05`).
  final String id;

  /// Display name of the cyber avatar.
  final String name;

  /// Lore / description snippet.
  final String subtitle;

  /// Minimum progression level required to unlock this avatar.
  final int requiredLevel;

  /// Primary neon accent color used for glow and strokes.
  final Color primaryColor;

  /// Secondary cyber accent color for gradients and secondary vectors.
  final Color secondaryColor;

  /// Whether this avatar is unlocked by default on first launch (Level 1).
  final bool isStarter;

  /// Returns true if the user's level or unlocked list unlocks this avatar.
  bool isUnlockedFor({int level = 1, List<String>? unlockedAvatars}) {
    if (isStarter) return true;
    if (level >= requiredLevel) return true;
    if (unlockedAvatars != null && unlockedAvatars.contains(id)) return true;
    return false;
  }
}

/// Detailed progression progress metrics toward the next level.
class LevelProgress {
  const LevelProgress({
    required this.currentLevel,
    required this.nextLevel,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.xpIntoCurrentLevel,
    required this.xpNeededForNextLevel,
    required this.progress,
  });

  final int currentLevel;
  final int nextLevel;
  final int currentLevelXp;
  final int nextLevelXp;
  final int xpIntoCurrentLevel;
  final int xpNeededForNextLevel;

  /// Progress fraction clamped to `0.0 .. 1.0`.
  final double progress;

  /// Percentage formatted string (e.g. `45%`).
  String get percentageText => '${(progress * 100).toInt()}%';
}

/// Central gamification engine for AetherDrop progression, avatar rendering,
/// rank titles, and frame gradients.
class Gamification {
  Gamification._();

  // ---------------------------------------------------------------------------
  // 12 Built-in Procedural Cyber Avatars
  // ---------------------------------------------------------------------------

  /// Starter Tier (Level 1)
  static const CyberAvatarInfo starterCyber01 = CyberAvatarInfo(
    id: 'starter_cyber_01',
    name: 'Neon Pulse Core',
    subtitle: 'High-frequency electric quantum spark generator',
    requiredLevel: 1,
    primaryColor: AetherDropColors.electricCyan,
    secondaryColor: AetherDropColors.hyperCobalt,
    isStarter: true,
  );

  static const CyberAvatarInfo starterCyber02 = CyberAvatarInfo(
    id: 'starter_cyber_02',
    name: 'Stealth Hex',
    subtitle: 'Cobalt-reinforced hexagonal encrypted firewall node',
    requiredLevel: 1,
    primaryColor: AetherDropColors.hyperCobalt,
    secondaryColor: AetherDropColors.electricCyan,
    isStarter: true,
  );

  static const CyberAvatarInfo starterCyber03 = CyberAvatarInfo(
    id: 'starter_cyber_03',
    name: 'Quantum Prism',
    subtitle: 'Dual inverted spatial prism refracting light-speed data',
    requiredLevel: 1,
    primaryColor: AetherDropColors.plasmaViolet,
    secondaryColor: AetherDropColors.electricCyan,
    isStarter: true,
  );

  static const CyberAvatarInfo starterCyber04 = CyberAvatarInfo(
    id: 'starter_cyber_04',
    name: 'Orbital Vector',
    subtitle: 'Twin gyroscopic quantum rings warping packets across space',
    requiredLevel: 1,
    primaryColor: AetherDropColors.electricCyan,
    secondaryColor: AetherDropColors.neonEmerald,
    isStarter: true,
  );

  /// Unlockable Tiers (Levels 5 to 50)
  static const CyberAvatarInfo cyberKitsune05 = CyberAvatarInfo(
    id: 'cyber_kitsune_05',
    name: 'Cyber Kitsune',
    subtitle: 'Agile neon spirit mask channeling encrypted hyper-routes',
    requiredLevel: 5,
    primaryColor: Color(0xFFFF2A85),
    secondaryColor: AetherDropColors.electricCyan,
  );

  static const CyberAvatarInfo voidDroid08 = CyberAvatarInfo(
    id: 'void_droid_08',
    name: 'Void Droid',
    subtitle: 'Autonomous sub-space mecha with panoramic sensor array',
    requiredLevel: 8,
    primaryColor: Color(0xFF00FFB2),
    secondaryColor: AetherDropColors.hyperCobalt,
  );

  static const CyberAvatarInfo holoSamurai10 = CyberAvatarInfo(
    id: 'holo_samurai_10',
    name: 'Holo-Samurai',
    subtitle: 'Armored crested blade-master guarding peer integrity',
    requiredLevel: 10,
    primaryColor: AetherDropColors.plasmaViolet,
    secondaryColor: Color(0xFFFF007A),
  );

  static const CyberAvatarInfo plasmaValkyrie15 = CyberAvatarInfo(
    id: 'plasma_valkyrie_15',
    name: 'Plasma Valkyrie',
    subtitle: 'Winged cyber-warrior descending with supersonic throughput',
    requiredLevel: 15,
    primaryColor: Color(0xFF67E8F9),
    secondaryColor: AetherDropColors.plasmaViolet,
  );

  static const CyberAvatarInfo chronoPhantom20 = CyberAvatarInfo(
    id: 'chrono_phantom_20',
    name: 'Chrono Phantom',
    subtitle: 'Temporal rift warden defying latency and packet decay',
    requiredLevel: 20,
    primaryColor: Color(0xFFC084FC),
    secondaryColor: Color(0xFF38BDF8),
  );

  static const CyberAvatarInfo astralPhoenix25 = CyberAvatarInfo(
    id: 'astral_phoenix_25',
    name: 'Astral Phoenix',
    subtitle: 'Cosmic solar raptor soaring through inter-planetary pipes',
    requiredLevel: 25,
    primaryColor: AetherDropColors.liquidGold,
    secondaryColor: Color(0xFFFF5722),
  );

  static const CyberAvatarInfo novaTitan35 = CyberAvatarInfo(
    id: 'nova_titan_35',
    name: 'Nova Titan',
    subtitle: 'Heavy octagonal thermonuclear fusion reactor core',
    requiredLevel: 35,
    primaryColor: Color(0xFFFF3366),
    secondaryColor: AetherDropColors.liquidGold,
  );

  static const CyberAvatarInfo apexSingularity50 = CyberAvatarInfo(
    id: 'apex_singularity_50',
    name: 'Apex Singularity',
    subtitle: 'Omniscient black hole accretion star bending spacetime',
    requiredLevel: 50,
    primaryColor: AetherDropColors.electricCyan,
    secondaryColor: AetherDropColors.liquidGold,
  );

  /// All 12 procedural Cyber Avatars in progression order.
  static const List<CyberAvatarInfo> allAvatars = <CyberAvatarInfo>[
    starterCyber01,
    starterCyber02,
    starterCyber03,
    starterCyber04,
    cyberKitsune05,
    voidDroid08,
    holoSamurai10,
    plasmaValkyrie15,
    chronoPhantom20,
    astralPhoenix25,
    novaTitan35,
    apexSingularity50,
  ];

  /// The 4 Starter Tier Avatars available to every user on first launch.
  static const List<CyberAvatarInfo> starterAvatars = <CyberAvatarInfo>[
    starterCyber01,
    starterCyber02,
    starterCyber03,
    starterCyber04,
  ];

  /// Looks up avatar definition by [id], falling back to [starterCyber01].
  static CyberAvatarInfo getAvatarById(String id) {
    for (final CyberAvatarInfo avatar in allAvatars) {
      if (avatar.id == id) return avatar;
    }
    return starterCyber01;
  }

  // ---------------------------------------------------------------------------
  // Helper Methods
  // ---------------------------------------------------------------------------

  /// Returns the prestigious rank title associated with a given [level].
  static String getRankTitle(int level) {
    if (level >= 50) return 'Singularity Core';
    if (level >= 35) return 'Nova Vanguard';
    if (level >= 25) return 'Quantum Conduit';
    if (level >= 20) return 'Chrono Wanderer';
    if (level >= 15) return 'Plasma Valkyrie';
    if (level >= 10) return 'Data Architect';
    if (level >= 8) return 'Void Pioneer';
    if (level >= 5) return 'Pulse Runner';
    return 'Spark Node';
  }

  /// Calculates XP progression metrics to the next level based on total [xp].
  ///
  /// Formula: `level = floor(sqrt(xp / 25))`, so `xp = 25 * level^2`.
  static LevelProgress getProgressToNextLevel(int xp) {
    final int safeXp = math.max(0, xp);
    final int currentLevel = safeXp <= 0
        ? 1
        : math.max(1, math.sqrt(safeXp / 25.0).floor());
    final int nextLevel = currentLevel + 1;

    final int currentLevelStartXp = currentLevel == 1
        ? 0
        : (25 * currentLevel * currentLevel);
    final int nextLevelTargetXp = 25 * nextLevel * nextLevel;

    final int xpIntoCurrent = math.max(0, safeXp - currentLevelStartXp);
    final int xpNeededTotal = math.max(1, nextLevelTargetXp - currentLevelStartXp);
    final double fraction = (xpIntoCurrent / xpNeededTotal).clamp(0.0, 1.0);

    return LevelProgress(
      currentLevel: currentLevel,
      nextLevel: nextLevel,
      currentLevelXp: currentLevelStartXp,
      nextLevelXp: nextLevelTargetXp,
      xpIntoCurrentLevel: xpIntoCurrent,
      xpNeededForNextLevel: math.max(0, nextLevelTargetXp - safeXp),
      progress: fraction,
    );
  }

  /// Returns the glowing linear or sweep frame gradient for a given [level].
  static Gradient getFrameGradient(int level) {
    if (level >= 50) {
      return const SweepGradient(
        colors: <Color>[
          AetherDropColors.electricCyan,
          AetherDropColors.plasmaViolet,
          AetherDropColors.liquidGold,
          Color(0xFFFF2A85),
          AetherDropColors.electricCyan,
        ],
      );
    }
    if (level >= 35) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFFF3366),
          AetherDropColors.liquidGold,
          Color(0xFFFF3366),
        ],
      );
    }
    if (level >= 25) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          AetherDropColors.liquidGold,
          Color(0xFFFFE066),
          AetherDropColors.electricCyan,
          AetherDropColors.liquidGold,
        ],
      );
    }
    if (level >= 15) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF67E8F9),
          AetherDropColors.plasmaViolet,
          Color(0xFFC084FC),
        ],
      );
    }
    if (level >= 10) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          AetherDropColors.plasmaViolet,
          AetherDropColors.electricCyan,
          AetherDropColors.hyperCobalt,
          AetherDropColors.plasmaViolet,
        ],
      );
    }
    if (level >= 5) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          AetherDropColors.electricCyan,
          AetherDropColors.hyperCobalt,
          AetherDropColors.electricCyan,
        ],
      );
    }
    // Level 1-4: Matte Slate with Subtle Electric Cyan pulse
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color(0xFF475569),
        AetherDropColors.electricCyan,
        Color(0xFF334155),
        Color(0xFF475569),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Procedural Vector Vector Drawing Engine for All 12 Avatars
  // ---------------------------------------------------------------------------

  /// Draws the procedural vector emblem of any cyber avatar on the provided [canvas].
  static void paintEmblem({
    required Canvas canvas,
    required String avatarId,
    required Offset center,
    required double emblemRadius,
    required Color primaryColor,
    required Color secondaryColor,
    double pulseFactor = 0.5,
  }) {
    final Paint glowStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (emblemRadius * 0.14).clamp(1.6, 3.4)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[primaryColor, secondaryColor],
      ).createShader(
        Rect.fromCircle(center: center, radius: emblemRadius),
      );

    final Paint coreFill = Paint()
      ..style = PaintingStyle.fill
      ..color = primaryColor.withValues(alpha: 0.18 + 0.14 * pulseFactor);

    final Paint accentStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (emblemRadius * 0.10).clamp(1.2, 2.4)
      ..strokeCap = StrokeCap.round
      ..color = secondaryColor.withValues(alpha: 0.85);

    switch (avatarId) {
      case 'starter_cyber_02':
        // 2. Stealth Hex — Hexagonal encrypted firewall
        final Path hex = polygonPath(center, emblemRadius, 6, -math.pi / 2);
        canvas.drawPath(hex, coreFill);
        canvas.drawPath(hex, glowStroke);
        canvas.drawCircle(center, emblemRadius * 0.32, glowStroke);
        final Path innerHex = polygonPath(center, emblemRadius * 0.62, 6, 0);
        canvas.drawPath(innerHex, accentStroke);

      case 'starter_cyber_03':
        // 3. Quantum Prism — Nested dual triangles
        final Path outerTri = polygonPath(center, emblemRadius, 3, -math.pi / 2);
        final Path innerTri = polygonPath(center, emblemRadius * 0.58, 3, math.pi / 2);
        canvas.drawPath(outerTri, coreFill);
        canvas.drawPath(outerTri, glowStroke);
        canvas.drawPath(innerTri, accentStroke);
        canvas.drawCircle(center, emblemRadius * 0.16, glowStroke);

      case 'starter_cyber_04':
        // 4. Orbital Vector — Dual gyroscopic intersecting orbits
        canvas.drawCircle(center, emblemRadius * 0.35, coreFill);
        canvas.drawCircle(center, emblemRadius * 0.35, glowStroke);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(math.pi / 4);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: emblemRadius * 2.1,
            height: emblemRadius * 0.82,
          ),
          glowStroke,
        );
        canvas.rotate(-math.pi / 2);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: emblemRadius * 2.1,
            height: emblemRadius * 0.82,
          ),
          accentStroke,
        );
        canvas.restore();

      case 'cyber_kitsune_05':
        // 5. Cyber Kitsune — Geometric fox mask silhouette
        final Path mask = Path()
          ..moveTo(center.dx, center.dy + emblemRadius * 0.86)
          ..lineTo(center.dx - emblemRadius * 0.78, center.dy - emblemRadius * 0.10)
          ..lineTo(center.dx - emblemRadius * 0.55, center.dy - emblemRadius * 0.90)
          ..lineTo(center.dx, center.dy - emblemRadius * 0.30)
          ..lineTo(center.dx + emblemRadius * 0.55, center.dy - emblemRadius * 0.90)
          ..lineTo(center.dx + emblemRadius * 0.78, center.dy - emblemRadius * 0.10)
          ..close();
        canvas.drawPath(mask, coreFill);
        canvas.drawPath(mask, glowStroke);
        // Forehead crest diamond
        final Path crest = polygonPath(
          Offset(center.dx, center.dy - emblemRadius * 0.05),
          emblemRadius * 0.22,
          4,
          0,
        );
        canvas.drawPath(crest, accentStroke);

      case 'void_droid_08':
        // 6. Void Droid — Angular mecha head & panoramic visor
        final Path droid = Path()
          ..moveTo(center.dx - emblemRadius * 0.65, center.dy - emblemRadius * 0.75)
          ..lineTo(center.dx + emblemRadius * 0.65, center.dy - emblemRadius * 0.75)
          ..lineTo(center.dx + emblemRadius * 0.85, center.dy + emblemRadius * 0.25)
          ..lineTo(center.dx + emblemRadius * 0.45, center.dy + emblemRadius * 0.85)
          ..lineTo(center.dx - emblemRadius * 0.45, center.dy + emblemRadius * 0.85)
          ..lineTo(center.dx - emblemRadius * 0.85, center.dy + emblemRadius * 0.25)
          ..close();
        canvas.drawPath(droid, coreFill);
        canvas.drawPath(droid, glowStroke);
        // Glowing horizontal sensor visor
        canvas.drawLine(
          Offset(center.dx - emblemRadius * 0.55, center.dy),
          Offset(center.dx + emblemRadius * 0.55, center.dy),
          accentStroke,
        );
        canvas.drawCircle(center, emblemRadius * 0.15, glowStroke);

      case 'holo_samurai_10':
        // 7. Holo Samurai — Crescent kabuto horns & central blade
        final Path crest = Path()
          ..moveTo(center.dx, center.dy - emblemRadius * 0.92)
          ..lineTo(center.dx + emblemRadius * 0.36, center.dy)
          ..lineTo(center.dx, center.dy + emblemRadius * 0.92)
          ..lineTo(center.dx - emblemRadius * 0.36, center.dy)
          ..close();
        final Path horns = Path()
          ..moveTo(center.dx - emblemRadius * 0.88, center.dy - emblemRadius * 0.55)
          ..quadraticBezierTo(
            center.dx,
            center.dy + emblemRadius * 0.40,
            center.dx + emblemRadius * 0.88,
            center.dy - emblemRadius * 0.55,
          );
        canvas.drawPath(crest, coreFill);
        canvas.drawPath(crest, glowStroke);
        canvas.drawPath(horns, accentStroke);

      case 'plasma_valkyrie_15':
        // 8. Plasma Valkyrie — Winged helm & supersonic prism
        final Path wingLeft = Path()
          ..moveTo(center.dx - emblemRadius * 0.15, center.dy + emblemRadius * 0.60)
          ..lineTo(center.dx - emblemRadius * 0.90, center.dy - emblemRadius * 0.45)
          ..lineTo(center.dx - emblemRadius * 0.55, center.dy - emblemRadius * 0.85)
          ..lineTo(center.dx - emblemRadius * 0.15, center.dy - emblemRadius * 0.15)
          ..close();
        final Path wingRight = Path()
          ..moveTo(center.dx + emblemRadius * 0.15, center.dy + emblemRadius * 0.60)
          ..lineTo(center.dx + emblemRadius * 0.90, center.dy - emblemRadius * 0.45)
          ..lineTo(center.dx + emblemRadius * 0.55, center.dy - emblemRadius * 0.85)
          ..lineTo(center.dx + emblemRadius * 0.15, center.dy - emblemRadius * 0.15)
          ..close();
        canvas.drawPath(wingLeft, coreFill);
        canvas.drawPath(wingLeft, glowStroke);
        canvas.drawPath(wingRight, coreFill);
        canvas.drawPath(wingRight, glowStroke);
        canvas.drawCircle(center, emblemRadius * 0.25, accentStroke);

      case 'chrono_phantom_20':
        // 9. Chrono Phantom — Hourglass rift & quantum vortex
        final Path hourglass = Path()
          ..moveTo(center.dx - emblemRadius * 0.70, center.dy - emblemRadius * 0.75)
          ..lineTo(center.dx + emblemRadius * 0.70, center.dy - emblemRadius * 0.75)
          ..lineTo(center.dx - emblemRadius * 0.70, center.dy + emblemRadius * 0.75)
          ..lineTo(center.dx + emblemRadius * 0.70, center.dy + emblemRadius * 0.75)
          ..close();
        canvas.drawPath(hourglass, coreFill);
        canvas.drawPath(hourglass, glowStroke);
        canvas.drawCircle(center, emblemRadius * 0.22, accentStroke);
        canvas.drawLine(
          Offset(center.dx, center.dy - emblemRadius * 0.85),
          Offset(center.dx, center.dy + emblemRadius * 0.85),
          accentStroke,
        );

      case 'astral_phoenix_25':
        // 10. Astral Phoenix — Cosmic solar falcon wings
        final Path wings = Path()
          ..moveTo(center.dx, center.dy - emblemRadius * 0.90)
          ..lineTo(center.dx + emblemRadius * 0.90, center.dy - emblemRadius * 0.25)
          ..lineTo(center.dx + emblemRadius * 0.40, center.dy + emblemRadius * 0.85)
          ..lineTo(center.dx, center.dy + emblemRadius * 0.35)
          ..lineTo(center.dx - emblemRadius * 0.40, center.dy + emblemRadius * 0.85)
          ..lineTo(center.dx - emblemRadius * 0.90, center.dy - emblemRadius * 0.25)
          ..close();
        canvas.drawPath(wings, coreFill);
        canvas.drawPath(wings, glowStroke);
        canvas.drawCircle(
          Offset(center.dx, center.dy - emblemRadius * 0.15),
          emblemRadius * 0.20,
          accentStroke,
        );

      case 'nova_titan_35':
        // 11. Nova Titan — Thermonuclear fusion octagon & 4 coils
        final Path coreOct = polygonPath(center, emblemRadius * 0.65, 8, math.pi / 8);
        canvas.drawPath(coreOct, coreFill);
        canvas.drawPath(coreOct, glowStroke);
        for (int i = 0; i < 4; i++) {
          final double angle = i * math.pi / 2;
          final Offset start = Offset(
            center.dx + emblemRadius * 0.65 * math.cos(angle),
            center.dy + emblemRadius * 0.65 * math.sin(angle),
          );
          final Offset end = Offset(
            center.dx + emblemRadius * 0.95 * math.cos(angle),
            center.dy + emblemRadius * 0.95 * math.sin(angle),
          );
          canvas.drawLine(start, end, accentStroke);
        }
        canvas.drawCircle(center, emblemRadius * 0.26, glowStroke);

      case 'apex_singularity_50':
        // 12. Apex Singularity — Event Horizon star & black hole accretion
        final Path star = starPath(center, emblemRadius, emblemRadius * 0.44, 8);
        canvas.drawPath(star, coreFill);
        canvas.drawPath(star, glowStroke);
        // Central black hole core
        canvas.drawCircle(
          center,
          emblemRadius * 0.30,
          Paint()..color = AetherDropColors.deepMatteObsidian,
        );
        canvas.drawCircle(center, emblemRadius * 0.30, glowStroke);
        canvas.drawCircle(center, emblemRadius * 0.12, accentStroke);

      default:
        // 1. starter_cyber_01 (Neon Pulse Core) & default fallback
        final Path diamond = polygonPath(center, emblemRadius, 4, 0);
        canvas.drawPath(diamond, coreFill);
        canvas.drawPath(diamond, glowStroke);

        final Path bolt = Path()
          ..moveTo(center.dx + emblemRadius * 0.14, center.dy - emblemRadius * 0.58)
          ..lineTo(center.dx - emblemRadius * 0.26, center.dy + emblemRadius * 0.05)
          ..lineTo(center.dx + emblemRadius * 0.06, center.dy + emblemRadius * 0.05)
          ..lineTo(center.dx - emblemRadius * 0.14, center.dy + emblemRadius * 0.58);
        canvas.drawPath(bolt, accentStroke);
    }
  }

  /// Constructs a regular polygon path with [sides] at [center] and [radius].
  static Path polygonPath(
    Offset center,
    double radius,
    int sides,
    double startAngle,
  ) {
    final Path path = Path();
    for (int i = 0; i < sides; i++) {
      final double angle = startAngle + (2 * math.pi * i / sides);
      final Offset point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  /// Constructs a star path with [points] alternating between [outerRadius] and [innerRadius].
  static Path starPath(
    Offset center,
    double outerRadius,
    double innerRadius,
    int points,
  ) {
    final Path path = Path();
    final int totalVertices = points * 2;
    for (int i = 0; i < totalVertices; i++) {
      final double r = i.isEven ? outerRadius : innerRadius;
      final double angle = -math.pi / 2 + (math.pi * i / points);
      final Offset pt = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    return path;
  }
}

