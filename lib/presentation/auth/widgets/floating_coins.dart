import 'dart:math';
import 'package:flutter/material.dart';

/// Floating financial icons animation for login/register background
class FloatingCoins extends StatefulWidget {
  const FloatingCoins({super.key});

  @override
  State<FloatingCoins> createState() => _FloatingCoinsState();
}

class _FloatingCoinsState extends State<FloatingCoins>
    with TickerProviderStateMixin {
  final List<_FloatingItem> _items = [];
  final _random = Random();

  static const List<String> _emojis = [
    '💰', '💵', '💳', '📊', '🪙', '💎', '📈', '🏦', '💲', '🤑',
  ];

  @override
  void initState() {
    super.initState();
    // Create 12 floating items with random properties
    for (int i = 0; i < 12; i++) {
      _items.add(_FloatingItem(
        emoji: _emojis[_random.nextInt(_emojis.length)],
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 20.0 + _random.nextDouble() * 20,
        opacity: 0.08 + _random.nextDouble() * 0.12,
        speed: 0.3 + _random.nextDouble() * 0.7,
        drift: (_random.nextDouble() - 0.5) * 0.3,
        rotationSpeed: (_random.nextDouble() - 0.5) * 2,
        delay: _random.nextDouble() * 2,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: _items.map((item) {
            return _FloatingCoinWidget(
              item: item,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            );
          }).toList(),
        );
      },
    );
  }
}

class _FloatingItem {
  final String emoji;
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double speed;
  final double drift;
  final double rotationSpeed;
  final double delay;

  _FloatingItem({
    required this.emoji,
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.drift,
    required this.rotationSpeed,
    required this.delay,
  });
}

class _FloatingCoinWidget extends StatefulWidget {
  final _FloatingItem item;
  final double width;
  final double height;

  const _FloatingCoinWidget({
    required this.item,
    required this.width,
    required this.height,
  });

  @override
  State<_FloatingCoinWidget> createState() => _FloatingCoinWidgetState();
}

class _FloatingCoinWidgetState extends State<_FloatingCoinWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final durationMs = (8000 / widget.item.speed).round();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    // Start with delay for staggered effect
    Future.delayed(
      Duration(milliseconds: (widget.item.delay * 1000).round()),
      () {
        if (mounted) _controller.repeat();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Float upward, loop from bottom
        final yOffset = (widget.item.y - t) % 1.0;
        // Drift sideways with sine wave
        final xOffset = widget.item.x +
            sin(t * 2 * pi) * widget.item.drift;
        // Gentle rotation
        final rotation = t * widget.item.rotationSpeed * 2 * pi;
        // Fade in/out at edges
        double opacity = widget.item.opacity;
        if (yOffset < 0.1) {
          opacity *= yOffset / 0.1;
        } else if (yOffset > 0.85) {
          opacity *= (1.0 - yOffset) / 0.15;
        }

        return Positioned(
          left: xOffset * widget.width,
          top: yOffset * widget.height,
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Text(
                widget.item.emoji,
                style: TextStyle(fontSize: widget.item.size),
              ),
            ),
          ),
        );
      },
    );
  }
}
