import 'dart:async';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptOCRService {
  static final ReceiptOCRService _instance = ReceiptOCRService._internal();

  factory ReceiptOCRService() {
    return _instance;
  }

  ReceiptOCRService._internal();

  bool _isProcessing = false;
  static const Duration _ocrTimeout = Duration(seconds: 12);

  late final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract amount from receipt image
  Future<Map<String, dynamic>> extractReceiptInfo(String imagePath) async {
    if (_isProcessing) {
      return {
        'success': false,
        'error': 'OCR đang xử lý, vui lòng thử lại sau vài giây',
      };
    }

    _isProcessing = true;
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage).timeout(_ocrTimeout);

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
    } finally {
      _isProcessing = false;
    }
  }

  /// Extract amount using regex patterns (optimized for Vietnamese format)
  double _extractAmount(String text) {
    // Vietnamese currency format: 45,000 VND or -VND 45,000 or similar
    // Strategy: look for patterns near VND keyword first, then any standalone number
    
    // Pattern 1: Amount with VND keyword (e.g., "-VND 45,000" or "VND 45000")
    final vndPattern = RegExp(r'(?:VND|₫|đ)\s*-?\s*([0-9]{1,3}(?:[.,][0-9]{3})*)', 
      caseSensitive: false);
    var match = vndPattern.firstMatch(text);
    if (match != null) {
      String numStr = match.group(1)!.replaceAll(RegExp(r'[,.]'), '');
      final value = double.tryParse(numStr) ?? 0;
      if (value > 500 && value < 1000000000) {
        return value;
      }
    }
    
    // Pattern 2: Standalone currency amount (e.g., "45,000" or "45.000")
    final amountPattern = RegExp(r'\b(\d{1,3}(?:[.,]\d{3})+)\b');
    final matches = amountPattern.allMatches(text);
    
    if (matches.isNotEmpty) {
      // Take the first significant number (usually appears before others in receipt)
      for (final m in matches) {
        String numStr = m.group(1)!.replaceAll(RegExp(r'[,.]'), '');
        final value = double.tryParse(numStr) ?? 0;
        if (value > 500 && value < 100000000) {
          return value;
        }
      }
    }
    
    // Pattern 3: Fallback - any number >= 1000
    final fallbackPattern = RegExp(r'\b(\d{4,})\b');
    match = fallbackPattern.firstMatch(text);
    if (match != null) {
      final value = double.tryParse(match.group(1)!) ?? 0;
      if (value > 500 && value < 1000000000) {
        return value;
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
