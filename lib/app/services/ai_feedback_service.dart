// lib/app/services/ai_feedback_service.dart
import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';

/// Service untuk berinteraksi dengan Firebase AI (Google AI)
/// Menghasilkan REKOMENDASI berdasarkan data perilaku
class AiFeedbackService {
  // Gunakan Gemini 1.5 Flash untuk kecepatan maksimal
  static const String _modelName = 'gemini-2.5-flash-lite';

  // ===== GENERATE REKOMENDASI DENGAN PROMPT DARI CONTROLLER =====
  Future<String> generateRecommendationWithDetailedPrompt(String prompt) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: _modelName,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 450,
        ),
      );

      final optimizedPrompt =
          '''
$prompt

INSTRUKSI:
- Jawab SINGKAT dan LANGSUNG
- JANGAN gunakan markdown (*, -, #)
- Maksimum 200 kata
''';

      final response = await model.generateContent([
        Content.text(optimizedPrompt),
      ]);
      return response.text?.trim() ?? _getFallbackRecommendation();
    } catch (e) {
      print('❌ Error: $e');
      return _getFallbackRecommendation();
    }
  }

  // ===== STREAM VERSION =====
  Future<(Stream<String> stream, Future<String> result)>
  generateRecommendationStream(String prompt) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: _modelName,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 450,
      ),
    );

    final optimizedPrompt =
        '''
$prompt

INSTRUKSI:
- Jawab SINGKAT dan LANGSUNG
- JANGAN gunakan markdown (*, -, #)
- Maksimum 200 kata
''';

    final respStream = model.generateContentStream([
      Content.text(optimizedPrompt),
    ]);

    final controller = StreamController<String>();
    final buffer = StringBuffer();
    final done = Completer<String>();

    () async {
      try {
        await for (final chunk in respStream) {
          final t = chunk.text;
          if (t != null && t.isNotEmpty) {
            buffer.write(t);
            controller.add(buffer.toString());
          }
        }
        done.complete(buffer.toString());
      } catch (e) {
        done.completeError(e);
      } finally {
        await controller.close();
      }
    }();

    return (controller.stream, done.future);
  }

  // ===== FALLBACK (JIKA AI GAGAL) =====
  String _getFallbackRecommendation() {
    return '''
SARAN KONTAK MATA: Tatap kamera seperti menatap mata HRD
SARAN EKSPRESI: Tersenyum di awal dan akhir jawaban
SARAN POSTUR: Duduk tegak dan rileks
SARAN VERBAL: Kurangi kata pengisi
KESIMPULAN: Terus berlatih untuk meningkatkan performa
MOTIVASI: Setiap latihan membuat Anda lebih siap!
''';
  }
}
