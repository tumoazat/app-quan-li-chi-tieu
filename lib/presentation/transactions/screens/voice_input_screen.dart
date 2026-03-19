import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appchitieu/core/services/voice_input_service.dart';

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

  Future<void> _stopListening() async {
    final voiceNotifier = ref.read(voiceInputProvider.notifier);
    await voiceNotifier.stopListening();
  }

  Future<void> _parseAndReturn() async {
    if (_recognizedText.isEmpty) return;

    try {
      final lower = _recognizedText.toLowerCase();
      String category = 'Other';

      if (lower.contains('ăn') || lower.contains('cơm') || lower.contains('cà phê')) {
        category = 'Food & Dining';
      } else if (lower.contains('xăng') || lower.contains('xe')) {
        category = 'Transportation';
      } else if (lower.contains('mua') || lower.contains('shopping')) {
        category = 'Shopping';
      }

      double amount = 0.0;
      final amountMatch = RegExp(r'(\d+)').firstMatch(_recognizedText);
      if (amountMatch != null) {
        final numStr = amountMatch.group(1) ?? '0';
        amount = double.tryParse(numStr) ?? 0.0;
        if (_recognizedText.contains('k') || _recognizedText.contains('K')) {
          amount *= 1000;
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop({
        'amount': amount,
        'category': category,
        'description': _recognizedText,
        'source': 'voice',
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInputProvider);
    final isListening = voiceState.isListening;

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
              isListening ? 'Listening...' : 'Ready to listen',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            if (_recognizedText.isNotEmpty) ...[
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
                      Text(_recognizedText, style: Theme.of(context).textTheme.bodyLarge),
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
                    onPressed: isListening ? _stopListening : _startListening,
                    icon: Icon(isListening ? Icons.stop : Icons.mic),
                    label: Text(isListening ? 'Stop' : 'Listen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isListening ? Colors.red : Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  if (_recognizedText.isNotEmpty)
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
