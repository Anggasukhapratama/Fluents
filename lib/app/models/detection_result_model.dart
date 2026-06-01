// lib/app/models/detection_result_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk hasil deteksi perilaku selama sesi wawancara
/// TIDAK mengandung skor angka, hanya label deskriptif 3 tingkat
class DetectionResultModel {
  final EyeContactResult eyeContact;
  final FacialExpressionResult facialExpression;
  final HeadPostureResult headPosture;
  final DateTime timestamp;
  final String aiRecommendation; // Rekomendasi dari LLM (Llama 3.1 8B via Groq)

  DetectionResultModel({
    required this.eyeContact,
    required this.facialExpression,
    required this.headPosture,
    required this.timestamp,
    required this.aiRecommendation,
  });

  Map<String, dynamic> toMap() {
    return {
      'eyeContact': eyeContact.toMap(),
      'facialExpression': facialExpression.toMap(),
      'headPosture': headPosture.toMap(),
      'timestamp': Timestamp.fromDate(timestamp),
      'aiRecommendation': aiRecommendation,
    };
  }

  factory DetectionResultModel.fromMap(Map<String, dynamic> map) {
    return DetectionResultModel(
      eyeContact: EyeContactResult.fromMap(map['eyeContact'] ?? {}),
      facialExpression: FacialExpressionResult.fromMap(
        map['facialExpression'] ?? {},
      ),
      headPosture: HeadPostureResult.fromMap(map['headPosture'] ?? {}),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      aiRecommendation: map['aiRecommendation'] ?? '',
    );
  }

  /// Mendapatkan status keseluruhan (3 tingkat) dengan sistem poin
  String get overallAssessment {
    int eyePoints = _getPointsFromLabel(eyeContact.conclusion);
    int facePoints = _getPointsFromLabel(facialExpression.conclusion);
    int posturePoints = _getPointsFromLabel(headPosture.conclusion);

    int totalPoints = eyePoints + facePoints + posturePoints;
    bool hasZero = (eyePoints == 0 || facePoints == 0 || posturePoints == 0);

    if (totalPoints == 6) return 'Sangat Percaya Diri';
    if (totalPoints >= 4 && totalPoints <= 5 && !hasZero) return 'Siap Wawancara';
    if (totalPoints >= 2 && totalPoints <= 3) return 'Cukup Baik';
    return 'Perlu Banyak Latihan';
  }

  // Helper untuk konversi label ke poin
  int _getPointsFromLabel(String label) {
    if (label.contains('Fokus & Percaya Diri') ||
        label.contains('Ramah & Antusias') ||
        label.contains('Tenang & Profesional')) {
      return 2;
    }
    if (label.contains('Sesekali Terdistraksi') ||
        label.contains('Cukup Ramah') ||
        label.contains('Sedikit Gelisah')) {
      return 1;
    }
    return 0;
  }

  /// Apakah performa tergolong baik?
  bool get isGoodPerformance {
    return overallAssessment == 'Sangat Percaya Diri' ||
        overallAssessment == 'Siap Wawancara' ||
        overallAssessment == 'Cukup Baik';
  }

  /// Rekomendasi singkat dari sistem (fallback jika AI gagal)
  String get fallbackRecommendation {
    final buffer = StringBuffer();

    if (eyeContact.needsImprovement) {
      buffer.writeln('👀 Kontak mata: ${eyeContact.improvementSuggestion}');
    }
    if (facialExpression.needsImprovement) {
      buffer.writeln('😊 Ekspresi: ${facialExpression.improvementSuggestion}');
    }
    if (headPosture.needsImprovement) {
      buffer.writeln('🧍 Postur: ${headPosture.improvementSuggestion}');
    }

    if (buffer.isEmpty) {
      return '✨ Performa Anda sangat baik! Pertahankan kepercayaan diri ini untuk wawancara sesungguhnya.';
    }
    return buffer.toString();
  }
}

// ==================== KONTAK MATA (3 TINGKAT) ====================
class EyeContactResult {
  final int lookAwayCount; // Frekuensi melirik ke samping
  final int lookDownCount; // Frekuensi menunduk
  final String
  conclusion; // "Fokus & Percaya Diri", "Sesekali Terdistraksi", "Sering Kehilangan Fokus"
  final String suggestion; // Saran perbaikan

  EyeContactResult({
    required this.lookAwayCount,
    required this.lookDownCount,
    required this.conclusion,
    required this.suggestion,
  });

  Map<String, dynamic> toMap() => {
    'lookAwayCount': lookAwayCount,
    'lookDownCount': lookDownCount,
    'conclusion': conclusion,
    'suggestion': suggestion,
  };

  factory EyeContactResult.fromMap(Map<String, dynamic> map) {
    return EyeContactResult(
      lookAwayCount: map['lookAwayCount'] ?? 0,
      lookDownCount: map['lookDownCount'] ?? 0,
      conclusion: map['conclusion'] ?? 'Sering Kehilangan Fokus',
      suggestion:
          map['suggestion'] ?? 'Latih kontak mata dengan menatap kamera.',
    );
  }

  int get totalViolations => lookAwayCount + lookDownCount;

  /// Status deskriptif (3 tingkat)
  String get descriptiveStatus {
    final total = totalViolations;
    if (total <= 3)
      return 'Fokus & Percaya Diri - Kontak mata terjaga dengan sangat baik';
    if (total <= 6)
      return 'Sesekali Terdistraksi - Kontak mata cukup stabil, sesekali teralihkan';
    return 'Sering Kehilangan Fokus - Kontak mata tidak stabil, perlu latihan intensif';
  }

  /// Apakah perlu perbaikan?
  bool get needsImprovement => totalViolations > 6;

  /// Saran perbaikan spesifik
  String get improvementSuggestion {
    // ✅ Cek dulu apakah benar-benar perlu improvement
    if (!needsImprovement) {
      return 'Pertahankan kontak mata yang baik! Anda sudah fokus ke kamera.';
    }

    // ✅ Baru kasih saran spesifik
    if (lookAwayCount > lookDownCount) {
      return 'Cobalah mengurangi kebiasaan melirik ke samping. Bayangkan kamera adalah mata pewawancara.';
    }
    if (lookDownCount > lookAwayCount) {
      return 'Cobalah tidak menunduk saat berbicara. Atur ketinggian layar agar sejajar dengan mata.';
    }
    return 'Latih kontak mata dengan fokus pada satu titik (misalnya titik tengah kamera) selama 30 detik.';
  }
}

// ==================== EKSPRESI WAJAH (3 TINGKAT) ====================
class FacialExpressionResult {
  final int smileCount; // Frekuensi tersenyum
  final int neutralCount; // Frekuensi wajah datar/kaku
  final String
  conclusion; // "Ramah & Antusias", "Cukup Ramah / Netral", "Kaku & Tegang"
  final String suggestion;

  FacialExpressionResult({
    required this.smileCount,
    required this.neutralCount,
    required this.conclusion,
    required this.suggestion,
  });

  Map<String, dynamic> toMap() => {
    'smileCount': smileCount,
    'neutralCount': neutralCount,
    'conclusion': conclusion,
    'suggestion': suggestion,
  };

  factory FacialExpressionResult.fromMap(Map<String, dynamic> map) {
    return FacialExpressionResult(
      smileCount: map['smileCount'] ?? 0,
      neutralCount: map['neutralCount'] ?? 0,
      conclusion: map['conclusion'] ?? 'Kaku & Tegang',
      suggestion: map['suggestion'] ?? 'Cobalah tersenyum lebih sering.',
    );
  }

  /// Status deskriptif (3 tingkat)
  String get descriptiveStatus {
    if (smileCount >= 3 && smileCount > neutralCount) {
      return 'Ramah & Antusias - Ekspresi ramah dan menunjukkan antusiasme tinggi';
    }
    if (smileCount >= 1) {
      return 'Cukup Ramah / Netral - Ekspresi cukup ramah, namun bisa lebih hangat';
    }
    return 'Kaku & Tegang - Ekspresi datar, perlu peningkatan frekuensi senyum';
  }

  /// Apakah perlu perbaikan?
  bool get needsImprovement => smileCount <= 1 || neutralCount >= 4;

  /// Saran perbaikan spesifik
  String get improvementSuggestion {
    if (smileCount == 0) {
      return 'Cobalah tersenyum setidaknya 2-3 kali selama wawancara, terutama di awal dan akhir jawaban.';
    }
    if (smileCount <= 2) {
      return 'Tingkatkan frekuensi senyum Anda. Tersenyum natural membuat Anda terlihat lebih percaya diri.';
    }
    return 'Pertahankan senyum ramah Anda, itu adalah aset berharga dalam wawancara!';
  }
}

// ==================== POSTUR KEPALA (3 TINGKAT) ====================
class HeadPostureResult {
  final int headTiltLeftCount; // Miring kiri
  final int headTiltRightCount; // Miring kanan
  final int headDownCount; // Menunduk
  final String
  conclusion; // "Tenang & Profesional", "Sedikit Gelisah", "Gugup & Cemas"
  final String suggestion;

  HeadPostureResult({
    required this.headTiltLeftCount,
    required this.headTiltRightCount,
    required this.headDownCount,
    required this.conclusion,
    required this.suggestion,
  });

  Map<String, dynamic> toMap() => {
    'headTiltLeftCount': headTiltLeftCount,
    'headTiltRightCount': headTiltRightCount,
    'headDownCount': headDownCount,
    'conclusion': conclusion,
    'suggestion': suggestion,
  };

  factory HeadPostureResult.fromMap(Map<String, dynamic> map) {
    return HeadPostureResult(
      headTiltLeftCount: map['headTiltLeftCount'] ?? 0,
      headTiltRightCount: map['headTiltRightCount'] ?? 0,
      headDownCount: map['headDownCount'] ?? 0,
      conclusion: map['conclusion'] ?? 'Gugup & Cemas',
      suggestion: map['suggestion'] ?? 'Duduklah dengan postur lebih tegak.',
    );
  }

  int get totalViolations =>
      headTiltLeftCount + headTiltRightCount + headDownCount;

  /// Status deskriptif (3 tingkat)
  String get descriptiveStatus {
    final total = totalViolations;
    if (total <= 3)
      return 'Tenang & Profesional - Postur kepala tegak dan stabil';
    if (total <= 6)
      return 'Sedikit Gelisah - Postur kepala cukup stabil, ada sedikit gerakan';
    return 'Gugup & Cemas - Postur kepala tidak stabil, banyak gerakan tidak terkontrol';
  }

  /// Apakah perlu perbaikan?
  bool get needsImprovement => totalViolations > 6;

  /// Saran perbaikan spesifik
  String get improvementSuggestion {
    if (headTiltLeftCount > 0 || headTiltRightCount > 0) {
      return 'Kurangi kebiasaan memiringkan kepala. Duduklah dengan bahu tegak dan rileks.';
    }
    if (headDownCount > 0) {
      return 'Hindari menunduk saat berbicara. Pastikan layar kamera sejajar dengan pandangan mata.';
    }
    return 'Jaga postur tubuh tetap tegak. Latihan di depan cermin dapat membantu membangun kebiasaan baik.';
  }
}
