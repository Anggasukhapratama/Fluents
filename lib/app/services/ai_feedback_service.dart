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
- Kontak Mata: "$eyeLabel" (${eyeViolations <= 3 ? 2 : (eyeViolations <= 6 ? 1 : 0)}/2), tidak fokus $eyeViolations kali
  Detail: melirik kiri $lookLeftCount, melirik kanan $lookRightCount, menunduk $lookDownCount
- Ekspresi: "$smileLabel" ($smilePoints/2), momen antusias $enthusiasmMoments kali
- Postur: "$postureLabel" (${postureViolations <= 3 ? 2 : (postureViolations <= 6 ? 1 : 0)}/2), tidak stabil $postureViolations kali
  Detail: bahu miring kiri $headTiltLeftCount, bahu miring kanan $headTiltRightCount, kepala menunduk $headDownCount
- Kecepatan: $wpm WPM (ideal 130-160), filler $fillerCount kali
- Total: $totalPoints/$maxPoints

FORMAT (ikuti persis, tanpa markdown):

KESIMPULAN:
[1-2 kalimat: sebutkan hasilnya secara keseluruhan, lalu beri 1 kalimat koreksi singkat apa yang perlu ditingkatkan]

POIN UTAMA:

Kontak Mata: $eyeLabel (${eyeViolations <= 3 ? 2 : (eyeViolations <= 6 ? 1 : 0)}/2)
[2 kalimat: kondisi kontak mata, lalu cara memperbaikinya]

Ekspresi: $smileLabel ($smilePoints/2)
[2 kalimat: kondisi ekspresi, lalu cara memperbaikinya]

Postur: $postureLabel (${postureViolations <= 3 ? 2 : (postureViolations <= 6 ? 1 : 0)}/2)
[2 kalimat: kondisi postur, lalu cara memperbaikinya]

HASIL OVERALL:
$totalPoints/$maxPoints poin

REKOMENDASI:
1. [saran konkret dari poin utama]
2. [saran konkret dari poin utama]
3. [saran konkret dari poin utama]

MOTIVASI:
[1 kalimat pendek yang nyambung dengan rekomendasi di atas]

ATURAN: Bahasa Indonesia, tanpa markdown (* - # **). Kalimat pendek dan langsung ke inti. Maksimal 150 kata total.
''';

    final result = await _groqService.generateText(
      prompt: prompt,
      temperature: 0.6,
      maxTokens: 600,
      fallback: '',
    );

    if (result.isEmpty) return _getFallbackDetailAnalysis(overallLabel);
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

  String _getFallbackDetailAnalysis(String overallLabel) {
    if (overallLabel == 'Sangat Percaya Diri' ||
        overallLabel == 'Siap Wawancara') {
      return '''
KESIMPULAN:
Performa Anda sudah sangat baik. Pertahankan konsistensi ini di wawancara sesungguhnya.

POIN UTAMA:

Kontak Mata: Fokus terhadap Pewawancara (2/2)
Tatapan Anda terjaga baik ke kamera. Pertahankan kebiasaan ini.

Ekspresi: Ramah dan Profesional (2/2)
Senyum Anda natural dan tepat. Jaga agar tetap tulus, jangan dipaksakan.

Postur: Sikap Profesional (2/2)
Postur tubuh stabil dan rapi. Lanjutkan posisi duduk yang tegak.

HASIL OVERALL:
6/6 poin

REKOMENDASI:
1. Pertahankan kontak mata ke kamera
2. Jaga senyum tetap natural
3. Pertahankan postur tegak dan rileks

MOTIVASI:
Anda siap wawancara! Pertahankan kebiasaan baik ini.
''';
    } else if (overallLabel == 'Cukup Baik') {
      return '''
KESIMPULAN:
Performa Anda cukup baik, namun masih bisa ditingkatkan terutama pada fokus dan kestabilan.

POIN UTAMA:

Kontak Mata: Sesekali Terdistraksi (1/2)
Sesekali tatapan Anda teralihkan dari kamera. Coba tatap kamera seperti menatap mata HRD.

Ekspresi: Cukup Ramah (1/2)
Antusiasme Anda belum konsisten. Tunjukkan senyum natural di momen yang tepat.

Postur: Sedikit Gelisah (1/2)
Postur sedikit kurang stabil. Duduk tegak dengan sandaran punggung.

HASIL OVERALL:
4/6 poin

REKOMENDASI:
1. Fokuskan pandangan ke kamera
2. Tunjukkan 2-5 momen antusias
3. Jaga postur tetap tegak dan stabil

MOTIVASI:
Anda di jalur yang tepat, sedikit latihan lagi pasti lebih baik!
''';
    } else {
      return '''
KESIMPULAN:
Performa Anda masih perlu banyak latihan, terutama pada fokus, ekspresi, dan postur.

POIN UTAMA:

Kontak Mata: Tidak Fokus (0-1/2)
Tatapan Anda sering teralihkan. Latih fokus menatap kamera secara konsisten.

Ekspresi: Terlalu Tegang (0-1/2)
Ekspresi terlalu datar atau berlebihan. Tunjukkan senyum natural secukupnya.

Postur: Kurang Tenang (0-1/2)
Postur kurang stabil dan tegak. Duduk tegak dengan kedua kaki menapak lantai.

HASIL OVERALL:
0-3/6 poin

REKOMENDASI:
1. Latih kontak mata 5 menit setiap hari
2. Tunjukkan senyum natural 2-5 kali per sesi
3. Duduk tegak dan jaga kestabilan postur

MOTIVASI:
Jangan menyerah, latihan rutin akan membawa kemajuan!
''';
    }
  }
}
