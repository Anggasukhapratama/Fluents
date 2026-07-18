// lib/app/models/detection_result_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk hasil deteksi perilaku selama sesi wawancara
/// TIDAK mengandung skor angka, hanya label deskriptif
///
/// LABEL SESUAI HRD - Khansa Farah Salsabila:
/// - Kontak Mata (2 label): "Fokus terhadap Pewawancara" | "Tidak Fokus"
/// - Ekspresi (3 label): "Ramah dan Profesional" | "Terlalu Tegang" | "Tidak Proporsional"
/// - Postur (2 label): "Sikap Profesional" | "Kurang Tenang"
class DetectionResultModel {
  final EyeContactResult eyeContact;
  final FacialExpressionResult facialExpression;
  final HeadPostureResult headPosture;
  final DateTime timestamp;
  final String aiRecommendation;

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

  // ============================================================
  // OVERALL ASSESSMENT - Tetap pakai poin 0-6
  // ============================================================
  String get overallAssessment {
    int eyePoints = _getPointsFromLabel(eyeContact.conclusion);
    int facePoints = _getPointsFromLabel(facialExpression.conclusion);
    int posturePoints = _getPointsFromLabel(headPosture.conclusion);

    int totalPoints = eyePoints + facePoints + posturePoints;

    if (totalPoints >= 5) return 'Sangat Percaya Diri';
    if (totalPoints >= 3) return 'Siap Wawancara';
    if (totalPoints >= 2) return 'Cukup Baik';
    return 'Perlu Banyak Latihan';
  }

  int _getPointsFromLabel(String label) {
    // KONTAK MATA - 2 LABEL
    if (label.contains('Fokus terhadap Pewawancara')) return 2;
    if (label.contains('Tidak Fokus')) return 0;

    // EKSPRESI - 3 LABEL
    if (label.contains('Ramah dan Profesional')) return 2;
    if (label.contains('Terlalu Tegang')) return 0;
    if (label.contains('Tidak Proporsional')) return 0;

    // POSTUR - 2 LABEL
    if (label.contains('Sikap Profesional')) return 2;
    if (label.contains('Kurang Tenang')) return 0;

    return 0;
  }

  bool get isGoodPerformance {
    return overallAssessment == 'Sangat Percaya Diri' ||
        overallAssessment == 'Siap Wawancara' ||
        overallAssessment == 'Cukup Baik';
  }

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

  String getDescriptiveAnalysis() {
    final buffer = StringBuffer();
    buffer.writeln('📊 ANALISIS HASIL WAWANCARA');
    buffer.writeln('=' * 40);
    buffer.writeln('');

    buffer.writeln('👀 KONTAK MATA: ${eyeContact.conclusion}');
    buffer.writeln(eyeContact.getDetailedAnalysis());
    buffer.writeln('');

    buffer.writeln('😊 EKSPRESI WAJAH: ${facialExpression.conclusion}');
    buffer.writeln(facialExpression.getDetailedAnalysis());
    buffer.writeln('');

    buffer.writeln('🧍 POSTUR TUBUH: ${headPosture.conclusion}');
    buffer.writeln(headPosture.getDetailedAnalysis());
    buffer.writeln('');

    buffer.writeln('📝 REKOMENDASI');
    buffer.writeln(
      aiRecommendation.isNotEmpty ? aiRecommendation : fallbackRecommendation,
    );

    return buffer.toString();
  }
}

// ============================================================
// KONTAK MATA - 2 LABEL (Sesuai HRD)
// ============================================================
class EyeContactResult {
  final int lookAwayCount;
  final int lookDownCount;
  final String conclusion; // "Fokus terhadap Pewawancara" | "Tidak Fokus"
  final String suggestion;

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
      conclusion: map['conclusion'] ?? 'Tidak Fokus',
      suggestion:
          map['suggestion'] ?? 'Latih kontak mata dengan menatap kamera.',
    );
  }

  int get totalViolations => lookAwayCount + lookDownCount;

  /// Status deskriptif - 2 LABEL (Sesuai HRD)
  String get descriptiveStatus {
    final total = totalViolations;
    if (total <= 3)
      return 'Fokus terhadap Pewawancara - Kontak mata terjaga dengan sangat baik';
    return 'Tidak Fokus - Kontak mata tidak stabil, perlu latihan intensif';
  }

  String getDetailedAnalysis() {
    final total = totalViolations;
    if (total <= 3) {
      return '✅ Kontak mata Anda sangat baik! Anda berhasil mempertahankan fokus ke pewawancara sepanjang wawancara.';
    } else {
      String detail =
          '❌ Kontak mata Anda masih perlu banyak latihan. Terlalu sering mengalihkan pandangan.\n';
      if (lookAwayCount > 0) {
        detail += '   - Melirik ke samping: $lookAwayCount kali\n';
      }
      if (lookDownCount > 0) {
        detail += '   - Menunduk: $lookDownCount kali\n';
      }
      detail += '💡 Saran: Latih fokus menatap kamera 5 menit setiap hari.';
      return detail;
    }
  }

  bool get needsImprovement => totalViolations > 3;

  String get improvementSuggestion {
    if (!needsImprovement) {
      return '✅ Pertahankan kontak mata yang baik! Anda sudah fokus ke pewawancara.';
    }
    if (lookAwayCount > lookDownCount) {
      return '👀 Kurangi kebiasaan melirik ke samping. Bayangkan kamera adalah mata pewawancara.';
    }
    if (lookDownCount > lookAwayCount) {
      return '⬆️ Hindari menunduk saat berbicara. Atur ketinggian layar agar sejajar dengan mata.';
    }
    return '🎯 Latih kontak mata dengan fokus pada satu titik selama 30 detik.';
  }
}

// ============================================================
// EKSPRESI WAJAH - 3 LABEL (Sesuai HRD)
// Ruben, Hall, & Schmid Mast (2015): "Smiling in a Job Interview: When Less Is More"
// ============================================================
class FacialExpressionResult {
  final int smileCount;
  final int neutralCount;
  final String
  conclusion; // "Ramah dan Profesional" | "Terlalu Tegang" | "Tidak Proporsional"
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
      conclusion: map['conclusion'] ?? 'Terlalu Tegang',
      suggestion: map['suggestion'] ?? 'Cobalah tersenyum lebih sering.',
    );
  }

  /// Status deskriptif - 3 LABEL (Sesuai HRD)
  String get descriptiveStatus {
    if (smileCount >= 6 && smileCount <= 10) {
      return 'Ramah dan Profesional - Senyum natural di momen yang tepat';
    }
    if (smileCount > 10) {
      return 'Tidak Proporsional - Senyum terlalu sering, terkesan kurang serius';
    }
    return 'Terlalu Tegang - Ekspresi datar, perlu peningkatan ekspresi';
  }

  String getDetailedAnalysis() {
    if (smileCount >= 6 && smileCount <= 10) {
      return '✅ Ekspresi Anda sangat profesional! Senyum natural di momen yang tepat (${smileCount}x).\n   Ini menunjukkan keramahan dan profesionalisme yang seimbang.';
    } else if (smileCount > 10) {
      return '⚠️ Senyum Anda terlalu sering (${smileCount}x). Ini bisa terkesan tidak proporsional.\n💡 Saran: Kurangi frekuensi senyum agar terlihat lebih profesional.';
    } else {
      return '❌ Ekspresi Anda terlalu tegang. Tidak ada senyum yang terdeteksi.\n💡 Saran: Tunjukkan senyum 2-5 kali selama wawancara, terutama di awal dan akhir.';
    }
  }

  bool get needsImprovement => smileCount <= 1 || smileCount > 10;

  String get improvementSuggestion {
    if (smileCount == 0) {
      return '😊 Cobalah tersenyum 6-10 kali selama wawancara, terutama di awal dan akhir jawaban.';
    }
    if (smileCount <= 2) {
      return '😃 Tingkatkan frekuensi senyum Anda. Senyum natural membuat Anda terlihat lebih percaya diri.';
    }
    if (smileCount > 10) {
      return '⚠️ Kurangi frekuensi senyum. Senyum berlebihan (>15 kali) terkesan tidak profesional.';
    }
    return '😊 Pertahankan senyum ramah Anda, itu adalah aset berharga dalam wawancara!';
  }

  String getSmileRecommendation() {
    if (smileCount >= 6 && smileCount <= 10) {
      return '✅ Frekuensi senyum ideal! Pertahankan.';
    } else if (smileCount > 10) {
      return '⚠️ Terlalu sering. Kurangi agar terlihat profesional.';
    } else {
      return '❌ Terlalu tegang. Target: 6-10 kali senyum natural.';
    }
  }
}

// ============================================================
// POSTUR KEPALA - 2 LABEL (Sesuai HRD)
// ============================================================
class HeadPostureResult {
  final int headTiltLeftCount;
  final int headTiltRightCount;
  final int headDownCount;
  final String conclusion; // "Sikap Profesional" | "Kurang Tenang"
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
      conclusion: map['conclusion'] ?? 'Kurang Tenang',
      suggestion: map['suggestion'] ?? 'Duduklah dengan postur lebih tegak.',
    );
  }

  int get totalViolations =>
      headTiltLeftCount + headTiltRightCount + headDownCount;

  /// Status deskriptif - 2 LABEL (Sesuai HRD)
  String get descriptiveStatus {
    final total = totalViolations;
    if (total <= 3) return 'Sikap Profesional - Postur kepala tegak dan stabil';
    return 'Kurang Tenang - Postur tidak stabil, banyak gerakan tidak terkontrol';
  }

  String getDetailedAnalysis() {
    final total = totalViolations;
    if (total <= 3) {
      return '✅ Postur Anda sangat baik dan profesional! Tubuh tegak dan stabil.\n   Ini menunjukkan ketenangan dan kesiapan menghadapi wawancara.';
    } else {
      String detail =
          '❌ Postur Anda masih perlu banyak latihan. Terlalu banyak gerakan tidak stabil.\n';
      if (headTiltLeftCount > 0) {
        detail += '   - Bahu miring kiri: $headTiltLeftCount kali\n';
      }
      if (headTiltRightCount > 0) {
        detail += '   - Bahu miring kanan: $headTiltRightCount kali\n';
      }
      if (headDownCount > 0) {
        detail += '   - Kepala menunduk: $headDownCount kali\n';
      }
      detail +=
          '💡 Saran: Latih postur di depan cermin. Duduk tegak dengan bahu rileks.';
      return detail;
    }
  }

  bool get needsImprovement => totalViolations > 3;

  String get improvementSuggestion {
    if (headTiltLeftCount > 0 || headTiltRightCount > 0) {
      return '🧘 Kurangi kebiasaan memiringkan kepala. Duduklah dengan bahu tegak dan rileks.';
    }
    if (headDownCount > 0) {
      return '⬆️ Hindari menunduk saat berbicara. Pastikan layar kamera sejajar dengan pandangan mata.';
    }
    if (!needsImprovement) {
      return '✅ Postur tubuh sudah baik. Pertahankan posisi tegak dan rileks.';
    }
    return '🧍 Jaga postur tubuh tetap tegak. Latihan di depan cermin dapat membantu membangun kebiasaan baik.';
  }

  String getPostureRecommendation() {
    final total = totalViolations;
    if (total <= 3) {
      return '✅ Postur ideal! Pertahankan.';
    } else {
      return '❌ Perlu latihan postur. Target: ≤3 kali gerakan tidak stabil.';
    }
  }
}

// ============================================================
// EXTENSION: Konversi Label ke Poin
// ============================================================
extension LabelPointExtension on String {
  int get labelPoints {
    // KONTAK MATA - 2 LABEL
    if (contains('Fokus terhadap Pewawancara')) return 2;
    if (contains('Tidak Fokus')) return 0;

    // EKSPRESI - 3 LABEL
    if (contains('Ramah dan Profesional')) return 2;
    if (contains('Terlalu Tegang')) return 0;
    if (contains('Tidak Proporsional')) return 0;

    // POSTUR - 2 LABEL
    if (contains('Sikap Profesional')) return 2;
    if (contains('Kurang Tenang')) return 0;

    return 0;
  }
}
