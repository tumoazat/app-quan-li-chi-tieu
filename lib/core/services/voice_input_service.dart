import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Trạng thái voice input
class VoiceInputState {
  final bool isListening;
  final bool isAvailable;
  final String recognizedText;
  final double soundLevel;

  const VoiceInputState({
    this.isListening = false,
    this.isAvailable = false,
    this.recognizedText = '',
    this.soundLevel = 0.0,
  });

  VoiceInputState copyWith({
    bool? isListening,
    bool? isAvailable,
    String? recognizedText,
    double? soundLevel,
  }) {
    return VoiceInputState(
      isListening: isListening ?? this.isListening,
      isAvailable: isAvailable ?? this.isAvailable,
      recognizedText: recognizedText ?? this.recognizedText,
      soundLevel: soundLevel ?? this.soundLevel,
    );
  }
}

/// Provider quản lý voice input
final voiceInputProvider = StateNotifierProvider<VoiceInputNotifier, VoiceInputState>((ref) {
  return VoiceInputNotifier();
});

/// Notifier quản lý trạng thái nhận dạng giọng nói
class VoiceInputNotifier extends StateNotifier<VoiceInputState> {
  final SpeechToText _speech = SpeechToText();

  VoiceInputNotifier() : super(const VoiceInputState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final available = await _speech.initialize(
      onError: (error) => state = state.copyWith(isListening: false),
    );
    state = state.copyWith(isAvailable: available);
  }

  /// Bắt đầu nghe giọng nói
  Future<void> startListening({required Function(String) onResult}) async {
    if (!state.isAvailable || state.isListening) return;

    state = state.copyWith(isListening: true, recognizedText: '');

    await _speech.listen(
      onResult: (result) {
        state = state.copyWith(recognizedText: result.recognizedWords);
        if (result.finalResult) {
          onResult(result.recognizedWords);
          state = state.copyWith(isListening: false);
        }
      },
      localeId: 'vi-VN', // Nhận dạng tiếng Việt
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      onSoundLevelChange: (level) => state = state.copyWith(soundLevel: level),
    );
  }

  /// Dừng nghe
  Future<void> stopListening() async {
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}
