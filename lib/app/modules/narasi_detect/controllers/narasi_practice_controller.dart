import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:fluent_ai/app/models/practice_session_model.dart';
import 'package:fluent_ai/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:fluent_ai/app/routes/app_pages.dart';
import 'package:fluent_ai/app/services/practice_firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'narasi_detect_controller.dart';

enum PracticeStep { choose, customInput, countdown, practice, result }

class NarasiPracticeController extends GetxController {
  // ===== CONFIG =====
  static const int lineDurationSeconds = 10;
  static const int sttRefreshGapMs = 450;
  static const int sttListenForSeconds = 14;
  static const int sttPauseForSeconds = 2;

  // ===== Dependencies =====
  final NarasiDetectController detect = Get.find<NarasiDetectController>();
  final PracticeFirestoreService fs = PracticeFirestoreService();

  // ===== Audio Player =====
  final AudioPlayer audioPlayer = AudioPlayer();

  /// ✅ GLOBAL SOUND TOGGLE
  final soundEnabled = true.obs;

  void toggleSound() {
    soundEnabled.value = !soundEnabled.value;
    if (!soundEnabled.value) {
      try {
        audioPlayer.stop();
      } catch (_) {}
    }
  }

  final Map<String, String> soundPaths = {
    'mouth_too_open': 'sounds/alert.mp3',
    'head_tilt': 'sounds/alert.mp3',
    'bad_posture': 'sounds/alert.mp3',
    'bad_eye_contact': 'sounds/alert.mp3',
    'speaking_too_fast': 'sounds/alert.mp3',
    'too_many_fillers': 'sounds/alert.mp3',
    'good_job': 'sounds/good.mp3',
  };

  final Map<String, String> soundMessages = {
    'mouth_too_open': 'Mulut terlalu terbuka!',
    'head_tilt': 'Kepala miring! Tegakkan!',
    'bad_posture': 'Postur membungkuk! Duduk tegak!',
    'bad_eye_contact': 'Kurangi menunduk, lihat kamera!',
    'speaking_too_fast': 'Bicara terlalu cepat!',
    'too_many_fillers': 'Terlalu banyak "umm", "anu"!',
    'good_job': 'Bagus! Pertahankan!',
  };

  DateTime? _lastMouthSound;
  DateTime? _lastTiltSound;
  DateTime? _lastPostureSound;
  DateTime? _lastEyeSound;
  DateTime? _lastSpeedSound;
  DateTime? _lastFillerSound;
  DateTime? _lastGoodSound;

  // ===== STT Engine =====
  final stt.SpeechToText sttEngine = stt.SpeechToText();
  bool _sttReady = false;
  bool _restarting = false;
  DateTime? _lastRestartAt;
  bool _sttCycling = false;

  final sttStatusText = ''.obs;
  final sttIsListening = false.obs;

  // ===== Flow State =====
  final step = PracticeStep.choose.obs;
  final selectedDifficulty = 'medium'.obs;
  final customTextController = TextEditingController();

  // ===== Script Management =====
  final RxList<String> scriptLines = <String>[].obs;
  final currentIndex = 0.obs;
  final currentLine = ''.obs;

  // ===== Countdown =====
  final countdown = 0.obs;
  Timer? _countdownTimer;

  // ===== Session State =====
  final isSessionRunning = false.obs;

  // ===== STT Results =====
  final recognizedText = ''.obs;
  final currentLineRecognized = ''.obs;
  final sttConfidence = 0.0.obs;

  // ===== Speech Metrics =====
  final wordsPerMinute = 0.obs;
  final fillerCount = 0.obs;
  final fluencyScore = 0.0.obs;
  DateTime? _sessionStart;

  // ✅ Silence handling (FIX fluency selalu 100)
  DateTime? _lastSpeechAt;
  Timer? _silenceTimer;

  // ===== Line Timer =====
  Timer? _lineWindowTimer;
  final secondsLeftInLine = lineDurationSeconds.obs;

  // ===== Final Results =====
  final RxList<String> finalSuggestions = <String>[].obs;

  // ===== Averages (session) =====
  final RxList<double> mouthRatios = <double>[].obs;
  final RxList<double> tiltDegrees = <double>[].obs;
  final RxList<double> postureScores = <double>[].obs;
  final RxList<double> eyeRatios = <double>[].obs;

  // ===== Per-line collectors =====
  final RxList<double> _lineMouth = <double>[].obs;
  final RxList<double> _lineTiltAbs = <double>[].obs;
  final RxList<double> _linePosture = <double>[].obs;
  final RxList<double> _lineEye = <double>[].obs;
  final RxList<int> _lineWpmSamples = <int>[].obs;
  final RxList<int> _lineFillerSamples = <int>[].obs;

  final RxList<int> lineConfidenceScores = <int>[].obs;
  final RxList<String> lineLabels = <String>[].obs;

  // ✅ TOTAL CONFIDENCE SESSION (yang kamu minta)
  final totalConfidenceSession = 0.0.obs;

  // ✅ FIX MERAH DI VIEW:
  final confidenceTotalSesi = 0.0.obs;
  final confidenceTotalLabel = 'Tenang'.obs;

  void _syncConfidenceAlias() {
    final s = totalConfidenceSession.value;
    confidenceTotalSesi.value = s;

    if (s >= 70) {
      confidenceTotalLabel.value = 'Tenang';
    } else if (s >= 45) {
      confidenceTotalLabel.value = 'Kurang PD';
    } else {
      confidenceTotalLabel.value = 'Gugup';
    }
  }

  // ===== Live Feedback Flags =====
  final isMouthGood = true.obs;
  final isHeadGood = true.obs;
  final isPostureGood = true.obs;
  final isEyeGood = true.obs;
  final isSpeedGood = true.obs;
  final isFillerGood = true.obs;

  // ===== Celebration (Confetti) =====
  final showCelebration = false.obs;

  // ✅ timer periodic MLKit feedback
  Timer? _mlkitPeriodicTimer;

  // ✅ guard biar transcript gak ke-append dobel
  String _lastCommittedLine = '';

  // ✅ Tambahan: track baris yang sudah di-commit
  final Set<String> _committedLines = {};

  // ===== BANK NARASI =====
  final List<String> mediumIntro = const [
    "Selamat pagi, perkenalkan nama saya [Nama Anda].",
    "Saya lulusan [Nama Universitas] jurusan [Jurusan Anda].",
    "Saat ini saya tertarik berkarier di bidang [Bidang Anda].",
  ];

  final List<String> mediumPool = const [
    "Saya memiliki pengalaman di bidang [Bidang Anda] selama [X tahun].",
    "Saya pernah mengerjakan proyek [Proyek] yang fokus pada [Topik].",
    "Saya terbiasa bekerja dengan target dan deadline yang jelas.",
    "Saya senang belajar hal baru dan cepat beradaptasi.",
    "Saya sering berkolaborasi dengan tim lintas divisi.",
    "Kekuatan saya adalah komunikasi yang jelas dan terstruktur.",
    "Saya terbiasa membuat dokumentasi agar pekerjaan rapi.",
    "Saya nyaman menerima feedback dan memperbaiki proses.",
    "Saya teliti, terutama untuk pekerjaan yang detail.",
    "Saya menjaga kualitas kerja dengan checklist dan review.",
    "Saya bisa menjelaskan ide dengan sederhana dan mudah dipahami.",
    "Saya menggunakan [Tools/Tech] untuk meningkatkan produktivitas.",
    "Saya terbiasa menyusun prioritas supaya pekerjaan efektif.",
    "Saya nyaman presentasi singkat untuk update progres.",
    "Saya tertarik melamar di perusahaan ini karena [Alasan Anda].",
  ];

  final List<String> hardIntro = const [
    "Selamat pagi, perkenalkan nama saya [Nama Anda].",
    "Saya berfokus pada pengembangan skill di bidang [Bidang Anda].",
    "Saya ingin berkontribusi melalui hasil yang terukur dan berdampak.",
  ];

  final List<String> hardPool = const [
    "Saya pernah memimpin tim dan mengelola target yang ketat.",
    "Saya terbiasa bekerja di bawah tekanan dan tetap menjaga kualitas.",
    "Saya menghadapi tantangan [Tantangan] dan menyelesaikannya dengan [Solusi].",
    "Saya sering melakukan evaluasi pasca proyek untuk meningkatkan proses.",
    "Saya mampu membuat estimasi waktu dan risiko secara realistis.",
    "Saya menjaga komunikasi agar stakeholder selalu mendapatkan update.",
    "Saya bisa mengurai masalah kompleks menjadi langkah-langkah kecil.",
    "Saya mengutamakan kualitas: testing, review, dan dokumentasi.",
    "Saya terbiasa mengukur hasil dengan metrik seperti [Metrik].",
    "Saya pernah melakukan improvement yang meningkatkan efisiensi [X%].",
    "Saya nyaman melakukan presentasi dan menjawab pertanyaan teknis.",
    "Dalam 5 tahun ke depan, saya ingin menjadi ahli di bidang ini.",
    "Saya yakin bisa berkontribusi melalui [Nilai tambah Anda].",
    "Saya punya kebiasaan belajar: membaca, praktik, dan evaluasi rutin.",
    "Saya siap menerima feedback dan cepat melakukan iterasi.",
  ];

  @override
  void onInit() {
    super.onInit();
    _preloadAudio();
    _setupMlkitListeners();
    _initStt();

    // ✅ sync alias otomatis kalau totalConfidenceSession berubah
    ever(totalConfidenceSession, (_) => _syncConfidenceAlias());
    _syncConfidenceAlias();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _lineWindowTimer?.cancel();
    _silenceTimer?.cancel();
    _mlkitPeriodicTimer?.cancel();
    _mlkitPeriodicTimer = null;
    _stopSttHard();
    audioPlayer.dispose();
    customTextController.dispose();
    super.onClose();
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _preloadAudio() async {
    try {
      await audioPlayer.setReleaseMode(ReleaseMode.release);
      await audioPlayer.setVolume(0.8);
      await audioPlayer.setPlayerMode(PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<void> _playSound(String soundType) async {
    if (!isSessionRunning.value) return;
    if (!soundEnabled.value) return;

    try {
      final now = DateTime.now();

      bool throttle(Duration d, DateTime? last) =>
          last != null && now.difference(last) < d;

      switch (soundType) {
        case 'mouth_too_open':
          if (throttle(const Duration(seconds: 3), _lastMouthSound)) return;
          _lastMouthSound = now;
          break;
        case 'head_tilt':
          if (throttle(const Duration(seconds: 3), _lastTiltSound)) return;
          _lastTiltSound = now;
          break;
        case 'bad_posture':
          if (throttle(const Duration(seconds: 3), _lastPostureSound)) return;
          _lastPostureSound = now;
          break;
        case 'bad_eye_contact':
          if (throttle(const Duration(seconds: 4), _lastEyeSound)) return;
          _lastEyeSound = now;
          break;
        case 'speaking_too_fast':
          if (throttle(const Duration(seconds: 5), _lastSpeedSound)) return;
          _lastSpeedSound = now;
          break;
        case 'too_many_fillers':
          if (throttle(const Duration(seconds: 5), _lastFillerSound)) return;
          _lastFillerSound = now;
          break;
        case 'good_job':
          if (throttle(const Duration(seconds: 10), _lastGoodSound)) return;
          _lastGoodSound = now;
          break;
      }

      final soundPath = soundPaths[soundType];
      if (soundPath == null) return;

      await audioPlayer.stop();
      await audioPlayer.play(AssetSource(soundPath));
    } catch (_) {}
  }

  // ===== STT init =====
  Future<void> _initStt() async {
    try {
      _sttReady = await sttEngine.initialize(
        onStatus: (status) {
          sttStatusText.value = status;
          sttIsListening.value = sttEngine.isListening;

          if (!isSessionRunning.value) return;

          if (status == 'done' || status == 'notListening') {
            _scheduleRestartListening(reason: 'status:$status');
          }
        },
        onError: (e) {
          sttStatusText.value = 'error:${e.errorMsg}';
          if (!isSessionRunning.value) return;
          _scheduleRestartListening(reason: 'error');
        },
      );
    } catch (_) {
      _sttReady = false;
    }
  }

  Future<void> _stopSttHard() async {
    try {
      if (sttEngine.isListening) {
        await sttEngine.stop();
      }
    } catch (_) {}
    sttIsListening.value = false;
  }

  Future<void> _startListeningOnce() async {
    if (!isSessionRunning.value) return;
    if (!_sttReady || !sttEngine.isAvailable) return;
    if (sttEngine.isListening) return;

    try {
      sttEngine.listen(
        localeId: 'id_ID',
        partialResults: true,
        cancelOnError: false,
        listenFor: const Duration(seconds: sttListenForSeconds),
        pauseFor: const Duration(seconds: sttPauseForSeconds),
        onResult: (result) {
          final text = result.recognizedWords.trim();
          if (text.isEmpty) return;

          _lastSpeechAt = DateTime.now();

          currentLineRecognized.value = text;
          sttConfidence.value = result.confidence;

          _updateRealtimeSpeech(text);
        },
      );

      sttIsListening.value = true;
    } catch (_) {
      sttIsListening.value = false;
      _scheduleRestartListening(reason: 'listen-exception');
    }
  }

  void _scheduleRestartListening({required String reason}) {
    if (!isSessionRunning.value || _restarting) return;

    final now = DateTime.now();
    if (_lastRestartAt != null &&
        now.difference(_lastRestartAt!) < const Duration(seconds: 2)) {
      return;
    }

    _restarting = true;
    _lastRestartAt = now;

    Future.delayed(const Duration(milliseconds: 900), () async {
      _restarting = false;
      if (!isSessionRunning.value) return;
      if (!_sttReady || !sttEngine.isAvailable) return;

      try {
        if (sttEngine.isListening) {
          await sttEngine.stop();
        }
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: sttRefreshGapMs));
      if (!isSessionRunning.value) return;

      await _startListeningOnce();
    });
  }

  Future<void> _refreshSttForNewLine() async {
    if (!isSessionRunning.value) return;
    if (_sttCycling) return;
    _sttCycling = true;

    try {
      if (!_sttReady || !sttEngine.isAvailable) return;

      try {
        if (sttEngine.isListening) {
          await sttEngine.stop();
        }
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: sttRefreshGapMs));
      if (!isSessionRunning.value) return;

      await _startListeningOnce();
    } finally {
      _sttCycling = false;
    }
  }

  void _startSilenceMonitor() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!isSessionRunning.value) return;

      final last = _lastSpeechAt;
      if (last == null) {
        wordsPerMinute.value = 0;
        fluencyScore.value = 0;
        return;
      }

      final idleMs = DateTime.now().difference(last).inMilliseconds;
      if (idleMs > 1500) {
        wordsPerMinute.value = 0;
        final next = (fluencyScore.value - 6).clamp(0.0, 100.0);
        fluencyScore.value = next;
      }
    });
  }

  void _setupMlkitListeners() {
    ever(detect.mouthOpenRatio, (ratio) {
      if (!isSessionRunning.value) return;
      final r = (ratio as num).toDouble();

      mouthRatios.add(r);
      _lineMouth.add(r);

      if (r > 0.45) {
        isMouthGood.value = false;
        _playSound('mouth_too_open');
      } else if (r > 0.12 && r < 0.35) {
        isMouthGood.value = true;
      } else if (r < 0.12) {
        isMouthGood.value = false;
      }
    });

    ever(detect.headTiltDeg, (tilt) {
      if (!isSessionRunning.value) return;
      final absTilt = (tilt as num).toDouble().abs();

      tiltDegrees.add(absTilt);
      _lineTiltAbs.add(absTilt);

      if (absTilt > 15) {
        isHeadGood.value = false;
        _playSound('head_tilt');
      } else if (absTilt > 8) {
        isHeadGood.value = false;
      } else {
        isHeadGood.value = true;
      }
    });

    ever(detect.postureLeanScore, (posture) {
      if (!isSessionRunning.value) return;
      final p = (posture as num).toDouble();

      postureScores.add(p);
      _linePosture.add(p);

      if (p > 0.7) {
        isPostureGood.value = false;
        _playSound('bad_posture');
      } else if (p > 0.4) {
        isPostureGood.value = false;
      } else {
        isPostureGood.value = true;
      }
    });

    ever(detect.eyeContactRatio, (v) {
      if (!isSessionRunning.value) return;
      final e = (v as num).toDouble().clamp(0.0, 1.0);

      eyeRatios.add(e);
      _lineEye.add(e);

      if (e < 0.35) {
        isEyeGood.value = false;
        _playSound('bad_eye_contact');
      } else if (e < 0.55) {
        isEyeGood.value = false;
      } else {
        isEyeGood.value = true;
      }
    });

    _mlkitPeriodicTimer?.cancel();
    _mlkitPeriodicTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!isSessionRunning.value) return;

      _lineWpmSamples.add(wordsPerMinute.value);
      _lineFillerSamples.add(fillerCount.value);

      if (wordsPerMinute.value > 180) {
        isSpeedGood.value = false;
        _playSound('speaking_too_fast');
      } else if (wordsPerMinute.value > 100 && wordsPerMinute.value < 170) {
        isSpeedGood.value = true;
      }

      if (fillerCount.value >= 3) {
        isFillerGood.value = false;
        _playSound('too_many_fillers');
      }

      if (isMouthGood.value &&
          isHeadGood.value &&
          isPostureGood.value &&
          isEyeGood.value &&
          isSpeedGood.value &&
          isFillerGood.value) {
        _playSound('good_job');
      }
    });
  }

  double _avgD(List<double> v) {
    if (v.isEmpty) return 0.0;
    double s = 0;
    for (final x in v) s += x;
    return s / v.length;
  }

  double _avgI(List<int> v) {
    if (v.isEmpty) return 0.0;
    int s = 0;
    for (final x in v) s += x;
    return s / v.length;
  }

  void pickMedium() {
    selectedDifficulty.value = 'medium';
    _buildScriptFromSelection();
    startCountdown();
  }

  void pickHard() {
    selectedDifficulty.value = 'hard';
    _buildScriptFromSelection();
    startCountdown();
  }

  void pickCustom() {
    selectedDifficulty.value = 'custom';
    step.value = PracticeStep.customInput;
    customTextController.clear();
  }

  void submitCustomAndStart() {
    final text = customTextController.text.trim();
    if (text.isEmpty) {
      Get.snackbar(
        'Script kosong',
        'Silakan tulis naskah custom terlebih dahulu',
      );
      return;
    }

    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      Get.snackbar('Format salah', 'Pisahkan setiap kalimat dengan baris baru');
      return;
    }

    scriptLines.assignAll(lines);
    currentIndex.value = 0;
    currentLine.value = scriptLines.first;

    _resetAll();
    startCountdown();
  }

  void backToChoose() {
    stopSession(goResult: false);
    step.value = PracticeStep.choose;
  }

  void _buildScriptFromSelection() {
    final rng = Random();

    if (selectedDifficulty.value == 'medium') {
      final pool = [...mediumPool]..shuffle(rng);
      final picked = pool.take(2 + rng.nextInt(2)).toList();
      final script = [...mediumIntro, ...picked];
      scriptLines.assignAll(script);
    } else if (selectedDifficulty.value == 'hard') {
      final pool = [...hardPool]..shuffle(rng);
      final picked = pool.take(3 + rng.nextInt(3)).toList();
      final script = [...hardIntro, ...picked];
      scriptLines.assignAll(script);
    } else {
      scriptLines.clear();
    }

    currentIndex.value = 0;
    currentLine.value = scriptLines.isNotEmpty ? scriptLines.first : '';
    _resetAll();
  }

  void startCountdown() {
    if (!detect.isCameraReady.value) {
      Get.snackbar('Kamera', 'Kamera belum siap. Tunggu sebentar...');
      step.value = PracticeStep.choose;
      return;
    }

    countdown.value = 3;
    step.value = PracticeStep.countdown;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown.value > 1) {
        countdown.value--;
      } else {
        t.cancel();
        countdown.value = 0;
        startSession();
      }
    });
  }

  Future<void> startSession() async {
    if (isSessionRunning.value) return;

    try {
      if (!detect.isCameraReady.value) {
        Get.snackbar('Kamera', 'Kamera belum siap. Tunggu sebentar...');
        step.value = PracticeStep.choose;
        return;
      }

      final micOk = await _ensureMicPermission();
      if (!micOk) {
        Get.snackbar('Izin Microphone', 'Aktifkan izin microphone untuk STT');
        step.value = PracticeStep.choose;
        return;
      }

      if (!_sttReady) await _initStt();

      _resetAll();
      finalSuggestions.clear();

      isSessionRunning.value = true;
      _sessionStart = DateTime.now();
      _lastSpeechAt = null;

      // ✅ Reset committed lines
      _committedLines.clear();

      step.value = PracticeStep.practice;

      await detect.start();

      if (_sttReady && sttEngine.isAvailable) {
        await _refreshSttForNewLine();
      } else {
        Get.snackbar('STT', 'STT tidak tersedia, latihan berjalan tanpa STT');
      }

      _startLineWindow();
      _startSilenceMonitor();
    } catch (e) {
      isSessionRunning.value = false;
      step.value = PracticeStep.choose;
      Get.snackbar('Error', 'Gagal memulai sesi: $e');
    }
  }

  Future<void> stopSession({required bool goResult}) async {
    isSessionRunning.value = false;

    _lineWindowTimer?.cancel();
    _silenceTimer?.cancel();
    _mlkitPeriodicTimer?.cancel();
    _mlkitPeriodicTimer = null;

    await detect.stop();
    await _stopSttHard();

    _finalizeWpm();
    _finalizeFluency();

    if (goResult) {
      // ✅ Simpan transcript baris terakhir jika ada
      if (currentLineRecognized.value.isNotEmpty) {
        _commitLineTranscript();
      }

      _finalizeTotalConfidenceSession();

      final tips = buildSuggestions();
      finalSuggestions.assignAll(tips);

      await _saveSessionToFirebase(tips);

      showCelebration.value = true;
      Future.delayed(const Duration(milliseconds: 1800), () {
        showCelebration.value = false;
      });

      step.value = PracticeStep.result;
    }
  }

  void _startLineWindow() {
    secondsLeftInLine.value = lineDurationSeconds;
    currentLineRecognized.value = '';
    _resetLineCollectors();

    _lineWindowTimer?.cancel();
    _lineWindowTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!isSessionRunning.value) {
        t.cancel();
        return;
      }

      if (secondsLeftInLine.value > 1) {
        secondsLeftInLine.value--;
        return;
      }

      secondsLeftInLine.value = 0;

      // ✅ Panggil finalize untuk baris ini (akan menyimpan transcript)
      _finalizeLineScoreAndStore();

      if (currentIndex.value < scriptLines.length - 1) {
        currentIndex.value++;
        currentLine.value = scriptLines[currentIndex.value];

        secondsLeftInLine.value = lineDurationSeconds;
        currentLineRecognized.value = '';
        _resetLineCollectors();

        if (_sttReady && sttEngine.isAvailable) {
          await _refreshSttForNewLine();
        }
        return;
      }

      t.cancel();
      await stopSession(goResult: true);
    });
  }

  void _resetLineCollectors() {
    _lineMouth.clear();
    _lineTiltAbs.clear();
    _linePosture.clear();
    _lineEye.clear();
    _lineWpmSamples.clear();
    _lineFillerSamples.clear();
  }

  // HANYA BAGIAN YANG DIUBAH - METHOD _finalizeLineScoreAndStore

  void _finalizeLineScoreAndStore() {
    // ✅ CEK DULU APAKAH Wajah Terdeteksi di sesi ini?
    // Jika wajah tidak pernah terdeteksi sama sekali, jangan simpan skor aneh
    if (!detect.isFaceDetected.value && mouthRatios.isEmpty) {
      print(
        '⚠️ Wajah tidak terdeteksi sepanjang baris ini - skip penyimpanan skor',
      );
      return;
    }

    final mouthAvg = _avgD(_lineMouth).clamp(0.0, 1.0);
    final tiltAvg = _avgD(_lineTiltAbs).clamp(0.0, 30.0);
    final postureAvg = _avgD(_linePosture).clamp(0.0, 1.0);
    final eyeAvg = _avgD(_lineEye).clamp(0.0, 1.0);
    final wpmAvg = _avgI(_lineWpmSamples).clamp(0.0, 260.0);
    final fillerAvg = _avgI(_lineFillerSamples).clamp(0.0, 10.0);

    double mouthPenalty;
    if (mouthAvg < 0.14) {
      mouthPenalty = 70;
    } else if (mouthAvg <= 0.42) {
      mouthPenalty = 10;
    } else {
      mouthPenalty = 65;
    }

    final tiltPenalty = (tiltAvg <= 6)
        ? 5
        : (tiltAvg >= 18)
        ? 80
        : ((tiltAvg - 6) / 12) * 80;

    final posturePenalty = postureAvg * 90;

    final eyePenalty = ((1.0 - eyeAvg) * 80).clamp(0.0, 80.0);

    double wpmPenalty;
    if (wpmAvg < 95) {
      wpmPenalty = 40;
    } else if (wpmAvg <= 175) {
      wpmPenalty = 10;
    } else {
      wpmPenalty = 55;
    }

    final fillerPenalty = (fillerAvg * 12).clamp(0.0, 80.0);

    final totalPenalty =
        (mouthPenalty * 0.20 +
                tiltPenalty * 0.18 +
                posturePenalty * 0.20 +
                eyePenalty * 0.12 +
                wpmPenalty * 0.16 +
                fillerPenalty * 0.14)
            .clamp(0.0, 100.0);

    final confidence = (100 - totalPenalty).round().clamp(0, 100);

    String label;
    if (confidence >= 70) {
      label = 'Tenang';
    } else if (confidence >= 45) {
      label = 'Kurang PD';
    } else {
      label = 'Gugup';
    }

    // ✅ HANYA simpan jika confidence masuk akal (tidak 0 semua)
    if (mouthAvg > 0 || tiltAvg > 0 || postureAvg > 0 || eyeAvg > 0) {
      lineConfidenceScores.add(confidence);
      lineLabels.add(label);
    }

    // Tetap simpan transcript
    _commitLineTranscript();
  }

  void _finalizeTotalConfidenceSession() {
    if (lineConfidenceScores.isEmpty) {
      totalConfidenceSession.value = 0.0;
      _syncConfidenceAlias();
      return;
    }
    double sum = 0;
    for (final x in lineConfidenceScores) {
      sum += x.toDouble();
    }
    totalConfidenceSession.value = double.parse(
      (sum / lineConfidenceScores.length).toStringAsFixed(2),
    );

    _syncConfidenceAlias();
  }

  void _commitLineTranscript() {
    final lineText = currentLineRecognized.value.trim();
    if (lineText.isEmpty) return;

    // ✅ CEK APAKAH SUDAH PERNAH DI-COMMIT
    // Gunakan hash dari text + index untuk unique identifier
    final lineId = '${currentIndex.value}_$lineText';
    if (_committedLines.contains(lineId)) {
      return; // Sudah pernah di-commit, skip
    }

    _committedLines.add(lineId);
    _lastCommittedLine = lineText;

    if (recognizedText.value.isEmpty) {
      recognizedText.value = lineText;
    } else {
      recognizedText.value += '\n$lineText';
    }
  }

  void _updateRealtimeSpeech(String spoken) {
    final start = _sessionStart ?? DateTime.now();
    final secs = max(1, DateTime.now().difference(start).inSeconds);

    final wc = spoken.split(' ').where((w) => w.trim().isNotEmpty).length;
    wordsPerMinute.value = (wc / secs * 60).round();

    final filler = {
      'umm',
      'uh',
      'ah',
      'eh',
      'ehem',
      'jadi',
      'kan',
      'anu',
      'itu',
      'em',
      'hmm',
      'mmm',
      'ya',
      'begini',
      'begitu',
      'apa',
      'sih',
    };

    fillerCount.value = spoken
        .toLowerCase()
        .split(' ')
        .where((w) => filler.contains(w.trim()))
        .length;

    final base = 100.0 - (fillerCount.value * 6.0);

    double wpmPenalty = 0;
    if (wordsPerMinute.value > 190) wpmPenalty = 15;
    if (wordsPerMinute.value > 0 && wordsPerMinute.value < 90) wpmPenalty = 12;

    fluencyScore.value = (base - wpmPenalty).clamp(0.0, 100.0);
  }

  void _finalizeWpm() {
    final start = _sessionStart;
    if (start == null) return;

    final secs = max(1, DateTime.now().difference(start).inSeconds);
    final wc = recognizedText.value
        .replaceAll('\n', ' ')
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
        .length;

    wordsPerMinute.value = (wc / secs * 60).round();
  }

  void _finalizeFluency() {
    fluencyScore.value = fluencyScore.value.clamp(0.0, 100.0);
  }

  List<String> buildSuggestions() {
    final tips = <String>[];

    if (detect.scoreTilt.value >= 60) {
      tips.add(
        '👤 Kepala terlalu miring — jaga kepala tetap tegak dan pandang kamera',
      );
    }
    if (detect.scorePosture.value >= 60) {
      tips.add(
        '💪 Postur miring — sejajarkan bahu dan pinggul, duduk/berdiri lebih tegak',
      );
    }
    if (detect.scoreEye.value >= 55) {
      tips.add(
        '👀 Kontak mata kurang — kurangi menunduk, arahkan wajah ke kamera saat bicara',
      );
    }

    if (wordsPerMinute.value > 180) {
      tips.add('⚡ Terlalu cepat — target 120–160 kata/menit');
    } else if (wordsPerMinute.value > 0 && wordsPerMinute.value < 95) {
      tips.add(
        '🐌 Terlalu pelan — tingkatkan tempo sedikit agar lebih meyakinkan',
      );
    }

    if (fillerCount.value >= 4) {
      tips.add('🗣️ Filler banyak — ganti “umm/anu” dengan jeda 1 detik');
    }

    if (lineConfidenceScores.isNotEmpty) {
      final minScore = lineConfidenceScores.reduce(min);
      if (minScore < 45) {
        tips.add(
          '🎯 Ada beberapa kalimat yang terdengar ragu — coba ulang dengan intonasi lebih tegas',
        );
      }
    }

    if (tips.isEmpty) {
      tips.add('🎉 Excellent! Performa kamu sudah bagus, pertahankan!');
      tips.add(
        '✅ Postur, tempo bicara, eye contact, dan confidence sudah oke untuk interview',
      );
    }

    return tips;
  }

  Future<void> _saveSessionToFirebase(List<String> tips) async {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);
    final monthKey = DateFormat('yyyy-MM').format(now);

    final avgMouthRatio = _avgD(mouthRatios);
    final avgTiltAbsDeg = _avgD(tiltDegrees);
    final avgPostureLean = _avgD(postureScores);

    final session = PracticeSession(
      createdAt: now,
      dateKey: dateKey,
      monthKey: monthKey,
      difficulty: selectedDifficulty.value,
      scriptLineCount: scriptLines.length,
      wpm: wordsPerMinute.value,
      fluency: fluencyScore.value,
      fillerCount: fillerCount.value,
      scoreMouth: detect.scoreMouth.value,
      scoreTilt: detect.scoreTilt.value,
      scorePosture: detect.scorePosture.value,
      nervousScore: detect.nervousScore.value,
      nervousLabel: detect.nervousLabel.value,
      avgMouthRatio: avgMouthRatio,
      avgTiltAbsDeg: avgTiltAbsDeg,
      avgPostureLean: avgPostureLean,
      recognizedText: recognizedText.value,
      suggestions: tips,
    );

    try {
      await fs.saveSession(session);

      // ✅ TAMBAHKAN NOTIFIKASI +5 POIN
      Get.snackbar(
        '✨ Latihan Selesai!',
        'Hasil tersimpan • +5 poin • Aktivitas tercatat',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        icon: const Icon(Icons.emoji_events, color: Colors.white),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        'Peringatan',
        'Gagal menyimpan ke cloud: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _resetAll() {
    recognizedText.value = '';
    currentLineRecognized.value = '';
    sttConfidence.value = 0.0;

    wordsPerMinute.value = 0;
    fillerCount.value = 0;
    fluencyScore.value = 0.0;

    totalConfidenceSession.value = 0.0;
    _syncConfidenceAlias();

    secondsLeftInLine.value = lineDurationSeconds;
    _sessionStart = null;

    _lastSpeechAt = null;
    _silenceTimer?.cancel();

    _restarting = false;
    _lastRestartAt = null;
    _sttCycling = false;

    lineConfidenceScores.clear();
    lineLabels.clear();

    mouthRatios.clear();
    tiltDegrees.clear();
    postureScores.clear();
    eyeRatios.clear();

    _resetLineCollectors();

    _lastMouthSound = null;
    _lastTiltSound = null;
    _lastPostureSound = null;
    _lastEyeSound = null;
    _lastSpeedSound = null;
    _lastFillerSound = null;
    _lastGoodSound = null;

    _lastCommittedLine = '';
    _committedLines.clear();
  }
}
