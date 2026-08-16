// lib/app/modules/narasi_detect/views/narasi_practice_view.dart
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

  // ============================================================
  // INSTRUCTIONS VIEW (tidak berubah)
  // ============================================================
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
                        'Pastikan wajah terlihat jelas di kamera. AI akan mendeteksi kontak mata Anda secara real-time.',
                    color: _primaryBlue,
                  ),
                  const SizedBox(height: 16),
                  _instructionCardModern(
                    number: '02',
                    icon: Icons.visibility,
                    title: 'Perhatikan Frekuensi Melirik',
                    desc:
                        'Usahakan tidak terlalu sering menengok. Aplikasi akan menghitung berapa kali Anda mengalihkan pandangan ke kanan, kiri, atas, atau bawah.',
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
                        'Setelah menyelesaikan 5 pertanyaan, Anda akan mendapatkan analisis lengkap kontak mata dan rekomendasi.',
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 16),

                  // Tambahkan instruksi senyum (baru)
                  _instructionCardModern(
                    number: '05',
                    icon: Icons.emoji_emotions,
                    title: 'Senyum yang Alami',
                    desc:
                        'Aplikasi mendeteksi pola temporal senyum (onset, apex, offset) untuk membedakan senyum tulus dan dibuat-buat. Usahakan tersenyum secara natural: muncul secara perlahan, puncak singkat, dan surut perlahan. Hindari menahan senyum terlalu lama atau tersenyum sangat mendadak.',
                    color: const Color(0xFFF97316),
                  ),
                  const SizedBox(height: 24),

                  _eyeContactTipsCard(),
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

  Widget _eyeContactTipsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.20),
            const Color(0xFF3B82F6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tips Kontak Mata Ideal',
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
            emoji: '👀',
            title: '70-80% Wajah Terlihat',
            desc:
                'Usahakan wajah Anda terlihat di kamera setidaknya 70% dari total waktu latihan. Ini menunjukkan fokus yang baik.',
          ),
          const SizedBox(height: 10),
          _tipRow(
            emoji: '⚠️',
            title: 'Hindari Terlalu Sering Keluar Layar',
            desc:
                'Jika wajah hilang lebih dari 30% waktu, dianggap kurang fokus. Perbaiki posisi duduk Anda.',
          ),
          const SizedBox(height: 10),
          _tipRow(
            emoji: '🔄',
            title: 'Alihkan Pandangan Secara Natural',
            desc:
                'Saat berpikir, alihkan pandangan ke samping sebentar, lalu kembali ke kamera. Ini tetap dihitung sebagai fokus.',
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
                    'Target: Fokus ≥70% → Ideal, 70-80% → Ideal, >80% → Terlalu Lama',
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
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
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

  // ============================================================
  // JOB INPUT VIEW (tidak berubah)
  // ============================================================
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

  // ============================================================
  // CHOOSE LEVEL VIEW (tidak berubah)
  // ============================================================
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
            subtitle:
                '5 pertanyaan • 30 detik per pertanyaan • Total 2.5 menit',
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
                    details: '5 Pertanyaan • 30 detik/jawaban',
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
                    details: '5 Pertanyaan • 30 detik/jawaban',
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
              'Tips: Usahakan wajah terlihat minimal 70% dari total sesi. Ideal 70-80%. Percaya diri adalah kunci utama!',
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

  // ============================================================
  // COUNTDOWN VIEW (tidak berubah)
  // ============================================================
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

  // ============================================================
  // PRACTICE VIEW (REAL-TIME) – PERUBAHAN UTAMA
  // ============================================================
  Widget _practice(BuildContext context) {
    return Column(
      children: [
        _header(
          title: 'Wawancara dengan HRD',
          subtitle: '5 pertanyaan • 30 detik/jawaban • 2.5 menit',
          showBack: true,
          actions: [
            IconButton(
              onPressed: () => _showDurationInfoDialog(context),
              icon: const Icon(Icons.info_outline_rounded, color: _primaryGold),
            ),
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
                // ===== ALERT CARD DIHAPUS =====
                _questionCard(),
                const SizedBox(height: 12),
                _timerAndProgressRow(),
                const SizedBox(height: 12),
                // ===== CARD KONTAK MATA (HANYA COUNTER) =====
                _eyeContactCounterCard(),
                const SizedBox(height: 12),
                _smileDetectionCard(),
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

  void _showDurationInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.timer, color: _primaryGold),
            SizedBox(width: 8),
            Text('Durasi Wawancara'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('⏱️ Total Durasi: 2.5 menit (150 detik)'),
            SizedBox(height: 8),
            Text('📝 Jumlah Pertanyaan: 5'),
            SizedBox(height: 8),
            Text('⏳ Waktu per Pertanyaan: 30 detik'),
            SizedBox(height: 12),
            Text(
              '💡 Tips: Jawab dengan ringkas dan percaya diri. Jaga wajah terlihat minimal 70% dari total waktu.',
              style: TextStyle(fontSize: 12, color: _textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: _primaryGold)),
          ),
        ],
      ),
    );
  }

  // ===== CAMERA SECTION =====
  Widget _cameraSection(BuildContext context) {
    return Column(
      children: [
        _cameraCard(context),
        const SizedBox(height: 10),
        _statusBadgesRow(), // Menampilkan counter arah
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

  // ===== STATUS SESI =====
  Widget _statusBadgesRow() {
    return Obx(() {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
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

  // ===== QUESTION CARD =====
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

  // ===== TIMER & PROGRESS ROW =====
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
                    color: secs <= 5 ? _danger : _primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatDuration(secs),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: secs <= 5 ? _danger : _textDark,
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
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: _warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _warning.withOpacity(0.3)),
            ),
            child: IconButton(
              onPressed: controller.isAnswering.value
                  ? _showSkipConfirmationDialog
                  : null,
              icon: Icon(
                Icons.skip_next_rounded,
                color: controller.isAnswering.value
                    ? _warning
                    : _textMuted.withOpacity(0.3),
                size: 28,
              ),
              tooltip: 'Skip pertanyaan',
            ),
          ),
        ],
      );
    });
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0d';
    if (seconds < 60) return '${seconds}d';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) return '${minutes}m';
    return '${minutes}m${remainingSeconds}s';
  }

  void _showSkipConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Skip Pertanyaan?'),
        content: const Text(
          'Anda akan melewati pertanyaan ini dan lanjut ke pertanyaan berikutnya. '
          'Jawaban Anda tidak akan disimpan.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.skipCurrentQuestion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  // ===== EYE CONTACT STATUS CARD =====
  Widget _eyeContactCounterCard() {
    return Obx(() {
      final d = controller.detect;
      final isFaceDetected = d.isFaceDetected.value;
      final isLookingAtCamera = d.isLookingAtCamera.value;
      final status = !isFaceDetected
          ? 'Wajah belum terdeteksi'
          : isLookingAtCamera
          ? 'Fokus ke kamera'
          : 'Pandangan teralihkan';
      final message = !isFaceDetected
          ? 'Posisikan wajah Anda di dalam area kamera.'
          : isLookingAtCamera
          ? 'Bagus, pertahankan kontak mata secara natural.'
          : 'Arahkan pandangan kembali ke kamera saat siap.';
      final color = !isFaceDetected
          ? _danger
          : isLookingAtCamera
          ? _success
          : _warning;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.visibility, color: _primaryBlue, size: 20),
                SizedBox(width: 8),
                Text(
                  '👀 Kontak Mata',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    isLookingAtCamera && isFaceDetected
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textMuted,
                          ),
                        ),
                      ],
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

  Widget _smileDetectionCard() {
    return Obx(() {
      final d = controller.detect;
      final isFaceDetected = d.isFaceDetected.value;
      final isSmiling = d.isSmileDetected.value;
      final status = !isFaceDetected
          ? 'Wajah belum terdeteksi'
          : isSmiling
          ? 'Tersenyum'
          : 'Tidak tersenyum';
      final message = !isFaceDetected
          ? 'Pastikan wajah dan senyum terlihat jelas di kamera.'
          : isSmiling
          ? 'Bagus! AI mendeteksi senyuman Anda saat ini.'
          : 'Coba tersenyum dengan alami agar terdeteksi.';
      final color = !isFaceDetected
          ? _danger
          : isSmiling
          ? _success
          : _warning;
      final totalSmiles = d.getTotalSmiles();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_emotions, color: _primaryGold, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '😊 Deteksi Senyum',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    isSmiling && isFaceDetected ? Icons.mood : Icons.mood_bad,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Menghapus tampilan persentase dan kategori Asli/Palsu/Netral.
            if (totalSmiles > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _primaryGold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total Senyum: $totalSmiles',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _primaryGold,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: _textMuted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ===== SPEECH STATS =====
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

  // ===== TRANSCRIPT CARD =====
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

  // ===== STOP BUTTON =====
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

  // ============================================================
  // RESULT VIEW
  // ============================================================
  Widget _result(BuildContext context) {
    return Column(
      children: [
        _header(
          title: 'Hasil Latihan Interview',
          subtitle: 'Analisis lengkap dari AI',
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
                  _eyeContactResultCard(),
                  const SizedBox(height: 16),
                  _smileExpressionResultCard(),
                  const SizedBox(height: 16),
                  _speechMetricsCard(context),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showNarrationEvaluationDialog(context),
                      icon: const Icon(Icons.assignment_rounded),
                      label: const Text('Hasil Evaluasi Narasi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryDark,
                        side: const BorderSide(color: _primaryGold),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _qaHistoryWithCorrectionsCard(),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        controller.stopSession(goResult: false);
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

  void _showNarrationEvaluationDialog(BuildContext context) {
    final detect = controller.detect;
    final savedEyeResult = controller.detectionResult.value?.eyeContact;
    final focusPercentage =
        savedEyeResult?.focusPercentage ?? detect.getFocusPercentage();
    final totalBreaks = savedEyeResult?.totalBreaks ?? detect.getTotalBreaks();

    // arah melirik
    final right = detect.getRightBreaks();
    final left = detect.getLeftBreaks();
    final up = detect.getUpBreaks();
    final down = detect.getDownBreaks();

    final String eyeTitle;
    final String eyeReason;
    final String eyeSuggestion;
    final Color eyeColor;
    if (focusPercentage < 70) {
      eyeTitle = 'Kontak mata terlalu sedikit';
      eyeReason =
          'Fokus ke kamera tercatat ${focusPercentage.toStringAsFixed(1)}%, di bawah rentang ideal 70-80%. Pandangan teralihkan $totalBreaks kali.';
      eyeSuggestion =
          'Posisikan kamera sejajar mata dan kembali lihat lensa setelah berpikir sebentar.';
      eyeColor = _success;
    } else if (focusPercentage > 80) {
      eyeTitle = 'Anda terlalu fokus';
      eyeReason =
          'Fokus ke kamera tercatat ${focusPercentage.toStringAsFixed(1)}%, di atas rentang natural 70-80%. Tatapan yang terlalu menetap dapat terasa kaku atau mengintimidasi.';
      eyeSuggestion =
          'Saat jeda atau berpikir, alihkan pandangan singkat secara natural lalu kembali ke kamera.';
      eyeColor = _success;
    } else {
      eyeTitle = 'Kontak mata seimbang';
      eyeReason =
          'Fokus ke kamera tercatat ${focusPercentage.toStringAsFixed(1)}%, berada dalam rentang ideal 70-80%.';
      eyeSuggestion =
          'Pertahankan pola ini: tatap kamera saat menyampaikan poin penting dan tetap beri jeda yang natural.';
      eyeColor = _success;
    }

    // Saran per arah melirik
    String _breaksSummary() {
      final parts = <String>[];
      if (right > 0)
        parts.add('Kanan: $right kali (Coba pusatkan pandangan ke kamera)');
      if (left > 0)
        parts.add(
          'Kiri: $left kali (Kurangi menoleh ke samping saat berpikir)',
        );
      if (up > 0)
        parts.add('Atas: $up kali (Pastikan posisi kamera sejajar mata)');
      if (down > 0)
        parts.add('Bawah: $down kali (Hindari menunduk; angkat sedikit dagu)');
      if (parts.isEmpty)
        return 'Tidak ada pola melirik yang signifikan terdeteksi.';
      return parts.join(' • ');
    }

    // Tampilkan bottom sheet modern (dari bawah ke atas) menggunakan DraggableScrollableSheet untuk menghindari overflow
    Get.bottomSheet(
      DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.85,
        builder: (context, scrollCtrl) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // drag indicator & close button
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6E9EE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Hasil Evaluasi Narasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _evaluationSection(
                    icon: Icons.visibility_rounded,
                    title: eyeTitle,
                    reason: eyeReason,
                    suggestion: eyeSuggestion,
                    color: eyeColor,
                  ),

                  const SizedBox(height: 12),

                  // SENYUM: tampilkan ringkasan senyum jika tersedia
                  (() {
                    final smile = controller.detectionResult.value?.smileResult;
                    if (smile == null) return const SizedBox.shrink();
                    final reason =
                        'Jumlah Senyum: ${smile.totalSmiles} (Asli/Kredibel: ${smile.totalAuthentic}, Palsu/Kurang Kredibel: ${smile.totalFake})';
                    return _evaluationSection(
                      icon: Icons.emoji_emotions,
                      title: 'SENYUM — ${smile.dominantLabel}',
                      reason: reason,
                      suggestion: smile.suggestion ?? '',
                      color: Colors.orange,
                    );
                  }()),

                  const SizedBox(height: 12),

                  // Broken down gaze/break counts with suggestions
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detail Melirik & Saran',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total gangguan pandangan: $totalBreaks',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _breaksSummary(),
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Saran umum:',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '• Latih menjaga posisi kepala dan kamera tetap stabil.',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• Saat berpikir, gunakan jeda singkat untuk melihat ke bawah atau samping lalu kembali ke kamera agar tidak terlihat menghindar.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Arti Label Kontak Mata',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _eyeContactLabelGuide(
                    title: 'Terlalu Sedikit (<70%)',
                    description:
                        'Kontak mata yang terlalu sedikit dapat terlihat seperti menghindari lawan bicara atau kurang yakin.',
                    color: _success,
                  ),
                  const SizedBox(height: 8),
                  _eyeContactLabelGuide(
                    title: 'Ideal (70-80%)',
                    description:
                        'Kontak mata seimbang menunjukkan fokus, rasa percaya diri, dan tetap terasa natural.',
                    color: _success,
                  ),
                  const SizedBox(height: 8),
                  _eyeContactLabelGuide(
                    title: 'Terlalu Banyak (>80%)',
                    description:
                        'Tatapan yang terlalu menetap dapat terasa kaku, menakutkan, atau mengintimidasi.',
                    color: _success,
                  ),

                  const SizedBox(height: 18),

                  // Tombol tutup di bawah (opsional)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGold,
                        foregroundColor: _primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _evaluationSection({
    required IconData icon,
    required String title,
    required String reason,
    required String suggestion,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(reason, style: const TextStyle(fontSize: 12, height: 1.35)),
          const SizedBox(height: 8),
          Text(
            'Saran: $suggestion',
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eyeContactLabelGuide({
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: _textDark, fontSize: 12, height: 1.35),
          children: [
            TextSpan(
              text: '$title: ',
              style: TextStyle(fontWeight: FontWeight.w800, color: color),
            ),
            TextSpan(text: description),
          ],
        ),
      ),
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

  // ===== EYE CONTACT RESULT CARD (Hasil Akhir) =====
  Widget _eyeContactResultCard() {
    return Obx(() {
      final d = controller.detect;
      final savedEyeResult = controller.detectionResult.value?.eyeContact;
      final label = savedEyeResult?.conclusion ?? d.eyeStatusText.value;
      final displayLabel = _eyeContactDisplayLabel(label);
      final percentage =
          savedEyeResult?.focusPercentage ?? d.getFocusPercentage();
      final displayDescription = _eyeContactResultDescription(
        label,
        percentage,
      );
      final totalBreaks = savedEyeResult?.totalBreaks ?? d.getTotalBreaks();
      final right = d.getRightBreaks();
      final left = d.getLeftBreaks();
      final up = d.getUpBreaks();
      final down = d.getDownBreaks();

      const color = _success;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👀 KONTAK MATA',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    displayLabel,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Persentase Fokus Akhir: ${percentage.toStringAsFixed(1)}% / 80% (rentang ideal)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: _textMuted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statChip('Total Melirik', '$totalBreaks', color),
                      if (right > 0)
                        _statChip('Kanan', '$right', Colors.orange),
                      if (left > 0) _statChip('Kiri', '$left', Colors.orange),
                      if (up > 0) _statChip('Atas', '$up', Colors.orange),
                      if (down > 0) _statChip('Bawah', '$down', Colors.orange),
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

  String _eyeContactDisplayLabel(String label) {
    switch (label) {
      case 'Terlalu Sedikit':
        return 'Kontak Mata Terlalu Sedikit';
      case 'Terlalu Lama':
        return 'Anda Terlalu Fokus';
      case 'Ideal':
        return 'Kontak Mata Ideal';
      default:
        return label.isEmpty ? 'Kontak Mata Tidak Terdeteksi' : label;
    }
  }

  String _eyeContactResultDescription(String label, double percentage) {
    final pctStr = '${percentage.toStringAsFixed(1)}% / 80% (rentang ideal)';
    if (label == 'Terlalu Lama') {
      return 'Anda menatap layar terlalu lama ($pctStr). Dampak: tatapan dapat terasa kaku atau mengintimidasi. Saran: alihkan pandangan singkat secara natural saat berpikir, lalu kembali ke kamera.';
    }
    if (label == 'Terlalu Sedikit') {
      return 'Pandangan ke layar masih terlalu sedikit ($pctStr). Dampak: kurang terhubung dengan audiens. Saran: coba tingkatkan frekuensi melihat kamera saat menyampaikan poin penting.';
    }
    return 'Kontak mata Anda sudah seimbang dan natural ($pctStr). Pertahankan pola ini.';
  }

  Widget _smileExpressionResultCard() {
    return Obx(() {
      final smile = controller.detectionResult.value?.smileResult;
      final total = smile?.totalSmiles ?? controller.detect.getTotalSmiles();
      final label =
          smile?.dominantLabel ??
          (total > 0 ? 'Tersenyum' : 'Belum ada deteksi senyum');
      final suggestion =
          smile?.suggestion ??
          (total > 0
              ? 'Terlihat tersenyum — pertahankan ekspresi natural.'
              : 'Cobalah tersenyum dengan natural saat menjawab agar ekspresi Anda lebih hangat.');
      final color = total > 0 ? _primaryGold : _textMuted;

      return Container(
        padding: const EdgeInsets.all(16),
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
                Icon(Icons.emoji_emotions, color: _primaryGold, size: 22),
                const SizedBox(width: 10),
                const Text(
                  '😊 Ekspresi Senyum',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statChip('Total Senyum', '$total', _primaryGold),
                if (smile != null) ...[
                  _statChip(
                    'Senyum Asli (Kredibel, Dapat Dipercaya, Tulus, dan Autentik)',
                    '${smile.totalAuthentic}',
                    _success,
                  ),
                  _statChip(
                    'Senyum Palsu (Kurang Kredibel dan Kurang Dapat Dipercaya)',
                    '${smile.totalFake}',
                    _warning,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              suggestion,
              style: const TextStyle(
                fontSize: 12,
                color: _textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ===== SPEECH METRICS CARD =====
  Widget _speechMetricsCard(BuildContext context) {
    return Obx(() {
      final perQuestionDetails = controller.getPerQuestionDetails();
      final avgWpm = controller.wordsPerMinute.value;

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
                  color: _primaryBlue,
                  subtitle: '',
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
            if (perQuestionDetails.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              const Text(
                'WPM per Pertanyaan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              ...perQuestionDetails.map(
                (detail) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${detail['number']}',
                          style: const TextStyle(
                            color: _primaryBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Pertanyaan',
                          style: TextStyle(fontSize: 13, color: _textMuted),
                        ),
                      ),
                      Text(
                        '${detail['wpm']} WPM',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                    'Panduan Kecepatan Bicara',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Gunakan 120–160 WPM sebagai rentang latihan wawancara: cukup cepat untuk menjaga momentum, namun masih memberi ruang bagi pewawancara untuk mengikuti dan mencatat poin Anda.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _wpmStandardChip(
                        'Terlalu Lambat',
                        '< 120',
                        const Color(0xFFEF4444),
                      ),
                      _wpmStandardChip(
                        'Ideal',
                        '120 - 160',
                        const Color(0xFF10B981),
                      ),
                      _wpmStandardChip(
                        'Terlalu Cepat',
                        '> 160',
                        const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '• Jika >160 WPM: terlalu cepat. Tambahkan jeda satu detik setelah poin penting.\n'
                    '• Jika <120 WPM: terlalu lambat. Tambahkan energi dan kurangi dead air.\n'
                    '• Pause satu detik setelah poin kuat adalah tanda percaya diri, bukan kelemahan.',
                    style: TextStyle(
                      fontSize: 11,
                      color: _textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (false && perQuestionDetails.isNotEmpty) ...[
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: _primaryGold, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Detail per Pertanyaan',
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
                              width: 100,
                              child: Text(
                                'Pertanyaan',
                                style: _tableHeaderStyle(),
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                'WPM',
                                style: _tableHeaderStyle(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                'Kar.',
                                style: _tableHeaderStyle(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                'Waktu',
                                style: _tableHeaderStyle(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 55,
                              child: Text(
                                'Menengok',
                                style: _tableHeaderStyle(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                'Asli',
                                style: _tableHeaderStyle(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                'Palsu',
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
          if (subtitle.isNotEmpty)
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

  // ===== PER QUESTION ROW (dengan kolom Menengok) =====
  Widget _perQuestionRow(Map<String, dynamic> detail) {
    final wpm = detail['wpm'] as int;
    final wpmColor = controller.getWpmColor(wpm);
    final wpmRating = controller.getWpmRating(wpm);
    final breaks = detail['breaks'] as int;
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
            width: 100,
            child: Text(
              questionText,
              style: const TextStyle(fontSize: 11, color: _textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 50,
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
            width: 40,
            child: Text(
              '${detail['wordCount']}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              _formatDuration(detail['speakingSeconds']),
              style: const TextStyle(fontSize: 12, color: _textMuted),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 55,
            child: Text(
              '$breaks',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              '${detail['authentic'] ?? 0}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _success,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              '${detail['fake'] ?? 0}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _warning,
              ),
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

  // ===== QA HISTORY WITH CORRECTIONS =====
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
            ...corrections.asMap().entries.map(
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
            ),
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

  // ============================================================
  // HEADER & BUTTONS
  // ============================================================
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

// ============================================================
// LOADING DOT ANIMATION
// ============================================================
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
