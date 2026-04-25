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

// ===== ENUM STEP =====
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

  // ===== AI SUMMARY & DETECTION RESULT =====
  final aiSummary = ''.obs;
  final detectionResult = Rxn<DetectionResultModel>();

  final Map<PracticeLevel, List<String>> hrdQuestions = {
    PracticeLevel.medium: [
      "Selamat pagi, perkenalkan diri Anda secara singkat.",
      "Apa yang membuat Anda tertarik melamar di perusahaan kami?",
      "Ceritakan tentang latar belakang pendidikan Anda.",
      "Apa yang Anda ketahui tentang posisi yang Anda lamar?",
      "Mengapa Anda memilih karir di bidang ini?",
      "Apa kelebihan utama Anda yang paling relevan dan bisa berkontribusi untuk posisi ini?",
      "Bagaimana cara Anda memprioritaskan pekerjaan ketika memiliki beberapa tugas dengan tenggat waktu (deadline) yang bersamaan?",
      "Lingkungan kerja atau budaya perusahaan seperti apa yang membuat Anda bisa bekerja paling produktif?",
      "Apa yang biasanya Anda harapkan dari seorang manajer atau atasan dalam mendukung pekerjaan Anda?",
      "Ceritakan alat, tools, atau metode apa yang biasa Anda gunakan untuk menjaga agar pekerjaan Anda tetap terorganisir.",
    ],
    PracticeLevel.hard: [
      "Ceritakan tentang pengalaman kerja Anda yang paling menantang.",
      "Bagaimana cara Anda menghadapi konflik dalam tim?",
      "Apa pencapaian terbesar Anda di pekerjaan sebelumnya?",
      "Mengapa Anda meninggalkan pekerjaan sebelumnya?",
      "Bagaimana Anda menangani tekanan dan tenggat waktu (deadline) yang ketat?",
      "Ceritakan momen ketika Anda harus beradaptasi dengan perubahan besar di tempat kerja secara tiba-tiba. Bagaimana respons Anda?",
      "Pernahkah Anda harus bekerja sama dengan rekan kerja yang sulit atau memiliki gaya komunikasi yang bertolak belakang dengan Anda? Bagaimana cara Anda mengatasinya?",
      "Ceritakan pengalaman Anda saat harus mengambil keputusan yang cepat namun informasi yang Anda miliki saat itu sangat terbatas.",
      "Bagaimana cara Anda tetap memotivasi diri sendiri saat harus mengerjakan tugas yang repetitif atau mungkin membosankan bagi Anda?",
      "Berikan contoh ketika Anda menerima kritik atau umpan balik (feedback) yang tajam dari atasan atau klien. Bagaimana Anda memproses dan menindaklanjutinya?",
    ],
    PracticeLevel.advance: [
      "Kami butuh seseorang yang bisa memimpin tim besar. Berikan contoh konkret nya.",
      "Bagaimana Anda menangani situasi di mana atasan Anda membuat keputusan salah?",
      "Dalam 5 tahun ke depan, di mana Anda melihat diri Anda?",
      "Apa kelemahan terbesar Anda? Berikan contoh nyata.",
      "Ceritakan tentang proyek yang gagal karena kesalahan Anda.",
      "Ceritakan pengalaman Anda saat harus meyakinkan pemangku kepentingan (stakeholders) atau manajemen atas yang awalnya sangat menentang ide atau proposal Anda.",
      "Jika Anda diterima, apa strategi, rencana, atau perubahan konkret yang akan Anda terapkan dalam 90 hari pertama kerja Anda?",
      "Pernahkah Anda dihadapkan pada dilema etika profesional di tempat kerja? Langkah apa yang Anda ambil untuk menyelesaikannya?",
      "Ceritakan sebuah inovasi, proses baru, atau efisiensi yang Anda inisiasi sendiri. Bagaimana proses eksekusinya dan apa dampak terukurnya bagi perusahaan?",
      "Bagaimana cara Anda memastikan bahwa tim yang Anda pimpin tidak hanya mencapai target, tetapi juga tetap sejalan dengan visi dan nilai strategis perusahaan dalam jangka panjang?",
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

  // ===== TTS INIT =====
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

  // ===== NAVIGASI =====
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

  // ===== STT =====
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

  // ===== SESSION CONTROL =====
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
      detect.resetAllCounters(); // Ganti resetDiscreteCounters & resetAverages
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

    await _generateAiSummary();

    if (goResult) {
      final tips = buildSuggestions();
      finalSuggestions.assignAll(tips);
      await _saveSessionToFirebase(tips);
      step.value = PracticeStep.result;
    }
  }

  Future<void> _generateAiSummary() async {
    // Ambil nilai dari RxInt menggunakan .value
    final summary = await aiService.generateSummary(
      lookAwayCount: detect.lookAwayCount.value,
      lookDownCount: detect.lookDownCount.value,
      smileCount: detect.smileCount.value,
      neutralCount: detect.neutralCount.value,
      headTiltLeftCount: detect.headTiltLeftCount.value,
      headTiltRightCount: detect.headTiltRightCount.value,
      headDownCount: detect.headDownCount.value,
      level: selectedLevel.value.toString().split('.').last,
      wpm: wordsPerMinute.value,
      fillerCount: fillerCount.value,
    );
    aiSummary.value = summary;

    detectionResult.value = DetectionResultModel(
      eyeContact: EyeContactResult(
        lookAwayCount: detect.lookAwayCount.value,
        lookDownCount: detect.lookDownCount.value,
        conclusion: aiService.getEyeContactConclusion(
          detect.lookAwayCount.value,
          detect.lookDownCount.value,
        ),
        suggestion: aiService.getEyeContactSuggestion(
          detect.lookAwayCount.value,
          detect.lookDownCount.value,
        ),
      ),
      facialExpression: FacialExpressionResult(
        smileCount: detect.smileCount.value,
        neutralCount: detect.neutralCount.value,
        conclusion: aiService.getFacialConclusion(
          detect.smileCount.value,
          detect.neutralCount.value,
        ),
        suggestion: aiService.getFacialSuggestion(
          detect.smileCount.value,
          detect.neutralCount.value,
        ),
      ),
      headPosture: HeadPostureResult(
        headTiltLeftCount: detect.headTiltLeftCount.value,
        headTiltRightCount: detect.headTiltRightCount.value,
        headDownCount: detect.headDownCount.value,
        conclusion: aiService.getHeadPostureConclusion(
          detect.headTiltLeftCount.value,
          detect.headTiltRightCount.value,
          detect.headDownCount.value,
        ),
        suggestion: aiService.getHeadPostureSuggestion(
          detect.headTiltLeftCount.value,
          detect.headTiltRightCount.value,
          detect.headDownCount.value,
        ),
      ),
      timestamp: DateTime.now(),
      aiSummary: summary,
    );
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
      'mm',
      'hh',
      'aah',
      'ooh',
      'ehh',
      'uhh',
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

  List<String> buildSuggestions() {
    final tips = <String>[];

    // Gunakan counter pelanggaran sebagai dasar saran
    if (detect.totalEyeViolations > 3) {
      tips.add(
        '👀 Anda sering mengalihkan pandangan atau menunduk. Usahakan fokus menatap kamera.',
      );
    } else if (detect.totalEyeViolations > 1) {
      tips.add(
        '👀 Kontak mata perlu ditingkatkan. Hindari melihat ke samping atau menunduk.',
      );
    }

    if (detect.totalHeadViolations > 3) {
      tips.add(
        '🧍 Postur tubuh kurang tegak. Duduklah dengan posisi bahu sejajar dan kepala tegak.',
      );
    } else if (detect.totalHeadViolations > 1) {
      tips.add(
        '🧍 Perhatikan postur tubuh Anda. Kurangi kebiasaan memiringkan kepala.',
      );
    }

    if (detect.neutralCount.value > detect.smileCount.value &&
        detect.neutralCount.value > 3) {
      tips.add(
        '😊 Ekspresi cenderung datar. Berikan senyum agar memancarkan aura positif.',
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

    // Hitung skor sederhana dari frekuensi pelanggaran (opsional untuk kompatibilitas)
    final maxViolations = 10;
    final eyeScore =
        ((maxViolations - detect.totalEyeViolations).clamp(0, maxViolations) /
                maxViolations *
                100)
            .round();
    final postureScore =
        ((maxViolations - detect.totalHeadViolations).clamp(0, maxViolations) /
                maxViolations *
                100)
            .round();
    final smileScoreValue =
        (detect.smileCount.value /
                (detect.smileCount.value + detect.neutralCount.value + 1) *
                100)
            .round();
    final overallScore = ((eyeScore + postureScore + smileScoreValue) / 3)
        .round();

    final session = PracticeSession(
      createdAt: now,
      dateKey: DateFormat('yyyy-MM-dd').format(now),
      monthKey: DateFormat('yyyy-MM').format(now),
      difficulty: levelNames[selectedLevel.value] ?? 'medium',
      scriptLineCount: scriptLines.length,
      wpm: wordsPerMinute.value,
      fluency: fluencyScore.value,
      fillerCount: fillerCount.value,
      scoreSmile: smileScoreValue,
      scoreEye: eyeScore,
      scorePosture: postureScore,
      overallConfidence: overallScore,
      overallLabel: overallScore >= 70
          ? 'Baik'
          : (overallScore >= 40 ? 'Cukup' : 'Perlu Perbaikan'),
      recognizedText: recognizedText.value,
      suggestions: tips,
      detectionResult: detectionResult.value,
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
    secondsLeftInLine.value = _answerSecondsForLevel(selectedLevel.value);
    _sessionStart = null;
    _lastSpeechAt = null;
    isAsking.value = false;
    isAnswering.value = false;
    _silenceTimer?.cancel();
    _answerTimer?.cancel();
    aiSummary.value = '';
    detectionResult.value = null;
  }

  void backToChoose() {
    stopSession(goResult: false);
    step.value = PracticeStep.choose;
  }
}
