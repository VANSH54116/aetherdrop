import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Reusable Dark Glassmorphic container with `BackdropFilter` blur
/// (`sigmaX: 18, sigmaY: 18`), Translucent Carbon fill (`rgba(255,255,255,0.04)`),
/// and a crisp `1px solid rgba(255,255,255,0.10)` border.
class GlassCard extends StatefulWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.width,
    this.height,
    this.borderRadius = AetherDropGlass.borderRadius,
    this.blurSigmaX = AetherDropGlass.blurSigmaX,
    this.blurSigmaY = AetherDropGlass.blurSigmaY,
    this.backgroundColor,
    this.borderColor,
    this.hoverBorderColor,
    this.borderWidth = AetherDropGlass.borderWidth,
    this.gradient,
    this.glowColor,
    this.glowIntensity = 0.16,
    this.onTap,
    this.onLongPress,
    this.enableHoverEffect = true,
    this.alignment,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blurSigmaX;
  final double blurSigmaY;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? hoverBorderColor;
  final double borderWidth;
  final Gradient? gradient;
  final Color? glowColor;
  final double glowIntensity;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableHoverEffect;
  final AlignmentGeometry? alignment;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool interactive =
        widget.enableHoverEffect &&
        (widget.onTap != null || widget.hoverBorderColor != null);

    final Color defaultSurface = isDark
        ? (_isHovered && interactive
              ? AetherDropColors.translucentCarbonHover
              : AetherDropColors.translucentCarbon)
        : AetherDropColors.frostedWhiteSurface;

    final Color effectiveSurface = widget.backgroundColor ?? defaultSurface;

    final Color defaultBorder = isDark
        ? AetherDropColors.glassBorder
        : AetherDropColors.lightGlassBorder;

    final Color effectiveBorder = _isHovered && interactive
        ? (widget.hoverBorderColor ??
              AetherDropColors.electricCyan.withValues(alpha: 0.55))
        : (widget.borderColor ?? defaultBorder);

    final Color? activeGlow =
        widget.glowColor ??
        (_isHovered && interactive ? AetherDropColors.electricCyan : null);

    final BorderRadius radius = BorderRadius.circular(widget.borderRadius);

    Widget cardBody = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurSigmaX,
          sigmaY: widget.blurSigmaY,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: widget.width,
          height: widget.height,
          alignment: widget.alignment,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.gradient == null ? effectiveSurface : null,
            gradient: widget.gradient,
            borderRadius: radius,
            border: Border.all(
              color: effectiveBorder,
              width: widget.borderWidth,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              if (activeGlow != null)
                BoxShadow(
                  color: activeGlow.withValues(
                    alpha: _isHovered
                        ? (widget.glowIntensity * 1.4).clamp(0.0, 1.0)
                        : widget.glowIntensity,
                  ),
                  blurRadius: _isHovered ? 28 : 20,
                  spreadRadius: _isHovered ? 1 : 0,
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap != null || widget.onLongPress != null) {
      cardBody = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          splashColor: AetherDropColors.electricCyan.withValues(alpha: 0.12),
          highlightColor: AetherDropColors.hyperCobalt.withValues(alpha: 0.08),
          child: cardBody,
        ),
      );
    }

    if (interactive) {
      cardBody = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        child: cardBody,
      );
    }

    if (widget.margin != null) {
      return Padding(
        padding: widget.margin!,
        child: cardBody,
      );
    }

    return cardBody;
  }
}
