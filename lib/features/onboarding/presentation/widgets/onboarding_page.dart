import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A single onboarding page with icon, title, and description.
class OnboardingPage extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final Color color;

  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 72),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.92, end: 1.08, duration: 1200.ms, curve: Curves.easeInOut),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scaleXY(begin: 0.7, end: 1.0, duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 40),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.3, end: 0, duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 350.ms).slideY(begin: 0.3, end: 0, duration: 400.ms, delay: 350.ms),
        ],
      ),
    );
  }
}
