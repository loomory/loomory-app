import 'package:flutter/material.dart';

class DSLargeCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String body;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final String? cancelButtonText;
  final VoidCallback? onCancelPressed;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? backgroundColor;

  const DSLargeCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    required this.buttonText,
    required this.onButtonPressed,
    this.cancelButtonText,
    this.onCancelPressed,
    this.padding,
    this.elevation,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: elevation ?? 4,
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: backgroundColor ?? colorScheme.surfaceContainer,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title Section
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
            ),

            // Subtitle Section (if provided)
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],

            const SizedBox(height: 20),

            // Body Section
            Text(body, style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface)),

            const SizedBox(height: 24),

            // Button Section
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancel Button (if provided)
                if (cancelButtonText != null && onCancelPressed != null) ...[
                  TextButton(
                    onPressed: onCancelPressed,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(cancelButtonText!, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 12),
                ],

                // Primary Button
                ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
