import 'package:flutter/material.dart';

/// Section header widget
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsets padding;
  final bool centered;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment:
            centered
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
