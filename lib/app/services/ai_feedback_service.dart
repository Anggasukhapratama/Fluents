// lib/app/services/ai_feedback_service.dart
import 'dart:async';
import 'groq_service.dart';

/// Service untuk menghasilkan REKOMENDASI berdasarkan data perilaku
/// Menggunakan GroqService (model: llama-3.1-8b-instant) dengan
/// rotasi API Key otomatis di dalam GroqService.
///
/// LABEL SESUAI HRD:
/// - Kontak Mata: "Fokus terhadap Pewawancara" | "Sesekali Terdistraksi" | "Tidak Fokus"
/// - Ekspresi: "Ramah dan Profesional" | "Cukup Ramah" | "Terlalu Tegang" | "Tidak Proporsional"
/// - Postur: "Sikap Profesional" | "Sedikit Gelisah" | "Kurang Tenang"
class AiFeedbackService {
  final GroqService _groqService = GroqService();

  // ============================================================
  // GENERATE REKOMENDASI DENGAN PROMPT DARI CONTROLLER
  // ============================================================
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

  // ============================================================
  // STREAM VERSION
  // ============================================================
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

  // ============================================================
  // KOREKSI JAWABAN PER PERTANYAAN
  // ============================================================
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

  /// Parse structured feedback menjadi map
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
  // GENERATE DETAIL ANALISIS PERILAKU LENGKAP
  // TANPA SKOR / POIN (HANYA DESKRIPTIF)
  // LABEL SESUAI HRD
  // ============================================================
  Future<String> generateBehaviorDetailAnalysis({
    required String eyeLabel,
    required int eyeViolations,
    required String smileLabel,
    required int smileCount,
    required int neutralCount,
    required String postureLabel,
    required int postureViolations,
    required int totalPoints,
    required int maxPoints,
    required String overallLabel,
    required int lookLeftCount,
    required int lookRightCount,
    required int lookDownCount,
    required int headTiltLeftCount,
    required int headTiltRightCount,
    required int headDownCount,
    required int wpm,
    required int fillerCount,
    required int totalWords,
    int enthusiasmMoments = 0,
    int smilePoints = 0,
  }) async {
    final prompt =
        '''
Anda HRD profesional. Buat analisis hasil wawancara dari data ini. Ringkas tapi informatif.

DATA:
- Kontak Mata: "$eyeLabel" (tidak fokus $eyeViolations kali)
  Detail: melirik kiri $lookLeftCount, melirik kanan $lookRightCount, menunduk $lookDownCount
- Ekspresi: "$smileLabel" (momen antusias $enthusiasmMoments kali)
- Postur: "$postureLabel" (tidak stabil $postureViolations kali)
  Detail: bahu miring kiri $headTiltLeftCount, bahu miring kanan $headTiltRightCount, kepala menunduk $headDownCount
- Kecepatan: $wpm WPM (ideal 130-160), filler $fillerCount kali

FORMAT (ikuti persis, tanpa markdown):

KESIMPULAN:
[1-2 kalimat: sebutkan hasilnya secara keseluruhan, lalu beri 1 kalimat koreksi singkat apa yang perlu ditingkatkan. JANGAN sebutkan angka atau skor.]

POIN UTAMA:

Kontak Mata: $eyeLabel
[2 kalimat: kondisi kontak mata, lalu cara memperbaikinya. JANGAN sebutkan angka atau skor.]

Ekspresi: $smileLabel
[2 kalimat: kondisi ekspresi, lalu cara memperbaikinya. JANGAN sebutkan angka atau skor.]

Postur: $postureLabel
[2 kalimat: kondisi postur, lalu cara memperbaikinya. JANGAN sebutkan angka atau skor.]

REKOMENDASI:
1. [saran konkret dari poin utama]
2. [saran konkret dari poin utama]
3. [saran konkret dari poin utama]

MOTIVASI:
[1 kalimat pendek yang nyambung dengan rekomendasi di atas]

ATURAN: Bahasa Indonesia, tanpa markdown (* - # **). Kalimat pendek dan langsung ke inti. Maksimal 150 kata total. JANGAN sebutkan angka skor atau poin sama sekali.
''';

    final result = await _groqService.generateText(
      prompt: prompt,
      temperature: 0.6,
      maxTokens: 600,
      fallback: '',
    );

    if (result.isEmpty) return _getFallbackDetailAnalysis();
    return result;
  }

  // ============================================================
  // FALLBACK METHODS
  // ============================================================

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

  String _getFallbackDetailAnalysis() {
    return '''
KESIMPULAN:
Performa Anda cukup baik, namun masih ada beberapa aspek yang bisa ditingkatkan, terutama pada fokus dan kestabilan postur.

POIN UTAMA:

Kontak Mata: Fokus terhadap Pewawancara
Tatapan Anda sudah cukup baik, tetapi sesekali masih teralihkan. Coba bayangkan kamera adalah mata pewawancara dan tahan pandangan lebih lama.

Ekspresi: Ramah dan Profesional
Anda menunjukkan ekspresi yang natural dan tepat. Pertahankan senyum di momen yang pas, jangan berlebihan.

Postur: Sikap Profesional
Postur tubuh Anda tergolong stabil. Pastikan bahu tetap rileks dan punggung tegak sepanjang wawancara.

REKOMENDASI:
1. Latih kontak mata dengan menatap kamera 5 menit setiap hari.
2. Jaga ekspresi tetap natural dengan tersenyum saat pembukaan dan penutupan.
3. Perbaiki postur dengan duduk tegak dan menempelkan punggung ke sandaran kursi.

MOTIVASI:
Setiap latihan membawa Anda selangkah lebih dekat ke kesuksesan wawancara!
''';
  }
}
