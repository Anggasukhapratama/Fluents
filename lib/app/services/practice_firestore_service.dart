// lib/app/services/practice_firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/practice_session_model.dart';

class PracticeFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('User belum login');
    return u.uid;
  }

  CollectionReference<Map<String, dynamic>> _sessionsRef(String uid) =>
      _db.collection('users').doc(uid).collection('practice_sessions');

  DocumentReference<Map<String, dynamic>> _lastRef(String uid) =>
      _db.collection('users').doc(uid).collection('progress').doc('last');

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _activitiesRef(String uid) =>
      _db.collection('users').doc(uid).collection('activities');

  // ============================================================
  // SIMPAN SESI LATIHAN KE FIRESTORE
  // ============================================================
  Future<void> saveSession(PracticeSession session) async {
    final uid = _uid;

    await _sessionsRef(uid).add(session.toMap(uid));

    await _lastRef(uid).set({
      'uid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'dateKey': session.dateKey,
      'monthKey': session.monthKey,
      'difficulty': session.difficulty,
      'wpm': session.wpm,
      'fluency': session.fluency,
      'fillerCount': session.fillerCount,
      // ===== LABEL SESUAI HRD =====
      'eyeContactLabel': session.eyeContactLabel,
      'smileLabel': session.smileLabel,
      'postureLabel': session.postureLabel,
      // ===== ANALISIS DESKRIPTIF (TANPA OVERALL) =====
      'analysisResult': session.analysisResult,
      'recognizedText': session.recognizedText,
      'suggestions': session.suggestions,
      'jobTarget': session.jobTarget,
      if (session.detectionResult != null)
        'detectionResult': session.detectionResult!.toMap(),
    }, SetOptions(merge: true));

    await _addPoints(uid, 3);
    await _addActivity(
      uid: uid,
      title: 'Latihan Interview ${_getLevelName(session.difficulty)}',
      route: '/narasi-practice/result',
      points: 3,
    );
  }

  // ============================================================
  // STREAM LAST SESSION
  // ============================================================
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamLastSession() {
    final uid = _uid;
    return _lastRef(uid).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamLastCorrection() {
    final uid = _uid;
    return _lastRef(uid).snapshots();
  }

  // ============================================================
  // STREAM SESSIONS BERDASARKAN TANGGAL
  // ============================================================
  Stream<QuerySnapshot<Map<String, dynamic>>> streamSessionsByDateKeyRange({
    required String startDateKey,
    required String endDateKey,
  }) {
    final uid = _uid;
    return _sessionsRef(uid)
        .where('dateKey', isGreaterThanOrEqualTo: startDateKey)
        .where('dateKey', isLessThanOrEqualTo: endDateKey)
        .orderBy('dateKey', descending: true)
        .snapshots();
  }

  // ============================================================
  // AMBIL SEMUA SESI
  // ============================================================
  Future<List<PracticeSession>> getAllSessions({int limit = 50}) async {
    final uid = _uid;
    final snapshot = await _sessionsRef(
      uid,
    ).orderBy('createdAt', descending: true).limit(limit).get();

    return snapshot.docs.map((doc) {
      return PracticeSession.fromMap(doc.data());
    }).toList();
  }

  // ============================================================
  // AMBIL SESI BERDASARKAN LEVEL
  // ============================================================
  Future<List<PracticeSession>> getSessionsByDifficulty(
    String difficulty,
  ) async {
    final uid = _uid;
    final snapshot = await _sessionsRef(uid)
        .where('difficulty', isEqualTo: difficulty)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return PracticeSession.fromMap(doc.data());
    }).toList();
  }

  // ============================================================
  // STATISTIK USER - TANPA OVERALL LABEL
  // ============================================================
  Future<Map<String, dynamic>> getUserStatistics() async {
    final uid = _uid;
    final sessions = await getAllSessions();

    if (sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'bestPerformance': 'Belum ada latihan',
        'latestAnalysis': 'Mulai latihan pertama Anda!',
        'totalPoints': 0,
        'improvementNote': 'Semakin sering latihan, semakin baik performa Anda',
      };
    }

    final totalSessions = sessions.length;

    // ===== CARI SESI TERBAIK BERDASARKAN TOTAL POIN =====
    final bestSession = sessions.reduce((a, b) {
      return a.totalPoints > b.totalPoints ? a : b;
    });

    final latestSession = sessions.first;

    final userDoc = await _userRef(uid).get();
    final totalPoints = (userDoc.data()?['pointsTotal'] ?? 0) as int;

    return {
      'totalSessions': totalSessions,
      'bestPerformance': bestSession.performanceStatus,
      'bestAnalysis': bestSession.analysisResult.isNotEmpty
          ? bestSession.analysisResult.substring(0, 100) + '...'
          : 'Analisis belum tersedia',
      'latestAnalysis': latestSession.analysisResult.isNotEmpty
          ? latestSession.analysisResult.substring(0, 100) + '...'
          : 'Analisis belum tersedia',
      'latestStatus': latestSession.performanceStatus,
      'totalPoints': totalPoints,
      'improvementNote': _getImprovementNote(sessions),
      // Detail per parameter dari sesi terbaik
      'bestEyeContact': bestSession.eyeContactLabel,
      'bestSmile': bestSession.smileLabel,
      'bestPosture': bestSession.postureLabel,
      'bestTotalPoints': bestSession.totalPoints,
    };
  }

  // ============================================================
  // HAPUS SESI
  // ============================================================
  Future<void> deleteSession(String sessionId) async {
    final uid = _uid;
    await _sessionsRef(uid).doc(sessionId).delete();
  }

  // ============================================================
  // PRIVATE METHODS
  // ============================================================

  String _getLevelName(String difficulty) {
    switch (difficulty) {
      case 'medium':
        return 'Menengah';
      case 'hard':
        return 'Sulit';
      case 'advance':
        return 'Profesional';
      default:
        return difficulty;
    }
  }

  /// Mendapatkan catatan peningkatan berdasarkan total poin
  String _getImprovementNote(List<PracticeSession> sessions) {
    if (sessions.length < 2) return 'Terus latih kemampuan interview Anda!';

    // Bandingkan 2 sesi terakhir berdasarkan total poin
    final latest = sessions.first;
    final previous = sessions[1];

    if (latest.totalPoints > previous.totalPoints) {
      return '🎉 Selamat! Performa Anda meningkat dibanding latihan sebelumnya!';
    } else if (latest.totalPoints < previous.totalPoints) {
      return '📈 Terus semangat! Setiap latihan membawa Anda lebih dekat ke sukses.';
    } else {
      return '💪 Konsistensi adalah kunci. Pertahankan semangat latihan Anda!';
    }
  }

  Future<void> _addPoints(String uid, int points) async {
    try {
      final userRef = _userRef(uid);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (snapshot.exists) {
          final currentPoints = (snapshot.data()?['pointsTotal'] ?? 0) as int;
          transaction.update(userRef, {
            'pointsTotal': currentPoints + points,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final user = _auth.currentUser;
          transaction.set(userRef, {
            'pointsTotal': points,
            'email': user?.email,
            'username': user?.displayName ?? 'User',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('❌ Gagal menambah poin: $e');
    }
  }

  Future<void> _addActivity({
    required String uid,
    required String title,
    required String route,
    required int points,
  }) async {
    try {
      await _activitiesRef(uid).add({
        'title': title,
        'route': route,
        'points': points,
        'at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Gagal menambah activity: $e');
    }
  }
}
