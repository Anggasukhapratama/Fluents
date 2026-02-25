import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/narasi_practice_controller.dart';

class NarasiPracticeView extends GetView<NarasiPracticeController> {
  const NarasiPracticeView({super.key});

  // ✅ Modern clean white theme (elegan, nggak merah)
  static const Color _bg = Color(0xFFF6F7FB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _text = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE7EAF0);

  static const Color _navy = Color(0xFF0B1220); // primary accent
  static const Color _teal = Color(0xFF14B8A6); // secondary accent
  static const Color _good = Color(0xFF22C55E);
  static const Color _warn = Color(0xFFF59E0B);
  static const Color _bad = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Obx(() {
          switch (controller.step.value) {
            case PracticeStep.choose:
              return _choose();
            case PracticeStep.customInput:
              return _custom();
            case PracticeStep.countdown:
              return _countdown();
            case PracticeStep.practice:
              return _practice(context);
            case PracticeStep.result:
              return _result();
          }
        }),
      ),
    );
  }

  // ===== Step: choose =====
  Widget _choose() {
    return Column(
      children: [
        _topBar(
          title: 'Simulasi Interview',
          subtitle: 'Pilih mode latihan untuk mulai',
          actions: [
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close, color: _text),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _heroCard(
                  title: 'Siap untuk Interview?',
                  subtitle:
                      'Kamu akan membaca 1 kalimat selama 5 detik.\nSistem menilai: Mulut, Tilt Kepala, Postur, WPM & Fluency.',
                  icon: Icons.work_outline,
                ),
                const SizedBox(height: 14),
                _bigBtn(
                  title: 'Medium',
                  subtitle: 'Latihan dasar perkenalan',
                  icon: Icons.bolt,
                  onTap: controller.pickMedium,
                ),
                const SizedBox(height: 12),
                _bigBtn(
                  title: 'Hard',
                  subtitle: 'Latihan lebih panjang & menantang',
                  icon: Icons.local_fire_department_outlined,
                  onTap: controller.pickHard,
                ),
                const SizedBox(height: 12),
                _bigBtn(
                  title: 'Custom',
                  subtitle: 'Tulis naskah kamu sendiri',
                  icon: Icons.edit_outlined,
                  onTap: controller.pickCustom,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===== Step: custom input =====
  Widget _custom() {
    return Column(
      children: [
        _topBar(
          title: 'Custom Script',
          subtitle: 'Tulis naskah interview kamu',
          actions: [
            IconButton(
              onPressed: controller.backToChoose,
              icon: const Icon(Icons.arrow_back, color: _text),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _card(
                  child: TextField(
                    controller: controller.customTextController,
                    maxLines: 12,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText:
                          'Pisahkan per kalimat dengan ENTER.\n\nContoh:\nPerkenalkan nama saya...\nSaya lulusan...\nPengalaman saya...',
                    ),
                    style: const TextStyle(color: _text),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.backToChoose,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _navy,
                          side: const BorderSide(color: _border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: _surface,
                        ),
                        child: const Text('Kembali'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: controller.submitCustomAndStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Mulai'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===== Step: countdown =====
  Widget _countdown() {
    return Center(
      child: Obx(() {
        return Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            color: _navy,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              controller.countdown.value.toString(),
              style: const TextStyle(
                fontSize: 78,
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ===== Step: practice =====
  Widget _practice(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final camH = screenH * 0.38; // ✅ diperkecil (sebelumnya 0.44)

    return Column(
      children: [
        _topBar(
          title: 'Interview Practice',
          subtitle: 'Baca dengan percaya diri',
          actions: [
            IconButton(
              onPressed: controller.detect.switchCamera,
              icon: const Icon(Icons.cameraswitch, color: _text),
            ),
          ],
        ),

        // ✅ CAMERA AREA (lebih ramping)
        SizedBox(
          height: camH,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: FractionallySizedBox(
                  widthFactor: 0.90, // ✅ frame lebih kecil/lebar pas
                  child: Obx(() {
                    final cam = controller.detect.cameraController;
                    if (cam == null || !controller.detect.isCameraReady.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _cameraFrame(cam);
                  }),
                ),
              ),

              // ✅ Badge dibuat center (bukan kanan-kiri)
              Positioned(
                top: 14,
                left: 22,
                right: 22,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() {
                        final running = controller.isSessionRunning.value;
                        return _pill(
                          running ? 'Realtime ON' : 'Realtime OFF',
                          running ? _good : _muted,
                          running ? Icons.bolt : Icons.pause_circle,
                        );
                      }),
                      const SizedBox(height: 8),
                      Obx(() {
                        final ns = controller.detect.nervousScore.value;
                        final label = controller.detect.nervousLabel.value;
                        final c = ns >= 75 ? _bad : (ns >= 45 ? _warn : _good);
                        return _pill('$label • $ns/100', c, Icons.insights);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ===== PANEL BAWAH =====
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: const Border(top: BorderSide(color: _border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    'Bacalah Kalimat Ini',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _card(
                    child: Obx(
                      () => Text(
                        controller.currentLine.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                          color: _text,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Obx(() {
                    return Text(
                      'Sisa waktu: ${controller.secondsLeftInLine.value}s • Tenang, jelas, dan tegas.',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _muted,
                      ),
                      textAlign: TextAlign.center,
                    );
                  }),

                  const SizedBox(height: 14),
                  _mlkitTopBoxes(),
                  const SizedBox(height: 14),
                  _speechStats(),
                  const SizedBox(height: 14),
                  _sttPanel(),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: Obx(() {
                      final running = controller.isSessionRunning.value;
                      return ElevatedButton.icon(
                        onPressed: running
                            ? () => controller.stopSession(goResult: true)
                            : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Selesai'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mlkitTopBoxes() {
    return Obx(() {
      final d = controller.detect;

      final mouthRatio = d.mouthOpenRatio.value.clamp(0, 1);
      final tiltAbs = d.headTiltDeg.value.abs();
      final posture = d.postureLeanScore.value.clamp(0, 1);

      final mouthStatus = mouthRatio >= 0.22 ? 'Bicara' : 'Diam';
      final tiltStatus = tiltAbs >= 10 ? 'Miring' : 'Lurus';
      final postureStatus = posture >= 0.55 ? 'Miring' : 'Tegak';

      return Row(
        children: [
          Expanded(
            child: _miniBox(
              'Mulut',
              '${d.scoreMouth.value}/100',
              subtitle: '$mouthStatus • ${mouthRatio.toStringAsFixed(2)}',
              accent: _teal,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _miniBox(
              'Tilt Kepala',
              '${d.scoreTilt.value}/100',
              subtitle: '$tiltStatus • ${tiltAbs.toStringAsFixed(1)}°',
              accent: _navy,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _miniBox(
              'Postur',
              '${d.scorePosture.value}/100',
              subtitle:
                  '$postureStatus • ${(posture * 100).toStringAsFixed(0)}%',
              accent: _teal,
            ),
          ),
        ],
      );
    });
  }

  Widget _speechStats() {
    return Obx(() {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistik Bicara',
              style: TextStyle(fontWeight: FontWeight.w900, color: _text),
            ),
            const SizedBox(height: 10),
            _row('WPM', '${controller.wordsPerMinute.value}'),
            _row('Filler', '${controller.fillerCount.value}x'),
            _row(
              'Fluency',
              '${controller.fluencyScore.value.toStringAsFixed(1)}/100',
            ),
          ],
        ),
      );
    });
  }

  Widget _sttPanel() {
    return _card(
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'STT Kalimat Ini',
              style: TextStyle(fontWeight: FontWeight.w900, color: _text),
            ),
            const SizedBox(height: 8),
            Text(
              controller.currentLineRecognized.value.isEmpty
                  ? '...'
                  : controller.currentLineRecognized.value,
              style: const TextStyle(color: _text),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Step: result =====
  Widget _result() {
    return Column(
      children: [
        _topBar(
          title: 'Hasil Interview Practice',
          subtitle: 'Lihat skor dan saran',
          actions: [
            IconButton(
              onPressed: controller.backToChoose,
              icon: const Icon(Icons.close, color: _text),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _card(
                  child: Obx(() {
                    final d = controller.detect;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan Skor',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _row('Mulut', '${d.scoreMouth.value}/100'),
                        _row('Tilt Kepala', '${d.scoreTilt.value}/100'),
                        _row('Postur', '${d.scorePosture.value}/100'),
                        _row(
                          'Confidence',
                          '${d.nervousLabel.value} (${d.nervousScore.value}/100)',
                        ),
                        const Divider(height: 24),
                        _row('WPM', '${controller.wordsPerMinute.value}'),
                        _row('Filler', '${controller.fillerCount.value}x'),
                        _row(
                          'Fluency',
                          '${controller.fluencyScore.value.toStringAsFixed(1)}/100',
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 12),
                _card(
                  child: Obx(() {
                    final tips = controller.finalSuggestions;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saran Perbaikan',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (tips.isEmpty)
                          const Text(
                            'Belum ada saran.',
                            style: TextStyle(color: _muted),
                          )
                        else
                          ...tips.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '• $t',
                                style: const TextStyle(color: _text),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 12),
                _card(
                  child: Obx(() {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hasil Rekaman (STT)',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.recognizedText.value.isEmpty
                              ? '-'
                              : controller.recognizedText.value,
                          style: const TextStyle(color: _text),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.backToChoose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
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

  // ===== COMMON UI =====
  Widget _topBar({
    required String title,
    required String subtitle,
    required List<Widget> actions,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: _surface,
        border: const Border(bottom: BorderSide(color: _border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w600,
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

  Widget _heroCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: const BorderSide(color: _border).toBorder(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: _navy, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: _muted, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraFrame(CameraController cam) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(cam),

            // overlay halus biar pill kebaca
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.20),
                    Colors.transparent,
                    Colors.black.withOpacity(0.14),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // border tipis elegan
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.40),
                      width: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigBtn({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: _muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _muted),
          ],
        ),
      ),
    );
  }

  Widget _miniBox(
    String title,
    String value, {
    required String subtitle,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w900, color: accent),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  // ✅ pill: center + max width + ellipsis (biar nggak melebar/nyamping)
  Widget _pill(String text, Color color, IconData icon) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.48),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.85)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _muted,
              ),
            ),
          ),
          Text(
            v,
            style: const TextStyle(fontWeight: FontWeight.w900, color: _text),
          ),
        ],
      ),
    );
  }
}

extension _BorderSideExt on BorderSide {
  BoxBorder toBorder() => Border.fromBorderSide(this);
}
