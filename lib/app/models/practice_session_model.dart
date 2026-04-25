// lib/app/models/practice_session_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detection_result_model.dart';

class PracticeSession {
  final DateTime createdAt;
  final String dateKey;
  final String monthKey;
  final String difficulty;
  final int scriptLineCount;

  // Speech metrics
  final int wpm;
  final double fluency;
  final int fillerCount;

  // Legacy scores (untuk kompatibilitas)
  final int scoreSmile;
  final int scoreEye;
  final int scorePosture;
  final int overallConfidence;
  final String overallLabel;

  // Transcript
  final String recognizedText;
  final List<String> suggestions;

  // NEW: Detailed detection result
  final DetectionResultModel? detectionResult;

  PracticeSession({
    required this.createdAt,
    required this.dateKey,
    required this.monthKey,
    required this.difficulty,
    required this.scriptLineCount,
    required this.wpm,
    required this.fluency,
    required this.fillerCount,
    required this.scoreSmile,
    required this.scoreEye,
    required this.scorePosture,
    required this.overallConfidence,
    required this.overallLabel,
    required this.recognizedText,
    required this.suggestions,
    this.detectionResult,
  });

  Map<String, dynamic> toMap(String uid) {
    return {
      'uid': uid,
      'createdAt': Timestamp.fromDate(createdAt),
      'dateKey': dateKey,
      'monthKey': monthKey,
      'difficulty': difficulty,
      'scriptLineCount': scriptLineCount,
      'wpm': wpm,
      'fluency': fluency,
      'fillerCount': fillerCount,
      'scoreSmile': scoreSmile,
      'scoreEye': scoreEye,
      'scorePosture': scorePosture,
      'overallConfidence': overallConfidence,
      'overallLabel': overallLabel,
      'recognizedText': recognizedText,
      'suggestions': suggestions,
      if (detectionResult != null) 'detectionResult': detectionResult!.toMap(),
    };
  }

  factory PracticeSession.fromMap(Map<String, dynamic> m, {String? docId}) {
    final ts = (m['createdAt'] as Timestamp?) ?? Timestamp.now();
    return PracticeSession(
      createdAt: ts.toDate(),
      dateKey: (m['dateKey'] ?? '') as String,
      monthKey: (m['monthKey'] ?? '') as String,
      difficulty: (m['difficulty'] ?? 'medium') as String,
      scriptLineCount: (m['scriptLineCount'] ?? 0) as int,
      wpm: (m['wpm'] ?? 0) as int,
      fluency: ((m['fluency'] ?? 0.0) as num).toDouble(),
      fillerCount: (m['fillerCount'] ?? 0) as int,
      scoreSmile: (m['scoreSmile'] ?? 0) as int,
      scoreEye: (m['scoreEye'] ?? 0) as int,
      scorePosture: (m['scorePosture'] ?? 0) as int,
      overallConfidence: (m['overallConfidence'] ?? 0) as int,
      overallLabel: (m['overallLabel'] ?? 'Tenang') as String,
      recognizedText: (m['recognizedText'] ?? '') as String,
      suggestions: List<String>.from((m['suggestions'] ?? const []) as List),
      detectionResult: m['detectionResult'] != null
          ? DetectionResultModel.fromMap(m['detectionResult'])
          : null,
    );
  }

  // Helper method untuk mendapatkan ringkasan singkat
  String get shortSummary {
    if (detectionResult != null) {
      return '${detectionResult!.overallStatus} | '
          'Mata: ${detectionResult!.eyeContact.simpleStatus} | '
          'Ekspresi: ${detectionResult!.facialExpression.simpleStatus}';
    }
    return 'Skor: $overallConfidence/100 - $overallLabel';
  }

  // Helper method untuk mengetahui apakah performa bagus
  bool get isGoodPerformance {
    if (detectionResult != null) {
      return detectionResult!.totalEyeViolations <= 2 &&
          detectionResult!.totalHeadViolations <= 2 &&
          detectionResult!.facialExpression.smileCount >= 3;
    }
    return overallConfidence >= 70;
  }
}
