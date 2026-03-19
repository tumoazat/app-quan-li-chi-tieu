/// File name: ai_chat_service.dart
/// Author: Nguyễn Thị Linh
/// Created: 2026-03-19
/// Description: Core Gemini API integration for AI chatbot
/// 
/// Responsibilities:
/// - Initialize Gemini GenerativeModel
/// - Send messages to Gemini API
/// - Build financial context from transaction data
/// - Handle API errors and responses
/// - Manage system prompts and generation config

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Exception được throw khi AI service gặp lỗi
class AiChatException implements Exception {
  final String message;
  final String? code;

  AiChatException({
    required this.message,
    this.code,
  });

  @override
  String toString() => message;
}

/// Service tích hợp Gemini API
/// 
/// Chuyên trách:
/// - Giao tiếp với Gemini API
/// - Xây dựng context tài chính
/// - Quản lý cấu hình model
class AiChatService {
  /// API Key cho Gemini (TODO: Move to environment variable)
  /// Hiện tại được hardcode, cần chuyển sang .env hoặc Remote Config
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';

  late final GenerativeModel _model;

  /// Khởi tạo AiChatService
  /// Thiết lập GenerativeModel với configuration
  AiChatService() {
    _initializeModel();
  }

  /// Khởi tạo Gemini model với cấu hình tối ưu
  void _initializeModel() {
    try {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topP: 0.95,
          topK: 40,
          maxOutputTokens: 2048,
        ),
        systemInstruction: Content.system(_buildSystemPrompt()),
        safetySettings: [
          SafetySetting(
            category: HarmCategory.hateSpeech,
            threshold: HarmBlockThreshold.medium,
          ),
          SafetySetting(
            category: HarmCategory.sexualContent,
            threshold: HarmBlockThreshold.high,
          ),
        ],
      );
      debugPrint('✅ Gemini Model initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Gemini model: $e');
      throw AiChatException(
        message: 'Failed to initialize AI model: $e',
        code: 'MODEL_INIT_ERROR',
      );
    }
  }

  /// Gửi tin nhắn tới Gemini API
  ///
  /// Gửi tin nhắn cùng với context tài chính để AI có thông tin
  /// cần thiết để đưa ra lời khuyên chính xác.
  ///
  /// @param userMessage Tin nhắn từ người dùng
  /// @param financialContext Context tài chính của người dùng
  /// @return Phản hồi từ Gemini
  /// @throws AiChatException nếu API call thất bại
  Future<String> sendMessage({
    required String userMessage,
    required String financialContext,
  }) async {
    return _safeApiCall(() async {
      try {
        // Kết hợp context tài chính và tin nhắn
        final prompt = '$financialContext\n\nCâu hỏi: $userMessage';

        debugPrint('📤 Sending to Gemini: $userMessage');

        final response = await _model.generateContent([
          Content.multi([
            TextPart(prompt),
          ]),
        ]);

        final result = response.text ?? 'Không có phản hồi';
        debugPrint('📥 Response from Gemini: ${result.substring(0, 50)}...');

        return result;
      } on GenerativeAIException catch (e) {
        debugPrint('❌ Gemini API Error: ${e.message}');
        throw AiChatException(
          message: 'Gemini API Error: ${e.message}',
          code: 'GEMINI_API_ERROR',
        );
      } catch (e) {
        debugPrint('❌ Unexpected Error: $e');
        throw AiChatException(
          message: 'Unexpected error: $e',
          code: 'UNKNOWN_ERROR',
        );
      }
    });
  }

  /// Xây dựng financial context từ dữ liệu chi tiêu
  ///
  /// Thực hiện:
  /// 1. Format dữ liệu tài chính
  /// 2. Tính toán thống kê (income, expense, balance)
  /// 3. Trả về string context đủ thông tin cho AI
  ///
  /// @param income Tổng thu nhập
  /// @param expense Tổng chi tiêu
  /// @param budget Ngân sách hàng tháng
  /// @param categories Danh sách chi tiêu theo danh mục
  /// @return Financial context string
  String buildFinancialContext({
    required double income,
    required double expense,
    required double budget,
    Map<String, double>? categories,
  }) {
    final balance = income - expense;
    final savingsRate =
        income > 0 ? ((balance / income) * 100).toStringAsFixed(1) : '0.0';
    final budgetUsage =
        budget > 0 ? ((expense / budget) * 100).toStringAsFixed(1) : '0.0';

    final categoriesText = _buildCategoriesText(categories ?? {});

    return '''
📊 DỮ LIỆU TÀI CHÍNH:
━━━━━━━━━━━━━━━━━━━━━━━━━━
💵 Thu nhập: ${_formatCurrency(income)}
📉 Chi tiêu: ${_formatCurrency(expense)}
💰 Số dư hiện tại: ${_formatCurrency(balance)}
💼 Ngân sách tháng: ${_formatCurrency(budget)}
📈 Mức tiết kiệm: $savingsRate%
⚠️ Ngân sách sử dụng: $budgetUsage%
$categoriesText
''';
  }

  /// Format dữ liệu danh mục chi tiêu
  String _buildCategoriesText(Map<String, double> categories) {
    if (categories.isEmpty) return '';

    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final categoriesStr = sorted
        .map((e) => '  • ${e.key}: ${_formatCurrency(e.value)}')
        .join('\n');

    return '''
📋 Chi tiêu theo danh mục:
$categoriesStr''';
  }

  /// Format số tiền theo định dạng Việt Nam (VNĐ)
  /// 
  /// Ví dụ: 1500000 -> "1.500.000đ"
  String _formatCurrency(double amount) {
    final formatter = _VietnamCurrencyFormatter();
    return formatter.format(amount);
  }

  /// Xây dựng system prompt cho AI
  /// 
  /// Định nghĩa tính cách, quy tắc, và cách hành động của AI
  String _buildSystemPrompt() => '''
Bạn là "Chi Tiêu AI" - một trợ lý tài chính thông minh, thân thiện và lạc quan.

🎯 QUY TẮC HOẠT ĐỘNG:
━━━━━━━━━━━━━━━━━━━━━━━━━━
1️⃣ Trả lời LUÔN bằng tiếng Việt, tự nhiên và dễ hiểu
2️⃣ Phân tích dựa trên dữ liệu THỰC tế, không bịa số
3️⃣ Lời khuyên phải CỤ THỂ với con số chính xác
4️⃣ Sử dụng emoji để trực quan hóa thông tin 👍
5️⃣ Giọng điệu thân thiện, khích lệ, không khi khô khan
6️⃣ Đơn vị tiền: VNĐ (format: 1.500.000đ)
7️⃣ Câu trả lời ngắn gọn nhưng đầy đủ (50-200 từ)
8️⃣ Nếu dữ liệu không đủ, hãy nói rõ cần thêm thông tin gì

💡 PHONG CÁCH TRỢ LÝ:
━━━━━━━━━━━━━━━━━━━━━━━━━━
✨ Tích cực và khích lệ
📊 Dựa dữ liệu và logic
🎯 Mục tiêu hướng đến
👥 Lắng nghe thấu đáo
💪 Hỗ trợ không nhượng bộ

🚫 TUYỆT ĐỐI KHÔNG:
━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Bịa số liệu hoặc dự đoán
❌ Đưa ra lời khuyên đầu tư tài chính
❌ Trả lời những câu hỏi ngoài lĩnh vực tài chính cá nhân
❌ Trở nên tiêu cực hoặc kèm theo lời chỉ trích
''';

  /// Safe wrapper cho API calls
  /// 
  /// Xử lý lỗi một cách nhất quán
  Future<String> _safeApiCall(Future<String> Function() apiCall) async {
    try {
      return await apiCall();
    } on GenerativeAIException catch (e) {
      debugPrint('❌ Gemini API Error: ${e.message}');
      return 'Xin lỗi, AI không thể trả lời lúc này. Vui lòng thử lại.';
    } on AiChatException {
      return 'Xin lỗi, có lỗi xảy ra. Vui lòng kiểm tra kết nối mạng.';
    } catch (e) {
      debugPrint('❌ Unexpected Error in API call: $e');
      return 'Có lỗi không mong muốn xảy ra. Vui lòng thử lại.';
    }
  }
}

/// Helper class để format tiền tệ Việt Nam
class _VietnamCurrencyFormatter {
  String format(double amount) {
    if (amount.isInfinite || amount.isNaN) {
      return '0đ';
    }

    final String numberStr = amount.toStringAsFixed(0);
    final StringBuffer result = StringBuffer();

    int count = 0;
    for (int i = numberStr.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result.write('.');
      }
      result.write(numberStr[i]);
      count++;
    }

    return '${result.toString().split('').reversed.join()}đ';
  }
}
