import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/voice_input_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class VoiceInputButton extends ConsumerStatefulWidget {
  final Function(String) onTextRecognized;
  final String label;
  final double? width;
  final double? height;

  const VoiceInputButton({
    super.key,
    required this.onTextRecognized,
    this.label = 'Nói để nhập',
    this.width,
    this.height,
  });

  @override
  ConsumerState<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends ConsumerState<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInputProvider);

    return GestureDetector(
      onTapDown: voiceState.isAvailable
          ? (_) async {
              await ref
                  .read(voiceInputProvider.notifier)
                  .startListening(onResult: widget.onTextRecognized);
              _animationController.forward();
            }
          : null,
      onTapUp: (_) async {
        _animationController.stop();
        _animationController.reset();
        await ref.read(voiceInputProvider.notifier).stopListening();
      },
      onTapCancel: () async {
        _animationController.stop();
        _animationController.reset();
        await ref.read(voiceInputProvider.notifier).stopListening();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse animation
          if (voiceState.isListening)
            ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.2)
                  .animate(_animationController),
              child: Container(
                width: (widget.width ?? 60) + 20,
                height: (widget.height ?? 60) + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
            ),

          // Main button
          Container(
            width: widget.width ?? 60,
            height: widget.height ?? 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: voiceState.isListening
                  ? LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.primary.withOpacity(0.5),
                      ],
                    ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(
                    voiceState.isListening ? 0.6 : 0.3,
                  ),
                  blurRadius: voiceState.isListening ? 20 : 10,
                  spreadRadius: voiceState.isListening ? 5 : 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  voiceState.isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 28,
                ),
                if (!voiceState.isListening)
                  SizedBox(
                    width: (widget.width ?? 60),
                    child: const Center(
                      child: Text(
                        '🎤',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Sound level indicator
          if (voiceState.isListening)
            Positioned(
              bottom: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🔊 ${(voiceState.soundLevel * 100).toStringAsFixed(0)}%',
                  style: AppTypography.bodySmall(context).copyWith(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class VoiceInputWidget extends ConsumerWidget {
  final Function(String) onTextRecognized;
  final String? initialText;
  final TextEditingController? controller;

  const VoiceInputWidget({
    super.key,
    required this.onTextRecognized,
    this.initialText,
    this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceInputProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voice button
        Center(
          child: VoiceInputButton(
            width: 80,
            height: 80,
            label: 'Nhấn và nói',
            onTextRecognized: (text) {
              if (controller != null) {
                controller!.text = text;
              }
              onTextRecognized(text);
            },
          ),
        ),
        const SizedBox(height: 16),

        // Recognized text display
        if (voiceState.recognizedText.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đã nhận diện:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  voiceState.recognizedText,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

        // Status indicator
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              voiceState.isListening
                  ? '🎙️ Đang nghe...'
                  : voiceState.isAvailable
                      ? '✅ Sẵn sàng'
                      : '❌ Không hỗ trợ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: voiceState.isListening
                    ? Colors.orange
                    : voiceState.isAvailable
                        ? Colors.green
                        : Colors.red,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
