// lib/app/controllers/narasi_practice_controller.dart
import 'dart:async';
import 'dart:math';

import 'package:fluent_ai/app/models/detection_result_model.dart';
import 'package:fluent_ai/app/models/practice_session_model.dart';
import 'package:fluent_ai/app/services/ai_feedback_service.dart';
import 'package:fluent_ai/app/services/practice_firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import 'narasi_detect_controller.dart';

enum PracticeStep { instructions, choose, countdown, practice, result }

enum PracticeLevel { medium, hard, advance }

class NarasiPracticeController extends GetxController {
  static const int sttRefreshGapMs = 450;

  final NarasiDetectController detect = Get.find<NarasiDetectController>();
  final PracticeFirestoreService fs = PracticeFirestoreService();
  final AiFeedbackService aiService = AiFeedbackService();

  late final FlutterTts flutterTts;
  final isTtsSpeaking = false.obs;
  final soundEnabled = true.obs;

  final selectedLevel = PracticeLevel.medium.obs;

  final stt.SpeechToText sttEngine = stt.SpeechToText();
  bool _sttReady = false;
  final sttStatusText = ''.obs;
  final sttIsListening = false.obs;

  Timer? _sttRestartTimer;
  bool _isSttRestarting = false;
  DateTime? _lastSttRestart;

  final step = PracticeStep.instructions.obs;

  final RxList<String> scriptLines = <String>[].obs;
  final currentIndex = 0.obs;
  final currentLine = ''.obs;

  final countdown = 0.obs;
  Timer? _countdownTimer;

  final isSessionRunning = false.obs;
  final isAsking = false.obs;
  final isAnswering = false.obs;

  final RxList<Map<String, String>> qaHistory = <Map<String, String>>[].obs;
  final recognizedText = ''.obs;
  final currentLineRecognized = ''.obs;
  final sttConfidence = 0.0.obs;

  // ========== WPM & FILLER (TANPA FLUENCY) ==========
  final wordsPerMinute = 0.obs;
  final fillerCount = 0.obs;
  final totalWordsSpoken = 0.obs;
  final totalFillersCount = 0.obs;
  final RxList<String> allRecognizedWords = <String>[].obs;

  DateTime? _sessionStart;
  DateTime? _lastSpeechAt;
  Timer? _silenceTimer;
  int _totalSpeakingSeconds = 0;

  Timer? _answerTimer;
  final secondsLeftInLine = 0.obs;

  final RxList<String> finalSuggestions = <String>[].obs;

  final aiRecommendation = ''.obs;
  final detectionResult = Rxn<DetectionResultModel>();

  final eyeContactLabel = ''.obs;
  final smileLabel = ''.obs;
  final postureLabel = ''.obs;
  final overallLabel = ''.obs;
  final confidenceMessage = ''.obs;

  final isFaceWarning = false.obs;
  final faceWarningMessage = ''.obs;
  Timer? _faceWarningTimer;

  final isAiProcessing = false.obs;
  final aiProcessingMessage = 'Sedang menganalisis hasil...'.obs;

  // Flag untuk mencegah penyimpanan ganda
  bool _isSessionSaved = false;

  final Map<PracticeLevel, List<String>> hrdQuestions = {
    PracticeLevel.medium: [
      "Selamat pagi, perkenalkan diri Anda secara singkat.",
      "Apa yang membuat Anda tertarik melamar di perusahaan kami?",
      "Ceritakan tentang latar belakang pendidikan Anda.",
      "Apa yang Anda ketahui tentang posisi yang Anda lamar?",
      "Mengapa Anda memilih karir di bidang ini?",
      "Apa kelebihan utama Anda yang paling relevan untuk posisi ini?",
      "Bagaimana cara Anda memprioritaskan pekerjaan ketika memiliki beberapa tugas?",
    ],
    PracticeLevel.hard: [
      "Ceritakan tentang pengalaman kerja Anda yang paling menantang.",
      "Bagaimana cara Anda menghadapi konflik dalam tim?",
      "Apa pencapaian terbesar Anda di pekerjaan sebelumnya?",
      "Mengapa Anda meninggalkan pekerjaan sebelumnya?",
      "Bagaimana Anda menangani tekanan dan tenggat waktu yang ketat?",
      "Ceritakan momen ketika Anda harus beradaptasi dengan perubahan besar di tempat kerja.",
    ],
    PracticeLevel.advance: [
      "Kami butuh seseorang yang bisa memimpin tim besar. Berikan contoh konkretnya.",
      "Bagaimana Anda menangani situasi di mana atasan Anda membuat keputusan yang salah?",
      "Dalam 5 tahun ke depan, di mana Anda melihat diri Anda?",
      "Apa kelemahan terbesar Anda? Berikan contoh nyata.",
      "Ceritakan tentang proyek yang gagal karena kesalahan Anda.",
      "Ceritakan pengalaman saat harus meyakinkan pemangku kepentingan yang awalnya menentang ide Anda.",
    ],
  };

  int _answerSecondsForLevel(PracticeLevel level) {
    switch (level) {
      case PracticeLevel.medium:
        return 20;
      case PracticeLevel.hard:
        return 25;
      case PracticeLevel.advance:
        return 30;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initStt();
    _initTts();

    ever(detect.isFaceDetected, (detected) {
      if (isSessionRunning.value && !detected) {
        _showFaceWarning(
          'Wajah tidak terdeteksi! Pastikan wajah Anda terlihat jelas di kamera.',
        );
      } else if (detected && isFaceWarning.value) {
        _clearFaceWarning();
      }
    });

    ever(sttIsListening, (listening) {
      if (!listening && isSessionRunning.value && isAnswering.value) {
        _scheduleSttRestart();
      }
    });
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _answerTimer?.cancel();
    _silenceTimer?.cancel();
    _sttRestartTimer?.cancel();
    _faceWarningTimer?.cancel();
    _stopSttHard();
    _stopTts();
    super.onClose();
  }

  void _showFaceWarning(String message) {
    isFaceWarning.value = true;
    faceWarningMessage.value = message;
    _faceWarningTimer?.cancel();
    _faceWarningTimer = Timer(const Duration(seconds: 3), () {
      if (isFaceWarning.value) {
        isFaceWarning.value = false;
        faceWarningMessage.value = '';
      }
    });
  }

  void _clearFaceWarning() {
    isFaceWarning.value = false;
    faceWarningMessage.value = '';
    _faceWarningTimer?.cancel();
  }

  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("id-ID");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);

    flutterTts.setStartHandler(() => isTtsSpeaking.value = true);
    flutterTts.setCompletionHandler(() {
      isTtsSpeaking.value = false;
      isAsking.value = false;
      if (isSessionRunning.value) _startAnswerPhase();
    });
    flutterTts.setCancelHandler(() {
      isTtsSpeaking.value = false;
      isAsking.value = false;
    });
    flutterTts.setErrorHandler((msg) {
      isTtsSpeaking.value = false;
      isAsking.value = false;
      if (isSessionRunning.value) _startAnswerPhase();
    });
  }

  Future<void> _stopTts() async {
    try {
      await flutterTts.stop();
      isTtsSpeaking.value = false;
      isAsking.value = false;
    } catch (_) {}
  }

  Future<void> speakHrdQuestion(String question) async {
    _answerTimer?.cancel();
    isAnswering.value = false;

    if (sttEngine.isListening) {
      await sttEngine.stop();
      sttIsListening.value = false;
    }

    currentLineRecognized.value = '';

    if (!soundEnabled.value) {
      isAsking.value = false;
      await _startAnswerPhase();
      return;
    }

    try {
      isAsking.value = true;
      await _stopTts();
      await flutterTts.speak(question);
    } catch (_) {
      isAsking.value = false;
      await _startAnswerPhase();
    }
  }

  void toggleSound() {
    soundEnabled.value = !soundEnabled.value;
    if (!soundEnabled.value) _stopTts();
  }

  void startToChoose() {
    step.value = PracticeStep.choose;
  }

  void pickMedium() {
    selectedLevel.value = PracticeLevel.medium;
    detect.setLevel('medium');
    _buildScriptFromLevel();
    startCountdown();
  }

  void pickHard() {
    selectedLevel.value = PracticeLevel.hard;
    detect.setLevel('hard');
    _buildScriptFromLevel();
    startCountdown();
  }

  void pickAdvance() {
    selectedLevel.value = PracticeLevel.advance;
    detect.setLevel('advance');
    _buildScriptFromLevel();
    startCountdown();
  }

  void _buildScriptFromLevel() {
    final level = selectedLevel.value;
    final questions = hrdQuestions[level] ?? [];
    final rng = Random();
    final shuffled = List<String>.from(questions)..shuffle(rng);

    int count = level == PracticeLevel.medium
        ? 5
        : (level == PracticeLevel.hard ? 6 : 6);
    scriptLines.assignAll(shuffled.take(count).toList());
    currentIndex.value = 0;
    currentLine.value = scriptLines.isNotEmpty ? scriptLines.first : '';

    _resetAll();
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _initStt() async {
    try {
      _sttReady = await sttEngine.initialize(
        onStatus: (status) {
          sttStatusText.value = status;
          sttIsListening.value = sttEngine.isListening;
        },
        onError: (e) {
          sttStatusText.value = 'error:${e.errorMsg}';
          _scheduleSttRestart();
        },
      );
    } catch (_) {
      _sttReady = false;
    }
  }

  Future<void> _stopSttHard() async {
    try {
      if (sttEngine.isListening) await sttEngine.stop();
    } catch (_) {}
    sttIsListening.value = false;
  }

  Future<void> _startListeningOnce() async {
    if (!isSessionRunning.value ||
        !isAnswering.value ||
        !_sttReady ||
        !sttEngine.isAvailable) {
      return;
    }
    if (sttEngine.isListening) return;

    try {
      sttEngine.listen(
        localeId: 'id_ID',
        partialResults: true,
        cancelOnError: false,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        onResult: (result) {
          final text = result.recognizedWords.trim();
          if (text.isNotEmpty) {
            _lastSpeechAt = DateTime.now();
            currentLineRecognized.value = text;
            sttConfidence.value = result.confidence;
            _updateRealtimeSpeech(text);
          }
        },
      );
      sttIsListening.value = true;
      _scheduleSttRestart();
    } catch (_) {
      sttIsListening.value = false;
      _scheduleSttRestart();
    }
  }

  void _scheduleSttRestart() {
    _sttRestartTimer?.cancel();
    _sttRestartTimer = Timer(const Duration(seconds: 2), () {
      if (isSessionRunning.value &&
          isAnswering.value &&
          !sttEngine.isListening) {
        _restartStt();
      }
    });
  }

  Future<void> _restartStt() async {
    if (_isSttRestarting || !isSessionRunning.value || !isAnswering.value) {
      return;
    }
    final now = DateTime.now();
    if (_lastSttRestart != null &&
        now.difference(_lastSttRestart!) < const Duration(seconds: 3)) {
      return;
    }

    _isSttRestarting = true;
    _lastSttRestart = now;
    try {
      if (sttEngine.isListening) await sttEngine.stop();
      await Future.delayed(const Duration(milliseconds: 300));
      await _startListeningOnce();
    } finally {
      _isSttRestarting = false;
    }
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
        step.value = PracticeStep.choose;
        return;
      }
      final micOk = await _ensureMicPermission();
      if (!micOk) {
        Get.snackbar('Izin', 'Aktifkan microphone untuk latihan');
        step.value = PracticeStep.choose;
        return;
      }
      if (!_sttReady) {
        await _initStt();
      }

      _resetAll();
      _isSessionSaved = false;
      detect.resetAllCounters();
      detect.startWindowTimer();

      isSessionRunning.value = true;
      _sessionStart = DateTime.now();
      _lastSpeechAt = null;
      step.value = PracticeStep.practice;

      await detect.start();
      await speakHrdQuestion(currentLine.value);
      _startSilenceMonitor();
    } catch (e) {
      isSessionRunning.value = false;
      step.value = PracticeStep.choose;
    }
  }

  // ========== UPDATE REAL-TIME SPEECH (WPM & FILLER ONLY) ==========
  void _updateRealtimeSpeech(String spoken) {
    if (spoken.trim().isEmpty) return;

    // Simpan teks yang sedang diucapkan (real-time)
    currentLineRecognized.value = spoken;
    _lastSpeechAt = DateTime.now();

    // Hitung kata dari teks saat ini
    final words = spoken
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();
    int currentWordsCount = words.length;

    // Hitung total kata = kata dari riwayat Q&A sebelumnya + kata saat ini
    int totalWordsFromHistory = 0;
    for (final item in qaHistory) {
      final answer = item['a'] ?? '';
      final answerWords = answer
          .split(RegExp(r'\s+'))
          .where((w) => w.trim().isNotEmpty)
          .toList();
      totalWordsFromHistory += answerWords.length;
    }

    // TOTAL KATA SEJAUH INI = riwayat + kata saat ini
    totalWordsSpoken.value = totalWordsFromHistory + currentWordsCount;

    // Hitung filler dari teks saat ini
    final fillerWords = {
      'umm',
      'uh',
      'ah',
      'eh',
      'ehem',
      'anu',
      'em',
      'hmm',
      'eee',
      'ooo',
      'mm',
      'hh',
      'aah',
      'ooh',
      'ehh',
      'uhh',
      'ahh',
      'oh',
      'hm',
      'e',
      'uhm',
      'huh',
      'mmh',
      'mhmm',
      'ha',
      'he',
      'ho',
    };

    int currentFillers = 0;
    for (final word in words) {
      final cleanWord = word.toLowerCase().trim().replaceAll(
        RegExp(r'[^\w]'),
        '',
      );
      if (fillerWords.contains(cleanWord)) {
        currentFillers++;
      }
    }

    // Total filler = filler dari history + filler saat ini
    int totalFillers = 0;
    for (final item in qaHistory) {
      final answer = (item['a'] ?? '').toLowerCase();
      final answerWords = answer
          .split(RegExp(r'\s+'))
          .where((w) => w.trim().isNotEmpty);
      for (final word in answerWords) {
        final cleanWord = word.trim().replaceAll(RegExp(r'[^\w]'), '');
        if (fillerWords.contains(cleanWord)) {
          totalFillers++;
        }
      }
    }
    totalFillers += currentFillers;
    fillerCount.value = totalFillers;
    totalFillersCount.value = totalFillers;

    // WPM REAL-TIME - dihitung dari total waktu sesi berjalan
    if (_sessionStart != null) {
      final elapsedMinutes =
          DateTime.now().difference(_sessionStart!).inSeconds / 60.0;

      if (elapsedMinutes > 0 && totalWordsSpoken.value > 0) {
        // WPM = total kata / total waktu dalam menit
        int wpmValue = (totalWordsSpoken.value / elapsedMinutes).round();

        // Batasi WPM agar tidak aneh (maks 200)
        if (wpmValue > 200) wpmValue = 200;

        wordsPerMinute.value = wpmValue;
      }
    }

    if (kDebugMode) {
      print(
        '🔊 Real-time: ${totalWordsSpoken.value} kata | ${fillerCount.value} filler | ${wordsPerMinute.value} WPM',
      );
    }
  }

  // ========== FINALISASI WPM ==========
  void _finalizeWpm() {
    // HITUNG TOTAL KATA DARI SEMUA JAWABAN (Q&A HISTORY + JAWABAN TERAKHIR)
    int totalWords = 0;

    // 1. Hitung kata dari semua Q&A yang sudah tersimpan
    for (final item in qaHistory) {
      final answer = item['a'] ?? '';
      final words = answer
          .split(RegExp(r'\s+'))
          .where((w) => w.trim().isNotEmpty)
          .toList();
      totalWords += words.length;
    }

    // 2. Tambahkan kata dari jawaban terakhir (yang belum di-commit)
    final currentText = currentLineRecognized.value.trim();
    if (currentText.isNotEmpty) {
      final currentWords = currentText
          .split(RegExp(r'\s+'))
          .where((w) => w.trim().isNotEmpty)
          .toList();
      totalWords += currentWords.length;
    }

    // SIMPAN TOTAL KATA FINAL
    totalWordsSpoken.value = totalWords;

    // HITUNG TOTAL WAKTU SESI
    // Waktu sesi = dari mulai sampai selesai (dalam detik)
    int totalTimeSeconds = 0;

    if (_sessionStart != null) {
      totalTimeSeconds = DateTime.now().difference(_sessionStart!).inSeconds;
    }

    // WPM FINAL = (total kata / total waktu dalam menit)
    if (totalWords > 0 && totalTimeSeconds > 0) {
      double totalMinutes = totalTimeSeconds / 60.0;
      int finalWpm = (totalWords / totalMinutes).round();

      // Batasi WPM maksimal 200
      if (finalWpm > 200) finalWpm = 200;

      wordsPerMinute.value = finalWpm;
    } else {
      wordsPerMinute.value = 0;
    }

    if (kDebugMode) {
      print('📊 FINAL STATS:');
      print('   Total kata: $totalWords');
      print(
        '   Total waktu: $totalTimeSeconds detik (${(totalTimeSeconds / 60).toStringAsFixed(1)} menit)',
      );
      print('   WPM Final: ${wordsPerMinute.value}');
      print('   Jumlah Q&A: ${qaHistory.length}');

      // Detail per pertanyaan
      for (int i = 0; i < qaHistory.length; i++) {
        final answer = qaHistory[i]['a'] ?? '';
        final wordCount = answer
            .split(RegExp(r'\s+'))
            .where((w) => w.trim().isNotEmpty)
            .length;
        print('   Q${i + 1}: $wordCount kata');
      }
    }
  }

  // ========== FINALISASI FILLER - PERBAIKAN ==========
  void _finalizeFillers() {
    int totalFillers = 0;
    final fillerWords = {
      'umm',
      'uh',
      'ah',
      'eh',
      'ehem',
      'anu',
      'em',
      'hmm',
      'eee',
      'ooo',
      'mm',
      'hh',
      'aah',
      'ooh',
      'ehh',
      'uhh',
      'ahh',
      'oh',
      'hm',
      'e',
      'uhm',
      'huh',
      'mmh',
      'mhmm',
      'ha',
      'he',
      'ho',
    };

    // Hitung filler dari Q&A history
    for (final item in qaHistory) {
      final answer = (item['a'] ?? '').toLowerCase();
      final words = answer
          .split(RegExp(r'\s+'))
          .where((w) => w.trim().isNotEmpty);
      for (final word in words) {
        final cleanWord = word.trim().replaceAll(RegExp(r'[^\w]'), '');
        if (fillerWords.contains(cleanWord)) {
          totalFillers++;
        }
      }
    }

    // Tambahkan filler dari jawaban terakhir
    final currentText = currentLineRecognized.value.trim().toLowerCase();
    if (currentText.isNotEmpty) {
      final currentWords = currentText
          .split(RegExp(r'\s+'))
          .where((w) => w.trim().isNotEmpty);
      for (final word in currentWords) {
        final cleanWord = word.trim().replaceAll(RegExp(r'[^\w]'), '');
        if (fillerWords.contains(cleanWord)) {
          totalFillers++;
        }
      }
    }

    fillerCount.value = totalFillers;
    totalFillersCount.value = totalFillers;

    if (kDebugMode) {
      print(
        '🗣️ FINAL FILLER: $totalFillers dari ${totalWordsSpoken.value} kata',
      );
    }
  }

  void _startSilenceMonitor() {
    // Tidak perlu menghitung fluency, biarkan kosong
  }

  Future<void> stopSession({required bool goResult}) async {
    isSessionRunning.value = false;
    isAsking.value = false;
    isAnswering.value = false;
    _clearFaceWarning();

    await _stopTts();
    _answerTimer?.cancel();
    _silenceTimer?.cancel();
    _sttRestartTimer?.cancel();
    await detect.stop();
    await _stopSttHard();

    _commitLineTranscript();
    _finalizeWpm();
    _finalizeFillers();

    if (goResult) {
      step.value = PracticeStep.result;
      isAiProcessing.value = true;
      aiProcessingMessage.value =
          '⏳ AI sedang menganalisis hasil latihan Anda...';
    }

    await _generateAiRecommendation();

    if (goResult && !_isSessionSaved) {
      await _saveSessionToFirestore();
      _isSessionSaved = true;
    }

    if (goResult) {
      isAiProcessing.value = false;
      aiProcessingMessage.value = '';
    }
  }

  Future<void> _saveSessionToFirestore() async {
    try {
      final List<String> suggestions = _extractSuggestionsFromAI();

      final detectionResultModel = DetectionResultModel(
        eyeContact: EyeContactResult(
          lookAwayCount:
              detect.lookAwayLeftCount.value + detect.lookAwayRightCount.value,
          lookDownCount: detect.lookDownCount.value,
          conclusion: eyeContactLabel.value,
          suggestion: _getEyeSuggestion(),
        ),
        facialExpression: FacialExpressionResult(
          smileCount: detect.smileCount.value,
          neutralCount: detect.neutralCount.value,
          conclusion: smileLabel.value,
          suggestion: _getSmileSuggestion(),
        ),
        headPosture: HeadPostureResult(
          headTiltLeftCount: detect.headTiltLeftCount.value,
          headTiltRightCount: detect.headTiltRightCount.value,
          headDownCount: detect.headDownCount.value,
          conclusion: postureLabel.value,
          suggestion: _getPostureSuggestion(),
        ),
        timestamp: DateTime.now(),
        aiRecommendation: aiRecommendation.value,
      );

      final session = PracticeSession(
        createdAt: DateTime.now(),
        dateKey: DateFormat('yyyyMMdd').format(DateTime.now()),
        monthKey: DateFormat('yyyyMM').format(DateTime.now()),
        difficulty: _getLevelString(selectedLevel.value),
        scriptLineCount: scriptLines.length,
        wpm: wordsPerMinute.value,
        fluency: 0, // Tidak dipakai
        fillerCount: fillerCount.value,
        eyeContactLabel: eyeContactLabel.value,
        smileLabel: smileLabel.value,
        postureLabel: postureLabel.value,
        overallLabel: overallLabel.value,
        confidenceMessage: confidenceMessage.value,
        recognizedText: recognizedText.value,
        suggestions: suggestions,
        detectionResult: detectionResultModel,
      );

      await fs.saveSession(session);

      if (kDebugMode) {
        print('✅ Sesi latihan berhasil disimpan ke Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Gagal menyimpan sesi ke Firestore: $e');
      }
    }
  }

  List<String> _extractSuggestionsFromAI() {
    final List<String> extracted = [];
    final text = aiRecommendation.value;

    final saranIndex = text.indexOf('SARAN:');
    if (saranIndex != -1) {
      final saranPart = text.substring(saranIndex);
      final lines = saranPart.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('-') && trimmed.length > 2) {
          extracted.add(trimmed.substring(1).trim());
        }
      }
    }

    if (extracted.isEmpty) {
      extracted.addAll([
        'Tingkatkan kontak mata dengan fokus ke kamera',
        'Cobalah tersenyum lebih sering saat menjawab',
        'Jaga postur tubuh tetap tegak dan rileks',
      ]);
    }

    return extracted.take(3).toList();
  }

  String _getEyeSuggestion() {
    final total =
        detect.lookAwayLeftCount.value +
        detect.lookAwayRightCount.value +
        detect.lookDownCount.value;
    if (total <= 3) {
      return 'Kontak mata sudah baik. Pertahankan fokus ke kamera.';
    } else if (total <= 6) {
      return 'Kurangi melirik ke samping. Bayangkan kamera adalah mata pewawancara.';
    } else {
      return 'Latih kontak mata dengan fokus pada satu titik selama 30 detik setiap hari.';
    }
  }

  String _getSmileSuggestion() {
    final smile = detect.smileCount.value;
    if (smile >= 3 && smile > detect.neutralCount.value) {
      return 'Ekspresi ramah sudah baik. Pertahankan senyum natural Anda.';
    } else if (smile >= 1) {
      return 'Tingkatkan frekuensi senyum, terutama di awal dan akhir jawaban.';
    } else {
      return 'Cobalah tersenyum setidaknya 2-3 kali selama wawancara.';
    }
  }

  String _getPostureSuggestion() {
    final total =
        detect.headTiltLeftCount.value +
        detect.headTiltRightCount.value +
        detect.headDownCount.value;
    if (total <= 3) {
      return 'Postur tubuh sudah baik. Pertahankan posisi tegak dan rileks.';
    } else if (total <= 6) {
      return 'Kurangi gerakan kepala yang tidak perlu. Duduk lebih tenang.';
    } else {
      return 'Latih postur di depan cermin. Duduk tegak dengan bahu rileks.';
    }
  }

  Future<void> _generateAiRecommendation() async {
    final totalLeftEye = detect.lookAwayLeftCount.value;
    final totalRightEye = detect.lookAwayRightCount.value;
    final totalDownEye = detect.lookDownCount.value;
    final totalEye = totalLeftEye + totalRightEye + totalDownEye;

    final totalSmile = detect.smileCount.value;
    final totalNeutral = detect.neutralCount.value;

    final totalLeftHead = detect.headTiltLeftCount.value;
    final totalRightHead = detect.headTiltRightCount.value;
    final totalDownHead = detect.headDownCount.value;
    final totalHead = totalLeftHead + totalRightHead + totalDownHead;

    final eyeLabelValue = detect.getEyeLevelLabel();
    final smileLabelValue = detect.getSmileLevelLabel();
    final postureLabelValue = detect.getPostureLevelLabel();

    final eyePoints = detect.getEyeContactPoints();
    final smilePoints = detect.getFacialExpressionPoints();
    final posturePoints = detect.getPosturePoints();
    final totalPoints = eyePoints + smilePoints + posturePoints;
    final maxPoints = 6;
    final hasZeroPoint =
        (eyePoints == 0 || smilePoints == 0 || posturePoints == 0);

    late String overallLabelValue;
    late String motivationMessage;

    if (totalPoints >= 5 && !hasZeroPoint) {
      overallLabelValue = 'Siap Wawancara';
      motivationMessage =
          'Selamat! Anda sudah siap menghadapi wawancara sesungguhnya.';
    } else if ((totalPoints >= 3 && !hasZeroPoint) || totalPoints >= 4) {
      overallLabelValue = 'Cukup Siap';
      motivationMessage = 'Anda cukup siap, terus latih kemampuan Anda!';
    } else {
      overallLabelValue = 'Butuh Banyak Latihan';
      motivationMessage =
          'Jangan berkecil hati! Latihan rutin akan membawa perubahan besar!';
    }

    eyeContactLabel.value = eyeLabelValue;
    smileLabel.value = smileLabelValue;
    postureLabel.value = postureLabelValue;
    overallLabel.value = overallLabelValue;
    confidenceMessage.value = motivationMessage;

    String getPointEmoji(int points) {
      if (points == 2) return '✅';
      if (points == 1) return '⚠️';
      return '❌';
    }

    final rincianPoin =
        '''
📊 RINCIAN POIN:
   • Kontak Mata : $eyePoints/2 ${getPointEmoji(eyePoints)} ($eyeLabelValue)
   • Ekspresi    : $smilePoints/2 ${getPointEmoji(smilePoints)} ($smileLabelValue)
   • Postur      : $posturePoints/2 ${getPointEmoji(posturePoints)} ($postureLabelValue)

💡 PENJELASAN POIN:
   - Poin 2 = ✅ Sangat baik, pertahankan!
   - Poin 1 = ⚠️ Cukup, masih bisa ditingkatkan
   - Poin 0 = ❌ Perlu banyak latihan lagi
''';

    final detailedPrompt =
        '''
HRD profesional. Analisis SINGKAT wawancara ini:

DATA:
Kontak Mata: $eyeLabelValue ($totalEye pelanggaran) - Poin: $eyePoints/2
Ekspresi: $smileLabelValue (senyum $totalSmile) - Poin: $smilePoints/2
Postur: $postureLabelValue ($totalHead gerakan) - Poin: $posturePoints/2
Verbal: ${wordsPerMinute.value} WPM, ${fillerCount.value} kata pengisi

HASIL STATUS: $overallLabelValue (Total Poin: $totalPoints/$maxPoints)

TUGAS ANDA:
1. Jelaskan dalam 1-2 kalimat MENGAPA kandidat mendapat status $overallLabelValue
2. Berikan 3 saran perbaikan terpenting (tanpa nomor, cukup strip -)

FORMAT JAWABAN:
KENAPA: [jelaskan penyebabnya]

SARAN:
- [saran 1]
- [saran 2]
- [saran 3]
''';

    final recommendation = await aiService
        .generateRecommendationWithDetailedPrompt(detailedPrompt);

    final cleanRecommendation = recommendation
        .replaceAll(RegExp(r'[*_\-]{3,}'), '')
        .replaceAll(RegExp(r'[*]{2,}'), '')
        .replaceAll('━', '')
        .replaceAll('─', '')
        .trim();

    final fullResult =
        '''
HASIL ANALISIS PERILAKU

1. KONTAK MATA
   Melirik ke kiri: $totalLeftEye kali
   Melirik ke kanan: $totalRightEye kali
   Menunduk: $totalDownEye kali
   Total pelanggaran: $totalEye kali
   Label: $eyeLabelValue
   Poin: $eyePoints/2

2. EKSPRESI WAJAH
   Tersenyum: $totalSmile kali
   Ekspresi datar: $totalNeutral kali
   Label: $smileLabelValue
   Poin: $smilePoints/2

3. POSTUR TUBUH
   Kepala miring kiri: $totalLeftHead kali
   Kepala miring kanan: $totalRightHead kali
   Kepala menunduk: $totalDownHead kali
   Total gerakan: $totalHead kali
   Label: $postureLabelValue
   Poin: $posturePoints/2

4. KOMUNIKASI VERBAL
   Kecepatan bicara: ${wordsPerMinute.value} WPM (Ideal: 120-160)
   Kata pengisi: ${fillerCount.value} kali (Max ideal: 2-3)
   Total kata diucapkan: ${totalWordsSpoken.value} kata

5. HASIL OVERALL
   Status: $overallLabelValue
   Total Poin: $totalPoints/$maxPoints
   $motivationMessage

$rincianPoin

REKOMENDASI AI:
$cleanRecommendation
''';

    aiRecommendation.value = fullResult;
  }

  String _getLevelString(PracticeLevel level) {
    switch (level) {
      case PracticeLevel.medium:
        return 'medium';
      case PracticeLevel.hard:
        return 'hard';
      case PracticeLevel.advance:
        return 'advance';
    }
  }

  Future<void> _startAnswerPhase() async {
    if (!isSessionRunning.value) return;
    isAnswering.value = true;
    secondsLeftInLine.value = _answerSecondsForLevel(selectedLevel.value);
    currentLineRecognized.value = '';

    if (_sttReady && sttEngine.isAvailable) await _restartStt();

    _answerTimer?.cancel();
    _answerTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!isSessionRunning.value || !isAnswering.value) {
        t.cancel();
        return;
      }
      if (secondsLeftInLine.value > 1) {
        secondsLeftInLine.value--;
        return;
      }

      secondsLeftInLine.value = 0;
      isAnswering.value = false;
      t.cancel();
      _commitLineTranscript();

      if (currentIndex.value < scriptLines.length - 1) {
        currentIndex.value++;
        currentLine.value = scriptLines[currentIndex.value];
        await speakHrdQuestion(currentLine.value);
      } else {
        await stopSession(goResult: true);
      }
    });
  }

  void _resetAll() {
    recognizedText.value = '';
    currentLineRecognized.value = '';
    sttConfidence.value = 0.0;
    qaHistory.clear();
    allRecognizedWords.clear();
    totalWordsSpoken.value = 0;
    totalFillersCount.value = 0;
    wordsPerMinute.value = 0;
    fillerCount.value = 0;
    secondsLeftInLine.value = _answerSecondsForLevel(selectedLevel.value);
    _sessionStart = null;
    _lastSpeechAt = null;
    _totalSpeakingSeconds = 0;
    isAsking.value = false;
    isAnswering.value = false;
    _silenceTimer?.cancel();
    _answerTimer?.cancel();
    aiRecommendation.value = '';
    detectionResult.value = null;
    _clearFaceWarning();

    eyeContactLabel.value = '';
    smileLabel.value = '';
    postureLabel.value = '';
    overallLabel.value = '';
    confidenceMessage.value = '';
  }

  void backToChoose() {
    print("DEBUG: backToChoose() dipanggil di controller");
    print("Current step: ${step.value}");
    print("isSessionRunning: ${isSessionRunning.value}");

    _countdownTimer?.cancel();
    _answerTimer?.cancel();
    _silenceTimer?.cancel();
    _sttRestartTimer?.cancel();
    _faceWarningTimer?.cancel();

    _stopTts();
    _stopSttHard();

    if (isSessionRunning.value) {
      isSessionRunning.value = false;
      detect.stop();
    }

    _resetAll();

    step.value = PracticeStep.instructions;

    print("Step setelah diubah: ${step.value}");
  }

  void _commitLineTranscript() {
    final lineText = currentLineRecognized.value.trim();

    // Hitung jumlah kata dari jawaban ini
    final wordCount = lineText.isEmpty
        ? 0
        : lineText
              .split(RegExp(r'\s+'))
              .where((w) => w.trim().isNotEmpty)
              .length;

    // Simpan Q&A ke history (termasuk jumlah kata)
    qaHistory.add({
      'q': currentLine.value,
      'a': lineText,
      'wordCount': wordCount.toString(), // Simpan jumlah kata per jawaban
    });

    // Gabungkan ke recognizedText
    final block = lineText.isEmpty
        ? 'Q: ${currentLine.value}\nA: (tidak ada jawaban)'
        : 'Q: ${currentLine.value}\nA: $lineText';

    recognizedText.value = recognizedText.value.isEmpty
        ? block
        : '${recognizedText.value}\n\n$block';

    // Reset untuk pertanyaan berikutnya
    currentLineRecognized.value = '';

    if (kDebugMode) {
      print('📝 Q&A #${qaHistory.length} disimpan: $wordCount kata');
    }
  }
}
