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

  Future<void> saveSession(PracticeSession session) async {
    final uid = _uid;

    // Simpan session
    await _sessionsRef(uid).add(session.toMap(uid));

    // Update last correction
    await _lastRef(uid).set({
      'uid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'dateKey': session.dateKey,
      'monthKey': session.monthKey,
      'difficulty': session.difficulty,
      'wpm': session.wpm,
      'fluency': session.fluency,
      'fillerCount': session.fillerCount,
      'scoreMouth': session.scoreMouth,
      'scoreTilt': session.scoreTilt,
      'scorePosture': session.scorePosture,
      'nervousScore': session.nervousScore,
      'nervousLabel': session.nervousLabel,
      'suggestions': session.suggestions,
    }, SetOptions(merge: true));

    // ✅ TAMBAHKAN 5 POIN KE DOKUMEN USER
    await _addPoints(uid, 5);

    // ✅ TAMBAHKAN ACTIVITY KE COLLECTION activities
    await _addActivity(
      uid: uid,
      title: 'Latihan Narasi',
      route: '/narasi-practice/result', // Sesuaikan dengan route di app Anda
      points: 5,
    );
  }

  // ✅ METHOD UNTUK MENAMBAH POIN
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

      print('✅ Berhasil menambah $points poin untuk user $uid');
    } catch (e) {
      print('❌ Gagal menambah poin: $e');
    }
  }

  // ✅ METHOD BARU UNTUK MENAMBAH ACTIVITY
  Future<void> _addActivity({
    required String uid,
    required String title,
    required String route,
    required int points,
  }) async {
    try {
      final activitiesRef = _activitiesRef(uid);

      await activitiesRef.add({
        'title': title,
        'route': route,
        'points': points,
        'at': FieldValue.serverTimestamp(),
      });

      print('✅ Activity berhasil ditambahkan: $title');
    } catch (e) {
      print('❌ Gagal menambah activity: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSessionsByDateKeyRange({
    required String startDateKey,
    required String endDateKey,
  }) {
    final uid = _uid;
    return _sessionsRef(uid)
        .where('dateKey', isGreaterThanOrEqualTo: startDateKey)
        .where('dateKey', isLessThanOrEqualTo: endDateKey)
        .orderBy('dateKey')
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamLastCorrection() {
    final uid = _uid;
    return _lastRef(uid).snapshots();
  }
}
