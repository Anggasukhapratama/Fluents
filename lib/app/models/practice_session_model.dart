// lib/app/models/practice_session_model.dart
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'detection_result_model.dart';

/// Model untuk menyimpan sesi latihan wawancara
/// TIDAK mengandung skor angka, hanya label deskriptif dan frekuensi
///
/// LABEL SESUAI HRD:
/// - Kontak Mata: "Fokus terhadap Pewawancara" | "Sesekali Terdistraksi" | "Tidak Fokus"
/// - Ekspresi: "Ramah dan Profesional" | "Cukup Ramah" | "Terlalu Tegang" | "Tidak Proporsional"
/// - Postur: "Sikap Profesional" | "Sedikit Gelisah" | "Kurang Tenang"
class PracticeSession {
  final DateTime createdAt;
  final String dateKey;
  final String monthKey;
  final String difficulty; // 'medium', 'hard', 'advance'
  final int scriptLineCount;

  // Speech metrics (hanya data mentah, tanpa skor)
  final int wpm;
  final double fluency;
  final int fillerCount;

  // ===== JOB TARGET =====
  final String jobTarget;

  // ===== LABEL DESKRIPTIF 3 TINGKAT - SESUAI HRD =====
  final String eyeContactLabel;
  // "Fokus terhadap Pewawancara" | "Sesekali Terdistraksi" | "Tidak Fokus"

  final String smileLabel;
  // "Ramah dan Profesional" | "Cukup Ramah" | "Terlalu Tegang" | "Tidak Proporsional"

  final String postureLabel;
  // "Sikap Profesional" | "Sedikit Gelisah" | "Kurang Tenang"

  // ===== ANALISIS DESKRIPTIF (TANPA OVERALL) =====
  final String analysisResult; // Hasil analisis deskriptif dari AI

  // Transcript & feedback
  final String recognizedText;
  final List<String> suggestions;

  // Detailed detection result (opsional)
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
    required this.smileLabel,
    required this.postureLabel,
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
      'smileLabel': smileLabel,
      'postureLabel': postureLabel,
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
      eyeContactLabel: (m['eyeContactLabel'] ?? 'Tidak Fokus') as String,
      smileLabel: (m['smileLabel'] ?? 'Terlalu Tegang') as String,
      postureLabel: (m['postureLabel'] ?? 'Kurang Tenang') as String,
      analysisResult: (m['analysisResult'] ?? '') as String,
      recognizedText: (m['recognizedText'] ?? '') as String,
      suggestions: List<String>.from((m['suggestions'] ?? const []) as List),
      jobTarget: (m['jobTarget'] ?? '') as String,
      detectionResult: m['detectionResult'] != null
          ? DetectionResultModel.fromMap(m['detectionResult'])
          : null,
    );
  }

  /// Ringkasan singkat untuk ditampilkan di dashboard
  String get shortSummary {
    if (detectionResult != null) {
      return '${detectionResult!.overallAssessment} | $eyeContactLabel | $smileLabel';
    }
    return 'Kontak Mata: $eyeContactLabel, Ekspresi: $smileLabel, Postur: $postureLabel';
  }

  /// Mendapatkan poin dari label (untuk chart)
  int get eyeContactPoints {
    if (eyeContactLabel == 'Fokus terhadap Pewawancara') return 2;
    if (eyeContactLabel == 'Sesekali Terdistraksi') return 1;
    return 0;
  }

  int get smilePoints {
    if (smileLabel == 'Ramah dan Profesional') return 2;
    if (smileLabel == 'Cukup Ramah') return 1;
    return 0;
  }

  int get posturePoints {
    if (postureLabel == 'Sikap Profesional') return 2;
    if (postureLabel == 'Sedikit Gelisah') return 1;
    return 0;
  }

  int get totalPoints => eyeContactPoints + smilePoints + posturePoints;

  /// Warna untuk label performa (untuk UI)
  Color get performanceColor {
    final total = totalPoints;
    if (total >= 5) return const Color(0xFF059669); // Hijau tua - Sangat Baik
    if (total >= 3) return const Color(0xFF10B981); // Hijau - Baik
    if (total >= 2) return const Color(0xFFF59E0B); // Oranye - Cukup
    return const Color(0xFFEF4444); // Merah - Perlu Latihan
  }

  /// Status performa berdasarkan total poin
  String get performanceStatus {
    final total = totalPoints;
    if (total >= 5) return '🌟 Sangat Baik';
    if (total >= 3) return '✅ Baik';
    if (total >= 2) return '⚠️ Cukup';
    return '💪 Perlu Latihan';
  }

  /// Deskripsi lengkap untuk ditampilkan
  String get fullDescription {
    return '''
📊 HASIL LATIHAN WAWANCARA
═══════════════════════════

👀 KONTAK MATA: $eyeContactLabel
   Poin: $eyeContactPoints/2

😊 EKSPRESI: $smileLabel
   Poin: $smilePoints/2

🧍 POSTUR: $postureLabel
   Poin: $posturePoints/2

📊 TOTAL POIN: $totalPoints/6
   Status: $performanceStatus

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
