import 'dart:convert';

import 'firestore_chatbot_service.dart';
import 'gemini_service.dart';
import 'prompt_builder.dart';

class ChatbotResponse {
  const ChatbotResponse({required this.text, required this.suggestedQuestions});

  final String text;
  final List<String> suggestedQuestions;
}

class ChatbotService {
  final FirestoreChatbotService _firestoreService = FirestoreChatbotService();

  final GeminiService _geminiService = GeminiService();

  final PromptBuilder _promptBuilder = PromptBuilder();

  Future<ChatbotResponse> sendMessage(String question) async {
    try {
      final databaseContext = await _firestoreService.getDatabaseContext(
        question,
      );

      final prompt = _promptBuilder.buildChatbotPrompt(
        question: question,
        databaseContext: databaseContext,
      );

      final response = await _geminiService.sendMessage(prompt);
      return _parseResponse(response, question);
    } catch (e) {
      throw Exception('Gagal memproses pesan chatbot: $e');
    }
  }

  ChatbotResponse _parseResponse(String response, String question) {
    const marker = '---SUGGESTED_QUESTIONS---';
    final markerIndex = response.indexOf(marker);
    if (markerIndex < 0) {
      return ChatbotResponse(
        text: response.trim(),
        suggestedQuestions: _fallbackSuggestions(question, response),
      );
    }

    final text = response.substring(0, markerIndex).trim();
    final jsonPart = response.substring(markerIndex + marker.length).trim();
    final firstBracket = jsonPart.indexOf('[');
    final lastBracket = jsonPart.lastIndexOf(']');

    if (firstBracket >= 0 && lastBracket > firstBracket) {
      try {
        final decoded = jsonDecode(
          jsonPart.substring(firstBracket, lastBracket + 1),
        );
        if (decoded is List) {
          final suggestions = decoded
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .take(3)
              .toList();
          if (suggestions.isNotEmpty) {
            return ChatbotResponse(
              text: text.isEmpty ? response.trim() : text,
              suggestedQuestions: suggestions,
            );
          }
        }
      } catch (_) {
        // Fall back to context-aware suggestions below.
      }
    }

    return ChatbotResponse(
      text: text.isEmpty ? response.trim() : text,
      suggestedQuestions: _fallbackSuggestions(question, response),
    );
  }

  List<String> _fallbackSuggestions(String question, String response) {
    final text = '${question.toLowerCase()} ${response.toLowerCase()}';
    if (text.contains('promo')) {
      return const [
        'Promo mana yang sedang berlaku?',
        'Cari promo makanan murah',
        'Restoran mana yang punya diskon?',
      ];
    }
    if (text.contains('reservasi') || text.contains('booking')) {
      return const [
        'Cek status reservasi saya',
        'Reservasi untuk tanggal berapa?',
        'Bagaimana cara membatalkan reservasi?',
      ];
    }
    if (text.contains('menu') ||
        text.contains('makanan') ||
        text.contains('kuliner')) {
      return const [
        'Rekomendasikan menu favorit',
        'Cari menu dengan harga terjangkau',
        'Menu apa yang cocok untuk makan malam?',
      ];
    }
    if (text.contains('restoran')) {
      return const [
        'Restoran mana yang dekat saya?',
        'Cari restoran paling populer',
        'Restoran mana yang punya rating terbaik?',
      ];
    }
    return const [
      'Cari restoran terdekat',
      'Lihat promo yang tersedia',
      'Rekomendasikan menu hari ini',
    ];
  }
}
