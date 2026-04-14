import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/narasi_practice_controller.dart';

class NarasiPracticeView extends GetView<NarasiPracticeController> {
  const NarasiPracticeView({super.key});

  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _text = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _success = Color(0xFF22C55E);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Obx(() {
          switch (controller.step.value) {
            case PracticeStep
                .instructions: // 1. UPDATE: Tambahkan Case Instructions
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

  // 2. FUNGSI BARU: Widget Halaman Instruksi
  Widget _instructionsView(BuildContext context) {
    return Column(
      children: [
        _header(
          title: 'Panduan Latihan',
          subtitle: 'Ikuti langkah berikut untuk hasil terbaik',
          showBack: false,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _instructionCard(
                  icon: Icons.face_retouching_natural,
                  title: 'Posisikan Wajah',
                  desc:
                      'Pastikan wajah terlihat jelas di kamera dan berada di area tengah.',
                  color: _primary,
                ),
                _instructionCard(
                  icon: Icons.accessibility_new,
                  title: 'Jaga Postur Tubuh',
                  desc:
                      'Duduklah dengan tegak. AI akan menilai jika bahu Anda miring atau membungkuk.',
                  color: _success,
                ),
                _instructionCard(
                  icon: Icons.record_voice_over,
                  title: 'Bicara Jelas',
                  desc:
                      'Gunakan suara yang lantang. AI akan mendeteksi kecepatan bicara dan kata pengisi (umm/eh).',
                  color: _warning,
                ),
                _instructionCard(
                  icon: Icons.insights,
                  title: 'Evaluasi Real-time',
                  desc:
                      'Skor akan muncul langsung. Fokuslah pada kamera seolah menatap HRD.',
                  color: _danger,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.startToChoose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'SAYA MENGERTI, LANJUTKAN',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. FUNGSI BARU: Widget Card Instruksi
  Widget _instructionCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: _muted, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chooseLevel(BuildContext context) {
    return Column(
      children: [
        _header(
          title: 'Simulasi Interview HRD',
          subtitle: 'Pilih level kesulitan',
          showBack:
              true, // Diubah menjadi true agar bisa kembali ke instruksi jika diinginkan
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _levelCard(
                  level: 'Medium',
                  desc: 'Pertanyaan perkenalan dasar',
                  icon: Icons.sentiment_satisfied,
                  color: _success,
                  onTap: controller.pickMedium,
                ),
                const SizedBox(height: 14),
                _levelCard(
                  level: 'Hard',
                  desc: 'Pertanyaan lebih dalam',
                  icon: Icons.trending_up,
                  color: _warning,
                  onTap: controller.pickHard,
                ),
                const SizedBox(height: 14),
                _levelCard(
                  level: 'Advance',
                  desc: 'Pertanyaan tekanan tinggi',
                  icon: Icons.workspace_premium,
                  color: _danger,
                  isPremium: true,
                  onTap: controller.pickAdvance,
                ),
                const Spacer(),
                _hintCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _hintCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: const [
          Icon(Icons.lightbulb_outline, color: _primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tips: Tatap kamera, jawab dengan rileks, dan jaga postur tubuh tegak.',
              style: TextStyle(color: _muted, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelCard({
    required String level,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _text,
                        ),
                      ),
                      if (isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _danger,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: _muted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: _muted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _countdown(BuildContext context) {
    return Center(
      child: Obx(
        () => Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            color: _primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.35),
                blurRadius: 26,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              controller.countdown.value.toString(),
              style: const TextStyle(
                fontSize: 72,
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _practice(BuildContext context) {
    return Column(
      children: [
        _header(
          title: 'Interview dengan HRD',
          subtitle: 'Jawab dengan percaya diri',
          showBack: true,
          actions: [
            _muteButton(),
            IconButton(
              onPressed: controller.detect.switchCamera,
              icon: const Icon(Icons.cameraswitch, color: _text),
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
                _questionCard(),
                const SizedBox(height: 12),
                _timerAndProgressRow(),
                const SizedBox(height: 14),
                _threeDetections(),
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
      if (cam == null || !controller.detect.isCameraReady.value) {
        return Container(
          height: camH,
          width: maxW,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      return Container(
        width: maxW,
        height: camH,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
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
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _primary.withOpacity(0.55),
                      width: 2,
                    ),
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
      final conf = d.overallConfidence.value;
      final color = conf >= 75 ? _success : (conf >= 50 ? _warning : _danger);

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _pill(
            icon: Icons.emoji_emotions,
            text: '${d.overallLabel.value} • ${conf.round()}/100',
            color: color,
          ),
          if (controller.isAsking.value)
            _pill(
              icon: Icons.record_voice_over,
              text: 'HRD bertanya...',
              color: _primary,
            ),
          if (controller.isAnswering.value)
            _pill(icon: Icons.mic, text: 'Giliran kamu', color: _success),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _questionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.help_outline, color: _primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Pertanyaan HRD',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Obx(
            () => Text(
              controller.currentLine.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.35,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timelapse, color: _primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '⏱ $secs dtk',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: secs <= 3 ? _danger : _muted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$curr/$total',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: curr / total,
                minHeight: 12,
                backgroundColor: _border,
                color: _primary,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _threeDetections() {
    return Obx(() {
      final d = controller.detect;
      return Row(
        children: [
          Expanded(
            child: _metricCard(
              title: 'Mata',
              icon: '👀',
              score: d.scoreEye.value,
              status: d.labelEye.value,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _metricCard(
              title: 'Postur',
              icon: '🧍',
              score: d.scorePosture.value,
              status: d.labelPosture.value,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _metricCard(
              title: 'Senyum',
              icon: '😊',
              score: d.scoreSmile.value,
              status: d.labelSmile.value,
            ),
          ),
        ],
      );
    });
  }

  Widget _metricCard({
    required String title,
    required String icon,
    required int score,
    required String status,
  }) {
    Color color = score >= 70 ? _success : (score >= 45 ? _warning : _danger);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Text(
            '$icon  $title',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: _muted, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _speechStats() {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            _statCol('WPM', '${controller.wordsPerMinute.value}'),
            _dividerV(),
            _statCol('Filler', '${controller.fillerCount.value}x'),
            _dividerV(),
            _statCol('Fluency', '${controller.fluencyScore.value.round()}'),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String label, String value) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
  Widget _dividerV() => Container(height: 28, width: 1, color: _border);

  Widget _transcriptCard() {
    return Obx(() {
      final tx = controller.currentLineRecognized.value.trim();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.subtitles, color: _primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tx.isEmpty ? 'Teks jawaban akan muncul di sini...' : tx,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tx.isEmpty ? _muted : _text,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
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
        icon: const Icon(Icons.stop),
        label: const Text('Selesai'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _danger,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _result(BuildContext context) {
    return Column(
      children: [
        _header(
          title: 'Hasil Interview',
          subtitle: 'Skor dan evaluasi HRD',
          showBack: true,
          actions: [
            IconButton(
              onPressed: () {
                // Reset step ke instruksi ketika tombol close/latihan lagi ditekan
                controller.stopSession(goResult: false);
                controller.step.value = PracticeStep.instructions;
              },
              icon: const Icon(Icons.close, color: _text),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _overallCard(),
                const SizedBox(height: 16),
                _card(
                  title: 'Detail Penilaian',
                  child: Obx(() {
                    final d = controller.detect;
                    return Column(
                      children: [
                        _scoreRow(
                          '👀 Kontak Mata',
                          '${d.scoreEye.value}/100',
                          d.labelEye.value,
                        ),
                        _scoreRow(
                          '🧍 Postur Tubuh',
                          '${d.scorePosture.value}/100',
                          d.labelPosture.value,
                        ),
                        _scoreRow(
                          '😊 Senyum',
                          '${d.scoreSmile.value}/100',
                          d.labelSmile.value,
                        ),
                        const Divider(height: 24),
                        _scoreRow(
                          '⚡ WPM (Kecepatan)',
                          '${controller.wordsPerMinute.value}',
                          '',
                        ),
                        _scoreRow(
                          '🗣️ Filler (Umm/Ah)',
                          '${controller.fillerCount.value}x',
                          '',
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 14),
                _card(
                  title: 'Saran Perbaikan (HRD Feedback)',
                  child: Obx(() {
                    final tips = controller.finalSuggestions;
                    return Column(
                      children: tips.isEmpty
                          ? [const Text('Sempurna!')]
                          : tips
                                .map(
                                  (t) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '• ',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        Expanded(
                                          child: Text(
                                            t,
                                            style: const TextStyle(
                                              height: 1.25,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                    );
                  }),
                ),
                const SizedBox(height: 14),

                _qaHistoryCard(),

                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Reset step ke instruksi
                      controller.stopSession(goResult: false);
                      controller.step.value = PracticeStep.instructions;
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Latihan Lagi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _qaHistoryCard() {
    return Obx(() {
      final history = controller.qaHistory;

      if (history.isEmpty) {
        return _card(
          title: 'Riwayat Tanya Jawab',
          child: const Text(
            'Tidak ada jawaban yang terekam.',
            style: TextStyle(color: _muted),
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Tanya Jawab',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...history.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Q: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _primary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item['q'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _text,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'A: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _success,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item['a'] ?? '',
                            style: const TextStyle(color: _muted, height: 1.3),
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

  Widget _overallCard() {
    return Obx(() {
      final conf = controller.detect.overallConfidence.value;
      final color = conf >= 80 ? _success : (conf >= 60 ? _warning : _danger);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.insights, color: color, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Skor Evaluasi HRD',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${conf.round()}/100 • ${controller.detect.overallLabel.value}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: color,
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

  Widget _header({
    required String title,
    required String subtitle,
    bool showBack = false,
    List<Widget> actions = const [],
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              // 4. UPDATE TOMBOL KEMBALI: Diarahkan kembali ke instruksi atau stop sesi
              onPressed: () {
                if (controller.step.value == PracticeStep.choose) {
                  controller.step.value = PracticeStep.instructions;
                } else {
                  controller.backToChoose();
                }
              },
              icon: const Icon(Icons.arrow_back),
              color: _text,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: _muted)),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }

  Widget _muteButton() => Obx(
    () => IconButton(
      onPressed: controller.toggleSound,
      icon: Icon(
        controller.soundEnabled.value ? Icons.volume_up : Icons.volume_off,
        color: controller.soundEnabled.value ? _primary : _muted,
      ),
    ),
  );

  Widget _card({required String title, required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );

  Widget _scoreRow(String label, String value, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: _muted)),
          ),
          Text('$value ', style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(status, style: const TextStyle(color: _primary, fontSize: 12)),
        ],
      ),
    );
  }
}
