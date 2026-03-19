import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/models/transaction_model.dart';
import 'auth_provider.dart';

// Transaction repository provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// Transactions stream provider for a specific month
// Key format: "year-month" e.g. "2026-2"
final transactionsStreamProvider = StreamProvider.autoDispose
    .family<List<TransactionModel>, String>((ref, monthKey) {
  final repository = ref.watch(transactionRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return Stream.value([]);
  }

  final parts = monthKey.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);

  // Keep alive to prevent premature disposal
  ref.keepAlive();
  
  return repository.getTransactionsByMonth(user.uid, year, month);
});

// Recent transactions provider (last 5)
final recentTransactionsProvider = StreamProvider.autoDispose<List<TransactionModel>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return Stream.value([]);
  }

  return repository.getRecentTransactions(user.uid, limit: 5);
});

// All transactions for current user
final allTransactionsProvider = StreamProvider.autoDispose<List<TransactionModel>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return Stream.value([]);
  }

  return repository.getTransactions(user.uid);
});

// Add transaction provider
final addTransactionProvider = FutureProvider.autoDispose
    .family<String, TransactionModel>((ref, transaction) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.addTransaction(transaction);
});

// Update transaction provider
final updateTransactionProvider = FutureProvider.autoDispose
    .family<void, TransactionModel>((ref, transaction) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.updateTransaction(transaction);
});

// Delete transaction provider
final deleteTransactionProvider = FutureProvider.autoDispose
    .family<void, Map<String, String>>((ref, params) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.deleteTransaction(
    params['userId']!,
    params['transactionId']!,
  );
});

// Get transactions by category
final transactionsByCategoryProvider = StreamProvider.autoDispose
    .family<List<TransactionModel>, Map<String, dynamic>>((ref, params) {
  final repository = ref.watch(transactionRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return Stream.value([]);
  }

  final categoryId = params['categoryId'] as String;
  final startDate = params['startDate'] as DateTime?;
  final endDate = params['endDate'] as DateTime?;

  return repository.getTransactionsByCategory(
    user.uid,
    categoryId,
    startDate: startDate,
    endDate: endDate,
  );
});
