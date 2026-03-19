class ChatMessage {
  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.createdAt,
    this.isTyping = false,
  });

  final String id;
  final ChatSender sender;
  final String text;
  final DateTime createdAt;
  final bool isTyping;
}

enum ChatSender {
  user,
  assistant,
}

class QuickPrompt {
  const QuickPrompt({
    required this.title,
    required this.prompt,
    required this.emoji,
  });

  final String title;
  final String prompt;
  final String emoji;
}
