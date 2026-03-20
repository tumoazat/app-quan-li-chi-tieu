import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptOCRService {
  static final ReceiptOCRService _instance = ReceiptOCRService._internal();

  factory ReceiptOCRService() {
    return _instance;
  }

  ReceiptOCRService._internal();

  late final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract amount from receipt image
  Future<Map<String, dynamic>> extractReceiptInfo(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      final fullText = recognizedText.text;
      final amount = _extractAmount(fullText);
      final category = _detectCategory(fullText);
      final date = _extractDate(fullText);

      return {
        'success': true,
        'amount': amount,
        'category': category,
        'description': fullText,
        'date': date,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Extract amount using regex patterns
  double _extractAmount(String text) {
    // Pattern: 50000, 50.000, 50,00, 50k, 50m
    final patterns = [
      RegExp(r'(\d+)[.,]?(\d{3})[.,]?(\d{2})'),
      RegExp(r'(\d+)[km](?:\s|$)'),
      RegExp(r'(\d{2,})[.,](\d{2})'),
      RegExp(r'(\d+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String amount = match.group(1)!;
        final suffix = match.group(2) ?? '';

        double value = double.tryParse(amount) ?? 0;

        if (suffix.contains('k')) value *= 1000;
        if (suffix.contains('m')) value *= 1000000;
        if (suffix.contains('b')) value *= 1000000000;

        if (value > 0 && value < 1000000000) {
          return value;
        }
      }
    }
    return 0.0;
  }

  /// Detect category based on keywords
  String _detectCategory(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('ăn') ||
        lowerText.contains('cơm') ||
        lowerText.contains('café') ||
        lowerText.contains('nhà hàng') ||
        lowerText.contains('quán')) {
      return 'Food & Dining';
    }

    if (lowerText.contains('xăng') ||
        lowerText.contains('xe') ||
        lowerText.contains('taxi') ||
        lowerText.contains('uber') ||
        lowerText.contains('grab')) {
      return 'Transport';
    }

    if (lowerText.contains('mua') ||
        lowerText.contains('shop') ||
        lowerText.contains('siêu thị') ||
        lowerText.contains('mall')) {
      return 'Shopping';
    }

    if (lowerText.contains('điện') ||
        lowerText.contains('nước') ||
        lowerText.contains('internet')) {
      return 'Utilities';
    }

    if (lowerText.contains('y tế') || lowerText.contains('bệnh viện')) {
      return 'Healthcare';
    }

    return 'Other';
  }

  /// Extract date from text
  DateTime? _extractDate(String text) {
    // Pattern: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
    final datePattern =
        RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})');
    final match = datePattern.firstMatch(text);

    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);

        return DateTime(year, month, day);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
