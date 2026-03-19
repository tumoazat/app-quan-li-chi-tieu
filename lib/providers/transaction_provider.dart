/// File name: transaction_provider.dart
/// Author: Nguyễn Văn An
/// Created: 2026-03-20
/// Description: Riverpod providers for transaction state management
///
/// Responsibilities:
/// - Transaction CRUD state management
/// - Stream providers for real-time updates
/// - Current user transaction filtering

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/transaction_model.dart';
import '../data/services/transaction_service.dart';
import '../core/constants/categories.dart';

part 'transaction_provider.g.dart';

// ============ SERVICE PROVIDER ============

/// Singleton TransactionService provider
@riverpod
TransactionService transactionService(Ref ref) {
  return TransactionService();
}

// ============ TRANSACTION STATE ============

/// Transaction State - Lưu trạng thái transaction
class TransactionState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String? filterCategory;
  final TransactionType? filterType;

  TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.filterStartDate,
    this.filterEndDate,
    this.filterCategory,
    this.filterType,
  });

  /// Copy with - Tạo copy với các field được thay đổi
  TransactionState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    String? filterCategory,
    TransactionType? filterType,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterStartDate: filterStartDate ?? this.filterStartDate,
      filterEndDate: filterEndDate ?? this.filterEndDate,
      filterCategory: filterCategory ?? this.filterCategory,
      filterType: filterType ?? this.filterType,
    );
  }

  /// Lọc transactions theo filter
  List<Transaction> get filteredTransactions {
    var filtered = transactions;

    if (filterCategory != null) {
      filtered = filtered.where((tx) => tx.category == filterCategory).toList();
    }

    if (filterType != null) {
      filtered = filtered.where((tx) => tx.type == filterType).toList();
    }

    if (filterStartDate != null && filterEndDate != null) {
      filtered = filtered
          .where((tx) =>
              tx.date.isAfter(filterStartDate!) &&
              tx.date.isBefore(filterEndDate!.add(const Duration(days: 1))))
          .toList();
    }

    return filtered;
  }
}

// ============ TRANSACTION NOTIFIER ============

/// TransactionNotifier - Quản lý transaction state
class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionService _service;
  final String userId;

  TransactionNotifier({
    required TransactionService service,
    required this.userId,
  })  : _service = service,
        super(TransactionState());

  // ✅ CREATE
  /// Tạo giao dịch mới
  Future<void> addTransaction(Transaction transaction) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _service.createTransaction(transaction);

      // Reload transactions
      await _loadTransactions();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ✅ READ
  /// Tải danh sách transactions
  Future<void> _loadTransactions() async {
    try {
      final transactions = await _service.getUserTransactions(userId);
      state = state.copyWith(transactions: transactions);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Lấy transaction theo ID
  Future<Transaction?> getTransaction(String transactionId) async {
    try {
      return await _service.getTransaction(transactionId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Tải transaction theo khoảng thời gian
  Future<void> loadTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        filterStartDate: startDate,
        filterEndDate: endDate,
      );

      final transactions = await _service.getTransactionsByDateRange(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Tải transaction theo category
  Future<void> loadTransactionsByCategory(String category) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        filterCategory: category,
      );

      final transactions = await _service.getTransactionsByCategory(
        userId: userId,
        category: category,
      );

      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ✅ UPDATE
  /// Cập nhật giao dịch
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _service.updateTransaction(transaction);

      // Update trong local state
      final index =
          state.transactions.indexWhere((tx) => tx.id == transaction.id);
      if (index != -1) {
        final updated = state.transactions;
        updated[index] = transaction;
        state = state.copyWith(transactions: [...updated]);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ✅ DELETE
  /// Xóa giao dịch
  Future<void> deleteTransaction(String transactionId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _service.deleteTransaction(transactionId);

      // Xóa từ local state
      final updated = state.transactions
          .where((tx) => tx.id != transactionId)
          .toList();

      state = state.copyWith(
        transactions: updated,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ✅ FILTER
  /// Đặt filter theo category
  void setFilterCategory(String? category) {
    state = state.copyWith(filterCategory: category);
  }

  /// Đặt filter theo type
  void setFilterType(TransactionType? type) {
    state = state.copyWith(filterType: type);
  }

  /// Đặt filter theo date range
  void setFilterDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(
      filterStartDate: startDate,
      filterEndDate: endDate,
    );
  }

  /// Reset tất cả filters
  void resetFilters() {
    state = state.copyWith(
      filterCategory: null,
      filterType: null,
      filterStartDate: null,
      filterEndDate: null,
    );
  }

  /// Load initial data
  Future<void> init() async {
    await _loadTransactions();
  }
}

// ============ PROVIDERS ============

/// Current user ID provider (cần được implement bởi Person 1)
@riverpod
String currentUserId(Ref ref) {
  // TODO: Lấy từ auth provider của Person 1
  return 'user_123';
}

/// Transaction notifier provider
@riverpod
StateNotifier<TransactionState> transactionNotifier(Ref ref) {
  final service = ref.watch(transactionServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  final notifier = TransactionNotifier(
    service: service,
    userId: userId,
  );

  // Khởi tạo dữ liệu
  notifier.init();

  return notifier;
}

/// Transaction state provider
@riverpod
TransactionState transactionState(Ref ref) {
  return ref.watch(transactionNotifierProvider);
}

/// Stream provider cho real-time updates
@riverpod
Stream<List<Transaction>> transactionsStreamProvider(Ref ref) {
  final service = ref.watch(transactionServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  return service.streamUserTransactions(userId);
}

/// Filtered transactions provider
@riverpod
List<Transaction> filteredTransactionsProvider(Ref ref) {
  final state = ref.watch(transactionStateProvider);
  return state.filteredTransactions;
}

/// Statistics providers
@riverpod
double totalIncomeProvider(Ref ref) {
  final transactions = ref.watch(transactionsStreamProvider);

  return transactions.when(
    data: (txs) => txs
        .where((tx) => tx.type == TransactionType.income)
        .fold(0, (sum, tx) => sum + tx.amount),
    loading: () => 0,
    error: (_, __) => 0,
  );
}

@riverpod
double totalExpenseProvider(Ref ref) {
  final transactions = ref.watch(transactionsStreamProvider);

  return transactions.when(
    data: (txs) => txs
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0, (sum, tx) => sum + (tx.amount).abs()),
    loading: () => 0,
    error: (_, __) => 0,
  );
}

@riverpod
double balanceProvider(Ref ref) {
  final income = ref.watch(totalIncomeProvider);
  final expense = ref.watch(totalExpenseProvider);
  return income - expense;
}

/// Get transactions by month
@riverpod
Future<List<Transaction>> transactionsByMonthProvider(
  Ref ref,
  DateTime month,
) async {
  final service = ref.watch(transactionServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  final startDate = DateTime(month.year, month.month, 1);
  final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

  return service.getTransactionsByDateRange(
    userId: userId,
    startDate: startDate,
    endDate: endDate,
  );
}

/// Get category expenses
@riverpod
Future<Map<String, double>> categoryExpensesProvider(Ref ref) async {
  final transactions = ref.watch(transactionsStreamProvider);

  return transactions.when(
    data: (txs) {
      final expenses = <String, double>{};

      for (final tx in txs) {
        if (tx.type == TransactionType.expense) {
          expenses[tx.category] =
              (expenses[tx.category] ?? 0) + tx.amount.abs();
        }
      }

      return expenses;
    },
    loading: () => {},
    error: (_, __) => {},
  );
}
