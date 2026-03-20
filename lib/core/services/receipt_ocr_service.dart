import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../features/ocr/receipt_parser.dart';

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
      
      // Use ReceiptParser for accurate amount extraction
      final parsed = ReceiptParser.parse(fullText);
      final amount = (parsed['amount'] as double?) ?? 0.0;
      final description = parsed['description'] as String? ?? '';
      
      final category = _detectCategory(fullText);
      final date = parsed['date'] as DateTime?;

      return {
        'success': true,
        'amount': amount,
        'category': category,
        'description': description,
        'date': date,
        'rawText': fullText,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
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

  void dispose() {
    _textRecognizer.close();
  }
}
