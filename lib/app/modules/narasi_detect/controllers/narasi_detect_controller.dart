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

  // ========== EKSPRESI WAJAH ==========
  // Threshold senyum (Garcia & Perez, 2018)
  double _smileThr = 0.50; // Probabilitas 0.50

  // ===== MOMEN ANTUSIAS DETECTION =====
  // Berdasarkan: Ruben, M. A., Hall, J. A., & Schmid Mast, M. (2015).
  // "Smiling in a Job Interview: When Less Is More."
  // Journal of Social Psychology, 155(2), 107-126.
  //
  // Konsep: hitung berapa kali kandidat menunjukkan ekspresi antusias
  // (1 momen antusias = ekspresi antusias bertahan minimal 1 detik)
  //
  // Penilaian:
  //  - 2-5 momen   → IDEAL (Antusias & Profesional)
  //  - 1 atau 6-9  → CUKUP
  //  - 0 momen     → KURANG (Datar & Tegang)
  //  - 10+ momen   → BERLEBIHAN
  static const int _momentMinDurationMs = 1000; // Minimal 1 detik untuk dianggap "1 momen"
  static const int _momentCooldownMs = 1500;    // Jeda antar momen baru

  // Variabel untuk menyimpan lebar bahu (untuk kalkulasi sudut)
  double _lastShoulderWidth =
      1.0; // Default 1.0 untuk menghindari division by zero

  String currentLevel = 'medium';

  // ===== COUNTER MOMEN TIDAK FOKUS & TIDAK STABIL =====
  final lookAwayLeftCount = 0.obs;
  final lookAwayRightCount = 0.obs;
  final lookDownCount = 0.obs;
  final smileCount = 0.obs; // Tetap ada untuk backward compatibility
  final neutralCount = 0.obs; // Tetap ada untuk backward compatibility
  final headTiltLeftCount = 0.obs;
  final headTiltRightCount = 0.obs;
  final headDownCount = 0.obs;

  // ===== EKSPRESI: MOMEN ANTUSIAS TRACKING =====
  // Hitung berapa kali kandidat menunjukkan momen antusias (durasi minimal 1 detik)
  final enthusiasmMomentCount = 0.obs;       // Jumlah momen antusias terdeteksi
  final smileFrameCount = 0.obs;             // Frame antusias (smileProb >= 0.50)
  final neutralFrameCount = 0.obs;           // Frame netral (0.15 <= smileProb < 0.50)
  final stiffFrameCount = 0.obs;             // Frame datar (smileProb < 0.15)
  final totalExpressionFrames = 0.obs;

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

  // ===== STATE UNTUK MOMEN ANTUSIAS =====
  DateTime? _enthusiasmStartTime;     // Kapan ekspresi antusias mulai
  DateTime? _lastMomentDetectedAt;    // Kapan momen antusias terakhir dihitung
  bool _momentAlreadyCountedInSession = false; // Sudah dihitung di sesi antusias ini?

  // ===== COOLDOWN UNTUK MENCEGAH SPAM DETEKSI =====
  DateTime? _lastEyeViolation;
  DateTime? _lastHeadViolation;
  DateTime? _lastSmileDetection;
  static const int _eyeViolationCooldownMs =
      2000; // 2 detik antar momen tidak fokus
  static const int _headViolationCooldownMs =
      2500; // 2.5 detik antar momen tidak stabil
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

    // Reset time-based expression tracking
    smileFrameCount.value = 0;
    neutralFrameCount.value = 0;
    stiffFrameCount.value = 0;
    totalExpressionFrames.value = 0;

    // Reset momen antusias
    enthusiasmMomentCount.value = 0;
    _enthusiasmStartTime = null;
    _lastMomentDetectedAt = null;
    _momentAlreadyCountedInSession = false;

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
    final moments = enthusiasmMomentCount.value;

    // ===== PENILAIAN BERBASIS JURNAL =====
    // Ruben, Hall, & Schmid Mast (2015): "When Less Is More"
    // Konsep: hitung berapa kali kandidat menunjukkan momen antusias
    // - 2-5 momen   → IDEAL (Antusias & Profesional)
    // - 1 atau 6-9  → CUKUP
    // - 0 momen     → Datar & Tegang
    // - 10+ momen   → Antusias Berlebihan

    if (moments >= 2 && moments <= 5) {
      return 2; // Antusias & Profesional
    }
    if (moments == 1 || (moments >= 6 && moments <= 9)) {
      return 1; // Cukup Antusias
    }
    // moments == 0 atau moments >= 10
    return 0; // Datar & Tegang ATAU Antusias Berlebihan
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

    // Update status ekspresi berdasarkan jumlah momen antusias
    // Threshold berdasarkan: Ruben, Hall, & Schmid Mast (2015)
    final moments = enthusiasmMomentCount.value;
    if (moments >= 2 && moments <= 5) {
      smileStatusText.value = 'Antusias & Profesional';
    } else if (moments >= 10) {
      smileStatusText.value = 'Antusias Berlebihan';
    } else if (moments == 0) {
      smileStatusText.value = 'Datar & Tegang';
    } else {
      // 1 momen atau 6-9 momen
      smileStatusText.value = 'Cukup Antusias';
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
    final moments = enthusiasmMomentCount.value;

    // Threshold berdasarkan: Ruben, Hall, & Schmid Mast (2015)
    if (moments >= 2 && moments <= 5) {
      return 'Antusias & Profesional';
    }
    if (moments >= 10) {
      return 'Antusias Berlebihan';
    }
    if (moments == 0) {
      return 'Datar & Tegang';
    }
    // 1 momen atau 6-9 momen
    return 'Cukup Antusias';
  }

  /// Helper: jumlah momen antusias (untuk ditampilkan di UI)
  int getEnthusiasmMomentCount() => enthusiasmMomentCount.value;

  /// Helper: Persentase senyum (untuk ditampilkan di UI/AI prompt)
  double getSmilePercentage() {
    final total = totalExpressionFrames.value;
    if (total == 0) return 0.0;
    return (smileFrameCount.value / total) * 100;
  }

  /// Helper: Persentase netral
  double getNeutralPercentage() {
    final total = totalExpressionFrames.value;
    if (total == 0) return 0.0;
    return (neutralFrameCount.value / total) * 100;
  }

  /// Helper: Persentase kaku/tegang
  double getStiffPercentage() {
    final total = totalExpressionFrames.value;
    if (total == 0) return 0.0;
    return (stiffFrameCount.value / total) * 100;
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

    // ===== TRACKING FRAME EKSPRESI (untuk data tambahan) =====
    totalExpressionFrames.value++;
    if (_smoothSmile >= 0.50) {
      smileFrameCount.value++;
    } else if (_smoothSmile >= 0.15) {
      neutralFrameCount.value++;
    } else {
      stiffFrameCount.value++;
    }

    final bool isEnthusiastic = _smoothSmile >= _smileThr;
    final now = DateTime.now();

    // ===== MOMEN ANTUSIAS DETECTION =====
    // 1 momen = ekspresi antusias bertahan minimal 1 detik
    if (isEnthusiastic) {
      // Mulai tracking momen antusias
      if (_enthusiasmStartTime == null) {
        _enthusiasmStartTime = now;
        _momentAlreadyCountedInSession = false;
      } else if (!_momentAlreadyCountedInSession) {
        // Cek apakah sudah cukup lama (≥ 1 detik) dan jeda dari momen terakhir cukup
        final duration = now.difference(_enthusiasmStartTime!).inMilliseconds;
        final cooldownOk = _lastMomentDetectedAt == null ||
            now.difference(_lastMomentDetectedAt!).inMilliseconds >= _momentCooldownMs;

        if (duration >= _momentMinDurationMs && cooldownOk) {
          enthusiasmMomentCount.value++;
          _lastMomentDetectedAt = now;
          _momentAlreadyCountedInSession = true;
        }
      }
    } else {
      // Reset state ketika ekspresi kembali ke netral/datar
      _enthusiasmStartTime = null;
      _momentAlreadyCountedInSession = false;
    }

    // ===== Backward compat: smileCount & neutralCount =====
    if (isEnthusiastic && !_wasSmiling) {
      if (_lastSmileDetection == null ||
          now.difference(_lastSmileDetection!) >
              Duration(milliseconds: _smileDetectionCooldownMs)) {
        smileCount.value++;
        _lastSmileDetection = now;
      }
    } else if (!isEnthusiastic && _wasSmiling && smileProb < 0.15) {
      if (_lastSmileDetection == null ||
          now.difference(_lastSmileDetection!) >
              Duration(milliseconds: _smileDetectionCooldownMs)) {
        neutralCount.value++;
        _lastSmileDetection = now;
      }
    }
    _wasSmiling = isEnthusiastic;

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
