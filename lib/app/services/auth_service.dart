import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // ===================== EMAIL LOGIN =====================
  Future<UserCredential> loginEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      // ✅ SIMPAN RIWAYAT LOGIN EMAIL
      await _db.collection('login_history').add({
        'uid': user.uid,
        'method': 'email',
        'platform': kIsWeb ? 'web' : 'mobile',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // update last login
      await _db.collection('users').doc(user.uid).set({
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return cred;
  }

  // ===================== EMAIL REGISTER =====================
  Future<UserCredential> registerEmail({
    required String username,
    required String email,
    required String password,
    required String gender,
    required String desiredJob,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) throw Exception('User null setelah register');

    await user.updateDisplayName(username);

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'username': username,
      'email': email,
      'gender': gender,
      'desiredJob': desiredJob,
      'provider': 'email',
      'pointsTotal': 0, // Inisialisasi poin agar muncul di leaderboard
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ✅ CATAT LOGIN PERTAMA SETELAH REGISTER
    await _db.collection('login_history').add({
      'uid': user.uid,
      'method': 'email_register',
      'platform': kIsWeb ? 'web' : 'mobile',
      'timestamp': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  // ===================== GOOGLE LOGIN (WEB + MOBILE) =====================
  Future<UserCredential> loginGoogle() async {
    final googleSignIn = GoogleSignIn(
      clientId: kIsWeb
          ? '972659297586-lq731loutcr9cm1dsj4dhmc284jr5k1p.apps.googleusercontent.com'
          : null,
      scopes: const ['email'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Login Google dibatalkan');
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(credential);
    final user = userCred.user;
    if (user == null) throw Exception('User null setelah login Google');

    // simpan/update user
    final userDocRef = _db.collection('users').doc(user.uid);
    final userDocSnap = await userDocRef.get();
    final isNewUser = !userDocSnap.exists;

    await userDocRef.set({
      'uid': user.uid,
      'username': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
      'provider': 'google',
      'lastLoginAt': FieldValue.serverTimestamp(),
      // pointsTotal hanya di-set kalau user baru, biar tidak overwrite poin existing
      if (isNewUser) 'pointsTotal': 0,
      if (isNewUser) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ✅ SIMPAN RIWAYAT LOGIN GOOGLE
    await _db.collection('login_history').add({
      'uid': user.uid,
      'method': 'google',
      'platform': kIsWeb ? 'web' : 'mobile',
      'timestamp': FieldValue.serverTimestamp(),
    });

    return userCred;
  }

  // ===================== FORGOT PASSWORD =====================
  Future<void> forgotPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  // ===================== SIGN OUT =====================
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    await _auth.signOut();
  }
}
