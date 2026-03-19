import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// Animated dots page indicator using smooth_page_indicator.
class PageIndicator extends StatelessWidget {
  final PageController controller;
  final int count;
  final Color activeColor;

  const PageIndicator({
    super.key,
    required this.controller,
    required this.count,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return SmoothPageIndicator(
      controller: controller,
      count: count,
      effect: ExpandingDotsEffect(
        activeDotColor: activeColor,
        dotColor: activeColor.withOpacity(0.3),
        dotHeight: 8,
        dotWidth: 8,
        expansionFactor: 3,
        spacing: 6,
      ),
    );
  }
}
