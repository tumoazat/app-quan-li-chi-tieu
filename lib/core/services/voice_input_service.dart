import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

/// Trạng thái voice input
class VoiceInputState {
  final bool isListening;
  final bool isAvailable;
  final String recognizedText;
  final double soundLevel;
  final String? error;

  const VoiceInputState({
    this.isListening = false,
    this.isAvailable = false,
    this.recognizedText = '',
    this.soundLevel = 0.0,
    this.error,
  });

  VoiceInputState copyWith({
    bool? isListening,
    bool? isAvailable,
    String? recognizedText,
    double? soundLevel,
    String? error,
    bool clearError = false,
  }) {
    return VoiceInputState(
      isListening: isListening ?? this.isListening,
      isAvailable: isAvailable ?? this.isAvailable,
      recognizedText: recognizedText ?? this.recognizedText,
      soundLevel: soundLevel ?? this.soundLevel,
      error: clearError ? null : (error ?? this.error),
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
  String? _localeId;
  String? _fallbackLocaleId;
  Function(String)? _onResultCallback;
  bool _startInProgress = false;
  bool _isTryingFallback = false;
  bool _isTryingLanguageFallback = false;
  bool _usingOnDevice = false;

  VoiceInputNotifier() : super(const VoiceInputState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Web: browser handles mic permission via prompt.
      // Mobile: request runtime permission explicitly.
      if (!kIsWeb) {
        final micStatus = await Permission.microphone.request();
        if (!micStatus.isGranted) {
          state = state.copyWith(
            isAvailable: false,
            error: 'Chưa cấp quyền microphone.',
          );
          return;
        }
      }

      final available = await _speech.initialize(
        onError: _handleSpeechError,
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            state = state.copyWith(isListening: false);
          }
        },
      );

      if (!available) {
        state = state.copyWith(
          isAvailable: false,
          error: 'Thiết bị/trình duyệt không hỗ trợ nhận diện giọng nói.',
        );
        return;
      }

      final locales = await _speech.locales();
      String? viExact;
      String? viAny;
      String? enAny;

      for (final l in locales) {
        final id = l.localeId;
        final lower = id.toLowerCase();
        viExact ??= (lower == 'vi-vn') ? id : null;
        viAny ??= lower.startsWith('vi') ? id : null;
        enAny ??= lower.startsWith('en') ? id : null;
      }

      _fallbackLocaleId = enAny ?? (locales.isNotEmpty ? locales.first.localeId : null);
      _localeId = viExact ?? viAny ?? _fallbackLocaleId;

      state = state.copyWith(isAvailable: true, clearError: true);
    } catch (e) {
      state = state.copyWith(
        isAvailable: false,
        error: 'Không thể khởi tạo voice input: $e',
      );
    }
  }

  /// Bắt đầu nghe giọng nói
  Future<void> startListening({required Function(String) onResult}) async {
    if (_startInProgress || state.isListening || _speech.isListening) return;

    // Re-init on demand for flaky browsers/devices.
    if (!state.isAvailable) {
      await _initialize();
      if (!state.isAvailable) return;
    }

    _onResultCallback = onResult;
    _isTryingFallback = false;
    _isTryingLanguageFallback = false;
    _usingOnDevice = false;
    _startInProgress = true;
    state = state.copyWith(
      isListening: true,
      recognizedText: '',
      soundLevel: 0,
      clearError: true,
    );

    try {
      final localeToUse = _localeId;

      bool started;
      if (kIsWeb) {
        // Web Speech: chỉ dùng cloud mode, onDevice thường fail.
        started = await _startListenSession(localeId: localeToUse, onDevice: false);
      } else {
        // Mobile/Desktop: ưu tiên cloud trước (ổn định hơn trên emulator),
        // sau đó fallback on-device nếu cần.
        started = await _startListenSession(localeId: localeToUse, onDevice: false);
        if (!started) {
          started = await _startListenSession(localeId: localeToUse, onDevice: true);
        }
      }

      if (!started) {
        state = state.copyWith(
          isListening: false,
          error: kIsWeb
              ? 'Web Speech không khởi động được. Kiểm tra internet và quyền mic của trình duyệt.'
              : 'Không thể bắt đầu nhận diện giọng nói trên thiết bị này.',
        );
      }
    } finally {
      _startInProgress = false;
    }
  }

  Future<bool> _startListenSession({
    required String? localeId,
    required bool onDevice,
  }) async {
    _usingOnDevice = onDevice;
    try {
      if (_speech.isListening) return true;
      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords.trim();
          state = state.copyWith(recognizedText: words);
          // Trả kết quả realtime để UI luôn nhận được text.
          if (words.isNotEmpty) {
            _onResultCallback?.call(words);
          }
          if (result.finalResult) {
            state = state.copyWith(isListening: false);
          }
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 5),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          onDevice: onDevice,
          listenMode: ListenMode.dictation,
        ),
        onSoundLevelChange: (level) => state = state.copyWith(soundLevel: level),
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return _speech.isListening;
    } catch (e) {
      return false;
    }
  }

  void _handleSpeechError(dynamic error) {
    final raw = '$error';
    final msg = raw.toLowerCase();

    // Trường hợp web báo start trùng phiên: coi như đang chạy.
    if (msg.contains('already started')) {
      state = state.copyWith(isListening: true, clearError: true);
      return;
    }

    // Locale hiện tại không khả dụng trên thiết bị -> thử locale fallback 1 lần.
    if (!kIsWeb &&
        (msg.contains('error_language_unavailable') ||
            msg.contains('language_unavailable')) &&
        !_isTryingLanguageFallback) {
      _isTryingLanguageFallback = true;
      unawaited(_retryWithFallbackLocale());
      return;
    }

    // Web thường trả lỗi network tạm thời. Retry lại cloud mode 1 lần.
    if (kIsWeb && msg.contains('network') && !_isTryingFallback) {
      _isTryingFallback = true;
      unawaited(_retryWebCloud());
      return;
    }

    // Nếu lỗi mạng khi đang cloud mode thì thử lại bằng on-device một lần.
    if (!kIsWeb && msg.contains('network') && !_usingOnDevice && !_isTryingFallback) {
      _isTryingFallback = true;
      unawaited(_retryWithOnDevice());
      return;
    }

    state = state.copyWith(
      isListening: false,
      error: kIsWeb
          ? 'Web Speech lỗi kết nối. Hãy kiểm tra mạng hoặc thử Chrome/Edge.'
          : (msg.contains('language_unavailable') || msg.contains('error_language_unavailable')
              ? 'Ngôn ngữ nhận diện hiện không khả dụng trên máy. Hãy thử đổi ngôn ngữ thiết bị hoặc cài Google Speech Services.'
              : 'Voice error: $raw'),
    );
  }

  Future<void> _retryWithFallbackLocale() async {
    try {
      await _speech.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 250));

      final fallback = _fallbackLocaleId;
      if (fallback == null) {
        state = state.copyWith(
          isListening: false,
          error: 'Không tìm thấy locale speech phù hợp trên thiết bị.',
        );
        return;
      }

      _localeId = fallback;
      state = state.copyWith(isListening: true, clearError: true);

      var started = await _startListenSession(localeId: _localeId, onDevice: false);
      if (!started) {
        started = await _startListenSession(localeId: _localeId, onDevice: true);
      }

      if (!started) {
        state = state.copyWith(
          isListening: false,
          error:
              'Thiết bị không hỗ trợ locale speech hiện tại. Vui lòng cài Google Speech Services và language pack.',
        );
      }
    } catch (_) {
      state = state.copyWith(
        isListening: false,
        error: 'Không thể fallback ngôn ngữ nhận diện.',
      );
    }
  }

  Future<void> _retryWebCloud() async {
    try {
      await _speech.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      state = state.copyWith(isListening: true, clearError: true);

      final started = await _startListenSession(
        localeId: _localeId,
        onDevice: false,
      );

      if (!started) {
        state = state.copyWith(
          isListening: false,
          error:
              'Trình duyệt không kết nối được dịch vụ nhận giọng nói. Thử Chrome/Edge, tắt Brave Shields, và kiểm tra mạng.',
        );
      }
    } catch (_) {
      state = state.copyWith(
        isListening: false,
        error:
            'Không thể khởi động Web Speech. Hãy reload trang và cấp lại quyền microphone.',
      );
    }
  }

  Future<void> _retryWithOnDevice() async {
    try {
      await _speech.cancel();
      state = state.copyWith(isListening: true, clearError: true);
      final localeToUse = kIsWeb ? null : _localeId;
      await _startListenSession(localeId: localeToUse, onDevice: true);
      if (!_speech.isListening) {
        state = state.copyWith(
          isListening: false,
          error: 'Lỗi mạng và thiết bị không hỗ trợ nhận diện offline.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        error: 'Không thể fallback offline: $e',
      );
    }
  }

  /// Dừng nghe
  Future<void> stopListening() async {
    await _speech.stop();
    // Nếu người dùng dừng sớm, vẫn trả text hiện tại.
    final words = state.recognizedText.trim();
    if (words.isNotEmpty) {
      _onResultCallback?.call(words);
    }
    state = state.copyWith(isListening: false);
  }

  /// Huỷ phiên nghe hiện tại
  Future<void> cancelListening() async {
    await _speech.cancel();
    state = state.copyWith(isListening: false);
  }

  /// Xoá lỗi hiện tại
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}
