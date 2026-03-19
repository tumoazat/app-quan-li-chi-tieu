import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_typography.dart';

class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with bounce
            Text(
              icon,
              style: const TextStyle(fontSize: 80),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 1.0,
                  end: 1.1,
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: AppTypography.headlineMedium(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              subtitle,
              style: AppTypography.bodyMedium(context).copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            
            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Predefined empty states
  static Widget noTransactions({VoidCallback? onAdd}) {
    return EmptyState(
      icon: '📝',
      title: 'Chưa có giao dịch',
      subtitle: 'Bắt đầu ghi chép thu chi của bạn ngay hôm nay',
      actionLabel: onAdd != null ? 'Thêm giao dịch' : null,
      onAction: onAdd,
    );
  }

  static Widget noData() {
    return const EmptyState(
      icon: '📊',
      title: 'Chưa có dữ liệu',
      subtitle: 'Dữ liệu sẽ hiển thị khi bạn có giao dịch',
    );
  }

  static Widget error({String? message}) {
    return EmptyState(
      icon: '⚠️',
      title: 'Đã xảy ra lỗi',
      subtitle: message ?? 'Vui lòng thử lại sau',
    );
  }

  static Widget noResults({String? query}) {
    return EmptyState(
      icon: '🔍',
      title: 'Không tìm thấy kết quả',
      subtitle: query != null 
          ? 'Không tìm thấy kết quả cho "$query"'
          : 'Thử tìm kiếm với từ khóa khác',
    );
  }

  static Widget noCategories() {
    return const EmptyState(
      icon: '📂',
      title: 'Chưa có danh mục',
      subtitle: 'Thêm danh mục để phân loại giao dịch',
    );
  }
}
