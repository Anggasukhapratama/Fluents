import 'package:camera/camera.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/face_check_controller.dart';
import 'package:fluent_ai/app/modules/dashboard/controllers/dashboard_controller.dart';

class FaceCheckView extends StatefulWidget {
  const FaceCheckView({Key? key}) : super(key: key);

  @override
  State<FaceCheckView> createState() => _FaceCheckViewState();
}

class _FaceCheckViewState extends State<FaceCheckView> {
  final FaceCheckController controller = Get.put(FaceCheckController());
  late ConfettiController _confettiController;

  Rect _previewRect = Rect.zero;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    ever(controller.isReady, (v) {
      if (v == true) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A12),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0B1020),
                    const Color(0xFF070A12),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -1.0,
              emissionFrequency: 0.05,
              numberOfParticles: 18,
              maxBlastForce: 90,
              minBlastForce: 70,
              gravity: 0.25,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.yellow,
                Colors.purple,
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: Stack(
                    children: [
                      _portraitPreviewCard(),
                      _topStepRow(),
                      _miniMetrics(),
                      _transitionLoadingOverlay(),
                    ],
                  ),
                ),
                _instructionCard(),
                _statusIndicators(),
                _actionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- HEADER ----------
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          _glassIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () async {
              await controller.stopAllSounds(); // ✅ stop loop before back
              Get.back();
            },
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Face Verification',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Follow the steps to verify your face',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Obx(() {
            final on = controller.soundEnabled.value;
            return _glassIconButton(
              icon: on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              onTap: () => controller.soundEnabled.value = !on,
            );
          }),
          const SizedBox(width: 10),
          _pointsPill(),
          const SizedBox(width: 10),
          _progressRing(),
        ],
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _pointsPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.35)),
      ),
      child: Obx(
        () => Text(
          '${controller.totalPoints.value} pts',
          style: const TextStyle(
            color: Colors.greenAccent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _progressRing() {
    return Obx(() {
      final p = controller.overallProgress.value.clamp(0.0, 1.0);
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              value: p,
              strokeWidth: 4,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                p == 1.0 ? Colors.greenAccent : Colors.lightBlueAccent,
              ),
            ),
          ),
          Text(
            '${(p * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    });
  }

  // ---------- CAMERA PREVIEW CARD ----------
  Widget _portraitPreviewCard() {
    return Obx(() {
      if (!controller.isCameraInitialized.value ||
          controller.cameraController == null) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        );
      }

      final cam = controller.cameraController!;
      final stepColor = controller.getCurrentStepColor();

      return LayoutBuilder(
        builder: (context, constraints) {
          final outerW = constraints.maxWidth;
          final outerH = constraints.maxHeight;

          double cardW = outerW * 0.92;
          double cardH = cardW * (4 / 3);

          if (cardH > outerH * 0.92) {
            cardH = outerH * 0.92;
            cardW = cardH * (3 / 4);
          }

          final left = (outerW - cardW) / 2;
          final top = (outerH - cardH) / 2;

          _previewRect = Rect.fromLTWH(left, top, cardW, cardH);

          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                width: cardW,
                height: cardH,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.55),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: cam.value.previewSize?.height ?? 720,
                            height: cam.value.previewSize?.width ?? 1280,
                            child: CameraPreview(cam),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.25),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.35),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _SingleTargetFramePainter(
                    previewRect: _previewRect,
                    color: stepColor,
                    hasFace: controller.isFaceDetected.value,
                    successProgress: controller.getSuccessProgress(),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  // ---------- TOP STEPS ----------
  Widget _topStepRow() {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Obx(() {
        final step = controller.currentStep.value;
        final total = controller.checkSteps.length;

        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(total, (i) {
                final idx = i + 1;
                final isCurrent = idx == step;
                final isDone = idx < step;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isCurrent ? 30 : 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? controller.getCurrentStepColor()
                        : isDone
                        ? Colors.white.withOpacity(0.18)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrent
                          ? Colors.white.withOpacity(0.35)
                          : Colors.transparent,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$idx',
                    style: TextStyle(
                      color: isCurrent || isDone
                          ? Colors.white
                          : Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      }),
    );
  }

  // ---------- MINI METRICS ----------
  Widget _miniMetrics() {
    return Positioned(
      right: 18,
      bottom: 18,
      child: Obx(() {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metricRow('Smile', controller.smileProbability.value),
              const SizedBox(height: 8),
              _metricRow(
                'Eyes',
                ((controller.leftEyeOpenProbability.value +
                            controller.rightEyeOpenProbability.value) /
                        2)
                    .clamp(0.0, 1.0),
              ),
              const SizedBox(height: 8),
              _metricRow(
                'Yaw',
                (controller.headEulerAngleY.value.abs() / 30).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 8),
              _metricRow(
                'Pitch',
                (controller.headEulerAngleX.value.abs() / 30).clamp(0.0, 1.0),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _metricRow(String label, double value) {
    final v = value.clamp(0.0, 1.0);
    final pct = (v * 100).toInt();
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 74,
            height: 6,
            color: Colors.white10,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: v,
              child: Container(
                color: v > 0.7
                    ? Colors.greenAccent
                    : (v > 0.4 ? Colors.orangeAccent : Colors.redAccent),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$pct%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ---------- LOADING OVERLAY ----------
  Widget _transitionLoadingOverlay() {
    return Obx(() {
      if (!controller.isTransitioning.value) return const SizedBox.shrink();

      return Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.28),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Verifying...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ---------- INSTRUCTION CARD ----------
  Widget _instructionCard() {
    return Obx(() {
      final stepData = controller.getCurrentStepData();
      final color = controller.getCurrentStepColor();

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.35)),
              ),
              child: Icon(
                controller.getCurrentStepIcon(),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.getInstructionText(stepData['instruction']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (stepData['description'] ?? '').toString(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _holdPill(color),
          ],
        ),
      );
    });
  }

  Widget _holdPill(Color color) {
    return Obx(() {
      final prog = controller.getSuccessProgress();
      if (prog <= 0) return const SizedBox.shrink();

      final remain =
          ((controller.stepSuccessTime.value -
                      controller.successDuration.value) /
                  1000)
              .ceil();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Text(
          'Hold ${remain > 0 ? remain : 0}s',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    });
  }

  // ---------- STATUS INDICATORS ----------
  Widget _statusIndicators() {
    return Obx(() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _chip('Face', controller.isFaceDetected.value),
            _chip('Straight', controller.isLookingStraight.value),
            _chip('Smile', controller.isSmiling.value),
            _chip('Eyes', controller.isBothEyesOpen.value),
          ],
        ),
      );
    });
  }

  Widget _chip(String label, bool on) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: on
            ? Colors.green.withOpacity(0.16)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: on
              ? Colors.green.withOpacity(0.35)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: on ? Colors.greenAccent : Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ---------- ACTION BUTTONS ----------
  Widget _actionButtons() {
    const Color darkGreen = Color(0xFF14532D);
    const Color darkGreen2 = Color(0xFF166534);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Obx(() {
        final isLast =
            controller.currentStep.value == controller.checkSteps.length;
        final isReady = controller.isReady.value;

        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: controller.currentStep.value > 1
                    ? controller.previousStep
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.18)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isLast && isReady
                      ? const LinearGradient(colors: [darkGreen, darkGreen2])
                      : LinearGradient(
                          colors: [
                            controller.getCurrentStepColor(),
                            controller.getCurrentStepColor().withOpacity(0.8),
                          ],
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: controller.getCurrentStepColor().withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: controller.isTransitioning.value
                      ? null
                      : () async {
                          if (isLast && isReady) {
                            // ✅ STOP audio before leaving screen
                            await controller.stopAllSounds();

                            try {
                              if (Get.isRegistered<DashboardController>()) {
                                await Get.find<DashboardController>()
                                    .addPointsAndLog(
                                      title: 'Cek Wajah',
                                      route: '/face-check',
                                      points: 2,
                                    );
                              }
                            } catch (_) {}

                            Get.back(
                              result: {
                                'isReady': true,
                                'time': DateTime.now(),
                                'totalPoints': controller.totalPoints.value,
                              },
                            );
                            return;
                          }

                          controller.nextStepManual();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isLast
                        ? (isReady ? 'Complete ✓' : 'Check Again')
                        : 'Continue',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ==========================================================
// ✅ SINGLE frame painter (no moving bbox)
// ==========================================================
class _SingleTargetFramePainter extends CustomPainter {
  final Rect previewRect;
  final Color color;
  final bool hasFace;
  final double successProgress;

  _SingleTargetFramePainter({
    required this.previewRect,
    required this.color,
    required this.hasFace,
    required this.successProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (previewRect == Rect.zero) return;

    final full = Offset.zero & size;
    final hole = RRect.fromRectAndRadius(
      previewRect,
      const Radius.circular(24),
    );
    final overlayPath = Path()..addRect(full);
    final holePath = Path()..addRRect(hole);
    final diff = Path.combine(PathOperation.difference, overlayPath, holePath);

    canvas.drawPath(diff, Paint()..color = Colors.black.withOpacity(0.20));

    final target = Rect.fromCenter(
      center: previewRect.center,
      width: previewRect.width * 0.74,
      height: previewRect.height * 0.72,
    );

    final baseColor = hasFace ? color : Colors.redAccent;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = baseColor.withOpacity(0.14);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = baseColor.withOpacity(0.85);

    final r = RRect.fromRectAndRadius(target, const Radius.circular(22));
    canvas.drawRRect(r, glow);
    canvas.drawRRect(r, stroke);

    final cPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = baseColor.withOpacity(0.9);

    const corner = 18.0;
    final tl = target.topLeft;
    final tr = target.topRight;
    final bl = target.bottomLeft;
    final br = target.bottomRight;

    void cornerL(Offset p, Offset dx, Offset dy) {
      canvas.drawLine(p, p + dx, cPaint);
      canvas.drawLine(p, p + dy, cPaint);
    }

    cornerL(tl, const Offset(corner, 0), const Offset(0, corner));
    cornerL(tr, const Offset(-corner, 0), const Offset(0, corner));
    cornerL(bl, const Offset(corner, 0), const Offset(0, -corner));
    cornerL(br, const Offset(-corner, 0), const Offset(0, -corner));

    if (successProgress > 0) {
      final barW = target.width * 0.55;
      final barH = 4.0;
      final bar = Rect.fromCenter(
        center: Offset(target.center.dx, target.top + 14),
        width: barW,
        height: barH,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(bar, const Radius.circular(10)),
        Paint()..color = Colors.white.withOpacity(0.18),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            bar.left,
            bar.top,
            barW * successProgress.clamp(0.0, 1.0),
            barH,
          ),
          const Radius.circular(10),
        ),
        Paint()..color = baseColor.withOpacity(0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SingleTargetFramePainter oldDelegate) => true;
}
