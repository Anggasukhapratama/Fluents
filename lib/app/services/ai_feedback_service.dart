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

  // ===== KOREKSI JAWABAN PER PERTANYAAN =====
  /// Koreksi jawaban user per pertanyaan dengan format terstruktur
  Future<String> correctAnswerWithStructuredFeedback({
    required String question,
    required String userAnswer,
    required String jobTarget,
  }) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: _modelName,
        generationConfig: GenerationConfig(
          temperature: 0.6,
          maxOutputTokens: 350,
        ),
      );

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

      final response = await model.generateContent([Content.text(prompt)]);

      String result = response.text?.trim() ?? '';
      if (result.isEmpty) {
        return _getFallbackStructuredFeedback(userAnswer);
      }

      return result;
    } catch (e) {
      print('❌ Error correct answer structured: $e');
      return _getFallbackStructuredFeedback(userAnswer);
    }
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
  /// Generate detail analisis perilaku lengkap untuk tombol "Detail Analisis Perilaku"
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
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: _modelName,
        generationConfig: GenerationConfig(
          temperature: 0.6,
          maxOutputTokens: 1000,
        ),
      );

      final prompt =
          '''
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
   - Rincian: Melirik kiri $lookLeftCount kali, melirik kanan $lookRightCount kali, menunduk $lookDownCount kali
   - Penjelasan: [jelaskan arti dari label dan poin tersebut]
   
   Ekspresi: $smileLabel (poin: ${(smileCount >= 3 && smileCount > neutralCount) ? 2 : (smileCount >= 1 ? 1 : 0)}/2)
   - Rincian: Tersenyum $smileCount kali, ekspresi netral $neutralCount kali
   - Penjelasan: [jelaskan arti dari label dan poin tersebut]
   
   Postur: $postureLabel (poin: ${postureViolations <= 3 ? 2 : (postureViolations <= 6 ? 1 : 0)}/2)
   - Rincian: Bahu miring kiri $headTiltLeftCount kali, bahu miring kanan $headTiltRightCount kali, kepala menunduk $headDownCount kali
   - Penjelasan: [jelaskan arti dari label dan poin tersebut]
   
   TOTAL: $totalPoints/$maxPoints poin
   - Hasil Overall: $overallLabel

3. REKOMENDASI:
   Berikan 4-5 rekomendasi spesifik berdasarkan kelemahan yang terdeteksi:
   - Jika kontak mata bermasalah: beri saran latihan fokus ke kamera dengan metode yang jelas
   - Jika ekspresi kaku: beri saran untuk tersenyum lebih sering dan latihan ekspresi
   - Jika postur bermasalah: beri saran posisi duduk yang benar dan latihan relaksasi
   - Jika WPM terlalu lambat (<110): beri saran untuk mempercepat bicara
   - Jika WPM terlalu cepat (>180): beri saran untuk lebih rileks dan beri jeda
   - Jika filler words banyak: beri saran mengurangi kata "umm", "anu", "eee"
   - Jika sudah baik: beri saran untuk mempertahankan

   Setiap rekomendasi harus spesifik dan actionable (bisa langsung dilakukan).

4. SARAN MOTIVASI:
   Berikan kalimat penyemangat yang sesuai dengan status overall kandidat. Sesuaikan dengan kondisi:
   - Jika "Siap Wawancara": apresiasi dan saran mempertahankan
   - Jika "Cukup Siap": semangat untuk terus meningkatkan
   - Jika "Butuh Banyak Latihan": motivasi agar tidak menyerah

JANGAN gunakan markdown seperti *, -, # kecuali untuk bullet points.
Gunakan format teks biasa dengan line breaks yang jelas.
''';

      final response = await model.generateContent([Content.text(prompt)]);

      String result = response.text?.trim() ?? '';
      if (result.isEmpty) {
        return _getFallbackDetailAnalysis(overallLabel);
      }

      return result;
    } catch (e) {
      print('❌ Error generate detail analysis: $e');
      return _getFallbackDetailAnalysis(overallLabel);
    }
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
Selamat! Performa Anda sangat baik secara keseluruhan. Kontak mata terjaga dengan baik (total pelanggaran minimal), ekspresi ramah dan antusias (senyum mendominasi), serta postur tubuh yang tenang dan profesional. Kecepatan bicara Anda juga ideal. Anda sudah siap menghadapi wawancara sesungguhnya.

2. RINCIAN POIN:
Kontak Mata: Fokus & Percaya Diri (2/2)
- Rincian: Pelanggaran minimal (≤3 kali)
- Penjelasan: Anda mampu mempertahankan fokus ke kamera dengan sangat baik

Ekspresi: Ramah & Antusias (2/2)
- Rincian: Senyum ≥3 kali dan lebih banyak dari ekspresi netral
- Penjelasan: Ekspresi Anda natural dan hangat, menunjukkan kepercayaan diri

Postur: Tenang & Profesional (2/2)
- Rincian: Pelanggaran postur minimal (≤3 kali)
- Penjelasan: Postur tubuh stabil dan menunjukkan ketenangan

TOTAL: 6/6 poin
- Hasil Overall: Siap Wawancara

3. REKOMENDASI:
- Pertahankan kontak mata yang baik dengan tetap fokus ke kamera
- Lanjutkan ekspresi ramah dan percaya diri
- Jaga postur tubuh tetap tegak dan rileks
- Pertahankan kecepatan bicara ideal 130-160 WPM

4. SARAN MOTIVASI:
Pertahankan performa terbaik Anda! Teruslah berlatih untuk semakin percaya diri dan siap menghadapi wawancara impian Anda!
''';
    } else if (overallLabel == 'Cukup Siap') {
      return '''
1. KESIMPULAN:
Performa Anda cukup baik namun masih ada beberapa aspek yang perlu ditingkatkan. Kontak mata sudah cukup baik (masih dalam batas toleransi), ekspresi mulai menunjukkan keramahan namun masih perlu ditingkatkan frekuensi senyumnya, dan postur tubuh masih cukup sering menunjukkan kegelisahan. Dengan latihan rutin, Anda bisa mencapai level "Siap Wawancara".

2. RINCIAN POIN:
Kontak Mata: Fokus & Percaya Diri (2/2)
- Rincian: Pelanggaran 4-6 kali
- Penjelasan: Kontak mata sudah baik, hanya sesekali terdistraksi

Ekspresi: Cukup Ramah / Netral (1/2)
- Rincian: Senyum 1-2 kali
- Penjelasan: Mulai menunjukkan ekspresi ramah tapi masih perlu ditingkatkan

Postur: Sedikit Gelisah (1/2)
- Rincian: Pelanggaran postur 4-6 kali
- Penjelasan: Masih ada gerakan tidak perlu, perlu lebih rileks

TOTAL: 4/6 poin
- Hasil Overall: Cukup Siap

3. REKOMENDASI:
- Kontak Mata: Sudah baik, pertahankan fokus ke kamera
- Ekspresi: Cobalah tersenyum setidaknya 3 kali selama wawancara, terutama di awal dan akhir jawaban
- Postur: Duduk dengan sandaran punggung, tarik napas dalam sebelum menjawab untuk mengurangi kegelisahan
- Kecepatan Bicara: Jika terlalu lambat, coba percepat; jika terlalu cepat, coba lebih rileks
- Kata Pengisi: Latihan bicara dengan struktur yang jelas untuk mengurangi "umm" dan "anu"

4. SARAN MOTIVASI:
Anda sudah di jalur yang tepat! Dengan latihan rutin 10 menit setiap hari, performa Anda akan semakin baik menuju kesiapan penuh!
''';
    } else {
      return '''
1. KESIMPULAN:
Performa Anda masih perlu banyak latihan. Kontak mata sering teralihkan (pelanggaran >6 kali), ekspresi masih terlihat kaku dan tegang (minim senyum), serta postur tubuh menunjukkan kegugupan yang cukup tinggi (banyak gerakan tidak stabil). Namun jangan berkecil hati, setiap latihan adalah langkah menuju perbaikan.

2. RINCIAN POIN:
Kontak Mata: Sering Kehilangan Fokus (0/2)
- Rincian: Pelanggaran >6 kali
- Penjelasan: Terlalu sering mengalihkan pandangan dari kamera

Ekspresi: Kaku & Tegang (0/2)
- Rincian: Tidak ada atau sangat minim senyum
- Penjelasan: Ekspresi terlalu datar, perlu lebih hangat

Postur: Gugup & Cemas (0/2)
- Rincian: Pelanggaran postur >6 kali
- Penjelasan: Terlalu banyak gerakan tidak stabil, menunjukkan kegugupan

TOTAL: 0/6 poin
- Hasil Overall: Butuh Banyak Latihan

3. REKOMENDASI:
- Kontak Mata: Latih fokus ke kamera dengan metode "20-20-20" (setiap 20 detik, fokus ke kamera selama 20 detik)
- Ekspresi: Cobalah tersenyum di awal dan akhir setiap jawaban, latih di depan cermin
- Postur: Duduk tegak dengan kedua kaki menapak lantai, tangan rileks di pangkuan, tarik napas dalam sebelum menjawab
- Kecepatan Bicara: Rekam dan dengarkan kembali jawaban Anda, coba bicara dengan kecepatan 130-160 kata per menit
- Kata Pengisi: Siapkan poin-poin jawaban sebelum berbicara untuk mengurangi kata "umm" dan "anu"
- Latihan Rutin: Lakukan latihan 15 menit setiap hari selama 1 minggu

4. SARAN MOTIVASI:
Jangan menyerah! Setiap latihan membawa Anda lebih dekat ke kesuksesan. Ingat, semua orang hebat pasti melalui proses latihan yang panjang. Teruslah berlatih, Anda pasti bisa! 💪
''';
    }
  }
}
