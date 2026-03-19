import 'package:flutter/material.dart';

import '../../core/utils/date_formatter.dart';
import '../../data/models/expense.dart';
import 'primary_button.dart';

/// File name: add_expense_sheet.dart
/// Author: Lê Duy Khánh
/// Created: 2026-03-19
/// Description: Shared bottom sheet for adding expense.
class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key, required this.onSave});

  final ValueChanged<Expense> onSave;

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Nội dung chi tiêu'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Số tiền'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildCategoryDropdown()),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickDate,
                  child: Text(DateFormatter.toDisplay(_selectedDate)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(label: 'Lưu chi tiêu', onPressed: _submit),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<ExpenseCategory>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(labelText: 'Danh mục'),
      items: ExpenseCategory.values
          .map(
            (category) => DropdownMenuItem<ExpenseCategory>(
              value: category,
              child: Text(_categoryLabel(category)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _selectedCategory = value;
        });
      },
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _selectedDate,
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập dữ liệu hợp lệ.')),
      );
      return;
    }

    widget.onSave(
      Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
      ),
    );

    Navigator.of(context).pop();
  }

  String _categoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Ăn uống';
      case ExpenseCategory.transport:
        return 'Di chuyển';
      case ExpenseCategory.shopping:
        return 'Mua sắm';
      case ExpenseCategory.bills:
        return 'Hóa đơn';
      case ExpenseCategory.entertainment:
        return 'Giải trí';
      case ExpenseCategory.other:
        return 'Khác';
    }
  }
}
