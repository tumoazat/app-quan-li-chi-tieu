import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider theo dõi trạng thái kết nối mạng
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none));
});

/// Dịch vụ kiểm tra kết nối mạng
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Kiểm tra xem có kết nối mạng không
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Stream theo dõi trạng thái kết nối
  Stream<bool> get connectivityStream => _connectivity
      .onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none));
}

/// Provider singleton ConnectivityService
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});
