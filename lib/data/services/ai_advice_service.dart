import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/constants/category_data.dart';

enum AdviceType { positive, insight, tip, warning, alert }

class AdviceItem {
  final AdviceType type;
  final String emoji;
  final String title;
  final String message;
  final String? highlight;
  final Color borderColor;

  AdviceItem({
    required this.type,
    required this.emoji,
    required this.title,
    required this.message,
    this.highlight,
    required this.borderColor,
  });
}

class AiAdviceService {
  // Analyze transactions and provide advice
  Future<List<AdviceItem>> analyzeTransactions({
    required List<TransactionModel> transactions,
    required double monthlyBudget,
  }) async {
    final List<AdviceItem> advices = [];

    // Separate income and expenses
    final expenses = transactions.where((t) => t.isExpense).toList();
    final incomes = transactions.where((t) => t.isIncome).toList();

    // Calculate totals
    final totalExpense = expenses.fold<double>(
        0, (sum, t) => sum + t.amount);
    final totalIncome = incomes.fold<double>(
        0, (sum, t) => sum + t.amount);

    // 1. Budget Analysis
    if (monthlyBudget > 0) {
      final budgetUsedPercent = (totalExpense / monthlyBudget) * 100;
      
      if (budgetUsedPercent >= 90) {
        // Alert - over 90%
        advices.add(AdviceItem(
          type: AdviceType.alert,
          emoji: '🚨',
          title: 'Cảnh báo ngân sách!',
          message: 'Bạn đã chi tiêu ${budgetUsedPercent.toStringAsFixed(1)}% ngân sách tháng này. '
              'Hãy cẩn thận với các khoản chi tiêu còn lại!',
          highlight: '${budgetUsedPercent.toStringAsFixed(1)}%',
          borderColor: Colors.red,
        ));
        
        // Calculate daily remaining budget
        final now = DateTime.now();
        final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;
        if (daysLeft > 0) {
          final remaining = monthlyBudget - totalExpense;
          final dailyBudget = remaining / daysLeft;
          advices.add(AdviceItem(
            type: AdviceType.tip,
            emoji: '💰',
            title: 'Ngân sách hàng ngày',
            message: 'Còn $daysLeft ngày trong tháng. Bạn có thể chi tối đa '
                '${CurrencyFormatter.formatVND(dailyBudget)}/ngày.',
            highlight: CurrencyFormatter.formatVND(dailyBudget),
            borderColor: Colors.orange,
          ));
        }
      } else if (budgetUsedPercent >= 70) {
        // Warning - 70-90%
        advices.add(AdviceItem(
          type: AdviceType.warning,
          emoji: '⚠️',
          title: 'Chú ý ngân sách',
          message: 'Bạn đã sử dụng ${budgetUsedPercent.toStringAsFixed(1)}% ngân sách. '
              'Hãy cân nhắc các khoản chi tiêu không cần thiết.',
          highlight: '${budgetUsedPercent.toStringAsFixed(1)}%',
          borderColor: Colors.orange,
        ));
      } else if (budgetUsedPercent < 50) {
        // Positive - under 50%
        advices.add(AdviceItem(
          type: AdviceType.positive,
          emoji: '🎉',
          title: 'Quản lý tốt!',
          message: 'Tuyệt vời! Bạn mới chỉ chi ${budgetUsedPercent.toStringAsFixed(1)}% ngân sách. '
              'Tiếp tục duy trì thói quen tốt này!',
          highlight: '${budgetUsedPercent.toStringAsFixed(1)}%',
          borderColor: Colors.green,
        ));
      }
    }

    // 2. Top Category Analysis
    if (expenses.isNotEmpty) {
      final categoryTotals = <String, double>{};
      for (var expense in expenses) {
        categoryTotals[expense.categoryId] = 
            (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
      }

      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (sortedCategories.isNotEmpty) {
        final topCategory = sortedCategories.first;
        final category = CategoryModel.findById(topCategory.key);
        final percentage = (topCategory.value / totalExpense) * 100;

        advices.add(AdviceItem(
          type: AdviceType.insight,
          emoji: '📊',
          title: 'Danh mục chi nhiều nhất',
          message: 'Bạn chi nhiều nhất cho ${category?.name ?? 'danh mục này'} '
              '(${CurrencyFormatter.formatVND(topCategory.value)}, ${percentage.toStringAsFixed(1)}% tổng chi tiêu).',
          highlight: category?.name,
          borderColor: Colors.blue,
        ));

        // 3. Saving Tip based on top category
        final potentialSaving = topCategory.value * 0.15;
        final monthlySaving = potentialSaving;
        final yearlySaving = potentialSaving * 12;
        
        advices.add(AdviceItem(
          type: AdviceType.tip,
          emoji: '💡',
          title: 'Gợi ý tiết kiệm',
          message: 'Nếu giảm 15% chi tiêu cho ${category?.name ?? 'danh mục này'}, '
              'bạn sẽ tiết kiệm được ${CurrencyFormatter.formatVND(monthlySaving)}/tháng '
              '→ ${CurrencyFormatter.formatVND(yearlySaving)}/năm!',
          highlight: CurrencyFormatter.formatVND(yearlySaving),
          borderColor: Colors.purple,
        ));
      }
    }

    // 4. Spending Habits
    if (expenses.isNotEmpty) {
      final averagePerTransaction = totalExpense / expenses.length;
      advices.add(AdviceItem(
        type: AdviceType.insight,
        emoji: '🔍',
        title: 'Thói quen chi tiêu',
        message: 'Trung bình mỗi giao dịch của bạn là '
            '${CurrencyFormatter.formatVND(averagePerTransaction)}. '
            'Tổng cộng ${expenses.length} giao dịch trong kỳ này.',
        highlight: CurrencyFormatter.formatVND(averagePerTransaction),
        borderColor: Colors.indigo,
      ));
    }

    // 5. Saving Rate
    if (totalIncome > 0) {
      final savingRate = ((totalIncome - totalExpense) / totalIncome) * 100;
      
      if (savingRate >= 20) {
        advices.add(AdviceItem(
          type: AdviceType.positive,
          emoji: '🌟',
          title: 'Tỉ lệ tiết kiệm xuất sắc!',
          message: 'Tuyệt vời! Bạn đang tiết kiệm ${savingRate.toStringAsFixed(1)}% thu nhập. '
              'Đây là một tỷ lệ rất tốt!',
          highlight: '${savingRate.toStringAsFixed(1)}%',
          borderColor: Colors.green,
        ));
      } else if (savingRate >= 10) {
        advices.add(AdviceItem(
          type: AdviceType.insight,
          emoji: '📈',
          title: 'Tỉ lệ tiết kiệm tốt',
          message: 'Bạn đang tiết kiệm ${savingRate.toStringAsFixed(1)}% thu nhập. '
              'Cố gắng tăng lên 20% để đạt mục tiêu tốt hơn!',
          highlight: '${savingRate.toStringAsFixed(1)}%',
          borderColor: Colors.blue,
        ));
      } else if (savingRate < 10 && savingRate >= 0) {
        advices.add(AdviceItem(
          type: AdviceType.warning,
          emoji: '⚠️',
          title: 'Tỉ lệ tiết kiệm thấp',
          message: 'Bạn chỉ tiết kiệm được ${savingRate.toStringAsFixed(1)}% thu nhập. '
              'Hãy cố gắng cắt giảm chi tiêu không cần thiết!',
          highlight: '${savingRate.toStringAsFixed(1)}%',
          borderColor: Colors.orange,
        ));
      } else {
        advices.add(AdviceItem(
          type: AdviceType.alert,
          emoji: '🚨',
          title: 'Chi tiêu vượt thu nhập!',
          message: 'Chi tiêu của bạn đã vượt quá thu nhập! '
              'Hãy xem xét lại các khoản chi và tìm cách cắt giảm ngay.',
          borderColor: Colors.red,
        ));
      }
    }

    // 6. Transaction Frequency
    if (transactions.isNotEmpty) {
      final now = DateTime.now();
      final firstDate = transactions.map((t) => t.date).reduce(
          (a, b) => a.isBefore(b) ? a : b);
      final daysDiff = now.difference(firstDate).inDays + 1;
      final transactionsPerDay = transactions.length / daysDiff;

      if (transactionsPerDay > 5) {
        advices.add(AdviceItem(
          type: AdviceType.insight,
          emoji: '🔄',
          title: 'Tần suất giao dịch cao',
          message: 'Bạn có trung bình ${transactionsPerDay.toStringAsFixed(1)} giao dịch/ngày. '
              'Có thể bạn đang chi tiêu nhỏ nhiều lần.',
          highlight: '${transactionsPerDay.toStringAsFixed(1)} giao dịch/ngày',
          borderColor: Colors.teal,
        ));
      }
    }

    return advices;
  }

  // Compare with previous month
  Future<AdviceItem?> compareWithPreviousMonth({
    required List<TransactionModel> currentMonthTransactions,
    required List<TransactionModel> previousMonthTransactions,
  }) async {
    final currentExpense = currentMonthTransactions
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    
    final previousExpense = previousMonthTransactions
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    if (previousExpense == 0) return null;

    final changePercent = ((currentExpense - previousExpense) / previousExpense) * 100;
    
    if (changePercent > 10) {
      return AdviceItem(
        type: AdviceType.warning,
        emoji: '📈',
        title: 'Chi tiêu tăng so với tháng trước',
        message: 'Chi tiêu tháng này tăng ${changePercent.toStringAsFixed(1)}% so với tháng trước '
            '(${CurrencyFormatter.formatVND(currentExpense - previousExpense)} tăng thêm).',
        highlight: '+${changePercent.toStringAsFixed(1)}%',
        borderColor: Colors.orange,
      );
    } else if (changePercent < -10) {
      return AdviceItem(
        type: AdviceType.positive,
        emoji: '📉',
        title: 'Chi tiêu giảm so với tháng trước',
        message: 'Tuyệt vời! Chi tiêu giảm ${changePercent.abs().toStringAsFixed(1)}% so với tháng trước '
            '(tiết kiệm ${CurrencyFormatter.formatVND((previousExpense - currentExpense).abs())}).',
        highlight: '-${changePercent.abs().toStringAsFixed(1)}%',
        borderColor: Colors.green,
      );
    }

    return null;
  }
}
