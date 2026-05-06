// lib/app/models/practice_session_model.dart
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'detection_result_model.dart';

/// Model untuk menyimpan sesi latihan wawancara
/// TIDAK mengandung skor angka, hanya label deskriptif dan frekuensi
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

  // ===== LABEL DESKRIPTIF 3 TINGKAT =====
  final String eyeContactLabel;
  // "Fokus & Percaya Diri", "Sesekali Terdistraksi", "Sering Kehilangan Fokus"

  final String smileLabel;
  // "Ramah & Antusias", "Cukup Ramah / Netral", "Kaku & Tegang"

  final String postureLabel;
  // "Tenang & Profesional", "Sedikit Gelisah", "Gugup & Cemas"

  final String overallLabel;
  // "Siap Wawancara", "Cukup Siap", "Butuh Banyak Latihan" ✅ DIPERBAIKI

  final String confidenceMessage; // Pesan motivasi

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
    required this.overallLabel,
    required this.confidenceMessage,
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
      'eyeContactLabel': eyeContactLabel,
      'smileLabel': smileLabel,
      'postureLabel': postureLabel,
      'overallLabel': overallLabel,
      'confidenceMessage': confidenceMessage,
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
      eyeContactLabel:
          (m['eyeContactLabel'] ?? 'Sering Kehilangan Fokus') as String,
      smileLabel: (m['smileLabel'] ?? 'Kaku & Tegang') as String,
      postureLabel: (m['postureLabel'] ?? 'Gugup & Cemas') as String,
      // ✅ PERBAIKAN: default value & komentar
      overallLabel: (m['overallLabel'] ?? 'Butuh Banyak Latihan') as String,
      confidenceMessage:
          (m['confidenceMessage'] ?? 'Terus berlatih, Anda pasti bisa!')
              as String,
      recognizedText: (m['recognizedText'] ?? '') as String,
      suggestions: List<String>.from((m['suggestions'] ?? const []) as List),
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
    return 'Penilaian: $overallLabel - $confidenceMessage';
  }

  /// Apakah performa tergolong baik?
  /// ✅ DIPERBAIKI: menggunakan label yang benar
  bool get isGoodPerformance {
    return overallLabel == 'Siap Wawancara' || overallLabel == 'Cukup Siap';
  }

  /// Warna untuk label performa (untuk UI)
  Color get performanceColor {
    switch (overallLabel) {
      case 'Siap Wawancara':
        return const Color(0xFF10B981); // Hijau
      case 'Cukup Siap':
        return const Color(0xFFF59E0B); // Oranye
      case 'Butuh Banyak Latihan':
        return const Color(0xFFEF4444); // Merah
      default:
        return const Color(0xFF6B7280); // Abu-abu
    }
  }

  /// Mendapatkan poin dari label overall (untuk chart)
  int get overallPoints {
    switch (overallLabel) {
      case 'Siap Wawancara':
        return 3;
      case 'Cukup Siap':
        return 2;
      case 'Butuh Banyak Latihan':
        return 1;
      default:
        return 0;
    }
  }

  /// Status deskriptif untuk ditampilkan
  String get overallStatus {
    switch (overallLabel) {
      case 'Siap Wawancara':
        return '✅ Siap menghadapi wawancara sesungguhnya';
      case 'Cukup Siap':
        return '⚠️ Cukup siap, perlu sedikit latihan lagi';
      case 'Butuh Banyak Latihan':
        return '💪 Butuh latihan lebih banyak';
      default:
        return 'Belum dinilai';
    }
  }
}
