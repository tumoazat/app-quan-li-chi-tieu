import 'package:flutter/material.dart';

enum MessageRole { user, assistant, system }
enum MessageType { text, financialSummary, suggestion, chart }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isLoading;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.type = MessageType.text,
    DateTime? timestamp,
    this.isLoading = false,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? content,
    bool? isLoading,
    MessageType? type,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp,
      isLoading: isLoading ?? this.isLoading,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
}

class QuickAction {
  final String label;
  final String emoji;
  final String prompt;
  final Color color;

  const QuickAction({
    required this.label,
    required this.emoji,
    required this.prompt,
    required this.color,
  });

  static const List<QuickAction> defaults = [
    QuickAction(
      label: 'Phân tích chi tiêu',
      emoji: '📊',
      prompt: 'Phân tích chi tiết chi tiêu của tôi tháng này. Tôi chi nhiều nhất cho mục nào? Có gì bất thường không?',
      color: Color(0xFF6C5CE7),
    ),
    QuickAction(
      label: 'Gợi ý tiết kiệm',
      emoji: '💡',
      prompt: 'Dựa trên chi tiêu của tôi, hãy đưa ra 5 gợi ý tiết kiệm cụ thể và thực tế nhất.',
      color: Color(0xFF00B894),
    ),
    QuickAction(
      label: 'Đánh giá tài chính',
      emoji: '🏆',
      prompt: 'Đánh giá tình hình tài chính tổng thể của tôi tháng này. Tỷ lệ tiết kiệm, mức chi tiêu có hợp lý không?',
      color: Color(0xFFFDAA5D),
    ),
    QuickAction(
      label: 'Cảnh báo chi tiêu',
      emoji: '⚠️',
      prompt: 'Kiểm tra xem tôi có đang chi tiêu vượt ngân sách không? Những danh mục nào cần cắt giảm?',
      color: Color(0xFFE17055),
    ),
    QuickAction(
      label: 'So sánh thu chi',
      emoji: '⚖️',
      prompt: 'So sánh thu nhập và chi tiêu của tôi tháng này. Tôi đang thâm hụt hay dư dả? Cho tôi lời khuyên.',
      color: Color(0xFF0984E3),
    ),
    QuickAction(
      label: 'Kế hoạch tháng sau',
      emoji: '📅',
      prompt: 'Dựa trên dữ liệu tháng này, lập kế hoạch chi tiêu cho tháng sau giúp tôi. Nên phân bổ ngân sách như thế nào?',
      color: Color(0xFFA29BFE),
    ),
    // === DỰ ĐOÁN TÀI CHÍNH ===
    QuickAction(
      label: 'Dự đoán cuối tháng',
      emoji: '🔮',
      prompt: 'Dự đoán chi tiêu và thu nhập cuối tháng này dựa trên tốc độ hiện tại. Tôi có vượt ngân sách không?',
      color: Color(0xFF6C5CE7),
    ),
    QuickAction(
      label: 'Xu hướng tài chính',
      emoji: '📈',
      prompt: 'Dự báo xu hướng tài chính 3-6-12 tháng tới. Tôi sẽ tích lũy được bao nhiêu? Nếu gửi tiết kiệm thì lãi bao nhiêu?',
      color: Color(0xFF00CEC9),
    ),
    QuickAction(
      label: 'Tư vấn đầu tư',
      emoji: '💹',
      prompt: 'So sánh các kênh đầu tư cho tôi: gửi tiết kiệm, chứng khoán, vàng, bất động sản. Nên phân bổ thế nào?',
      color: Color(0xFFE17055),
    ),
    QuickAction(
      label: 'Mục tiêu tiết kiệm',
      emoji: '🎯',
      prompt: 'Với mức tiết kiệm hiện tại, bao lâu tôi đạt được mục tiêu tiết kiệm mua xe, laptop, du lịch, nhà?',
      color: Color(0xFF00B894),
    ),
    QuickAction(
      label: 'Đánh giá rủi ro',
      emoji: '🛡️',
      prompt: 'Đánh giá rủi ro tài chính của tôi. Tôi có đang an toàn không? Cần cải thiện gì?',
      color: Color(0xFFFF7675),
    ),
    QuickAction(
      label: 'Kịch bản tài chính',
      emoji: '🎭',
      prompt: 'Phân tích 3 kịch bản tài chính: lạc quan, trung bình, bi quan. Nếu thu tăng/giảm 10% thì sao?',
      color: Color(0xFF0984E3),
    ),
    QuickAction(
      label: 'Tự do tài chính',
      emoji: '🏖️',
      prompt: 'Với tỷ lệ tiết kiệm hiện tại, bao giờ tôi đạt tự do tài chính (FIRE)? Cần bao nhiêu tiền để nghỉ hưu sớm?',
      color: Color(0xFFFDAA5D),
    ),
    QuickAction(
      label: 'Ảnh hưởng lạm phát',
      emoji: '📊',
      prompt: 'Lạm phát sẽ ảnh hưởng thế nào đến chi tiêu của tôi trong 1-3-5-10 năm tới? Cách bảo vệ?',
      color: Color(0xFFA29BFE),
    ),
    QuickAction(
      label: 'Dòng tiền',
      emoji: '💧',
      prompt: 'Dự báo dòng tiền 4 tuần tới và 3 tháng tới. Tôi có đủ tiền trang trải không?',
      color: Color(0xFF55A3E7),
    ),
  ];
}
