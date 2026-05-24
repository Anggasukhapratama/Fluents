import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// ============================================================
// FACE CHECK CONTROLLER - Latihan Ekspresi & Kontak Mata
// ============================================================
// Fitur: Tantangan terstruktur untuk melatih ekspresi wajah
// dan kontak mata saat wawancara kerja.
// ============================================================

enum FaceCheckStep { intro, challenge, result }

class FaceChallenge {
  final String id;
  final String title;
  final String description;
  final String tip;
  final IconData icon;
  final Color color;
  final int durationSeconds;
  final bool Function(FaceCheckController c) checkCondition;

  const FaceChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.tip,
    required this.icon,
    required this.color,
    required this.durationSeconds,
    required this.checkCondition,
  });
}

class ChallengeResult {
  final String challengeId;
  final String title;
  final int score; // 0-100
  final int holdSeconds;
  final int targetSeconds;
  final String feedback;

  ChallengeResult({
    required this.challengeId,
    required this.title,
    required this.score,
    required this.holdSeconds,
    required this.targetSeconds,
    required this.feedback,
  });
}

class FaceCheckController extends GetxController {
  // ==================== CAMERA & DETECTION ====================
  CameraController? cameraController;
  final isCameraInitialized = false.obs;
  final cameras = <CameraDescription>[].obs;

  late FaceDetector faceDetector;

  final detectedFaces = <Face>[].obs;
  final isFaceDetected = false.obs;

  // Face attributes
  final smileProbability = 0.0.obs;
  final rightEyeOpenProbability = 0.0.obs;
  final leftEyeOpenProbability = 0.0.obs;

  // Head angles
  final headEulerAngleY = 0.0.obs; // yaw (kiri-kanan)
  final headEulerAngleX = 0.0.obs; // pitch (atas-bawah)
  final headEulerAngleZ = 0.0.obs; // roll (miring)

  bool _isProcessing = false;
  Size? _lastImageSize;

  // ==================== FLOW STATE ====================
  final step = FaceCheckStep.intro.obs;
  final currentChallengeIndex = 0.obs;
  final isRunning = false.obs;

  // ==================== CHALLENGE TIMER ====================
  final holdProgress = 0.0.obs; // 0.0 - 1.0
  final holdSeconds = 0.obs;
  final isConditionMet = false.obs;
  Timer? _challengeTimer;
  Timer? _progressTimer;

  // ==================== COUNTDOWN ====================
  final countdown = 0.obs;
  Timer? _countdownTimer;

  // ==================== RESULTS ====================
  final results = <ChallengeResult>[].obs;
  final overallScore = 0.obs;
  final overallLabel = ''.obs;
  final overallMessage = ''.obs;

  // ==================== AUDIO ====================
  final soundEnabled = true.obs;
  late final AudioPlayer _sfxPlayer;

  // ==================== CHALLENGES ====================
  late final List<FaceChallenge> challenges;

  FaceChallenge get currentChallenge => challenges[currentChallengeIndex.value];

  @override
  void onInit() {
    super.onInit();
    _initChallenges();
    _initFaceDetector();
    _initAudio();
    initializeCamera();
  }

  @override
  void onClose() {
    _challengeTimer?.cancel();
    _progressTimer?.cancel();
    _countdownTimer?.cancel();
    try {
      cameraController?.stopImageStream();
      cameraController?.dispose();
    } catch (_) {}
    faceDetector.close();
    _stopAllSounds();
    try {
      _sfxPlayer.dispose();
    } catch (_) {}
    super.onClose();
  }

  // ==================== INIT ====================

  void _initChallenges() {
    challenges = [
      FaceChallenge(
        id: 'eye_contact',
        title: 'Kontak Mata',
        description: 'Tatap kamera dengan percaya diri selama 8 detik tanpa menoleh.',
        tip: 'Bayangkan Anda sedang berbicara dengan pewawancara. Tatap langsung ke lensa kamera.',
        icon: Icons.visibility,
        color: const Color(0xFF4285F4),
        durationSeconds: 8,
        checkCondition: (c) {
          return c.isFaceDetected.value &&
              c.headEulerAngleY.value.abs() < 12 &&
              c.headEulerAngleX.value.abs() < 12 &&
              c.headEulerAngleZ.value.abs() < 15;
        },
      ),
      FaceChallenge(
        id: 'professional_smile',
        title: 'Senyum Profesional',
        description: 'Tunjukkan senyum ramah dan profesional selama 6 detik.',
        tip: 'Senyum yang natural menunjukkan keramahan. Jangan terlalu lebar, cukup senyum hangat.',
        icon: Icons.emoji_emotions,
        color: const Color(0xFFEA4335),
        durationSeconds: 6,
        checkCondition: (c) {
          return c.isFaceDetected.value &&
              c.smileProbability.value >= 0.65 &&
              c.headEulerAngleY.value.abs() < 15;
        },
      ),
      FaceChallenge(
        id: 'confident_posture',
        title: 'Postur Percaya Diri',
        description: 'Jaga kepala tegak dan tatapan lurus selama 8 detik.',
        tip: 'Postur tegak menunjukkan kepercayaan diri. Jangan menunduk atau memiringkan kepala.',
        icon: Icons.accessibility_new,
        color: const Color(0xFF34A853),
        durationSeconds: 8,
        checkCondition: (c) {
          return c.isFaceDetected.value &&
              c.headEulerAngleX.value.abs() < 8 &&
              c.headEulerAngleY.value.abs() < 10 &&
              c.headEulerAngleZ.value.abs() < 10;
        },
      ),
      FaceChallenge(
        id: 'enthusiastic_expression',
        title: 'Ekspresi Antusias',
        description: 'Tunjukkan ekspresi antusias: mata terbuka lebar dan senyum.',
        tip: 'Saat pewawancara menjelaskan posisi, tunjukkan ketertarikan dengan mata terbuka dan senyum.',
        icon: Icons.star,
        color: const Color(0xFFFBBC05),
        durationSeconds: 6,
        checkCondition: (c) {
          return c.isFaceDetected.value &&
              c.smileProbability.value >= 0.5 &&
              c.leftEyeOpenProbability.value >= 0.75 &&
              c.rightEyeOpenProbability.value >= 0.75 &&
              c.headEulerAngleY.value.abs() < 15;
        },
      ),
      FaceChallenge(
        id: 'calm_neutral',
        title: 'Tenang & Fokus',
        description: 'Jaga ekspresi tenang dan fokus selama 8 detik. Mata terbuka, wajah rileks.',
        tip: 'Saat mendengarkan pertanyaan, jaga ekspresi netral yang tenang. Jangan tegang.',
        icon: Icons.self_improvement,
        color: const Color(0xFF9C27B0),
        durationSeconds: 8,
        checkCondition: (c) {
          return c.isFaceDetected.value &&
              c.leftEyeOpenProbability.value >= 0.6 &&
              c.rightEyeOpenProbability.value >= 0.6 &&
              c.headEulerAngleY.value.abs() < 10 &&
              c.headEulerAngleX.value.abs() < 10 &&
              c.headEulerAngleZ.value.abs() < 12 &&
              c.smileProbability.value < 0.8; // tidak senyum berlebihan
        },
      ),
    ];
  }

  void _initFaceDetector() {
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableClassification: true,
      enableLandmarks: false,
      enableContours: false,
      enableTracking: true,
      minFaceSize: 0.25,
    );
    faceDetector = FaceDetector(options: options);
  }

  void _initAudio() {
    _sfxPlayer = AudioPlayer();
  }

  Future<void> _playSuccess() async {
    if (!soundEnabled.value) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/load.mp3'), volume: 1.0);
    } catch (_) {}
  }

  Future<void> _stopAllSounds() async {
    try {
      await _sfxPlayer.stop();
    } catch (_) {}
  }

  // ==================== CAMERA ====================

  Future<void> initializeCamera() async {
    try {
      cameras.value = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );

      await cameraController!.initialize();
      isCameraInitialized.value = true;
      await cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (!isCameraInitialized.value || _isProcessing) return;
    _isProcessing = true;

    try {
      _lastImageSize = Size(image.width.toDouble(), image.height.toDouble());
      final inputImage = _toInputImage(image);
      final faces = await faceDetector.processImage(inputImage);

      detectedFaces.value = faces;

      if (faces.isEmpty) {
        isFaceDetected.value = false;
        return;
      }

      final face = faces.first;
      isFaceDetected.value = true;
      _updateFaceData(face);
    } catch (_) {
    } finally {
      _isProcessing = false;
    }
  }

  InputImage _toInputImage(CameraImage image) {
    final rotation =
        InputImageRotationValue.fromRawValue(
          cameraController?.description.sensorOrientation ?? 0,
        ) ??
        InputImageRotation.rotation0deg;

    if (Platform.isIOS) {
      final plane = image.planes.first;
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: plane.bytesPerRow,
      );
      return InputImage.fromBytes(bytes: plane.bytes, metadata: metadata);
    }

    final nv21 = _yuv420ToNv21(image);
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: InputImageFormat.nv21,
      bytesPerRow: image.planes.first.bytesPerRow,
    );
    return InputImage.fromBytes(bytes: nv21, metadata: metadata);
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final width = image.width;
    final height = image.height;

    final out = Uint8List(width * height + (width * height ~/ 2));
    out.setRange(0, width * height, yPlane.bytes);

    int uvIndex = width * height;
    final rowStride = uPlane.bytesPerRow;
    final pixelStride = uPlane.bytesPerPixel ?? 1;

    for (int row = 0; row < height ~/ 2; row++) {
      for (int col = 0; col < width ~/ 2; col++) {
        final index = row * rowStride + col * pixelStride;
        out[uvIndex++] = vPlane.bytes[index];
        out[uvIndex++] = uPlane.bytes[index];
      }
    }
    return out;
  }

  void _updateFaceData(Face face) {
    smileProbability.value = face.smilingProbability ?? 0.0;
    rightEyeOpenProbability.value = face.rightEyeOpenProbability ?? 0.0;
    leftEyeOpenProbability.value = face.leftEyeOpenProbability ?? 0.0;
    headEulerAngleX.value = face.headEulerAngleX ?? 0.0;
    headEulerAngleY.value = face.headEulerAngleY ?? 0.0;
    headEulerAngleZ.value = face.headEulerAngleZ ?? 0.0;
  }

  // ==================== FLOW ====================

  void startChallenges() {
    currentChallengeIndex.value = 0;
    results.clear();
    step.value = FaceCheckStep.challenge;
    _startCountdown();
  }

  void _startCountdown() {
    countdown.value = 3;
    isRunning.value = false;
    holdProgress.value = 0;
    holdSeconds.value = 0;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown.value > 1) {
        countdown.value--;
      } else {
        t.cancel();
        countdown.value = 0;
        _startCurrentChallenge();
      }
    });
  }

  void _startCurrentChallenge() {
    isRunning.value = true;
    holdProgress.value = 0;
    holdSeconds.value = 0;
    isConditionMet.value = false;

    final duration = currentChallenge.durationSeconds;
    int elapsedTenths = 0;

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!isRunning.value) {
        t.cancel();
        return;
      }

      final conditionOk = currentChallenge.checkCondition(this);
      isConditionMet.value = conditionOk;

      if (conditionOk) {
        elapsedTenths++;
        holdSeconds.value = elapsedTenths ~/ 10;
        holdProgress.value = (elapsedTenths / (duration * 10)).clamp(0.0, 1.0);

        if (elapsedTenths >= duration * 10) {
          t.cancel();
          _completeChallenge(holdSeconds: duration, perfect: true);
        }
      } else {
        // Reset jika kondisi tidak terpenuhi
        if (elapsedTenths > 0) {
          elapsedTenths = (elapsedTenths - 2).clamp(0, duration * 10);
          holdSeconds.value = elapsedTenths ~/ 10;
          holdProgress.value = (elapsedTenths / (duration * 10)).clamp(0.0, 1.0);
        }
      }
    });

    // Timeout: setelah durasi * 2, selesaikan dengan skor parsial
    _challengeTimer?.cancel();
    _challengeTimer = Timer(Duration(seconds: duration * 3), () {
      if (isRunning.value) {
        _completeChallenge(holdSeconds: holdSeconds.value, perfect: false);
      }
    });
  }

  void _completeChallenge({required int holdSeconds, required bool perfect}) {
    isRunning.value = false;
    _progressTimer?.cancel();
    _challengeTimer?.cancel();

    final challenge = currentChallenge;
    final target = challenge.durationSeconds;
    final score = ((holdSeconds / target) * 100).round().clamp(0, 100);

    String feedback;
    if (score >= 90) {
      feedback = 'Sangat baik! Anda berhasil menyelesaikan tantangan dengan sempurna.';
    } else if (score >= 70) {
      feedback = 'Cukup baik! Sedikit lagi Anda bisa sempurna. Terus latihan!';
    } else if (score >= 40) {
      feedback = 'Perlu latihan lagi. Coba fokus dan rileks saat melakukannya.';
    } else {
      feedback = 'Belum berhasil. Jangan khawatir, latihan rutin akan membantu!';
    }

    results.add(ChallengeResult(
      challengeId: challenge.id,
      title: challenge.title,
      score: score,
      holdSeconds: holdSeconds,
      targetSeconds: target,
      feedback: feedback,
    ));

    _playSuccess();

    // Lanjut ke tantangan berikutnya atau selesai
    if (currentChallengeIndex.value < challenges.length - 1) {
      currentChallengeIndex.value++;
      Future.delayed(const Duration(milliseconds: 1500), () {
        _startCountdown();
      });
    } else {
      _calculateFinalResult();
    }
  }

  void skipChallenge() {
    isRunning.value = false;
    _progressTimer?.cancel();
    _challengeTimer?.cancel();

    final challenge = currentChallenge;
    results.add(ChallengeResult(
      challengeId: challenge.id,
      title: challenge.title,
      score: 0,
      holdSeconds: 0,
      targetSeconds: challenge.durationSeconds,
      feedback: 'Tantangan dilewati.',
    ));

    if (currentChallengeIndex.value < challenges.length - 1) {
      currentChallengeIndex.value++;
      _startCountdown();
    } else {
      _calculateFinalResult();
    }
  }

  void _calculateFinalResult() {
    if (results.isEmpty) {
      overallScore.value = 0;
      overallLabel.value = 'Belum Dinilai';
      overallMessage.value = '';
      step.value = FaceCheckStep.result;
      return;
    }

    final totalScore = results.fold(0, (sum, r) => sum + r.score);
    final avg = (totalScore / results.length).round();
    overallScore.value = avg;

    if (avg >= 85) {
      overallLabel.value = 'Siap Wawancara';
      overallMessage.value =
          'Ekspresi dan kontak mata Anda sangat baik! Anda siap menghadapi wawancara dengan percaya diri.';
    } else if (avg >= 65) {
      overallLabel.value = 'Cukup Siap';
      overallMessage.value =
          'Ekspresi Anda sudah cukup baik. Latihan rutin akan membuat Anda lebih natural dan percaya diri.';
    } else if (avg >= 40) {
      overallLabel.value = 'Perlu Latihan';
      overallMessage.value =
          'Anda perlu lebih banyak latihan untuk mengontrol ekspresi wajah. Coba latihan di depan cermin juga.';
    } else {
      overallLabel.value = 'Butuh Banyak Latihan';
      overallMessage.value =
          'Jangan menyerah! Latihan rutin setiap hari akan sangat membantu meningkatkan kepercayaan diri Anda.';
    }

    step.value = FaceCheckStep.result;
  }

  void restartAll() {
    step.value = FaceCheckStep.intro;
    currentChallengeIndex.value = 0;
    results.clear();
    holdProgress.value = 0;
    holdSeconds.value = 0;
    isRunning.value = false;
    overallScore.value = 0;
    overallLabel.value = '';
    overallMessage.value = '';
  }

  // ==================== HELPERS ====================

  double get totalProgress {
    final completed = results.length;
    final total = challenges.length;
    if (total == 0) return 0;
    final currentProg = isRunning.value ? holdProgress.value : 0.0;
    return ((completed + currentProg) / total).clamp(0.0, 1.0);
  }
}
