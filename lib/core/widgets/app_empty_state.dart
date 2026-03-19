import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A reusable, animated empty-state widget used across screens.
class AppEmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 428 ? 428.0 : constraints.maxWidth;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    icon,
                    style: const TextStyle(fontSize: 64),
                  ).animate().fadeIn(duration: 400.ms).scaleXY(begin: 0.8, end: 1.0, duration: 400.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 300.ms, delay: 100.ms),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 300.ms, delay: 200.ms),
                  if (buttonLabel != null && onButtonPressed != null) ...[
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: onButtonPressed,
                      child: Text(buttonLabel!),
                    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).scaleXY(begin: 0.9, end: 1.0, duration: 300.ms, delay: 300.ms),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
