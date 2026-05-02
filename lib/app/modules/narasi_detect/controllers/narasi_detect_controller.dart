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
  static const int _processIntervalMs = 150; // Dikurangi frekuensi processing

  // ===== ML KIT DETECTOR =====
  late final FaceDetector _faceDetector;
  late final PoseDetector _poseDetector;

  // ===== STATUS WAJAH =====
  final isFaceDetected = false.obs;
  bool _wasFaceDetectedBefore = false;

  // ===== THRESHOLD DETEKSI - SANGAT TIDAK SENSITIF =====
  double _lookAwayYawThr = 18.0; // Lebih besar = kurang sensitif
  double _lookDownPitchThr = 15.0; // Lebih besar = kurang sensitif
  double _headTiltLeftThr = 0.065; // Lebih besar = kurang sensitif
  double _headTiltRightThr = 0.065;
  double _headDownThr = 0.085;
  double _smileThr = 0.20;

  String currentLevel = 'medium';

  // ===== COUNTER PELANGGARAN DETAIL =====
  final lookAwayLeftCount = 0.obs; // Melirik ke kiri
  final lookAwayRightCount = 0.obs; // Melirik ke kanan
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

  // Untuk smoothing pose detection
  double _smoothShoulderDiff = 0.0;
  double _smoothHeadDown = 0.0;

  // ===== NOTIFIKASI REAL-TIME =====
  final notificationMessage = ''.obs;
  Timer? _notificationTimer;
  DateTime? _lastNotificationTime;
  static const int _notificationCooldownMs = 3000;

  // ===== POSTURE ALERT COOLDOWN =====
  DateTime? _lastPostureAlert;
  static const int _postureAlertCooldownMs = 6000;

  // ===== STATUS TEKS =====
  final eyeStatusText = ''.obs;
  final smileStatusText = ''.obs;
  final postureStatusText = ''.obs;

  // ===== GETTER UNTUK KOMPATIBILITAS DENGAN KODE LAMA =====
  int get lookAwayCount => lookAwayLeftCount.value + lookAwayRightCount.value;
  int get lookAwayLeft => lookAwayLeftCount.value;
  int get lookAwayRight => lookAwayRightCount.value;
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
        _lookAwayYawThr = 14.0;
        _lookDownPitchThr = 12.0;
        _headTiltLeftThr = 0.055;
        _headTiltRightThr = 0.055;
        _headDownThr = 0.075;
        _smileThr = 0.25;
        break;
      case 'hard':
        _lookAwayYawThr = 16.0;
        _lookDownPitchThr = 13.0;
        _headTiltLeftThr = 0.060;
        _headTiltRightThr = 0.060;
        _headDownThr = 0.080;
        _smileThr = 0.23;
        break;
      default:
        _lookAwayYawThr = 18.0;
        _lookDownPitchThr = 15.0;
        _headTiltLeftThr = 0.065;
        _headTiltRightThr = 0.065;
        _headDownThr = 0.085;
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
    _wasFaceDetectedBefore = false;

    _updateDescriptiveStatusTexts();
  }

  void startWindowTimer() {}
  void stopWindowTimer() {}

  // ===== UPDATE STATUS TEKS (3 TINGKAT) =====
  void _updateDescriptiveStatusTexts() {
    // Kontak Mata
    final totalEye =
        lookAwayLeftCount.value +
        lookAwayRightCount.value +
        lookDownCount.value;
    if (totalEye <= 1) {
      eyeStatusText.value = 'Fokus & Percaya Diri';
    } else if (totalEye <= 3) {
      eyeStatusText.value = 'Sesekali Terdistraksi';
    } else {
      eyeStatusText.value = 'Sering Kehilangan Fokus';
    }

    // Ekspresi
    if (smileCount.value >= 3 && smileCount.value > neutralCount.value) {
      smileStatusText.value = 'Ramah & Antusias';
    } else if (smileCount.value >= 1) {
      smileStatusText.value = 'Cukup Ramah / Netral';
    } else {
      smileStatusText.value = 'Kaku & Tegang';
    }

    // Postur
    final totalHead =
        headTiltLeftCount.value +
        headTiltRightCount.value +
        headDownCount.value;
    if (totalHead <= 1) {
      postureStatusText.value = 'Tenang & Profesional';
    } else if (totalHead <= 3) {
      postureStatusText.value = 'Sedikit Gelisah';
    } else {
      postureStatusText.value = 'Gugup & Cemas';
    }
  }

  // ===== LABEL PER KATEGORI 3 TINGKAT =====

  /// Label Kontak Mata (3 tingkat)
  String getEyeLevelLabel() {
    final total =
        lookAwayLeftCount.value +
        lookAwayRightCount.value +
        lookDownCount.value;
    if (total <= 3) return 'Fokus & Percaya Diri';
    if (total <= 6) return 'Sesekali Terdistraksi';
    return 'Sering Kehilangan Fokus';
  }

  /// Label Ekspresi/Senyum (3 tingkat)
  String getSmileLevelLabel() {
    final smile = smileCount.value;
    final neutral = neutralCount.value;
    if (smile >= 3 && smile > neutral) return 'Ramah & Antusias';
    if (smile >= 1) return 'Cukup Ramah / Netral';
    return 'Kaku & Tegang';
  }

  /// Label Postur (3 tingkat)
  String getPostureLevelLabel() {
    final total =
        headTiltLeftCount.value +
        headTiltRightCount.value +
        headDownCount.value;
    if (total <= 3) return 'Tenang & Profesional';
    if (total <= 6) return 'Sedikit Gelisah';
    return 'Gugup & Cemas';
  }

  /// Label Kontak Mata detail dengan jumlah
  String getEyeContactLabelDetail() {
    final totalLeft = lookAwayLeftCount.value;
    final totalRight = lookAwayRightCount.value;
    final totalDown = lookDownCount.value;
    final total = totalLeft + totalRight + totalDown;

    if (total <= 1) return 'Fokus & Percaya Diri (≤1 kali melirik)';
    if (total <= 3) return 'Sesekali Terdistraksi (2-3 kali melirik)';
    return 'Sering Kehilangan Fokus (>3 kali melirik)';
  }

  /// Label Ekspresi detail dengan jumlah
  String getSmileLabelDetail() {
    final totalSmile = smileCount.value;
    final totalNeutral = neutralCount.value;

    if (totalSmile >= 3 && totalSmile > totalNeutral) {
      return 'Ramah & Antusias (≥3 kali senyum)';
    }
    if (totalSmile >= 1) {
      return 'Cukup Ramah / Netral (1-2 kali senyum)';
    }
    return 'Kaku & Tegang (0 kali senyum, $totalNeutral kali ekspresi datar)';
  }

  /// Label Postur detail dengan jumlah
  String getPostureLabelDetail() {
    final totalLeft = headTiltLeftCount.value;
    final totalRight = headTiltRightCount.value;
    final totalDown = headDownCount.value;
    final total = totalLeft + totalRight + totalDown;

    if (total <= 1) return 'Tenang & Profesional (≤1 kali gerakan)';
    if (total <= 3) return 'Sedikit Gelisah (2-3 kali gerakan)';
    return 'Gugup & Cemas (>3 kali gerakan)';
  }

  /// Label keseluruhan (overall)
  String getOverallConfidenceLabel() {
    final eyeLabel = getEyeLevelLabel();
    final smileLabel = getSmileLevelLabel();
    final postureLabel = getPostureLevelLabel();

    if (eyeLabel == 'Fokus & Percaya Diri' &&
        smileLabel == 'Ramah & Antusias' &&
        postureLabel == 'Tenang & Profesional') {
      return 'Percaya Diri';
    } else if (eyeLabel != 'Sering Kehilangan Fokus' &&
        smileLabel != 'Kaku & TString getSmileLevelLabel() {egang' &&
        postureLabel != 'Gugup & Cemas') {
      return 'Cukup Percaya Diri';
    } else {
      return 'Ragu-ragu';
    }
  }

  // ===== FEEDBACK PER KATEGORI (3 TINGKAT) =====

  /// Feedback detail Kontak Mata
  String getDetailedEyeFeedback() {
    final total =
        lookAwayLeftCount.value +
        lookAwayRightCount.value +
        lookDownCount.value;

    if (total <= 1) {
      return 'Kontak mata fokus & percaya diri. Pertahankan!';
    } else if (total <= 3) {
      return 'Kontak mata sesekali terdistraksi. Coba lebih fokus ke kamera.';
    } else {
      return 'Kontak mata sering kehilangan fokus. Latih menatap kamera.';
    }
  }

  /// Feedback detail Ekspresi
  String getDetailedSmileFeedback() {
    final smile = smileCount.value;
    final neutral = neutralCount.value;

    if (smile >= 3 && smile > neutral) {
      return 'Ekspresi ramah & antusias. Pertahankan!';
    } else if (smile >= 1) {
      return 'Ekspresi cukup ramah. Coba lebih sering tersenyum.';
    } else {
      return 'Ekspresi kaku & tegang. Tersenyumlah di awal dan akhir jawaban.';
    }
  }

  /// Feedback detail Postur
  String getDetailedPostureFeedback() {
    final total =
        headTiltLeftCount.value +
        headTiltRightCount.value +
        headDownCount.value;

    if (total <= 1) {
      return 'Postur tenang & profesional. Pertahankan!';
    } else if (total <= 3) {
      return 'Postur sedikit gelisah. Coba lebih rileks.';
    } else {
      return 'Postur gugup & cemas. Duduk tegak dan tarik napas.';
    }
  }

  // ===== ANALISIS LENGKAP =====

  /// Mendapatkan analisis lengkap dalam bentuk teks
  String getDetailedAnalysis() {
    final totalLeftEye = lookAwayLeftCount.value;
    final totalRightEye = lookAwayRightCount.value;
    final totalDownEye = lookDownCount.value;
    final totalEye = totalLeftEye + totalRightEye + totalDownEye;

    final totalSmile = smileCount.value;
    final totalNeutral = neutralCount.value;

    final totalLeftHead = headTiltLeftCount.value;
    final totalRightHead = headTiltRightCount.value;
    final totalDownHead = headDownCount.value;
    final totalHead = totalLeftHead + totalRightHead + totalDownHead;

    final analysis = StringBuffer();

    analysis.writeln('======= HASIL ANALISIS PERILAKU =======');
    analysis.writeln('');

    // 1. KONTAK MATA
    analysis.writeln('1. KONTAK MATA');
    analysis.writeln('   - Melirik ke kiri: $totalLeftEye kali');
    analysis.writeln('   - Melirik ke kanan: $totalRightEye kali');
    analysis.writeln('   - Menunduk: $totalDownEye kali');
    analysis.writeln('   - Total pelanggaran: $totalEye kali');
    analysis.writeln('   - Label: ${getEyeContactLabelDetail()}');
    analysis.writeln('');

    // 2. EKSPRESI WAJAH
    analysis.writeln('2. EKSPRESI WAJAH');
    analysis.writeln('   - Tersenyum: $totalSmile kali');
    analysis.writeln('   - Ekspresi datar/Netral: $totalNeutral kali');
    analysis.writeln('   - Label: ${getSmileLabelDetail()}');
    analysis.writeln('');

    // 3. POSTUR TUBUH
    analysis.writeln('3. POSTUR TUBUH');
    analysis.writeln('   - Kepala miring ke kiri: $totalLeftHead kali');
    analysis.writeln('   - Kepala miring ke kanan: $totalRightHead kali');
    analysis.writeln('   - Kepala menunduk: $totalDownHead kali');
    analysis.writeln('   - Total gerakan tidak stabil: $totalHead kali');
    analysis.writeln('   - Label: ${getPostureLabelDetail()}');
    analysis.writeln('');

    // 4. KESIMPULAN AKHIR
    final overallLabel = getOverallConfidenceLabel();
    analysis.writeln('4. KESIMPULAN AKHIR');
    analysis.writeln('   - $overallLabel');

    return analysis.toString();
  }

  /// Mendapatkan saran perbaikan lengkap
  String getDetailedFeedback() {
    final totalLeftEye = lookAwayLeftCount.value;
    final totalRightEye = lookAwayRightCount.value;
    final totalDownEye = lookDownCount.value;
    final totalEye = totalLeftEye + totalRightEye + totalDownEye;

    final totalSmile = smileCount.value;

    final totalLeftHead = headTiltLeftCount.value;
    final totalRightHead = headTiltRightCount.value;
    final totalDownHead = headDownCount.value;
    final totalHead = totalLeftHead + totalRightHead + totalDownHead;

    final feedback = StringBuffer();

    feedback.writeln('======= SARAN PERBAIKAN =======');
    feedback.writeln('');

    // Feedback untuk Kontak Mata
    if (totalEye <= 1) {
      feedback.writeln('✓ Kontak Mata: Fokus & Percaya Diri. Pertahankan!');
    } else if (totalEye <= 3) {
      feedback.writeln('📌 Kontak Mata: Sesekali Terdistraksi.');
      if (totalLeftEye > 0 || totalRightEye > 0) {
        feedback.writeln(
          '   → Kurangi kebiasaan melirik ke samping. Bayangkan kamera adalah mata HRD.',
        );
      }
      if (totalDownEye > 0) {
        feedback.writeln(
          '   → Atur posisi layar lebih tinggi agar tidak perlu menunduk.',
        );
      }
    } else {
      feedback.writeln('⚠️ Kontak Mata: Sering Kehilangan Fokus.');
      if (totalLeftEye > 0 || totalRightEye > 0) {
        feedback.writeln(
          '   → Anda sering melirik ke samping ($totalLeftEye kali kiri, $totalRightEye kali kanan).',
        );
        feedback.writeln(
          '   → Latihan: Tempelkan stiker kecil di samping kamera sebagai pengingat untuk fokus.',
        );
      }
      if (totalDownEye > 0) {
        feedback.writeln('   → Anda sering menunduk ($totalDownEye kali).');
        feedback.writeln(
          '   → Latihan: Naikkan laptop/webcam setinggi mata Anda.',
        );
      }
      feedback.writeln(
        '   → Latihan harian: Tatap kamera 30 detik tanpa berkedip setiap hari.',
      );
    }
    feedback.writeln('');

    // Feedback untuk Ekspresi
    if (totalSmile >= 3) {
      feedback.writeln('✓ Ekspresi: Ramah & Antusias. Luar biasa!');
    } else if (totalSmile >= 1) {
      feedback.writeln('📌 Ekspresi: Cukup Ramah / Netral.');
      feedback.writeln(
        '   → Tingkatkan jadi 3-4 kali senyum selama sesi wawancara.',
      );
      feedback.writeln(
        '   → Tips: Tersenyumlah di awal dan akhir setiap jawaban.',
      );
    } else {
      feedback.writeln('⚠️ Ekspresi: Kaku & Tegang.');
      feedback.writeln('   → Ini adalah area yang perlu segera diperbaiki.');
      feedback.writeln(
        '   → Latihan: Rekam diri Anda tersenyum, tonton ulang, biasakan.',
      );
    }
    feedback.writeln('');

    // Feedback untuk Postur
    if (totalHead <= 1) {
      feedback.writeln('✓ Postur: Tenang & Profesional. Sempurna!');
    } else if (totalHead <= 3) {
      feedback.writeln('📌 Postur: Sedikit Gelisah.');
      if (totalLeftHead > 0 || totalRightHead > 0) {
        feedback.writeln('   → Kurangi kebiasaan memiringkan kepala.');
      }
      if (totalDownHead > 0) {
        feedback.writeln('   → Angkat kepala saat berbicara.');
      }
      feedback.writeln('   → Duduk dengan punggung menyentuh sandaran kursi.');
    } else {
      feedback.writeln('⚠️ Postur: Gugup & Cemas.');
      if (totalLeftHead > 0 || totalRightHead > 0) {
        feedback.writeln(
          '   → Kepala miring $totalLeftHead kali kiri, $totalRightHead kali kanan.',
        );
        feedback.writeln(
          '   → Solusi: Atur ketinggian kursi agar bahu rileks.',
        );
      }
      if (totalDownHead > 0) {
        feedback.writeln('   → Kepala menunduk $totalDownHead kali.');
        feedback.writeln(
          '   → Solusi: Tempelkan sticky note "ANGKAT KEPALA" di monitor.',
        );
      }
      feedback.writeln(
        '   → Latihan: Latihan di depan cermin 5 menit setiap hari.',
      );
    }
    feedback.writeln('');

    feedback.writeln('======= RINGKASAN =======');
    if (totalEye <= 1 && totalSmile >= 3 && totalHead <= 1) {
      feedback.writeln(
        'Performa Anda sangat baik! Pertahankan dan terus tingkatkan.',
      );
    } else {
      feedback.writeln(
        'Terus berlatih! Setiap sesi membawa Anda selangkah lebih dekat ke sukses.',
      );
    }

    return feedback.toString();
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
        _showNotification('✅ Wajah terdeteksi!');
      }

      if (faces.isNotEmpty) {
        _updateFromFace(faces.first);
      }

      if (poses.isNotEmpty && isFaceDetected.value) {
        _updateFromPose(poses.first);
      }
    } catch (e) {
      if (kDebugMode) print('Error processing frame: $e');
    } finally {
      _processing = false;
    }
  }

  void _updateFromFace(Face face) {
    final yaw = (face.headEulerAngleY ?? 0).toDouble();
    final pitch = (face.headEulerAngleX ?? 0).toDouble();

    // Deteksi Senyum
    final smileProb = face.smilingProbability ?? 0.0;
    _smoothSmile = (_smoothSmile == 0.0)
        ? smileProb
        : (0.7 * smileProb + 0.3 * _smoothSmile);

    final bool isSmiling = _smoothSmile > _smileThr;

    if (isSmiling && !_wasSmiling) {
      smileCount.value++;
      print('😊 SENYUM! Total: ${smileCount.value}');
      _showNotification('😊 Senyum terdeteksi!');
    } else if (!isSmiling && _wasSmiling && smileProb < 0.15) {
      neutralCount.value++;
    }
    _wasSmiling = isSmiling;

    // Deteksi Melirik ke KIRI (yaw negatif)
    final bool isLookingLeft = yaw < -_lookAwayYawThr;
    if (isLookingLeft && !_wasLookingLeft) {
      lookAwayLeftCount.value++;
      print('👀 MELIRIK KIRI! Total kiri: ${lookAwayLeftCount.value}');
      _showNotification('👀 Mata: Melirik ke kiri');
    }
    _wasLookingLeft = isLookingLeft;

    // Deteksi Melirik ke KANAN (yaw positif)
    final bool isLookingRight = yaw > _lookAwayYawThr;
    if (isLookingRight && !_wasLookingRight) {
      lookAwayRightCount.value++;
      print('👀 MELIRIK KANAN! Total kanan: ${lookAwayRightCount.value}');
      _showNotification('👀 Mata: Melirik ke kanan');
    }
    _wasLookingRight = isLookingRight;

    // Deteksi Menunduk
    final bool isLookingDown = pitch > _lookDownPitchThr;
    if (isLookingDown && !_wasLookingDown) {
      lookDownCount.value++;
      print('⬇️ MENUNDUK! Total: ${lookDownCount.value}');
      _showNotification('⬇️ Mata: Menunduk');
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

    // Deteksi miring kepala dengan smoothing
    if (leftShoulder != null && rightShoulder != null) {
      final shoulderDiff = rightShoulder.y - leftShoulder.y;
      _smoothShoulderDiff = (_smoothShoulderDiff == 0.0)
          ? shoulderDiff
          : (0.8 * shoulderDiff + 0.2 * _smoothShoulderDiff);

      final bool isTiltLeft = _smoothShoulderDiff > _headTiltLeftThr;
      final bool isTiltRight = _smoothShoulderDiff < -_headTiltRightThr;

      if (isTiltLeft && !_wasHeadTiltLeft) {
        headTiltLeftCount.value++;
        print('🧍 KEPALA MIRING KIRI! Total: ${headTiltLeftCount.value}');
        _showPostureAlert('🧍 Postur: Kepala miring ke kiri');
      }
      if (isTiltRight && !_wasHeadTiltRight) {
        headTiltRightCount.value++;
        print('🧍 KEPALA MIRING KANAN! Total: ${headTiltRightCount.value}');
        _showPostureAlert('🧍 Postur: Kepala miring ke kanan');
      }

      _wasHeadTiltLeft = isTiltLeft;
      _wasHeadTiltRight = isTiltRight;
    }

    // Deteksi menunduk dengan smoothing
    if (nose != null && leftEye != null && rightEye != null) {
      final eyeCenterY = (leftEye.y + rightEye.y) / 2;
      final headDownValue = nose.y - eyeCenterY;
      _smoothHeadDown = (_smoothHeadDown == 0.0)
          ? headDownValue
          : (0.8 * headDownValue + 0.2 * _smoothHeadDown);

      final bool isHeadDown = _smoothHeadDown > _headDownThr;

      if (isHeadDown && !_wasHeadDown) {
        headDownCount.value++;
        print('🧍 KEPALA MENUNDUK! Total: ${headDownCount.value}');
        _showPostureAlert('🧍 Postur: Kepala menunduk');
      }
      _wasHeadDown = isHeadDown;
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
}
