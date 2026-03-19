import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';

class MonthSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const MonthSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _AnimatedArrowButton(
            icon: Icons.chevron_left_rounded,
            onPressed: () {
              HapticFeedback.selectionClick();
              _onPreviousMonth();
            },
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                DateFormatter.formatShortMonthYear(selectedDate),
                key: ValueKey(selectedDate),
                style: AppTypography.titleMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          _AnimatedArrowButton(
            icon: Icons.chevron_right_rounded,
            onPressed: () {
              HapticFeedback.selectionClick();
              _onNextMonth();
            },
          ),
        ],
      ),
    );
  }

  void _onPreviousMonth() {
    final newDate = DateTime(
      selectedDate.year,
      selectedDate.month - 1,
    );
    onDateChanged(newDate);
  }

  void _onNextMonth() {
    final newDate = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
    );
    onDateChanged(newDate);
  }
}

class _AnimatedArrowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _AnimatedArrowButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_AnimatedArrowButton> createState() => _AnimatedArrowButtonState();
}

class _AnimatedArrowButtonState extends State<_AnimatedArrowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            widget.icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
