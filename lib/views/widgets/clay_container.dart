import 'package:flutter/material.dart';

class ClayContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double depth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool isRecessed;

  ClayContainer({
    super.key,
    required this.child,
    double? borderRadius,
    double? cornerRadius,
    double? depth,
    double? spread,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.borderWidth = 0.0,
    this.onTap,
    this.isRecessed = false,
  })  : borderRadius = cornerRadius ?? borderRadius ?? 24.0,
        depth = spread ?? depth ?? 12.0;

  Color _getHighlightColor(Color baseColor, bool isDark) {
    if (isDark) {
      return HSLColor.fromColor(baseColor)
          .withLightness((HSLColor.fromColor(baseColor).lightness + 0.12).clamp(0.0, 1.0))
          .toColor()
          .withValues(alpha: 0.25);
    }
    return Colors.white.withValues(alpha: 0.85);
  }

  Color _getShadowColor(Color baseColor, bool isDark) {
    if (isDark) {
      return Colors.black.withValues(alpha: 0.55);
    }
    return HSLColor.fromColor(baseColor)
        .withLightness((HSLColor.fromColor(baseColor).lightness - 0.25).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: 0.35);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final baseColor = color ??
        (isDark ? const Color(0xFF192234) : Colors.white);

    final highlightColor = _getHighlightColor(baseColor, isDark);
    final shadowColor = _getShadowColor(baseColor, isDark);

    final currentDepth = depth.abs();
    final offset = isRecessed ? -currentDepth / 2 : currentDepth / 2;

    Widget content = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ??
                    (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : primaryColor.withValues(alpha: 0.15)),
                width: borderWidth,
              )
            : null,
        boxShadow: [
          // Top-Left Light Highlight
          BoxShadow(
            color: isRecessed ? shadowColor : highlightColor,
            offset: Offset(-offset, -offset),
            blurRadius: currentDepth,
            spreadRadius: 1,
          ),
          // Bottom-Right Ambient Shadow
          BoxShadow(
            color: isRecessed ? highlightColor : shadowColor,
            offset: Offset(offset, offset),
            blurRadius: currentDepth,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
