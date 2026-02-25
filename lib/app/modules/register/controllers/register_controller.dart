import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../services/auth_service.dart';

class RegisterController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final usernameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final confirmC = TextEditingController();
  final desiredJobC = TextEditingController();

  final gender = ''.obs;
  final genders = const ['Laki-laki', 'Perempuan', 'Lainnya'];

  final isLoading = false.obs;
  final hidePass = true.obs;
  final hideConfirm = true.obs;

  void togglePass() => hidePass.value = !hidePass.value;
  void toggleConfirm() => hideConfirm.value = !hideConfirm.value;

  @override
  void onClose() {
    usernameC.dispose();
    emailC.dispose();
    passC.dispose();
    confirmC.dispose();
    desiredJobC.dispose();
    super.onClose();
  }

  Future<void> register() async {
    final username = usernameC.text.trim();
    final email = emailC.text.trim();
    final pass = passC.text;
    final confirm = confirmC.text;
    final g = gender.value;
    final desired = desiredJobC.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        pass.isEmpty ||
        confirm.isEmpty ||
        g.isEmpty ||
        desired.isEmpty) {
      Get.snackbar('Gagal', 'Semua field wajib diisi');
      return;
    }
    if (pass != confirm) {
      Get.snackbar('Gagal', 'Password dan konfirmasi tidak sama');
      return;
    }
    if (pass.length < 6) {
      Get.snackbar('Gagal', 'Password minimal 6 karakter');
      return;
    }

    try {
      isLoading.value = true;

      final cred = await _authService.registerEmail(
        username: username,
        email: email,
        password: pass,
        gender: g,
        desiredJob: desired,
      );

      final user = cred.user!;
      await user.sendEmailVerification();

      await _authService.signOut();

      Get.offAllNamed(Routes.LOGIN);
      Get.snackbar(
        'Berhasil',
        'Link verifikasi sudah dikirim ke email. Silakan verifikasi lalu login.',
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Register gagal', e.message ?? e.code);
    } catch (e) {
      Get.snackbar('Register gagal', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
