import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shared animation configurations for consistent UX across the app
class AnimationConfig {
  // Durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 700);

  // Stagger delays
  static const Duration staggerDelay = Duration(milliseconds: 80);

  // Curves
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
}

/// Extension on Widget to add common app animations
extension AppAnimations on Widget {
  /// Fade in from bottom - used for section entries
  Widget fadeInSlideUp({int index = 0, Duration? delay}) {
    return animate()
        .fadeIn(
          duration: AnimationConfig.normal,
          delay: delay ?? (AnimationConfig.staggerDelay * index),
          curve: AnimationConfig.defaultCurve,
        )
        .slideY(
          begin: 0.15,
          end: 0,
          duration: AnimationConfig.normal,
          delay: delay ?? (AnimationConfig.staggerDelay * index),
          curve: AnimationConfig.defaultCurve,
        );
  }

  /// Fade in from left - used for list items
  Widget fadeInSlideLeft({int index = 0, Duration? delay}) {
    return animate()
        .fadeIn(
          duration: AnimationConfig.normal,
          delay: delay ?? (AnimationConfig.staggerDelay * index),
          curve: AnimationConfig.defaultCurve,
        )
        .slideX(
          begin: -0.08,
          end: 0,
          duration: AnimationConfig.normal,
          delay: delay ?? (AnimationConfig.staggerDelay * index),
          curve: AnimationConfig.defaultCurve,
        );
  }

  /// Scale in - used for cards and buttons
  Widget scaleIn({int index = 0, Duration? delay}) {
    return animate()
        .fadeIn(
          duration: AnimationConfig.normal,
          delay: delay ?? (AnimationConfig.staggerDelay * index),
          curve: AnimationConfig.defaultCurve,
        )
        .scaleXY(
          begin: 0.92,
          end: 1.0,
          duration: AnimationConfig.normal,
          delay: delay ?? (AnimationConfig.staggerDelay * index),
          curve: AnimationConfig.defaultCurve,
        );
  }

  /// Bounce in - used for icons and small elements
  Widget bounceIn({int index = 0, Duration? delay}) {
    return animate()
        .fadeIn(
          duration: AnimationConfig.fast,
          delay: delay ?? (AnimationConfig.staggerDelay * index),
        )
        .scaleXY(
          begin: 0.5,
          end: 1.0,
          duration: AnimationConfig.slow,
          delay: delay ?? (AnimationConfig.staggerDelay * index),
          curve: AnimationConfig.bounceCurve,
        );
  }

  /// Shimmer effect - used for headers and highlights
  Widget shimmerEffect({Duration? delay}) {
    return animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(
      duration: const Duration(seconds: 2),
      delay: delay ?? Duration.zero,
      color: Colors.white24,
    );
  }
}

/// Animated counter that counts up from 0 to target value
class AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String Function(double) formatter;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    required this.formatter,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          formatter(animatedValue),
          style: style,
        );
      },
    );
  }
}

/// Animated progress bar that fills from 0 to target
class AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final Color? backgroundColor;
  final double height;
  final Duration duration;
  final Duration delay;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.backgroundColor,
    this.height = 8,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: animatedValue,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.7), color],
                ),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        );
      },
    );
  }
}
