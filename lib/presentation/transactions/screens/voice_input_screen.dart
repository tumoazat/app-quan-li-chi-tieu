import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appchitieu/core/services/voice_input_service.dart';
import 'package:appchitieu/core/constants/category_data.dart';
import 'package:appchitieu/features/ai_categorization/data/keyword_repository.dart';

/// Màn hình nhập giao dịch bằng giọng nói.
///
/// Flow:
/// 1) Bắt đầu nghe qua `voiceInputProvider`.
/// 2) Nhận text realtime.
/// 3) Parse số tiền + category.
/// 4) Trả payload về màn hình tạo giao dịch.
class VoiceInputScreen extends ConsumerStatefulWidget {
  const VoiceInputScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Gọi service speech-to-text để bắt đầu phiên nghe.
  Future<void> _startListening() async {
    final voiceNotifier = ref.read(voiceInputProvider.notifier);
    await voiceNotifier.startListening(onResult: (result) {
      if (mounted) {
        setState(() {
          _recognizedText = result;
        });
      }
    });
  }

  /// Dừng phiên nghe hiện tại.
  Future<void> _stopListening() async {
    final voiceNotifier = ref.read(voiceInputProvider.notifier);
    await voiceNotifier.stopListening();
  }

  /// Parse nội dung speech thành dữ liệu giao dịch chuẩn để `Navigator.pop`.
  Future<void> _parseAndReturn() async {
    final voiceText = ref.read(voiceInputProvider).recognizedText.isNotEmpty
        ? ref.read(voiceInputProvider).recognizedText
        : _recognizedText;

    if (voiceText.isEmpty) return;

    try {
      final lower = voiceText.toLowerCase();
      final categoryId = _inferExpenseCategoryId(lower) ?? 'expense_others';
      final categoryName = CategoryModel.findById(categoryId)?.name ?? 'Khác';
      final amount = _extractAmountVnd(voiceText);

      if (!mounted) return;
      Navigator.of(context).pop({
        'amount': amount,
        'category': categoryName,
        'categoryId': categoryId,
        'description': voiceText,
        'source': 'voice',
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// Suy luận category chi tiêu từ keyword map.
  String? _inferExpenseCategoryId(String lowerText) {
    String? bestCategoryId;
    int bestLen = 0;

    for (final entry in keywordMap.entries) {
      final keyword = entry.key;
      final categoryId = entry.value;
      if (!categoryId.startsWith('expense_')) continue;
      if (lowerText.contains(keyword) && keyword.length > bestLen) {
        bestLen = keyword.length;
        bestCategoryId = categoryId;
      }
    }

    return bestCategoryId;
  }

  /// Tách số tiền VND từ câu nói (hỗ trợ k/tr/triệu/tỷ...).
  double _extractAmountVnd(String input) {
    final text = input.toLowerCase();

    // Match: 50k, 50.000đ, 1,200,000 vnd, 2 triệu, 1.5tr...
    final regex = RegExp(
      r'(\d{1,3}(?:[\.,]\d{3})+|\d+(?:[\.,]\d+)?)\s*(k|nghìn|ngàn|triệu|tr|tỷ|ty|đ|vnd|vnđ)?',
      caseSensitive: false,
    );

    double bestValue = 0;
    int bestScore = -1;

    for (final m in regex.allMatches(text)) {
      final rawNum = m.group(1);
      if (rawNum == null || rawNum.isEmpty) continue;

      final unit = (m.group(2) ?? '').toLowerCase();
      final parsed = _parseNumber(rawNum);
      if (parsed == null) continue;

      double value = parsed;
      if (unit == 'k' || unit == 'nghìn' || unit == 'ngàn') {
        value *= 1000;
      } else if (unit == 'triệu' || unit == 'tr') {
        value *= 1000000;
      } else if (unit == 'tỷ' || unit == 'ty') {
        value *= 1000000000;
      }

      // Ưu tiên token có đơn vị tiền và số tiền lớn hợp lý
      var score = 0;
      if (unit.isNotEmpty) score += 100;
      if (rawNum.contains('.') || rawNum.contains(',')) score += 20;
      if (value >= 1000) score += 10;

      if (score > bestScore || (score == bestScore && value > bestValue)) {
        bestScore = score;
        bestValue = value;
      }
    }

    return bestValue;
  }

  double? _parseNumber(String raw) {
    var value = raw.trim();

    // 50.000 / 1.200.000 -> remove thousand separator dots
    if (RegExp(r'^\d{1,3}(?:\.\d{3})+$').hasMatch(value)) {
      value = value.replaceAll('.', '');
    }
    // 1,200,000 -> remove thousand separator commas
    else if (RegExp(r'^\d{1,3}(?:,\d{3})+$').hasMatch(value)) {
      value = value.replaceAll(',', '');
    } else {
      // Decimal fallback: use dot
      value = value.replaceAll(',', '.');
    }

    return double.tryParse(value);
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInputProvider);
    final isListening = voiceState.isListening;
    final recognizedText =
        voiceState.recognizedText.isNotEmpty ? voiceState.recognizedText : _recognizedText;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Input'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_animationController.value * 0.2),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening ? Colors.red.withOpacity(0.3) : Colors.blue.withOpacity(0.2),
                      border: Border.all(
                        color: isListening ? Colors.red : Colors.blue,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      size: 60,
                      color: isListening ? Colors.red : Colors.blue,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Text(
              isListening
                  ? 'Đang nghe...'
                  : (voiceState.isAvailable ? 'Sẵn sàng ghi âm' : 'Thiết bị không hỗ trợ voice input'),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (voiceState.error != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    voiceState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (recognizedText.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You said:',
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(recognizedText, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: !voiceState.isAvailable
                        ? null
                        : (isListening ? _stopListening : _startListening),
                    icon: Icon(isListening ? Icons.stop : Icons.mic),
                    label: Text(isListening ? 'Stop' : 'Listen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isListening ? Colors.red : Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  if (recognizedText.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _parseAndReturn,
                      icon: const Icon(Icons.check),
                      label: const Text('Parse'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 8),
                    Text(
                      '• Speak clearly\n• Example: "50k on food"\n• Say amount and category',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
