import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/quick_actions_bar.dart';
import 'widgets/financial_summary_header.dart';

class AiAdviceScreen extends ConsumerStatefulWidget {
  const AiAdviceScreen({super.key});

  @override
  ConsumerState<AiAdviceScreen> createState() => _AiAdviceScreenState();
}

class _AiAdviceScreenState extends ConsumerState<AiAdviceScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showQuickActions = true;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(text);
    _controller.clear();
    setState(() => _showQuickActions = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final now = DateTime.now();
    final transactionsAsync = ref.watch(
      transactionsStreamProvider('${now.year}-${now.month}'),
    );
    final monthlyBudget = ref.watch(monthlyBudgetProvider);

    // Auto scroll when new messages arrive
    ref.listen(chatProvider, (prev, next) {
      if (prev != null && next.length > prev.length) {
        _scrollToBottom();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🤖', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Tài Chính',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Trợ lý thông minh',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Cuộc trò chuyện mới',
            onPressed: () {
              ref.read(chatProvider.notifier).clearChat();
              setState(() => _showQuickActions = true);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Financial Summary Header
          transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) return const SizedBox.shrink();
              final totalIncome = transactions
                  .where((t) => t.isIncome)
                  .fold<double>(0, (s, t) => s + t.amount);
              final totalExpense = transactions
                  .where((t) => t.isExpense)
                  .fold<double>(0, (s, t) => s + t.amount);
              return FinancialSummaryHeader(
                totalIncome: totalIncome,
                totalExpense: totalExpense,
                balance: totalIncome - totalExpense,
                budget: monthlyBudget,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(
                  message: messages[index],
                  showAvatar: index == 0 ||
                      messages[index].role != messages[index - 1].role,
                );
              },
            ),
          ),

          // Quick Actions
          if (_showQuickActions && messages.length <= 1)
            QuickActionsBar(
              onActionTap: (action) {
                _sendMessage(action.prompt);
              },
            ),

          // Input Bar
          _buildInputBar(context, isDark),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quick suggestions button
          IconButton(
            icon: Icon(
              _showQuickActions
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.lightbulb_outline_rounded,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() => _showQuickActions = !_showQuickActions);
            },
          ),
          // Text input
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Hỏi về tài chính của bạn...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 4),
          // Send button
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(_controller.text),
            ),
          ),
        ],
      ),
    );
  }
}
