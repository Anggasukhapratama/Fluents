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

class FaceCheckController extends GetxController {
  CameraController? cameraController;
  RxBool isCameraInitialized = false.obs;
  RxList<CameraDescription> cameras = <CameraDescription>[].obs;

  late FaceDetector faceDetector;

  RxList<Face> detectedFaces = <Face>[].obs;
  RxBool isFaceDetected = false.obs;

  // Face attributes
  RxDouble smileProbability = 0.0.obs;
  RxDouble rightEyeOpenProbability = 0.0.obs;
  RxDouble leftEyeOpenProbability = 0.0.obs;

  // Head angles
  RxDouble headEulerAngleY = 0.0.obs; // yaw
  RxDouble headEulerAngleX = 0.0.obs; // pitch
  RxDouble headEulerAngleZ = 0.0.obs; // roll

  // Check status
  RxBool isSmiling = false.obs;
  RxBool isLookingStraight = false.obs;
  RxBool isBothEyesOpen = false.obs;
  RxBool isReady = false.obs;

  // UI states
  RxString currentInstruction = 'frame_your_face'.obs;
  RxInt currentStep = 1.obs;
  RxDouble overallProgress = 0.0.obs;

  // Timing
  RxInt successDuration = 0.obs; // ms
  RxInt stepSuccessTime = 2000.obs; // 2 detik

  // ✅ overlay verifying
  RxBool isTransitioning = false.obs;

  // Points
  RxInt totalPoints = 0.obs;

  // Audio toggle
  final RxBool soundEnabled = true.obs;

  bool _isProcessing = false;
  Timer? _progressTimer;

  // Keep last image info
  Size? _lastImageSize;
  bool _isFrontCamera = true;

  // Audio players
  late final AudioPlayer _sfxPlayer;
  late final AudioPlayer _loopPlayer;

  // Transisi delay
  final int transitionDelayMs = 1200;

  final List<Map<String, dynamic>> checkSteps = [
    {
      'id': 1,
      'instruction': 'frame_your_face',
      'description': 'Position your face within the frame',
      'checkFunction': 'checkFaceInFrame',
      'color': 0xFF4285F4,
      'icon': Icons.camera,
      'threshold': 0.25,
      'points': 25,
    },
    {
      'id': 2,
      'instruction': 'look_straight',
      'description': 'Look straight at the camera',
      'checkFunction': 'checkLookingStraight',
      'color': 0xFFFBBC05,
      'icon': Icons.center_focus_strong,
      'threshold': 12.0,
      'points': 25,
    },
    {
      'id': 3,
      'instruction': 'smile_check',
      'description': 'Please smile naturally',
      'checkFunction': 'checkSmile',
      'color': 0xFFEA4335,
      'icon': Icons.emoji_emotions,
      'threshold': 0.75,
      'points': 25,
    },
    {
      'id': 4,
      'instruction': 'eyes_open',
      'description': 'Keep both eyes open',
      'checkFunction': 'checkEyesOpen',
      'color': 0xFF34A853,
      'icon': Icons.remove_red_eye,
      'threshold': 0.65,
      'points': 25,
    },
    {
      'id': 5,
      'instruction': 'final_check',
      'description': 'Perfect! You\'re ready',
      'checkFunction': 'finalCheck',
      'color': 0xFF9C27B0,
      'icon': Icons.check_circle,
      'threshold': null,
      'points': 0,
    },
  ];

  final Map<String, Map<String, dynamic>> stepStatus = {
    'frame_your_face': {'color': Color(0xFF4285F4), 'icon': Icons.camera},
    'look_straight': {
      'color': Color(0xFFFBBC05),
      'icon': Icons.center_focus_strong,
    },
    'smile_check': {'color': Color(0xFFEA4335), 'icon': Icons.emoji_emotions},
    'eyes_open': {'color': Color(0xFF34A853), 'icon': Icons.remove_red_eye},
    'final_check': {'color': Color(0xFF9C27B0), 'icon': Icons.check_circle},
  };

  @override
  void onInit() {
    super.onInit();
    _initFaceDetector();
    _initAudio();
    initializeCamera();
    _startProgressTimer();

    // ✅ SAFETY: kalau user matiin sound, stop semua audio yg mungkin looping
    ever<bool>(soundEnabled, (on) async {
      if (!on) {
        try {
          await _sfxPlayer.stop();
        } catch (_) {}
        try {
          await _loopPlayer.stop();
        } catch (_) {}
      }
    });
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
    _loopPlayer = AudioPlayer();
    _loopPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> _playTinung() async {
    if (!soundEnabled.value) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/load.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint('SFX error: $e');
    }
  }

  Future<void> _startLoadingSound() async {
    if (!soundEnabled.value) return;
    try {
      // ✅ penting: stop dulu sebelum play loop
      await _loopPlayer.stop();
      await _loopPlayer.play(AssetSource('sounds/alert.mp3'), volume: 0.65);
    } catch (e) {
      debugPrint('Loop sound error: $e');
    }
  }

  Future<void> _stopLoadingSound() async {
    try {
      await _loopPlayer.stop();
    } catch (_) {}
  }

  /// ✅ bisa dipanggil dari View sebelum Get.back()
  Future<void> stopAllSounds() async {
    try {
      await _sfxPlayer.stop();
    } catch (_) {}
    try {
      await _loopPlayer.stop();
    } catch (_) {}
  }

  Future<void> initializeCamera() async {
    try {
      cameras.value = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _isFrontCamera = front.lensDirection == CameraLensDirection.front;

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

      await cameraController!.startImageStream(processCameraImage);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      Get.snackbar(
        'Camera Error',
        'Failed to initialize camera: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> processCameraImage(CameraImage image) async {
    if (!isCameraInitialized.value || _isProcessing) return;
    if (isTransitioning.value) return; // ✅ pause detection while overlay
    _isProcessing = true;

    try {
      _lastImageSize = Size(image.width.toDouble(), image.height.toDouble());

      final inputImage = _toInputImage(image);
      final faces = await faceDetector.processImage(inputImage);

      detectedFaces.value = faces;

      if (faces.isEmpty) {
        isFaceDetected.value = false;
        successDuration.value = 0;
        return;
      }

      final face = faces.first;
      isFaceDetected.value = true;

      _updateFaceData(face);
      performCurrentCheck();
    } catch (e) {
      debugPrint('Error processing image: $e');
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

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final width = image.width;
    final height = image.height;

    final out = Uint8List(width * height + (width * height ~/ 2));
    out.setRange(0, width * height, yBytes);

    int uvIndex = width * height;
    final rowStride = uPlane.bytesPerRow;
    final pixelStride = uPlane.bytesPerPixel ?? 1;

    for (int row = 0; row < height ~/ 2; row++) {
      for (int col = 0; col < width ~/ 2; col++) {
        final index = row * rowStride + col * pixelStride;
        out[uvIndex++] = vBytes[index];
        out[uvIndex++] = uBytes[index];
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

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!isCameraInitialized.value) return;
      if (isTransitioning.value) return;
      performCurrentCheck();
    });
  }

  void performCurrentCheck() {
    if (currentStep.value < 1 || currentStep.value > checkSteps.length) return;

    final currentStepData = checkSteps[currentStep.value - 1];
    final String fn = currentStepData['checkFunction'];

    bool checkPassed = false;

    switch (fn) {
      case 'checkFaceInFrame':
        checkPassed = checkFaceInFrame();
        break;
      case 'checkLookingStraight':
        checkPassed = checkLookingStraight();
        break;
      case 'checkSmile':
        checkPassed = checkSmile();
        break;
      case 'checkEyesOpen':
        checkPassed = checkEyesOpen();
        break;
      case 'finalCheck':
        checkPassed = finalCheck();
        break;
    }

    _updateSuccessDuration(checkPassed);
  }

  bool checkFaceInFrame() {
    if (detectedFaces.isEmpty) return false;
    if (_lastImageSize == null) return false;

    final face = detectedFaces.first;
    final w = _lastImageSize!.width;
    final h = _lastImageSize!.height;

    final faceWRatio = face.boundingBox.width / w;
    final faceHRatio = face.boundingBox.height / h;

    final inFrame =
        faceWRatio > 0.22 &&
        faceWRatio < 0.70 &&
        faceHRatio > 0.22 &&
        faceHRatio < 0.70;

    final centerX = face.boundingBox.center.dx / w;
    final centerY = face.boundingBox.center.dy / h;

    final isCentered =
        (centerX > 0.30 && centerX < 0.70) &&
        (centerY > 0.25 && centerY < 0.75);

    return inFrame && isCentered;
  }

  bool checkLookingStraight() {
    const yawThresh = 15.0;
    const pitchThresh = 15.0;
    const rollThresh = 20.0;

    final passed =
        headEulerAngleY.value.abs() < yawThresh &&
        headEulerAngleX.value.abs() < pitchThresh &&
        headEulerAngleZ.value.abs() < rollThresh;

    isLookingStraight.value = passed;
    return passed;
  }

  bool checkSmile() {
    const smileThresh = 0.70;
    final passed = smileProbability.value >= smileThresh;
    isSmiling.value = passed;
    return passed;
  }

  bool checkEyesOpen() {
    const eyeThresh = 0.60;
    final passed =
        rightEyeOpenProbability.value >= eyeThresh &&
        leftEyeOpenProbability.value >= eyeThresh;
    isBothEyesOpen.value = passed;
    return passed;
  }

  bool finalCheck() {
    final passed =
        isFaceDetected.value &&
        isLookingStraight.value &&
        isSmiling.value &&
        isBothEyesOpen.value;

    isReady.value = passed;

    if (passed) {
      overallProgress.value = 1.0;
      isTransitioning.value = false;
      _stopLoadingSound(); // ✅ jaga-jaga
    }

    return passed;
  }

  void _updateSuccessDuration(bool conditionMet) {
    if (isTransitioning.value) return;

    if (conditionMet) {
      if (successDuration.value < stepSuccessTime.value) {
        successDuration.value += 100;
      }
    } else {
      successDuration.value = 0;
    }

    _updateOverallProgress();

    if (conditionMet && successDuration.value >= stepSuccessTime.value) {
      // ✅ guard: kalau sudah final step, jangan transisi lagi
      if (currentStep.value >= checkSteps.length) {
        isTransitioning.value = false;
        _stopLoadingSound(); // ✅ FIX: stop loop juga
        finalCheck();
        return;
      }
      _goToNextStepWithDelay();
    }
  }

  void _updateOverallProgress() {
    final stepProgress = (successDuration.value / stepSuccessTime.value).clamp(
      0.0,
      1.0,
    );
    final stepWeight = 1.0 / checkSteps.length;

    overallProgress.value =
        ((currentStep.value - 1) * stepWeight) + (stepProgress * stepWeight);
  }

  Future<void> _goToNextStepWithDelay() async {
    if (isTransitioning.value) return;

    // ✅ kalau sudah step terakhir, pastikan loop mati juga
    if (currentStep.value >= checkSteps.length) {
      await _stopLoadingSound();
      isTransitioning.value = false;
      return;
    }

    isTransitioning.value = true;

    try {
      await _playTinung();
      await _startLoadingSound();

      await Future.delayed(Duration(milliseconds: transitionDelayMs));

      await _stopLoadingSound();

      _goToNextStepInternal();

      if (currentStep.value >= checkSteps.length) {
        finalCheck();
      }
    } catch (e) {
      debugPrint('Transition error: $e');
      await _stopLoadingSound();
    } finally {
      // ✅ FIX UTAMA: apapun yang terjadi, loop sound harus berhenti
      await _stopLoadingSound();
      isTransitioning.value = false;
    }
  }

  void _goToNextStepInternal() {
    if (currentStep.value < checkSteps.length) {
      final completedStep = checkSteps[currentStep.value - 1];
      final points = completedStep['points'] as int? ?? 0;
      totalPoints.value += points;

      successDuration.value = 0;

      currentStep.value++;
      currentInstruction.value =
          checkSteps[currentStep.value - 1]['instruction'];

      _updateOverallProgress();

      if (currentStep.value == checkSteps.length) {
        finalCheck();
      }
    }
  }

  void nextStepManual() {
    if (isTransitioning.value) return;

    if (currentStep.value >= checkSteps.length) {
      isTransitioning.value = false;
      _stopLoadingSound(); // ✅ safety
      finalCheck();
      return;
    }

    final currentStepData = checkSteps[currentStep.value - 1];
    final points = currentStepData['points'] as int? ?? 0;
    totalPoints.value += points;

    currentStep.value++;
    currentInstruction.value = checkSteps[currentStep.value - 1]['instruction'];
    successDuration.value = 0;
    _updateOverallProgress();

    _playTinung();
  }

  void previousStep() {
    if (isTransitioning.value) return;

    if (currentStep.value > 1) {
      final prevStep = checkSteps[currentStep.value - 2];
      final points = prevStep['points'] as int? ?? 0;
      totalPoints.value -= points;

      currentStep.value--;
      currentInstruction.value =
          checkSteps[currentStep.value - 1]['instruction'];
      successDuration.value = 0;
      _updateOverallProgress();
    }
  }

  void restartCheck() {
    currentStep.value = 1;
    currentInstruction.value = checkSteps.first['instruction'];
    overallProgress.value = 0.0;
    successDuration.value = 0;
    totalPoints.value = 0;

    isFaceDetected.value = false;
    isLookingStraight.value = false;
    isSmiling.value = false;
    isBothEyesOpen.value = false;
    isReady.value = false;

    isTransitioning.value = false;

    // ✅ stop loop sound biar gak nyangkut saat restart
    _stopLoadingSound();
  }

  Map<String, dynamic> getCurrentStepData() =>
      checkSteps[currentStep.value - 1];

  String getInstructionText(String key) {
    const map = {
      'frame_your_face': 'Position Your Face',
      'look_straight': 'Look Straight',
      'smile_check': 'Smile Please',
      'eyes_open': 'Eyes Open',
      'final_check': 'All Set!',
    };
    return map[key] ?? key;
  }

  Color getCurrentStepColor() {
    final current = checkSteps[currentStep.value - 1]['instruction'];
    return stepStatus[current]?['color'] ?? Colors.blue;
  }

  IconData getCurrentStepIcon() {
    final current = checkSteps[currentStep.value - 1]['instruction'];
    return stepStatus[current]?['icon'] ?? Icons.camera;
  }

  double getSuccessProgress() =>
      (successDuration.value / stepSuccessTime.value).clamp(0.0, 1.0);

  @override
  void onClose() {
    _progressTimer?.cancel();

    try {
      cameraController?.stopImageStream();
      cameraController?.dispose();
    } catch (_) {}

    faceDetector.close();

    // ✅ stop audio on close
    stopAllSounds();

    try {
      _sfxPlayer.dispose();
      _loopPlayer.dispose();
    } catch (_) {}

    super.onClose();
  }
}
