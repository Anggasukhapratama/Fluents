import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HrdFirestoreService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('User belum login');
    return u.uid;
  }

  CollectionReference<Map<String, dynamic>> _sessionsRef(String uid) =>
      _db.collection('users').doc(uid).collection('hrd_sessions');

  /// ✅ Ringkasan terakhir HRD disimpan di:
  /// users/{uid}/progress/hrd_last
  DocumentReference<Map<String, dynamic>> _lastRef(String uid) =>
      _db.collection('users').doc(uid).collection('progress').doc('hrd_last');

  /// ✅ Save 1 sesi HRD (untuk chart) + update ringkasan terakhir (untuk card progress)
  Future<void> saveSession({
    required DateTime createdAt,
    required String dateKey,
    required String monthKey,
    required String weekKey,
    required int score,
    required int points,
    required List<int> scores,
    required List<int> hits,
    required List<String> answers,
    required List<Map<String, dynamic>> details, // optional detail per Q
    required List<String> feedback, // ✅ ini yang dipakai ProgressView
  }) async {
    final uid = _uid;

    final payload = <String, dynamic>{
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'dateKey': dateKey,
      'monthKey': monthKey,
      'weekKey': weekKey,

      'score': score,
      'points': points,

      // detail raw
      'scores': scores,
      'hits': hits,
      'answers': answers,
      'details': details,

      // ✅ feedback coach HRD
      'feedback': feedback,
    };

    // simpan sesi list (buat chart)
    await _sessionsRef(uid).add(payload);

    // simpan ringkasan terakhir (buat card progress)
    await _lastRef(uid).set(payload, SetOptions(merge: true));
  }

  /// query harian (buat chart)
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

  /// ambil “ringkasan terakhir” HRD
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamLastCorrection() {
    final uid = _uid;
    return _lastRef(uid).snapshots();
  }
}
