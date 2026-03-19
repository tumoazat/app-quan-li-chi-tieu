/// File name: transaction_widgets.dart
/// Author: Nguyễn Văn An
/// Created: 2026-03-20
/// Description: Reusable widgets for transactions
///
/// Responsibilities:
/// - Shared UI components
/// - Custom widgets for transaction display

import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/constants/categories.dart';
import '../../data/models/transaction_model.dart';

/// Widget hiển thị transaction item
class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionItem({
    Key? key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final icon = CategoryIcon.getIcon(transaction.category);
    final color = CategoryColor.getColor(transaction.category);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(50),
        child: Text(icon, style: const TextStyle(fontSize: 24)),
      ),
      title: Text(transaction.category),
      subtitle: Text(
        CurrencyFormatter.formatRelativeDate(transaction.date),
      ),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          PopupMenuItem(
            onTap: onTap,
            child: const Text('Chỉnh sửa'),
          ),
          PopupMenuItem(
            onTap: onDelete,
            child: const Text('Xóa'),
          ),
        ],
        child: Text(
          CurrencyFormatter.formatWithSign(transaction.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}

/// Widget filter transaction
class TransactionFilterBar extends StatefulWidget {
  final Function(String? category, TransactionType? type) onFilter;

  const TransactionFilterBar({
    Key? key,
    required this.onFilter,
  }) : super(key: key);

  @override
  State<TransactionFilterBar> createState() => _TransactionFilterBarState();
}

class _TransactionFilterBarState extends State<TransactionFilterBar> {
  String? _selectedCategory;
  TransactionType? _selectedType;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            FilterChip(
              label: const Text('Tất cả'),
              selected: _selectedCategory == null && _selectedType == null,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = null;
                  _selectedType = null;
                });
                widget.onFilter(null, null);
              },
            ),
            const SizedBox(width: 8),
            // Type filters
            FilterChip(
              label: const Text('Chi tiêu'),
              selected: _selectedType == TransactionType.expense,
              onSelected: (selected) {
                setState(() {
                  _selectedType =
                      selected ? TransactionType.expense : null;
                });
                widget.onFilter(_selectedCategory, _selectedType);
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Thu nhập'),
              selected: _selectedType == TransactionType.income,
              onSelected: (selected) {
                setState(() {
                  _selectedType = selected ? TransactionType.income : null;
                });
                widget.onFilter(_selectedCategory, _selectedType);
              },
            ),
            const SizedBox(width: 8),
            // Category filters
            ...ExpenseCategory.categories.take(4).map((cat) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('${CategoryIcon.getIcon(cat)} $cat'),
                  selected: _selectedCategory == cat,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? cat : null;
                    });
                    widget.onFilter(_selectedCategory, _selectedType);
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

/// Category selector widget
class CategorySelector extends StatefulWidget {
  final String initialCategory;
  final bool isIncome;
  final Function(String) onCategorySelected;

  const CategorySelector({
    Key? key,
    required this.initialCategory,
    required this.isIncome,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ExpenseCategory.getCategories(isIncome: widget.isIncome);

    return SizedBox(
      height: 100,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = category);
              widget.onCategorySelected(category);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CategoryColor.getColor(category)
                        : CategoryColor.getColor(category).withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    CategoryIcon.getIcon(category),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Money input widget
class MoneyInput extends StatefulWidget {
  final Function(double) onChanged;
  final double initialValue;
  final String label;

  const MoneyInput({
    Key? key,
    required this.onChanged,
    this.initialValue = 0,
    this.label = 'Số tiền',
  }) : super(key: key);

  @override
  State<MoneyInput> createState() => _MoneyInputState();
}

class _MoneyInputState extends State<MoneyInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue == 0 ? '' : widget.initialValue.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      onChanged: (value) {
        if (value.isNotEmpty) {
          widget.onChanged(double.tryParse(value) ?? 0);
        }
      },
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.attach_money),
        suffixText: 'đ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Date picker widget
class DatePickerWidget extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final DateTime initialDate;

  const DatePickerWidget({
    Key? key,
    required this.onDateSelected,
    DateTime? initialDate,
  })  : initialDate = initialDate ?? const DateTime.now(),
        super(key: key);

  @override
  State<DatePickerWidget> createState() => _DatePickerWidgetState();
}

class _DatePickerWidgetState extends State<DatePickerWidget> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Ngày'),
      subtitle: Text(CurrencyFormatter.formatDateFull(_selectedDate)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
          widget.onDateSelected(date);
        }
      },
    );
  }
}
