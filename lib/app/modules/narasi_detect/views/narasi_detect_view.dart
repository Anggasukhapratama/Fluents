// lib/app/views/narasi_detect_view.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/narasi_detect_controller.dart';
import 'narasi_practice_view.dart';

class NarasiDetectView extends GetView<NarasiDetectController> {
  const NarasiDetectView({super.key});

  static const Color _primaryDark = Color(0xFF0A2540);
  static const Color _primaryGold = Color(0xFFD4AF37);
  static const Color _surfaceLight = Color(0xFFF8FAFE);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceLight,
      body: SafeArea(
        child: Stack(
          children: [
            _buildCameraPreview(context),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, _primaryDark.withOpacity(0.7)],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _buildStatusCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(BuildContext context) {
    return Obx(() {
      final cam = controller.cameraController;
      if (cam == null || !controller.isCameraReady.value) {
        return Container(
          color: _primaryDark,
          child: const Center(
            child: CircularProgressIndicator(color: _primaryGold),
          ),
        );
      }
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: 100,
          child: AspectRatio(
            aspectRatio: 1 / cam.value.aspectRatio,
            child: CameraPreview(cam),
          ),
        ),
      );
    });
  }

  // ============================================================
  // STATUS CARD (Menggunakan getter baru)
  // ============================================================
  Widget _buildStatusCard() {
    return Obx(() {
      final d = controller;
      final eyeLabel = d.eyeStatusText.value;
      final warning = d.eyeWarning.value;
      final totalBreaks = d.getTotalBreaks(); // <-- Ganti getBreakCount
      final rightBreaks = d.getRightBreaks(); // tambahan untuk arah
      final leftBreaks = d.getLeftBreaks();
      final upBreaks = d.getUpBreaks();
      final downBreaks = d.getDownBreaks();
      final isFaceDetected = d.isFaceDetected.value;

      Color labelColor;
      IconData statusIcon;
      String statusDesc;

      if (eyeLabel == 'Ideal') {
        labelColor = _success;
        statusIcon = Icons.check_circle;
        statusDesc =
            '✅ Kontak mata ideal menunjukkan kepercayaan diri dan keterbukaan.';
      } else if (eyeLabel == 'Terlalu Lama') {
        labelColor = _warning;
        statusIcon = Icons.warning_amber_rounded;
        statusDesc =
            '🟠 Terlalu banyak kontak mata bisa dianggap menakutkan atau mengintimidasi.';
      } else if (eyeLabel == 'Terlalu Sedikit') {
        labelColor = _danger;
        statusIcon = Icons.error_outline;
        statusDesc =
            '🔴 Kontak mata yang konsisten dan tidak terlalu lama meningkatkan rasa percaya. Terlalu sedikit kontak mata dianggap menghindari atau tidak jujur.';
      } else {
        labelColor = _textMuted;
        statusIcon = Icons.hourglass_empty;
        statusDesc = '⏳ Menunggu...';
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kontak Mata',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '⏱️ 5 pertanyaan • 30 detik/jawaban',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Deteksi wajah
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFaceDetected
                    ? _success.withOpacity(0.1)
                    : _danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isFaceDetected ? _success : _danger),
              ),
              child: Row(
                children: [
                  Icon(
                    isFaceDetected ? Icons.face : Icons.face_outlined,
                    color: isFaceDetected ? _success : _danger,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isFaceDetected
                          ? '✅ Wajah terdeteksi'
                          : '❌ Wajah tidak terdeteksi',
                      style: TextStyle(
                        color: isFaceDetected ? _success : _danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Status kontak mata (dengan label dan total break)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: labelColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: labelColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(statusIcon, color: labelColor),
                      const SizedBox(width: 8),
                      Text(
                        eyeLabel.isEmpty ? 'Menunggu...' : eyeLabel,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: labelColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    warning.isEmpty ? statusDesc : warning,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tampilkan total break dan rincian arah
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip('Total', '$totalBreaks', labelColor),
                      if (rightBreaks > 0)
                        _chip('Kanan', '$rightBreaks', Colors.orange),
                      if (leftBreaks > 0)
                        _chip('Kiri', '$leftBreaks', Colors.orange),
                      if (upBreaks > 0)
                        _chip('Atas', '$upBreaks', Colors.orange),
                      if (downBreaks > 0)
                        _chip('Bawah', '$downBreaks', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Motivasi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _primaryDark.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primaryGold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: _primaryGold, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getMotivationMessage(eyeLabel, totalBreaks),
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Mulai
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  controller.resetCounters();
                  Get.to(() => NarasiPracticeView());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'MULAI LATIHAN INTERVIEW',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _getMotivationMessage(String label, int totalBreaks) {
    if (label == 'Ideal') {
      return '🌟 Kontak mata ideal menunjukkan kepercayaan diri dan keterbukaan. Pertahankan! (Melirik $totalBreaks kali)';
    } else if (label == 'Terlalu Lama') {
      return '🟠 Terlalu banyak kontak mata bisa dianggap menakutkan atau mengintimidasi. Coba alihkan sesekali. (Melirik $totalBreaks kali)';
    } else if (label == 'Terlalu Sedikit') {
      return '🔴 Kontak mata yang konsisten meningkatkan rasa percaya. Terlalu sedikit dianggap menghindar. (Melirik $totalBreaks kali)';
    } else {
      return '🎯 Pastikan wajah terlihat jelas di kamera.';
    }
  }

  // Helper untuk chip kecil
  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
