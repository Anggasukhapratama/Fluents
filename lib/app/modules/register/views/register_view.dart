import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/register_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/auth_widgets.dart';
import '../../../widgets/solid_button.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
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
                      _Header(onBack: () => Get.offNamed(Routes.LOGIN)),
                      const SizedBox(height: 18),

                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: _RegisterCard(controller: controller),
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
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
        ),
        const SizedBox(width: 6),
        Image.asset('assets/logo.png', height: 36),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Fluent AI',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Interview Practice',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 10,
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

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({required this.controller});
  final RegisterController controller;

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      opacity: 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/illus_register.png',
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.person_add_alt_1_rounded,
              size: 64,
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 10),

          const Text(
            'Buat Akun Baru',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Bergabung dengan Fluent AI',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 18),

          NiceField(
            controller: controller.usernameC,
            label: 'Username',
            hint: 'Masukkan username',
            icon: Icons.person_outline,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          NiceField(
            controller: controller.emailC,
            label: 'Email',
            hint: 'contoh@mail.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          Obx(
            () => NiceField(
              controller: controller.passC,
              label: 'Password',
              hint: 'Minimal 6 karakter',
              icon: Icons.lock_outline,
              obscureText: controller.hidePass.value,
              textInputAction: TextInputAction.next,
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
          const SizedBox(height: 12),

          Obx(
            () => NiceField(
              controller: controller.confirmC,
              label: 'Konfirmasi Password',
              hint: 'Ulangi password',
              icon: Icons.verified_outlined,
              obscureText: controller.hideConfirm.value,
              textInputAction: TextInputAction.next,
              suffix: IconButton(
                onPressed: controller.toggleConfirm,
                icon: Icon(
                  controller.hideConfirm.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          _GenderDropdown(controller: controller),
          const SizedBox(height: 12),

          NiceField(
            controller: controller.desiredJobC,
            label: 'Pekerjaan Sekarang',
            hint: 'Contoh: Software Engineer',
            icon: Icons.work_outline,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 18),

          Obx(
            () => SolidButton(
              text: 'Daftar Sekarang',
              onPressed: controller.register,
              loading: controller.isLoading.value,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sudah punya akun? ',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              GestureDetector(
                onTap: () => Get.offNamed(Routes.LOGIN),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
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

class _GenderDropdown extends StatelessWidget {
  const _GenderDropdown({required this.controller});
  final RegisterController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Kelamin',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Obx(
          () => DropdownButtonFormField<String>(
            value: controller.gender.value.isEmpty
                ? null
                : controller.gender.value,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintText: 'Pilih jenis kelamin',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFD32F2F),
                  width: 1.5,
                ),
              ),
              prefixIcon: Icon(
                Icons.person_outline,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
            items: controller.genders
                .map(
                  (g) => DropdownMenuItem(
                    value: g,
                    child: Text(
                      g,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => controller.gender.value = v ?? '',
            icon: Icon(
              Icons.arrow_drop_down_rounded,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}
