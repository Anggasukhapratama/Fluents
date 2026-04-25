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
  static const int _processIntervalMs = 200; // 5 FPS

  // ===== ML KIT DETECTOR =====
  late final FaceDetector _faceDetector;
  late final PoseDetector _poseDetector;

  // ===== STATUS WAJAH =====
  final isFaceDetected = false.obs;

  // ===== THRESHOLD UNTUK DETEKSI =====
  static const double _smileThr = 0.30;
  static const double _lookAwayYawThr = 12.0;
  static const double _lookDownPitchThr = 8.0;
  static const double _headTiltLeftThr = 0.08;
  static const double _headTiltRightThr = 0.08;
  static const double _headDownThr = 0.15;

  // ===== COUNTER PELANGGARAN (FREKUENSI) =====
  // Kontak Mata
  final lookAwayCount = 0.obs; // Mengalihkan pandangan ke samping
  final lookDownCount = 0.obs; // Menunduk

  // Ekspresi Wajah
  final smileCount = 0.obs; // Tersenyum
  final neutralCount = 0.obs; // Wajah datar/kaku

  // Postur Kepala
  final headTiltLeftCount = 0.obs; // Kepala miring kiri
  final headTiltRightCount = 0.obs; // Kepala miring kanan
  final headDownCount = 0.obs; // Kepala menunduk

  // ===== NOTIFIKASI REAL-TIME =====
  final notificationMessage = ''.obs;
  Timer? _notificationTimer;

  // ===== SMOOTHING UNTUK DETEKSI SEMENTARA =====
  bool _wasLookingAway = false;
  bool _wasLookingDown = false;
  bool _wasSmiling = false;
  bool _wasHeadTiltLeft = false;
  bool _wasHeadTiltRight = false;
  bool _wasHeadDown = false;

  // Untuk smoothing ekspresi (biar tidak flicker)
  double _smoothSmile = 0.0;

  @override
  void onInit() {
    super.onInit();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
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
    _notificationTimer?.cancel();
    _faceDetector.close();
    _poseDetector.close();
    cameraController?.dispose();
    super.onClose();
  }

  // ===== RESET SEMUA COUNTER (panggil sebelum mulai latihan) =====
  void resetAllCounters() {
    lookAwayCount.value = 0;
    lookDownCount.value = 0;
    smileCount.value = 0;
    neutralCount.value = 0;
    headTiltLeftCount.value = 0;
    headTiltRightCount.value = 0;
    headDownCount.value = 0;

    _wasLookingAway = false;
    _wasLookingDown = false;
    _wasSmiling = false;
    _wasHeadTiltLeft = false;
    _wasHeadTiltRight = false;
    _wasHeadDown = false;
    _smoothSmile = 0.0;

    notificationMessage.value = '';
  }

  // ===== HELPER TOTAL PELANGGARAN =====
  int get totalEyeViolations => lookAwayCount.value + lookDownCount.value;
  int get totalHeadViolations =>
      headTiltLeftCount.value + headTiltRightCount.value + headDownCount.value;

  // ===== INIT KAMERA =====
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
      if (kDebugMode) print('❌ Error inisialisasi kamera: $e');
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

  // ===== SHOW NOTIFICATION (hilang setelah 2 detik) =====
  void _showNotification(String message) {
    notificationMessage.value = message;
    _notificationTimer?.cancel();
    _notificationTimer = Timer(const Duration(seconds: 2), () {
      if (notificationMessage.value == message) {
        notificationMessage.value = '';
      }
    });
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

      final faces = await _faceDetector.processImage(input);
      final poses = await _poseDetector.processImage(input);

      isFaceDetected.value = faces.isNotEmpty;

      if (!isFaceDetected.value) {
        _showNotification(
          '❌ Wajah tidak terdeteksi - pastikan wajah terlihat jelas',
        );
      }

      _updateFromFace(faces.isNotEmpty ? faces.first : null);
      _updateFromPose(poses.isNotEmpty ? poses.first : null);
    } catch (e) {
      if (kDebugMode) print('Error processing frame: $e');
    } finally {
      _processing = false;
    }
  }

  // ===== DETEKSI DARI FACE =====
  void _updateFromFace(Face? face) {
    if (face == null) return;

    // 1) DETEKSI SENYUM (dengan smoothing)
    final smileProb = face.smilingProbability ?? 0.0;
    _smoothSmile = (_smoothSmile == 0.0)
        ? smileProb
        : (0.35 * smileProb + 0.65 * _smoothSmile);
    final bool currentlySmiling = _smoothSmile > _smileThr;

    if (currentlySmiling && !_wasSmiling) {
      smileCount.value++;
    } else if (!currentlySmiling && _wasSmiling) {
      neutralCount.value++;
      _showNotification('😐 Ekspresi Anda terlihat datar, coba tersenyum!');
    }
    _wasSmiling = currentlySmiling;

    // 2) DETEKSI KONTAK MATA
    final yaw = (face.headEulerAngleY ?? 0).toDouble();
    final pitch = (face.headEulerAngleX ?? 0).toDouble();

    // Mengalihkan pandangan ke samping
    final bool isLookingAway = yaw.abs() > _lookAwayYawThr;
    if (isLookingAway && !_wasLookingAway) {
      lookAwayCount.value++;
      _showNotification('👀 Hindari mengalihkan pandangan ke samping!');
    }
    _wasLookingAway = isLookingAway;

    // Menunduk
    final bool isLookingDown = pitch > _lookDownPitchThr;
    if (isLookingDown && !_wasLookingDown) {
      lookDownCount.value++;
      _showNotification('👀 Jangan menunduk, angkat kepala Anda!');
    }
    _wasLookingDown = isLookingDown;
  }

  // ===== DETEKSI DARI POSE (Postur Kepala) =====
  void _updateFromPose(Pose? pose) {
    if (pose == null) return;

    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];

    if (ls == null || rs == null || lh == null || rh == null) return;

    // Deteksi miring kiri/kanan dari selisih tinggi bahu
    final shoulderDiff = rs.y - ls.y;
    final bool isTiltLeft = shoulderDiff > _headTiltLeftThr;
    final bool isTiltRight = shoulderDiff < -_headTiltRightThr;

    if (isTiltLeft && !_wasHeadTiltLeft) {
      headTiltLeftCount.value++;
      _showNotification('🧍 Bahu miring ke kiri, coba tegakkan postur!');
    }
    if (isTiltRight && !_wasHeadTiltRight) {
      headTiltRightCount.value++;
      _showNotification('🧍 Bahu miring ke kanan, coba tegakkan postur!');
    }
    _wasHeadTiltLeft = isTiltLeft;
    _wasHeadTiltRight = isTiltRight;

    // Deteksi menunduk (kepala)
    final shoulderDist = math
        .sqrt(math.pow(ls.x - rs.x, 2) + math.pow(ls.y - rs.y, 2))
        .clamp(1.0, 1e9);
    final shCx = (ls.x + rs.x) / 2.0;
    final hipCx = (lh.x + rh.x) / 2.0;
    final centerOffsetRatio = ((shCx - hipCx).abs() / shoulderDist).clamp(
      0.0,
      1.0,
    );

    final bool isHeadDown = centerOffsetRatio > _headDownThr;
    if (isHeadDown && !_wasHeadDown) {
      headDownCount.value++;
      _showNotification('🧍 Kepala menunduk, angkat dan tegakkan!');
    }
    _wasHeadDown = isHeadDown;
  }

  // ===== INPUT IMAGE UTILITY =====
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
}
