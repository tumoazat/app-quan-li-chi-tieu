import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../data/models/transaction_model.dart';
import '../../core/constants/category_data.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../features/ai_categorization/application/categorization_notifier.dart';
import '../shared/gradient_button.dart';
import '../../core/router/app_router.dart';
import '../../core/services/geo_location_service.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionModel? editTransaction;
  
  const AddTransactionSheet({super.key, this.editTransaction});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late TransactionType _type;
  late double _amount;
  String? _categoryId;
  late DateTime _date;
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Initialize with edit transaction data if provided
    if (widget.editTransaction != null) {
      _type = widget.editTransaction!.type;
      _amount = widget.editTransaction!.amount;
      _categoryId = widget.editTransaction!.categoryId;
      _date = widget.editTransaction!.date;
      _noteController.text = widget.editTransaction!.note ?? '';
    } else {
      _type = TransactionType.expense;
      _amount = 0;
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = CategoryModel.getCategoriesByType(
      _type == TransactionType.expense ? 'expense' : 'income',
    );

    if (_categoryId == null && categories.isNotEmpty) {
      _categoryId = categories.first.id;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  
                  // Type selector
                  Center(
                    child: SizedBox(
                      width: 240,
                      height: 40,
                      child: SegmentedButton<TransactionType>(
                        segments: const [
                          ButtonSegment(
                            value: TransactionType.expense,
                            label: Text('Chi tiêu'),
                          ),
                          ButtonSegment(
                            value: TransactionType.income,
                            label: Text('Thu nhập'),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (Set<TransactionType> newSelection) {
                          setState(() {
                            _type = newSelection.first;
                            _categoryId = null;
                          });
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Amount display
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Số tiền',
                          style: AppTypography.bodyMedium(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.formatVND(_amount),
                          style: AppTypography.displayLarge(context).copyWith(
                            color: _type == TransactionType.income
                                ? Colors.green[600]
                                : Colors.red[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAmountKeypad(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Category selector
                  Text(
                    'Danh mục',
                    style: AppTypography.titleMedium(context),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _categoryId == category.id;
                      
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _categoryId = category.id;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected 
                                  ? AppColors.primary 
                                  : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: category.color.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    category.emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                category.name,
                                style: AppTypography.labelSmall(context),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Date picker
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormatter.formatVietnamese(_date),
                            style: AppTypography.titleMedium(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Note field
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.note),
                      hintText: 'Thêm ghi chú...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                    onChanged: _onNoteChanged,
                  ),

                  // AI suggestion chip
                  if (_type == TransactionType.expense)
                    Consumer(
                      builder: (context, ref, _) {
                        final suggestion = ref.watch(categorizationNotifierProvider);
                        if (suggestion == null) return const SizedBox.shrink();
                        final cat = CategoryModel.findById(suggestion.categoryId);
                        if (cat == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Chip(
                                avatar: Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                                label: Text('Gợi ý: ${cat.name}'),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () => ref.read(categorizationNotifierProvider.notifier).dismiss(),
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() => _categoryId = suggestion.categoryId);
                                  ref.read(categorizationNotifierProvider.notifier).dismiss();
                                },
                                child: const Text('Áp dụng'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick action buttons for new features
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Camera OCR button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await context.push(AppRouter.receiptCamera);
                                  if (result != null && result is Map<String, dynamic>) {
                                    setState(() {
                                      _amount = result['amount'] ?? _amount;
                                      if (result['category'] != null) {
                                        final cat = CategoryModel.getCategoriesByType('expense').firstWhere(
                                          (c) => c.name == result['category'],
                                          orElse: () => CategoryModel.getCategoriesByType('expense').first,
                                        );
                                        _categoryId = cat.id;
                                      }
                                      if (result['description'] != null) {
                                        _noteController.text = result['description'];
                                      }
                                    });
                                  }
                                },
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('Chụp', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Voice input button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await context.push(AppRouter.voiceInput);
                                  if (result != null && result is Map<String, dynamic>) {
                                    setState(() {
                                      _amount = result['amount'] ?? _amount;
                                      if (result['category'] != null) {
                                        final cat = CategoryModel.getCategoriesByType('expense').firstWhere(
                                          (c) => c.name == result['category'],
                                          orElse: () => CategoryModel.getCategoriesByType('expense').first,
                                        );
                                        _categoryId = cat.id;
                                      }
                                      if (result['description'] != null) {
                                        _noteController.text = result['description'];
                                      }
                                    });
                                  }
                                },
                                icon: const Icon(Icons.mic, size: 18),
                                label: const Text('Giọng nói', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Geo analytics button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => context.push(AppRouter.geoAnalytics),
                                icon: const Icon(Icons.assessment, size: 18),
                                label: const Text('Thống kê', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  backgroundColor: Colors.teal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Transaction map button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => context.push(AppRouter.transactionMap),
                                icon: const Icon(Icons.map, size: 18),
                                label: const Text('Bản đồ', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  backgroundColor: Colors.deepOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Save button
          Padding(
            padding: const EdgeInsets.all(20),
            child: Opacity(
              opacity: _amount > 0 ? 1.0 : 0.5,
              child: GradientButton(
                label: widget.editTransaction != null ? 'Cập nhật giao dịch' : 'Lưu giao dịch',
                onPressed: _amount > 0 ? _saveTransaction : () {},
                isLoading: _isLoading,
                width: double.infinity,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onNoteChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(categorizationNotifierProvider.notifier).analyze(text);
      }
    });
  }

  Widget _buildAmountKeypad() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('000'),
              _buildKeypadButton('0'),
              _buildKeypadButton('⌫', isDelete: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String value, {bool isDelete = false}) {
    return InkWell(
      onTap: () => _onKeypadTap(value, isDelete),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 72,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDelete 
              ? Colors.red.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          value,
          style: AppTypography.titleLarge(context).copyWith(
            color: isDelete ? Colors.red : null,
          ),
        ),
      ),
    );
  }

  void _onKeypadTap(String value, bool isDelete) {
    setState(() {
      if (isDelete) {
        _amount = (_amount / 10).floor().toDouble();
      } else {
        final increment = value == '000' ? 1000 : double.parse(value);
        _amount = (_amount * 10) + increment;
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_amount <= 0 || _categoryId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final isEditing = widget.editTransaction != null;
      
      if (isEditing) {
        // Update existing transaction
        final updatedTransaction = TransactionModel(
          id: widget.editTransaction!.id,
          userId: user.uid,
          amount: _amount,
          type: _type,
          categoryId: _categoryId!,
          date: _date,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          createdAt: widget.editTransaction!.createdAt,
        );

        await ref.read(transactionRepositoryProvider).updateTransaction(updatedTransaction);
      } else {
        // Get location BEFORE creating transaction
        debugPrint('📍 Requesting location before transaction creation...');
        final position = await GeoLocationService().getCurrentLocation();
        debugPrint('📍 Location result: $position');

        // Create new transaction
        final transaction = TransactionModel(
          id: const Uuid().v4(),
          userId: user.uid,
          amount: _amount,
          type: _type,
          categoryId: _categoryId!,
          date: _date,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          createdAt: DateTime.now(),
        );

        // Get the actual Firestore document ID
        final firestoreId = await ref.read(transactionRepositoryProvider).addTransaction(transaction);
        debugPrint('✅ Transaction created with ID: $firestoreId');

        // Add location data to the transaction if we have location
        if (position != null) {
          try {
            debugPrint('📌 Adding location to transaction: $firestoreId');
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('transactions')
                .doc(firestoreId)
                .update({
              'location': GeoPoint(position.latitude, position.longitude),
              'address': '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}',
            });
            debugPrint('✅ Location added successfully');
          } catch (e) {
            debugPrint('⚠️ Failed to add location: $e');
          }
        }

        // Add notification
        final category = CategoryModel.findById(_categoryId!);
        final categoryName = category?.name ?? 'Khác';
        if (_type == TransactionType.income) {
          ref.read(notificationProvider.notifier)
              .addIncomeNotification(_amount, categoryName);
        } else {
          ref.read(notificationProvider.notifier)
              .addExpenseNotification(_amount, categoryName);
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Đã cập nhật giao dịch thành công' : 'Đã lưu giao dịch thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
