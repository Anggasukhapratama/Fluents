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
  // ===== Kamera =====
  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  final isCameraReady = false.obs;
  final isRunning = false.obs;

  DateTime? _lastProcess;
  bool _processing = false;
  static const int _processIntervalMs = 200; // 5 FPS

  static const double _targetZoom = 1.0; // Anti Cembung

  // ===== ML Kit Detector =====
  late final FaceDetector _faceDetector;
  late final PoseDetector _poseDetector;

  // ===== 3 DETEKSI UTAMA (HRD STANDARD) =====
  final isSmiling = false.obs;
  final smileScore = 0.0.obs;

  final eyeContactRatio = 0.0.obs;

  final postureLeanScore = 0.0.obs; // 0 = Tegak, 1 = Sangat Miring/Membungkuk

  // ===== STATUS DETEKSI WAJAH =====
  final isFaceDetected = false.obs;
  final faceDetectionMessage = ''.obs;

  // ===== SKOR AKHIR (0-100) & LABEL HRD (REAL-TIME) =====
  final scoreSmile = 0.obs;
  final labelSmile = 'Kaku'.obs;

  final scoreEye = 0.obs;
  final labelEye = 'Terdistraksi'.obs;

  final scorePosture = 0.obs;
  final labelPosture = 'Kurang Siap'.obs;

  // Overall confidence (0-100)
  final overallConfidence = 0.0.obs;
  final overallLabel = 'Gelisah / Cemas'.obs;

  // ===== Internal & Smoothing =====
  InputImageRotation? _rotation;
  Size? _lastImageSize;

  static const double _smoothFactor = 0.35;
  double _smoothSmile = 0.0;
  double _smoothEye = 0.0;
  double _smoothPosture = 0.0;

  // Thresholds
  static const double _eyeYawThr = 15.0;
  static const double _eyePitchThr = 12.0;
  static const double _smileThr = 0.3;

  // ===== VARIABEL UNTUK NILAI RATA-RATA (AVERAGE) =====
  int _frameCount = 0;
  double _sumSmile = 0.0;
  double _sumEye = 0.0;
  double _sumPosture = 0.0;

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
    _faceDetector.close();
    _poseDetector.close();
    cameraController?.dispose();
    super.onClose();
  }

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
    _rotation = _toInputImageRotation(selected.sensorOrientation);
    await _applyZoomSafely(cameraController!, _targetZoom);
    isCameraReady.value = true;
  }

  Future<void> _applyZoomSafely(CameraController c, double target) async {
    try {
      final minZoom = await c.getMinZoomLevel();
      final maxZoom = await c.getMaxZoomLevel();
      double z = target.clamp(minZoom, maxZoom);
      await c.setZoomLevel(z);
    } catch (_) {}
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
        faceDetectionMessage.value =
            'Wajah tidak terdeteksi - pastikan wajah terlihat jelas';
      } else {
        faceDetectionMessage.value = '';
      }

      _updateFromFace(faces.isNotEmpty ? faces.first : null);
      _updateFromPose(poses.isNotEmpty ? poses.first : null);
      _recomputeScoresAndLabels();
    } finally {
      _processing = false;
    }
  }

  void _updateFromFace(Face? face) {
    if (face == null) {
      isSmiling.value = false;
      smileScore.value = 0.0;
      eyeContactRatio.value = 0.0;
      return;
    }

    // 1) Senyum
    final smileProb = face.smilingProbability ?? 0.0;
    _smoothSmile = (_smoothSmile == 0.0)
        ? smileProb
        : (_smoothFactor * smileProb + (1 - _smoothFactor) * _smoothSmile);
    smileScore.value = _smoothSmile.clamp(0.0, 1.0);
    isSmiling.value = smileScore.value > _smileThr;

    // 2) Kontak Mata
    final yaw = (face.headEulerAngleY ?? 0).toDouble();
    final pitch = (face.headEulerAngleX ?? 0).toDouble();

    final goodEye = yaw.abs() <= _eyeYawThr && pitch.abs() <= _eyePitchThr;
    final eyeVal = goodEye ? 1.0 : 0.0;
    _smoothEye = (_smoothEye == 0.0)
        ? eyeVal
        : (_smoothFactor * eyeVal + (1 - _smoothFactor) * _smoothEye);
    eyeContactRatio.value = _smoothEye.clamp(0.0, 1.0);
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

    if (ls == null || rs == null || lh == null || rh == null) return;

    double dist(double ax, double ay, double bx, double by) {
      final dx = ax - bx;
      final dy = ay - by;
      return math.sqrt(dx * dx + dy * dy);
    }

    final shoulderDist = dist(ls.x, ls.y, rs.x, rs.y).clamp(1.0, 1e9);
    final shoulderDy = (rs.y - ls.y).abs();
    final shoulderTiltRatio = (shoulderDy / shoulderDist).clamp(0.0, 1.0);

    final hipDist = dist(lh.x, lh.y, rh.x, rh.y).clamp(1.0, 1e9);
    final hipDy = (rh.y - lh.y).abs();
    final hipTiltRatio = (hipDy / hipDist).clamp(0.0, 1.0);

    final shCx = (ls.x + rs.x) / 2.0;
    final hipCx = (lh.x + rh.x) / 2.0;
    final centerOffsetRatio = ((shCx - hipCx).abs() / shoulderDist).clamp(
      0.0,
      1.0,
    );

    double mapRatio(double r, {double dead = 0.05, double maxBad = 0.22}) {
      if (r <= dead) return 0.0;
      return ((r - dead) / (maxBad - dead)).clamp(0.0, 1.0);
    }

    final shoulderBad = mapRatio(shoulderTiltRatio, dead: 0.05, maxBad: 0.22);
    final hipBad = mapRatio(hipTiltRatio, dead: 0.05, maxBad: 0.22);
    final offsetBad = mapRatio(centerOffsetRatio, dead: 0.06, maxBad: 0.35);

    final raw = (shoulderBad * 0.55 + hipBad * 0.25 + offsetBad * 0.20).clamp(
      0.0,
      1.0,
    );
    _smoothPosture = (_smoothPosture == 0.0)
        ? raw
        : (_smoothFactor * raw + (1.0 - _smoothFactor) * _smoothPosture);
    postureLeanScore.value = _smoothPosture.clamp(0.0, 1.0);
  }

  void _recomputeScoresAndLabels() {
    if (!isFaceDetected.value) {
      scoreSmile.value = 0;
      scoreEye.value = 0;
      scorePosture.value = 0;
      overallConfidence.value = 0.0;
      overallLabel.value = 'Wajah Tidak Terdeteksi';
      return;
    }

    scoreSmile.value = (smileScore.value * 100).round().clamp(0, 100);
    scoreEye.value = (eyeContactRatio.value * 100).round().clamp(0, 100);
    scorePosture.value = ((1.0 - postureLeanScore.value) * 100).round().clamp(
      0,
      100,
    );

    labelSmile.value = scoreSmile.value >= 40
        ? 'Ramah & Terbuka'
        : 'Kaku / Tegang';
    labelEye.value = scoreEye.value >= 70
        ? 'Fokus & Percaya Diri'
        : 'Terdistraksi';
    labelPosture.value = scorePosture.value >= 60
        ? 'Antusias & Siap'
        : 'Kurang Siap / Miring';

    final overall =
        ((scoreEye.value * 0.40) +
        (scorePosture.value * 0.40) +
        (scoreSmile.value * 0.20));

    overallConfidence.value = overall.round().toDouble();

    if (overallConfidence.value >= 80) {
      overallLabel.value = 'Sangat Meyakinkan & Profesional';
    } else if (overallConfidence.value >= 60) {
      overallLabel.value = 'Cukup Siap (Perlu Peningkatan)';
    } else if (overallConfidence.value >= 40) {
      overallLabel.value = 'Kurang Percaya Diri / Ragu';
    } else {
      overallLabel.value = 'Gelisah / Tidak Fokus';
    }

    // --- LOGIKA NILAI RATA-RATA DARI KESELURUHAN FRAME ---
    if (isRunning.value) {
      _frameCount++;
      _sumSmile += scoreSmile.value;
      _sumEye += scoreEye.value;
      _sumPosture += scorePosture.value;
    }
  }

  InputImage? _cameraImageToInputImage(CameraImage image) {
    final rot = _rotation;
    if (rot == null) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) allBytes.putUint8List(plane.bytes);
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    _lastImageSize = imageSize;

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

  // --- METHOD BARU UNTUK RATA-RATA SESI ---
  void resetAverages() {
    _frameCount = 0;
    _sumSmile = 0.0;
    _sumEye = 0.0;
    _sumPosture = 0.0;
  }

  int get finalAvgSmile =>
      _frameCount == 0 ? 0 : (_sumSmile / _frameCount).round();
  int get finalAvgEye => _frameCount == 0 ? 0 : (_sumEye / _frameCount).round();
  int get finalAvgPosture =>
      _frameCount == 0 ? 0 : (_sumPosture / _frameCount).round();

  int get finalAvgOverall => _frameCount == 0
      ? 0
      : ((finalAvgEye * 0.40) +
                (finalAvgPosture * 0.40) +
                (finalAvgSmile * 0.20))
            .round();
}
