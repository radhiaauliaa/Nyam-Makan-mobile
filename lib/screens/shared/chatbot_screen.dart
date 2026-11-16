import 'package:flutter/material.dart';

import '../../services/chatbot_service.dart';
import '../../utils/theme.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Halo! Aku asisten Nyam! Makaan. Mau cari menu, restoran, promo, atau cek reservasi?',
      isUser: false,
    ),
  ];

  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? suggestion]) async {
    final question = (suggestion ?? _messageController.text).trim();
    if (question.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage(text: question, isUser: true));
    });
    _scrollToBottom();

    try {
      final response = await _chatbotService.sendMessage(question);
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(text: _cleanChatbotResponse(response), isUser: false),
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: _readableError(error), isUser: false));
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  String _readableError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) {
      return 'Maaf, chatbot sedang mengalami kendala. Coba lagi sebentar.';
    }
    return 'Maaf, aku belum bisa menjawab sekarang.\n$message';
  }

  String _cleanChatbotResponse(String response) {
    return response
        .trim()
        .replaceAllMapped(
          RegExp(r'\*{1,2}([^*\n]+?)\*{1,2}'),
          (match) => match[1]!,
        );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.lightOrange,
              child: Icon(Icons.smart_toy, color: AppColors.primaryOrange),
            ),
            SizedBox(width: 10),
            Text('Asisten Nyam!'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isSending) {
                  return const _TypingIndicator();
                }
                final message = _messages[index];
                return _MessageBubble(message: message);
              },
            ),
          ),
          if (_messages.length == 1 && !_isSending)
            _SuggestionRow(onSelected: _sendMessage),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Tulis pertanyaan...',
                  prefixIcon: const Icon(Icons.chat_bubble_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isSending ? null : _sendMessage,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final color = message.isUser ? AppColors.primaryOrange : Colors.white;
    final textColor = message.isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isUser ? 18 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 18),
          ),
          boxShadow: message.isUser
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, height: 1.4),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Sedang mengetik...'),
          ],
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      'Cari promo',
      'Rekomendasi menu',
      'Cek reservasi saya',
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ActionChip(
            label: Text(suggestion),
            onPressed: () => onSelected(suggestion),
            side: const BorderSide(color: AppColors.lightOrange),
            backgroundColor: Colors.white,
            labelStyle: const TextStyle(color: AppColors.primaryOrange),
          );
        },
      ),
    );
  }
}
