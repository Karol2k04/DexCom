import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final double blur;
  final Color? overlayColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.blur = 8.0,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOverlay =
        overlayColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.04)
            : Colors.white.withOpacity(0.6));

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: effectiveOverlay,
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
