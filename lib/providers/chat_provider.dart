import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider() {
    _messages.add(
      ChatMessage(
        id: _nextId(),
        sender: ChatSender.assistant,
        text: 'Xin chao, minh la tro ly AI quan ly chi tieu. Ban can tu van gi hom nay?',
        createdAt: DateTime.now(),
      ),
    );
  }

  final List<ChatMessage> _messages = <ChatMessage>[];
  bool _isSending = false;

  final List<QuickPrompt> quickPrompts = const <QuickPrompt>[
    QuickPrompt(
      title: 'Toi nen tiet kiem the nao?',
      prompt: 'Toi nen tiet kiem the nao voi muc thu nhap hien tai?',
      emoji: '💰',
    ),
    QuickPrompt(
      title: 'Thong ke chi tieu',
      prompt: 'Hay thong ke chi tieu va nhung khoan nao dang tang nhanh.',
      emoji: '📊',
    ),
    QuickPrompt(
      title: 'Goi y cat giam',
      prompt: 'Khoan chi nao minh co the cat giam trong thang nay?',
      emoji: '✂️',
    ),
  ];

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  bool get isSending => _isSending;

  Future<void> sendMessage(String rawInput) async {
    final String input = rawInput.trim();
    if (input.isEmpty || _isSending) {
      return;
    }

    _messages.add(
      ChatMessage(
        id: _nextId(),
        sender: ChatSender.user,
        text: input,
        createdAt: DateTime.now(),
      ),
    );

    _isSending = true;
    _messages.add(
      ChatMessage(
        id: _nextId(),
        sender: ChatSender.assistant,
        text: '',
        createdAt: DateTime.now(),
        isTyping: true,
      ),
    );
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 850));

    _messages.removeLast();
    _messages.add(
      ChatMessage(
        id: _nextId(),
        sender: ChatSender.assistant,
        text: _buildReply(input),
        createdAt: DateTime.now(),
      ),
    );

    _isSending = false;
    notifyListeners();
  }

  Future<void> sendQuickPrompt(QuickPrompt prompt) {
    return sendMessage(prompt.prompt);
  }

  void clearConversation() {
    _messages
      ..clear()
      ..add(
        ChatMessage(
          id: _nextId(),
          sender: ChatSender.assistant,
          text: 'Da xoa lich su chat. Ban muon bat dau lai voi muc tieu nao?',
          createdAt: DateTime.now(),
        ),
      );
    notifyListeners();
  }

  String _buildReply(String input) {
    final String normalized = input.toLowerCase();

    if (normalized.contains('tiet kiem')) {
      return 'Goi y nhanh: ap dung quy tac 50/30/20, tu dong chuyen 20% thu nhap vao quy tiet kiem ngay sau khi nhan luong, va dat muc tieu tiet kiem theo tuan de de bam sat.';
    }

    if (normalized.contains('thong ke') || normalized.contains('chi tieu')) {
      return 'Ban nen theo doi 3 nhom chinh: an uong, di chuyen, giai tri. Neu 1 nhom vuot 10-15% so voi trung binh 4 tuan, hay dat canh bao va giam muc chi trong 2 tuan tiep theo.';
    }

    if (normalized.contains('cat giam') || normalized.contains('toi uu')) {
      return 'Thu uu tien cat giam chi phi linh hoat (an ngoai, mua sam ngau hung). Dat ngan sach theo tuan cho tung nhom va dung ngay khi cham nguong 90%.';
    }

    return 'Minh da ghi nhan. De tu van chinh xac hon, ban co the chia se tong thu nhap thang, tong chi, va muc tieu tiet kiem cua ban?';
  }

  String _nextId() => DateTime.now().microsecondsSinceEpoch.toString();
}
