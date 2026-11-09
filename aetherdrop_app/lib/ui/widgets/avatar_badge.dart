import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/gamification.dart';
import '../../core/theme.dart';

/// Renders procedural custom-painted vector/SVG-style Cyber Avatars with
/// animated glowing rank borders scaled to the user's progression level.
class AvatarBadge extends StatefulWidget {
  const AvatarBadge({
    required this.avatarId,
    super.key,
    this.level = 1,
    this.size = 64,
    this.isOnline = false,
    this.showLevelPill = true,
    this.animateRing = true,
    this.onTap,
  });

  /// Identifier of the cyber avatar (e.g. `starter_cyber_01`, `cyber_kitsune_05`,
  /// `holo_samurai_10`, `astral_phoenix_25`, `apex_singularity_50`).
  final String avatarId;

  /// User progression level determining the rank border palette and glow intensity.
  final int level;

  /// Total diameter of the avatar badge in logical pixels.
  final double size;

  /// Whether to render a live online pulse indicator dot.
  final bool isOnline;

  /// Whether to display the `LVL X` rank pill at the bottom of the avatar.
  final bool showLevelPill;

  /// Whether the outer rank border ring rotates continuously.
  final bool animateRing;

  /// Optional tap callback for selecting or inspecting an avatar.
  final VoidCallback? onTap;

  /// Returns the rank title associated with a given user [level].
  static String rankTitleForLevel(int level) {
    return Gamification.getRankTitle(level);
  }

  /// Returns the rank border colors for a given [level].
  static List<Color> rankColorsForLevel(int level) {
    if (level >= 50) {
      // Singularity Core — Event Horizon Halo (Electric Cyan + Plasma Violet + Liquid Gold)
      return const <Color>[
        AetherDropColors.electricCyan,
        AetherDropColors.plasmaViolet,
        AetherDropColors.liquidGold,
        Color(0xFFFF2A85),
        AetherDropColors.electricCyan,
      ];
    }
    if (level >= 35) {
      return const <Color>[
        Color(0xFFFF3366),
        AetherDropColors.liquidGold,
        Color(0xFFFF3366),
      ];
    }
    if (level >= 25) {
      // Quantum Conduit — Liquid Gold & Electric Cyan Frame
      return const <Color>[
        AetherDropColors.liquidGold,
        Color(0xFFFFE066),
        AetherDropColors.electricCyan,
        AetherDropColors.liquidGold,
      ];
    }
    if (level >= 15) {
      return const <Color>[
        Color(0xFF67E8F9),
        AetherDropColors.plasmaViolet,
        Color(0xFFC084FC),
      ];
    }
    if (level >= 10) {
      // Data Architect — Plasma Violet & Hyper Cobalt Animated Border
      return const <Color>[
        AetherDropColors.plasmaViolet,
        AetherDropColors.electricCyan,
        AetherDropColors.hyperCobalt,
        AetherDropColors.plasmaViolet,
      ];
    }
    if (level >= 5) {
      // Pulse Runner — Electric Cyan Neon Ring
      return const <Color>[
        AetherDropColors.electricCyan,
        AetherDropColors.hyperCobalt,
        AetherDropColors.electricCyan,
      ];
    }
    // Spark Node (Lvl 1–4) — Matte Slate + Subtle Cyan Pulse Ring
    return const <Color>[
      Color(0xFF475569),
      AetherDropColors.electricCyan,
      Color(0xFF334155),
      Color(0xFF475569),
    ];
  }

  @override
  State<AvatarBadge> createState() => _AvatarBadgeState();
}

class _AvatarBadgeState extends State<AvatarBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (widget.animateRing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AvatarBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateRing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animateRing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> ringColors = AvatarBadge.rankColorsForLevel(widget.level);
    final Color primaryGlow = ringColors.first;
    final double glowSpread = widget.level >= 25
        ? 2.0
        : (widget.level >= 5 ? 1.0 : 0.0);

    Widget badge = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          // Animated glowing rank border + custom-painted vector cyber avatar
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, _) {
              final double phase = _controller.value * 2 * math.pi;
              final double pulse = 0.5 + 0.5 * math.sin(phase * 2);

              return Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: primaryGlow.withValues(
                        alpha: widget.level >= 5
                            ? (0.28 + 0.18 * pulse)
                            : (0.14 + 0.08 * pulse),
                      ),
                      blurRadius: widget.size * 0.28,
                      spreadRadius: glowSpread,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _CyberAvatarPainter(
                    avatarId: widget.avatarId,
                    level: widget.level,
                    rotationAngle: phase,
                    pulseFactor: pulse,
                    ringColors: ringColors,
                  ),
                ),
              );
            },
          ),

          // Live online status dot
          if (widget.isOnline)
            Positioned(
              right: widget.size * 0.04,
              top: widget.size * 0.04,
              child: Container(
                width: (widget.size * 0.22).clamp(10.0, 18.0),
                height: (widget.size * 0.22).clamp(10.0, 18.0),
                decoration: BoxDecoration(
                  color: AetherDropColors.neonEmerald,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AetherDropColors.deepMatteObsidian,
                    width: 2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AetherDropColors.neonEmerald.withValues(
                        alpha: 0.65,
                      ),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

          // Level Pill Badge
          if (widget.showLevelPill)
            Positioned(
              bottom: -4,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: (widget.size * 0.12).clamp(6.0, 10.0),
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AetherDropColors.deepMatteObsidian.withValues(
                    alpha: 0.92,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: primaryGlow.withValues(alpha: 0.75),
                    width: 1,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: primaryGlow.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  'LVL ${widget.level}',
                  style: AetherDropTheme.monoStyle(
                    fontSize: (widget.size * 0.14).clamp(8.5, 11.5),
                    fontWeight: FontWeight.w700,
                    color: primaryGlow == const Color(0xFF475569)
                        ? AetherDropColors.electricCyan
                        : primaryGlow,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.onTap != null) {
      badge = GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: badge,
        ),
      );
    }

    return badge;
  }
}

class _CyberAvatarPainter extends CustomPainter {
  const _CyberAvatarPainter({
    required this.avatarId,
    required this.level,
    required this.rotationAngle,
    required this.pulseFactor,
    required this.ringColors,
  });

  final String avatarId;
  final int level;
  final double rotationAngle;
  final double pulseFactor;
  final List<Color> ringColors;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2;
    final double strokeWidth = (radius * 0.10).clamp(2.2, 4.5);

    // 1. Deep Obsidian inner core background
    final Paint coreBgPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFF161B26),
          AetherDropColors.deepMatteObsidian,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - strokeWidth * 0.5, coreBgPaint);

    // 2. Animated rotating SweepGradient rank border ring
    final Rect ringRect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        colors: ringColors,
        transform: GradientRotation(rotationAngle),
      ).createShader(ringRect);
    canvas.drawCircle(center, radius - strokeWidth / 2, ringPaint);

    // Optional outer orbital segmented arc for Level 10+
    if (level >= 10) {
      final Paint orbitalPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = ringColors.first.withValues(alpha: 0.45 + 0.35 * pulseFactor);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth * 1.55),
        -rotationAngle * 0.7,
        math.pi * 0.65,
        false,
        orbitalPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth * 1.55),
        -rotationAngle * 0.7 + math.pi,
        math.pi * 0.65,
        false,
        orbitalPaint,
      );
    }

    // 3. Vector Cyber Emblem inside the avatar core
    final CyberAvatarInfo avatarInfo = Gamification.getAvatarById(avatarId);
    final Color primaryAccent = avatarInfo.primaryColor;
    final Color secondaryAccent = avatarInfo.secondaryColor;
    final double emblemRadius = radius * 0.52;

    // Subtle internal cyber grid ring
    final Paint gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = primaryAccent.withValues(alpha: 0.18);
    canvas.drawCircle(center, emblemRadius * 1.15, gridPaint);

    Gamification.paintEmblem(
      canvas: canvas,
      avatarId: avatarId,
      center: center,
      emblemRadius: emblemRadius,
      primaryColor: primaryAccent,
      secondaryColor: secondaryAccent,
      pulseFactor: pulseFactor,
    );
  }

  @override
  bool shouldRepaint(covariant _CyberAvatarPainter oldDelegate) {
    return oldDelegate.avatarId != avatarId ||
        oldDelegate.level != level ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.pulseFactor != pulseFactor;
  }
}
