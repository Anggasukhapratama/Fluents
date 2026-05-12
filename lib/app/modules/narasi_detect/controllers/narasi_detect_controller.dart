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

  // ===== THRESHOLD DETEKSI - DIPERBARUI DENGAN REFERENSI JURNAL =====
  // Kontak mata (Ye et al., 2021)
  double _lookAwayYawThr = 20.0; // Yaw 20° untuk melirik
  double _lookDownPitchThr = 21.0; // Pitch 21° untuk menunduk

  // POSTUR - Xing et al. (2023)
  // Sudut bahu miring 2° (dikonversi dari radian)
  double _headTiltAngleThr = 0.0349; // 2° dalam radian

  // Senyum (Garcia & Perez, 2018)
  double _smileThr = 0.50; // Probabilitas 0.50

  // Variabel untuk menyimpan lebar bahu (untuk kalkulasi sudut)
  double _lastShoulderWidth =
      1.0; // Default 1.0 untuk menghindari division by zero

  String currentLevel = 'medium';

  // ===== COUNTER PELANGGARAN =====
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
  double _smoothShoulderAngle = 0.0; // Diubah dari _smoothShoulderDiff

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
    // Threshold kontak mata sesuai Ye et al. (2021) untuk semua level
    _lookAwayYawThr = 20.0; // Yaw 20°
    _lookDownPitchThr = 21.0; // Pitch 21°

    // Threshold senyum sesuai Garcia & Perez (2018)
    _smileThr = 0.50;

    // Threshold bahu miring sesuai Xing et al. (2023) - 2° untuk semua level
    _headTiltAngleThr = 0.0349; // 2° dalam radian

    // Semua level menggunakan standar jurnal yang sama
    switch (level) {
      case 'advance':
        // Threshold tetap sama sesuai standar jurnal
        break;
      case 'hard':
        // Threshold tetap sama sesuai standar jurnal
        break;
      default: // medium
        // Threshold tetap sama sesuai standar jurnal
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
    _smoothShoulderAngle = 0.0;
    _lastNotificationTime = null;
    _lastPostureAlert = null;
    _lastEyeViolation = null;
    _lastHeadViolation = null;
    _lastSmileDetection = null;
    _consecutiveHeadTiltLeft = 0;
    _consecutiveHeadTiltRight = 0;
    _consecutiveHeadDown = 0;

    _lastShoulderWidth = 1.0;

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
    // Nose dan Eye TIDAK digunakan lagi karena redundant dengan Face Detection

    if (leftShoulder != null && rightShoulder != null) {
      // Hitung lebar bahu (jarak horizontal)
      final shoulderWidth = (rightShoulder.x - leftShoulder.x).abs();

      // Update lebar bahu dengan smoothing untuk stabilitas
      if (shoulderWidth > 0.01) {
        // Validasi minimal width
        _lastShoulderWidth = _lastShoulderWidth == 1.0
            ? shoulderWidth
            : (0.7 * shoulderWidth + 0.3 * _lastShoulderWidth);
      }

      // Hitung perbedaan Y (vertikal) antara bahu kanan dan kiri
      final shoulderDiffY = rightShoulder.y - leftShoulder.y;

      // Hitung SUDUT kemiringan bahu dalam radian
      // Sudut = atan2(perbedaan_vertikal, lebar_bahu)
      final shoulderAngle = math.atan2(shoulderDiffY, _lastShoulderWidth);

      // Smoothing sudut untuk stabilitas
      _smoothShoulderAngle = (_smoothShoulderAngle == 0.0)
          ? shoulderAngle
          : (0.6 * shoulderAngle + 0.4 * _smoothShoulderAngle);

      // Deteksi kemiringan berdasarkan SUDUT (bukan pixel difference)
      // Bahu kanan lebih tinggi = sudut positif = miring ke kiri
      // Bahu kiri lebih tinggi = sudut negatif = miring ke kanan
      final bool isTiltLeft = _smoothShoulderAngle > _headTiltAngleThr;
      final bool isTiltRight = _smoothShoulderAngle < -_headTiltAngleThr;

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
          _showPostureAlert('Postur: Bahu miring ke kiri');
        }
      }

      if (_consecutiveHeadTiltRight >= _requiredConsecutiveFrames &&
          !_wasHeadTiltRight) {
        if (_lastHeadViolation == null ||
            now.difference(_lastHeadViolation!) >
                Duration(milliseconds: _headViolationCooldownMs)) {
          headTiltRightCount.value++;
          _lastHeadViolation = now;
          _showPostureAlert('Postur: Bahu miring ke kanan');
        }
      }

      _wasHeadTiltLeft = _consecutiveHeadTiltLeft >= _requiredConsecutiveFrames;
      _wasHeadTiltRight =
          _consecutiveHeadTiltRight >= _requiredConsecutiveFrames;
    }

    // ===== DETEKSI KEPALA MENUNDUK VIA POSE DIHAPUS =====
    // Deteksi kepala menunduk via Nose-Eye SUDAH DIHAPUS
    // karena sudah dicover oleh Face Detection (Pitch 21° dari Ye et al., 2021)
    // Counter headDownCount tetap dipertahankan untuk backward compatibility
    // tapi hanya akan bertambah dari Face Detection (Pitch 21°)

    // Reset _wasHeadDown karena tidak digunakan lagi
    _wasHeadDown = false;
    _consecutiveHeadDown = 0;
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
