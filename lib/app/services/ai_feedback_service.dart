// lib/app/services/ai_feedback_service.dart
import 'package:firebase_ai/firebase_ai.dart';

/// Service untuk berinteraksi dengan Gemini AI
/// Menghasilkan REKOMENDASI + LABEL AKHIR berdasarkan data perilaku
class AiFeedbackService {
  // ===== GENERATE REKOMENDASI DARI GEMINI =====
  Future<String> generateRecommendation({
    required int lookAwayCount,
    required int lookDownCount,
    required int smileCount,
    required int neutralCount,
    required int headTiltLeftCount,
    required int headTiltRightCount,
    required int headDownCount,
    required String level,
    required int wpm,
    required int fillerCount,
  }) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 800,
        ),
      );

      final eyeDesc = _getEyeDescriptive(lookAwayCount + lookDownCount);
      final smileDesc = _getSmileDescriptive(smileCount, neutralCount);
      final postureDesc = _getPostureDescriptive(
        headTiltLeftCount + headTiltRightCount + headDownCount,
      );
      final speechDesc = _getSpeechDescriptive(wpm, fillerCount);

      final prompt =
          '''
Anda adalah HRD profesional yang memberikan **REKOMENDASI** dan **PENILAIAN AKHIR** kepada kandidat setelah sesi simulasi wawancara.

**DATA PERILAKU KANDIDAT:**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👀 KONTAK MATA: $eyeDesc
😊 EKSPRESI WAJAH: $smileDesc  
🧍 POSTUR TUBUH: $postureDesc
🎤 KOMUNIKASI VERBAL: $speechDesc
📊 LEVEL KESULITAN: $level
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**TUGAS ANDA:**
Buatlah REKOMENDASI dalam 4-5 kalimat dengan format berikut:

[Kalimat 1] PENILAIAN AKHIR: Sebutkan "Percaya Diri", "Cukup Percaya Diri", atau "Ragu-ragu" berdasarkan data di atas.
[Kalimat 2] Apresiasi: Sebutkan 1 hal yang sudah baik dari kandidat.
[Kalimat 3] Area Perbaikan: Sebutkan 1-2 aspek yang perlu ditingkatkan (jika ada).
[Kalimat 4] Saran Aksi: Berikan saran konkret dan actionable.
[Kalimat 5] Motivasi: Kalimat penyemangat untuk membangun kepercayaan diri.

**CONTOH OUTPUT:**
Penilaian Akhir: Cukup Percaya Diri
Anda sudah menunjukkan kontak mata yang fokus dan percaya diri. Namun, ekspresi wajah Anda masih cenderung kaku dan postur tubuh sesekali terlihat gelisah. Cobalah tersenyum lebih sering di awal dan akhir jawaban, serta duduk dengan posisi lebih tegak. Dengan sedikit latihan lagi, Anda pasti siap menghadapi wawancara sesungguhnya!

**PENTING:**
- JANGAN sebutkan angka mentah (misal: "5 kali melirik") - angka hanya untuk analisis internal
- GUNAKAN bahasa Indonesia yang profesional dan membangun
- Gunakan label 3 tingkat: Kontak Mata (Fokus & Percaya Diri / Sesekali Terdistraksi / Sering Kehilangan Fokus), Ekspresi (Ramah & Antusias / Cukup Ramah / Kaku & Tegang), Postur (Tenang & Profesional / Sedikit Gelisah / Gugup & Cemas)
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ??
          _getFallbackRecommendation(
            lookAwayCount: lookAwayCount,
            lookDownCount: lookDownCount,
            smileCount: smileCount,
            neutralCount: neutralCount,
            headTiltCount: headTiltLeftCount + headTiltRightCount,
            headDownCount: headDownCount,
            wpm: wpm,
            fillerCount: fillerCount,
          );
    } catch (e) {
      print('❌ Error generating AI recommendation: $e');
      return _getFallbackRecommendation(
        lookAwayCount: lookAwayCount,
        lookDownCount: lookDownCount,
        smileCount: smileCount,
        neutralCount: neutralCount,
        headTiltCount: headTiltLeftCount + headTiltRightCount,
        headDownCount: headDownCount,
        wpm: wpm,
        fillerCount: fillerCount,
      );
    }
  }

  // ===== LABEL DESKRIPTIF 3 TINGKAT (untuk Firestore) =====

  String getEyeContactLabel(
    int lookAwayCount,
    int lookDownCount,
    String level,
  ) {
    final total = lookAwayCount + lookDownCount;
    if (total <= 1)
      return 'Fokus & Percaya Diri - Kontak mata terjaga dengan sangat baik';
    if (total <= 3)
      return 'Sesekali Terdistraksi - Kontak mata cukup stabil, sesekali teralihkan';
    return 'Sering Kehilangan Fokus - Kontak mata tidak stabil, perlu latihan intensif';
  }

  String getSmileLabel(int smileCount, int neutralCount, String level) {
    if (smileCount >= 3 && smileCount > neutralCount)
      return 'Ramah & Antusias - Ekspresi ramah dan menunjukkan antusiasme tinggi';
    if (smileCount >= 1)
      return 'Cukup Ramah / Netral - Ekspresi cukup ramah, namun bisa lebih hangat';
    return 'Kaku & Tegang - Ekspresi datar, perlu peningkatan frekuensi senyum';
  }

  String getPostureLabel(int tiltLeft, int tiltRight, int down, String level) {
    final total = tiltLeft + tiltRight + down;
    if (total <= 1)
      return 'Tenang & Profesional - Postur kepala tegak dan stabil, menunjukkan ketenangan';
    if (total <= 3)
      return 'Sedikit Gelisah - Postur kepala cukup stabil, ada sedikit gerakan tidak perlu';
    return 'Gugup & Cemas - Postur kepala tidak stabil, banyak gerakan tidak terkontrol';
  }

  String getOverallLabelFromData({
    required int lookAwayCount,
    required int lookDownCount,
    required int smileCount,
    required int neutralCount,
    required int headTiltLeftCount,
    required int headTiltRightCount,
    required int headDownCount,
  }) {
    final totalEye = lookAwayCount + lookDownCount;
    final totalHead = headTiltLeftCount + headTiltRightCount + headDownCount;

    if (totalEye <= 1 && totalHead <= 1 && smileCount >= 3)
      return 'Percaya Diri';
    if (totalEye <= 3 && totalHead <= 3 && smileCount >= 1)
      return 'Cukup Percaya Diri';
    return 'Ragu-ragu';
  }

  String getConfidenceMessage(String overallLabel) {
    switch (overallLabel) {
      case 'Percaya Diri':
        return 'Luar biasa! Anda menunjukkan kepercayaan diri yang tinggi. Pertahankan!';
      case 'Cukup Percaya Diri':
        return 'Bagus! Anda cukup percaya diri. Sedikit latihan lagi pasti lebih mantap.';
      case 'Ragu-ragu':
        return 'Jangan khawatir! Dengan latihan rutin, Anda pasti bisa lebih percaya diri.';
      default:
        return 'Terus berlatih, kesuksesan menanti Anda!';
    }
  }

  // ===== KESIMPULAN =====

  String getEyeContactConclusion(int lookAwayCount, int lookDownCount) {
    final total = lookAwayCount + lookDownCount;
    if (total <= 1)
      return 'Fokus & Percaya Diri (${total}x pelanggaran) - Kontak mata sangat baik dan stabil';
    if (total <= 3)
      return 'Sesekali Terdistraksi (${total}x pelanggaran) - Kontak mata cukup baik, perlu sedikit peningkatan';
    return 'Sering Kehilangan Fokus (${total}x pelanggaran) - Kontak mata kurang stabil, sering teralihkan';
  }

  String getFacialConclusion(int smileCount, int neutralCount) {
    if (smileCount >= 3 && smileCount > neutralCount)
      return 'Ramah & Antusias (😊 $smileCount senyum) - Ekspresi sangat baik, ramah dan antusias';
    if (smileCount >= 1)
      return 'Cukup Ramah / Netral (😊 $smileCount senyum | 😐 $neutralCount datar) - Ekspresi cukup baik, namun bisa lebih hangat';
    return 'Kaku & Tegang (😊 $smileCount senyum | 😐 $neutralCount datar) - Ekspresi kurang baik, cenderung kaku dan tegang';
  }

  String getHeadPostureConclusion(int tiltLeft, int tiltRight, int down) {
    final total = tiltLeft + tiltRight + down;
    if (total <= 1)
      return 'Tenang & Profesional (${total}x gerakan) - Postur sangat baik, tegak dan stabil';
    if (total <= 3)
      return 'Sedikit Gelisah (${total}x gerakan) - Postur cukup baik, ada sedikit gerakan tidak perlu';
    return 'Gugup & Cemas (${total}x gerakan) - Postur perlu perbaikan, terlalu banyak gerakan';
  }

  // ===== SARAN =====

  String getEyeContactSuggestion(int lookAwayCount, int lookDownCount) {
    if (lookAwayCount > lookDownCount)
      return 'Coba fokus pada satu titik dan kurangi gerakan mata ke samping.';
    if (lookDownCount > lookAwayCount)
      return 'Atur posisi layar lebih tinggi agar tidak perlu menunduk.';
    return 'Latih kontak mata dengan menatap cermin 2 menit setiap hari.';
  }

  String getFacialSuggestion(int smileCount, int neutralCount) {
    if (smileCount < 3)
      return 'Cobalah tersenyum lebih sering, terutama di awal dan akhir jawaban. Senyum membuat Anda terlihat lebih percaya diri!';
    return 'Pertahankan senyum ramah Anda, itu menunjukkan kepercayaan diri!';
  }

  String getHeadPostureSuggestion(int tiltLeft, int tiltRight, int down) {
    if (tiltLeft > 0 || tiltRight > 0)
      return 'Duduklah dengan bahu tegak dan hindari memiringkan kepala.';
    if (down > 0)
      return 'Angkat kepala saat berbicara, atur layar setinggi mata.';
    return 'Jaga postur tubuh tetap tegak agar terlihat percaya diri.';
  }

  // ===== HELPER DESKRIPTIF =====

  String _getEyeDescriptive(int total) {
    if (total <= 1) return 'fokus dan percaya diri, dominan menatap kamera';
    if (total <= 3) return 'sesekali terdistraksi, masih cukup fokus';
    return 'sering kehilangan fokus, lebih banyak tidak menatap kamera';
  }

  String _getSmileDescriptive(int smile, int neutral) {
    if (smile >= 3 && smile > neutral)
      return 'ramah dan antusias, sering tersenyum natural';
    if (smile >= 1) return 'cukup ramah, tersenyum sesekali';
    return 'kaku dan tegang, kurang menunjukkan ekspresi hangat';
  }

  String _getPostureDescriptive(int total) {
    if (total <= 1) return 'tenang dan profesional, tegak dan stabil';
    if (total <= 3) return 'sedikit gelisah dengan beberapa gerakan ringan';
    return 'gugup dan cemas, banyak gerakan tidak perlu';
  }

  String _getSpeechDescriptive(int wpm, int fillerCount) {
    String speed;
    if (wpm >= 120 && wpm <= 160) {
      speed = 'kecepatan bicara ideal';
    } else if (wpm > 180) {
      speed = 'terlalu cepat';
    } else if (wpm < 90) {
      speed = 'sangat lambat';
    } else {
      speed = 'kecepatan bicara cukup baik';
    }
    if (fillerCount >= 5) return '$speed, namun cukup banyak kata pengisi';
    return '$speed, tanpa kata pengisi yang mengganggu';
  }

  // ===== FALLBACK =====

  String _getFallbackRecommendation({
    required int lookAwayCount,
    required int lookDownCount,
    required int smileCount,
    required int neutralCount,
    required int headTiltCount,
    required int headDownCount,
    required int wpm,
    required int fillerCount,
  }) {
    final totalEye = lookAwayCount + lookDownCount;
    final totalHead = headTiltCount + headDownCount;

    String akhir;
    if (totalEye <= 1 && totalHead <= 1 && smileCount >= 3) {
      akhir = 'Percaya Diri';
    } else if (totalEye <= 3 && totalHead <= 3 && smileCount >= 1) {
      akhir = 'Cukup Percaya Diri';
    } else {
      akhir = 'Ragu-ragu';
    }

    if (totalEye <= 1 && totalHead <= 1 && smileCount >= 3) {
      return 'Penilaian Akhir: $akhir\nAnda menunjukkan performa yang sangat meyakinkan! Kontak mata fokus dan percaya diri, ekspresi ramah dan antusias, serta postur tubuh tenang dan profesional. Pertahankan kebiasaan baik ini untuk wawancara sesungguhnya!';
    }
    if (totalEye >= 4) {
      if (lookAwayCount > lookDownCount) {
        return 'Penilaian Akhir: $akhir\nKontak mata menjadi tantangan utama Anda. Anda sering melirik ke samping. Cobalah latihan menatap kamera 30 detik setiap hari. Kontak mata yang baik menunjukkan kepercayaan diri!';
      } else {
        return 'Penilaian Akhir: $akhir\nAnda cenderung menunduk saat berbicara, sehingga terkesan kurang percaya diri. Atur posisi layar agar sejajar dengan pandangan mata Anda.';
      }
    }
    if (totalHead >= 4) {
      return 'Penilaian Akhir: $akhir\nPostur tubuh Anda cukup sering bergerak. Duduklah dengan posisi tegak dan rileks. Postur yang baik mencerminkan profesionalisme!';
    }
    if (neutralCount >= 4 && smileCount <= 2) {
      return 'Penilaian Akhir: $akhir\nEkspresi wajah Anda cenderung kaku. Cobalah tersenyum natural di awal dan akhir setiap jawaban. Sedikit senyum bisa memberikan kesan besar!';
    }
    if (wpm > 180) {
      return 'Penilaian Akhir: $akhir\nAnda berbicara terlalu cepat. Cobalah bicara sedikit lebih pelan. Kecepatan bicara ideal adalah 120-160 kata per menit.';
    }
    if (fillerCount >= 5) {
      return 'Penilaian Akhir: $akhir\nAnda cukup sering menggunakan kata pengisi. Cobalah berlatih berbicara dengan kalimat pendek dan jelas.';
    }
    return 'Penilaian Akhir: $akhir\nPerforma Anda cukup stabil. Fokus utama: konsistensi kontak mata dan frekuensi senyum. Ingat, setiap latihan membawa Anda selangkah lebih dekat menuju kesuksesan!';
  }

  Future<String> generateRecommendationWithDetailedPrompt(String prompt) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1000,
        ),
      );
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? _getFallbackDetailedRecommendation();
    } catch (e) {
      print('❌ Error: $e');
      return _getFallbackDetailedRecommendation();
    }
  }

  String _getFallbackDetailedRecommendation() {
    return '''
REKOMENDASI DARI AI GEMINI

Kesimpulan:
Berdasarkan hasil analisis, performa Anda secara umum masih ragu-ragu. Terdapat beberapa aspek yang perlu mendapatkan perhatian lebih.

Analisis Per Kategori:
Kontak Mata: Masih sering teralihkan yang mengurangi kesan fokus.
Ekspresi Wajah: Kurang menunjukkan antusiasme dan cenderung kaku.
Postur Tubuh: Cukup baik namun masih ada gerakan tidak perlu.

Saran Perbaikan:
1. Latih kontak mata dengan menatap kamera 30 detik setiap hari.
2. Tersenyumlah di awal dan akhir setiap jawaban.
3. Duduk dengan posisi lebih tegak dan rileks.

Kesimpulan Akhir:
Terus berlatih! Setiap sesi latihan membawa Anda selangkah lebih dekat menuju kesuksesan wawancara. Jangan menyerah!
''';
  }
}
