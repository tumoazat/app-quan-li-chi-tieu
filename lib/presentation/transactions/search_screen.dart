import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';

/// Màn hình tìm kiếm giao dịch nâng cao
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  TransactionType? _selectedType; // income, expense, hoặc null
  DateTimeRange? _dateRange;
  RangeValues _amountRange = const RangeValues(0, 10000000);

  // Debounce timer
  DateTime? _lastSearchTime;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Debounce 300ms
    _lastSearchTime = DateTime.now();
    final searchTime = _lastSearchTime;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_lastSearchTime == searchTime && mounted) {
        setState(() => _searchQuery = value.toLowerCase());
      }
    });
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions) {
    return transactions.where((t) {
      // Lọc theo text search (note hoặc categoryId)
      if (_searchQuery.isNotEmpty) {
        final matchNote = (t.note ?? '').toLowerCase().contains(_searchQuery);
        final matchCategory = t.categoryId.toLowerCase().contains(_searchQuery);
        if (!matchNote && !matchCategory) return false;
      }

      // Lọc theo loại giao dịch
      if (_selectedType != null && t.type != _selectedType) return false;

      // Lọc theo khoảng thời gian
      if (_dateRange != null) {
        if (t.date.isBefore(_dateRange!.start) || t.date.isAfter(_dateRange!.end)) {
          return false;
        }
      }

      // Lọc theo khoảng số tiền
      if (t.amount < _amountRange.start || t.amount > _amountRange.end) return false;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final transactionsAsync = ref.watch(
      transactionsStreamProvider('${now.year}-${now.month}'),
    );

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm giao dịch...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Chip lọc đang active
          if (_selectedType != null || _dateRange != null)
            _buildActiveFilters(),

          // Kết quả tìm kiếm
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                final filtered = _filterTransactions(transactions);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Không tìm thấy giao dịch', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionItem(filtered[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (_selectedType != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_selectedType == TransactionType.income ? 'Thu nhập' : 'Chi tiêu'),
                selected: true,
                onSelected: (_) => setState(() => _selectedType = null),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => _selectedType = null),
              ),
            ),
          if (_dateRange != null)
            FilterChip(
              label: Text(
                '${DateFormatter.formatVietnamese(_dateRange!.start)} - ${DateFormatter.formatVietnamese(_dateRange!.end)}',
              ),
              selected: true,
              onSelected: (_) => setState(() => _dateRange = null),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => setState(() => _dateRange = null),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final isExpense = transaction.isExpense;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isExpense
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        child: Icon(
          isExpense ? Icons.arrow_upward : Icons.arrow_downward,
          color: isExpense ? Colors.red : Colors.green,
        ),
      ),
      title: Text(
        (transaction.note == null || transaction.note!.isEmpty)
            ? transaction.categoryId
            : transaction.note!,
      ),
      subtitle: Text(DateFormatter.formatVietnamese(transaction.date)),
      trailing: Text(
        '${isExpense ? '-' : '+'}${CurrencyFormatter.formatVND(transaction.amount)}',
        style: TextStyle(
          color: isExpense ? Colors.red : Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bộ lọc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Lọc theo loại giao dịch
              const Text('Loại giao dịch'),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Tất cả'),
                    selected: _selectedType == null,
                    onSelected: (_) {
                      setModalState(() {});
                      setState(() => _selectedType = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Thu nhập'),
                    selected: _selectedType == TransactionType.income,
                    onSelected: (_) {
                      setModalState(() {});
                      setState(() => _selectedType = TransactionType.income);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Chi tiêu'),
                    selected: _selectedType == TransactionType.expense,
                    onSelected: (_) {
                      setModalState(() {});
                      setState(() => _selectedType = TransactionType.expense);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lọc theo khoảng số tiền
              Text(
                'Số tiền: ${CurrencyFormatter.formatVND(_amountRange.start)} - ${CurrencyFormatter.formatVND(_amountRange.end)}',
              ),
              RangeSlider(
                values: _amountRange,
                min: 0,
                max: 10000000,
                divisions: 100,
                onChanged: (values) {
                  setModalState(() {});
                  setState(() => _amountRange = values);
                },
              ),
              const SizedBox(height: 16),

              // Lọc theo khoảng ngày
              Row(
                children: [
                  const Text('Khoảng thời gian: '),
                  TextButton(
                    onPressed: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (range != null) {
                        setModalState(() {});
                        setState(() => _dateRange = range);
                      }
                    },
                    child: Text(_dateRange == null ? 'Chọn ngày' : 'Đã chọn'),
                  ),
                  if (_dateRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        setModalState(() {});
                        setState(() => _dateRange = null);
                      },
                    ),
                ],
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
