/// File name: chat_message.dart
/// Author: Nguyễn Thị Linh
/// Created: 2026-03-19
/// Description: Chat message and quick action models for AI chatbot
/// 
/// Responsibilities:
/// - Define ChatMessage model with sender, content, timestamp
/// - Define QuickAction model for predefined suggestions
/// - Provide JSON serialization/deserialization

import 'package:uuid/uuid.dart';

/// Enum định nghĩa loại tin nhắn
enum ChatMessageType {
  user('user'),
  assistant('assistant'),
  system('system');

  final String value;
  const ChatMessageType(this.value);
}

/// Model đại diện cho một tin nhắn trong chat
class ChatMessage {
  /// ID duy nhất của tin nhắn
  final String id;

  /// Người gửi tin nhắn (user hoặc assistant)
  final ChatMessageType type;

  /// Nội dung tin nhắn
  final String content;

  /// Thời gian gửi tin nhắn
  final DateTime timestamp;

  /// Ngữ cảnh tài chính (nếu có)
  final String? financialContext;

  /// Lỗi nếu xảy ra (nếu có)
  final String? error;

  /// Trạng thái loading
  final bool isLoading;

  ChatMessage({
    String? id,
    required this.type,
    required this.content,
    DateTime? timestamp,
    this.financialContext,
    this.error,
    this.isLoading = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Tạo bản sao với các thuộc tính thay đổi
  ChatMessage copyWith({
    String? id,
    ChatMessageType? type,
    String? content,
    DateTime? timestamp,
    String? financialContext,
    String? error,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      financialContext: financialContext ?? this.financialContext,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Chuyển đổi sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'financialContext': financialContext,
      'error': error,
      'isLoading': isLoading,
    };
  }

  /// Tạo từ JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      type: ChatMessageType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => ChatMessageType.system,
      ),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      financialContext: json['financialContext'] as String?,
      error: json['error'] as String?,
      isLoading: json['isLoading'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, type: ${type.value}, content: $content, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          content == other.content &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^ type.hashCode ^ content.hashCode ^ timestamp.hashCode;
}

/// Model đại diện cho một gợi ý nhanh (QuickAction)
class QuickAction {
  /// ID duy nhất
  final String id;

  /// Tiêu đề action
  final String title;

  /// Mô tả ngắn
  final String description;

  /// Icon emoji
  final String emoji;

  /// Tin nhắn được gửi khi nhấn
  final String messageText;

  /// Loại action
  final QuickActionType type;

  QuickAction({
    String? id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.messageText,
    this.type = QuickActionType.general,
  }) : id = id ?? const Uuid().v4();

  /// Tạo bản sao với các thuộc tính thay đổi
  QuickAction copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    String? messageText,
    QuickActionType? type,
  }) {
    return QuickAction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      messageText: messageText ?? this.messageText,
      type: type ?? this.type,
    );
  }

  /// Chuyển đổi sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'messageText': messageText,
      'type': type.value,
    };
  }

  /// Tạo từ JSON
  factory QuickAction.fromJson(Map<String, dynamic> json) {
    return QuickAction(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
      messageText: json['messageText'] as String,
      type: QuickActionType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => QuickActionType.general,
      ),
    );
  }

  @override
  String toString() => 'QuickAction(id: $id, title: $title, emoji: $emoji)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuickAction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          emoji == other.emoji;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ emoji.hashCode;
}

/// Enum loại quick action
enum QuickActionType {
  general('general'),
  analysis('analysis'),
  advice('advice'),
  goal('goal');

  final String value;
  const QuickActionType(this.value);
}

/// Các quick actions mặc định
final defaultQuickActions = [
  QuickAction(
    title: 'Phân tích chi tiêu',
    description: 'Xem chi tiết chi tiêu của tôi',
    emoji: '📊',
    messageText: 'Hãy phân tích chi tiêu của tôi trong tháng này',
    type: QuickActionType.analysis,
  ),
  QuickAction(
    title: 'Lời khuyên tiết kiệm',
    description: 'Nhận gợi ý tiết kiệm',
    emoji: '💰',
    messageText: 'Bạn có thể cho tôi lời khuyên để tiết kiệm tiền?',
    type: QuickActionType.advice,
  ),
  QuickAction(
    title: 'Đặt mục tiêu',
    description: 'Lập kế hoạch tài chính',
    emoji: '🎯',
    messageText: 'Tôi muốn đặt mục tiêu tiết kiệm, bạn có thể giúp tôi không?',
    type: QuickActionType.goal,
  ),
  QuickAction(
    title: 'So sánh với tháng trước',
    description: 'Xem xu hướng chi tiêu',
    emoji: '📈',
    messageText: 'Hãy so sánh chi tiêu của tôi so với tháng trước',
    type: QuickActionType.analysis,
  ),
];
