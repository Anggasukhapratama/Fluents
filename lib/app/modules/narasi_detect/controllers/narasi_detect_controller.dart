// lib/app/modules/narasi_detect/controllers/narasi_detect_controller.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class NarasiDetectController extends GetxController {
  // Kamera
  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  final isCameraReady = false.obs;
  final isRunning = false.obs;

  int? _lastProcess;
  bool _processing = false;
  static const int _processIntervalMs = 150;

  // Face detector
  late final FaceDetector _faceDetector;

  // Status wajah
  final isFaceDetected = false.obs;

  // Smile detection
  final smileProbability = 0.0.obs; // raw value from MLKit (0..1)
  final isSmileDetected = false.obs;
  final smileStatusText = ''.obs;
 
  // Internal smoothing and hysteresis
  double _smoothedSmile = 0.0;
  static const double _smileEmaAlpha = 0.3; // smoothing
  static const double _smileEnterThreshold = 0.55;
  static const double _smileExitThreshold = 0.45;
  // Heuristik klasifikasi (tunable)
  static const double _smileAuthOnsetMin = 0.35; // seconds
  static const double _smileAuthApexMax = 1.5; // seconds
  static const double _smileAuthOffsetMin = 0.6; // seconds
  static const double _smileFakeOnsetMax = 0.18; // seconds
  static const double _smileFakeApexMin = 0.6; // seconds
  static const double _smileFakeOffsetMax = 0.4; // seconds
  static const double _smileMinPeakScore = 0.4; // ignore very weak smiles
  bool _isSmiling = false;

  // Current smile event buffer (timestamps in ms and score)
  List<Map<String, dynamic>> _currentSmileFrames = [];
  int? _currentSmileStartMs;

  // Aggregated counters (session-wide)
  int _totalSmiles = 0;
  int _totalAuthentic = 0;
  int _totalFake = 0;
  int _totalUncertain = 0;

  // Keep list of recent smile events for optional audit
  final List<Map<String, dynamic>> _smileEvents = []; // each event has metadata



  // ===== VARIABEL UNTUK BREAK COUNT & ARAH =====
  int _sessionStartMs = 0;
  int _focusDurationMs = 0;
  int _lastFrameTimestampMs = 0;

  // Break counters per arah (PRIVATE)
  // Dibuat reaktif agar widget Obx dapat memperbarui counter secara aman.
  final _rightBreaks = 0.obs;
  final _leftBreaks = 0.obs;
  final _upBreaks = 0.obs;
  final _downBreaks = 0.obs;
  final _totalBreaks = 0.obs;

  bool _wasLooking = false;

  // Threshold orientasi wajah
  static const double _yawThreshold = 20.0;
  static const double _pitchThreshold = 20.0;

  // Status orientasi untuk UI
  final isLookingAtCamera = false.obs;

  // Label kontak mata dengan deskripsi lengkap
  final eyeStatusText = ''.obs;
  final eyeWarning = ''.obs;

  // ========== LIFECYCLE ==========
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
    initCamera();
  }

  @override
  void onClose() {
    stop();
    _faceDetector.close();
    cameraController?.dispose();
    super.onClose();
  }

  // ========== KAMERA ==========
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

  // ========== START / STOP ==========
  Future<void> start() async {
    if (!isCameraReady.value || cameraController == null) return;
    if (isRunning.value) return;
    try {
      isRunning.value = true;
      _sessionStartMs = DateTime.now().millisecondsSinceEpoch;
      _focusDurationMs = 0;
      _lastFrameTimestampMs = 0;
      _rightBreaks.value = 0;
      _leftBreaks.value = 0;
      _upBreaks.value = 0;
      _downBreaks.value = 0;
      _totalBreaks.value = 0;
      _wasLooking = false;
      eyeStatusText.value = 'Memulai...';
      eyeWarning.value = '';
      isLookingAtCamera.value = false;
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
    _updateStatus(DateTime.now().millisecondsSinceEpoch);
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

  // ========== RESET ==========
  void resetCounters() {
    _sessionStartMs = 0;
    _focusDurationMs = 0;
    _lastFrameTimestampMs = 0;
    _rightBreaks.value = 0;
    _leftBreaks.value = 0;
    _upBreaks.value = 0;
    _downBreaks.value = 0;
    _totalBreaks.value = 0;
    _wasLooking = false;
    isFaceDetected.value = false;
    isLookingAtCamera.value = false;
    eyeStatusText.value = '';
    eyeWarning.value = '';

    // Reset smile-related state/counters
    smileProbability.value = 0.0;
    isSmileDetected.value = false;
    smileStatusText.value = '';
    _smoothedSmile = 0.0;
    _isSmiling = false;
    _currentSmileFrames = [];
    _currentSmileStartMs = null;
    _totalSmiles = 0;
    _totalAuthentic = 0;
    _totalFake = 0;
    _totalUncertain = 0;
    _smileEvents.clear();
  }

  // ========== FRAME PROCESSING ==========
  Future<void> _onFrame(CameraImage image) async {
    if (!isRunning.value || _processing) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastProcess != null && now - _lastProcess! < _processIntervalMs) {
      return;
    }
    _lastProcess = now;
    _processing = true;
    try {
      final input = _cameraImageToInputImage(image);
      if (input == null) return;
      final faces = await _faceDetector.processImage(input);
      final detected = faces.isNotEmpty;
      isFaceDetected.value = detected;
 
      bool looking = false;
      double yaw = 0.0;
      double pitch = 0.0;
      if (detected) {
        final face = faces.first;
        yaw = (face.headEulerAngleY ?? 0).toDouble();
        pitch = (face.headEulerAngleX ?? 0).toDouble();
        looking =
            (yaw.abs() < _yawThreshold) && (pitch.abs() < _pitchThreshold);
 
        // Smile probability from MLKit (requires enableClassification=true)
        final rawSmile = (face.smilingProbability ?? 0.0).toDouble();
        smileProbability.value = rawSmile;
        smileStatusText.value = _isSmiling ? 'Tersenyum' : 'Tidak tersenyum';

        // Smooth value
        _smoothedSmile = (_smileEmaAlpha * rawSmile) + (1 - _smileEmaAlpha) * _smoothedSmile;

        // Hysteresis for enter/exit
        if (!_isSmiling && _smoothedSmile >= _smileEnterThreshold) {
          _isSmiling = true;
          isSmileDetected.value = true;
          smileStatusText.value = 'Tersenyum';
          _currentSmileStartMs = now;
          _currentSmileFrames = [];
        }

        if (_isSmiling) {
          _currentSmileFrames.add({'t': now, 's': _smoothedSmile});

          // exit condition
          if (_smoothedSmile < _smileExitThreshold) {
            // finalize event: compute basic temporal metrics and record an event
            final frames = List<Map<String, dynamic>>.from(_currentSmileFrames);
            if (frames.isNotEmpty) {
              final startMs = frames.first['t'] as int;
              final endMs = frames.last['t'] as int;

              // find peak
              double peakScore = -1.0;
              int peakIdx = 0;
              for (int i = 0; i < frames.length; i++) {
                final s = (frames[i]['s'] as double);
                if (s > peakScore) {
                  peakScore = s;
                  peakIdx = i;
                }
              }

              final peakTime = frames[peakIdx]['t'] as int;

              final onsetDur = (peakTime - startMs) / 1000.0;
              final offsetDur = (endMs - peakTime) / 1000.0;

              // apex: contiguous frames around peak where score >= 0.9*peak
              final apexThreshold = 0.9 * peakScore;
              int aStart = peakIdx;
              while (aStart > 0 && (frames[aStart - 1]['s'] as double) >= apexThreshold) {
                aStart--;
              }
              int aEnd = peakIdx;
              while (aEnd < frames.length - 1 && (frames[aEnd + 1]['s'] as double) >= apexThreshold) {
                aEnd++;
              }
              final apexDur = ((frames[aEnd]['t'] as int) - (frames[aStart]['t'] as int)) / 1000.0;

              // Classify event using temporal heuristics; keep recording total and events
              String classification = 'UNCERTAIN';

              if (peakScore >= _smileMinPeakScore) {
                if (onsetDur >= _smileAuthOnsetMin && apexDur <= _smileAuthApexMax && offsetDur >= _smileAuthOffsetMin) {
                  classification = 'AUTHENTIC';
                } else if (onsetDur <= _smileFakeOnsetMax && apexDur >= _smileFakeApexMin && offsetDur <= _smileFakeOffsetMax) {
                  classification = 'FAKE';
                } else {
                  classification = 'UNCERTAIN';
                }
              } else {
                classification = 'UNCERTAIN';
              }

              // increment counters
              _totalSmiles++;
              if (classification == 'AUTHENTIC') _totalAuthentic++;
              else if (classification == 'FAKE') _totalFake++;
              else _totalUncertain++;

              // store event metadata including classification
              _smileEvents.add({
                'startMs': startMs,
                'endMs': endMs,
                'onset': onsetDur,
                'apex': apexDur,
                'offset': offsetDur,
                'peakScore': peakScore,
                'classification': classification,
              });

              if (kDebugMode && classification == 'FAKE') {
                print('[SmileDetect] FAKE smile detected: onset=${onsetDur}s apex=${apexDur}s offset=${offsetDur}s peak=${peakScore}');
              }
            }
            // reset event
            _isSmiling = false;
            isSmileDetected.value = false;
            smileStatusText.value = 'Tidak tersenyum';
            _currentSmileFrames = [];
            _currentSmileStartMs = null;
          }
        }
      }
      isLookingAtCamera.value = looking;

      // ===== DETEKSI BREAK DAN ARAH =====
      if (_wasLooking && !looking) {
        final absYaw = yaw.abs();
        final absPitch = pitch.abs();
        if (absYaw > absPitch) {
          if (yaw > 0) {
            _rightBreaks.value++;
          } else {
            _leftBreaks.value++;
          }
        } else {
          if (pitch > 0) {
            _upBreaks.value++;
          } else {
            _downBreaks.value++;
          }
        }
        _totalBreaks.value++;
      }
      _wasLooking = looking;

      if (looking && _sessionStartMs > 0) {
        if (_lastFrameTimestampMs != 0) {
          final delta = now - _lastFrameTimestampMs;
          if (delta > 0) _focusDurationMs += delta;
        } else {
          _focusDurationMs += 1;
        }
      }
      _lastFrameTimestampMs = now;

      _updateStatus(now);
    } catch (e) {
      if (kDebugMode) print('Error processing frame: $e');
    } finally {
      _processing = false;
    }
  }

  // ========== UPDATE STATUS ==========
  void _updateStatus(int now) {
    if (_sessionStartMs == 0) {
      eyeStatusText.value = 'Menunggu...';
      eyeWarning.value = '';
      return;
    }
    final totalElapsed = now - _sessionStartMs;

    // Masa stabilisasi 5 detik
    if (totalElapsed < 5000) {
      eyeStatusText.value = 'Memulai...';
      eyeWarning.value = '⏳ Deteksi sedang stabil...';
      return;
    }

    if (totalElapsed <= 0) {
      eyeStatusText.value = 'Menunggu...';
      eyeWarning.value = '';
      return;
    }

    final percentage = (_focusDurationMs / totalElapsed) * 100;
    String label, warning;
    if (percentage < 70) {
      label = 'Terlalu Sedikit';
      warning =
          '🔴 Kontak mata yang konsisten dan tidak terlalu lama meningkatkan rasa percaya. Terlalu sedikit kontak mata dianggap menghindari atau tidak jujur.';
    } else if (percentage <= 80) {
      label = 'Ideal';
      warning =
          '✅ Kontak mata ideal menunjukkan kepercayaan diri dan keterbukaan.';
    } else {
      label = 'Terlalu Lama';
      warning =
          '🟠 Terlalu banyak kontak mata bisa dianggap menakutkan atau mengintimidasi.';
    }
    eyeStatusText.value = label;
    eyeWarning.value = warning;
  }

  // ================================================================
  // ========== GETTER UNTUK BREAK & ARAH ===========================
  // ================================================================
  int getRightBreaks() => _rightBreaks.value;
  int getLeftBreaks() => _leftBreaks.value;
  int getUpBreaks() => _upBreaks.value;
  int getDownBreaks() => _downBreaks.value;
  int getTotalBreaks() => _totalBreaks.value;

  // Smile getters
  int getTotalSmiles() => _totalSmiles;
  int getAuthenticCount() => _totalAuthentic;
  int getFakeCount() => _totalFake;
  int getUncertainCount() => _totalUncertain;
  List<Map<String, dynamic>> getSmileEvents() => List<Map<String, dynamic>>.from(_smileEvents);

  double getFocusPercentage() {
    if (_sessionStartMs == 0) return 0.0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final totalElapsed = now - _sessionStartMs;
    if (totalElapsed <= 0) return 0.0;
    return (_focusDurationMs / totalElapsed) * 100;
  }

  int getFocusDurationMs() => _focusDurationMs;
  int getSessionElapsedMs() {
    if (_sessionStartMs == 0) return 0;
    return DateTime.now().millisecondsSinceEpoch - _sessionStartMs;
  }

  // ========== HELPER KONVERSI ==========
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
