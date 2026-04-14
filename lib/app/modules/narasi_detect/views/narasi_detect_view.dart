import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/narasi_detect_controller.dart';
import 'narasi_practice_view.dart'; // Sesuaikan dengan path import kamu

class NarasiDetectView extends GetView<NarasiDetectController> {
  const NarasiDetectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          if (!controller.isCameraReady.value) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Menyiapkan kamera...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }
          return _buildCameraPreview(context);
        }),
      ),
    );
  }

  Widget _buildCameraPreview(BuildContext context) {
    return Stack(
      children: [
        // Background Kamera Full Screen (Anti Cembung/Melar)
        Positioned.fill(
          child: controller.cameraController != null
              ? _fullScreenCamera(context, controller.cameraController!)
              : Container(color: Colors.black),
        ),

        // Status Card di Atas
        Positioned(top: 20, left: 20, right: 20, child: _buildStatusCard()),

        // Tombol di Bawah
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: _buildBottomButtons(),
        ),
      ],
    );
  }

  // WIDGET KHUSUS AGAR KAMERA TIDAK MELAR DI FULL SCREEN
  Widget _fullScreenCamera(BuildContext context, CameraController cam) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: FittedBox(
        fit: BoxFit
            .cover, // Akan memotong bagian yang berlebih agar tetap proporsional
        child: SizedBox(
          width: 100, // Lebar arbitrer, FittedBox akan menyesuaikannya
          child: AspectRatio(
            aspectRatio: 1 / cam.value.aspectRatio,
            child: CameraPreview(cam),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Obx(() {
      final d = controller;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Analisis HRD',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            // Deteksi Wajah
            Row(
              children: [
                Icon(
                  d.isFaceDetected.value ? Icons.face : Icons.face_outlined,
                  color: d.isFaceDetected.value ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d.isFaceDetected.value
                        ? 'Wajah terdeteksi'
                        : 'Wajah tidak terdeteksi',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),

            // Indikator 3 Poin (Tanpa Stabilitas)
            _buildDetectionRow(
              '👀 Mata',
              d.labelEye.value,
              d.scoreEye.value / 100,
              _getColor(d.scoreEye.value),
            ),
            const SizedBox(height: 8),
            _buildDetectionRow(
              '🧍 Postur',
              d.labelPosture.value,
              d.scorePosture.value / 100,
              _getColor(d.scorePosture.value),
            ),
            const SizedBox(height: 8),
            _buildDetectionRow(
              '😊 Senyum',
              d.labelSmile.value,
              d.scoreSmile.value / 100,
              _getColor(d.scoreSmile.value),
            ),

            const SizedBox(height: 16),

            // Skor Keseluruhan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getConfidenceColor(
                  d.overallConfidence.value,
                ).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getConfidenceColor(d.overallConfidence.value),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Skor Keseluruhan',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.overallConfidence.value.round()}',
                    style: TextStyle(
                      color: _getConfidenceColor(d.overallConfidence.value),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.overallLabel.value,
                    style: TextStyle(
                      color: _getConfidenceColor(d.overallConfidence.value),
                      fontWeight: FontWeight.w600,
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

  Color _getColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 45) return Colors.orange;
    return Colors.red;
  }

  Widget _buildDetectionRow(
    String label,
    String status,
    double value,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80, // Fix width agar bar tidak goyang
          child: Text(
            status,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: controller.switchCamera,
            icon: const Icon(Icons.cameraswitch),
            label: const Text('Kamera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () => Get.to(() => const NarasiPracticeView()),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Mulai Latihan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double value) {
    if (value >= 80) return Colors.green;
    if (value >= 60) return Colors.orange;
    return Colors.red;
  }
}
