import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// Card with gradient background
class GradientCard extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const GradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final defaultGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppTheme.cardBackground,
        AppTheme.cardBackground.withValues(alpha: 0.8),
      ],
    );

    Widget card = Container(
      decoration: BoxDecoration(
        gradient: gradient ?? defaultGradient,
        borderRadius: borderRadius,
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}
