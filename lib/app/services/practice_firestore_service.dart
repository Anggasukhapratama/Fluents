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

  // ===== SAVE SESSION =====
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
      'scoreSmile': session.scoreSmile,
      'scoreEye': session.scoreEye,
      'scorePosture': session.scorePosture,
      'overallConfidence': session.overallConfidence,
      'overallLabel': session.overallLabel,
      'suggestions': session.suggestions,
      if (session.detectionResult != null)
        'detectionResult': session.detectionResult!.toMap(),
    }, SetOptions(merge: true));

    await _addPoints(uid, 5);

    await _addActivity(
      uid: uid,
      title: 'Latihan Interview ${session.difficulty}',
      route: '/narasi-practice/result',
      points: 5,
    );
  }

  // ✅ TAMBAHKAN METHOD INI
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamLastCorrection() {
    final uid = _uid;
    return _lastRef(uid).snapshots();
  }

  // ===== STREAM SESSIONS BY DATE RANGE =====
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

  // ===== STREAM LAST SESSION =====
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamLastSession() {
    final uid = _uid;
    return _lastRef(uid).snapshots();
  }

  // ===== GET ALL SESSIONS =====
  Future<List<PracticeSession>> getAllSessions({int limit = 50}) async {
    final uid = _uid;
    final snapshot = await _sessionsRef(
      uid,
    ).orderBy('createdAt', descending: true).limit(limit).get();

    return snapshot.docs.map((doc) {
      return PracticeSession.fromMap(doc.data());
    }).toList();
  }

  // ===== GET SESSIONS BY DIFFICULTY =====
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

  // ===== GET STATISTIK USER =====
  Future<Map<String, dynamic>> getUserStatistics() async {
    final uid = _uid;

    final sessionsSnapshot = await _sessionsRef(uid).get();
    final sessions = sessionsSnapshot.docs.map((doc) {
      return PracticeSession.fromMap(doc.data());
    }).toList();

    if (sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'averageConfidence': 0,
        'averageWpm': 0,
        'averageFluency': 0,
        'bestScore': 0,
        'totalPoints': 0,
      };
    }

    final totalSessions = sessions.length;
    final avgConfidence =
        sessions.map((s) => s.overallConfidence).reduce((a, b) => a + b) /
        totalSessions;
    final avgWpm =
        sessions.map((s) => s.wpm).reduce((a, b) => a + b) / totalSessions;
    final avgFluency =
        sessions.map((s) => s.fluency).reduce((a, b) => a + b) / totalSessions;
    final bestScore = sessions
        .map((s) => s.overallConfidence)
        .reduce((a, b) => a > b ? a : b);

    final userDoc = await _userRef(uid).get();
    final totalPoints = (userDoc.data()?['pointsTotal'] ?? 0) as int;

    return {
      'totalSessions': totalSessions,
      'averageConfidence': avgConfidence.round(),
      'averageWpm': avgWpm.round(),
      'averageFluency': avgFluency.round(),
      'bestScore': bestScore,
      'totalPoints': totalPoints,
    };
  }

  // ===== DELETE SESSION =====
  Future<void> deleteSession(String sessionId) async {
    final uid = _uid;
    await _sessionsRef(uid).doc(sessionId).delete();
  }

  // ===== PRIVATE METHODS =====
  Future<void> _addPoints(String uid, int points) async {
    try {
      final userRef = _userRef(uid);

      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);

        if (snapshot.exists) {
          final currentPoints = (snapshot.data()?['pointsTotal'] ?? 0) as int;
          final newPoints = currentPoints + points;

          transaction.update(userRef, {
            'pointsTotal': newPoints,
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
