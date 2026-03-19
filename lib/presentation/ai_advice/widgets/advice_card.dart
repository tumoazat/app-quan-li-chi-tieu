import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/services/ai_advice_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

class AdviceCard extends StatelessWidget {
  final AdviceItem advice;
  final int index;

  const AdviceCard({
    super.key,
    required this.advice,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingBase),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusXl),
        border: Border(
          left: BorderSide(
            color: advice.borderColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              advice.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    advice.title,
                    style: AppTypography.titleLarge(context),
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  _buildMessageWithHighlight(context),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(
        duration: Duration(milliseconds: AppConstants.animationNormal),
        delay: Duration(milliseconds: 50 * index),
      )
      .slideY(
        begin: 0.2,
        end: 0,
        duration: Duration(milliseconds: AppConstants.animationNormal),
        delay: Duration(milliseconds: 50 * index),
      );
  }

  Widget _buildMessageWithHighlight(BuildContext context) {
    final message = advice.message;
    final highlight = advice.highlight;

    if (highlight == null || !message.contains(highlight)) {
      return Text(
        message,
        style: AppTypography.bodyMedium(context).copyWith(
          height: 1.5,
        ),
      );
    }

    final parts = message.split(highlight);
    final spans = <TextSpan>[];

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i]));
      }
      
      if (i < parts.length - 1) {
        spans.add(
          TextSpan(
            text: highlight,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(
        style: AppTypography.bodyMedium(context).copyWith(
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }
}
