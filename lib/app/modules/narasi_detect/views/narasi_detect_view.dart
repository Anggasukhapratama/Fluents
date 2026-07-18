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
            // Kamera Preview
            _buildCameraPreview(context),

            // Overlay gradient
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

            // Notifikasi
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: _buildNotification(),
            ),

            // Status Card
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
      if (!controller.isCameraReady.value ||
          controller.cameraController == null) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: _primaryGold),
                SizedBox(height: 16),
                Text(
                  'Menyiapkan kamera...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }
      final size = MediaQuery.of(context).size;
      final cam = controller.cameraController!;
      return SizedBox(
        width: size.width,
        height: size.height,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 100,
            child: AspectRatio(
              aspectRatio: 1 / cam.value.aspectRatio,
              child: CameraPreview(cam),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNotification() {
    return Obx(() {
      final notif = controller.notificationMessage.value;
      if (notif.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _primaryGold,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryGold.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notif,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ============================================================
  // STATUS CARD - LABEL SESUAI HRD
  // Kontak Mata: 2 label (Fokus terhadap Pewawancara / Tidak Fokus)
  // Ekspresi: 3 label (Ramah dan Profesional / Terlalu Tegang / Tidak Proporsional)
  // Postur: 2 label (Sikap Profesional / Kurang Tenang)
  // TANPA OVERALL LABEL
  // ============================================================
  Widget _buildStatusCard() {
    return Obx(() {
      final d = controller;

      // Hitung status
      final eyeTotal =
          d.lookAwayLeftCount.value +
          d.lookAwayRightCount.value +
          d.lookDownCount.value;
      final headTotal =
          d.headTiltLeftCount.value +
          d.headTiltRightCount.value +
          d.headDownCount.value;
      final enthusiasmMoments = d.enthusiasmMomentCount.value;

      // KONTAK MATA - 2 label
      String eyeLabel, eyeFeedback;
      Color eyeColor;
      if (eyeTotal <= 3) {
        eyeLabel = "Fokus terhadap Pewawancara";
        eyeColor = _success;
        eyeFeedback = "Kontak mata sangat baik! Fokus ke kamera.";
      } else {
        eyeLabel = "Tidak Fokus";
        eyeColor = _danger;
        eyeFeedback =
            "Terlalu sering mengalihkan pandangan. Latih kontak mata!";
      }

      // EKSPRESI - 3 label
      String smileLabel, smileFeedback;
      Color smileColor;
      if (enthusiasmMoments >= 2 && enthusiasmMoments <= 5) {
        smileLabel = "Ramah dan Profesional";
        smileColor = _success;
        smileFeedback = "Ekspresi Anda natural dan profesional. Pertahankan!";
      } else if (enthusiasmMoments >= 10) {
        smileLabel = "Tidak Proporsional";
        smileColor = _danger;
        smileFeedback = "Terlalu sering tersenyum bisa terlihat tidak natural.";
      } else {
        smileLabel = "Terlalu Tegang";
        smileColor = _danger;
        smileFeedback =
            "Ekspresi terlalu tegang. Tunjukkan antusiasme di momen yang tepat.";
      }

      // POSTUR - 2 label
      String postureLabel, postureFeedback;
      Color postureColor;
      if (headTotal <= 3) {
        postureLabel = "Sikap Profesional";
        postureColor = _success;
        postureFeedback = "Postur tubuh sangat baik, menunjukkan ketenangan.";
      } else {
        postureLabel = "Kurang Tenang";
        postureColor = _danger;
        postureFeedback =
            "Terlalu banyak gerakan. Duduk tegak dan tarik napas.";
      }

      // HAPUS: totalPoints, maxPoints, dll

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
            // Header (HAPUS totalPoints/maxPoints)
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
                    Icons.analytics_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Real-time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '⏱️ 5 menit • 5 pertanyaan',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                // HAPUS: Container totalPoints/$maxPoints
              ],
            ),
            const SizedBox(height: 20),

            // Deteksi Wajah (tetap)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: d.isFaceDetected.value
                    ? _success.withOpacity(0.1)
                    : _danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: d.isFaceDetected.value ? _success : _danger,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    d.isFaceDetected.value ? Icons.face : Icons.face_outlined,
                    color: d.isFaceDetected.value ? _success : _danger,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      d.isFaceDetected.value
                          ? 'Wajah terdeteksi dengan baik'
                          : 'Wajah tidak terdeteksi - pastikan wajah terlihat jelas',
                      style: TextStyle(
                        color: d.isFaceDetected.value ? _success : _danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3 kartu (tanpa poin)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildLabelCard(
                    title: 'KONTAK MATA',
                    icon: Icons.visibility,
                    label: eyeLabel,
                    color: eyeColor,
                    feedback: eyeFeedback,
                    count: '$eyeTotal x',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildLabelCard(
                    title: 'EKSPRESI',
                    icon: Icons.mood,
                    label: smileLabel,
                    color: smileColor,
                    feedback: smileFeedback,
                    count: '✨ $enthusiasmMoments momen',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildLabelCard(
                    title: 'POSTUR',
                    icon: Icons.accessibility_new,
                    label: postureLabel,
                    color: postureColor,
                    feedback: postureFeedback,
                    count: '$headTotal x',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Motivasi (tetap)
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
                      _getMotivationMessage(
                        eyeTotal,
                        headTotal,
                        enthusiasmMoments,
                      ),
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
                  controller.resetAllCounters();
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

  // ============================================================
  // LABEL CARD - SESUAI HRD
  // ============================================================
  Widget _buildLabelCard({
    required String title,
    required IconData icon,
    required String label,
    required Color color,
    required String feedback,
    required String count,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          // HAPUS: Poin: x/2
          const SizedBox(height: 6),
          Text(
            feedback,
            style: TextStyle(fontSize: 10, color: color, height: 1.2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  // ============================================================
  // HELPER METHODS
  // ============================================================

  Color _getOverallColor(int totalPoints) {
    if (totalPoints >= 5) return const Color(0xFF059669);
    if (totalPoints >= 3) return const Color(0xFF10B981);
    if (totalPoints >= 2) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  IconData _getOverallIcon(int totalPoints) {
    if (totalPoints >= 5) return Icons.emoji_events_rounded;
    if (totalPoints >= 3) return Icons.trending_up_rounded;
    if (totalPoints >= 2) return Icons.check_circle_rounded;
    return Icons.fitness_center_rounded;
  }

  String _getMotivationMessage(int eye, int head, int enthusiasmMoments) {
    // Hitung poin sesuai label HRD
    // Kontak Mata: ≤3 = 2 poin, >3 = 0 poin
    int eyePoints = (eye <= 3) ? 2 : 0;

    // Ekspresi: 2-5 momen = 2 poin, lainnya = 0
    int smilePoints = (enthusiasmMoments >= 2 && enthusiasmMoments <= 5)
        ? 2
        : 0;

    // Postur: ≤3 = 2 poin, >3 = 0 poin
    int headPoints = (head <= 3) ? 2 : 0;

    int totalPoints = eyePoints + smilePoints + headPoints;

    if (totalPoints == 6) {
      return '🌟 Sangat Percaya Diri! Luar biasa, Anda menunjukkan performa sempurna!';
    }
    if (totalPoints >= 4 && totalPoints <= 5) {
      return '✅ Siap Wawancara! Anda menunjukkan kepercayaan diri yang tinggi. Pertahankan!';
    }
    if (totalPoints >= 2 && totalPoints <= 3) {
      return '⚠️ Cukup Baik. Anda sudah di jalur yang tepat. Tingkatkan terus kemampuan Anda!';
    }
    return '💪 Perlu Banyak Latihan. Setiap latihan membawa Anda lebih dekat ke sukses!';
  }
}
