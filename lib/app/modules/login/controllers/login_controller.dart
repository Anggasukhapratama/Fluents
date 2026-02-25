import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluent_ai/app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  // Text controllers
  final emailC = TextEditingController();
  final passC = TextEditingController();

  // UI states
  final isLoading = false.obs;
  final hidePass = true.obs;

  // Lockout states
  final isLocked = false.obs;
  final lockSecondsLeft = 0.obs;

  // prefs keys
  static const _kFailCount = 'login_fail_count';
  static const _kLockUntil = 'login_lock_until_ms';
  static const _kLockLevel = 'login_lock_level';

  // rules
  static const int _maxFailsBeforeLock = 3;
  static const int _baseLockSeconds = 30;
  static const int _maxLockSeconds = 600;

  Timer? _lockTimer;

  @override
  void onInit() {
    super.onInit();
    _resumeLockIfAny();
  }

  @override
  void onClose() {
    _lockTimer?.cancel();
    emailC.dispose();
    passC.dispose();
    super.onClose();
  }

  // ===== UI Actions =====
  void togglePass() => hidePass.value = !hidePass.value;

  void toRegister() => Get.offNamed(Routes.REGISTER);

  // ===== LOGIN FLOW =====
  Future<void> login() async {
    final locked = await _checkLockedAndStartTimer();
    if (locked) {
      Get.snackbar(
        'Tunggu',
        'Terlalu banyak percobaan. Coba lagi dalam ${lockSecondsLeft.value} detik.',
      );
      return;
    }

    final email = emailC.text.trim();
    final pass = passC.text;

    if (email.isEmpty || pass.isEmpty) {
      Get.snackbar('Gagal', 'Email & password wajib diisi');
      return;
    }

    try {
      isLoading.value = true;

      final cred = await _authService.loginEmail(email, pass);
      final user = cred.user;
      if (user == null) throw Exception('User null setelah login');

      await user.reload();
      final refreshed = _authService.currentUser;

      // ✅ Kalau belum verifikasi: jangan dihitung sebagai "password salah"
      if (refreshed != null && !refreshed.emailVerified) {
        // opsional: jangan signOut kalau kamu mau user tetap bisa ke VerifyEmail
        // tapi karena kamu maunya user login setelah verify, boleh signOut.
        await _authService.signOut();

        Get.snackbar(
          'Verifikasi Email',
          'Silakan verifikasi email dulu sebelum login.',
          mainButton: TextButton(
            onPressed: () => user.sendEmailVerification(),
            child: const Text('Kirim Ulang'),
          ),
        );
        return;
      }

      // sukses => reset security state
      await _resetSecurityState();

      Get.offAllNamed(Routes.DASHBOARD);
    } on FirebaseAuthException catch (e) {
      // ✅ hanya kredensial error yang dihitung fail
      final shouldCountAsFail = _isCredentialError(e.code);
      if (shouldCountAsFail) {
        await _onLoginFailed();
      }

      final msg = _mapAuthErrorToMessage(e);
      Get.snackbar('Login Gagal', msg);
    } catch (e) {
      // ✅ error non-auth (misal bug, format, dll) jangan bikin lockout
      Get.snackbar('Login Gagal', 'Terjadi kesalahan: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool _isCredentialError(String code) {
    return code == 'wrong-password' ||
        code == 'user-not-found' ||
        code == 'invalid-credential' ||
        code == 'invalid-email';
  }

  String _mapAuthErrorToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Password salah.';
      case 'user-not-found':
        return 'Akun tidak ditemukan.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'network-request-failed':
        return 'Koneksi bermasalah. Coba lagi.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba beberapa saat lagi.';
      default:
        return e.message ?? 'Login gagal (${e.code})';
    }
  }

  Future<void> forgotPassword() async {
    final email = emailC.text.trim();
    if (email.isEmpty) {
      Get.snackbar('Info', 'Isi email dulu untuk reset password');
      return;
    }

    try {
      await _authService.forgotPassword(email);
      Get.snackbar('Berhasil', 'Link reset password dikirim ke email');
    } catch (e) {
      Get.snackbar('Gagal', e.toString());
    }
  }

  Future<void> resendVerification() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        Get.snackbar(
          'Info',
          'Silakan login dulu agar bisa kirim ulang verifikasi',
        );
        return;
      }
      await user.sendEmailVerification();
      Get.snackbar('Berhasil', 'Link verifikasi baru dikirim ke email kamu.');
    } catch (e) {
      Get.snackbar('Gagal', 'Gagal mengirim email: $e');
    }
  }

  // ===== LOCKOUT LOGIC =====
  Future<void> _resumeLockIfAny() async {
    await _checkLockedAndStartTimer();
  }

  Future<bool> _checkLockedAndStartTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntil = prefs.getInt(_kLockUntil) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now < lockUntil) {
      final seconds = ((lockUntil - now) / 1000).ceil();
      _startCountdown(seconds);
      return true;
    }

    isLocked.value = false;
    lockSecondsLeft.value = 0;
    _lockTimer?.cancel();
    return false;
  }

  Future<void> _onLoginFailed() async {
    final prefs = await SharedPreferences.getInstance();

    final fails = (prefs.getInt(_kFailCount) ?? 0) + 1;
    await prefs.setInt(_kFailCount, fails);

    if (fails < _maxFailsBeforeLock) return;

    final level = (prefs.getInt(_kLockLevel) ?? 0) + 1;
    await prefs.setInt(_kLockLevel, level);

    final seconds = (_baseLockSeconds * (1 << (level - 1))).clamp(
      _baseLockSeconds,
      _maxLockSeconds,
    );

    final lockUntil = DateTime.now()
        .add(Duration(seconds: seconds))
        .millisecondsSinceEpoch;
    await prefs.setInt(_kLockUntil, lockUntil);

    await prefs.setInt(_kFailCount, 0);

    _startCountdown(seconds);
  }

  Future<void> loginGoogle() async {
    final locked = await _checkLockedAndStartTimer();
    if (locked) {
      Get.snackbar(
        'Tunggu',
        'Terlalu banyak percobaan. Coba lagi dalam ${lockSecondsLeft.value} detik.',
      );
      return;
    }

    try {
      isLoading.value = true;
      await _authService.loginGoogle();
      await _resetSecurityState();
      Get.offAllNamed(Routes.DASHBOARD);
    } catch (e) {
      final msg = e.toString().contains('dibatalkan')
          ? 'Login dibatalkan'
          : 'Gagal login Google: $e';
      Get.snackbar('Google Sign-In', msg);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _resetSecurityState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kFailCount, 0);
    await prefs.setInt(_kLockUntil, 0);
    await prefs.setInt(_kLockLevel, 0);

    isLocked.value = false;
    lockSecondsLeft.value = 0;
    _lockTimer?.cancel();
  }

  void _startCountdown(int seconds) {
    _lockTimer?.cancel();

    isLocked.value = true;
    lockSecondsLeft.value = seconds;

    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      lockSecondsLeft.value -= 1;
      if (lockSecondsLeft.value <= 0) {
        isLocked.value = false;
        lockSecondsLeft.value = 0;
        t.cancel();
      }
    });
  }
}
