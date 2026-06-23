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
  final bestLabel = ''.obs;
  final latestLabel = ''.obs;
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

  // ===== FILTER STATUS =====
  final selectedStatus = 'Semua Status'.obs;
  final List<String> statusOptions = [
    'Semua Status',
    'Sangat Percaya Diri',
    'Siap Wawancara',
    'Cukup Baik',
    'Perlu Banyak Latihan',
  ];

  // ===== DATA UNTUK LINE CHART =====
  final performanceTrend = <double>[].obs;
  final trendLabels = <String>[].obs;
  final trendColors = <Color>[].obs;

  // ===== LIMIT DEFAULT =====
  final int defaultLimit = 5;

  final statusCounts = <String, int>{}.obs;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _lastSessionSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionsSub;

  @override
  void onInit() {
    super.onInit();
    _loadAllData();
    _listenToRealtimeSessions();
    _listenToLastSession();
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

  void _listenToLastSession() {
    _lastSessionSub = _firestoreService.streamLastSession().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          latestLabel.value = data['overallLabel'] ?? 'Belum ada latihan';
        }
      }
    });
  }

  void _updateStatsFromSessions(List<PracticeSession> sessionList) {
    totalSessions.value = sessionList.length;

    if (sessionList.isEmpty) {
      bestLabel.value = 'Belum ada latihan';
      improvementNote.value = '💪 Mulai latihan pertama Anda!';
      _updateStatusCounts(sessionList);
      _generatePerformanceTrend();
      return;
    }

    String best = 'Perlu Banyak Latihan';
    for (var session in sessionList) {
      if (_isBetterLabel(session.overallLabel, best)) {
        best = session.overallLabel;
      }
    }
    bestLabel.value = best;

    improvementNote.value = _getImprovementNote(sessionList);
    _updateStatusCounts(sessionList);
    _loadUserPoints();
    _generatePerformanceTrend();
  }

  void _updateStatusCounts(List<PracticeSession> sessionList) {
    final Map<String, int> counts = {
      'Sangat Percaya Diri': 0,
      'Siap Wawancara': 0,
      'Cukup Baik': 0,
      'Perlu Banyak Latihan': 0,
    };

    for (var session in sessionList) {
      if (counts.containsKey(session.overallLabel)) {
        counts[session.overallLabel] = counts[session.overallLabel]! + 1;
      }
    }

    statusCounts.value = counts;
  }

  bool _isBetterLabel(String newLabel, String currentBest) {
    final order = ['Sangat Percaya Diri', 'Siap Wawancara', 'Cukup Baik', 'Perlu Banyak Latihan'];
    final newIndex = order.indexOf(newLabel);
    final currentIndex = order.indexOf(currentBest);
    if (currentBest.isEmpty) return true;
    if (newIndex == -1) return false;
    if (currentIndex == -1) return true;
    return newIndex < currentIndex;
  }

  String _getImprovementNote(List<PracticeSession> sessionList) {
    if (sessionList.length < 2) {
      return '💪 Terus semangat! Setiap latihan membawa Anda lebih dekat ke sukses.';
    }

    final latest = sessionList.first;
    final previous = sessionList[1];

    final order = ['Sangat Percaya Diri', 'Siap Wawancara', 'Cukup Baik', 'Perlu Banyak Latihan'];
    final latestIdx = order.indexOf(latest.overallLabel);
    final prevIdx = order.indexOf(previous.overallLabel);

    if (latestIdx < prevIdx) {
      return '🎉 Selamat! Performa Anda meningkat dibanding latihan sebelumnya!';
    } else if (latestIdx > prevIdx) {
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

      String bestLabelForDay = 'Tidak ada latihan';
      int maxPoints = 0;

      for (var session in daySessions) {
        int points = _labelToPoints(session.overallLabel);
        if (points > maxPoints) {
          maxPoints = points;
          bestLabelForDay = session.overallLabel;
        }
      }

      dailyStats.add(
        DailyStat(
          date: date,
          dateKey: dateKey,
          sessionCount: daySessions.length,
          bestLabel: bestLabelForDay,
          points: maxPoints,
        ),
      );
    }
  }

  void _generatePerformanceTrend() {
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) {
      return DateTime(now.year, now.month, now.day - i);
    }).reversed.toList();

    performanceTrend.clear();
    trendLabels.clear();
    trendColors.clear();

    final labelPoints = {
      'Sangat Percaya Diri': 4,
      'Siap Wawancara': 3,
      'Cukup Baik': 2,
      'Perlu Banyak Latihan': 1,
    };

    for (var date in last7Days) {
      final dateKey = _formatDateKey(date);
      final daySessions = sessions.where((s) => s.dateKey == dateKey).toList();

      String bestLabel = 'Tidak ada latihan';
      int bestPoints = 0;
      for (var session in daySessions) {
        int points = labelPoints[session.overallLabel] ?? 0;
        if (points > bestPoints) {
          bestPoints = points;
          bestLabel = session.overallLabel;
        }
      }

      if (bestLabel == 'Tidak ada latihan') {
        performanceTrend.add(0);
        trendLabels.add(_getShortDayName(date.weekday));
        trendColors.add(Colors.grey.withOpacity(0.3));
      } else {
        performanceTrend.add(bestPoints.toDouble());
        trendLabels.add(_getShortDayName(date.weekday));
        trendColors.add(getLabelColor(bestLabel));
      }
    }
  }

  String _getShortDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Sen';
      case 2: return 'Sel';
      case 3: return 'Rab';
      case 4: return 'Kam';
      case 5: return 'Jum';
      case 6: return 'Sab';
      case 7: return 'Min';
      default: return '';
    }
  }

  int _labelToPoints(String label) {
    switch (label) {
      case 'Sangat Percaya Diri':
        return 4;
      case 'Siap Wawancara':
        return 3;
      case 'Cukup Baik':
        return 2;
      case 'Perlu Banyak Latihan':
        return 1;
      default:
        return 0;
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

  void setStatus(String status) {
    selectedStatus.value = status;
  }

  void resetAllFilters() {
    selectedLevel.value = 'Semua Level';
    selectedStatus.value = 'Semua Status';
  }

  // ===== GET FILTERED SESSIONS =====
  List<PracticeSession> getFilteredSessions() {
    var filtered = sessions.toList();

    // 1. Filter Level
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

    // 2. Filter Status
    if (selectedStatus.value != 'Semua Status') {
      filtered = filtered
          .where((s) => s.overallLabel == selectedStatus.value)
          .toList();
    }

    // 3. Limit 5 (default)
    if (filtered.length > defaultLimit) {
      filtered = filtered.sublist(0, defaultLimit);
    }

    return filtered;
  }

  List<PracticeSession> getSessionsForStatusFilter() {
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

    return filtered;
  }

  bool get hasActiveFilter {
    return selectedLevel.value != 'Semua Level' ||
           selectedStatus.value != 'Semua Status';
  }

  // ===== WARNA =====
  Color getLabelColor(String label) {
    switch (label) {
      case 'Sangat Percaya Diri':
        return const Color(0xFF059669);
      case 'Siap Wawancara':
        return const Color(0xFF10B981);
      case 'Cukup Baik':
        return const Color(0xFFF59E0B);
      case 'Perlu Banyak Latihan':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
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
  final String bestLabel;
  final int points;

  DailyStat({
    required this.date,
    required this.dateKey,
    required this.sessionCount,
    required this.bestLabel,
    required this.points,
  });

  String get dayName {
    switch (date.weekday) {
      case 1: return 'Sen';
      case 2: return 'Sel';
      case 3: return 'Rab';
      case 4: return 'Kam';
      case 5: return 'Jum';
      case 6: return 'Sab';
      case 7: return 'Min';
      default: return '';
    }
  }

  String get shortDate {
    return '${date.day}/${date.month}';
  }
}