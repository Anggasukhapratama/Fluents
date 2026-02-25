import 'package:cloud_firestore/cloud_firestore.dart';

class PracticeSession {
  final DateTime createdAt;

  /// yyyy-MM-dd
  final String dateKey;

  /// yyyy-MM
  final String monthKey;

  final String difficulty;
  final int scriptLineCount;

  // Speech metrics
  final int wpm;
  final double fluency; // 0..100
  final int fillerCount;

  // MLKit scores
  final int scoreMouth; // 0..100
  final int scoreTilt; // 0..100
  final int scorePosture; // 0..100
  final int nervousScore; // 0..100
  final String nervousLabel;

  // raw-ish snapshot values (optional)
  final double avgMouthRatio; // 0..1
  final double avgTiltAbsDeg;
  final double avgPostureLean; // 0..1

  // STT
  final String recognizedText;

  // Suggestions
  final List<String> suggestions;

  PracticeSession({
    required this.createdAt,
    required this.dateKey,
    required this.monthKey,
    required this.difficulty,
    required this.scriptLineCount,
    required this.wpm,
    required this.fluency,
    required this.fillerCount,
    required this.scoreMouth,
    required this.scoreTilt,
    required this.scorePosture,
    required this.nervousScore,
    required this.nervousLabel,
    required this.avgMouthRatio,
    required this.avgTiltAbsDeg,
    required this.avgPostureLean,
    required this.recognizedText,
    required this.suggestions,
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
      'scoreMouth': scoreMouth,
      'scoreTilt': scoreTilt,
      'scorePosture': scorePosture,
      'nervousScore': nervousScore,
      'nervousLabel': nervousLabel,
      'avgMouthRatio': avgMouthRatio,
      'avgTiltAbsDeg': avgTiltAbsDeg,
      'avgPostureLean': avgPostureLean,
      'recognizedText': recognizedText,
      'suggestions': suggestions,
    };
  }

  static PracticeSession fromMap(Map<String, dynamic> m) {
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
      scoreMouth: (m['scoreMouth'] ?? 0) as int,
      scoreTilt: (m['scoreTilt'] ?? 0) as int,
      scorePosture: (m['scorePosture'] ?? 0) as int,
      nervousScore: (m['nervousScore'] ?? 0) as int,
      nervousLabel: (m['nervousLabel'] ?? 'Tenang') as String,
      avgMouthRatio: ((m['avgMouthRatio'] ?? 0.0) as num).toDouble(),
      avgTiltAbsDeg: ((m['avgTiltAbsDeg'] ?? 0.0) as num).toDouble(),
      avgPostureLean: ((m['avgPostureLean'] ?? 0.0) as num).toDouble(),
      recognizedText: (m['recognizedText'] ?? '') as String,
      suggestions: List<String>.from((m['suggestions'] ?? const []) as List),
    );
  }
}
