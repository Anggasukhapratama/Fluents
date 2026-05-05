// lib/app/modules/progress/controllers/progress_controller.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/practice_firestore_service.dart';
import '../../../models/practice_session_model.dart';

class ProgressController extends GetxController {
  final PracticeFirestoreService _firestoreService = PracticeFirestoreService();

  // State observables
  final isLoading = false.obs;
  final totalSessions = 0.obs;
  final totalPoints = 0.obs;
  final bestLabel = ''.obs;
  final latestLabel = ''.obs;
  final improvementNote = ''.obs;

  // List sesi latihan
  final sessions = <PracticeSession>[].obs;

  // Data untuk chart harian (7 hari terakhir)
  final dailyStats = <DailyStat>[].obs;

  // Filter level
  final selectedLevelFilter = 'semua'.obs;
  final List<String> levelFilters = ['semua', 'medium', 'hard', 'advance'];

  // Stream subscriptions
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

  // ==================== REALTIME LISTENERS ====================

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
            print('❌ Error loading sessions: $e');
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

  // ==================== UPDATE STATS FROM SESSIONS ====================

  void _updateStatsFromSessions(List<PracticeSession> sessionList) {
    totalSessions.value = sessionList.length;

    if (sessionList.isEmpty) {
      bestLabel.value = 'Belum ada latihan';
      improvementNote.value = '💪 Mulai latihan pertama Anda!';
      return;
    }

    // Cari best label (terbaik: Siap Wawancara > Cukup Siap > Butuh Banyak Latihan)
    String best = 'Butuh Banyak Latihan';
    for (var session in sessionList) {
      if (_isBetterLabel(session.overallLabel, best)) {
        best = session.overallLabel;
      }
    }
    bestLabel.value = best;

    // Generate improvement note
    improvementNote.value = _getImprovementNote(sessionList);

    // Hitung total poin dari user document
    _loadUserPoints();
  }

  bool _isBetterLabel(String newLabel, String currentBest) {
    final order = ['Siap Wawancara', 'Cukup Siap', 'Butuh Banyak Latihan'];
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

    // Bandingkan 2 sesi terakhir
    final latest = sessionList.first;
    final previous = sessionList[1];

    final order = ['Siap Wawancara', 'Cukup Siap', 'Butuh Banyak Latihan'];
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
      print('❌ Error loading user points: $e');
    }
  }

  // ==================== LOAD DATA ====================

  Future<void> _loadAllData() async {
    isLoading.value = true;

    try {
      // Ambil semua sesi
      final allSessions = await _firestoreService.getAllSessions(limit: 100);
      sessions.assignAll(allSessions);
      _updateStatsFromSessions(allSessions);

      // Generate data untuk chart harian
      _generateDailyStats();
    } catch (e) {
      print('❌ Error loading progress: $e');
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

      // Hitung label terbaik hari itu
      String bestLabelForDay = 'Tidak ada latihan';
      for (var session in daySessions) {
        if (_isBetterLabel(session.overallLabel, bestLabelForDay)) {
          bestLabelForDay = session.overallLabel;
        }
      }

      dailyStats.add(
        DailyStat(
          date: date,
          dateKey: dateKey,
          sessionCount: daySessions.length,
          bestLabel: bestLabelForDay,
          points: _labelToPoints(bestLabelForDay),
        ),
      );
    }
  }

  int _labelToPoints(String label) {
    switch (label) {
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

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ==================== PUBLIC METHODS ====================

  Future<void> refreshData() async {
    await _loadAllData();
  }

  void filterByLevel(String level) {
    selectedLevelFilter.value = level;
  }

  List<PracticeSession> getFilteredSessions() {
    if (selectedLevelFilter.value == 'semua') {
      return sessions;
    }
    return sessions
        .where((s) => s.difficulty == selectedLevelFilter.value)
        .toList();
  }

  Color getLabelColor(String label) {
    switch (label) {
      case 'Siap Wawancara':
        return const Color(0xFF10B981); // Hijau
      case 'Cukup Siap':
        return const Color(0xFFF59E0B); // Oranye
      case 'Butuh Banyak Latihan':
        return const Color(0xFFEF4444); // Merah
      default:
        return const Color(0xFF6B7280); // Abu
    }
  }

  String getLevelDisplayName(String level) {
    switch (level) {
      case 'medium':
        return 'Menengah';
      case 'hard':
        return 'Mahir';
      case 'advance':
        return 'Profesional';
      default:
        return level;
    }
  }

  // Untuk DashboardController sync
  void syncToDashboard() {
    // Method ini akan dipanggil oleh DashboardController
    // Data sudah otomatis sync melalui Rx variables
  }
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
