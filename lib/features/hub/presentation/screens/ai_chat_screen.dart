import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/models/ai_models.dart';
import '../../data/repositories/ai_repository.dart';

class AIChatScreen extends StatefulWidget {
  final String? conversationId;
  const AIChatScreen({super.key, this.conversationId});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _aiRepository = AIRepository();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  
  String? _activeConversationId;
  List<AIMessage> _messages = [];
  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _activeConversationId = widget.conversationId;
    if (_activeConversationId != null) _loadMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _aiRepository.getMessages(_activeConversationId!);
      if (mounted) {
        setState(() { _messages = messages; _isLoading = false; });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isGenerating) return;

    final prompt = text.trim();
    _textController.clear();

    try {
      if (_activeConversationId == null) {
        final conv = await _aiRepository.createConversation(prompt.length > 30 ? prompt.substring(0, 30) : prompt);
        _activeConversationId = conv.id;
      }

      final userMsg = await _aiRepository.sendMessage(conversationId: _activeConversationId!, content: prompt);
      setState(() { _messages.add(userMsg); _isGenerating = true; });
      _scrollToBottom();

      final aiResponse = await _aiRepository.getAIResponse(
        conversationId: _activeConversationId!,
        prompt: prompt,
        history: _messages.take(_messages.length - 1).toList(),
      );

      if (mounted) {
        setState(() {
          _messages.add(AIMessage(id: DateTime.now().toString(), conversationId: _activeConversationId!, userId: '', role: 'assistant', content: aiResponse, createdAt: DateTime.now()));
          _isGenerating = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('LinkUp AI', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.history_rounded, color: AppColors.primary), onPressed: () => _showHistory(context)),
          IconButton(icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary), onPressed: () => setState(() { _activeConversationId = null; _messages = []; })),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _buildMessageBubble(_messages[index], isDark),
                      ),
          ),
          if (_isGenerating) _buildGeneratingIndicator(isDark),
          _buildComposer(isDark),
        ],
      ),
    );
  }

  Widget _buildGeneratingIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          const SizedBox(width: 12),
          Text('AI is thinking...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text('Meet LinkUp AI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            const Text('Your premium assistant for ideas, writing, and learning.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 40),
            _buildSuggestionChip('✍️ Write a message', 'Draft a friendly reminder for my team meeting.'),
            _buildSuggestionChip('💡 Brainstorm ideas', '5 creative ideas for a weekend project.'),
            _buildSuggestionChip('📚 Explain simply', 'How does cloud computing work?'),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, String prompt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => _sendMessage(prompt),
        child: ListTile(
          dense: true,
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          trailing: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AIMessage message, bool isDark) {
    final isAI = message.role == 'assistant';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[
            Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white)),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAI ? (isDark ? AppColors.cardDark : Colors.white) : AppColors.primary,
                borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: Radius.circular(isAI ? 0 : 20), bottomRight: Radius.circular(isAI ? 20 : 0)),
                boxShadow: isAI ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))] : null,
              ),
              child: isAI 
                  ? MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontSize: 15, height: 1.5, fontWeight: FontWeight.w400),
                        code: TextStyle(backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100, fontSize: 13, fontFamily: 'monospace'),
                        codeblockDecoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  : Text(message.content, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500)),
            ),
          ),
          if (!isAI) ...[
            const SizedBox(width: 12),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.person_rounded, size: 16, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  Widget _buildComposer(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.grey.shade100, borderRadius: BorderRadius.circular(28), border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200)),
              child: TextField(
                controller: _textController,
                maxLines: 5,
                minLines: 1,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(hintText: 'Ask LinkUp AI...', border: InputBorder.none, filled: false, contentPadding: EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: IconButton(onPressed: () => _sendMessage(_textController.text), icon: const Icon(Icons.send_rounded, size: 22, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: _AIHistorySheet(
          onSelected: (id) {
            setState(() { _activeConversationId = id; _messages = []; });
            _loadMessages();
          },
        ),
      ),
    );
  }
}

class _AIHistorySheet extends StatelessWidget {
  final Function(String) onSelected;
  const _AIHistorySheet({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final aiRepository = AIRepository();

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.all(24), child: Text('Chat History', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20))),
          Expanded(
            child: StreamBuilder<List<AIConversation>>(
              stream: aiRepository.subscribeToConversations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final conversations = snapshot.data ?? [];
                if (conversations.isEmpty) return const Center(child: Text('No history yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)));
                return ListView.builder(
                  itemCount: conversations.length,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle), child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20)),
                      title: Text(conv.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(DateFormat('MMM d, h:mm a').format(conv.updatedAt), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey)),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey), onPressed: () => aiRepository.deleteConversation(conv.id)),
                      onTap: () { onSelected(conv.id); Navigator.pop(context); },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
