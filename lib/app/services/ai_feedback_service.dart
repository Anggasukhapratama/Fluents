// lib/app/services/ai_feedback_service.dart
import 'dart:async';
import 'groq_service.dart';

/// Service untuk menghasilkan REKOMENDASI berdasarkan data perilaku
/// Menggunakan GeminiKeyManager untuk rotasi API Key otomatis
class AiFeedbackService {
  static const String _modelName = 'gemini-2.5-flash';
  final GroqService _groqService = GroqService();

  // ===== GENERATE REKOMENDASI DENGAN PROMPT DARI CONTROLLER =====
  Future<String> generateRecommendationWithDetailedPrompt(String prompt) async {
    final optimizedPrompt = '''
$prompt

INSTRUKSI PENTING:
- Jawab dengan bahasa Indonesia yang natural dan mudah dibaca
- JANGAN gunakan format markdown apapun (*, -, #, **, ##, ###)
- JANGAN gunakan bullet points atau numbering
- Gunakan paragraf biasa dengan line breaks untuk pemisahan
- Maksimum 200 kata
- Tulis seperti sedang berbicara langsung kepada user
''';

    return _groqService.generateText(
      prompt: optimizedPrompt,
      temperature: 0.7,
      maxTokens: 450,
      fallback: _getFallbackRecommendation(),
    );
  }

  // ===== STREAM VERSION =====
  Future<(Stream<String> stream, Future<String> result)>
  generateRecommendationStream(String prompt) async {
    final optimizedPrompt = '''
$prompt

INSTRUKSI PENTING:
- Jawab dengan bahasa Indonesia yang natural dan mudah dibaca
- JANGAN gunakan format markdown apapun (*, -, #, **, ##, ###)
- JANGAN gunakan bullet points atau numbering
- Gunakan paragraf biasa dengan line breaks untuk pemisahan
- Maksimum 200 kata
- Tulis seperti sedang berbicara langsung kepada user
''';

    // Buat stream controller
    final controller = StreamController<String>();
    final done = Completer<String>();

    // Jalankan async agar stream bisa langsung dikembalikan
    () async {
      try {
        final result = await _groqService.generateText(
          prompt: optimizedPrompt,
          temperature: 0.7,
          maxTokens: 450,
          fallback: _getFallbackRecommendation(),
        );

        // Simulasi streaming karakter per karakter (smooth UX)
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

  // ===== KOREKSI JAWABAN PER PERTANYAAN =====
  Future<String> correctAnswerWithStructuredFeedback({
    required String question,
    required String userAnswer,
    required String jobTarget,
  }) async {
    final prompt = '''
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

  // ===== GENERATE DETAIL ANALISIS PERILAKU LENGKAP =====
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
  }) async {
    final prompt = '''
Anda adalah psikolog dan HRD profesional yang memberikan analisis mendetail untuk hasil wawancara.

DATA LENGKAP KANDIDAT:

1. KONTAK MATA:
   - Melirik ke kiri: $lookLeftCount kali
   - Melirik ke kanan: $lookRightCount kali
   - Menunduk: $lookDownCount kali
   - Total pelanggaran: $eyeViolations kali
   - Label: "$eyeLabel"
   - Poin: ${eyeViolations <= 3 ? 2 : (eyeViolations <= 6 ? 1 : 0)}/2

2. EKSPRESI WAJAH:
   - Tersenyum: $smileCount kali
   - Ekspresi netral: $neutralCount kali
   - Label: "$smileLabel"
   - Poin: ${(smileCount >= 3 && smileCount > neutralCount) ? 2 : (smileCount >= 1 ? 1 : 0)}/2

3. POSTUR TUBUH:
   - Bahu miring ke kiri: $headTiltLeftCount kali
   - Bahu miring ke kanan: $headTiltRightCount kali
   - Kepala menunduk: $headDownCount kali
   - Total pelanggaran: $postureViolations kali
   - Label: "$postureLabel"
   - Poin: ${postureViolations <= 3 ? 2 : (postureViolations <= 6 ? 1 : 0)}/2

4. KOMUNIKASI VERBAL:
   - Kecepatan bicara: $wpm WPM
   - Kata pengisi: $fillerCount kali
   - Total kata: $totalWords kata

5. HASIL OVERALL:
   - Status: "$overallLabel"
   - Total Poin: $totalPoints/$maxPoints

TUGAS ANDA:
Buat analisis detail dengan format berikut. Gunakan bahasa Indonesia yang baik, profesional, dan detail. Panjang analisis sekitar 400-600 kata.

PENTING: JANGAN gunakan format markdown apapun seperti *, -, #, **, ##, ###. Tulis dengan format teks biasa yang natural dan mudah dibaca.

1. KESIMPULAN:
   Jelaskan secara detail performa kandidat berdasarkan data di atas. Sebutkan:
   - Berapa kali pelanggaran kontak mata (rincian melirik kiri/kanan/menunduk)
   - Berapa kali senyum dan ekspresi netral
   - Berapa kali postur bermasalah (rincian bahu miring kiri/kanan/kepala menunduk)
   - Kecepatan bicara (WPM) termasuk kategori apa (Terlalu Lambat <110, Ideal 130-160, Terlalu Cepat >180)
   - Kenapa bisa mendapatkan status "$overallLabel"
   
   Buat kesimpulan yang informatif dan mudah dipahami.

2. RINCIAN POIN:
   Tulis dengan format berikut:
   
   Kontak Mata: $eyeLabel (poin: ${eyeViolations <= 3 ? 2 : (eyeViolations <= 6 ? 1 : 0)}/2)
   Rincian: Melirik kiri $lookLeftCount kali, melirik kanan $lookRightCount kali, menunduk $lookDownCount kali
   Penjelasan: [jelaskan arti dari label dan poin tersebut]
   
   Ekspresi: $smileLabel (poin: ${(smileCount >= 3 && smileCount > neutralCount) ? 2 : (smileCount >= 1 ? 1 : 0)}/2)
   Rincian: Tersenyum $smileCount kali, ekspresi netral $neutralCount kali
   Penjelasan: [jelaskan arti dari label dan poin tersebut]
   
   Postur: $postureLabel (poin: ${postureViolations <= 3 ? 2 : (postureViolations <= 6 ? 1 : 0)}/2)
   Rincian: Bahu miring kiri $headTiltLeftCount kali, bahu miring kanan $headTiltRightCount kali, kepala menunduk $headDownCount kali
   Penjelasan: [jelaskan arti dari label dan poin tersebut]
   
   TOTAL: $totalPoints/$maxPoints poin
   Hasil Overall: $overallLabel

3. REKOMENDASI:
   Berikan 4-5 rekomendasi spesifik berdasarkan kelemahan yang terdeteksi. Tulis dalam paragraf biasa, bukan bullet points.

4. SARAN MOTIVASI:
   Berikan kalimat penyemangat yang sesuai dengan status overall kandidat.

Gunakan format teks biasa dengan line breaks yang jelas. Hindari semua jenis formatting markdown.
''';

    final result = await _groqService.generateText(
      prompt: prompt,
      temperature: 0.6,
      maxTokens: 1200,
      fallback: '',
    );

    if (result.isEmpty) return _getFallbackDetailAnalysis(overallLabel);
    return result;
  }

  // ===== FALLBACK METHODS =====

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
    if (overallLabel == 'Siap Wawancara') {
      return '''
1. KESIMPULAN:
Selamat! Performa Anda sangat baik secara keseluruhan. Kontak mata terjaga dengan baik, ekspresi ramah dan antusias, serta postur tubuh yang tenang dan profesional. Anda sudah siap menghadapi wawancara sesungguhnya.

2. RINCIAN POIN:
Kontak Mata: Fokus & Percaya Diri (2/2)
Ekspresi: Ramah & Antusias (2/2)
Postur: Tenang & Profesional (2/2)
TOTAL: 6/6 poin

3. REKOMENDASI:
Pertahankan kontak mata yang baik dengan tetap fokus ke kamera. Lanjutkan ekspresi ramah dan percaya diri. Jaga postur tubuh tetap tegak dan rileks. Pertahankan kecepatan bicara ideal 130-160 WPM.

4. SARAN MOTIVASI:
Pertahankan performa terbaik Anda! Teruslah berlatih untuk semakin percaya diri!
''';
    } else if (overallLabel == 'Cukup Siap') {
      return '''
1. KESIMPULAN:
Performa Anda cukup baik namun masih ada beberapa aspek yang perlu ditingkatkan. Dengan latihan rutin, Anda bisa mencapai level "Siap Wawancara".

2. RINCIAN POIN:
Kontak Mata: Cukup Baik (1/2)
Ekspresi: Cukup Ramah (1/2)
Postur: Cukup Stabil (1/2)
TOTAL: 4/6 poin

3. REKOMENDASI:
Kontak Mata sudah baik, pertahankan fokus ke kamera. Untuk ekspresi, tersenyum setidaknya 3 kali selama wawancara. Postur tubuh bisa diperbaiki dengan duduk menggunakan sandaran punggung dan tarik napas dalam. Kecepatan bicara coba dijaga di rentang 130-160 WPM.

4. SARAN MOTIVASI:
Anda sudah di jalur yang tepat! Dengan latihan rutin, performa Anda akan semakin baik!
''';
    } else {
      return '''
1. KESIMPULAN:
Performa Anda masih perlu banyak latihan. Jangan berkecil hati, setiap latihan adalah langkah menuju perbaikan.

2. RINCIAN POIN:
Kontak Mata: Perlu Latihan (0/2)
Ekspresi: Perlu Latihan (0/2)
Postur: Perlu Latihan (0/2)
TOTAL: 0/6 poin

3. REKOMENDASI:
Untuk kontak mata, latih fokus ke kamera setiap hari. Ekspresi bisa diperbaiki dengan tersenyum di awal dan akhir setiap jawaban. Postur tubuh dijaga dengan duduk tegak dan kedua kaki menapak lantai. Kecepatan bicara ditargetkan 130-160 kata per menit. Lakukan latihan rutin 15 menit setiap hari selama 1 minggu.

4. SARAN MOTIVASI:
Jangan menyerah! Setiap latihan membawa Anda lebih dekat ke kesuksesan. Teruslah berlatih!
''';
    }
  }
}
