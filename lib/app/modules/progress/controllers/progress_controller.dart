// lib/app/modules/progress/controllers/progress_controller.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/practice_firestore_service.dart';
import '../../../models/practice_session_model.dart';

class ProgressController extends GetxController {
  final PracticeFirestoreService _firestoreService = PracticeFirestoreService();

  final isLoading = false.obs;
  final totalSessions = 0.obs;
  final totalPoints = 0.obs;

  // ===== PERUBAHAN: Tampilkan label per parameter terakhir =====
  final lastEyeContact = ''.obs;
  final lastSmile = ''.obs;
  final lastPosture = ''.obs;
  final improvementNote = ''.obs;

  final sessions = <PracticeSession>[].obs;
  final dailyStats = <DailyStat>[].obs;

  // ===== FILTER LEVEL =====
  final selectedLevel = 'Semua Level'.obs;
  final List<String> levelOptions = [
    'Semua Level',
    'Medium',
    'Hard',
    'Advance',
  ];

  // ===== FILTER PARAMETER =====
  final selectedParam = 'Semua Parameter'.obs;
  final List<String> paramOptions = [
    'Semua Parameter',
    'Kontak Mata',
    'Ekspresi',
    'Postur',
  ];

  // ===== FILTER PEKERJAAN =====
  final selectedJob = 'Semua Pekerjaan'.obs;
  final jobOptions = <String>['Semua Pekerjaan'].obs;

  // ===== DATA UNTUK GRAFIK PER PARAMETER =====
  final eyeTrend = <double>[].obs;
  final smileTrend = <double>[].obs;
  final postureTrend = <double>[].obs;
  final trendLabels = <String>[].obs;

  final int defaultLimit = 5;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _lastSessionSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionsSub;

  @override
  void onInit() {
    super.onInit();
    _loadAllData();
    _listenToRealtimeSessions();
  }

  @override
  void onClose() {
    _lastSessionSub?.cancel();
    _sessionsSub?.cancel();
    super.onClose();
  }

  void _listenToRealtimeSessions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _sessionsSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('practice_sessions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final sessionList = snapshot.docs.map((doc) {
              return PracticeSession.fromMap(doc.data());
            }).toList();

            sessions.assignAll(sessionList);
            _updateStatsFromSessions(sessionList);
            _generateDailyStats();
          },
          onError: (e) {
            if (kDebugMode) print('❌ Error loading sessions: $e');
          },
        );
  }

  void _updateStatsFromSessions(List<PracticeSession> sessionList) {
    totalSessions.value = sessionList.length;

    if (sessionList.isEmpty) {
      lastEyeContact.value = 'Belum ada latihan';
      lastSmile.value = 'Belum ada latihan';
      lastPosture.value = 'Belum ada latihan';
      improvementNote.value = '💪 Mulai latihan pertama Anda!';
      _generatePerformanceTrend();
      return;
    }

    // Ambil sesi terakhir
    final latest = sessionList.first;
    lastEyeContact.value = latest.eyeContactLabel;
    lastSmile.value = latest.smileLabel;
    lastPosture.value = latest.postureLabel;

    improvementNote.value = _getImprovementNote(sessionList);
    _updateJobOptions(sessionList);
    _loadUserPoints();
    _generatePerformanceTrend();
  }

  void _updateJobOptions(List<PracticeSession> sessionList) {
    final Map<String, String> normalizedJobs = {};
    for (var session in sessionList) {
      final raw = session.jobTarget.trim();
      if (raw.isNotEmpty) {
        final lower = raw.toLowerCase();
        if (!normalizedJobs.containsKey(lower)) {
          normalizedJobs[lower] = raw;
        }
      }
    }

    final sortedJobs = normalizedJobs.values.toList()..sort();
    jobOptions.assignAll(['Semua Pekerjaan', ...sortedJobs]);

    if (selectedJob.value != 'Semua Pekerjaan' &&
        !jobOptions.contains(selectedJob.value)) {
      selectedJob.value = 'Semua Pekerjaan';
    }
  }

  String _getImprovementNote(List<PracticeSession> sessionList) {
    if (sessionList.length < 2) {
      return '💪 Terus semangat! Setiap latihan membawa Anda lebih dekat ke sukses.';
    }

    final latest = sessionList.first;
    final previous = sessionList[1];

    // Bandingkan berdasarkan total poin
    if (latest.totalPoints > previous.totalPoints) {
      return '🎉 Selamat! Performa Anda meningkat dibanding latihan sebelumnya!';
    } else if (latest.totalPoints < previous.totalPoints) {
      return '📈 Terus semangat! Setiap latihan membawa Anda lebih dekat ke sukses.';
    } else {
      return '💪 Konsistensi adalah kunci. Pertahankan semangat latihan Anda!';
    }
  }

  Future<void> _loadUserPoints() async {
    try {
      final stats = await _firestoreService.getUserStatistics();
      totalPoints.value = stats['totalPoints'] ?? 0;
    } catch (e) {
      if (kDebugMode) print('❌ Error loading user points: $e');
    }
  }

  Future<void> _loadAllData() async {
    isLoading.value = true;

    try {
      final allSessions = await _firestoreService.getAllSessions(limit: 100);
      sessions.assignAll(allSessions);
      _updateStatsFromSessions(allSessions);
      _generateDailyStats();
    } catch (e) {
      if (kDebugMode) print('❌ Error loading progress: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _generateDailyStats() {
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) {
      return DateTime(now.year, now.month, now.day - i);
    }).reversed.toList();

    dailyStats.clear();

    for (var date in last7Days) {
      final dateKey = _formatDateKey(date);
      final daySessions = sessions.where((s) => s.dateKey == dateKey).toList();

      String bestEye = 'Tidak ada';
      String bestSmile = 'Tidak ada';
      String bestPosture = 'Tidak ada';
      int bestPoints = 0;

      for (var session in daySessions) {
        if (session.totalPoints > bestPoints) {
          bestPoints = session.totalPoints;
          bestEye = session.eyeContactLabel;
          bestSmile = session.smileLabel;
          bestPosture = session.postureLabel;
        }
      }

      dailyStats.add(
        DailyStat(
          date: date,
          dateKey: dateKey,
          sessionCount: daySessions.length,
          bestEye: bestEye,
          bestSmile: bestSmile,
          bestPosture: bestPosture,
          points: bestPoints,
        ),
      );
    }
  }

  // ===== GRAFIK PER PARAMETER =====
  void _generatePerformanceTrend() {
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) {
      return DateTime(now.year, now.month, now.day - i);
    }).reversed.toList();

    eyeTrend.clear();
    smileTrend.clear();
    postureTrend.clear();
    trendLabels.clear();

    final labelPoints = {
      'Fokus terhadap Pewawancara': 3,
      'Sesekali Terdistraksi': 2,
      'Tidak Fokus': 1,
      'Ramah dan Profesional': 3,
      'Cukup Ramah': 2,
      'Terlalu Tegang': 1,
      'Tidak Proporsional': 1,
      'Sikap Profesional': 3,
      'Sedikit Gelisah': 2,
      'Kurang Tenang': 1,
    };

    for (var date in last7Days) {
      final dateKey = _formatDateKey(date);
      final daySessions = sessions.where((s) => s.dateKey == dateKey).toList();

      int bestEyePoint = 0;
      int bestSmilePoint = 0;
      int bestPosturePoint = 0;
      String bestEye = 'Tidak ada';
      String bestSmile = 'Tidak ada';
      String bestPosture = 'Tidak ada';

      for (var session in daySessions) {
        final ePoint = labelPoints[session.eyeContactLabel] ?? 0;
        final sPoint = labelPoints[session.smileLabel] ?? 0;
        final pPoint = labelPoints[session.postureLabel] ?? 0;

        if (ePoint > bestEyePoint) {
          bestEyePoint = ePoint;
          bestEye = session.eyeContactLabel;
        }
        if (sPoint > bestSmilePoint) {
          bestSmilePoint = sPoint;
          bestSmile = session.smileLabel;
        }
        if (pPoint > bestPosturePoint) {
          bestPosturePoint = pPoint;
          bestPosture = session.postureLabel;
        }
      }

      eyeTrend.add(bestEyePoint.toDouble());
      smileTrend.add(bestSmilePoint.toDouble());
      postureTrend.add(bestPosturePoint.toDouble());
      trendLabels.add(_getShortDayName(date.weekday));
    }
  }

  String _getShortDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Sen';
      case 2:
        return 'Sel';
      case 3:
        return 'Rab';
      case 4:
        return 'Kam';
      case 5:
        return 'Jum';
      case 6:
        return 'Sab';
      case 7:
        return 'Min';
      default:
        return '';
    }
  }

  String _formatDateKey(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  Future<void> refreshData() async {
    await _loadAllData();
  }

  // ===== FILTER METHODS =====
  void setLevel(String level) {
    selectedLevel.value = level;
  }

  void setParam(String param) {
    selectedParam.value = param;
  }

  void setJob(String job) {
    selectedJob.value = job;
  }

  void resetAllFilters() {
    selectedLevel.value = 'Semua Level';
    selectedParam.value = 'Semua Parameter';
    selectedJob.value = 'Semua Pekerjaan';
  }

  // ===== GET FILTERED SESSIONS =====
  List<PracticeSession> getFilteredSessions() {
    var filtered = sessions.toList();

    if (selectedLevel.value != 'Semua Level') {
      final levelMap = {
        'Medium': 'medium',
        'Hard': 'hard',
        'Advance': 'advance',
      };
      final targetLevel = levelMap[selectedLevel.value];
      if (targetLevel != null) {
        filtered = filtered.where((s) => s.difficulty == targetLevel).toList();
      }
    }

    if (selectedJob.value != 'Semua Pekerjaan') {
      filtered = filtered
          .where(
            (s) =>
                s.jobTarget.trim().toLowerCase() ==
                selectedJob.value.toLowerCase(),
          )
          .toList();
    }

    if (filtered.length > defaultLimit) {
      filtered = filtered.sublist(0, defaultLimit);
    }

    return filtered;
  }

  List<PracticeSession> getSessionsForParamFilter() {
    var filtered = sessions.toList();

    if (selectedLevel.value != 'Semua Level') {
      final levelMap = {
        'Medium': 'medium',
        'Hard': 'hard',
        'Advance': 'advance',
      };
      final targetLevel = levelMap[selectedLevel.value];
      if (targetLevel != null) {
        filtered = filtered.where((s) => s.difficulty == targetLevel).toList();
      }
    }

    if (selectedJob.value != 'Semua Pekerjaan') {
      filtered = filtered
          .where(
            (s) =>
                s.jobTarget.trim().toLowerCase() ==
                selectedJob.value.toLowerCase(),
          )
          .toList();
    }

    return filtered;
  }

  bool get hasActiveFilter {
    return selectedLevel.value != 'Semua Level' ||
        selectedParam.value != 'Semua Parameter' ||
        selectedJob.value != 'Semua Pekerjaan';
  }

  // ===== WARNA =====
  Color getLabelColor(String label) {
    if (label.contains('Fokus terhadap Pewawancara') ||
        label.contains('Ramah dan Profesional') ||
        label.contains('Sikap Profesional')) {
      return const Color(0xFF10B981);
    }
    if (label.contains('Sesekali') ||
        label.contains('Cukup') ||
        label.contains('Sedikit')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFFEF4444);
  }

  Color getWpmColor(int wpm) {
    if (wpm >= 130 && wpm <= 160) return const Color(0xFF10B981);
    if (wpm >= 110 && wpm < 130) return const Color(0xFFF59E0B);
    if (wpm > 160 && wpm <= 180) return const Color(0xFFF59E0B);
    if (wpm > 180) return const Color(0xFFEF4444);
    return const Color(0xFFEF4444);
  }

  String getWpmRating(int wpm) {
    if (wpm >= 130 && wpm <= 160) return 'Ideal ✅';
    if (wpm >= 110 && wpm < 130) return 'Sedikit Lambat ⚠️';
    if (wpm > 160 && wpm <= 180) return 'Sedikit Cepat ⚠️';
    if (wpm > 180) return 'Terlalu Cepat ❌';
    return 'Terlalu Lambat ❌';
  }

  Color getFillerColor(int fillerCount) {
    if (fillerCount <= 2) return const Color(0xFF10B981);
    if (fillerCount <= 5) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String getLevelDisplayName(String level) {
    switch (level) {
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      case 'advance':
        return 'Advance';
      default:
        return level;
    }
  }

  void syncToDashboard() {}
}

class DailyStat {
  final DateTime date;
  final String dateKey;
  final int sessionCount;
  final String bestEye;
  final String bestSmile;
  final String bestPosture;
  final int points;

  DailyStat({
    required this.date,
    required this.dateKey,
    required this.sessionCount,
    required this.bestEye,
    required this.bestSmile,
    required this.bestPosture,
    required this.points,
  });

  String get dayName {
    switch (date.weekday) {
      case 1:
        return 'Sen';
      case 2:
        return 'Sel';
      case 3:
        return 'Rab';
      case 4:
        return 'Kam';
      case 5:
        return 'Jum';
      case 6:
        return 'Sab';
      case 7:
        return 'Min';
      default:
        return '';
    }
  }

  String get shortDate {
    return '${date.day}/${date.month}';
  }
}
