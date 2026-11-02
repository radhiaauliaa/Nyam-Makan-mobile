
import 'firestore_chatbot_service.dart';
import 'gemini_service.dart';
import 'prompt_builder.dart';

class ChatbotService {
  final FirestoreChatbotService _firestoreService =
      FirestoreChatbotService();

  final GeminiService _geminiService =
      GeminiService();

  final PromptBuilder _promptBuilder =
      PromptBuilder();

  Future<String> sendMessage(String question) async {
    try {
      final databaseContext =
          await _firestoreService.getDatabaseContext(
        question,
      );

      final prompt =
          _promptBuilder.buildChatbotPrompt(
        question: question,
        databaseContext: databaseContext,
      );

      return await _geminiService.sendMessage(prompt);
    } catch (e) {
      throw Exception(
        'Gagal memproses pesan chatbot: $e',
      );
    }
  }
}
