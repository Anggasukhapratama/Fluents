// lib/app/models/detection_result_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DetectionResultModel {
  final EyeContactResult eyeContact;
  final FacialExpressionResult facialExpression;
  final HeadPostureResult headPosture;
  final DateTime timestamp;
  final String aiSummary;

  DetectionResultModel({
    required this.eyeContact,
    required this.facialExpression,
    required this.headPosture,
    required this.timestamp,
    required this.aiSummary,
  });

  Map<String, dynamic> toMap() {
    return {
      'eyeContact': eyeContact.toMap(),
      'facialExpression': facialExpression.toMap(),
      'headPosture': headPosture.toMap(),
      'timestamp': Timestamp.fromDate(timestamp),
      'aiSummary': aiSummary,
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
      aiSummary: map['aiSummary'] ?? '',
    );
  }

  // Helper method untuk mendapatkan total pelanggaran
  int get totalEyeViolations =>
      eyeContact.lookAwayCount + eyeContact.lookDownCount;
  int get totalHeadViolations =>
      headPosture.headTiltLeftCount +
      headPosture.headTiltRightCount +
      headPosture.headDownCount;

  // Helper method untuk status keseluruhan
  String get overallStatus {
    if (totalEyeViolations <= 1 &&
        totalHeadViolations <= 1 &&
        facialExpression.smileCount >= 3) {
      return 'Sangat Baik';
    }
    if (totalEyeViolations <= 2 &&
        totalHeadViolations <= 2 &&
        facialExpression.smileCount >= 2) {
      return 'Cukup Baik';
    }
    if (totalEyeViolations >= 4 ||
        totalHeadViolations >= 4 ||
        facialExpression.neutralCount >= 5) {
      return 'Perlu Banyak Perbaikan';
    }
    return 'Perlu Peningkatan';
  }
}

// ===== KONTAK MATA =====
class EyeContactResult {
  final int lookAwayCount; // Mata melengos ke samping
  final int lookDownCount; // Mata menunduk ke bawah
  final String conclusion; // Kesimpulan
  final String suggestion; // Saran

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
      conclusion: map['conclusion'] ?? '',
      suggestion: map['suggestion'] ?? '',
    );
  }

  int get totalViolations => lookAwayCount + lookDownCount;

  String get statusLabel {
    if (totalViolations <= 1) return '✅ Sangat Fokus';
    if (totalViolations <= 2) return '⚠️ Cukup Fokus';
    if (totalViolations <= 4) return '❌ Kurang Fokus';
    return '❌❌ Sangat Kurang Fokus';
  }

  String get simpleStatus {
    if (totalViolations <= 1) return 'Sangat Fokus';
    if (totalViolations <= 2) return 'Cukup Fokus';
    if (totalViolations <= 4) return 'Kurang Fokus';
    return 'Sangat Kurang Fokus';
  }
}

// ===== EKSPRESI WAJAH =====
class FacialExpressionResult {
  final int smileCount; // Tersenyum
  final int neutralCount; // Wajah kaku/datar
  final String conclusion;
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
      conclusion: map['conclusion'] ?? '',
      suggestion: map['suggestion'] ?? '',
    );
  }

  String get statusLabel {
    if (smileCount > neutralCount && smileCount >= 3)
      return '✅ Sangat Antusias';
    if (smileCount > neutralCount) return '✅ Antusias & Ramah';
    if (smileCount == neutralCount && smileCount > 0)
      return '⚠️ Cukup Antusias';
    if (neutralCount > smileCount && neutralCount <= 3)
      return '⚠️ Kurang Antusias';
    return '❌ Kaku / Tidak Antusias';
  }

  String get simpleStatus {
    if (smileCount > neutralCount && smileCount >= 3) return 'Sangat Antusias';
    if (smileCount > neutralCount) return 'Antusias & Ramah';
    if (smileCount == neutralCount && smileCount > 0) return 'Cukup Antusias';
    if (neutralCount > smileCount && neutralCount <= 3)
      return 'Kurang Antusias';
    return 'Kaku / Tidak Antusias';
  }
}

// ===== POSTUR KEPALA =====
class HeadPostureResult {
  final int headTiltLeftCount; // Kepala miring ke kiri
  final int headTiltRightCount; // Kepala miring ke kanan
  final int headDownCount; // Kepala menunduk
  final String conclusion;
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
      conclusion: map['conclusion'] ?? '',
      suggestion: map['suggestion'] ?? '',
    );
  }

  int get totalViolations =>
      headTiltLeftCount + headTiltRightCount + headDownCount;

  String get statusLabel {
    if (totalViolations <= 1) return '✅ Sangat Tegak & Stabil';
    if (totalViolations <= 2) return '⚠️ Cukup Tegak';
    if (totalViolations <= 3) return '⚠️ Kurang Stabil';
    return '❌ Sering Bergerak / Tidak Stabil';
  }

  String get simpleStatus {
    if (totalViolations <= 1) return 'Sangat Tegak & Stabil';
    if (totalViolations <= 2) return 'Cukup Tegak';
    if (totalViolations <= 3) return 'Kurang Stabil';
    return 'Sering Bergerak / Tidak Stabil';
  }
}
