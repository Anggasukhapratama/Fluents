import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';

class VerifyEmailController extends GetxController {
  final auth = FirebaseAuth.instance;

  final isChecking = false.obs;
  final isVerified = false.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _startAutoCheck();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _startAutoCheck() {
    // cek tiap 3 detik
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => checkNow());
  }

  Future<void> resend() async {
    final user = auth.currentUser;
    if (user == null) {
      Get.snackbar('Info', 'Silakan login dulu untuk kirim ulang verifikasi');
      return;
    }
    await user.sendEmailVerification();
    Get.snackbar('Berhasil', 'Link verifikasi dikirim ulang (cek inbox/spam)');
  }

  Future<void> checkNow() async {
    final user = auth.currentUser;
    if (user == null) return;

    try {
      isChecking.value = true;
      await user.reload();
      final refreshed = auth.currentUser;

      if (refreshed != null && refreshed.emailVerified) {
        isVerified.value = true;
        _timer?.cancel();

        // setelah verified: logout biar user login ulang (sesuai request kamu)
        await auth.signOut();
        Get.offAllNamed(Routes.LOGIN);
        Get.snackbar('Sukses', 'Email terverifikasi. Silakan login.');
      }
    } finally {
      isChecking.value = false;
    }
  }

  Future<void> backToLogin() async {
    await auth.signOut();
    Get.offAllNamed(Routes.LOGIN);
  }
}
