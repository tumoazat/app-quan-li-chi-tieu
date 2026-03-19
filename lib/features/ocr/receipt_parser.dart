/// Parser phân tích text từ hóa đơn để trích xuất thông tin giao dịch
class ReceiptParser {
  /// Trích xuất số tiền từ text hóa đơn
  static double? extractAmount(String text) {
    // Ưu tiên lấy từ các từ khóa tổng tiền trước
    final keywordPatterns = [
      RegExp(r'tổng[:\s]+(\d[\d.,]+)', caseSensitive: false),
      RegExp(r'total[:\s]+(\d[\d.,]+)', caseSensitive: false),
      RegExp(r'thành tiền[:\s]+(\d[\d.,]+)', caseSensitive: false),
    ];

    for (final pattern in keywordPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final parsed = _parseAmountString(match.group(1)!);
        if (parsed != null) return parsed;
      }
    }

    // Format VNĐ: dùng dấu chấm phân nhóm hàng nghìn (1.000.000)
    final dotSeparatedPattern = RegExp(
      r'(\d{1,3}(?:\.\d{3})+)(?:đ|vnd|vnđ)?',
      caseSensitive: false,
    );
    final dotMatch = dotSeparatedPattern.firstMatch(text);
    if (dotMatch != null) {
      final cleaned = dotMatch.group(1)!.replaceAll('.', '');
      final amount = double.tryParse(cleaned);
      // Số hợp lệ VNĐ: >= 1000
      if (amount != null && amount >= 1000) return amount;
    }

    // Format quốc tế: dùng dấu phẩy phân nhóm (1,000,000)
    final commaSeparatedPattern = RegExp(
      r'(\d{1,3}(?:,\d{3})+)(?:đ|vnd|vnđ)?',
      caseSensitive: false,
    );
    final commaMatch = commaSeparatedPattern.firstMatch(text);
    if (commaMatch != null) {
      final cleaned = commaMatch.group(1)!.replaceAll(',', '');
      return double.tryParse(cleaned);
    }

    // Số kèm ký hiệu tiền tệ không có phân cách
    final currencyPattern = RegExp(r'(\d+)(?:đ|vnd|vnđ)', caseSensitive: false);
    final currencyMatch = currencyPattern.firstMatch(text);
    if (currencyMatch != null) {
      return double.tryParse(currencyMatch.group(1)!);
    }

    return null;
  }

  /// Phân tích chuỗi số tiền có thể có phân cách
  static double? _parseAmountString(String amountStr) {
    // Đếm dấu chấm và phẩy để phân biệt định dạng
    final dotCount = '.'.allMatches(amountStr).length;
    final commaCount = ','.allMatches(amountStr).length;

    String cleaned;
    if (dotCount > 1 || (dotCount >= 1 && commaCount == 0)) {
      // VNĐ format: 1.000.000 — chấm là phân nhóm
      cleaned = amountStr.replaceAll('.', '').replaceAll(',', '');
    } else if (commaCount > 1 || (commaCount >= 1 && dotCount == 0)) {
      // Quốc tế: 1,000,000 — phẩy là phân nhóm
      cleaned = amountStr.replaceAll(',', '').replaceAll('.', '');
    } else {
      // Không rõ — xóa cả hai
      cleaned = amountStr.replaceAll('.', '').replaceAll(',', '');
    }
    return double.tryParse(cleaned);
  }

  /// Trích xuất mô tả từ text hóa đơn
  static String extractDescription(String text) {
    // Lấy dòng đầu tiên có nghĩa (dài hơn 3 ký tự)
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length > 3)
        .toList();

    if (lines.isNotEmpty) {
      return lines.first.length > 50
          ? lines.first.substring(0, 50)
          : lines.first;
    }
    return 'Hóa đơn';
  }

  /// Trích xuất ngày từ text hóa đơn
  static DateTime? extractDate(String text) {
    // Pattern ngày: dd/MM/yyyy, dd-MM-yyyy, yyyy-MM-dd
    final patterns = [
      RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})'),
      RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          final g1 = match.group(1)!;
          final g2 = match.group(2)!;
          final g3 = match.group(3)!;

          if (g3.length == 4) {
            // Format: dd/MM/yyyy
            return DateTime(
              int.parse(g3),
              int.parse(g2),
              int.parse(g1),
            );
          } else {
            // Format: yyyy-MM-dd
            return DateTime(
              int.parse(g1),
              int.parse(g2),
              int.parse(g3),
            );
          }
        } catch (_) {}
      }
    }
    return null;
  }

  /// Phân tích toàn bộ hóa đơn, trả về map dữ liệu
  static Map<String, dynamic> parse(String text) {
    return {
      'amount': extractAmount(text),
      'description': extractDescription(text),
      'date': extractDate(text),
      'rawText': text,
    };
  }
}
