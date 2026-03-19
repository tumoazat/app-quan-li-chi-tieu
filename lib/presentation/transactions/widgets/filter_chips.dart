import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class FilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const FilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AnimatedFilterChip(
            value: 'all',
            label: '📋 Tất cả',
            isSelected: selectedFilter == 'all',
            onSelected: () {
              HapticFeedback.selectionClick();
              onFilterChanged('all');
            },
          ),
          const SizedBox(width: 8),
          _AnimatedFilterChip(
            value: 'expense',
            label: '💸 Chi tiêu',
            isSelected: selectedFilter == 'expense',
            onSelected: () {
              HapticFeedback.selectionClick();
              onFilterChanged('expense');
            },
          ),
          const SizedBox(width: 8),
          _AnimatedFilterChip(
            value: 'income',
            label: '💰 Thu nhập',
            isSelected: selectedFilter == 'income',
            onSelected: () {
              HapticFeedback.selectionClick();
              onFilterChanged('income');
            },
          ),
        ],
      ),
    );
  }
}

class _AnimatedFilterChip extends StatelessWidget {
  final String value;
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _AnimatedFilterChip({
    required this.value,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
