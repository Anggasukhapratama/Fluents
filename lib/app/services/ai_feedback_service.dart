// lib/app/services/ai_feedback_service.dart
import 'package:firebase_ai/firebase_ai.dart';

class AiFeedbackService {
  // ===== THRESHOLD UNTUK LABEL =====
  static const int _LOOK_AWAY_GOOD_THRESHOLD = 1;
  static const int _LOOK_AWAY_WARN_THRESHOLD = 2;
  static const int _LOOK_AWAY_BAD_THRESHOLD = 4;

  static const int _LOOK_DOWN_GOOD_THRESHOLD = 1;
  static const int _LOOK_DOWN_WARN_THRESHOLD = 2;
  static const int _LOOK_DOWN_BAD_THRESHOLD = 4;

  static const int _SMILE_GOOD_THRESHOLD = 3;
  static const int _NEUTRAL_BAD_THRESHOLD = 4;

  static const int _HEAD_TILT_GOOD_THRESHOLD = 1;
  static const int _HEAD_TILT_WARN_THRESHOLD = 2;
  static const int _HEAD_TILT_BAD_THRESHOLD = 3;

  static const int _HEAD_DOWN_GOOD_THRESHOLD = 1;
  static const int _HEAD_DOWN_WARN_THRESHOLD = 2;
  static const int _HEAD_DOWN_BAD_THRESHOLD = 3;

  // ===== GENERATE KESIMPULAN DENGAN AI =====
  Future<String> generateSummary({
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
      // ✅ CARA YANG BENAR - menggunakan googleAI() terlebih dahulu
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash', // parameter 'model', bukan 'modelName'
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 800,
        ),
      );

      final prompt =
          '''
Anda adalah HRD profesional yang memberikan feedback kepada kandidat wawancara kerja.

**DATA PERILAKU KANDIDAT:**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 KONTAK MATA:
- Melengos ke samping: $lookAwayCount kali
- Menunduk ke bawah: $lookDownCount kali

😊 EKSPRESI WAJAH:
- Tersenyum: $smileCount kali
- Wajah kaku/datar: $neutralCount kali

👤 POSTUR KEPALA:
- Miring ke kiri: $headTiltLeftCount kali
- Miring ke kanan: $headTiltRightCount kali
- Menunduk: $headDownCount kali

🎤 METRIK BICARA:
- Kecepatan (WPM): $wpm
- Kata pengisi (filler): $fillerCount kali
- Level kesulitan wawancara: $level
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**TUGAS ANDA:**
Buatlah KESIMPULAN AKHIR dalam 3-4 kalimat yang:

1. **Identifikasi masalah utama** berdasarkan data di atas (sebutkan 1-2 kelemahan terbesar)
2. **Beri apresiasi** jika ada aspek yang baik
3. **Berikan saran spesifik** untuk perbaikan di masa depan

**FORMAT OUTPUT:**
Gunakan bahasa Indonesia yang profesional, natural, dan mudah dipahami. Jangan menyebutkan angka mentah di kesimpulan.
''';

      // ✅ Cara generate content yang benar
      final response = await model.generateContent([Content.text(prompt)]);
      final result =
          response.text?.trim() ??
          _getFallbackSummary(
            lookAwayCount: lookAwayCount,
            lookDownCount: lookDownCount,
            smileCount: smileCount,
            neutralCount: neutralCount,
            headTiltCount: headTiltLeftCount + headTiltRightCount,
            headDownCount: headDownCount,
            wpm: wpm,
            fillerCount: fillerCount,
          );

      return result;
    } catch (e) {
      print('❌ Error generating AI summary: $e');
      return _getFallbackSummary(
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

  // ===== FALLBACK SUMMARY (JIKA AI GAGAL) =====
  String _getFallbackSummary({
    required int lookAwayCount,
    required int lookDownCount,
    required int smileCount,
    required int neutralCount,
    required int headTiltCount,
    required int headDownCount,
    required int wpm,
    required int fillerCount,
  }) {
    final totalEyeIssues = lookAwayCount + lookDownCount;
    final totalHeadIssues = headTiltCount + headDownCount;

    if (totalEyeIssues >= 5) {
      return 'Kontak mata menjadi kelemahan utama Anda dalam wawancara ini. Anda sering memalingkan pandangan dan menunduk, sehingga terkesan kurang percaya diri. Cobalah latihan kontak mata di depan kamera dan fokus pada satu titik saat berbicara.';
    }

    if (totalEyeIssues >= 3) {
      return 'Kontak mata Anda masih perlu ditingkatkan. Beberapa kali Anda terlihat melengos atau menunduk. Hal ini bisa membuat HRD mengira Anda kurang persiapan. Usahakan menatap kamera secara konsisten.';
    }

    if (totalHeadIssues >= 4) {
      return 'Postur kepala Anda perlu diperhatikan karena cukup sering bergerak (miring/menunduk). Hal ini bisa membuat HRD mengira Anda ragu-ragu. Usahakan menjaga kepala tetap tegak dan stabil saat menjawab pertanyaan.';
    }

    if (neutralCount >= 5 && smileCount <= 2) {
      return 'Ekspresi wajah Anda cenderung kaku selama wawancara. Cobalah untuk lebih sering tersenyum, terutama di awal dan akhir jawaban, agar terlihat lebih ramah dan antusias.';
    }

    if (wpm > 180) {
      return 'Anda berbicara terlalu cepat (di atas 180 kata per menit). Coba bicara lebih pelan agar pesan Anda lebih mudah dipahami oleh HRD.';
    }

    if (wpm > 0 && wpm < 90) {
      return 'Bicara Anda cenderung terlalu lambat. Tingkatkan tempo bicara sedikit agar terlihat lebih percaya diri dan antusias.';
    }

    if (fillerCount >= 5) {
      return 'Anda cukup sering menggunakan kata pengisi seperti "umm", "anu", atau "eee". Latihan bicara di depan cermin akan membantu mengurangi kebiasaan ini.';
    }

    if (totalEyeIssues <= 2 && totalHeadIssues <= 2 && smileCount >= 3) {
      return 'Bagus! Performa Anda sangat profesional. Kontak mata terjaga dengan baik, ekspresi wajah ramah, dan postur kepala stabil. Pertahankan kebiasaan baik ini untuk wawancara sesungguhnya!';
    }

    return 'Performa Anda cukup stabil secara keseluruhan. Fokus utama untuk peningkatan adalah konsistensi kontak mata dan menambah frekuensi senyum agar terlihat lebih percaya diri dan antusias. Latihan rutin akan sangat membantu.';
  }

  // ===== KONTAK MATA - KESIMPULAN =====
  String getEyeContactConclusion(int lookAwayCount, int lookDownCount) {
    final total = lookAwayCount + lookDownCount;
    if (total <= _LOOK_AWAY_GOOD_THRESHOLD) return '✅ Sangat Fokus';
    if (total <= _LOOK_AWAY_WARN_THRESHOLD) return '⚠️ Cukup Fokus';
    if (total <= _LOOK_AWAY_BAD_THRESHOLD) return '❌ Kurang Fokus';
    return '❌❌ Sangat Kurang Fokus';
  }

  String getEyeContactSuggestion(int lookAwayCount, int lookDownCount) {
    final total = lookAwayCount + lookDownCount;
    if (total <= 1) return 'Pertahankan kontak mata yang baik!';
    if (total <= 2) return 'Coba lebih fokus menatap kamera saat menjawab.';
    if (total <= 4) {
      if (lookAwayCount > lookDownCount) {
        return 'Hindari melihat ke samping, bayangkan kamera adalah mata HRD.';
      } else {
        return 'Hindari menunduk saat berbicara, angkat kepala Anda.';
      }
    }
    return 'Latihan menatap kamera secara konsisten sangat diperlukan.';
  }

  String getEyeContactStatusLabel(int lookAwayCount, int lookDownCount) {
    final total = lookAwayCount + lookDownCount;
    if (total <= 1) return 'Sangat Fokus';
    if (total <= 2) return 'Cukup Fokus';
    if (total <= 4) return 'Kurang Fokus';
    return 'Sangat Kurang Fokus';
  }

  // ===== EKSPRESI WAJAH - KESIMPULAN =====
  String getFacialConclusion(int smileCount, int neutralCount) {
    if (smileCount > neutralCount && smileCount >= _SMILE_GOOD_THRESHOLD) {
      return '✅ Sangat Antusias';
    }
    if (smileCount > neutralCount) {
      return '✅ Antusias & Ramah';
    }
    if (smileCount == neutralCount && smileCount > 0) {
      return '⚠️ Cukup Antusias';
    }
    if (neutralCount > smileCount && neutralCount <= _NEUTRAL_BAD_THRESHOLD) {
      return '⚠️ Kurang Antusias';
    }
    return '❌ Kaku / Tidak Antusias';
  }

  String getFacialSuggestion(int smileCount, int neutralCount) {
    if (smileCount > neutralCount && smileCount >= _SMILE_GOOD_THRESHOLD) {
      return 'Pertahankan senyum ramah Anda! Ini aset berharga.';
    }
    if (smileCount > neutralCount) {
      return 'Tingkatkan sedikit frekuensi senyum Anda untuk hasil lebih maksimal.';
    }
    if (smileCount == neutralCount && smileCount > 0) {
      return 'Cobalah tersenyum lebih sering, terutama di awal jawaban.';
    }
    if (neutralCount > smileCount && neutralCount <= _NEUTRAL_BAD_THRESHOLD) {
      return 'Berikan senyum di awal dan akhir setiap kalimat.';
    }
    return 'Latihan tersenyum alami di depan cermin akan membantu mengurangi kesan kaku.';
  }

  String getFacialStatusLabel(int smileCount, int neutralCount) {
    if (smileCount > neutralCount && smileCount >= _SMILE_GOOD_THRESHOLD) {
      return 'Sangat Antusias';
    }
    if (smileCount > neutralCount) {
      return 'Antusias & Ramah';
    }
    if (smileCount == neutralCount && smileCount > 0) {
      return 'Cukup Antusias';
    }
    if (neutralCount > smileCount && neutralCount <= _NEUTRAL_BAD_THRESHOLD) {
      return 'Kurang Antusias';
    }
    return 'Kaku / Tidak Antusias';
  }

  // ===== POSTUR KEPALA - KESIMPULAN =====
  String getHeadPostureConclusion(int tiltLeft, int tiltRight, int down) {
    final total = tiltLeft + tiltRight + down;
    if (total <= _HEAD_TILT_GOOD_THRESHOLD) return '✅ Sangat Tegak & Stabil';
    if (total <= _HEAD_TILT_WARN_THRESHOLD) return '⚠️ Cukup Tegak';
    if (total <= _HEAD_TILT_BAD_THRESHOLD) return '⚠️ Kurang Stabil';
    return '❌ Sering Bergerak / Tidak Stabil';
  }

  String getHeadPostureSuggestion(int tiltLeft, int tiltRight, int down) {
    final total = tiltLeft + tiltRight + down;

    if (total <= 1) {
      return 'Postur kepala Anda sudah sangat baik! Pertahankan.';
    }

    if (total <= 2) {
      if (tiltLeft > 0 || tiltRight > 0) {
        return 'Usahakan kepala tetap tegak, kurangi kebiasaan memiringkan kepala.';
      } else if (down > 0) {
        return 'Usahakan tidak menunduk saat berbicara, angkat kepala Anda.';
      }
      return 'Usahakan kepala tetap tegak saat berbicara.';
    }

    if (total <= 3) {
      if (tiltLeft > 0 || tiltRight > 0) {
        return 'Kurangi kebiasaan memiringkan kepala, ini bisa terlihat seperti ragu-ragu.';
      } else if (down > 0) {
        return 'Kurangi kebiasaan menunduk, pastikan layar sejajar dengan mata Anda.';
      }
      return 'Kurangi kebiasaan memiringkan atau menundukkan kepala.';
    }

    return 'Perhatikan posisi kursi dan layar agar kepala tidak perlu menunduk atau miring. Duduk dengan posisi tegak dan rileks.';
  }

  String getHeadPostureStatusLabel(int tiltLeft, int tiltRight, int down) {
    final total = tiltLeft + tiltRight + down;
    if (total <= 1) return 'Sangat Tegak & Stabil';
    if (total <= 2) return 'Cukup Tegak';
    if (total <= 3) return 'Kurang Stabil';
    return 'Sering Bergerak / Tidak Stabil';
  }

  // ===== HELPER METHODS =====
  int getTotalEyeViolations(int lookAwayCount, int lookDownCount) {
    return lookAwayCount + lookDownCount;
  }

  int getTotalHeadViolations(int tiltLeft, int tiltRight, int down) {
    return tiltLeft + tiltRight + down;
  }

  bool isPerformanceGood({
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

    return totalEye <= 2 &&
        totalHead <= 2 &&
        smileCount >= 3 &&
        neutralCount <= 3;
  }

  bool isPerformanceBad({
    required int lookAwayCount,
    required int lookDownCount,
    required int neutralCount,
    required int headTiltLeftCount,
    required int headTiltRightCount,
    required int headDownCount,
  }) {
    final totalEye = lookAwayCount + lookDownCount;
    final totalHead = headTiltLeftCount + headTiltRightCount + headDownCount;

    return totalEye >= 4 || totalHead >= 4 || neutralCount >= 5;
  }
}
