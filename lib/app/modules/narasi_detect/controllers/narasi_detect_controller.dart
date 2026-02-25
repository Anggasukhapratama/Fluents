import 'dart:math' as math;
import 'dart:math';
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
  // ===== Kamera =====
  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  final isCameraReady = false.obs;
  final isRunning = false.obs;

  // Throttling untuk mencegah overload
  DateTime? _lastProcess;
  bool _processing = false;

  static const int _processIntervalMs = 200; // 5 FPS

  // ===== ML Kit Detector =====
  late final FaceDetector _faceDetector;
  late final PoseDetector _poseDetector;

  // ===== Output untuk UI =====
  final headTiltDeg = 0.0.obs;
  final headYawDeg = 0.0.obs;
  final headPitchDeg = 0.0.obs;
  final mouthOpenRatio = 0.0.obs;
  final postureLeanScore = 0.0.obs;

  // ✅ Eye Contact (0..1)
  final eyeContactRatio = 0.0.obs;

  // ✅ STATUS DETEKSI Wajah
  final isFaceDetected = false.obs; // Tambahan: apakah wajah terdeteksi
  final faceDetectionMessage = ''.obs; // Pesan untuk user

  // Score untuk analisis (0..100)
  final scoreMouth = 0.obs;
  final scoreTilt = 0.obs;
  final scorePosture = 0.obs;
  final scoreEye = 0.obs;
  final nervousScore = 0.obs;
  final nervousLabel = 'Tenang'.obs;

  // ===== Internal variables =====
  InputImageRotation? _rotation;

  // ===== Anti reset / smoothing =====
  DateTime? _lastFaceSeenAt;
  DateTime? _lastNoFaceWarningAt; // Untuk throttle notifikasi

  // hold last good values
  double _lastMouthRatio = 0.0;
  double _lastTiltDeg = 0.0;
  double _lastYawDeg = 0.0;
  double _lastPitchDeg = 0.0;
  double _lastEyeRatio = 0.0;

  // Simple smoothing
  double _smoothMouth = 0.0;
  double _smoothTiltAbs = 0.0;
  double _smoothPosture = 0.0;
  double _smoothEye = 0.0;

  // tuning
  static const int _faceHoldMs = 500;
  static const double _smoothFactor = 0.35;

  // ✅ Eye contact thresholds
  static const double _eyeYawThr = 12.0;
  static const double _eyePitchThr = 10.0;

  // ✅ Bobot nervous
  static const double _wMouth = 0.33;
  static const double _wTilt = 0.27;
  static const double _wPosture = 0.30;
  static const double _wEye = 0.10;

  @override
  void onInit() {
    super.onInit();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.fast,
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
    _faceDetector.close();
    _poseDetector.close();
    cameraController?.dispose();
    super.onClose();
  }

  String get tiltStatus {
    if (!isFaceDetected.value) return 'Wajah tidak terdeteksi';
    final t = headTiltDeg.value.abs();
    if (t <= 6) return 'Tegak';
    if (t <= 12) return 'Agak miring';
    if (t <= 18) return 'Miring';
    return 'Sangat miring';
  }

  String get postureStatus {
    if (!isFaceDetected.value) return 'Wajah tidak terdeteksi';
    final p = postureLeanScore.value * 100;
    if (p <= 20) return 'Tegak';
    if (p <= 45) return 'Agak miring';
    if (p <= 70) return 'Miring';
    return 'Sangat miring';
  }

  String get mouthStatus {
    if (!isFaceDetected.value) return 'Wajah tidak terdeteksi';
    final r = mouthOpenRatio.value;
    if (r < 0.12) return 'Diam';
    if (r < 0.22) return 'Bicara pelan';
    if (r < 0.45) return 'Bicara normal';
    return 'Terlalu terbuka';
  }

  String get eyeStatus {
    if (!isFaceDetected.value) return 'Wajah tidak terdeteksi';
    final e = eyeContactRatio.value;
    if (e >= 0.75) return 'Bagus';
    if (e >= 0.50) return 'Cukup';
    if (e >= 0.30) return 'Kurang';
    return 'Buruk';
  }

  Future<void> initCamera() async {
    try {
      final camStatus = await Permission.camera.request();
      if (!camStatus.isGranted) {
        Get.snackbar(
          'Izin Kamera',
          'Aktifkan izin kamera di pengaturan device',
        );
        return;
      }

      cameras = await availableCameras();
      if (cameras.isEmpty) {
        Get.snackbar('Kamera', 'Tidak ada kamera yang tersedia');
        return;
      }

      final frontIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      final selected = cameras[frontIndex == -1 ? 0 : frontIndex];

      final formatGroup = Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.nv21;

      cameraController = CameraController(
        selected,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: formatGroup,
      );

      await cameraController!.initialize();
      _rotation = _toInputImageRotation(selected.sensorOrientation);

      isCameraReady.value = true;
      if (kDebugMode) print('✅ Kamera siap: ${selected.name}');
    } catch (e) {
      if (kDebugMode) print('❌ Error inisialisasi kamera: $e');
      Get.snackbar('Kamera', 'Gagal mengakses kamera: $e');
    }
  }

  Future<void> start() async {
    if (!isCameraReady.value || cameraController == null) {
      Get.snackbar('Kamera', 'Kamera belum siap');
      return;
    }
    if (isRunning.value) return;

    try {
      isRunning.value = true;
      await cameraController!.startImageStream(_onFrame);
      if (kDebugMode) print('✅ Stream kamera dimulai');
    } catch (e) {
      isRunning.value = false;
      if (kDebugMode) print('❌ Error start stream: $e');
      Get.snackbar('Stream', 'Gagal memulai stream: $e');
    }
  }

  Future<void> stop() async {
    try {
      if (cameraController != null &&
          cameraController!.value.isStreamingImages) {
        await cameraController!.stopImageStream();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error stop stream: $e');
    }
    isRunning.value = false;
    if (kDebugMode) print('⏹️ Stream kamera dihentikan');
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) {
      Get.snackbar('Kamera', 'Hanya 1 kamera tersedia');
      return;
    }

    try {
      await stop();

      final current = cameraController?.description;
      if (current == null) return;

      final currentDir = current.lensDirection;
      final newIndex = cameras.indexWhere((c) => c.lensDirection != currentDir);
      final selected = cameras[newIndex == -1 ? 0 : newIndex];

      isCameraReady.value = false;
      await cameraController?.dispose();

      final formatGroup = Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.nv21;

      cameraController = CameraController(
        selected,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: formatGroup,
      );

      await cameraController!.initialize();
      _rotation = _toInputImageRotation(selected.sensorOrientation);

      isCameraReady.value = true;
      await start();

      if (kDebugMode) print('🔄 Ganti kamera ke: ${selected.name}');
    } catch (e) {
      if (kDebugMode) print('❌ Error ganti kamera: $e');
      Get.snackbar('Kamera', 'Gagal ganti kamera: $e');
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (!isRunning.value) return;
    if (_processing) return;

    final now = DateTime.now();
    if (_lastProcess != null &&
        now.difference(_lastProcess!) <
            Duration(milliseconds: _processIntervalMs)) {
      return;
    }
    _lastProcess = now;

    _processing = true;
    try {
      final input = _cameraImageToInputImage(image);
      if (input == null) return;

      final faces = await _faceDetector.processImage(input);
      final poses = await _poseDetector.processImage(input);

      // ✅ Update status deteksi wajah
      final faceDetected = faces.isNotEmpty;
      isFaceDetected.value = faceDetected;

      // ✅ Set pesan berdasarkan status deteksi
      if (!faceDetected) {
        faceDetectionMessage.value =
            'Wajah tidak terdeteksi - pastikan wajah terlihat jelas';

        // Throttle notifikasi (muncul setiap 5 detik)
        if (_lastNoFaceWarningAt == null ||
            now.difference(_lastNoFaceWarningAt!) >
                const Duration(seconds: 5)) {
          _lastNoFaceWarningAt = now;
          if (kDebugMode) print('⚠️ PERINGATAN: Wajah tidak terdeteksi!');
          // Bisa ditambahkan snackbar atau sound jika perlu
        }
      } else {
        faceDetectionMessage.value = '';
      }

      _updateFromFace(faces.isNotEmpty ? faces.first : null);
      _updateFromPose(poses.isNotEmpty ? poses.first : null);

      _recomputeScores();
    } catch (e) {
      if (kDebugMode) print('❌ Error proses frame: $e');
    } finally {
      _processing = false;
    }
  }

  void _updateFromFace(Face? face) {
    final now = DateTime.now();

    if (face == null) {
      final last = _lastFaceSeenAt;
      final shouldHold =
          last != null && now.difference(last).inMilliseconds <= _faceHoldMs;

      if (shouldHold) {
        headPitchDeg.value = _lastPitchDeg;
        headYawDeg.value = _lastYawDeg;
        headTiltDeg.value = _lastTiltDeg;
        mouthOpenRatio.value = _lastMouthRatio;
        eyeContactRatio.value = _lastEyeRatio;
        return;
      }

      // Saat wajah hilang, kita set nilai default TAPI biarkan isFaceDetected false
      // sehingga di _recomputeScores akan masuk ke kondisi khusus
      _lastPitchDeg = 0.0;
      _lastYawDeg = 0.0;
      _lastTiltDeg = 0.0;
      _lastMouthRatio = 0.0;
      _lastEyeRatio = 0.0;

      headPitchDeg.value = 0.0;
      headYawDeg.value = 0.0;
      headTiltDeg.value = 0.0;
      mouthOpenRatio.value = 0.0;
      eyeContactRatio.value = 0.0;

      // ✅ Pastikan isFaceDetected sudah false dari _onFrame
      // Tidak perlu set ulang di sini
      return;
    }
    // face terdeteksi
    _lastFaceSeenAt = now;

    final pitch = (face.headEulerAngleX ?? 0).toDouble();
    final yaw = (face.headEulerAngleY ?? 0).toDouble();
    final tilt = (face.headEulerAngleZ ?? 0).toDouble();

    headPitchDeg.value = pitch;
    headYawDeg.value = yaw;
    headTiltDeg.value = tilt;

    // ✅ Eye contact
    final goodEye = yaw.abs() <= _eyeYawThr && pitch.abs() <= _eyePitchThr;
    final eyeVal = goodEye ? 1.0 : 0.0;
    _smoothEye = (_smoothEye == 0.0)
        ? eyeVal
        : (_smoothFactor * eyeVal + (1 - _smoothFactor) * _smoothEye);
    eyeContactRatio.value = _smoothEye.clamp(0.0, 1.0);

    double ratio = 0.0;

    final upper = face.contours[FaceContourType.upperLipTop]?.points;
    final lower = face.contours[FaceContourType.lowerLipBottom]?.points;
    final mouth = face.contours[FaceContourType.lowerLipTop]?.points;

    if (upper != null &&
        upper.isNotEmpty &&
        lower != null &&
        lower.isNotEmpty) {
      final upMid = upper[upper.length ~/ 2];
      final lowMid = lower[lower.length ~/ 2];

      double width = 0;
      if (mouth != null && mouth.length >= 2) {
        width = _dist(mouth.first, mouth.last);
      } else {
        width = _dist(upper.first, upper.last);
      }

      final open = _dist(upMid, lowMid);
      ratio = width > 0 ? (open / width) : 0.0;
      ratio = ratio.clamp(0.0, 1.0);
    } else {
      ratio = _lastMouthRatio;
    }

    _smoothMouth = (_smoothMouth == 0.0)
        ? ratio
        : (_smoothFactor * ratio + (1 - _smoothFactor) * _smoothMouth);
    mouthOpenRatio.value = _smoothMouth.clamp(0.0, 1.0);

    _lastPitchDeg = pitch;
    _lastYawDeg = yaw;
    _lastTiltDeg = tilt;
    _lastMouthRatio = mouthOpenRatio.value;
    _lastEyeRatio = eyeContactRatio.value;
  }

  void _updateFromPose(Pose? pose) {
    if (pose == null) {
      _smoothPosture = 0.0;
      postureLeanScore.value = 0.0;
      return;
    }

    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];

    if (ls == null || rs == null || lh == null || rh == null) {
      _smoothPosture = 0.0;
      postureLeanScore.value = 0.0;
      return;
    }

    final dx = rs.x - ls.x;
    final dy = rs.y - ls.y;
    final angle = math.atan2(dy, dx);
    final tiltDeg = angle * 180 / math.pi;

    final absTilt = tiltDeg.abs();
    final lean01 = (absTilt / 20.0).clamp(0, 1);

    final shCx = (ls.x + rs.x) / 2;
    final hipCx = (lh.x + rh.x) / 2;
    final offset = (shCx - hipCx).abs();
    final offset01 = (offset / 40.0).clamp(0, 1);

    final raw = (((lean01 * 0.6) + (offset01 * 0.4)).clamp(
      0.0,
      1.0,
    )).toDouble();

    _smoothPosture = (_smoothPosture == 0.0)
        ? raw
        : (_smoothFactor * raw + (1.0 - _smoothFactor) * _smoothPosture);
    postureLeanScore.value = _smoothPosture.clamp(0.0, 1.0);
  }

  void _recomputeScores() {
    // ✅ Jika wajah tidak terdeteksi, set semua skor ke 0 dan nervous = 100 (Gugup karena tidak terlihat)
    if (!isFaceDetected.value) {
      scoreMouth.value = 0;
      scoreTilt.value = 0;
      scorePosture.value = 0;
      scoreEye.value = 0; // 0 karena tidak ada kontak mata
      nervousScore.value = 100;
      nervousLabel.value = 'Wajah Tidak Terdeteksi';
      return;
    }

    // ===== Mouth score =====
    final r = mouthOpenRatio.value;

    const low = 0.16;
    const idealLow = 0.20;
    const idealHigh = 0.34;
    const high = 0.48;

    int mouthScore;
    if (r < low) {
      mouthScore = ((r / low) * 40).round();
    } else if (r <= idealLow) {
      mouthScore = 60 + (((r - low) / (idealLow - low)) * 40).round();
    } else if (r <= idealHigh) {
      mouthScore = 100;
    } else if (r <= high) {
      mouthScore = 100 - (((r - idealHigh) / (high - idealHigh)) * 60).round();
    } else {
      mouthScore = 30;
    }

    final mouthPenalty = (100 - mouthScore).clamp(0, 100);
    scoreMouth.value = mouthPenalty;

    // ===== Tilt score =====
    final tiltAbs = headTiltDeg.value.abs();
    _smoothTiltAbs = (_smoothTiltAbs == 0.0)
        ? tiltAbs
        : (_smoothFactor * tiltAbs + (1 - _smoothFactor) * _smoothTiltAbs);

    final tPenalty = (_smoothTiltAbs <= 6)
        ? 0
        : (_smoothTiltAbs >= 18)
        ? 100
        : (((_smoothTiltAbs - 6) / (18 - 6)) * 100).round();
    scoreTilt.value = tPenalty.clamp(0, 100);

    // ===== Posture score =====
    scorePosture.value = (postureLeanScore.value * 100).round().clamp(0, 100);

    // ===== Eye score =====
    // ===== Eye score (Sekarang 0 = jelek, 100 = bagus) =====
    scoreEye.value = (eyeContactRatio.value.clamp(0.0, 1.0) * 100)
        .round()
        .clamp(0, 100);

    // ===== Overall nervous score =====
    final ns =
        (scoreMouth.value * _wMouth +
                scoreTilt.value * _wTilt +
                scorePosture.value * _wPosture +
                scoreEye.value * _wEye)
            .round()
            .clamp(0, 100);

    nervousScore.value = ns;

    if (ns >= 75) {
      nervousLabel.value = 'Gugup';
    } else if (ns >= 45) {
      nervousLabel.value = 'Kurang percaya diri';
    } else {
      nervousLabel.value = 'Tenang';
    }
  }

  double _dist(Point<int> a, Point<int> b) {
    final dx = (a.x - b.x).toDouble();
    final dy = (a.y - b.y).toDouble();
    return math.sqrt(dx * dx + dy * dy);
  }

  InputImage? _cameraImageToInputImage(CameraImage image) {
    final rot = _rotation;
    if (rot == null) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
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
}
