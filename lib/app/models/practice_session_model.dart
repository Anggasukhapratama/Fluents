import 'package:cloud_firestore/cloud_firestore.dart';

class PracticeSession {
  final DateTime createdAt;
  final String dateKey;
  final String monthKey;
  final String difficulty;
  final int scriptLineCount;

  final int wpm;
  final double fluency;
  final int fillerCount;

  final int scoreSmile;
  final int scoreEye;
  final int scorePosture;

  final int overallConfidence;
  final String overallLabel;

  final String recognizedText;
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
    required this.scoreSmile,
    required this.scoreEye,
    required this.scorePosture,
    required this.overallConfidence,
    required this.overallLabel,
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
      'scoreSmile': scoreSmile,
      'scoreEye': scoreEye,
      'scorePosture': scorePosture,
      'overallConfidence': overallConfidence,
      'overallLabel': overallLabel,
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
      scoreSmile: (m['scoreSmile'] ?? 0) as int,
      scoreEye: (m['scoreEye'] ?? 0) as int,
      scorePosture: (m['scorePosture'] ?? 0) as int,
      overallConfidence: (m['overallConfidence'] ?? 0) as int,
      overallLabel: (m['overallLabel'] ?? 'Tenang') as String,
      recognizedText: (m['recognizedText'] ?? '') as String,
      suggestions: List<String>.from((m['suggestions'] ?? const []) as List),
    );
  }
}
