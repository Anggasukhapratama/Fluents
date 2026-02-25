import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/auth_widgets.dart';
import '../../../widgets/solid_button.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC), // abu muda
              Color(0xFFFFFFFF), // putih
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Header(),

                      const SizedBox(height: 18),

                      // ✅ GANTI Expanded -> Spacer manual aman untuk ScrollView
                      const SizedBox(height: 10),

                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: _LoginCard(controller: controller),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/logo.png', height: 42),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Fluent AI',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Interview Practice',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.controller});
  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      opacity: 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/illus_login.png',
            height: 90,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.login_rounded,
              size: 70,
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 10),

          const Text(
            'Login ke Akun Anda',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Masuk untuk mulai latihan wawancara',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 18),

          // Lock banner (Obx kecil)
          Obx(() {
            if (!controller.isLocked.value) return const SizedBox.shrink();
            return Column(
              children: [
                LockBanner(secondsLeft: controller.lockSecondsLeft.value),
                const SizedBox(height: 14),
              ],
            );
          }),

          // Email
          Obx(
            () => NiceField(
              controller: controller.emailC,
              label: 'Email',
              hint: 'contoh@mail.com',
              icon: Icons.email_outlined,
              enabled: !controller.isLocked.value,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 12),

          // Password
          Obx(
            () => NiceField(
              controller: controller.passC,
              label: 'Password',
              hint: 'Masukkan password',
              icon: Icons.lock_outline,
              enabled: !controller.isLocked.value,
              obscureText: controller.hidePass.value,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!controller.isLocked.value && !controller.isLoading.value) {
                  controller.login();
                }
              },
              suffix: IconButton(
                onPressed: controller.togglePass,
                icon: Icon(
                  controller.hidePass.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerRight,
            child: Obx(
              () => TextButton(
                onPressed: controller.isLocked.value
                    ? null
                    : controller.forgotPassword,
                child: const Text(
                  'Lupa password?',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Button Login
          Obx(
            () => SolidButton(
              text: 'Login',
              onPressed: controller.isLocked.value
                  ? null
                  : () => controller.login(),
              loading: controller.isLoading.value,
            ),
          ),
          const SizedBox(height: 12),

          Obx(
            () => OutlinedButton(
              onPressed: controller.isLoading.value || controller.isLocked.value
                  ? null
                  : controller.loginGoogle,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(color: Colors.grey.shade300),
                backgroundColor: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ICON GOOGLE (pakai built-in Material)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                    ),
                    child: const Icon(
                      Icons.g_mobiledata, // ikon Google
                      color: Colors.red,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Login dengan Google',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Belum punya akun? ',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => Get.offNamed(Routes.REGISTER),
                child: const Text(
                  'Daftar Sekarang',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
