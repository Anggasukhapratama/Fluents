// lib/app/models/detection_result_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DetectionResultModel {
  final EyeContactResult eyeContact;
  final DateTime timestamp;
  final String aiRecommendation;

  DetectionResultModel({
    required this.eyeContact,
    required this.timestamp,
    required this.aiRecommendation,
  });

  Map<String, dynamic> toMap() {
    return {
      'eyeContact': eyeContact.toMap(),
      'timestamp': Timestamp.fromDate(timestamp),
      'aiRecommendation': aiRecommendation,
    };
  }

  factory DetectionResultModel.fromMap(Map<String, dynamic> map) {
    return DetectionResultModel(
      eyeContact: EyeContactResult.fromMap(map['eyeContact'] ?? {}),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      aiRecommendation: map['aiRecommendation'] ?? '',
    );
  }

  String get overallAssessment {
    final label = eyeContact.conclusion;
    if (label == 'Ideal') return 'Kontak Mata Baik';
    if (label == 'Terlalu Lama') return 'Terlalu Fokus';
    return 'Kurang Kontak Mata';
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