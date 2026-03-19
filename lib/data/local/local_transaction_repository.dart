import 'package:hive/hive.dart';
import 'hive_service.dart';

/// Repository lưu trữ giao dịch cục bộ khi offline
class LocalTransactionRepository {
  Box get _box => HiveService.transactionBox;

  /// Lưu giao dịch vào cache
  Future<void> cacheTransaction(String id, Map<String, dynamic> data) async {
    await _box.put(id, data);
  }

  /// Lấy danh sách giao dịch từ cache
  List<Map<String, dynamic>> getCachedTransactions() {
    return _box.values.cast<Map<dynamic, dynamic>>().map((e) {
      return Map<String, dynamic>.from(e);
    }).toList();
  }

  /// Thêm giao dịch vào hàng đợi chờ đồng bộ
  Future<void> queueTransaction(Map<String, dynamic> data) async {
    final pending = _box.get('pending_transactions', defaultValue: <dynamic>[]) as List;
    pending.add(data);
    await _box.put('pending_transactions', pending);
  }

  /// Lấy danh sách giao dịch đang chờ đồng bộ
  List<Map<String, dynamic>> getPendingTransactions() {
    final pending = _box.get('pending_transactions', defaultValue: <dynamic>[]) as List;
    return pending.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Xóa hàng đợi sau khi đã đồng bộ
  Future<void> clearPendingTransactions() async {
    await _box.delete('pending_transactions');
  }

  /// Xóa toàn bộ cache
  Future<void> clearCache() async {
    await _box.clear();
  }
}
