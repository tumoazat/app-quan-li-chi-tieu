import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Trạng thái voice input
class VoiceInputState {
  final bool isListening;
  final bool isAvailable;
  final String recognizedText;
  final double soundLevel;
  final String? error;
  final String locale;

  const VoiceInputState({
    this.isListening = false,
    this.isAvailable = false,
    this.recognizedText = '',
    this.soundLevel = 0.0,
    this.error,
    this.locale = 'vi_VN',
  });

  VoiceInputState copyWith({
    bool? isListening,
    bool? isAvailable,
    String? recognizedText,
    double? soundLevel,
    String? error,
    String? locale,
  }) {
    return VoiceInputState(
      isListening: isListening ?? this.isListening,
      isAvailable: isAvailable ?? this.isAvailable,
      recognizedText: recognizedText ?? this.recognizedText,
      soundLevel: soundLevel ?? this.soundLevel,
      error: error,
      locale: locale ?? this.locale,
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
    try {
      final available = await _speech.initialize(
        onError: (error) {
          state = state.copyWith(
            isListening: false,
            error: 'Lỗi: ${error.errorMsg}',
          );
        },
        onStatus: (status) {
          if (status == 'notListening') {
            state = state.copyWith(isListening: false);
          }
        },
      );
      state = state.copyWith(isAvailable: available);
    } catch (e) {
      state = state.copyWith(error: 'Khởi tạo voice failed: $e');
    }
  }

  /// Bắt đầu nghe giọng nói Tiếng Việt
  Future<void> startListening({required Function(String) onResult}) async {
    if (!state.isAvailable) {
      state = state.copyWith(error: 'Voice recognition không khả dụng');
      return;
    }

    if (state.isListening) return;

    try {
      state = state.copyWith(
        isListening: true,
        recognizedText: '',
        error: null,
      );

      await _speech.listen(
        onResult: (result) {
          state = state.copyWith(recognizedText: result.recognizedWords);
          if (result.finalResult) {
            onResult(result.recognizedWords);
            state = state.copyWith(isListening: false);
          }
        },
        localeId: 'vi_VN', // Nhận dạng Tiếng Việt
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 4),
        partialResults: true, // Hiển thị kết quả từng phần
        onSoundLevelChange: (level) => state = state.copyWith(soundLevel: level),
      );
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        error: 'Lỗi nghe: $e',
      );
    }
  }

  /// Dừng nghe
  Future<void> stopListening() async {
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  /// Hủy bỏ nghe
  Future<void> cancelListening() async {
    await _speech.cancel();
    state = state.copyWith(
      isListening: false,
      recognizedText: '',
      error: null,
    );
  }

  /// Lấy danh sách ngôn ngữ hỗ trợ
  Future<List<LocaleName>> getLocales() async {
    return await _speech.locales();
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}
