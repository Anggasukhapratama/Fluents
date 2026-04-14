import 'dart:async';
import 'dart:math';

import 'package:fluent_ai/app/models/practice_session_model.dart';
import 'package:fluent_ai/app/services/practice_firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import 'narasi_detect_controller.dart';

// 1. UPDATE ENUM: Tambahkan 'instructions'
enum PracticeStep { instructions, choose, countdown, practice, result }

enum PracticeLevel { medium, hard, advance }

class NarasiPracticeController extends GetxController {
  static const int sttRefreshGapMs = 450;

  final NarasiDetectController detect = Get.find<NarasiDetectController>();
  final PracticeFirestoreService fs = PracticeFirestoreService();

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

  // 2. UPDATE DEFAULT STEP: Jadikan instructions sebagai langkah awal
  final step = PracticeStep.instructions.obs;

  final RxList<String> scriptLines = <String>[].obs;
  final currentIndex = 0.obs;
  final currentLine = ''.obs;

  final countdown = 0.obs;
  Timer? _countdownTimer;

  final isSessionRunning = false.obs;
  final isAsking = false.obs;
  final isAnswering = false.obs;

  // ===== RIWAYAT Q & A =====
  final RxList<Map<String, String>> qaHistory = <Map<String, String>>[].obs;
  final recognizedText = ''.obs;
  final currentLineRecognized = ''.obs;
  final sttConfidence = 0.0.obs;

  final wordsPerMinute = 0.obs;
  final fillerCount = 0.obs;
  final fluencyScore = 0.0.obs;
  DateTime? _sessionStart;
  DateTime? _lastSpeechAt;
  Timer? _silenceTimer;

  Timer? _answerTimer;
  final secondsLeftInLine = 0.obs;

  final RxList<String> finalSuggestions = <String>[].obs;
  final totalConfidenceSession = 0.0.obs;
  final confidenceTotalLabel = 'Gelisah / Cemas'.obs;

  final Map<PracticeLevel, List<String>> hrdQuestions = {
    PracticeLevel.medium: [
      "Selamat pagi, perkenalkan diri Anda secara singkat.",
      "Apa yang membuat Anda tertarik melamar di perusahaan kami?",
      "Ceritakan tentang latar belakang pendidikan Anda.",
      "Apa yang Anda ketahui tentang posisi yang Anda lamar?",
      "Mengapa Anda memilih karir di bidang ini?",
    ],
    PracticeLevel.hard: [
      "Ceritakan tentang pengalaman kerja Anda yang paling menantang.",
      "Bagaimana cara Anda menghadapi konflik dalam tim?",
      "Apa pencapaian terbesar Anda di pekerjaan sebelumnya?",
      "Mengapa Anda meninggalkan pekerjaan sebelumnya?",
      "Bagaimana Anda menangani tekanan dan deadline ketat?",
    ],
    PracticeLevel.advance: [
      "Kami butuh seseorang yang bisa memimpin tim besar. Berikan contoh konkret.",
      "Bagaimana Anda menangani situasi di mana atasan Anda membuat keputusan salah?",
      "Dalam 5 tahun ke depan, di mana Anda melihat diri Anda?",
      "Apa kelemahan terbesar Anda? Berikan contoh nyata.",
      "Ceritakan tentang proyek yang gagal karena kesalahan Anda.",
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

    ever(sttIsListening, (listening) {
      if (!listening && isSessionRunning.value && isAnswering.value) {
        _scheduleSttRestart();
      }
    });

    ever(totalConfidenceSession, (_) => _syncConfidenceAlias());
    _syncConfidenceAlias();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _answerTimer?.cancel();
    _silenceTimer?.cancel();
    _sttRestartTimer?.cancel();
    _stopSttHard();
    _stopTts();
    super.onClose();
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

  void _syncConfidenceAlias() {
    final s = totalConfidenceSession.value;
    if (s >= 80) {
      confidenceTotalLabel.value = 'Sangat Meyakinkan & Profesional';
    } else if (s >= 60) {
      confidenceTotalLabel.value = 'Cukup Siap (Perlu Peningkatan)';
    } else if (s >= 40) {
      confidenceTotalLabel.value = 'Kurang Percaya Diri / Ragu';
    } else {
      confidenceTotalLabel.value = 'Gelisah / Tidak Fokus';
    }
  }

  // 3. FUNGSI BARU: Pindah dari Instruksi ke Pilih Level
  void startToChoose() {
    step.value = PracticeStep.choose;
  }

  void pickMedium() {
    selectedLevel.value = PracticeLevel.medium;
    _buildScriptFromLevel();
    startCountdown();
  }

  void pickHard() {
    selectedLevel.value = PracticeLevel.hard;
    _buildScriptFromLevel();
    startCountdown();
  }

  void pickAdvance() {
    selectedLevel.value = PracticeLevel.advance;
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
        : (level == PracticeLevel.hard ? 6 : 7);
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
        Get.snackbar('Izin', 'Aktifkan mic');
        step.value = PracticeStep.choose;
        return;
      }
      if (!_sttReady) await _initStt();

      _resetAll();
      finalSuggestions.clear();
      detect.resetAverages(); // Reset kalkulasi rata-rata frame
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

  Future<void> stopSession({required bool goResult}) async {
    isSessionRunning.value = false;
    isAsking.value = false;
    isAnswering.value = false;

    await _stopTts();
    _answerTimer?.cancel();
    _silenceTimer?.cancel();
    _sttRestartTimer?.cancel();
    await detect.stop();
    await _stopSttHard();

    _commitLineTranscript();
    _finalizeWpm();
    _finalizeFluency();
    _finalizeTotalConfidenceSession();

    if (goResult) {
      final tips = buildSuggestions();
      finalSuggestions.assignAll(tips);
      await _saveSessionToFirebase(tips);
      step.value = PracticeStep.result;
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
        fluencyScore.value = (fluencyScore.value - 6).clamp(0.0, 100.0);
      }
    });
  }

  void _commitLineTranscript() {
    final lineText = currentLineRecognized.value.trim();
    if (lineText.isEmpty) return;

    qaHistory.add({'q': currentLine.value, 'a': lineText});

    final block = 'Q: ${currentLine.value}\nA: $lineText';
    recognizedText.value = recognizedText.value.isEmpty
        ? block
        : '${recognizedText.value}\n\n$block';
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
      'anu',
      'em',
      'hmm',
      'eee',
      'ooo',
    };
    fillerCount.value = spoken
        .toLowerCase()
        .split(' ')
        .where((w) => filler.contains(w.trim()))
        .length;

    final base = 100.0 - (fillerCount.value * 6.0);
    double wpmPenalty = wordsPerMinute.value > 190
        ? 15
        : (wordsPerMinute.value > 0 && wordsPerMinute.value < 90 ? 12 : 0);
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

  void _finalizeTotalConfidenceSession() {
    // Gunakan nilai final rata-rata untuk keseluruhan sesi
    totalConfidenceSession.value = detect.finalAvgOverall.toDouble();
    _syncConfidenceAlias();
  }

  List<String> buildSuggestions() {
    final tips = <String>[];

    // Gunakan Average untuk evaluasi akhir (bukan detik terakhir saja)
    if (detect.finalAvgEye < 70) {
      tips.add(
        '👀 Secara keseluruhan Anda sering mengalihkan pandangan. Usahakan fokus menatap kamera.',
      );
    }
    if (detect.finalAvgPosture < 60) {
      tips.add(
        '🧍 Postur tubuh rata-rata kurang tegak/membungkuk. Biasakan duduk simetris.',
      );
    }
    if (detect.finalAvgSmile < 40) {
      tips.add(
        '😊 Ekspresi cenderung kaku selama wawancara. Berikan senyum agar memancarkan aura positif.',
      );
    }

    if (wordsPerMinute.value > 180) {
      tips.add('⚡ Bicara terlalu cepat. Targetkan 120-160 kata/menit.');
    } else if (wordsPerMinute.value > 0 && wordsPerMinute.value < 95) {
      tips.add('🐌 Bicara terlalu pelan. Tingkatkan tempo.');
    }
    if (fillerCount.value >= 4) {
      tips.add(
        '🗣️ Kurangi kata pengisi (umm/anu/eee) agar terdengar lebih profesional.',
      );
    }

    if (tips.isEmpty) {
      tips.add('🎉 Luar biasa! Performa Anda sangat stabil dan profesional!');
    }
    return tips;
  }

  Future<void> _saveSessionToFirebase(List<String> tips) async {
    final now = DateTime.now();
    final levelNames = {
      PracticeLevel.medium: 'medium',
      PracticeLevel.hard: 'hard',
      PracticeLevel.advance: 'advance',
    };

    final session = PracticeSession(
      createdAt: now,
      dateKey: DateFormat('yyyy-MM-dd').format(now),
      monthKey: DateFormat('yyyy-MM').format(now),
      difficulty: levelNames[selectedLevel.value] ?? 'medium',
      scriptLineCount: scriptLines.length,
      wpm: wordsPerMinute.value,
      fluency: fluencyScore.value,
      fillerCount: fillerCount.value,

      // Simpan nilai rata-rata keseluruhan (Average) ke Cloud
      scoreSmile: detect.finalAvgSmile,
      scoreEye: detect.finalAvgEye,
      scorePosture: detect.finalAvgPosture,
      overallConfidence: detect.finalAvgOverall,
      overallLabel: confidenceTotalLabel.value,

      recognizedText: recognizedText.value,
      suggestions: tips,
    );

    try {
      await fs.saveSession(session);
      Get.snackbar(
        '✨ Latihan Selesai!',
        'Hasil tersimpan',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Peringatan', 'Gagal menyimpan ke cloud: $e');
    }
  }

  void _resetAll() {
    recognizedText.value = '';
    currentLineRecognized.value = '';
    sttConfidence.value = 0.0;
    qaHistory.clear();
    wordsPerMinute.value = 0;
    fillerCount.value = 0;
    fluencyScore.value = 0.0;
    totalConfidenceSession.value = 0.0;
    secondsLeftInLine.value = _answerSecondsForLevel(selectedLevel.value);
    _sessionStart = null;
    _lastSpeechAt = null;
    isAsking.value = false;
    isAnswering.value = false;
    _silenceTimer?.cancel();
    _answerTimer?.cancel();
  }

  void backToChoose() {
    stopSession(goResult: false);
    step.value = PracticeStep.choose;
  }
}
