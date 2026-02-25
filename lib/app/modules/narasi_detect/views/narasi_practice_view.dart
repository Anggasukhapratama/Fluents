import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/narasi_practice_controller.dart';

class NarasiPracticeView extends GetView<NarasiPracticeController> {
  const NarasiPracticeView({super.key});

  // ===== Modern clean white theme =====
  static const Color _bg = Color(0xFFF6F7FB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _text = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE7EAF0);

  static const Color _navy = Color(0xFF0B1220);
  static const Color _teal = Color(0xFF14B8A6);
  static const Color _good = Color(0xFF22C55E);
  static const Color _warn = Color(0xFFF59E0B);
  static const Color _bad = Color(0xFFEF4444);
  static const Color _orange = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() {
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
            Obx(
              () =>
                  SimpleConfettiOverlay(show: controller.showCelebration.value),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Step: choose =====
  Widget _choose() {
    return Column(
      children: [
        _topBar(
          title: 'Latihan Narasi',
          subtitle: 'Baca teks narasi seperti simulasi interview',
          actions: [
            _muteButton(),
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
                  title: 'Mode Latihan',
                  subtitle:
                      'Kamu akan membaca 1 kalimat dalam beberapa detik.\nSistem menilai: Mulut, Kepala, Postur, Kontak Mata, WPM & Fluency.',
                  icon: Icons.record_voice_over_outlined,
                ),
                const SizedBox(height: 14),
                _bigBtn(
                  title: 'Medium',
                  subtitle: 'Narasi perkenalan + beberapa kalimat acak',
                  icon: Icons.bolt,
                  onTap: controller.pickMedium,
                ),
                const SizedBox(height: 12),
                _bigBtn(
                  title: 'Hard',
                  subtitle: 'Narasi lebih panjang + variasi acak',
                  icon: Icons.local_fire_department_outlined,
                  onTap: controller.pickHard,
                ),
                const SizedBox(height: 12),
                _bigBtn(
                  title: 'Custom',
                  subtitle: 'Tulis narasi sendiri',
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
          title: 'Custom Narasi',
          subtitle: 'Tulis naskah narasi kamu (1 kalimat per baris)',
          actions: [
            _muteButton(),
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
    final camH = screenH * 0.40;

    return Column(
      children: [
        _topBar(
          title: 'Narasi Practice',
          subtitle: 'Baca jelas, tenang, dan percaya diri',
          actions: [
            _muteButton(),
            IconButton(
              onPressed: controller.detect.switchCamera,
              icon: const Icon(Icons.cameraswitch, color: _text),
            ),
          ],
        ),

        // Camera area
        Container(
          height: camH,
          alignment: Alignment.center,
          child: Stack(
            children: [
              Center(
                child: Obx(() {
                  final cam = controller.detect.cameraController;
                  if (cam == null || !controller.detect.isCameraReady.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final double aspectRatio = cam.value.aspectRatio;

                  return Container(
                    width: camH * aspectRatio,
                    height: camH,
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
                          AspectRatio(
                            aspectRatio: aspectRatio,
                            child: CameraPreview(cam),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.18),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.22),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: _orange.withOpacity(0.95),
                                    width: 2.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              // Pills status
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

              // ✅ TRANSCRIPT OVERLAY (STT) - INI YANG HILANG
              Positioned(
                left: 18,
                right: 18,
                bottom: 14,
                child: Obx(() {
                  final text = controller.currentLineRecognized.value.trim();
                  final show = text.isNotEmpty;

                  return AnimatedOpacity(
                    opacity: show ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 160),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _orange.withOpacity(0.9),
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.22),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        text.isEmpty ? '...' : text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Panel bawah
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
                  Obx(() {
                    final total = controller.scriptLines.isEmpty
                        ? 1
                        : controller.scriptLines.length;
                    final curr = controller.currentIndex.value + 1;
                    final prog = (curr / total).clamp(0.0, 1.0);

                    return Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Progress',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _text,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$curr/$total',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: prog,
                            minHeight: 8,
                            backgroundColor: _bg,
                            color: _orange,
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 14),

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
      final eye = d.eyeContactRatio.value.clamp(0, 1);
      final eyePct = (eye * 100).toStringAsFixed(0);
      final eyeStatus = d.eyeStatus;

      final mouthStatus = mouthRatio >= 0.22 ? 'Bicara' : 'Diam';
      final tiltStatus = tiltAbs >= 10 ? 'Miring' : 'Lurus';
      final postureStatus = posture >= 0.55 ? 'Miring' : 'Tegak';

      final eyeColor = (eye >= 0.75)
          ? _good
          : (eye >= 0.50)
          ? _warn
          : _bad;

      return Column(
        children: [
          Row(
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
                  'Kepala',
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
          ),
          const SizedBox(height: 10),

          // eye contact bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Icon(Icons.remove_red_eye_outlined, color: eyeColor, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Kontak Mata',
                  style: TextStyle(fontWeight: FontWeight.w900, color: _text),
                ),
                const Spacer(),
                Text(
                  '$eyeStatus • $eyePct%',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: eyeColor,
                  ),
                ),
              ],
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

  // ===== Step: result =====
  Widget _result() {
    return Column(
      children: [
        _topBar(
          title: 'Hasil Latihan',
          subtitle: 'Skor dan saran perbaikan',
          actions: [
            _muteButton(),
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
                // Ringkasan skor
                _card(
                  child: Obx(() {
                    final d = controller.detect;

                    // total confidence label + score
                    final totalLabel = controller.confidenceTotalLabel.value;
                    final totalScore = controller.confidenceTotalSesi.value;

                    final Color confColor = (totalScore >= 70)
                        ? _good
                        : (totalScore >= 45)
                        ? _warn
                        : _bad;

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
                        _row('Kepala', '${d.scoreTilt.value}/100'),
                        _row('Postur', '${d.scorePosture.value}/100'),
                        _row('Kontak Mata', '${d.scoreEye.value}/100'),

                        const Divider(height: 24),

                        // Confidence TOTAL SESI
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Confidence Total Sesi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _muted,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: confColor.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: confColor.withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                '$totalLabel (${totalScore.toStringAsFixed(2)})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: confColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        _row(
                          'Realtime (Nervous)',
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

                // Saran perbaikan
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

                // Hasil rekaman STT
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

  // =========================
  // ✅ MUTE BUTTON WIDGET
  // =========================
  Widget _muteButton() {
    return Obx(() {
      final enabled = controller.soundEnabled.value;
      return IconButton(
        tooltip: enabled ? 'Sound ON' : 'Sound OFF',
        onPressed: () {
          controller.toggleSound();
          final onNow = controller.soundEnabled.value;
          Get.snackbar(
            'Suara',
            onNow ? 'Sound diaktifkan 🔊' : 'Sound dimatikan 🔇',
            duration: const Duration(seconds: 1),
          );
        },
        icon: Icon(
          enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          color: enabled ? _navy : _muted,
        ),
      );
    });
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
        border: Border.all(color: _border),
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

// ================== SIMPLE CONFETTI (NO PACKAGE) ==================

class SimpleConfettiOverlay extends StatefulWidget {
  final bool show;
  const SimpleConfettiOverlay({super.key, required this.show});

  @override
  State<SimpleConfettiOverlay> createState() => _SimpleConfettiOverlayState();
}

class _SimpleConfettiOverlayState extends State<SimpleConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _rnd = Random();
  late List<_P> _p;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addListener(() => setState(() {}));

    _p = List.generate(90, (_) {
      return _P(
        x: _rnd.nextDouble(),
        y: -_rnd.nextDouble() * 0.3,
        vx: (_rnd.nextDouble() - 0.5) * 0.25,
        vy: 0.35 + _rnd.nextDouble() * 0.55,
        size: 2.5 + _rnd.nextDouble() * 4.5,
        rot: _rnd.nextDouble() * 6.0,
      );
    });
  }

  @override
  void didUpdateWidget(covariant SimpleConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();
    return IgnorePointer(
      child: Positioned.fill(
        child: CustomPaint(painter: _ConfettiPainter(_p, _c.value)),
      ),
    );
  }
}

class _P {
  double x, y, vx, vy, size, rot;
  _P({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rot,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_P> p;
  final double t;
  _ConfettiPainter(this.p, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
      const Color(0xFFF59E0B),
      const Color(0xFF22C55E),
      const Color(0xFF0EA5E9),
    ];

    for (int i = 0; i < p.length; i++) {
      final pp = p[i];
      final x = (pp.x + pp.vx * t) * size.width;
      final y = (pp.y + pp.vy * t) * size.height;
      final fade = (1.0 - t).clamp(0.0, 1.0);

      paint.color = colors[i % colors.length].withOpacity(0.95 * fade);

      final r = Rect.fromCenter(
        center: Offset(x, y),
        width: pp.size,
        height: pp.size * (1.6 + (i % 3) * 0.2),
      );

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(pp.rot + t * 10);
      canvas.translate(-x, -y);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
