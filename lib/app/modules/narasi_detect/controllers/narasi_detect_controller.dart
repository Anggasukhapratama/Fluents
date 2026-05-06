// lib/app/controllers/narasi_detect_controller.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class NarasiDetectController extends GetxController {
  // ===== KAMERA =====
  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  final isCameraReady = false.obs;
  final isRunning = false.obs;

  DateTime? _lastProcess;
  bool _processing = false;
  static const int _processIntervalMs = 200; // Dinaikkan dari 150 ke 200

  // ===== ML KIT DETECTOR =====
  late final FaceDetector _faceDetector;
  late final PoseDetector _poseDetector;

  // ===== STATUS WAJAH =====
  final isFaceDetected = false.obs;

  // ===== THRESHOLD DETEKSI - DIPERBAIKI =====
  // Kontak mata (sudah cukup baik)
  double _lookAwayYawThr = 22.0; // Dinaikkan dari 18.0
  double _lookDownPitchThr = 20.0; // Dinaikkan dari 15.0

  // POSTUR - INI YANG TERLALU SENSITIF
  // Nilai shoulderDiff diukur dalam pixel, semakin besar semakin tidak sensitif
  double _headTiltLeftThr = 0.12; // Dinaikkan SIGNIFIKAN dari 0.065
  double _headTiltRightThr = 0.12; // Dinaikkan SIGNIFIKAN dari 0.065
  double _headDownThr = 0.15; // Dinaikkan dari 0.085

  // Senyum
  double _smileThr = 0.20;

  String currentLevel = 'medium';

  // ===== COUNTER PELANGGARAN - DITAMBAH MINIMUM INTERVAL =====
  final lookAwayLeftCount = 0.obs;
  final lookAwayRightCount = 0.obs;
  final lookDownCount = 0.obs;
  final smileCount = 0.obs;
  final neutralCount = 0.obs;
  final headTiltLeftCount = 0.obs;
  final headTiltRightCount = 0.obs;
  final headDownCount = 0.obs;

  // ===== DETEKSI REAL-TIME =====
  bool _wasLookingLeft = false;
  bool _wasLookingRight = false;
  bool _wasLookingDown = false;
  bool _wasSmiling = false;
  bool _wasHeadTiltLeft = false;
  bool _wasHeadTiltRight = false;
  bool _wasHeadDown = false;
  double _smoothSmile = 0.0;
  double _smoothShoulderDiff = 0.0;
  double _smoothHeadDown = 0.0;

  // ===== COOLDOWN UNTUK MENCEGAH SPAM DETEKSI =====
  DateTime? _lastEyeViolation;
  DateTime? _lastHeadViolation;
  DateTime? _lastSmileDetection;
  static const int _eyeViolationCooldownMs =
      2000; // 2 detik antar pelanggaran mata
  static const int _headViolationCooldownMs =
      2500; // 2.5 detik antar pelanggaran postur
  static const int _smileDetectionCooldownMs =
      1500; // 1.5 detik antar deteksi senyum

  // ===== PERSISTENT STATE - HARUS BERTAHAN LEBIH LAMA =====
  int _consecutiveHeadTiltLeft = 0;
  int _consecutiveHeadTiltRight = 0;
  int _consecutiveHeadDown = 0;
  static const int _requiredConsecutiveFrames =
      4; // Butuh 4 frame berturut-turut

  // ===== NOTIFIKASI REAL-TIME =====
  final notificationMessage = ''.obs;
  Timer? _notificationTimer;
  DateTime? _lastNotificationTime;
  static const int _notificationCooldownMs = 3000;

  DateTime? _lastPostureAlert;
  static const int _postureAlertCooldownMs = 8000; // Dinaikkan dari 6000

  // ===== STATUS TEKS (untuk UI) =====
  final eyeStatusText = ''.obs;
  final smileStatusText = ''.obs;
  final postureStatusText = ''.obs;

  // ===== GETTER =====
  int get lookAwayCount => lookAwayLeftCount.value + lookAwayRightCount.value;
  int get totalEyeViolations =>
      lookAwayLeftCount.value + lookAwayRightCount.value + lookDownCount.value;
  int get totalHeadViolations =>
      headTiltLeftCount.value + headTiltRightCount.value + headDownCount.value;

  @override
  void onInit() {
    super.onInit();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );
    initCamera();
  }

  @override
  void onClose() {
    stop();
    _notificationTimer?.cancel();
    _faceDetector.close();
    _poseDetector.close();
    cameraController?.dispose();
    super.onClose();
  }

  void setLevel(String level) {
    currentLevel = level;
    _updateThresholdsForLevel(level);
  }

  void _updateThresholdsForLevel(String level) {
    switch (level) {
      case 'advance':
        // Advance: lebih sensitif
        _lookAwayYawThr = 18.0;
        _lookDownPitchThr = 15.0;
        _headTiltLeftThr = 0.10; // Masih lebih tinggi dari sebelumnya
        _headTiltRightThr = 0.10;
        _headDownThr = 0.12;
        _smileThr = 0.25;
        break;
      case 'hard':
        // Hard: medium sensitif
        _lookAwayYawThr = 20.0;
        _lookDownPitchThr = 17.0;
        _headTiltLeftThr = 0.11;
        _headTiltRightThr = 0.11;
        _headDownThr = 0.13;
        _smileThr = 0.23;
        break;
      default:
        // Medium: PALING TOLERAN
        _lookAwayYawThr = 22.0;
        _lookDownPitchThr = 20.0;
        _headTiltLeftThr = 0.12; // 2x lebih toleran dari sebelumnya
        _headTiltRightThr = 0.12; // 2x lebih toleran dari sebelumnya
        _headDownThr = 0.15; // Hampir 2x lebih toleran
        _smileThr = 0.20;
        break;
    }
  }

  void resetAllCounters() {
    lookAwayLeftCount.value = 0;
    lookAwayRightCount.value = 0;
    lookDownCount.value = 0;
    smileCount.value = 0;
    neutralCount.value = 0;
    headTiltLeftCount.value = 0;
    headTiltRightCount.value = 0;
    headDownCount.value = 0;

    _wasLookingLeft = false;
    _wasLookingRight = false;
    _wasLookingDown = false;
    _wasSmiling = false;
    _wasHeadTiltLeft = false;
    _wasHeadTiltRight = false;
    _wasHeadDown = false;
    _smoothSmile = 0.0;
    _smoothShoulderDiff = 0.0;
    _smoothHeadDown = 0.0;
    _lastNotificationTime = null;
    _lastPostureAlert = null;
    _lastEyeViolation = null;
    _lastHeadViolation = null;
    _lastSmileDetection = null;
    _consecutiveHeadTiltLeft = 0;
    _consecutiveHeadTiltRight = 0;
    _consecutiveHeadDown = 0;

    _updateDescriptiveStatusTexts();
  }

  // ===== POIN PER KATEGORI =====
  int getEyeContactPoints() {
    final total =
        lookAwayLeftCount.value +
        lookAwayRightCount.value +
        lookDownCount.value;
    if (total <= 3) return 2;
    if (total <= 6) return 1;
    return 0;
  }

  int getFacialExpressionPoints() {
    final smile = smileCount.value;
    final neutral = neutralCount.value;
    if (smile >= 3 && smile > neutral) return 2;
    if (smile >= 1) return 1;
    return 0;
  }

  int getPosturePoints() {
    final total =
        headTiltLeftCount.value +
        headTiltRightCount.value +
        headDownCount.value;
    if (total <= 3) return 2;
    if (total <= 6) return 1;
    return 0;
  }

  // ===== LABEL 3 TINGKAT =====
  void _updateDescriptiveStatusTexts() {
    final totalEye =
        lookAwayLeftCount.value +
        lookAwayRightCount.value +
        lookDownCount.value;
    if (totalEye <= 3) {
      eyeStatusText.value = 'Fokus & Percaya Diri';
    } else if (totalEye <= 6) {
      eyeStatusText.value = 'Sesekali Terdistraksi';
    } else {
      eyeStatusText.value = 'Sering Kehilangan Fokus';
    }

    if (smileCount.value >= 3 && smileCount.value > neutralCount.value) {
      smileStatusText.value = 'Ramah & Antusias';
    } else if (smileCount.value >= 1) {
      smileStatusText.value = 'Cukup Ramah / Netral';
    } else {
      smileStatusText.value = 'Kaku & Tegang';
    }

    final totalHead =
        headTiltLeftCount.value +
        headTiltRightCount.value +
        headDownCount.value;
    if (totalHead <= 3) {
      postureStatusText.value = 'Tenang & Profesional';
    } else if (totalHead <= 6) {
      postureStatusText.value = 'Sedikit Gelisah';
    } else {
      postureStatusText.value = 'Gugup & Cemas';
    }
  }

  String getEyeLevelLabel() {
    final total =
        lookAwayLeftCount.value +
        lookAwayRightCount.value +
        lookDownCount.value;
    if (total <= 3) return 'Fokus & Percaya Diri';
    if (total <= 6) return 'Sesekali Terdistraksi';
    return 'Sering Kehilangan Fokus';
  }

  String getSmileLevelLabel() {
    final smile = smileCount.value;
    final neutral = neutralCount.value;
    if (smile >= 3 && smile > neutral) return 'Ramah & Antusias';
    if (smile >= 1) return 'Cukup Ramah / Netral';
    return 'Kaku & Tegang';
  }

  String getPostureLevelLabel() {
    final total =
        headTiltLeftCount.value +
        headTiltRightCount.value +
        headDownCount.value;
    if (total <= 3) return 'Tenang & Profesional';
    if (total <= 6) return 'Sedikit Gelisah';
    return 'Gugup & Cemas';
  }

  // ===== NOTIFIKASI =====
  void _showNotification(String message) {
    final now = DateTime.now();
    if (_lastNotificationTime != null &&
        now.difference(_lastNotificationTime!) <
            Duration(milliseconds: _notificationCooldownMs)) {
      return;
    }
    _lastNotificationTime = now;
    notificationMessage.value = message;
    _notificationTimer?.cancel();
    _notificationTimer = Timer(const Duration(seconds: 2), () {
      if (notificationMessage.value == message) {
        notificationMessage.value = '';
      }
    });
  }

  void _showPostureAlert(String message) {
    final now = DateTime.now();
    if (_lastPostureAlert != null &&
        now.difference(_lastPostureAlert!) <
            Duration(milliseconds: _postureAlertCooldownMs)) {
      return;
    }
    _lastPostureAlert = now;
    _showNotification(message);
  }

  // ===== KAMERA =====
  Future<void> initCamera() async {
    try {
      final camStatus = await Permission.camera.request();
      if (!camStatus.isGranted) {
        Get.snackbar('Izin Kamera', 'Aktifkan izin kamera di pengaturan');
        return;
      }
      cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final frontIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      final selected = cameras[frontIndex == -1 ? 0 : frontIndex];
      await _setupCamera(selected);
    } catch (e) {
      if (kDebugMode) print('Error inisialisasi kamera: $e');
    }
  }

  Future<void> _setupCamera(CameraDescription selected) async {
    isCameraReady.value = false;
    final formatGroup = Platform.isIOS
        ? ImageFormatGroup.bgra8888
        : ImageFormatGroup.nv21;
    final newController = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: formatGroup,
    );
    cameraController = newController;
    await cameraController!.initialize();
    await cameraController!.setZoomLevel(1.0);
    isCameraReady.value = true;
  }

  Future<void> start() async {
    if (!isCameraReady.value || cameraController == null) return;
    if (isRunning.value) return;
    try {
      isRunning.value = true;
      resetAllCounters();
      await cameraController!.startImageStream(_onFrame);
    } catch (e) {
      isRunning.value = false;
    }
  }

  Future<void> stop() async {
    try {
      if (cameraController != null &&
          cameraController!.value.isStreamingImages) {
        await cameraController!.stopImageStream();
      }
    } catch (_) {}
    isRunning.value = false;
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) return;
    await stop();
    final current = cameraController?.description;
    final newIndex = cameras.indexWhere(
      (c) => c.lensDirection != current!.lensDirection,
    );
    await _setupCamera(cameras[newIndex == -1 ? 0 : newIndex]);
    await start();
  }

  // ===== FRAME PROCESSING =====
  Future<void> _onFrame(CameraImage image) async {
    if (!isRunning.value || _processing) return;
    final now = DateTime.now();
    if (_lastProcess != null &&
        now.difference(_lastProcess!) <
            const Duration(milliseconds: _processIntervalMs)) {
      return;
    }
    _lastProcess = now;
    _processing = true;
    try {
      final input = _cameraImageToInputImage(image);
      if (input == null) return;
      final results = await Future.wait([
        _faceDetector.processImage(input),
        _poseDetector.processImage(input),
      ]);
      final faces = results[0] as List<Face>;
      final poses = results[1] as List<Pose>;
      final wasFaceDetected = isFaceDetected.value;
      isFaceDetected.value = faces.isNotEmpty;
      if (!wasFaceDetected && isFaceDetected.value) {
        _showNotification('Wajah terdeteksi!');
      }
      if (faces.isNotEmpty) _updateFromFace(faces.first);
      if (poses.isNotEmpty && isFaceDetected.value)
        _updateFromPose(poses.first);
    } catch (e) {
      if (kDebugMode) print('Error processing frame: $e');
    } finally {
      _processing = false;
    }
  }

  void _updateFromFace(Face face) {
    final yaw = (face.headEulerAngleY ?? 0).toDouble();
    final pitch = (face.headEulerAngleX ?? 0).toDouble();
    final smileProb = face.smilingProbability ?? 0.0;

    // Smoothing senyum
    _smoothSmile = (_smoothSmile == 0.0)
        ? smileProb
        : (0.7 * smileProb + 0.3 * _smoothSmile);

    final bool isSmiling = _smoothSmile > _smileThr;

    // Deteksi senyum dengan cooldown
    final now = DateTime.now();
    if (isSmiling && !_wasSmiling) {
      if (_lastSmileDetection == null ||
          now.difference(_lastSmileDetection!) >
              Duration(milliseconds: _smileDetectionCooldownMs)) {
        smileCount.value++;
        _lastSmileDetection = now;
        _showNotification('Senyum terdeteksi!');
      }
    } else if (!isSmiling && _wasSmiling && smileProb < 0.15) {
      if (_lastSmileDetection == null ||
          now.difference(_lastSmileDetection!) >
              Duration(milliseconds: _smileDetectionCooldownMs)) {
        neutralCount.value++;
        _lastSmileDetection = now;
      }
    }
    _wasSmiling = isSmiling;

    // Deteksi mata dengan cooldown
    final bool isLookingLeft = yaw < -_lookAwayYawThr;
    if (isLookingLeft && !_wasLookingLeft) {
      if (_lastEyeViolation == null ||
          now.difference(_lastEyeViolation!) >
              Duration(milliseconds: _eyeViolationCooldownMs)) {
        lookAwayLeftCount.value++;
        _lastEyeViolation = now;
        _showNotification('Mata: Melirik ke kiri');
      }
    }
    _wasLookingLeft = isLookingLeft;

    final bool isLookingRight = yaw > _lookAwayYawThr;
    if (isLookingRight && !_wasLookingRight) {
      if (_lastEyeViolation == null ||
          now.difference(_lastEyeViolation!) >
              Duration(milliseconds: _eyeViolationCooldownMs)) {
        lookAwayRightCount.value++;
        _lastEyeViolation = now;
        _showNotification('Mata: Melirik ke kanan');
      }
    }
    _wasLookingRight = isLookingRight;

    final bool isLookingDown = pitch > _lookDownPitchThr;
    if (isLookingDown && !_wasLookingDown) {
      if (_lastEyeViolation == null ||
          now.difference(_lastEyeViolation!) >
              Duration(milliseconds: _eyeViolationCooldownMs)) {
        lookDownCount.value++;
        _lastEyeViolation = now;
        _showNotification('Mata: Menunduk');
      }
    }
    _wasLookingDown = isLookingDown;
    _updateDescriptiveStatusTexts();
  }

  void _updateFromPose(Pose pose) {
    if (!isFaceDetected.value) return;

    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftEye = pose.landmarks[PoseLandmarkType.leftEye];
    final rightEye = pose.landmarks[PoseLandmarkType.rightEye];

    if (leftShoulder != null && rightShoulder != null) {
      final shoulderDiff = rightShoulder.y - leftShoulder.y;

      // Smoothing yang lebih agresif
      _smoothShoulderDiff = (_smoothShoulderDiff == 0.0)
          ? shoulderDiff
          : (0.6 * shoulderDiff + 0.4 * _smoothShoulderDiff); // Lebih smooth

      // Deteksi dengan consecutive frames
      final bool isTiltLeft = _smoothShoulderDiff > _headTiltLeftThr;
      final bool isTiltRight = _smoothShoulderDiff < -_headTiltRightThr;

      // Update consecutive counters
      if (isTiltLeft) {
        _consecutiveHeadTiltLeft++;
        _consecutiveHeadTiltRight = 0;
      } else if (isTiltRight) {
        _consecutiveHeadTiltRight++;
        _consecutiveHeadTiltLeft = 0;
      } else {
        _consecutiveHeadTiltLeft = 0;
        _consecutiveHeadTiltRight = 0;
      }

      // Hanya trigger jika consecutive frames mencapai threshold
      final now = DateTime.now();
      if (_consecutiveHeadTiltLeft >= _requiredConsecutiveFrames &&
          !_wasHeadTiltLeft) {
        if (_lastHeadViolation == null ||
            now.difference(_lastHeadViolation!) >
                Duration(milliseconds: _headViolationCooldownMs)) {
          headTiltLeftCount.value++;
          _lastHeadViolation = now;
          _showPostureAlert('Postur: Kepala miring ke kiri');
        }
      }

      if (_consecutiveHeadTiltRight >= _requiredConsecutiveFrames &&
          !_wasHeadTiltRight) {
        if (_lastHeadViolation == null ||
            now.difference(_lastHeadViolation!) >
                Duration(milliseconds: _headViolationCooldownMs)) {
          headTiltRightCount.value++;
          _lastHeadViolation = now;
          _showPostureAlert('Postur: Kepala miring ke kanan');
        }
      }

      _wasHeadTiltLeft = _consecutiveHeadTiltLeft >= _requiredConsecutiveFrames;
      _wasHeadTiltRight =
          _consecutiveHeadTiltRight >= _requiredConsecutiveFrames;
    }

    if (nose != null && leftEye != null && rightEye != null) {
      final eyeCenterY = (leftEye.y + rightEye.y) / 2;
      final headDownValue = nose.y - eyeCenterY;

      // Smoothing lebih agresif
      _smoothHeadDown = (_smoothHeadDown == 0.0)
          ? headDownValue
          : (0.6 * headDownValue + 0.4 * _smoothHeadDown); // Lebih smooth

      final bool isHeadDown = _smoothHeadDown > _headDownThr;

      // Consecutive frame counter
      if (isHeadDown) {
        _consecutiveHeadDown++;
      } else {
        _consecutiveHeadDown = 0;
      }

      // Trigger dengan consecutive frames
      final now = DateTime.now();
      if (_consecutiveHeadDown >= _requiredConsecutiveFrames && !_wasHeadDown) {
        if (_lastHeadViolation == null ||
            now.difference(_lastHeadViolation!) >
                Duration(milliseconds: _headViolationCooldownMs)) {
          headDownCount.value++;
          _lastHeadViolation = now;
          _showPostureAlert('Postur: Kepala menunduk');
        }
      }

      _wasHeadDown = _consecutiveHeadDown >= _requiredConsecutiveFrames;
    }
  }

  // ===== HELPER KONVERSI GAMBAR =====
  InputImageRotation _toInputImageRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation90deg;
    }
  }

  InputImage? _cameraImageToInputImage(CameraImage image) {
    final rot = _toInputImageRotation(
      cameraController?.description.sensorOrientation ?? 90,
    );
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) allBytes.putUint8List(plane.bytes);
    final bytes = allBytes.done().buffer.asUint8List();
    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        (Platform.isAndroid
            ? InputImageFormat.nv21
            : InputImageFormat.bgra8888);
    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: rot,
      format: inputImageFormat,
      bytesPerRow: image.planes.first.bytesPerRow,
    );
    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  void startWindowTimer() {
    // Method ini sengaja dikosongkan karena tidak digunakan lagi
  }

  void stopWindowTimer() {
    // Method ini sengaja dikosongkan karena tidak digunakan lagi
  }
}
