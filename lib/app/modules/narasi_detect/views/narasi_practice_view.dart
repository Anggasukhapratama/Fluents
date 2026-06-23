// lib/app/views/narasi_practice_view.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/narasi_practice_controller.dart';

class NarasiPracticeView extends GetView<NarasiPracticeController> {
  NarasiPracticeView({super.key});

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

  // Cache untuk detail analisis (agar tidak loading ulang)
  String? _cachedAnalysis;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Obx(() {
          switch (controller.step.value) {
            case PracticeStep.instructions:
              return _instructionsView(context);
            case PracticeStep.jobInput:
              return _jobInputView(context);
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

  // ==================== INSTRUCTIONS VIEW ====================
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
                  const SizedBox(height: 24),

                  // ===== TIPS EKSPRESI ANTUSIAS =====
                  _expressionTipsCard(),

                  const SizedBox(height: 30),
                  _gradientButton(
                    onPressed: controller.nextToJobInput,
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

  // ===== TIPS EKSPRESI ANTUSIAS =====
  Widget _expressionTipsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFA726).withOpacity(0.20),
            const Color(0xFFFFA726).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tips_and_updates,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tips Ekspresi Antusias',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _tipRow(
            emoji: '😊',
            title: 'Senyum di awal jawaban',
            desc:
                'Tunjukkan senyum 1-2 detik saat menyapa atau memulai jawaban.',
          ),
          const SizedBox(height: 10),
          _tipRow(
            emoji: '🎯',
            title: 'Antusias saat cerita pengalaman',
            desc:
                'Saat menceritakan pencapaian atau hal positif, biarkan ekspresi natural.',
          ),
          const SizedBox(height: 10),
          _tipRow(
            emoji: '😐',
            title: 'Wajah netral saat mendengarkan',
            desc:
                'Tidak perlu senyum terus. Wajah tenang saat mendengarkan justru profesional.',
          ),
          const SizedBox(height: 10),
          _tipRow(
            emoji: '⚠️',
            title: 'Hindari senyum berlebihan',
            desc:
                'Senyum terlalu sering (10+ kali) terlihat dipaksakan dan kurang profesional.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Target Ideal: tunjukkan 2-5 momen antusias selama wawancara',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipRow({
    required String emoji,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.75),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
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

  // ==================== JOB INPUT VIEW ====================
  Widget _jobInputView(BuildContext context) {
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
            title: 'Target Pekerjaan',
            subtitle: 'Sebutkan posisi yang Anda lamar',
            showBack: true,
            onBack: controller.backToInstructions,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.work_outline_rounded,
                          size: 48,
                          color: _primaryGold,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Jenis Pekerjaan Apa yang Anda Lamar?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI akan menyesuaikan pertanyaan wawancara berdasarkan posisi yang Anda tuju',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: controller.jobTargetCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText:
                                'Contoh: Flutter Developer, UI/UX Designer, dll.',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(
                              Icons.business_center,
                              color: _primaryGold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _gradientButton(
                          onPressed: controller.submitJobTarget,
                          text: 'LANJUTKAN',
                          icon: Icons.arrow_forward_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CHOOSE LEVEL VIEW ====================
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
            onBack: controller.backToJobInput,
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
                    details: '5 Pertanyaan • 25 detik/jawaban',
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
                    details: '5 Pertanyaan • 30 detik/jawaban',
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
                        decoration: const BoxDecoration(
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

  // ==================== COUNTDOWN VIEW ====================
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

  // ==================== PRACTICE VIEW ====================
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
      final enthusiasmMoments = d.enthusiasmMomentCount.value;

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

      // ===== EKSPRESI: Berbasis Momen Antusias =====
      // Sesuai Ruben et al. (2015): "Smiling in a Job Interview - When Less Is More"
      // 2-5 momen = Ideal, 1 atau 6-9 = Cukup, 0 = Datar, 10+ = Berlebihan
      String smileLabel;
      Color smileColor;
      if (enthusiasmMoments >= 2 && enthusiasmMoments <= 5) {
        smileLabel = "Antusias & Profesional";
        smileColor = _success;
      } else if (enthusiasmMoments == 1 ||
          (enthusiasmMoments >= 6 && enthusiasmMoments <= 9)) {
        smileLabel = "Cukup Antusias";
        smileColor = _warning;
      } else if (enthusiasmMoments >= 10) {
        smileLabel = "Antusias Berlebihan";
        smileColor = _danger;
      } else {
        smileLabel = "Datar & Tegang";
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
              value: '✨ $enthusiasmMoments',
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
              'Kecepatan Bicara',
              '${controller.wordsPerMinute.value}',
              'WPM',
              Icons.speed_rounded,
            ),
            _dividerV(),
            _statCol(
              'Kata Pengisi',
              '${controller.fillerCount.value}',
              'kali',
              Icons.text_fields_rounded,
            ),
            _dividerV(),
            _statCol(
              'Total Kata',
              '${controller.totalWordsSpoken.value}',
              'kata',
              Icons.format_list_numbered_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String label, String value, String unit, IconData icon) =>
      Expanded(
        child: Column(
          children: [
            Icon(icon, color: _primaryBlue, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: _textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
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

  // ==================== RESULT VIEW ====================
  Widget _result(BuildContext context) {
    return Column(
      children: [
        _header(
          title: 'Hasil Latihan Interview',
          subtitle: 'Hasil analisis dari AI',
          showBack: true,
          actions: [
            IconButton(
              onPressed: () {
                controller.stopSession(goResult: false);
                controller.step.value = PracticeStep.instructions;
                _cachedAnalysis = null; // Reset cache
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
                  _behaviorDetectionCard(),
                  const SizedBox(height: 16),
                  _speechMetricsCard(context),
                  const SizedBox(height: 16),
                  _detailAnalysisButton(context),
                  const SizedBox(height: 16),
                  _qaHistoryWithCorrectionsCard(),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        controller.stopSession(goResult: false);
                        controller.detectionResult.value = null;
                        controller.step.value = PracticeStep.instructions;
                        _cachedAnalysis = null;
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

  // ==================== BEHAVIOR DETECTION CARD (BARU) ====================
  Widget _behaviorDetectionCard() {
    return Obx(() {
      final d = controller.detect;

      // Data Kontak Mata
      final lookLeft = d.lookAwayLeftCount.value;
      final lookRight = d.lookAwayRightCount.value;
      final lookDown = d.lookDownCount.value;
      final totalEye = lookLeft + lookRight + lookDown;
      final eyeLabel = controller.eyeContactLabel.value;
      final eyeColor = _getLabelColor(eyeLabel);

      // Data Ekspresi (Logika Baru: Momen Antusias)
      final enthusiasmMoments = d.enthusiasmMomentCount.value;
      final smileLabel = controller.smileLabel.value;
      final smileColor = _getLabelColor(smileLabel);

      // Data Postur
      final headLeft = d.headTiltLeftCount.value;
      final headRight = d.headTiltRightCount.value;
      final headDown = d.headDownCount.value;
      final totalHead = headLeft + headRight + headDown;
      final postureLabel = controller.postureLabel.value;
      final postureColor = _getLabelColor(postureLabel);

      // Data Verbal
      final totalWords = controller.totalWordsSpoken.value;
      final filler = controller.fillerCount.value;
      final avgWpm = controller.wordsPerMinute.value;

      // Data Overall
      final eyePoints = d.getEyeContactPoints();
      final smilePoints = d.getFacialExpressionPoints();
      final posturePoints = d.getPosturePoints();
      final totalPoints = eyePoints + smilePoints + posturePoints;
      final maxPoints = 6;
      final overallLabel = controller.overallLabel.value;

      // Warna untuk overall
      Color overallColor;
      switch (overallLabel) {
        case 'Sangat Percaya Diri':
          overallColor = _success;
          break;
        case 'Siap Wawancara':
          overallColor = _success;
          break;
        case 'Cukup Baik':
          overallColor = _warning;
          break;
        default:
          overallColor = _danger;
      }

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
              '📊 HASIL ANALISIS PERILAKU',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 16),

            // 1. KONTAK MATA
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: eyeColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: eyeColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.visibility, color: eyeColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'KONTAK MATA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: eyeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (lookLeft > 0)
                        _detailChip(
                          '👁️ Melirik kiri',
                          '$lookLeft x',
                          eyeColor,
                        ),
                      if (lookRight > 0)
                        _detailChip(
                          '👁️ Melirik kanan',
                          '$lookRight x',
                          eyeColor,
                        ),
                      if (lookDown > 0)
                        _detailChip('⬇️ Menunduk', '$lookDown x', eyeColor),
                      if (lookLeft == 0 && lookRight == 0 && lookDown == 0)
                        _detailChip('✅', 'Selalu fokus ke kamera', eyeColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total momen tidak fokus: $totalEye x',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: eyeColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: eyeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      eyeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: eyeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Poin: $eyePoints/2',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: eyeColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. EKSPRESI WAJAH
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: smileColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: smileColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mood, color: smileColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'EKSPRESI WAJAH',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: smileColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (enthusiasmMoments > 0)
                        _detailChip(
                          '✨ Momen Antusias',
                          '$enthusiasmMoments x',
                          smileColor,
                        ),
                      if (enthusiasmMoments == 0)
                        _detailChip('❌', 'Tidak terdeteksi', smileColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: smileColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      smileLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: smileColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Poin: $smilePoints/2',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: smileColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. POSTUR TUBUH
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: postureColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: postureColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.accessibility_new,
                        color: postureColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'POSTUR TUBUH',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: postureColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (headLeft > 0)
                        _detailChip(
                          '🤸 Bahu miring kiri',
                          '$headLeft x',
                          postureColor,
                        ),
                      if (headRight > 0)
                        _detailChip(
                          '🤸 Bahu miring kanan',
                          '$headRight x',
                          postureColor,
                        ),
                      if (headDown > 0)
                        _detailChip(
                          '⬇️ Kepala menunduk',
                          '$headDown x',
                          postureColor,
                        ),
                      if (headLeft == 0 && headRight == 0 && headDown == 0)
                        _detailChip('✅', 'Postur stabil', postureColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total gerakan tidak stabil: $totalHead x',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: postureColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: postureColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      postureLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: postureColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Poin: $posturePoints/2',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: postureColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. OVERALL (BARU - DITARUH DI SINI)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: overallColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: overallColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(
                    overallLabel == 'Sangat Percaya Diri'
                        ? Icons.star_rounded
                        : overallLabel == 'Siap Wawancara'
                        ? Icons.emoji_events_rounded
                        : overallLabel == 'Cukup Baik'
                        ? Icons.trending_up_rounded
                        : Icons.fitness_center_rounded,
                    color: overallColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hasil Overall: $overallLabel ($totalPoints/$maxPoints poin)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: overallColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 5. KOMUNIKASI VERBAL
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primaryBlue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.record_voice_over,
                        color: _primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'KOMUNIKASI VERBAL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _verbalStat(
                        'Kecepatan',
                        '$avgWpm',
                        'WPM',
                        avgWpm >= 130 && avgWpm <= 160 ? _success : _warning,
                      ),
                      _verbalStat(
                        'Kata Pengisi',
                        '$filler',
                        'kali',
                        filler <= 2 ? _success : _warning,
                      ),
                      _verbalStat(
                        'Total Kata',
                        '$totalWords',
                        'kata',
                        _primaryBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _detailChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _verbalStat(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(unit, style: const TextStyle(fontSize: 10, color: _textMuted)),
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

  // ==================== REKOMENDASI RINGKAS CARD ====================

  // ==================== DETAIL ANALYSIS BUTTON ====================
  Widget _detailAnalysisButton(BuildContext context) {
    final isLoading = false.obs;

    return Obx(
      () => GestureDetector(
        onTap: isLoading.value
            ? null
            : () async {
                isLoading.value = true;
                await _showDetailAnalysisDialog(context);
                isLoading.value = false;
              },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _primaryDark.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primaryGold.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading.value)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primaryGold,
                  ),
                )
              else
                const Icon(
                  Icons.analytics_rounded,
                  color: _primaryGold,
                  size: 18,
                ),
              const SizedBox(width: 8),
              Text(
                isLoading.value
                    ? 'Memuat analisis...'
                    : '📊 Lihat Detail Analisis Perilaku',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _primaryDark,
                ),
              ),
              if (!isLoading.value)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _primaryDark,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetailAnalysisDialog(BuildContext context) async {
    // Gunakan cache jika sudah ada
    _cachedAnalysis ??= await controller.getDetailedBehaviorAnalysis();
    final analysis = _cachedAnalysis!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryDark,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics_rounded,
                    color: _primaryGold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Detail Analisis Perilaku',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  analysis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: _textDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SPEECH METRICS CARD ====================
  Widget _speechMetricsCard(BuildContext context) {
    return Obx(() {
      final perQuestionDetails = controller.getPerQuestionDetails();
      final avgWpm = controller.wordsPerMinute.value;
      final avgWpmRating = controller.getWpmRating(avgWpm);
      final avgWpmColor = controller.getWpmColor(avgWpm);
      final avgWpmRecommendation = controller.getWpmRecommendation(avgWpm);

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
                Icon(Icons.speed_rounded, color: _primaryGold, size: 22),
                const SizedBox(width: 10),
                const Text(
                  '📊 Metrik Komunikasi Verbal',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _statDetailWithRating(
                  label: 'Rata-rata WPM',
                  value: '$avgWpm',
                  unit: 'kata/menit',
                  color: avgWpmColor,
                  subtitle: avgWpmRating,
                ),
                _statDetailWithRating(
                  label: 'Kata Pengisi',
                  value: '${controller.fillerCount.value}',
                  unit: 'kali',
                  color: controller.fillerCount.value <= 2
                      ? _success
                      : _warning,
                  subtitle: controller.fillerCount.value <= 2
                      ? 'Baik'
                      : 'Perlu dikurangi',
                ),
                _statDetailWithRating(
                  label: 'Total Kata',
                  value: '${controller.totalWordsSpoken.value}',
                  unit: 'kata',
                  color: _primaryBlue,
                  subtitle: 'keseluruhan',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryDark.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Standar Kecepatan Bicara (WPM):',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _wpmStandardChip(
                        'Terlalu Lambat',
                        '< 110',
                        const Color(0xFFEF4444),
                      ),
                      _wpmStandardChip(
                        'Ideal',
                        '130 - 160',
                        const Color(0xFF10B981),
                      ),
                      _wpmStandardChip(
                        'Terlalu Cepat',
                        '> 180',
                        const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '💡 WPM ideal antara 130-160 kata per menit',
                      style: TextStyle(fontSize: 10, color: _primaryBlue),
                    ),
                  ),
                ],
              ),
            ),

            if (perQuestionDetails.isNotEmpty) ...[
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: _primaryGold, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'WPM per Pertanyaan',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryDark.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 35,
                              child: Text('No', style: _tableHeaderStyle()),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Pertanyaan',
                                style: _tableHeaderStyle(),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                'WPM',
                                style: _tableHeaderStyle(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                'Kar.',
                                style: _tableHeaderStyle(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 55,
                              child: Text(
                                'Waktu',
                                style: _tableHeaderStyle(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...perQuestionDetails.map(
                        (detail) => _perQuestionRow(detail),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryDark.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📈 Tren Kecepatan Bicara',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: perQuestionDetails.map((detail) {
                        final wpm = detail['wpm'] as int;
                        final height = (wpm / 200 * 40).clamp(8.0, 40.0);
                        return Expanded(
                          child: Column(
                            children: [
                              Container(
                                height: height,
                                width: 20,
                                decoration: BoxDecoration(
                                  color: controller.getWpmColor(wpm),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${detail['number']}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (wpm >= 130 && wpm <= 160)
                                const Icon(
                                  Icons.star,
                                  size: 8,
                                  color: Color(0xFF10B981),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        _legendItem(const Color(0xFF10B981), 'Ideal (130-160)'),
                        _legendItem(
                          const Color(0xFFF59E0B),
                          'Sedikit Lambat/Cepat',
                        ),
                        _legendItem(const Color(0xFFEF4444), 'Perlu Perbaikan'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryDark.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    controller.fillerCount.value <= 2
                        ? Icons.check_circle
                        : Icons.warning_amber,
                    color: controller.fillerCount.value <= 2
                        ? _success
                        : _warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.fillerCount.value <= 2
                          ? 'Bagus! Kata pengisi Anda minim 👍'
                          : 'Kurangi kata "umm", "anu", "eee" ya 💪',
                      style: TextStyle(
                        fontSize: 12,
                        color: controller.fillerCount.value <= 2
                            ? _success
                            : _warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _statDetailWithRating({
    required String label,
    required String value,
    required String unit,
    required Color color,
    required String subtitle,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: _textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(unit, style: const TextStyle(color: _textMuted, fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _tableHeaderStyle() => const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: _textMuted,
  );

  Widget _wpmStandardChip(String label, String range, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $range WPM',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _perQuestionRow(Map<String, dynamic> detail) {
    final wpm = detail['wpm'] as int;
    final wpmColor = controller.getWpmColor(wpm);
    final wpmRating = controller.getWpmRating(wpm);
    String questionText = detail['question'] as String;
    if (questionText.length > 20)
      questionText = '${questionText.substring(0, 17)}...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: Text(
              '${detail['number']}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              questionText,
              style: const TextStyle(fontSize: 11, color: _textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(
                  '$wpm',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: wpmColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  wpmRating,
                  style: TextStyle(fontSize: 9, color: wpmColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              '${detail['wordCount']}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 55,
            child: Text(
              _formatDuration(detail['speakingSeconds']),
              style: const TextStyle(fontSize: 12, color: _textMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: _textMuted)),
      ],
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0d';
    if (seconds < 60) return '${seconds}d';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m${remainingSeconds}s';
  }

  // ==================== QA HISTORY WITH CORRECTIONS CARD ====================
  Widget _qaHistoryWithCorrectionsCard() {
    return Obx(() {
      final corrections = controller.answersWithCorrections;
      if (corrections.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
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
                Icon(Icons.auto_awesome_rounded, color: _primaryGold, size: 22),
                const SizedBox(width: 10),
                const Text(
                  '💬 Koreksi Jawaban dari AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...corrections
                .asMap()
                .entries
                .map(
                  (entry) => _correctionCard(
                    number: entry.key + 1,
                    question: entry.value.question,
                    answer: entry.value.userAnswer,
                    correction: entry.value.aiCorrection,
                    wpm: entry.value.wpm,
                    speakingSeconds: entry.value.speakingSeconds,
                    wordCount: entry.value.wordCount,
                    fillers: entry.value.fillerCount,
                  ),
                )
                .toList(),
          ],
        ),
      );
    });
  }

  Widget _correctionCard({
    required int number,
    required String question,
    required String answer,
    required String correction,
    required int wpm,
    required int speakingSeconds,
    required int wordCount,
    required int fillers,
  }) {
    final wpmColor = controller.getWpmColor(wpm);
    final wpmRating = controller.getWpmRating(wpm);

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
          Row(
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
                  'Pertanyaan $number',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _primaryDark,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: wpmColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.speed, size: 12, color: wpmColor),
                    const SizedBox(width: 4),
                    Text(
                      '$wpm $wpmRating',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: wpmColor,
                      ),
                    ),
                  ],
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
                  question,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                  answer.isEmpty ? '(tidak ada jawaban)' : answer,
                  style: TextStyle(
                    fontSize: 12,
                    color: answer.isEmpty ? _danger : _textMuted,
                    height: 1.5,
                    fontStyle: answer.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _answerStatItem(
                  icon: Icons.text_fields,
                  label: 'Kata',
                  value: '$wordCount',
                  color: _primaryBlue,
                ),
                Container(width: 1, height: 20, color: _border),
                _answerStatItem(
                  icon: Icons.timer,
                  label: 'Waktu',
                  value: _formatDuration(speakingSeconds),
                  color: _primaryBlue,
                ),
                Container(width: 1, height: 20, color: _border),
                _answerStatItem(
                  icon: Icons.mic_off,
                  label: 'Kata pengisi',
                  value: '$fillers',
                  color: fillers <= 1 ? _success : _warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryGold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryGold.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: _primaryGold,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Koreksi AI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _primaryGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  correction,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _answerStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 10, color: _textMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ==================== HEADER & BUTTONS ====================
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

  Widget _headerModern({
    required String title,
    required String subtitle,
    bool showBack = false,
    VoidCallback? onBack,
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
                onPressed: onBack ?? () => controller.backToInstructions(),
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
