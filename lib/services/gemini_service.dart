
import 'package:firebase_ai/firebase_ai.dart';

class GeminiService {
  final GenerativeModel _model =
      FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.5-flash-lite',
    generationConfig: GenerationConfig(
      maxOutputTokens: 100,
    ),
  );

  Future<String> sendMessage(String message) async {
    try {
      print('Mengirim permintaan ke Gemini...');

      final response = await _model.generateContent([
        Content.text(message),
      ]);

      print('Respons Gemini: ${response.text}');

      return response.text ?? 'Tidak ada respons.';
    } catch (e, stackTrace) {
      print('GEMINI ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }
}
