// lib/app/views/narasi_practice_view.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/narasi_practice_controller.dart';

class NarasiPracticeView extends GetView<NarasiPracticeController> {
  const NarasiPracticeView({super.key});

  static const Color _bg = Color(0xFFF0F4F8);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _primaryDark = Color(0xFF0A2540);
  static const Color _primaryGold = Color(0xFFD4AF37);
  static const Color _primaryBlue = Color(0xFF1A73E8);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Obx(() {
          switch (controller.step.value) {
            case PracticeStep.instructions:
              return _instructionsView(context);
            case PracticeStep.choose:
              return _chooseLevel(context);
            case PracticeStep.countdown:
              return _countdown(context);
            case PracticeStep.practice:
              return _practice(context);
            case PracticeStep.result:
              return _result(context);
          }
        }),
      ),
    );
  }

  Widget _instructionsView(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryDark,
            const Color(0xFF1E3A5F),
            const Color(0xFF0D2B45),
          ],
        ),
      ),
      child: Column(
        children: [
          _headerModern(
            title: 'Panduan Latihan',
            subtitle: 'Ikuti langkah berikut untuk hasil terbaik',
            showBack: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _welcomeCard(),
                  const SizedBox(height: 20),
                  _instructionCardModern(
                    number: '01',
                    icon: Icons.face_retouching_natural,
                    title: 'Posisikan Wajah',
                    desc:
                        'Pastikan wajah terlihat jelas di kamera dan berada di area tengah. AI akan mendeteksi kontak mata dan ekspresi Anda.',
                    color: _primaryBlue,
                  ),
                  const SizedBox(height: 16),
                  _instructionCardModern(
                    number: '02',
                    icon: Icons.accessibility_new,
                    title: 'Jaga Postur Tubuh',
                    desc:
                        'Duduklah dengan tegak dan rileks. AI akan menilai postur tubuh Anda selama wawancara berlangsung.',
                    color: _primaryGold,
                  ),
                  const SizedBox(height: 16),
                  _instructionCardModern(
                    number: '03',
                    icon: Icons.record_voice_over,
                    title: 'Bicara dengan Percaya Diri',
                    desc:
                        'Gunakan suara yang jelas. AI akan menganalisis kecepatan bicara dan kata pengisi seperti "umm" atau "anu".',
                    color: _success,
                  ),
                  const SizedBox(height: 16),
                  _instructionCardModern(
                    number: '04',
                    icon: Icons.insights,
                    title: 'Dapatkan Feedback AI',
                    desc:
                        'Setelah menyelesaikan semua pertanyaan, Anda akan mendapatkan analisis lengkap dan rekomendasi dari AI.',
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 30),
                  _gradientButton(
                    onPressed: controller.startToChoose,
                    text: 'MULAI LATIHAN SEKARANG',
                    icon: Icons.arrow_forward_rounded,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryGold.withOpacity(0.2),
            _primaryGold.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _primaryGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryGold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: _primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Siap menjadi lebih percaya diri?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Latihan ini akan membantumu menghadapi wawancara sesungguhnya',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionCardModern({
    required String number,
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.6)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryGold, Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryGold.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: _primaryDark, size: 20),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1,
            color: _primaryDark,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: _primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _headerModern({
    required String title,
    required String subtitle,
    bool showBack = false,
    List<Widget> actions = const [],
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          if (showBack)
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: () {
                  print("🔙 Tombol back ditekan");
                  controller.backToChoose();
                },
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                color: Colors.white,
                padding: const EdgeInsets.all(8), // ✅ Tambahkan padding
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ), // ✅ Ubah constraints
                iconSize: 18,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          ...actions,
        ],
      ),
    );
  }

  Widget _chooseLevel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryDark,
            const Color(0xFF1E3A5F),
            const Color(0xFF0D2B45),
          ],
        ),
      ),
      child: Column(
        children: [
          _headerModern(
            title: 'Pilih Level Kesulitan',
            subtitle: 'Sesuaikan dengan target karirmu',
            showBack: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _levelCardModern(
                    level: 'Pemula',
                    levelEn: 'Medium',
                    description:
                        'Cocok untuk pemula yang baru belajar interview',
                    details: '5 Pertanyaan • 20 detik/jawaban',
                    icon: Icons.sentiment_satisfied_alt,
                    color: _success,
                    gradientColors: [
                      const Color(0xFF10B981),
                      const Color(0xFF059669),
                    ],
                    onTap: controller.pickMedium,
                  ),
                  const SizedBox(height: 16),
                  _levelCardModern(
                    level: 'Mahir',
                    levelEn: 'Hard',
                    description: 'Tantangan dengan pertanyaan lebih kompleks',
                    details: '6 Pertanyaan • 25 detik/jawaban',
                    icon: Icons.trending_up,
                    color: _warning,
                    gradientColors: [
                      const Color(0xFFF59E0B),
                      const Color(0xFFD97706),
                    ],
                    onTap: controller.pickHard,
                  ),
                  const SizedBox(height: 16),
                  _levelCardModern(
                    level: 'Profesional',
                    levelEn: 'Advance',
                    description: 'Untuk profesional yang ingin uji kemampuan',
                    details: '6 Pertanyaan • 30 detik/jawaban',
                    icon: Icons.workspace_premium,
                    color: _primaryGold,
                    gradientColors: [
                      const Color(0xFFD4AF37),
                      const Color(0xFFB8860B),
                    ],
                    onTap: controller.pickAdvance,
                    isPremium: true,
                  ),
                  const SizedBox(height: 24),
                  _infoCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelCardModern({
    required String level,
    required String levelEn,
    required String description,
    required String details,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(icon, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  level,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (isPremium) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'PRO',
                                      style: TextStyle(
                                        color: _primaryDark,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                details,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: _primaryDark,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.lightbulb, color: _primaryGold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tips: Tatap kamera, jawab dengan rileks, dan jaga postur tubuh tegak. Percaya diri adalah kunci utama!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countdown(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryDark, const Color(0xFF1E3A5F)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'BERSIAP-SIAP!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: _primaryGold,
              ),
            ),
            const SizedBox(height: 20),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _primaryGold,
                        ),
                      ),
                    ),
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: _primaryGold.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Obx(
                          () => Text(
                            controller.countdown.value.toString(),
                            style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w800,
                              color: _primaryGold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            Text(
              'Fokus ke kamera dan siapkan dirimu!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _practice(BuildContext context) {
    return Column(
      children: [
        _header(
          title: 'Wawancara dengan HRD',
          subtitle: 'Jawab setiap pertanyaan dengan percaya diri',
          showBack: true,
          actions: [
            Obx(
              () => IconButton(
                onPressed: controller.toggleSound,
                icon: Icon(
                  controller.soundEnabled.value
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                ),
              ),
            ),
            IconButton(
              onPressed: controller.detect.switchCamera,
              icon: const Icon(Icons.cameraswitch_rounded),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                _cameraSection(context),
                const SizedBox(height: 14),
                _detectionAlertCard(),
                const SizedBox(height: 14),
                _questionCard(),
                const SizedBox(height: 12),
                _timerAndProgressRow(),
                const SizedBox(height: 12),
                _threeMetricsCard(),
                const SizedBox(height: 12),
                _speechStats(),
                const SizedBox(height: 14),
                _transcriptCard(),
                const SizedBox(height: 14),
                _stopButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _detectionAlertCard() {
    return Obx(() {
      final d = controller.detect;
      String alertMessage = '';
      Color alertColor = _success;
      IconData alertIcon = Icons.check_circle;

      if (!d.isFaceDetected.value) {
        alertMessage =
            'Wajah tidak terdeteksi. Pastikan wajah Anda terlihat jelas di kamera.';
        alertColor = _danger;
        alertIcon = Icons.warning_amber_rounded;
      } else if (d.totalEyeViolations > 3) {
        alertMessage = 'Kontak mata sering teralihkan. Coba fokus ke kamera.';
        alertColor = _warning;
        alertIcon = Icons.visibility_off;
      } else if (d.totalHeadViolations > 3) {
        alertMessage = 'Postur tubuh kurang stabil. Duduklah lebih tegak.';
        alertColor = _warning;
        alertIcon = Icons.accessibility_new;
      } else if (d.smileCount.value == 0 && d.neutralCount.value > 2) {
        alertMessage = 'Ekspresi masih kaku. Cobalah tersenyum.';
        alertColor = _warning;
        alertIcon = Icons.mood_bad;
      } else if (d.isFaceDetected.value) {
        alertMessage = 'Wajah terdeteksi dengan baik. Postur siap dianalisis.';
        alertColor = _success;
        alertIcon = Icons.face;
      } else {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: alertColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: alertColor, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(alertIcon, color: alertColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                alertMessage,
                style: TextStyle(
                  color: alertColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _cameraSection(BuildContext context) {
    return Column(
      children: [
        _cameraCard(context),
        const SizedBox(height: 10),
        _statusBadgesRow(),
      ],
    );
  }

  Widget _cameraCard(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final camH = screenH * 0.36;
    final maxW = screenW * 0.66;

    return Obx(() {
      final cam = controller.detect.cameraController;
      final isFaceDetected = controller.detect.isFaceDetected.value;

      if (cam == null || !controller.detect.isCameraReady.value) {
        return Container(
          height: camH,
          width: maxW,
          decoration: BoxDecoration(
            color: _primaryDark,
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: _primaryGold),
          ),
        );
      }

      return Container(
        width: maxW,
        height: camH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: 100,
                  child: AspectRatio(
                    aspectRatio: 1 / cam.value.aspectRatio,
                    child: CameraPreview(cam),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isFaceDetected ? _primaryGold : _danger,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isFaceDetected
                        ? _success.withOpacity(0.8)
                        : _danger.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFaceDetected ? Icons.face : Icons.face_retouching_off,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFaceDetected
                            ? 'WAJAH TERDETEKSI'
                            : 'WAJAH TIDAK TERDETEKSI',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryDark.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fiber_manual_record, color: _danger, size: 10),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _statusBadgesRow() {
    return Obx(() {
      final d = controller.detect;
      final totalEye = d.totalEyeViolations;
      final totalHead = d.totalHeadViolations;

      String statusText;
      Color statusColor;
      if (totalEye <= 1 && totalHead <= 1 && d.smileCount.value > 0) {
        statusText = 'Performa Sangat Baik';
        statusColor = _success;
      } else if (totalEye > 3 || totalHead > 3) {
        statusText = 'Perlu Banyak Perbaikan';
        statusColor = _danger;
      } else if (totalEye > 1 || totalHead > 1) {
        statusText = 'Perlu Peningkatan';
        statusColor = _warning;
      } else {
        statusText = 'Tetap Fokus';
        statusColor = _primaryBlue;
      }

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _pill(icon: Icons.analytics, text: statusText, color: statusColor),
          if (controller.isAsking.value)
            _pill(
              icon: Icons.record_voice_over,
              text: 'Pertanyaan HRD...',
              color: _primaryBlue,
            ),
          if (controller.isAnswering.value)
            _pill(
              icon: Icons.mic,
              text: 'Giliran Anda Menjawab',
              color: _success,
            ),
        ],
      );
    });
  }

  Widget _pill({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _questionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryDark, _primaryDark.withOpacity(0.95)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: _primaryGold, size: 20),
              const SizedBox(width: 10),
              Text(
                'Pertanyaan HRD',
                style: TextStyle(
                  color: _primaryGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => Text(
              controller.currentLine.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timerAndProgressRow() {
    return Obx(() {
      final total = controller.scriptLines.isEmpty
          ? 1
          : controller.scriptLines.length;
      final curr = controller.currentIndex.value + 1;
      final secs = controller.secondsLeftInLine.value;
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: secs <= 3 ? _danger : _primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$secs detik',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: secs <= 3 ? _danger : _textDark,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryDark.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$curr / $total',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _threeMetricsCard() {
    return Obx(() {
      final d = controller.detect;
      final eyeTotal = d.totalEyeViolations;
      final headTotal = d.totalHeadViolations;
      final smileTotal = d.smileCount.value;
      final neutralTotal = d.neutralCount.value;

      String eyeLabel;
      Color eyeColor;
      if (eyeTotal <= 3) {
        eyeLabel = "Fokus & Percaya Diri";
        eyeColor = _success;
      } else if (eyeTotal <= 6) {
        eyeLabel = "Sesekali Terdistraksi";
        eyeColor = _warning;
      } else {
        eyeLabel = "Sering Kehilangan Fokus";
        eyeColor = _danger;
      }

      String smileLabel;
      Color smileColor;
      if (smileTotal >= 3 && smileTotal > neutralTotal) {
        smileLabel = "Ramah & Antusias";
        smileColor = _success;
      } else if (smileTotal >= 1) {
        smileLabel = "Cukup Ramah / Netral";
        smileColor = _warning;
      } else {
        smileLabel = "Kaku & Tegang";
        smileColor = _danger;
      }

      String postureLabel;
      Color postureColor;
      if (headTotal <= 3) {
        postureLabel = "Tenang & Profesional";
        postureColor = _success;
      } else if (headTotal <= 6) {
        postureLabel = "Sedikit Gelisah";
        postureColor = _warning;
      } else {
        postureLabel = "Gugup & Cemas";
        postureColor = _danger;
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            _metricItemWithLabel(
              icon: Icons.visibility,
              label: 'Kontak Mata',
              value: '$eyeTotal x',
              status: eyeLabel,
              color: eyeColor,
            ),
            Container(width: 1, height: 50, color: _border),
            _metricItemWithLabel(
              icon: Icons.mood,
              label: 'Ekspresi',
              value: '😊 $smileTotal',
              status: smileLabel,
              color: smileColor,
            ),
            Container(width: 1, height: 50, color: _border),
            _metricItemWithLabel(
              icon: Icons.accessibility_new,
              label: 'Postur',
              value: '$headTotal x',
              status: postureLabel,
              color: postureColor,
            ),
          ],
        ),
      );
    });
  }

  Widget _metricItemWithLabel({
    required IconData icon,
    required String label,
    required String value,
    required String status,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: _textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _speechStats() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            _statCol(
              'Kecepatan (WPM)',
              '${controller.wordsPerMinute.value}',
              'kata/menit',
            ),
            _dividerV(),
            _statCol('Kata Pengisi', '${controller.fillerCount.value}', 'kali'),
            _dividerV(),
            _statCol(
              'Kelancaran',
              '${controller.fluencyScore.value.round()}',
              'poin',
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String label, String value, String unit) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _primaryDark,
          ),
        ),
        Text(unit, style: const TextStyle(color: _textMuted, fontSize: 10)),
      ],
    ),
  );

  Widget _dividerV() => Container(height: 30, width: 1, color: _border);

  Widget _transcriptCard() {
    return Obx(() {
      final tx = controller.currentLineRecognized.value.trim();
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(Icons.subtitles_rounded, color: _primaryBlue, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tx.isEmpty ? 'Teks jawaban akan muncul di sini...' : tx,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tx.isEmpty ? _textMuted : _textDark),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _stopButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => controller.stopSession(goResult: true),
        icon: const Icon(Icons.check_circle_rounded),
        label: const Text('Selesaikan & Lihat Hasil'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  // ==================== HASIL / RESULT ====================
  Widget _result(BuildContext context) {
    return Column(
      children: [
        _header(
          title: 'Hasil Latihan Interview',
          subtitle: 'Rekomendasi dari AI',
          showBack: true,
          actions: [
            IconButton(
              onPressed: () {
                controller.stopSession(goResult: false);
                controller.step.value = PracticeStep.instructions;
              },
              icon: const Icon(Icons.close_rounded),
              color: _textMuted,
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              if (controller.isAiProcessing.value) {
                return _buildAiLoading();
              }

              return Column(
                children: [
                  _aiRecommendationCard(),
                  const SizedBox(height: 16),
                  _speechMetricsCard(),
                  const SizedBox(height: 16),
                  _detectionResultCard(),
                  const SizedBox(height: 16),
                  _qaHistoryResultCard(),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        controller.stopSession(goResult: false);
                        controller.detectionResult.value = null;
                        controller.step.value = PracticeStep.instructions;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGold,
                        foregroundColor: _primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Latihan Lagi',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildAiLoading() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primaryGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation(_primaryGold),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Obx(
            () => Text(
              controller.aiProcessingMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Mohon tunggu sebentar...',
            style: TextStyle(fontSize: 13, color: _textMuted),
          ),
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LoadingDot(),
              SizedBox(width: 8),
              _LoadingDot(),
              SizedBox(width: 8),
              _LoadingDot(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detectionResultCard() {
    return Obx(() {
      final eyeLabel = controller.eyeContactLabel.value;
      final smileLabel = controller.smileLabel.value;
      final postureLabel = controller.postureLabel.value;

      if (eyeLabel.isEmpty && smileLabel.isEmpty && postureLabel.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Deteksi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 12),
            _detectionItem(
              icon: Icons.visibility_rounded,
              label: 'Kontak Mata',
              value: eyeLabel,
              color: _getLabelColor(eyeLabel),
            ),
            const SizedBox(height: 8),
            _detectionItem(
              icon: Icons.mood_rounded,
              label: 'Ekspresi',
              value: smileLabel,
              color: _getLabelColor(smileLabel),
            ),
            const SizedBox(height: 8),
            _detectionItem(
              icon: Icons.accessibility_new_rounded,
              label: 'Postur',
              value: postureLabel,
              color: _getLabelColor(postureLabel),
            ),
          ],
        ),
      );
    });
  }

  Widget _detectionItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: _textMuted)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Color _getLabelColor(String label) {
    if (label.contains('Fokus') ||
        label.contains('Ramah') ||
        label.contains('Tenang'))
      return _success;
    if (label.contains('Sesekali') ||
        label.contains('Cukup') ||
        label.contains('Sedikit'))
      return _warning;
    return _danger;
  }

  Widget _aiRecommendationCard() {
    return Obx(() {
      final rec = controller.aiRecommendation.value;
      if (rec.isEmpty) return const SizedBox.shrink();

      final cleanRec = rec
          .replaceAll(RegExp(r'[*_\-]{3,}'), '')
          .replaceAll('━', '')
          .replaceAll('─', '')
          .trim();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primaryDark, Color(0xFF1E3A5F)],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: _primaryGold, size: 26),
                const SizedBox(width: 12),
                Text(
                  'Rekomendasi AI',
                  style: TextStyle(
                    color: _primaryGold,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              cleanRec,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _speechMetricsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metrik Komunikasi Verbal',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statDetail(
                'WPM',
                '${controller.wordsPerMinute.value}',
                'kata/menit',
              ),
              _statDetail(
                'Kata Pengisi',
                '${controller.fillerCount.value}',
                'kali',
              ),
              _statDetail(
                'Kelancaran',
                '${controller.fluencyScore.value.round()}',
                'poin',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statDetail(String label, String value, String unit) => Expanded(
    child: Column(
      children: [
        Text(label, style: const TextStyle(color: _textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _primaryDark,
          ),
        ),
        Text(unit, style: const TextStyle(color: _textMuted, fontSize: 10)),
      ],
    ),
  );

  Widget _qaHistoryResultCard() {
    return Obx(() {
      final history = controller.qaHistory;
      if (history.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.question_answer, color: _primaryGold, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'RIWAYAT PERTANYAAN & JAWABAN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...history.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _primaryDark.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Pertanyaan ${index + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _primaryBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Q',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['q'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _success,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'A',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['a'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textMuted,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );
    });
  }

  // ==================== HELPER WIDGETS ====================
  Widget _header({
    required String title,
    required String subtitle,
    bool showBack = false,
    List<Widget> actions = const [],
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () => controller.backToChoose(),
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
              color: _textDark,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _primaryDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: _textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

// ==================== LOADING DOT ANIMATION ====================
class _LoadingDot extends StatefulWidget {
  const _LoadingDot();

  @override
  State<_LoadingDot> createState() => _LoadingDotState();
}

class _LoadingDotState extends State<_LoadingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: NarasiPracticeView._primaryGold,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
