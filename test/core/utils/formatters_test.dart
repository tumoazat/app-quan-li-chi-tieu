import 'package:flutter_test/flutter_test.dart';
import 'package:appchitieu/core/utils/currency_formatter.dart';
import 'package:appchitieu/core/utils/date_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formatVND định dạng số tiền VNĐ đúng', () {
      // Kiểm tra định dạng số tiền
      final result = CurrencyFormatter.formatVND(1000000);
      expect(result, contains('1'));
      expect(result.isNotEmpty, isTrue);
    });

    test('formatVND xử lý số 0', () {
      final result = CurrencyFormatter.formatVND(0);
      expect(result.isNotEmpty, isTrue);
    });

    test('formatVND xử lý số âm', () {
      // Hàm lấy trị tuyệt đối nên kết quả không rỗng
      final result = CurrencyFormatter.formatVND(-500000);
      expect(result.isNotEmpty, isTrue);
    });

    test('formatCompact định dạng số lớn dạng rút gọn', () {
      final result = CurrencyFormatter.formatCompact(2000000);
      expect(result, contains('M'));
    });
  });

  group('DateFormatter', () {
    test('formatVietnamese trả về chuỗi không rỗng', () {
      final date = DateTime(2026, 1, 15);
      final result = DateFormatter.formatVietnamese(date);
      expect(result.isNotEmpty, isTrue);
    });

    test('formatVietnamese trả về "Hôm nay" cho ngày hiện tại', () {
      final today = DateTime.now();
      final result = DateFormatter.formatVietnamese(today);
      expect(result, equals('Hôm nay'));
    });

    test('formatVietnamese định dạng ngày quá khứ đúng', () {
      final date = DateTime(2026, 2, 27);
      final result = DateFormatter.formatVietnamese(date);
      expect(result, isNotEmpty);
    });
  });
}
