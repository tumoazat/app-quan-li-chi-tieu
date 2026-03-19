import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CategoryModel {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final String type; // 'expense' or 'income'
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.type,
    this.sortOrder = 0,
  });

  // Default expense categories
  static const List<CategoryModel> defaultExpenseCategories = [
    CategoryModel(
      id: 'expense_food',
      name: 'Ăn uống',
      emoji: '🍕',
      color: AppColors.categoryFood,
      type: 'expense',
      sortOrder: 1,
    ),
    CategoryModel(
      id: 'expense_transport',
      name: 'Di chuyển',
      emoji: '🚗',
      color: AppColors.categoryTransport,
      type: 'expense',
      sortOrder: 2,
    ),
    CategoryModel(
      id: 'expense_shopping',
      name: 'Mua sắm',
      emoji: '🛒',
      color: AppColors.categoryShopping,
      type: 'expense',
      sortOrder: 3,
    ),
    CategoryModel(
      id: 'expense_entertainment',
      name: 'Giải trí',
      emoji: '🎮',
      color: AppColors.categoryEntertainment,
      type: 'expense',
      sortOrder: 4,
    ),
    CategoryModel(
      id: 'expense_education',
      name: 'Giáo dục',
      emoji: '📚',
      color: AppColors.categoryEducation,
      type: 'expense',
      sortOrder: 5,
    ),
    CategoryModel(
      id: 'expense_bills',
      name: 'Hóa đơn',
      emoji: '💡',
      color: AppColors.categoryBills,
      type: 'expense',
      sortOrder: 6,
    ),
    CategoryModel(
      id: 'expense_health',
      name: 'Sức khỏe',
      emoji: '🏥',
      color: AppColors.categoryHealth,
      type: 'expense',
      sortOrder: 7,
    ),
    CategoryModel(
      id: 'expense_coffee',
      name: 'Cà phê',
      emoji: '☕',
      color: AppColors.categoryCoffee,
      type: 'expense',
      sortOrder: 8,
    ),
    CategoryModel(
      id: 'expense_others',
      name: 'Khác',
      emoji: '📦',
      color: AppColors.categoryOthers,
      type: 'expense',
      sortOrder: 9,
    ),
  ];

  // Default income categories
  static const List<CategoryModel> defaultIncomeCategories = [
    CategoryModel(
      id: 'income_salary',
      name: 'Lương',
      emoji: '💰',
      color: AppColors.incomeLight,
      type: 'income',
      sortOrder: 1,
    ),
    CategoryModel(
      id: 'income_freelance',
      name: 'Freelance',
      emoji: '💼',
      color: Color(0xFF3498DB),
      type: 'income',
      sortOrder: 2,
    ),
    CategoryModel(
      id: 'income_investment',
      name: 'Đầu tư',
      emoji: '📈',
      color: Color(0xFFF39C12),
      type: 'income',
      sortOrder: 3,
    ),
    CategoryModel(
      id: 'income_gift',
      name: 'Quà tặng',
      emoji: '🎁',
      color: AppColors.expenseLight,
      type: 'income',
      sortOrder: 4,
    ),
    CategoryModel(
      id: 'income_others',
      name: 'Khác',
      emoji: '📦',
      color: AppColors.categoryOthers,
      type: 'income',
      sortOrder: 5,
    ),
  ];

  // Get all categories
  static List<CategoryModel> get allCategories => [
        ...defaultExpenseCategories,
        ...defaultIncomeCategories,
      ];

  // Get categories by type
  static List<CategoryModel> getCategoriesByType(String type) {
    if (type == 'expense') {
      return defaultExpenseCategories;
    } else if (type == 'income') {
      return defaultIncomeCategories;
    }
    return allCategories;
  }

  // Find category by id
  static CategoryModel? findById(String id) {
    try {
      return allCategories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
}
