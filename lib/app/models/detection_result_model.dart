// lib/app/models/detection_result_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DetectionResultModel {
  final EyeContactResult eyeContact;
  final SmileResult? smileResult;
  final DateTime timestamp;
  final String aiRecommendation;

  DetectionResultModel({
    required this.eyeContact,
    this.smileResult,
    required this.timestamp,
    required this.aiRecommendation,
  });

  Map<String, dynamic> toMap() {
    return {
      'eyeContact': eyeContact.toMap(),
      if (smileResult != null) 'smileResult': smileResult!.toMap(),
      'timestamp': Timestamp.fromDate(timestamp),
      'aiRecommendation': aiRecommendation,
    };
  }

  factory DetectionResultModel.fromMap(Map<String, dynamic> map) {
    return DetectionResultModel(
      eyeContact: EyeContactResult.fromMap(map['eyeContact'] ?? {}),
      smileResult: map['smileResult'] != null
          ? SmileResult.fromMap(map['smileResult'])
          : null,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      aiRecommendation: map['aiRecommendation'] ?? '',
    );
  }

  String get overallAssessment {
    final eyeLabel = eyeContact.conclusion;
    String eyeAssessment;
    if (eyeLabel == 'Ideal') eyeAssessment = 'Kontak Mata Baik';
    else if (eyeLabel == 'Terlalu Lama') eyeAssessment = 'Terlalu Fokus';
    else eyeAssessment = 'Kurang Kontak Mata';

    if (smileResult == null) return eyeAssessment;

    return '$eyeAssessment | Senyum: ${smileResult!.dominantLabel}';
  }

  bool get isGoodPerformance => eyeContact.conclusion == 'Ideal';
}

class EyeContactResult {
  final double focusPercentage;
  final int totalBreaks;
  final String conclusion;
  final String suggestion;

  EyeContactResult({
    required this.focusPercentage,
    required this.totalBreaks,
    required this.conclusion,
    required this.suggestion,
  });

  Map<String, dynamic> toMap() => {
    'focusPercentage': focusPercentage,
    'totalBreaks': totalBreaks,
    'conclusion': conclusion,
    'suggestion': suggestion,
  };

  factory EyeContactResult.fromMap(Map<String, dynamic> map) {
    return EyeContactResult(
      focusPercentage: (map['focusPercentage'] ?? 0.0).toDouble(),
      totalBreaks: map['totalBreaks'] ?? 0,
      conclusion: map['conclusion'] ?? 'Terlalu Sedikit',
      suggestion: map['suggestion'] ?? 'Usahakan lebih sering melihat kamera.',
    );
  }

  String getDetailedAnalysis() {
    if (conclusion == 'Ideal') {
      return '✅ Frekuensi fokus ideal. Total menengok $totalBreaks kali.';
    } else if (conclusion == 'Terlalu Lama') {
      return '⚠️ Terlalu menatap kaku. Total menengok $totalBreaks kali.';
    } else {
      return '❌ Kurang fokus. Total menengok $totalBreaks kali.';
    }
  }
}

class SmileResult {
  final int totalSmiles;
  // Counters kept for feedback/analysis — kept for backward compatibility
  final int totalAuthentic;
  final int totalFake;
  final int totalUncertain;
  final String dominantLabel;
  final String suggestion;

  SmileResult({
    required this.totalSmiles,
    this.totalAuthentic = 0,
    this.totalFake = 0,
    this.totalUncertain = 0,
    required this.dominantLabel,
    required this.suggestion,
  });

  Map<String, dynamic> toMap() => {
    'totalSmiles': totalSmiles,
    'totalAuthentic': totalAuthentic,
    'totalFake': totalFake,
    'totalUncertain': totalUncertain,
    'dominantLabel': dominantLabel,
    'suggestion': suggestion,
  };

  factory SmileResult.fromMap(Map<String, dynamic> map) {
    return SmileResult(
      totalSmiles: map['totalSmiles'] ?? 0,
      totalAuthentic: map['totalAuthentic'] ?? 0,
      totalFake: map['totalFake'] ?? 0,
      totalUncertain: map['totalUncertain'] ?? 0,
      dominantLabel: map['dominantLabel'] ?? '',
      suggestion: map['suggestion'] ?? '',
    );
  }
}