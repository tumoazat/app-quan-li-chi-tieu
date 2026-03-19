import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/category_data.dart';

class PieChartSection extends StatefulWidget {
  final Map<String, double> categoryBreakdown;
  final double totalExpense;

  const PieChartSection({
    super.key,
    required this.categoryBreakdown,
    required this.totalExpense,
  });

  @override
  State<PieChartSection> createState() => _PieChartSectionState();
}

class _PieChartSectionState extends State<PieChartSection> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort categories by amount descending
    final sortedCategories = widget.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiêu theo danh mục',
              style: AppTypography.headlineMedium(context),
            ),
            const SizedBox(height: 24),
            
            // Pie Chart
            Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    sections: _getSections(sortedCategories),
                  ),
                ),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            
            const SizedBox(height: 24),
            
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: sortedCategories.asMap().entries.map((entry) {
                final index = entry.key;
                final categoryId = entry.value.key;
                final amount = entry.value.value;
                final category = CategoryModel.findById(categoryId);
                final percentage = (amount / widget.totalExpense) * 100;

                return _LegendItem(
                  color: category?.color ?? Colors.grey,
                  label: category?.name ?? 'Khác',
                  percentage: percentage,
                  isSelected: touchedIndex == index,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getSections(
      List<MapEntry<String, double>> sortedCategories) {
    return sortedCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final categoryId = entry.value.key;
      final amount = entry.value.value;
      final isTouched = index == touchedIndex;
      final category = CategoryModel.findById(categoryId);
      final percentage = (amount / widget.totalExpense) * 100;

      return PieChartSectionData(
        color: category?.color ?? Colors.grey,
        value: amount,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 65 : 55,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.5,
      );
    }).toList();
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double percentage;
  final bool isSelected;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.percentage,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ${percentage.toStringAsFixed(1)}%',
          style: AppTypography.bodyMedium(context).copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
