// lib/app/controllers/narasi_practice_controller.dart
import 'dart:async';
import 'dart:math';

import 'package:fluent_ai/app/models/detection_result_model.dart';
import 'package:fluent_ai/app/models/narasi_question_model.dart';
import 'package:fluent_ai/app/models/practice_session_model.dart';
import 'package:fluent_ai/app/services/ai_feedback_service.dart';
import 'package:fluent_ai/app/services/ai_question_service.dart';
import 'package:fluent_ai/app/services/practice_firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import 'narasi_detect_controller.dart';

// ===== STEP FLOW =====
enum PracticeStep {
  instructions,
  jobInput,
  choose,
  countdown,
  practice,
  result,
}

enum PracticeLevel { medium, hard, advance }

class NarasiPracticeController extends GetxController {
  static const int sttRefreshGapMs = 450;

  final NarasiDetectController detect = Get.find<NarasiDetectController>();
  final PracticeFirestoreService fs = PracticeFirestoreService();
  final AiFeedbackService aiService = AiFeedbackService();
  final AiQuestionService aiQuestionService = AiQuestionService();

  late final FlutterTts flutterTts;
  final isTtsSpeaking = false.obs;
  final soundEnabled = true.obs;

  // ===== JOB TARGET =====
  final jobTarget = ''.obs;
  final TextEditingController jobTargetCtrl = TextEditingController();

  final selectedLevel = PracticeLevel.medium.obs;

  final stt.SpeechToText sttEngine = stt.SpeechToText();
  bool _sttReady = false;
  final sttStatusText = ''.obs;
  final sttIsListening = false.obs;

  Timer? _sttRestartTimer;
  bool _isSttRestarting = false;
  DateTime? _lastSttRestart;

  String _savedTranscriptForCurrentAnswer = '';

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

  final RxList<NarasiAnswerWithCorrection> answersWithCorrections =
      <NarasiAnswerWithCorrection>[].obs;
  final isGeneratingCorrections = false.obs;

  // ========== WPM & FILLER ==========
  final wordsPerMinute = 0.obs;
  final fillerCount = 0.obs;
  final totalWordsSpoken = 0.obs;
  final totalFillersCount = 0.obs;
  final RxList<String> allRecognizedWords = <String>[].obs;

  final RxList<int> perQuestionWpm = <int>[].obs;
  final RxList<int> perQuestionSpeakingSeconds = <int>[].obs;
  final RxList<int> perQuestionWordCount = <int>[].obs;

  Stopwatch? _speakingStopwatch;
  bool _isSpeakingNow = false;

  int _currentAnswerSpeakingSeconds = 0;
  int _currentAnswerWordCount = 0;

  DateTime? _sessionStart;
  DateTime? _firstSpeechAt;
  DateTime? _lastSpeechAt;
  Timer? _silenceTimer;
  int _totalSpeakingSeconds = 0;

  Timer? _answerTimer;
  final secondsLeftInLine = 0.obs;

  final RxList<String> finalSuggestions = <String>[].obs;

  final aiRecommendation = ''.obs;
  final detectionResult = Rxn<DetectionResultModel>();

  // ===== LABEL SESUAI HRD =====
  final eyeContactLabel = ''.obs;
  final smileLabel = ''.obs;
  final postureLabel = ''.obs;

  final isFaceWarning = false.obs;
  final faceWarningMessage = ''.obs;
  Timer? _faceWarningTimer;

  final isAiProcessing = false.obs;
  final aiProcessingMessage = 'Sedang menganalisis hasil...'.obs;

  bool _isSessionSaved = false;

  // ============================================================
  // DURASI: 5 MENIT TOTAL, 1 PERTANYAAN = 60 DETIK
  // ============================================================
  int _questionCountForLevel(PracticeLevel level) {
    return 5; // SEMUA LEVEL = 5 PERTANYAAN
  }

  int _answerSecondsForLevel(PracticeLevel level) {
    return 60; // SEMUA LEVEL = 60 DETIK PER PERTANYAAN
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  int _calculateWpm(int wordCount, int speakingSeconds) {
    if (speakingSeconds <= 0 || wordCount <= 0) return 0;
    final wpm = (wordCount / speakingSeconds) * 60;
    return wpm.round().clamp(40, 250);
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  int _countFillers(String text) {
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

    final words = text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);
    int count = 0;
    for (final word in words) {
      final clean = word.replaceAll(RegExp(r'[^\w]'), '');
      if (fillerWords.contains(clean)) count++;
    }
    return count;
  }

  void _stopSpeakingTimer() {
    if (_isSpeakingNow && _speakingStopwatch != null) {
      _speakingStopwatch?.stop();
      if (_firstSpeechAt != null && _lastSpeechAt != null) {
        final elapsed = _lastSpeechAt!.difference(_firstSpeechAt!).inSeconds;
        _currentAnswerSpeakingSeconds = elapsed > 0 ? elapsed : 1;
      } else {
        _currentAnswerSpeakingSeconds = _speakingStopwatch!.elapsed.inSeconds;
      }
      _isSpeakingNow = false;
      if (kDebugMode) {
        print(
          '⏹️ Speaking timer stopped: ${_currentAnswerSpeakingSeconds}s for current answer',
        );
      }
    }
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

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
    jobTargetCtrl.dispose();
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

  // ============================================================
  // TTS
  // ============================================================

  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("id-ID");

    try {
      final voices = await flutterTts.getVoices;
      bool voiceSet = false;
      if (voices != null) {
        for (var voice in voices) {
          if (voice["locale"] == "id-ID" &&
              voice["name"].toString().contains("network")) {
            await flutterTts.setVoice({
              "name": voice["name"],
              "locale": voice["locale"],
            });
            voiceSet = true;
            break;
          }
        }
      }
      if (!voiceSet) {
        await flutterTts.setVoice({
          "name": "id-id-x-dfz-network",
          "locale": "id-ID",
        });
      }
    } catch (_) {}

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

  // ============================================================
  // FLOW
  // ============================================================

  void startToInstructions() {
    step.value = PracticeStep.instructions;
  }

  void nextToJobInput() {
    step.value = PracticeStep.jobInput;
  }

  Future<void> submitJobTarget() async {
    final target = jobTargetCtrl.text.trim();
    if (target.isEmpty) {
      Get.snackbar('Oops', 'Isi dulu jenis pekerjaan yang Anda lamar');
      return;
    }
    jobTarget.value = target;
    step.value = PracticeStep.choose;
  }

  void backToJobInput() {
    step.value = PracticeStep.jobInput;
  }

  void startToChoose() {
    step.value = PracticeStep.choose;
  }

  // ===== PILIH LEVEL =====
  Future<void> pickMedium() async {
    if (isAiProcessing.value ||
        isSessionRunning.value ||
        step.value == PracticeStep.countdown)
      return;
    selectedLevel.value = PracticeLevel.medium;
    detect.setLevel('medium');
    await _buildScriptFromAI();
    startCountdown();
  }

  Future<void> pickHard() async {
    if (isAiProcessing.value ||
        isSessionRunning.value ||
        step.value == PracticeStep.countdown)
      return;
    selectedLevel.value = PracticeLevel.hard;
    detect.setLevel('hard');
    await _buildScriptFromAI();
    startCountdown();
  }

  Future<void> pickAdvance() async {
    if (isAiProcessing.value ||
        isSessionRunning.value ||
        step.value == PracticeStep.countdown)
      return;
    selectedLevel.value = PracticeLevel.advance;
    detect.setLevel('advance');
    await _buildScriptFromAI();
    startCountdown();
  }

  // ===== GENERATE PERTANYAAN DARI AI =====
  Future<void> _buildScriptFromAI() async {
    final level = selectedLevel.value;
    final questionCount = _questionCountForLevel(level);
    final target = jobTarget.value;

    if (target.isEmpty) {
      Get.snackbar('Error', 'Job target tidak boleh kosong');
      step.value = PracticeStep.jobInput;
      return;
    }

    isAiProcessing.value = true;
    aiProcessingMessage.value =
        'AI sedang menyusun $questionCount pertanyaan wawancara...';

    try {
      final questions = await aiQuestionService.generateQuestions(
        jobTarget: target,
        level: _getLevelString(level),
        questionCount: questionCount,
      );

      if (questions.length != questionCount) {
        print(
          '⚠️ AI menghasilkan ${questions.length} pertanyaan, diharapkan $questionCount',
        );
        _buildFallbackQuestions();
        return;
      }

      final validQuestions = questions
          .where((q) => q.trim().isNotEmpty && q.length > 10 && q.contains('?'))
          .toList();

      if (validQuestions.length != questionCount) {
        print('⚠️ Beberapa pertanyaan tidak valid, gunakan fallback');
        _buildFallbackQuestions();
        return;
      }

      scriptLines.assignAll(validQuestions);
      currentIndex.value = 0;
      currentLine.value = scriptLines.isNotEmpty ? scriptLines.first : '';

      _resetAll();
      answersWithCorrections.clear();

      print('✅ Berhasil generate $questionCount pertanyaan berkualitas');
    } catch (e) {
      print('❌ Gagal generate pertanyaan: $e');
      Get.snackbar(
        'Error',
        'Gagal generate pertanyaan, gunakan pertanyaan default',
      );
      _buildFallbackQuestions();
    } finally {
      isAiProcessing.value = false;
      aiProcessingMessage.value = '';
    }
  }

  void _buildFallbackQuestions() {
    final level = selectedLevel.value;
    final count = _questionCountForLevel(level);
    final target = jobTarget.value.isEmpty ? 'posisi ini' : jobTarget.value;

    final fallbacks = [
      'Ceritakan tentang diri Anda secara singkat.',
      'Apa yang membuat Anda tertarik dengan $target?',
      'Apa keahlian utama Anda yang relevan dengan $target?',
      'Bagaimana cara Anda mengatasi tekanan dalam pekerjaan?',
      'Apa pencapaian terbesar Anda sejauh ini?',
    ];

    final selectedQuestions = fallbacks.take(count).toList();

    while (selectedQuestions.length < count) {
      selectedQuestions.add(
        'Ceritakan pengalaman Anda yang relevan dengan $target.',
      );
    }

    scriptLines.assignAll(selectedQuestions);
    currentIndex.value = 0;
    currentLine.value = scriptLines.isNotEmpty ? scriptLines.first : '';
    _resetAll();

    print('✅ Fallback questions loaded: ${scriptLines.length} pertanyaan');
  }

  // ============================================================
  // STT
  // ============================================================

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
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 8),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
        onResult: (result) {
          final text = result.recognizedWords.trim();
          if (text.isNotEmpty) {
            _lastSpeechAt = DateTime.now();
            sttConfidence.value = result.confidence;

            if (_savedTranscriptForCurrentAnswer.isNotEmpty) {
              currentLineRecognized.value =
                  '$_savedTranscriptForCurrentAnswer $text';
            } else {
              currentLineRecognized.value = text;
            }
            _updateRealtimeSpeech(currentLineRecognized.value);
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
    _sttRestartTimer = Timer(const Duration(milliseconds: 500), () {
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
        now.difference(_lastSttRestart!) < const Duration(seconds: 1)) {
      return;
    }

    _isSttRestarting = true;
    _lastSttRestart = now;
    try {
      final currentText = currentLineRecognized.value.trim();
      if (currentText.isNotEmpty) {
        _savedTranscriptForCurrentAnswer = currentText;
      }

      if (sttEngine.isListening) await sttEngine.stop();
      await Future.delayed(const Duration(milliseconds: 300));
      await _startListeningOnce();
    } finally {
      _isSttRestarting = false;
    }
  }

  // ============================================================
  // SESSION FLOW
  // ============================================================

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

  void _updateRealtimeSpeech(String spoken) {
    if (spoken.trim().isEmpty) return;

    if (!_isSpeakingNow) {
      _isSpeakingNow = true;
      _firstSpeechAt = DateTime.now();
      _speakingStopwatch = Stopwatch()..start();
    }

    currentLineRecognized.value = spoken;
    _lastSpeechAt = DateTime.now();

    if (_firstSpeechAt != null) {
      final elapsed = _lastSpeechAt!.difference(_firstSpeechAt!).inSeconds;
      _currentAnswerSpeakingSeconds = elapsed > 0 ? elapsed : 1;
    }

    final currentWords = _countWords(spoken);
    _currentAnswerWordCount = currentWords;

    int totalWordsFromHistory = 0;
    for (final item in qaHistory) {
      totalWordsFromHistory += _countWords(item['a'] ?? '');
    }
    totalWordsSpoken.value = totalWordsFromHistory + _currentAnswerWordCount;

    final currentFillers = _countFillers(spoken);
    int totalFillers = 0;
    for (final item in qaHistory) {
      totalFillers += _countFillers(item['a'] ?? '');
    }
    fillerCount.value = totalFillers + currentFillers;
    totalFillersCount.value = fillerCount.value;

    if (_currentAnswerSpeakingSeconds > 0 && _currentAnswerWordCount > 0) {
      final currentWpm =
          (_currentAnswerWordCount / _currentAnswerSpeakingSeconds) * 60;
      wordsPerMinute.value = currentWpm.round().clamp(40, 250);
    }

    if (kDebugMode) {
      print(
        '🔊 Speaking: ${_currentAnswerWordCount} kata | ${_currentAnswerSpeakingSeconds}s | WPM: ${wordsPerMinute.value}',
      );
    }
  }

  void _finalizeWpm() {
    if (perQuestionWpm.isEmpty) {
      wordsPerMinute.value = 0;
      return;
    }

    final totalWpm = perQuestionWpm.fold(0, (sum, wpm) => sum + wpm);
    final avgWpm = (totalWpm / perQuestionWpm.length).round();
    wordsPerMinute.value = avgWpm.clamp(0, 200);

    final totalWords = perQuestionWordCount.fold(0, (sum, wc) => sum + wc);
    totalWordsSpoken.value = totalWords;
    _finalizeFillers();

    if (kDebugMode) {
      print('📊 FINAL WPM STATS: ${wordsPerMinute.value}');
    }
  }

  void _finalizeFillers() {
    int totalFillers = 0;
    for (final item in qaHistory) {
      totalFillers += _countFillers(item['a'] ?? '');
    }
    fillerCount.value = totalFillers;
    totalFillersCount.value = totalFillers;
  }

  void _startSilenceMonitor() {}

  // ============================================================
  // ANSWER PHASE
  // ============================================================

  Future<void> _startAnswerPhase() async {
    if (!isSessionRunning.value) return;
    isAnswering.value = true;
    secondsLeftInLine.value = _answerSecondsForLevel(selectedLevel.value);
    currentLineRecognized.value = '';

    _currentAnswerSpeakingSeconds = 0;
    _currentAnswerWordCount = 0;
    _isSpeakingNow = false;
    _firstSpeechAt = null;
    _speakingStopwatch = null;

    _savedTranscriptForCurrentAnswer = '';

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

      _stopSpeakingTimer();
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

  // ============================================================
  // COMMIT TRANSCRIPT
  // ============================================================

  void _commitLineTranscript() {
    final lineText = currentLineRecognized.value.trim();
    final currentQ = currentLine.value;

    final alreadyCommitted = qaHistory.any((item) => item['q'] == currentQ);
    if (alreadyCommitted) {
      print(
        '⚠️ Pertanyaan "$currentQ" sudah di-commit sebelumnya, skip duplikasi',
      );
      return;
    }

    _stopSpeakingTimer();

    final finalWordCount = _countWords(lineText);
    final finalSpeakingSeconds = _currentAnswerSpeakingSeconds;
    final finalWpm = _calculateWpm(finalWordCount, finalSpeakingSeconds);
    final finalFillers = _countFillers(lineText);

    perQuestionWordCount.add(finalWordCount);
    perQuestionSpeakingSeconds.add(finalSpeakingSeconds);
    perQuestionWpm.add(finalWpm);

    qaHistory.add({
      'q': currentQ,
      'a': lineText,
      'wordCount': finalWordCount.toString(),
      'speakingSeconds': finalSpeakingSeconds.toString(),
      'wpm': finalWpm.toString(),
      'fillers': finalFillers.toString(),
    });

    if (kDebugMode) {
      print(
        '📝 Q&A #${qaHistory.length} - Words: $finalWordCount, Speaking: ${finalSpeakingSeconds}s, WPM: $finalWpm',
      );
    }

    final block = lineText.isEmpty
        ? 'Q: $currentQ\nA: (tidak ada jawaban)'
        : 'Q: $currentQ\nA: $lineText';
    recognizedText.value = recognizedText.value.isEmpty
        ? block
        : '${recognizedText.value}\n\n$block';

    currentLineRecognized.value = '';
    _currentAnswerWordCount = 0;
    _currentAnswerSpeakingSeconds = 0;
    _speakingStopwatch = null;
    _isSpeakingNow = false;
    _savedTranscriptForCurrentAnswer = '';
  }

  // ============================================================
  // SKIP PERTANYAAN
  // ============================================================

  void skipCurrentQuestion() {
    if (!isSessionRunning.value || !isAnswering.value) return;

    // Commit transcript jika ada
    if (currentLineRecognized.value.trim().isNotEmpty) {
      _commitLineTranscript();
    }

    // Hentikan timer jawaban
    _answerTimer?.cancel();
    isAnswering.value = false;
    secondsLeftInLine.value = 0;

    // Lanjut ke pertanyaan berikutnya
    if (currentIndex.value < scriptLines.length - 1) {
      currentIndex.value++;
      currentLine.value = scriptLines[currentIndex.value];
      speakHrdQuestion(currentLine.value);
    } else {
      stopSession(goResult: true);
    }
  }

  // ============================================================
  // STOP SESSION & GENERATE ANALISIS
  // ============================================================

  Future<void> stopSession({required bool goResult}) async {
    if (!isSessionRunning.value) return;

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

    if (isAnswering.value && currentLineRecognized.value.trim().isNotEmpty) {
      _commitLineTranscript();
    }

    _finalizeWpm();
    _finalizeFillers();

    if (goResult) {
      step.value = PracticeStep.result;
      isAiProcessing.value = true;
      aiProcessingMessage.value =
          '⏳ AI sedang menganalisis hasil latihan Anda...';
    }

    // Generate koreksi AI
    await _generateAllCorrections();

    // Generate analisis deskriptif (TANPA OVERALL)
    await _generateDescriptiveAnalysis();

    if (goResult && !_isSessionSaved) {
      await _saveSessionToFirestore();
      _isSessionSaved = true;
    }

    if (goResult) {
      isAiProcessing.value = false;
      aiProcessingMessage.value = '';
    }
  }

  // ============================================================
  // GENERATE KOREKSI AI
  // ============================================================

  Future<void> _generateAllCorrections() async {
    if (qaHistory.isEmpty) return;

    isGeneratingCorrections.value = true;
    answersWithCorrections.clear();

    final target = jobTarget.value;
    final totalQuestions = qaHistory.length;

    aiProcessingMessage.value =
        '⏳ Menyiapkan koreksi AI untuk $totalQuestions pertanyaan...';

    final List<Future<NarasiAnswerWithCorrection?>> futures = [];

    for (int i = 0; i < totalQuestions; i++) {
      final item = qaHistory[i];
      final question = item['q'] ?? '';
      final answer = item['a'] ?? '';
      final index = i;

      final future = _generateSingleCorrectionWithTimeout(
        question: question,
        answer: answer,
        jobTarget: target,
        index: index,
        total: totalQuestions,
      );
      futures.add(future);

      await Future.delayed(const Duration(milliseconds: 500));
    }

    final results = await Future.wait(futures, eagerError: false);

    final successfulResults = results
        .whereType<NarasiAnswerWithCorrection>()
        .toList();
    successfulResults.sort((a, b) => a.question.compareTo(b.question));

    answersWithCorrections.assignAll(successfulResults);

    print(
      '📊 Koreksi selesai: ${successfulResults.length} berhasil dari $totalQuestions',
    );

    isGeneratingCorrections.value = false;
    aiProcessingMessage.value = '';
  }

  Future<NarasiAnswerWithCorrection?> _generateSingleCorrectionWithTimeout({
    required String question,
    required String answer,
    required String jobTarget,
    required int index,
    required int total,
  }) async {
    aiProcessingMessage.value = '⏳ Menganalisis jawaban ${index + 1}/$total...';

    try {
      final correction =
          await Future.wait([
            aiQuestionService.correctAnswer(
              question: question,
              userAnswer: answer,
              jobTarget: jobTarget,
            ),
          ]).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⚠️ Timeout untuk pertanyaan #${index + 1}');
              throw TimeoutException('Request timeout');
            },
          );

      final item = qaHistory[index];
      final wpm = int.tryParse(item['wpm'] ?? '0') ?? 0;
      final speakingSeconds = int.tryParse(item['speakingSeconds'] ?? '0') ?? 0;
      final wordCount = int.tryParse(item['wordCount'] ?? '0') ?? 0;
      final fillers = int.tryParse(item['fillers'] ?? '0') ?? 0;

      return NarasiAnswerWithCorrection(
        question: question,
        userAnswer: answer,
        aiCorrection: correction.first,
        speakingSeconds: speakingSeconds,
        wordCount: wordCount,
        wpm: wpm,
        fillerCount: fillers,
      );
    } on TimeoutException {
      print('❌ Timeout untuk pertanyaan #${index + 1}');
      return null;
    } catch (e) {
      print('❌ Error generate koreksi untuk QA #${index + 1}: $e');
      return null;
    }
  }

  Future<void> _generateDescriptiveAnalysis() async {
    final d = detect;

    // Ambil semua data
    final lookLeft = d.lookAwayLeftCount.value;
    final lookRight = d.lookAwayRightCount.value;
    final lookDown = d.lookDownCount.value;
    final totalEye = lookLeft + lookRight + lookDown;

    final enthusiasmMoments = d.getEnthusiasmMomentCount();

    final headLeft = d.headTiltLeftCount.value;
    final headRight = d.headTiltRightCount.value;
    final headDown = d.headDownCount.value;
    final totalHead = headLeft + headRight + headDown;

    // Label sesuai HRD
    final eyeLabelValue = d.getEyeLevelLabel();
    final smileLabelValue = d.getSmileLevelLabel();
    final postureLabelValue = d.getPostureLevelLabel();

    // SIMPAN LABEL KE OBSERVABLE
    eyeContactLabel.value = eyeLabelValue;
    smileLabel.value = smileLabelValue;
    postureLabel.value = postureLabelValue;

    // ===== BUILD ANALISIS DESKRIPTIF (TANPA OVERALL & TOTAL POIN) =====
    final buffer = StringBuffer();
    buffer.writeln('📊 ANALISIS HASIL WAWANCARA');
    buffer.writeln('=' * 40);
    buffer.writeln('');

    // 1. ANALISIS KONTAK MATA
    buffer.writeln('👀 KONTAK MATA: $eyeLabelValue');
    if (totalEye <= 3) {
      buffer.writeln(
        '✅ Kontak mata Anda sangat baik! Anda berhasil mempertahankan fokus ke pewawancara sepanjang wawancara.',
      );
    } else if (totalEye <= 6) {
      buffer.writeln(
        '⚠️ Kontak mata Anda cukup baik, namun masih ada beberapa momen di mana Anda mengalihkan pandangan.',
      );
      if (lookLeft > 0) buffer.writeln('   - Melirik ke kiri: $lookLeft kali');
      if (lookRight > 0)
        buffer.writeln('   - Melirik ke kanan: $lookRight kali');
      if (lookDown > 0) buffer.writeln('   - Menunduk: $lookDown kali');
      buffer.writeln(
        '💡 Saran: Kurangi kebiasaan melirik. Bayangkan kamera adalah mata pewawancara.',
      );
    } else {
      buffer.writeln(
        '❌ Kontak mata Anda masih perlu banyak latihan. Terlalu sering mengalihkan pandangan.',
      );
      if (lookLeft > 0) buffer.writeln('   - Melirik ke kiri: $lookLeft kali');
      if (lookRight > 0)
        buffer.writeln('   - Melirik ke kanan: $lookRight kali');
      if (lookDown > 0) buffer.writeln('   - Menunduk: $lookDown kali');
      buffer.writeln(
        '💡 Saran: Latih fokus menatap kamera 5 menit setiap hari.',
      );
    }
    buffer.writeln('');

    // 2. ANALISIS EKSPRESI WAJAH
    buffer.writeln('😊 EKSPRESI WAJAH: $smileLabelValue');
    if (enthusiasmMoments >= 2 && enthusiasmMoments <= 5) {
      buffer.writeln(
        '✅ Ekspresi Anda sangat profesional! Senyum natural di momen yang tepat (${enthusiasmMoments}x momen antusias).',
      );
    } else if (enthusiasmMoments == 0) {
      buffer.writeln(
        '❌ Ekspresi Anda terlalu tegang. Tidak ada momen antusias terdeteksi.',
      );
      buffer.writeln(
        '💡 Saran: Tunjukkan antusiasme 2-5 kali selama wawancara, terutama di awal dan akhir.',
      );
    } else if (enthusiasmMoments >= 10) {
      buffer.writeln(
        '⚠️ Senyum Anda terlalu sering (${enthusiasmMoments}x). Ini bisa terkesan tidak proporsional.',
      );
      buffer.writeln(
        '💡 Saran: Kurangi frekuensi senyum agar terlihat lebih profesional.',
      );
    } else {
      buffer.writeln(
        '⚠️ Ekspresi Anda cukup baik (${enthusiasmMoments}x momen antusias), namun bisa ditingkatkan.',
      );
      if (enthusiasmMoments == 1) {
        buffer.writeln(
          '💡 Saran: Tambahkan 1-2 momen antusias lagi agar lebih natural.',
        );
      } else {
        buffer.writeln(
          '💡 Saran: Kurangi sedikit frekuensi senyum agar tidak terkesan berlebihan.',
        );
      }
    }
    buffer.writeln('');

    // 3. ANALISIS POSTUR TUBUH
    buffer.writeln('🧍 POSTUR TUBUH: $postureLabelValue');
    if (totalHead <= 3) {
      buffer.writeln(
        '✅ Postur Anda sangat baik dan profesional! Tubuh tegak dan stabil.',
      );
    } else if (totalHead <= 6) {
      buffer.writeln(
        '⚠️ Postur Anda cukup baik, namun masih ada gerakan tidak perlu.',
      );
      if (headLeft > 0) buffer.writeln('   - Bahu miring kiri: $headLeft kali');
      if (headRight > 0)
        buffer.writeln('   - Bahu miring kanan: $headRight kali');
      if (headDown > 0) buffer.writeln('   - Kepala menunduk: $headDown kali');
      buffer.writeln(
        '💡 Saran: Duduk lebih tenang dan tegak. Kurangi gerakan kepala yang tidak perlu.',
      );
    } else {
      buffer.writeln(
        '❌ Postur Anda masih perlu banyak latihan. Terlalu banyak gerakan tidak stabil.',
      );
      if (headLeft > 0) buffer.writeln('   - Bahu miring kiri: $headLeft kali');
      if (headRight > 0)
        buffer.writeln('   - Bahu miring kanan: $headRight kali');
      if (headDown > 0) buffer.writeln('   - Kepala menunduk: $headDown kali');
      buffer.writeln(
        '💡 Saran: Latih postur di depan cermin. Duduk tegak dengan bahu rileks.',
      );
    }
    buffer.writeln('');

    // 4. METRIK VERBAL
    buffer.writeln('🗣️ KOMUNIKASI VERBAL');
    final avgWpm = wordsPerMinute.value;
    if (avgWpm >= 130 && avgWpm <= 160) {
      buffer.writeln('✅ Kecepatan bicara ideal: $avgWpm WPM');
    } else if (avgWpm > 180) {
      buffer.writeln('⚠️ Bicara terlalu cepat: $avgWpm WPM (ideal 130-160)');
      buffer.writeln(
        '💡 Saran: Bicara lebih pelan dan beri jeda antar kalimat.',
      );
    } else if (avgWpm < 110) {
      buffer.writeln('⚠️ Bicara terlalu lambat: $avgWpm WPM (ideal 130-160)');
      buffer.writeln(
        '💡 Saran: Percepat sedikit agar terlihat lebih percaya diri.',
      );
    } else {
      buffer.writeln('⚠️ Kecepatan bicara: $avgWpm WPM (ideal 130-160)');
    }

    if (fillerCount.value > 2) {
      buffer.writeln(
        '⚠️ Kata pengisi: ${fillerCount.value}x (kurangi "umm", "anu", "eee")',
      );
    } else {
      buffer.writeln('✅ Kata pengisi minim: ${fillerCount.value}x');
    }
    buffer.writeln('');

    // 5. REKOMENDASI KESELURUHAN
    buffer.writeln('📝 REKOMENDASI KESELURUHAN');
    final recommendations = <String>[];

    if (totalEye > 6)
      recommendations.add(
        '1. Latih kontak mata 5 menit/hari dengan menatap kamera',
      );
    if (enthusiasmMoments == 0)
      recommendations.add(
        '2. Tunjukkan 2-5 momen antusias dengan senyum natural',
      );
    if (enthusiasmMoments >= 10)
      recommendations.add(
        '2. Kurangi frekuensi senyum agar terlihat lebih profesional',
      );
    if (totalHead > 6)
      recommendations.add(
        '3. Latih postur di depan cermin, duduk tegak dan rileks',
      );
    if (avgWpm > 180)
      recommendations.add('4. Bicara lebih pelan, beri jeda antar kalimat');
    if (avgWpm < 110)
      recommendations.add('4. Percepat sedikit bicara agar lebih percaya diri');
    if (fillerCount.value > 2)
      recommendations.add(
        '5. Kurangi kata pengisi dengan latihan berbicara terstruktur',
      );

    if (recommendations.isEmpty) {
      buffer.writeln(
        '✅ Performa Anda sangat baik! Pertahankan semua kebiasaan positif ini.',
      );
      buffer.writeln('🌟 Anda sudah siap menghadapi wawancara sesungguhnya!');
    } else {
      for (final rec in recommendations) {
        buffer.writeln(rec);
      }
      buffer.writeln('');
      buffer.writeln(
        '💪 Terus latihan, setiap sesi membawa Anda lebih dekat ke sukses!',
      );
    }

    aiRecommendation.value = buffer.toString();
  }
  // ============================================================
  // SAVE TO FIRESTORE
  // ============================================================

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
        fluency: 0,
        fillerCount: fillerCount.value,
        eyeContactLabel: eyeContactLabel.value,
        smileLabel: smileLabel.value,
        postureLabel: postureLabel.value,
        analysisResult: aiRecommendation.value,
        recognizedText: recognizedText.value,
        suggestions: suggestions,
        jobTarget: jobTarget.value,
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

    final saranIndex = text.indexOf('REKOMENDASI');
    if (saranIndex != -1) {
      final saranPart = text.substring(saranIndex);
      final lines = saranPart.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('1.') ||
            trimmed.startsWith('2.') ||
            trimmed.startsWith('3.') ||
            trimmed.startsWith('4.') ||
            trimmed.startsWith('5.')) {
          if (trimmed.length > 3) {
            extracted.add(trimmed.substring(3).trim());
          }
        }
      }
    }

    if (extracted.isEmpty) {
      extracted.addAll([
        'Tingkatkan kontak mata dengan fokus ke kamera',
        'Tunjukkan senyum natural 2-5 kali selama wawancara',
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
    final moments = detect.enthusiasmMomentCount.value;
    if (moments >= 2 && moments <= 5) {
      return 'Ekspresi antusias sudah ideal. Pertahankan momen antusias yang natural ini!';
    } else if (moments == 0) {
      return 'Tunjukkan antusiasme 2-5 kali selama wawancara, terutama di awal dan akhir.';
    } else if (moments >= 10) {
      return 'Senyum terlalu sering bisa terlihat tidak natural. Coba lebih natural dan rileks.';
    } else {
      return 'Tunjukkan antusiasme yang seimbang agar terlihat profesional.';
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

  // ============================================================
  // GETTER LABEL (untuk UI)
  // ============================================================

  String getEyeLevelLabel() {
    final total =
        detect.lookAwayLeftCount.value +
        detect.lookAwayRightCount.value +
        detect.lookDownCount.value;
    if (total <= 3) return 'Fokus terhadap Pewawancara';
    if (total <= 6) return 'Sesekali Terdistraksi';
    return 'Tidak Fokus';
  }

  String getSmileLevelLabel() {
    final moments = detect.enthusiasmMomentCount.value;
    if (moments >= 2 && moments <= 5) return 'Ramah dan Profesional';
    if (moments >= 10) return 'Tidak Proporsional';
    if (moments == 0) return 'Terlalu Tegang';
    return 'Cukup Ramah';
  }

  String getPostureLevelLabel() {
    final total =
        detect.headTiltLeftCount.value +
        detect.headTiltRightCount.value +
        detect.headDownCount.value;
    if (total <= 3) return 'Sikap Profesional';
    if (total <= 6) return 'Sedikit Gelisah';
    return 'Kurang Tenang';
  }

  // ============================================================
  // UTILITY
  // ============================================================

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

  void _resetAll() {
    recognizedText.value = '';
    currentLineRecognized.value = '';
    sttConfidence.value = 0.0;
    qaHistory.clear();
    allRecognizedWords.clear();

    perQuestionWpm.clear();
    perQuestionSpeakingSeconds.clear();
    perQuestionWordCount.clear();

    totalWordsSpoken.value = 0;
    totalFillersCount.value = 0;
    wordsPerMinute.value = 0;
    fillerCount.value = 0;
    secondsLeftInLine.value = _answerSecondsForLevel(selectedLevel.value);

    _sessionStart = null;
    _firstSpeechAt = null;
    _lastSpeechAt = null;
    _totalSpeakingSeconds = 0;
    isAsking.value = false;
    isAnswering.value = false;

    _currentAnswerSpeakingSeconds = 0;
    _currentAnswerWordCount = 0;
    _isSpeakingNow = false;
    _speakingStopwatch = null;

    _silenceTimer?.cancel();
    _answerTimer?.cancel();
    aiRecommendation.value = '';
    detectionResult.value = null;
    _clearFaceWarning();

    eyeContactLabel.value = '';
    smileLabel.value = '';
    postureLabel.value = '';

    answersWithCorrections.clear();
  }

  void backToInstructions() {
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
  }

  void backToChoose() {
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
    step.value = PracticeStep.choose;
  }

  // ============================================================
  // PER QUESTION DETAILS
  // ============================================================

  List<Map<String, dynamic>> getPerQuestionDetails() {
    final List<Map<String, dynamic>> details = [];
    for (int i = 0; i < qaHistory.length; i++) {
      final item = qaHistory[i];
      details.add({
        'number': i + 1,
        'question': item['q'] ?? '',
        'answer': item['a'] ?? '',
        'wordCount': int.tryParse(item['wordCount'] ?? '0') ?? 0,
        'speakingSeconds': int.tryParse(item['speakingSeconds'] ?? '0') ?? 0,
        'wpm': int.tryParse(item['wpm'] ?? '0') ?? 0,
        'fillers': int.tryParse(item['fillers'] ?? '0') ?? 0,
      });
    }
    return details;
  }

  String getWpmRating(int wpm) {
    if (wpm >= 130 && wpm <= 160) return 'Ideal ✅';
    if (wpm >= 110 && wpm < 130) return 'Sedikit Lambat ⚠️';
    if (wpm > 160 && wpm <= 180) return 'Sedikit Cepat ⚠️';
    if (wpm > 180) return 'Terlalu Cepat ❌';
    return 'Terlalu Lambat ❌';
  }

  Color getWpmColor(int wpm) {
    if (wpm >= 130 && wpm <= 160) return const Color(0xFF10B981);
    if (wpm >= 110 && wpm < 130) return const Color(0xFFF59E0B);
    if (wpm > 160 && wpm <= 180) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String getWpmRecommendation(int wpm) {
    if (wpm >= 130 && wpm <= 160) {
      return '✅ Kecepatan bicara ideal, pertahankan!';
    } else if (wpm >= 110 && wpm < 130) {
      return '⚠️ Bicara terlalu lambat. Coba percepat sedikit agar lebih percaya diri.';
    } else if (wpm > 160 && wpm <= 180) {
      return '⚠️ Bicara agak cepat. Coba lebih rileks dan beri jeda.';
    } else if (wpm > 180) {
      return '❌ Bicara terlalu cepat! Pewawancara mungkin kesulitan mengikuti.';
    }
    return '❌ Bicara terlalu lambat. Coba percepat sedikit.';
  }

  // ============================================================
  // DETAIL BEHAVIOR ANALYSIS
  // ============================================================

  Future<String> getDetailedBehaviorAnalysis() async {
    final d = detect;

    final lookLeft = d.lookAwayLeftCount.value;
    final lookRight = d.lookAwayRightCount.value;
    final lookDown = d.lookDownCount.value;
    final totalEye = lookLeft + lookRight + lookDown;

    final enthusiasmMoments = d.enthusiasmMomentCount.value;

    final headLeft = d.headTiltLeftCount.value;
    final headRight = d.headTiltRightCount.value;
    final headDown = d.headDownCount.value;
    final totalHead = headLeft + headRight + headDown;

    final eyePoints = d.getEyeContactPoints();
    final smilePoints = d.getFacialExpressionPoints();
    final posturePoints = d.getPosturePoints();

    return await aiService.generateBehaviorDetailAnalysis(
      eyeLabel: eyeContactLabel.value,
      eyeViolations: totalEye,
      smileLabel: smileLabel.value,
      smileCount: d.smileCount.value,
      neutralCount: d.neutralCount.value,
      postureLabel: postureLabel.value,
      postureViolations: totalHead,
      totalPoints: eyePoints + smilePoints + posturePoints,
      maxPoints: 6,
      overallLabel: '${eyePoints + smilePoints + posturePoints}/6',
      lookLeftCount: lookLeft,
      lookRightCount: lookRight,
      lookDownCount: lookDown,
      headTiltLeftCount: headLeft,
      headTiltRightCount: headRight,
      headDownCount: headDown,
      wpm: wordsPerMinute.value,
      fillerCount: fillerCount.value,
      totalWords: totalWordsSpoken.value,
      enthusiasmMoments: enthusiasmMoments,
      smilePoints: smilePoints,
    );
  }
}
