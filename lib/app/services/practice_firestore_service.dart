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

  /// Simpan sesi latihan ke Firestore
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
      'eyeContactLabel': session.eyeContactLabel,
      'smileLabel': session.smileLabel,
      'postureLabel': session.postureLabel,
      'overallLabel': session.overallLabel,
      'confidenceMessage': session.confidenceMessage,
      'recognizedText': session.recognizedText,
      'suggestions': session.suggestions,
      if (session.detectionResult != null)
        'detectionResult': session.detectionResult!.toMap(),
    }, SetOptions(merge: true));

    await _addPoints(uid, 5);
    await _addActivity(
      uid: uid,
      title: 'Latihan Interview ${_getLevelName(session.difficulty)}',
      route: '/narasi-practice/result',
      points: 5,
    );
  }

  /// Stream untuk last session (untuk dashboard)
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamLastSession() {
    final uid = _uid;
    return _lastRef(uid).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamLastCorrection() {
    final uid = _uid;
    return _lastRef(uid).snapshots();
  }

  /// Stream sessions berdasarkan rentang tanggal
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

  /// Ambil semua sesi (max limit)
  Future<List<PracticeSession>> getAllSessions({int limit = 50}) async {
    final uid = _uid;
    final snapshot = await _sessionsRef(
      uid,
    ).orderBy('createdAt', descending: true).limit(limit).get();

    return snapshot.docs.map((doc) {
      return PracticeSession.fromMap(doc.data());
    }).toList();
  }

  /// Ambil sesi berdasarkan level
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

  /// Statistik user dengan sistem poin dan label baru
  Future<Map<String, dynamic>> getUserStatistics() async {
    final uid = _uid;
    final sessions = await getAllSessions();

    if (sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'bestLabel': 'Belum ada latihan',
        'latestAssessment': 'Mulai latihan pertama Anda!',
        'totalPoints': 0,
        'improvementNote': 'Semakin sering latihan, semakin baik performa Anda',
      };
    }

    final totalSessions = sessions.length;

    // Cari sesi terbaik berdasarkan overall label
    final bestSession = sessions.reduce((a, b) {
      final order = ['Siap Wawancara', 'Cukup Siap', 'Butuh Banyak Latihan'];
      return order.indexOf(a.overallLabel) < order.indexOf(b.overallLabel)
          ? a
          : b;
    });

    final latestSession = sessions.first;

    final userDoc = await _userRef(uid).get();
    final totalPoints = (userDoc.data()?['pointsTotal'] ?? 0) as int;

    return {
      'totalSessions': totalSessions,
      'bestLabel': bestSession.overallLabel,
      'bestConfidenceMessage': bestSession.confidenceMessage,
      'latestAssessment': latestSession.overallLabel,
      'latestConfidenceMessage': latestSession.confidenceMessage,
      'totalPoints': totalPoints,
      'improvementNote': _getImprovementNote(sessions),
    };
  }

  /// Hapus sesi
  Future<void> deleteSession(String sessionId) async {
    final uid = _uid;
    await _sessionsRef(uid).doc(sessionId).delete();
  }

  // ===== PRIVATE METHODS =====

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

  String _getImprovementNote(List<PracticeSession> sessions) {
    if (sessions.length < 2) return 'Terus latih kemampuan interview Anda!';

    // Bandingkan 2 sesi terakhir
    final latest = sessions.first;
    final previous = sessions[1];

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
