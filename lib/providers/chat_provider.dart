/// File name: chat_provider.dart
/// Author: Nguyễn Thị Linh
/// Created: 2026-03-19
/// Description: Chat state management using Riverpod
/// 
/// Responsibilities:
/// - Manage chat messages state
/// - Handle sending messages to AI
/// - Manage quick actions
/// - Handle loading and error states
/// - Provide financial context to AI

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/chat_message.dart';
import '../data/services/ai_chat_service.dart';

/// Exception cho chat provider
class ChatProviderException implements Exception {
  final String message;

  ChatProviderException(this.message);

  @override
  String toString() => message;
}

/// State của Chat
class ChatState {
  /// Danh sách các tin nhắn
  final List<ChatMessage> messages;

  /// Tin nhắn đang được gửi
  final bool isLoading;

  /// Lỗi nếu có
  final String? error;

  /// Danh sách quick actions
  final List<QuickAction> quickActions;

  /// Financial context hiện tại
  final String financialContext;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.quickActions = const [],
    this.financialContext = '',
  });

  /// Tạo bản sao với các thuộc tính thay đổi
  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    List<QuickAction>? quickActions,
    String? financialContext,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      quickActions: quickActions ?? this.quickActions,
      financialContext: financialContext ?? this.financialContext,
    );
  }

  @override
  String toString() =>
      'ChatState(messages: ${messages.length}, isLoading: $isLoading, error: $error)';
}

/// Provider cho AiChatService (singleton)
final aiChatServiceProvider = Provider<AiChatService>((ref) {
  return AiChatService();
});

/// Provider cho Chat State (StateNotifier)
class ChatNotifier extends StateNotifier<ChatState> {
  final AiChatService _aiChatService;

  ChatNotifier(this._aiChatService)
      : super(
          ChatState(
            messages: [
              ChatMessage(
                type: ChatMessageType.assistant,
                content: 'Xin chào! 👋 Tôi là Chi Tiêu AI, trợ lý tài chính của bạn. '
                    'Hãy chia sẻ tình hình tài chính hiện tại để tôi có thể giúp bạn quản lý chi tiêu tốt hơn!',
              ),
            ],
            quickActions: defaultQuickActions,
          ),
        );

  /// Gửi tin nhắn
  ///
  /// Thực hiện:
  /// 1. Thêm user message vào danh sách
  /// 2. Gửi đến AI service
  /// 3. Thêm AI response vào danh sách
  /// 4. Cập nhật state
  ///
  /// @param message Tin nhắn từ người dùng
  Future<void> sendMessage(String message) async {
    try {
      // Kiểm tra input
      if (message.trim().isEmpty) {
        throw ChatProviderException('Vui lòng nhập tin nhắn');
      }

      // Thêm user message
      final userMessage = ChatMessage(
        type: ChatMessageType.user,
        content: message,
      );

      state = state.copyWith(
        messages: [...state.messages, userMessage],
        error: null,
      );

      // Bắt đầu loading
      state = state.copyWith(isLoading: true);

      // Gọi AI
      final response = await _aiChatService.sendMessage(
        userMessage: message,
        financialContext: state.financialContext,
      );

      // Thêm AI response
      final aiMessage = ChatMessage(
        type: ChatMessageType.assistant,
        content: response,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } on ChatProviderException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      final errorMessage = e.toString();
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      // Thêm error message vào chat
      final errorChatMessage = ChatMessage(
        type: ChatMessageType.system,
        content: '❌ $errorMessage',
        error: errorMessage,
      );

      state = state.copyWith(
        messages: [...state.messages, errorChatMessage],
      );
    }
  }

  /// Gửi tin nhắn từ quick action
  Future<void> sendQuickAction(QuickAction action) async {
    await sendMessage(action.messageText);
  }

  /// Cập nhật financial context
  void updateFinancialContext(String context) {
    state = state.copyWith(financialContext: context);
  }

  /// Cập nhật financial context từ dữ liệu
  void updateFinancialContextFromData({
    required double income,
    required double expense,
    required double budget,
    Map<String, double>? categories,
  }) {
    final context = _aiChatService.buildFinancialContext(
      income: income,
      expense: expense,
      budget: budget,
      categories: categories,
    );
    updateFinancialContext(context);
  }

  /// Xóa một tin nhắn
  void deleteMessage(String messageId) {
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != messageId).toList(),
    );
  }

  /// Xóa tất cả tin nhắn
  void clearMessages() {
    state = state.copyWith(
      messages: [
        ChatMessage(
          type: ChatMessageType.assistant,
          content: 'Xin chào! 👋 Tôi là Chi Tiêu AI, trợ lý tài chính của bạn. '
              'Hãy chia sẻ tình hình tài chính hiện tại để tôi có thể giúp bạn quản lý chi tiêu tốt hơn!',
        ),
      ],
    );
  }

  /// Cập nhật quick actions
  void updateQuickActions(List<QuickAction> actions) {
    state = state.copyWith(quickActions: actions);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Riverpod StateNotifier Provider
final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final aiChatService = ref.watch(aiChatServiceProvider);
  return ChatNotifier(aiChatService);
});

/// Selector: Lấy danh sách messages
final chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.messages;
});

/// Selector: Kiểm tra đang loading
final chatIsLoadingProvider = StateProvider<bool>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.isLoading;
});

/// Selector: Lấy error message
final chatErrorProvider = StateProvider<String?>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.error;
});

/// Selector: Lấy quick actions
final chatQuickActionsProvider = StateProvider<List<QuickAction>>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.quickActions;
});

/// Selector: Lấy financial context
final chatFinancialContextProvider = StateProvider<String>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.financialContext;
});
