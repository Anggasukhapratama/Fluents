// lib/app/views/narasi_detect_view.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/narasi_detect_controller.dart';
import 'narasi_practice_view.dart';

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
        // Kamera Full Screen
        Positioned.fill(
          child: controller.cameraController != null
              ? _fullScreenCamera(context, controller.cameraController!)
              : Container(color: Colors.black),
        ),

        // Notifikasi Real-time (Toast)
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Obx(() {
            final notif = controller.notificationMessage.value;
            if (notif.isEmpty) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
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
          }),
        ),

        // Status Card di Bawah (tanpa skor angka)
        Positioned(bottom: 30, left: 20, right: 20, child: _buildStatusCard()),
      ],
    );
  }

  Widget _fullScreenCamera(BuildContext context, CameraController cam) {
    final size = MediaQuery.of(context).size;
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
  }

  Widget _buildStatusCard() {
    return Obx(() {
      final d = controller;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blueAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'PELANGGARAN PERILAKU',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Wajah (deteksi/tidak)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: d.isFaceDetected.value
                    ? Colors.green.withOpacity(0.15)
                    : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: d.isFaceDetected.value ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    d.isFaceDetected.value ? Icons.face : Icons.face_outlined,
                    color: d.isFaceDetected.value ? Colors.green : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      d.isFaceDetected.value
                          ? '✅ Wajah Terdeteksi'
                          : '❌ Wajah Tidak Terdeteksi',
                      style: TextStyle(
                        color: d.isFaceDetected.value
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3 Kategori Counter (hanya frekuensi, tanpa skor)
            Row(
              children: [
                Expanded(
                  child: _counterCard(
                    icon: '👀',
                    title: 'KONTAK MATA',
                    items: [
                      'Mengalihkan pandangan: ${d.lookAwayCount.value}x',
                      'Menunduk: ${d.lookDownCount.value}x',
                    ],
                    color: d.totalEyeViolations > 3
                        ? Colors.red
                        : (d.totalEyeViolations > 0
                              ? Colors.orange
                              : Colors.green),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _counterCard(
                    icon: '😊',
                    title: 'EKSPRESI',
                    items: [
                      'Tersenyum: ${d.smileCount.value}x',
                      'Wajah datar: ${d.neutralCount.value}x',
                    ],
                    color: d.smileCount.value > d.neutralCount.value
                        ? Colors.green
                        : (d.neutralCount.value > 3
                              ? Colors.red
                              : Colors.orange),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _counterCard(
                    icon: '🧍',
                    title: 'POSTUR',
                    items: [
                      'Miring kiri: ${d.headTiltLeftCount.value}x',
                      'Miring kanan: ${d.headTiltRightCount.value}x',
                      'Menunduk: ${d.headDownCount.value}x',
                    ],
                    color: d.totalHeadViolations > 3
                        ? Colors.red
                        : (d.totalHeadViolations > 0
                              ? Colors.orange
                              : Colors.green),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Ringkasan singkat (tanpa angka)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getSummaryColor(d).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getSummaryColor(d), width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    _getSummaryIcon(d),
                    color: _getSummaryColor(d),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getSummaryText(d),
                      style: TextStyle(
                        color: _getSummaryColor(d),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tombol Mulai Latihan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  controller.resetAllCounters();
                  Get.to(() => const NarasiPracticeView());
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'MULAI LATIHAN INTERVIEW',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _counterCard({
    required String icon,
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                item,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSummaryColor(NarasiDetectController d) {
    final totalEye = d.totalEyeViolations;
    final totalHead = d.totalHeadViolations;
    final smilePositive = d.smileCount.value > d.neutralCount.value;

    if (totalEye <= 1 && totalHead <= 1 && smilePositive) return Colors.green;
    if (totalEye <= 3 && totalHead <= 3) return Colors.orange;
    return Colors.red;
  }

  IconData _getSummaryIcon(NarasiDetectController d) {
    final totalEye = d.totalEyeViolations;
    final totalHead = d.totalHeadViolations;

    if (totalEye <= 1 && totalHead <= 1) return Icons.check_circle;
    if (totalEye <= 3 && totalHead <= 3) return Icons.warning_amber;
    return Icons.error;
  }

  String _getSummaryText(NarasiDetectController d) {
    final totalEye = d.totalEyeViolations;
    final totalHead = d.totalHeadViolations;

    if (totalEye <= 1 && totalHead <= 1 && d.smileCount.value > 0) {
      return '✨ Performa bagus! Pertahankan kontak mata dan postur tubuh.';
    }
    if (totalEye > 3 && totalHead > 3) {
      return '⚠️ Perlu perbaikan besar! Fokus pada kontak mata dan postur tubuh.';
    }
    if (totalEye > 3) {
      return '👀 Kontak mata perlu ditingkatkan. Hindari mengalihkan pandangan/menunduk.';
    }
    if (totalHead > 3) {
      return '🧍 Postur tubuh perlu diperbaiki. Duduklah dengan tegak.';
    }
    if (d.neutralCount.value > d.smileCount.value) {
      return '😐 Cobalah lebih sering tersenyum agar terlihat antusias.';
    }
    return '📝 Terus pantau perilaku Anda selama wawancara.';
  }
}
