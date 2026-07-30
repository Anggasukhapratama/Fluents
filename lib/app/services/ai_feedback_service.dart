// lib/app/services/ai_feedback_service.dart
import 'dart:async';
import 'groq_service.dart';

class AiFeedbackService {
  final GroqService _groqService = GroqService();

  Future<String> generateRecommendationWithDetailedPrompt(String prompt) async {
    final optimizedPrompt =
        '''
$prompt

CATATAN: Bahasa Indonesia natural, tanpa markdown (*, -, #, **), maksimal 100 kata.
''';
    return _groqService.generateText(
      prompt: optimizedPrompt,
      temperature: 0.7,
      maxTokens: 350,
      fallback: _getFallbackRecommendation(),
    );
  }

  Future<(Stream<String> stream, Future<String> result)>
  generateRecommendationStream(String prompt) async {
    final optimizedPrompt =
        '''
$prompt

INSTRUKSI PENTING:
- Jawab dengan bahasa Indonesia yang natural dan mudah dibaca
- JANGAN gunakan format markdown apapun (*, -, #, **, ##, ###)
- JANGAN gunakan bullet points atau numbering
- Gunakan paragraf biasa dengan line breaks untuk pemisahan
- Maksimum 200 kata
- Tulis seperti sedang berbicara langsung kepada user
''';

    final controller = StreamController<String>();
    final done = Completer<String>();

    () async {
      try {
        final result = await _groqService.generateText(
          prompt: optimizedPrompt,
          temperature: 0.7,
          maxTokens: 450,
          fallback: _getFallbackRecommendation(),
        );

        final words = result.split(' ');
        final buffer = StringBuffer();
        for (final word in words) {
          buffer.write('$word ');
          controller.add(buffer.toString().trim());
          await Future.delayed(const Duration(milliseconds: 30));
        }
        done.complete(result);
      } catch (e) {
        final fallback = _getFallbackRecommendation();
        controller.add(fallback);
        done.complete(fallback);
      } finally {
        await controller.close();
      }
    }();

    return (controller.stream, done.future);
  }

  Future<String> correctAnswerWithStructuredFeedback({
    required String question,
    required String userAnswer,
    required String jobTarget,
  }) async {
    final prompt =
        '''
Anda adalah HRD profesional yang memberikan feedback untuk wawancara posisi "$jobTarget".

PERTANYAAN: $question

JAWABAN KANDIDAT: ${userAnswer.isEmpty ? '(tidak menjawab)' : userAnswer}

Berikan feedback dengan format STRUKTUR berikut (pisahkan dengan garis pemisah "---"):

KELEBIHAN:
[tulis kelebihan jawaban, jika tidak ada tulis "Tidak ada kelebihan yang signifikan"]

---
KEKURANGAN:
[tulis kekurangan/saran perbaikan]

---
CONTOH JAWABAN LEBIH BAIK:
[tulis contoh kalimat jawaban yang lebih baik untuk pertanyaan ini]

Aturan:
- Maksimal 40 kata per bagian
- Gunakan bahasa Indonesia yang baik
- Jangan tambahkan teks di luar format
''';

    final result = await _groqService.generateText(
      prompt: prompt,
      temperature: 0.6,
      maxTokens: 350,
      fallback: '',
    );

    if (result.isEmpty) return _getFallbackStructuredFeedback(userAnswer);
    return result;
  }

  Map<String, String> parseStructuredFeedback(String feedback) {
    final parts = feedback.split('---');
    String strengths = '';
    String weaknesses = '';
    String example = '';

    for (var part in parts) {
      part = part.trim();
      if (part.startsWith('KELEBIHAN:')) {
        strengths = part.replaceFirst('KELEBIHAN:', '').trim();
      } else if (part.startsWith('KEKURANGAN:')) {
        weaknesses = part.replaceFirst('KEKURANGAN:', '').trim();
      } else if (part.startsWith('CONTOH JAWABAN LEBIH BAIK:')) {
        example = part.replaceFirst('CONTOH JAWABAN LEBIH BAIK:', '').trim();
      }
    }

    if (strengths.isEmpty && weaknesses.isEmpty && example.isEmpty) {
      return {
        'strengths': 'Jawaban diterima',
        'weaknesses': 'Coba kembangkan jawaban dengan lebih spesifik',
        'example': 'Berikan contoh konkret dari pengalaman Anda',
      };
    }

    return {
      'strengths': strengths,
      'weaknesses': weaknesses,
      'example': example,
    };
  }

  // ============================================================
  // GENERATE ANALISIS KONTAK MATA - DENGAN TOTAL BREAKS
  // ============================================================
  Future<String> generateEyeContactAnalysis({
    required double focusPercentage,
    required String eyeLabel,
    required int totalBreaks,
    required int wpm,
    required int fillerCount,
    required int totalWords,
  }) async {
    final prompt =
        '''
Anda adalah HRD profesional. Berikan analisis singkat tentang kontak mata kandidat berdasarkan data berikut:

- Persentase waktu wajah terlihat (fokus): ${focusPercentage.toStringAsFixed(0)}%
- Status Kontak Mata: "$eyeLabel"
- Total kali menengok/mengalihkan pandangan: $totalBreaks kali
- Kecepatan bicara: $wpm WPM (ideal 130-160)
- Kata pengisi: $fillerCount kali
- Total kata: $totalWords

Buat analisis dengan format berikut (tanpa markdown, bahasa Indonesia):

KESIMPULAN:
[1-2 kalimat tentang keseluruhan performa kontak mata dan saran perbaikan singkat]

SARAN KONTAK MATA:
[2-3 kalimat spesifik tentang cara memperbaiki kontak mata sesuai dengan status di atas]

MOTIVASI:
[1 kalimat pendek untuk menyemangati]

ATURAN: Maksimal 100 kata, tanpa markdown, langsung ke inti.
''';

    final result = await _groqService.generateText(
      prompt: prompt,
      temperature: 0.6,
      maxTokens: 400,
      fallback: _getFallbackEyeAnalysis(),
    );
    return result.isEmpty ? _getFallbackEyeAnalysis() : result;
  }

  // ============================================================
  // FALLBACK METHODS
  // ============================================================

  String _getFallbackRecommendation() {
    return '''
SARAN KONTAK MATA: Usahakan wajah terlihat minimal 70% dari total sesi.
SARAN VERBAL: Kurangi kata pengisi seperti "umm", "anu".
KESIMPULAN: Terus berlatih untuk meningkatkan performa
MOTIVASI: Setiap latihan membuat Anda lebih siap!
''';
  }

  String _getFallbackStructuredFeedback(String userAnswer) {
    if (userAnswer.isEmpty) {
      return '''
KELEBIHAN:
Tidak ada jawaban yang diberikan

---
KEKURANGAN:
Sebaiknya jawab pertanyaan meskipun hanya secara singkat

---
CONTOH JAWABAN LEBIH BAIK:
Coba jawab dengan struktur: perkenalan singkat, poin utama, dan penutup.
''';
    }
    return '''
KELEBIHAN:
Anda sudah berusaha menjawab pertanyaan

---
KEKURANGAN:
Coba lebih spesifik dan berikan contoh konkret

---
CONTOH JAWABAN LEBIH BAIK:
Gunakan metode STAR: Situasi, Tugas, Aksi, Hasil untuk menjelaskan pengalaman.
''';
  }

  String _getFallbackEyeAnalysis() {
    return '''
KESIMPULAN:
Performa kontak mata Anda masih perlu ditingkatkan. Usahakan wajah terlihat minimal 70% dari total sesi.

SARAN KONTAK MATA:
Atur posisi duduk agar wajah selalu dalam jangkauan kamera. Hindari menunduk atau melihat ke samping terlalu sering.

MOTIVASI:
Setiap latihan membuat Anda lebih percaya diri!
''';
  }
}
