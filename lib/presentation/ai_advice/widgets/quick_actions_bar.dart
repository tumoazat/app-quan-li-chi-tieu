import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/chat_message.dart';

class QuickActionsBar extends StatelessWidget {
  final void Function(QuickAction action) onActionTap;

  const QuickActionsBar({
    super.key,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '✨ Gợi ý cho bạn',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: QuickAction.defaults.length,
              itemBuilder: (context, index) {
                final action = QuickAction.defaults[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _QuickActionChip(
                    action: action,
                    onTap: () => onActionTap(action),
                    index: index,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final QuickAction action;
  final VoidCallback onTap;
  final int index;

  const _QuickActionChip({
    required this.action,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: action.color.withOpacity(0.4),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(22),
            color: action.color.withOpacity(isDark ? 0.15 : 0.08),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(action.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : action.color,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
        .fadeIn(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: 50 * index),
        )
        .slideX(
          begin: 0.2,
          end: 0,
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: 50 * index),
        );
  }
}
