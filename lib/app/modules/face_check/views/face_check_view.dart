import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/face_check_controller.dart';
import 'package:fluent_ai/app/modules/dashboard/controllers/dashboard_controller.dart';

class FaceCheckView extends StatelessWidget {
  const FaceCheckView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FaceCheckController());

    return Scaffold(
      backgroundColor: const Color(0xFF070A12),
      body: Obx(() {
        switch (controller.step.value) {
          case FaceCheckStep.intro:
            return _IntroScreen(controller: controller);
          case FaceCheckStep.challenge:
            return _ChallengeScreen(controller: controller);
          case FaceCheckStep.result:
            return _ResultScreen(controller: controller);
        }
      }),
    );
  }
}

// ============================================================
// INTRO SCREEN
// ============================================================
class _IntroScreen extends StatelessWidget {
  final FaceCheckController controller;
  const _IntroScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                _glassBack(),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Latihan Ekspresi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4285F4).withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.face_retouching_natural,
                color: Color(0xFF4285F4),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Latihan Ekspresi &\nKontak Mata',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Latih ekspresi wajah dan kontak mata Anda untuk tampil lebih percaya diri saat wawancara kerja.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Challenge list preview
            Expanded(
              child: ListView.builder(
                itemCount: controller.challenges.length,
                itemBuilder: (context, i) {
                  final c = controller.challenges[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: c.color.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: c.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(c.icon, color: c.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${c.durationSeconds} detik',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.white.withOpacity(0.3),
                          size: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.startChallenges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Mulai Latihan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassBack() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.back(),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ============================================================
// CHALLENGE SCREEN
// ============================================================
class _ChallengeScreen extends StatelessWidget {
  final FaceCheckController controller;
  const _ChallengeScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _header(),
          Expanded(child: _cameraPreview()),
          _challengeInfo(),
          _progressBar(),
          _actionRow(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _header() {
    return Obx(() {
      final idx = controller.currentChallengeIndex.value;
      final total = controller.challenges.length;
      final challenge = controller.currentChallenge;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            // Step indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: challenge.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: challenge.color.withOpacity(0.3)),
              ),
              child: Text(
                '${idx + 1}/$total',
                style: TextStyle(
                  color: challenge.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                challenge.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Sound toggle
            GestureDetector(
              onTap: () => controller.soundEnabled.value = !controller.soundEnabled.value,
              child: Icon(
                controller.soundEnabled.value
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: Colors.white54,
                size: 22,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _cameraPreview() {
    return Obx(() {
      if (!controller.isCameraInitialized.value || controller.cameraController == null) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        );
      }

      final cam = controller.cameraController!;
      final challenge = controller.currentChallenge;
      final conditionMet = controller.isConditionMet.value;
      final countdown = controller.countdown.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Camera
              AspectRatio(
                aspectRatio: 3 / 4,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: cam.value.previewSize?.height ?? 720,
                    height: cam.value.previewSize?.width ?? 1280,
                    child: CameraPreview(cam),
                  ),
                ),
              ),

              // Border glow
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: conditionMet
                          ? Colors.greenAccent.withOpacity(0.8)
                          : challenge.color.withOpacity(0.4),
                      width: conditionMet ? 3 : 2,
                    ),
                  ),
                ),
              ),

              // Status indicator
              if (controller.isRunning.value)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: conditionMet
                            ? Colors.green.withOpacity(0.85)
                            : Colors.red.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        conditionMet ? '✓ Tahan posisi ini!' : '✗ Sesuaikan posisi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),

              // Countdown overlay
              if (countdown > 0)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.6),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$countdown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bersiap...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Face not detected warning
              if (!controller.isFaceDetected.value && controller.isRunning.value)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Wajah tidak terdeteksi. Pastikan wajah terlihat jelas.',
                            style: TextStyle(color: Colors.white, fontSize: 12),
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

  Widget _challengeInfo() {
    return Obx(() {
      final challenge = controller.currentChallenge;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: challenge.color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber.withOpacity(0.8), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    challenge.tip,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _progressBar() {
    return Obx(() {
      final progress = controller.holdProgress.value;
      final challenge = controller.currentChallenge;
      final holdSec = controller.holdSeconds.value;
      final targetSec = challenge.durationSeconds;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${holdSec}s / ${targetSec}s',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: challenge.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(challenge.color),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _actionRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: controller.skipChallenge,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withOpacity(0.15)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Lewati'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RESULT SCREEN
// ============================================================
class _ResultScreen extends StatelessWidget {
  final FaceCheckController controller;
  const _ResultScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(() {
        final score = controller.overallScore.value;
        final label = controller.overallLabel.value;
        final message = controller.overallMessage.value;

        Color scoreColor;
        if (score >= 85) {
          scoreColor = Colors.greenAccent;
        } else if (score >= 65) {
          scoreColor = Colors.lightBlueAccent;
        } else if (score >= 40) {
          scoreColor = Colors.orangeAccent;
        } else {
          scoreColor = Colors.redAccent;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Score circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withOpacity(0.1),
                  border: Border.all(color: scoreColor.withOpacity(0.4), width: 3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'SKOR',
                      style: TextStyle(
                        color: scoreColor.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                label,
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Per-challenge results
              ...controller.results.map((r) => _resultCard(r)),

              const SizedBox(height: 24),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      if (Get.isRegistered<DashboardController>()) {
                        await Get.find<DashboardController>().addPointsAndLog(
                          title: 'Latihan Ekspresi & Kontak Mata',
                          route: '/face-check',
                          points: 3,
                        );
                      }
                    } catch (_) {}
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: controller.restartAll,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Ulangi Latihan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _resultCard(ChallengeResult r) {
    Color cardColor;
    IconData icon;
    if (r.score >= 85) {
      cardColor = Colors.greenAccent;
      icon = Icons.check_circle;
    } else if (r.score >= 65) {
      cardColor = Colors.lightBlueAccent;
      icon = Icons.thumb_up;
    } else if (r.score >= 40) {
      cardColor = Colors.orangeAccent;
      icon = Icons.warning_amber;
    } else {
      cardColor = Colors.redAccent;
      icon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cardColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r.feedback,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                '${r.score}',
                style: TextStyle(
                  color: cardColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${r.holdSeconds}s/${r.targetSeconds}s',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
