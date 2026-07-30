// lib/app/models/practice_session_model.dart
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detection_result_model.dart';

class PracticeSession {
  final DateTime createdAt;
  final String dateKey;
  final String monthKey;
  final String difficulty;
  final int scriptLineCount;
  final int wpm;
  final double fluency;
  final int fillerCount;
  final String jobTarget;
  final String eyeContactLabel;
  final String analysisResult;
  final String recognizedText;
  final List<String> suggestions;
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
    required this.eyeContactLabel,
    required this.analysisResult,
    required this.recognizedText,
    required this.suggestions,
    this.jobTarget = '',
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
      'eyeContactLabel': eyeContactLabel,
      'analysisResult': analysisResult,
      'recognizedText': recognizedText,
      'suggestions': suggestions,
      'jobTarget': jobTarget,
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
      eyeContactLabel: (m['eyeContactLabel'] ?? 'Terlalu Sedikit') as String,
      analysisResult: (m['analysisResult'] ?? '') as String,
      recognizedText: (m['recognizedText'] ?? '') as String,
      suggestions: List<String>.from((m['suggestions'] ?? const []) as List),
      jobTarget: (m['jobTarget'] ?? '') as String,
      detectionResult: m['detectionResult'] != null
          ? DetectionResultModel.fromMap(m['detectionResult'])
          : null,
    );
  }

  String get shortSummary {
    return 'Kontak Mata: $eyeContactLabel (${detectionResult?.eyeContact.focusPercentage.toStringAsFixed(1)}%)';
  }

  int get eyeContactPoints {
    if (eyeContactLabel == 'Ideal') return 2;
    if (eyeContactLabel == 'Terlalu Lama') return 1;
    return 0;
  }

  int get totalPoints => eyeContactPoints;

  Color get performanceColor {
    if (eyeContactLabel == 'Ideal') return const Color(0xFF10B981);
    if (eyeContactLabel == 'Terlalu Lama') return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get performanceStatus {
    if (eyeContactLabel == 'Ideal') return '✅ Baik';
    if (eyeContactLabel == 'Terlalu Lama') return '⚠️ Terlalu Fokus';
    return '💪 Perlu Perbaikan';
  }

  String get fullDescription {
    final pct = detectionResult?.eyeContact.focusPercentage ?? 0.0;
    return '''
📊 HASIL LATIHAN WAWANCARA
═══════════════════════════

👀 KONTAK MATA: $eyeContactLabel (${pct.toStringAsFixed(1)}%)
   ${detectionResult?.eyeContact.getDetailedAnalysis() ?? ''}

🗣️ KECEPATAN BICARA: $wpm WPM
🗣️ KATA PENGISI: $fillerCount kali
📝 TOTAL KATA: ${_countWords(recognizedText)} kata

📋 ANALISIS:
$analysisResult
''';
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
}
