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

  Widget _buildStatusCard() {
    return Obx(() {
      final d = controller;

      // Hitung status berdasarkan frekuensi pelanggaran
      final eyeTotal =
          d.lookAwayLeftCount.value +
          d.lookAwayRightCount.value +
          d.lookDownCount.value;
      final headTotal =
          d.headTiltLeftCount.value +
          d.headTiltRightCount.value +
          d.headDownCount.value;
      final enthusiasmMoments = d.enthusiasmMomentCount.value;

      // Label untuk Kontak Mata (3 level)
      String eyeLabel;
      Color eyeColor;
      String eyeFeedback;
      if (eyeTotal <= 3) {
        eyeLabel = "Fokus & Percaya Diri";
        eyeColor = _success;
        eyeFeedback = "Kontak mata sangat baik! Fokus ke kamera.";
      } else if (eyeTotal <= 6) {
        eyeLabel = "Sesekali Terdistraksi";
        eyeColor = _warning;
        eyeFeedback = "Masih ada gerakan mata, coba lebih fokus.";
      } else {
        eyeLabel = "Sering Kehilangan Fokus";
        eyeColor = _danger;
        eyeFeedback =
            "Terlalu sering mengalihkan pandangan. Latih kontak mata!";
      }

      // Label untuk Ekspresi (Berbasis Momen Antusias - Ruben et al., 2015)
      String smileLabel;
      Color smileColor;
      String smileFeedback;
      if (enthusiasmMoments >= 2 && enthusiasmMoments <= 5) {
        smileLabel = "Antusias & Profesional";
        smileColor = _success;
        smileFeedback = "Ekspresi Anda natural dan profesional. Pertahankan!";
      } else if (enthusiasmMoments == 1 ||
          (enthusiasmMoments >= 6 && enthusiasmMoments <= 9)) {
        smileLabel = "Cukup Antusias";
        smileColor = _warning;
        smileFeedback = enthusiasmMoments == 1
            ? "Coba tunjukkan antusiasme lebih sering."
            : "Antusiasme cukup, jangan terlalu sering.";
      } else if (enthusiasmMoments >= 10) {
        smileLabel = "Antusias Berlebihan";
        smileColor = _danger;
        smileFeedback =
            "Terlalu sering tersenyum bisa terlihat tidak natural.";
      } else {
        smileLabel = "Datar & Tegang";
        smileColor = _danger;
        smileFeedback =
            "Ekspresi terlalu datar. Tunjukkan antusiasme di momen yang tepat.";
      }

      // Label untuk Postur (3 level)
      String postureLabel;
      Color postureColor;
      String postureFeedback;
      if (headTotal <= 3) {
        postureLabel = "Tenang & Profesional";
        postureColor = _success;
        postureFeedback = "Postur tubuh sangat baik, menunjukkan ketenangan.";
      } else if (headTotal <= 6) {
        postureLabel = "Sedikit Gelisah";
        postureColor = _warning;
        postureFeedback = "Masih ada gerakan tidak perlu, coba lebih rileks.";
      } else {
        postureLabel = "Gugup & Cemas";
        postureColor = _danger;
        postureFeedback =
            "Terlalu banyak gerakan. Duduk tegak dan tarik napas.";
      }

      // Hitung poin untuk overall status
      int eyePoints = d.getEyeContactPoints();
      int smilePoints = d.getFacialExpressionPoints();
      int posturePoints = d.getPosturePoints();
      int totalPoints = eyePoints + smilePoints + posturePoints;
      bool hasZero = (eyePoints == 0 || smilePoints == 0 || posturePoints == 0);

      String overallLabel;
      Color overallColor;
      if (totalPoints == 6) {
        overallLabel = "🌟 Sangat Percaya Diri";
        overallColor = _success;
      } else if (totalPoints >= 4 && totalPoints <= 5 && !hasZero) {
        overallLabel = "✅ Siap Wawancara";
        overallColor = _success;
      } else if (totalPoints >= 2 && totalPoints <= 3) {
        overallLabel = "⚠️ Cukup Baik";
        overallColor = _warning;
      } else {
        overallLabel = "❌ Perlu Banyak Latihan";
        overallColor = _danger;
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
                      'Total Poin: $totalPoints/6',
                      style: TextStyle(
                        fontSize: 11,
                        color: overallColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: overallColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: overallColor),
                  ),
                  child: Text(
                    overallLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: overallColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Deteksi Wajah
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

            // ===== 3 KARTU PELABELAN =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kontak Mata
                Expanded(
                  child: _buildLabelCard(
                    title: 'KONTAK MATA',
                    icon: Icons.visibility,
                    label: eyeLabel,
                    color: eyeColor,
                    feedback: eyeFeedback,
                    count: '$eyeTotal x',
                    points: eyePoints,
                  ),
                ),
                const SizedBox(width: 10),

                // Ekspresi
                Expanded(
                  child: _buildLabelCard(
                    title: 'EKSPRESI',
                    icon: Icons.mood,
                    label: smileLabel,
                    color: smileColor,
                    feedback: smileFeedback,
                    count: '✨ $enthusiasmMoments momen',
                    points: smilePoints,
                  ),
                ),
                const SizedBox(width: 10),

                // Postur
                Expanded(
                  child: _buildLabelCard(
                    title: 'POSTUR',
                    icon: Icons.accessibility_new,
                    label: postureLabel,
                    color: postureColor,
                    feedback: postureFeedback,
                    count: '$headTotal x',
                    points: posturePoints,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Ringkasan Motivasi
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
                      _getMotivationMessage(eyeTotal, headTotal, enthusiasmMoments),
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

  Widget _buildLabelCard({
    required String title,
    required IconData icon,
    required String label,
    required Color color,
    required String feedback,
    required String count,
    required int points,
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
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Poin: $points/2',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
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

  String _getMotivationMessage(int eye, int head, int enthusiasmMoments) {
    // Hitung poin
    int eyePoints = (eye <= 3) ? 2 : ((eye <= 6) ? 1 : 0);
    // Poin Ekspresi (Berbasis Momen Antusias - Ruben et al., 2015)
    int smilePoints;
    if (enthusiasmMoments >= 2 && enthusiasmMoments <= 5) {
      smilePoints = 2;
    } else if (enthusiasmMoments == 1 ||
        (enthusiasmMoments >= 6 && enthusiasmMoments <= 9)) {
      smilePoints = 1;
    } else {
      smilePoints = 0; // 0 atau 10+
    }
    int headPoints = (head <= 3) ? 2 : ((head <= 6) ? 1 : 0);

    int totalPoints = eyePoints + smilePoints + headPoints;
    bool hasZero = (eyePoints == 0 || smilePoints == 0 || headPoints == 0);

    if (totalPoints == 6) {
      return '🌟 Sangat Percaya Diri! Luar biasa, Anda menunjukkan performa sempurna!';
    }
    if (totalPoints >= 4 && totalPoints <= 5 && !hasZero) {
      return '✅ Siap Wawancara! Anda menunjukkan kepercayaan diri yang tinggi. Pertahankan!';
    }
    if (totalPoints >= 2 && totalPoints <= 3) {
      return '⚠️ Cukup Baik. Anda sudah di jalur yang tepat. Tingkatkan terus kemampuan Anda!';
    }
    return '💪 Perlu Banyak Latihan. Setiap latihan membawa Anda lebih dekat ke sukses!';
  }
}
