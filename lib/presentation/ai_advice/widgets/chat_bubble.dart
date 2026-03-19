import 'package:flutter/material.dart';

import '../../../data/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isTyping) {
      return const _TypingBubble();
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isUser = message.sender == ChatSender.user;

    final Color bubbleColor = isUser
        ? (isDark ? const Color(0xFF256D5A) : const Color(0xFF1AA483))
        : (isDark ? const Color(0xFF1E2A3D) : Colors.white);

    final Color textColor = isUser
        ? Colors.white
        : (isDark ? const Color(0xFFE7EEF9) : const Color(0xFF1A2638));

    final Color strokeColor = isUser
        ? Colors.transparent
        : (isDark ? const Color(0xFF2E3A50) : const Color(0xFFDCE6F8));

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 16),
          ),
          border: Border.all(color: strokeColor),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dotColor = isDark ? const Color(0xFF9BB4DA) : const Color(0xFF5877A8);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2A3D) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(
            color: isDark ? const Color(0xFF2E3A50) : const Color(0xFFDCE6F8),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double t = _controller.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(3, (int index) {
                final double phase = (t + (index * 0.2)) % 1;
                final double scale = 0.65 + (phase < 0.5 ? phase : (1 - phase)) * 0.9;

                return Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 5),
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.5 + (scale * 0.4)),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
