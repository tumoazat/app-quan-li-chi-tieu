/// File name: transaction_list_screen.dart
/// Author: Nguyễn Văn An
/// Created: 2026-03-20
/// Description: Display list of transactions with filters
///
/// Responsibilities:
/// - Display transactions list
/// - Filter by category/type/date
/// - Navigate to add/edit screens

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/transaction_provider.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _filterCategory;
  TransactionType? _filterType;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý giao dịch'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          // Apply filters
          var filtered = transactions;

          if (_filterCategory != null) {
            filtered = filtered
                .where((tx) => tx.category == _filterCategory)
                .toList();
          }

          if (_filterType != null) {
            filtered = filtered.where((tx) => tx.type == _filterType).toList();
          }

          if (_filterStartDate != null && _filterEndDate != null) {
            filtered = filtered
                .where((tx) =>
                    tx.date.isAfter(_filterStartDate!) &&
                    tx.date.isBefore(_filterEndDate!.add(const Duration(days: 1))))
                .toList();
          }

          if (filtered.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final tx = filtered[index];
              return _TransactionTile(
                transaction: tx,
                onTap: () => _editTransaction(tx),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Lỗi: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc giao dịch'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type filter
              DropdownButtonFormField<TransactionType?>(
                value: _filterType,
                hint: const Text('Loại giao dịch'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Tất cả'),
                  ),
                  ...TransactionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _filterType = value);
                },
              ),
              const SizedBox(height: 16),
              // Category filter
              DropdownButtonFormField<String?>(
                value: _filterCategory,
                hint: const Text('Danh mục'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Tất cả'),
                  ),
                  ...ExpenseCategory.categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text('${CategoryIcon.getIcon(cat)} $cat'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _filterCategory = value);
                },
              ),
              const SizedBox(height: 16),
              // Date range
              Text('Từ: ${CurrencyFormatter.formatDate(_filterStartDate ?? DateTime.now())}'),
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _filterStartDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _filterStartDate = date);
                  }
                },
                child: const Text('Chọn ngày bắt đầu'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterType = null;
                _filterCategory = null;
                _filterStartDate = null;
                _filterEndDate = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Xóa bộ lọc'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Xong'),
          ),
        ],
      ),
    );
  }

  void _addNewTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    );
  }

  void _editTransaction(Transaction tx) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transaction: tx),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text('Không có giao dịch nào'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _addNewTransaction,
            child: const Text('Thêm giao dịch'),
          ),
        ],
      ),
    );
  }
}

/// Transaction tile widget
class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final icon = CategoryIcon.getIcon(transaction.category);
    final color = CategoryColor.getColor(transaction.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withAlpha(50),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(
          transaction.category,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.description ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              CurrencyFormatter.formatDate(transaction.date),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Text(
          CurrencyFormatter.formatWithSign(transaction.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// ============ ADD TRANSACTION SCREEN ============

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  TransactionType _type = TransactionType.expense;
  String _category = 'Ăn uống';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ExpenseCategory.getCategories(isIncome: _type == TransactionType.income);

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm giao dịch')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            SegmentedButton<TransactionType>(
              segments: const <ButtonSegment<TransactionType>>[
                ButtonSegment<TransactionType>(
                  value: TransactionType.expense,
                  label: Text('Chi tiêu'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment<TransactionType>(
                  value: TransactionType.income,
                  label: Text('Thu nhập'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: <TransactionType>{_type},
              onSelectionChanged: (Set<TransactionType> newSelection) {
                setState(() {
                  _type = newSelection.first;
                  _category = categories.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              items: categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text('${CategoryIcon.getIcon(cat)} $cat'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
              decoration: InputDecoration(
                labelText: 'Danh mục',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
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
                }
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleAddTransaction,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Thêm giao dịch'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddTransaction() async {
    // Validate
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final tx = Transaction(
        userId: 'user_123', // TODO: Get from auth provider
        type: _type,
        amount: _type == TransactionType.income ? amount : -amount,
        category: _category,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        date: _selectedDate,
      );

      await ref.read(transactionNotifierProvider.notifier).addTransaction(tx);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Thêm giao dịch thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ============ EDIT TRANSACTION SCREEN ============

class EditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction transaction;

  const EditTransactionScreen({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState
    extends ConsumerState<EditTransactionScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late TransactionType _type;
  late String _category;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _type = widget.transaction.type;
    _category = widget.transaction.category;
    _selectedDate = widget.transaction.date;
    _amountController =
        TextEditingController(text: widget.transaction.amount.abs().toString());
    _descriptionController =
        TextEditingController(text: widget.transaction.description);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ExpenseCategory.getCategories(isIncome: _type == TransactionType.income);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa giao dịch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _handleDeleteTransaction,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            SegmentedButton<TransactionType>(
              segments: const <ButtonSegment<TransactionType>>[
                ButtonSegment<TransactionType>(
                  value: TransactionType.expense,
                  label: Text('Chi tiêu'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment<TransactionType>(
                  value: TransactionType.income,
                  label: Text('Thu nhập'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: <TransactionType>{_type},
              onSelectionChanged: (Set<TransactionType> newSelection) {
                setState(() {
                  _type = newSelection.first;
                  _category = categories.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              items: categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text('${CategoryIcon.getIcon(cat)} $cat'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
              decoration: InputDecoration(
                labelText: 'Danh mục',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
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
                }
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSaveTransaction,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu giao dịch'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSaveTransaction() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final updated = widget.transaction.copyWith(
        type: _type,
        amount: _type == TransactionType.income ? amount : -amount,
        category: _category,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        date: _selectedDate,
      );

      await ref
          .read(transactionNotifierProvider.notifier)
          .updateTransaction(updated);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Cập nhật thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDeleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giao dịch'),
        content: const Text('Bạn chắc chắn muốn xóa giao dịch này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(transactionNotifierProvider.notifier)
            .deleteTransaction(widget.transaction.id);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Xóa thành công')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Lỗi: $e')),
          );
        }
      }
    }
  }
}
