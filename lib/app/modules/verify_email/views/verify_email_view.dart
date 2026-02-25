import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/verify_email_controller.dart';

class VerifyEmailView extends GetView<VerifyEmailController> {
  const VerifyEmailView({super.key});

  @override
  Widget build(BuildContext context) {
    final email = (Get.arguments is Map) ? (Get.arguments['email'] ?? '') : '';

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kami sudah mengirim link verifikasi ke:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              email.toString(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            const Text(
              'Silakan buka email, klik link verifikasi, lalu kembali ke aplikasi.',
            ),
            const SizedBox(height: 16),

            Obx(
              () => controller.isChecking.value
                  ? const Text('Mengecek status verifikasi...')
                  : const SizedBox.shrink(),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: controller.checkNow,
                child: const Text('Saya sudah verifikasi (Cek sekarang)'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: controller.resend,
                child: const Text('Kirim ulang link verifikasi'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: controller.backToLogin,
              child: const Text('Kembali ke Login'),
            ),
          ],
        ),
      ),
    );
  }
}
