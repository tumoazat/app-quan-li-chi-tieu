# 📊 HƯỚNG DẪN CHO NGƯỜI 2 - TRANSACTIONS & STATISTICS

## 👤 Trách Nhiệm của Bạn

**Nguyễn Văn An** - TRANSACTIONS & STATISTICS

### Công việc chính:

1. ✅ **Transaction CRUD** - Create, Read, Update, Delete giao dịch
2. ✅ **Statistics & Analytics** - Tính toán và hiển thị thống kê
3. ✅ **Charts & Visualization** - Biểu đồ chi tiêu
4. ✅ **Transaction List** - Danh sách giao dịch với filter

---

## 📁 Cấu Trúc File Đã Tạo

```
lib/
├── data/
│   ├── models/
│   │   └── transaction_model.dart ✅ (Model Transaction)
│   ├── services/
│   │   └── transaction_service.dart ✅ (CRUD + Firestore)
├── core/
│   ├── constants/
│   │   └── categories.dart ✅ (Categories + Icons + Colors)
│   ├── utils/
│   │   └── currency_formatter.dart ✅ (Formatters)
├── providers/
│   ├── transaction_provider.dart ✅ (State Management - Riverpod)
│   ├── statistics_provider.dart ✅ (Statistics Calculations)
├── presentation/
│   ├── transactions/
│   │   ├── transaction_list_screen.dart ✅ (List + Add + Edit)
│   │   └── transaction_widgets.dart ✅ (Reusable Widgets)
│   ├── statistics/
│   │   └── statistics_screen.dart ✅ (Dashboard + Charts)
```

---

## 🚀 Cách Sử Dụng

### 1️⃣ Transaction Model

**File:** [lib/data/models/transaction_model.dart](lib/data/models/transaction_model.dart)

```dart
// Tạo transaction mới
final transaction = Transaction(
  userId: 'user_123',
  type: TransactionType.expense,
  amount: -50000, // Dương = income, Âm = expense
  category: 'Ăn uống',
  description: 'Trưa ở nhà hàng',
  date: DateTime.now(),
);

// Convert to Map
final map = transaction.toMap();

// From Map
final tx = Transaction.fromMap(map);
```

---

### 2️⃣ Transaction Service (Firestore)

**File:** [lib/data/services/transaction_service.dart](lib/data/services/transaction_service.dart)

```dart
final service = TransactionService();

// ✅ CREATE
await service.createTransaction(transaction);

// ✅ READ
final tx = await service.getTransaction('tx_id');
final txs = await service.getUserTransactions('user_123');

// ✅ READ with filters
final filtered = await service.getTransactionsByDateRange(
  userId: 'user_123',
  startDate: DateTime(2026, 3, 1),
  endDate: DateTime(2026, 3, 31),
);

// ✅ UPDATE
await service.updateTransaction(transaction);

// ✅ DELETE
await service.deleteTransaction('tx_id');

// ✅ Stream real-time
service.streamUserTransactions('user_123').listen((txs) {
  print('Transactions updated: $txs');
});
```

---

### 3️⃣ Transaction Provider (Riverpod State)

**File:** [lib/providers/transaction_provider.dart](lib/providers/transaction_provider.dart)

```dart
// ✅ Lấy danh sách transactions (real-time)
final transactions = ref.watch(transactionsStreamProvider);

transactions.when(
  data: (txs) => _buildList(txs),
  loading: () => LoadingWidget(),
  error: (err, st) => ErrorWidget(error: err),
);

// ✅ Thêm transaction
await ref.read(transactionNotifierProvider.notifier)
  .addTransaction(transaction);

// ✅ Cập nhật
await ref.read(transactionNotifierProvider.notifier)
  .updateTransaction(transaction);

// ✅ Xóa
await ref.read(transactionNotifierProvider.notifier)
  .deleteTransaction('tx_id');

// ✅ Filter
ref.read(transactionNotifierProvider.notifier)
  .setFilterCategory('Ăn uống');

// ✅ Lấy thống kê
final income = ref.watch(totalIncomeProvider);
final expense = ref.watch(totalExpenseProvider);
final balance = ref.watch(balanceProvider);
```

---

### 4️⃣ Statistics Provider

**File:** [lib/providers/statistics_provider.dart](lib/providers/statistics_provider.dart)

```dart
// ✅ Tổng quát thống kê
final stats = ref.watch(statisticsProvider);

stats.when(
  data: (data) => Column(
    children: [
      Text('Total Income: ${data.totalIncome}'),
      Text('Total Expense: ${data.totalExpense}'),
      Text('Category Expenses: ${data.categoryExpenses}'),
      Text('Average Daily: ${data.averageDailyExpense}'),
      Text('Top Categories: ${data.topCategories}'),
    ],
  ),
  loading: () => LoadingWidget(),
  error: (e, st) => ErrorWidget(),
);

// ✅ Monthly Comparison
final monthly = ref.watch(monthlyComparisonProvider);
// Returns: {'2026-03': (income, expense)}

// ✅ Category Percentage
final percentages = ref.watch(categoryPercentageProvider);
// Returns: {'Ăn uống': 25.5, 'Giao thông': 15.2}

// ✅ Spending Trend (30 ngày)
final trend = ref.watch(spendingTrendProvider);
// Returns: [amount1, amount2, ...] (30 values)

// ✅ Recent transactions
final recent = ref.watch(recentTransactionsProvider);

// ✅ By month
final byMonth = ref.watch(transactionsByMonthProvider(DateTime.now()));
```

---

### 5️⃣ Transaction List Screen

**File:** [lib/presentation/transactions/transaction_list_screen.dart](lib/presentation/transactions/transaction_list_screen.dart)

```dart
// Sử dụng trong navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const TransactionListScreen(),
  ),
);
```

**Features:**

- ✅ Hiển thị danh sách transactions
- ✅ Filter by category/type/date
- ✅ Add new transaction (AddTransactionScreen)
- ✅ Edit transaction (EditTransactionScreen)
- ✅ Delete transaction
- ✅ Real-time updates

---

### 6️⃣ Statistics Screen

**File:** [lib/presentation/statistics/statistics_screen.dart](lib/presentation/statistics/statistics_screen.dart)

```dart
// Sử dụng
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const StatisticsScreen(),
  ),
);
```

**Features:**

- ✅ Summary cards (Income/Expense/Balance)
- ✅ Pie chart - Category breakdown
- ✅ Line chart - Spending trend (30 ngày)
- ✅ Top categories with percentage
- ✅ Recent transactions list

---

### 7️⃣ Category Constants

**File:** [lib/core/constants/categories.dart](lib/core/constants/categories.dart)

```dart
// Icons & Colors
CategoryIcon.getIcon('Ăn uống'); // '🍔'
CategoryColor.getColor('Ăn uống'); // Color

// Categories
ExpenseCategory.categories; // ['Ăn uống', 'Giao thông', ...]
ExpenseCategory.incomeCategories; // ['Lương', 'Thưởng', ...]
ExpenseCategory.getCategories(isIncome: false);

// Filters
TransactionFilters.getMonthStart(date);
TransactionFilters.getMonthEnd(date);
TransactionFilters.getQuarterRange(date);
TransactionFilters.getYearRange(date);
```

---

### 8️⃣ Currency Formatter

**File:** [lib/core/utils/currency_formatter.dart](lib/core/utils/currency_formatter.dart)

```dart
CurrencyFormatter.format(1500000); // '1.500.000đ'
CurrencyFormatter.formatCompact(1500000); // '1.5tr'
CurrencyFormatter.formatWithSign(50000); // '+50.000đ'

CurrencyFormatter.formatDate(date); // '20/03/2026'
CurrencyFormatter.formatTime(date); // '14:30'
CurrencyFormatter.formatDateTime(date); // '20/03/2026 14:30'
CurrencyFormatter.formatRelativeDate(date); // 'Hôm qua'
```

---

## 📝 Quy Tắc Coding

### ✅ Naming Convention

```dart
// Classes
class TransactionNotifier { }

// Methods
Future<void> addTransaction(Transaction tx)
List<Transaction> getTransactionsByMonth(DateTime month)

// Variables
final userId = 'user_123';
final selectedCategory = 'Ăn uống';
```

### ✅ Widget Structure

```dart
class MyTransactionWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsStreamProvider);

    return transactions.when(
      data: (txs) => _buildList(txs),
      loading: () => LoadingWidget(),
      error: (err, st) => ErrorWidget(error: err),
    );
  }
}
```

### ✅ Error Handling

```dart
try {
  await service.createTransaction(tx);
  print('✅ Transaction created');
} on FirebaseException catch (e) {
  throw TransactionException('Firebase error: ${e.message}');
} catch (e) {
  throw TransactionException('Unexpected error: $e');
}
```

---

## 🔧 Git Workflow

```bash
# 1. Tạo branch
git checkout develop
git pull origin develop
git checkout -b feature/an/transaction-crud

# 2. Commit
git add .
git commit -m "[FEAT] (an): Thêm CRUD transaction"

# 3. Push
git push origin feature/an/transaction-crud

# 4. Tạo Pull Request trên GitHub
# - Base: develop
# - Compare: feature/an/transaction-crud

# 5. Sau khi approve, merge với develop
git checkout develop
git pull origin develop
git merge --squash feature/an/transaction-crud
git commit -m "[FEAT] (an): Thêm CRUD transaction"
git push origin develop

# 6. Xóa branch
git push origin --delete feature/an/transaction-crud
git branch -d feature/an/transaction-crud
```

---

## 🚫 Dependencies Cần Thiết

Đảm bảo trong `pubspec.yaml` có:

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  cloud_firestore: ^5.6.5
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  fl_chart: ^6.1.0
  intl: ^0.19.0
  uuid: ^4.5.1
```

Nếu thiếu, chạy:

```bash
flutter pub get
```

---

## ⚠️ Common Issues

### 1. Import Error

```dart
// ❌ Sai
import 'transaction_model.dart';

// ✅ Đúng
import '../../data/models/transaction_model.dart';
```

### 2. Riverpod Generator

Nếu gặp lỗi về `.g.dart` files:

```bash
# Chạy builder
flutter pub run build_runner build

# Hoặc watch mode
flutter pub run build_runner watch
```

### 3. Firestore Rules

Hãy thông báo cho Person 1 (TÙNG) để setup Firestore rules:

```
match /transactions/{document=**} {
  allow read, write: if request.auth.uid == resource.data.userId;
}
```

---

## 📞 Liên Hệ

- **Slack/Teams**: Hỏi bất cứ lúc nào
- **GitHub Issues**: Track bugs & tasks
- **Code Review**: 24 hour response

---

## ✨ Next Steps

1. **Setup development environment**

   ```bash
   flutter pub get
   flutter pub run build_runner build
   ```

2. **Test transaction creation**
   - Build AddTransactionScreen
   - Thử thêm giao dịch

3. **Test statistics**
   - Verify pie chart
   - Verify line chart

4. **Collaborate with Person 1**
   - Setup Firebase auth integration
   - Get userId from auth provider

5. **Create Pull Request**
   - Submit for review
   - Merge to develop

---

**Happy Coding! 🚀**
