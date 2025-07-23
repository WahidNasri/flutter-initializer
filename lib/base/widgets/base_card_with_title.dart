import 'package:flutter/material.dart';

class BaseCardWithTitle extends StatelessWidget {
  final String title;
  final Widget? child;
  final Widget? leadingTitle;
  final EdgeInsets? margin;
  const BaseCardWithTitle({
    super.key,
    required this.title,
    this.child,
    this.leadingTitle, this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Container(
      margin: margin ?? EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                if (leadingTitle != null) ...[
                  leadingTitle!,
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (child != null) child!,
        ],
      ),
    );
  }
}
