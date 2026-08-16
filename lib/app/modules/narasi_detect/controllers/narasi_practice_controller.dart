// lib/app/modules/narasi_detect/controllers/narasi_practice_controller.dart
import 'dart:async';
import 'dart:math';

import 'package:fluent_ai/app/models/detection_result_model.dart';
import 'package:fluent_ai/app/models/narasi_question_model.dart';
import 'package:fluent_ai/app/models/practice_session_model.dart';
import 'package:fluent_ai/app/services/ai_feedback_service.dart';
import 'package:fluent_ai/app/services/ai_question_service.dart';
import 'package:fluent_ai/app/services/practice_firestore_service.dart';
import 'package:fluent_ai/app/services/elevenlabs_tts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'narasi_detect_controller.dart';

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

  // ElevenLabs TTS
  late final ElevenLabsTtsService _elevenTts;
  final isTtsSpeaking = false.obs;
  final soundEnabled = true.obs;

  // Job target
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

  // WPM & FILLER
  final wordsPerMinute = 0.obs;
  final fillerCount = 0.obs;
  final totalWordsSpoken = 0.obs;
  final totalFillersCount = 0.obs;
  final RxList<String> allRecognizedWords = <String>[].obs;

  final RxList<int> perQuestionWpm = <int>[].obs;
  final RxList<int> perQuestionSpeakingSeconds = <int>[].obs;
  final RxList<int> perQuestionWordCount = <int>[].obs;

  // Break count per pertanyaan (total dan arah)
  final RxList<int> perQuestionBreaks = <int>[].obs;
  final RxList<int> perQuestionRightBreaks = <int>[].obs;
  final RxList<int> perQuestionLeftBreaks = <int>[].obs;
  final RxList<int> perQuestionUpBreaks = <int>[].obs;
  final RxList<int> perQuestionDownBreaks = <int>[].obs;

  // Smile counts per pertanyaan
  final RxList<int> perQuestionTotalSmiles = <int>[].obs;
  final RxList<int> perQuestionAuthentic = <int>[].obs;
  final RxList<int> perQuestionFake = <int>[].obs;
  final RxList<int> perQuestionUncertain = <int>[].obs;

  // Akumulasi total arah (seluruh sesi) – Gunakan Map biasa, bukan RxMap
  final Map<String, int> totalDirectionBreaks = {
    'right': 0,
    'left': 0,
    'up': 0,
    'down': 0,
  };

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
  double? _finalFocusPercentage;
  int? _finalTotalBreaks;

  final eyeContactLabel = ''.obs;

  final isFaceWarning = false.obs;
  final faceWarningMessage = ''.obs;
  Timer? _faceWarningTimer;

  final isAiProcessing = false.obs;
  final aiProcessingMessage = 'Sedang menganalisis hasil...'.obs;

  bool _isSessionSaved = false;

  // Snapshot untuk break count dan fokus per pertanyaan
  int _questionStartFocusDuration = 0;
  int _questionStartTotalElapsed = 0;
  // Snapshot arah per pertanyaan
  int _questionStartRightBreaks = 0;
  int _questionStartLeftBreaks = 0;
  int _questionStartUpBreaks = 0;
  int _questionStartDownBreaks = 0;
  int _questionStartTotalBreaks = 0;

  // Snapshot smile counters per pertanyaan
  int _questionStartTotalSmiles = 0;
  int _questionStartAuthentic = 0;
  int _questionStartFake = 0;
  int _questionStartUncertain = 0;

  // ============================================================
  // DURASI: 2,5 MENIT TOTAL, 5 PERTANYAAN @ 30 DETIK
  // ============================================================
  int _questionCountForLevel(PracticeLevel level) {
    return 5;
  }

  int _answerSecondsForLevel(PracticeLevel level) {
    return 30;
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
    _initElevenTts();

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
    _elevenTts.dispose();
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
  // ELEVENLABS TTS
  // ============================================================

  void _initElevenTts() {
    _elevenTts = ElevenLabsTtsService();
  }

  Future<void> _stopTts() async {
    try {
      await _elevenTts.stop();
    } catch (_) {}
    isTtsSpeaking.value = false;
    isAsking.value = false;
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
      isTtsSpeaking.value = true;
      await _elevenTts.speak(
        question,
        onComplete: () {
          isTtsSpeaking.value = false;
          isAsking.value = false;
          if (isSessionRunning.value) _startAnswerPhase();
        },
      );
    } catch (_) {
      isTtsSpeaking.value = false;
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
    
    // Tampilkan loading saat AI memvalidasi
    isAiProcessing.value = true;
    aiProcessingMessage.value = 'Mengecek validitas profesi...';
    
    final isValid = await aiQuestionService.validateJobTarget(target);
    
    isAiProcessing.value = false;
    aiProcessingMessage.value = '';
    
    if (!isValid) {
      Get.snackbar(
        'Pekerjaan Tidak Valid', 
        'Kata "$target" tidak dikenali sebagai posisi pekerjaan/profesi sungguhan. Tolong masukkan profesi yang valid.',
      );
      return; // Berhenti di sini, jangan lanjut ke step choose
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
    await _buildScriptFromAI();
    startCountdown();
  }

  Future<void> pickHard() async {
    if (isAiProcessing.value ||
        isSessionRunning.value ||
        step.value == PracticeStep.countdown)
      return;
    selectedLevel.value = PracticeLevel.hard;
    await _buildScriptFromAI();
    startCountdown();
  }

  Future<void> pickAdvance() async {
    if (isAiProcessing.value ||
        isSessionRunning.value ||
        step.value == PracticeStep.countdown)
      return;
    selectedLevel.value = PracticeLevel.advance;
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
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
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
      detect.resetCounters();

      isSessionRunning.value = true;
      _sessionStart = DateTime.now();
      _lastSpeechAt = null;
      step.value = PracticeStep.practice;

      await detect.start();
      await speakHrdQuestion(currentLine.value);
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

  // ============================================================
  // ANSWER PHASE – 30 DETIK PER PERTANYAAN
  // ============================================================

  Future<void> _startAnswerPhase() async {
    if (!isSessionRunning.value) return;
    isAnswering.value = true;
    secondsLeftInLine.value = _answerSecondsForLevel(selectedLevel.value);
    currentLineRecognized.value = '';

    // ===== SNAPSHOT UNTUK FOKUS DAN ARAH =====
    _questionStartFocusDuration = detect.getFocusDurationMs();
    _questionStartTotalElapsed = detect.getSessionElapsedMs();
    _questionStartRightBreaks = detect.getRightBreaks();
    _questionStartLeftBreaks = detect.getLeftBreaks();
    _questionStartUpBreaks = detect.getUpBreaks();
    _questionStartDownBreaks = detect.getDownBreaks();
    _questionStartTotalBreaks = detect.getTotalBreaks();

    // Snapshot smile counters
    _questionStartTotalSmiles = detect.getTotalSmiles();
    _questionStartAuthentic = detect.getAuthenticCount();
    _questionStartFake = detect.getFakeCount();
    _questionStartUncertain = detect.getUncertainCount();

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
  // COMMIT TRANSCRIPT – DENGAN DATA ARAH
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

    // ===== AMBIL DATA BREAK ARAH DARI DETECT =====
    final d = detect;
    final rightDelta = d.getRightBreaks() - _questionStartRightBreaks;
    final leftDelta = d.getLeftBreaks() - _questionStartLeftBreaks;
    final upDelta = d.getUpBreaks() - _questionStartUpBreaks;
    final downDelta = d.getDownBreaks() - _questionStartDownBreaks;
    final totalDelta = d.getTotalBreaks() - _questionStartTotalBreaks;

    // ===== HITUNG PERSENTASE FOKUS UNTUK PERTANYAAN INI =====
    final endFocusDuration = d.getFocusDurationMs();
    final endTotalElapsed = d.getSessionElapsedMs();
    final focusDelta = endFocusDuration - _questionStartFocusDuration;
    final totalDeltaTime = endTotalElapsed - _questionStartTotalElapsed;
    double focusPercentage = 0.0;
    if (totalDeltaTime > 0) {
      focusPercentage = (focusDelta / totalDeltaTime) * 100;
    }
    focusPercentage = focusPercentage.clamp(0.0, 100.0);

    // Simpan ke list per pertanyaan
    perQuestionBreaks.add(totalDelta);
    perQuestionRightBreaks.add(rightDelta);
    perQuestionLeftBreaks.add(leftDelta);
    perQuestionUpBreaks.add(upDelta);
    perQuestionDownBreaks.add(downDelta);
    perQuestionWordCount.add(finalWordCount);
    perQuestionSpeakingSeconds.add(finalSpeakingSeconds);
    perQuestionWpm.add(finalWpm);

    // ===== Smile deltas per pertanyaan =====
    final endTotalSmiles = d.getTotalSmiles();
    final endAuthentic = d.getAuthenticCount();
    final endFake = d.getFakeCount();
    final endUncertain = d.getUncertainCount();

    final deltaSmiles = endTotalSmiles - _questionStartTotalSmiles;
    final deltaAuthentic = endAuthentic - _questionStartAuthentic;
    final deltaFake = endFake - _questionStartFake;
    final deltaUncertain = endUncertain - _questionStartUncertain;

    perQuestionTotalSmiles.add(deltaSmiles);
    perQuestionAuthentic.add(deltaAuthentic);
    perQuestionFake.add(deltaFake);
    perQuestionUncertain.add(deltaUncertain);

    // Simpan ke history
    qaHistory.add({
      'q': currentQ,
      'a': lineText,
      'wordCount': finalWordCount.toString(),
      'speakingSeconds': finalSpeakingSeconds.toString(),
      'wpm': finalWpm.toString(),
      'fillers': finalFillers.toString(),
      'focusPercentage': focusPercentage.toStringAsFixed(0),
      'breaks': totalDelta.toString(),
      'breaksRight': rightDelta.toString(),
      'breaksLeft': leftDelta.toString(),
      'breaksUp': upDelta.toString(),
      'breaksDown': downDelta.toString(),
      'totalSmiles': deltaSmiles.toString(),
      'authentic': deltaAuthentic.toString(),
      'fake': deltaFake.toString(),
      'uncertain': deltaUncertain.toString(),
    });

    // Akumulasi total arah (seluruh sesi) – dengan CASTING ke int
    totalDirectionBreaks['right'] =
        (totalDirectionBreaks['right']! + rightDelta) as int;
    totalDirectionBreaks['left'] =
        (totalDirectionBreaks['left']! + leftDelta) as int;
    totalDirectionBreaks['up'] = (totalDirectionBreaks['up']! + upDelta) as int;
    totalDirectionBreaks['down'] =
        (totalDirectionBreaks['down']! + downDelta) as int;

    if (kDebugMode) {
      print(
        '📝 Q&A #${qaHistory.length} - Words: $finalWordCount, Speaking: ${finalSpeakingSeconds}s, WPM: $finalWpm, Breaks: $totalDelta (R:$rightDelta L:$leftDelta U:$upDelta D:$downDelta)',
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

    // Reset snapshot untuk pertanyaan berikutnya
    _questionStartRightBreaks = 0;
    _questionStartLeftBreaks = 0;
    _questionStartUpBreaks = 0;
    _questionStartDownBreaks = 0;
    _questionStartTotalBreaks = 0;
    _questionStartFocusDuration = 0;
    _questionStartTotalElapsed = 0;
  }

  // ============================================================
  // SKIP PERTANYAAN
  // ============================================================

  void skipCurrentQuestion() {
    if (!isSessionRunning.value || !isAnswering.value) return;

    if (currentLineRecognized.value.trim().isNotEmpty) {
      _commitLineTranscript();
    }

    _answerTimer?.cancel();
    isAnswering.value = false;
    secondsLeftInLine.value = 0;

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
    // Simpan nilai akhir tepat ketika sesi berhenti agar feedback tidak berubah
    // selama proses analisis AI berjalan.
    _finalFocusPercentage = detect.getFocusPercentage();
    _finalTotalBreaks = detect.getTotalBreaks();
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

    await _generateAllCorrections();
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

  // ============================================================
  // GENERATE DESCRIPTIVE ANALYSIS – DENGAN RINCIAN ARAH
  // ============================================================

  Future<void> _generateDescriptiveAnalysis() async {
    final d = detect;
    final totalBreaks = _finalTotalBreaks ?? d.getTotalBreaks();
    final percentage = _finalFocusPercentage ?? d.getFocusPercentage();
    final label = _eyeContactLabelFor(percentage);

    eyeContactLabel.value = label;

    final analysis = await aiService.generateEyeContactAnalysis(
      focusPercentage: percentage,
      eyeLabel: label,
      totalBreaks: totalBreaks,
      wpm: wordsPerMinute.value,
      fillerCount: fillerCount.value,
      totalWords: totalWordsSpoken.value,
    );
    aiRecommendation.value = analysis;

    // Buat DetectionResultModel dengan rincian arah
    final right = d.getRightBreaks();
    final left = d.getLeftBreaks();
    final up = d.getUpBreaks();
    final down = d.getDownBreaks();

    String suggestion = '';
    if (label == 'Ideal') {
      suggestion = '✅ Frekuensi fokus baik. Total menengok $totalBreaks kali.';
    } else if (label == 'Terlalu Lama') {
      suggestion = '🟠 Terlalu menatap kaku. Total menengok $totalBreaks kali.';
    } else {
      suggestion = '🔴 Kurang fokus. Total menengok $totalBreaks kali.';
    }
    suggestion += ' (Kanan: $right, Kiri: $left, Atas: $up, Bawah: $down)';

    // Smile summary: hanya catat total senyum dan lencana dominan sederhana
    final totalSmiles = d.getTotalSmiles();

    final String smileDominantLabel = totalSmiles > 0 ? 'Tersenyum' : '';
    final String smileSuggestion = totalSmiles > 0
        ? 'Terlihat tersenyum selama sesi. Pertahankan ekspresi natural.'
        : '';

    // restore per-class counts into the SmileResult for saved feedback
    final int authenticCount = d.getAuthenticCount();
    final int fakeCount = d.getFakeCount();
    final int uncertainCount = d.getUncertainCount();

    final detectionResultModel = DetectionResultModel(
      eyeContact: EyeContactResult(
        focusPercentage: percentage,
        totalBreaks: totalBreaks,
        conclusion: label,
        suggestion: suggestion,
      ),
      smileResult: SmileResult(
        totalSmiles: totalSmiles,
        totalAuthentic: authenticCount,
        totalFake: fakeCount,
        totalUncertain: uncertainCount,
        dominantLabel: smileDominantLabel,
        suggestion: smileSuggestion,
      ),
      timestamp: DateTime.now(),
      aiRecommendation: analysis,
    );
    detectionResult.value = detectionResultModel;
  }

  String _eyeContactLabelFor(double focusPercentage) {
    if (focusPercentage < 70) return 'Terlalu Sedikit';
    if (focusPercentage > 80) return 'Terlalu Lama';
    return 'Ideal';
  }

  // ============================================================
  // SAVE SESSION
  // ============================================================

  Future<void> _saveSessionToFirestore() async {
    try {
      final List<String> suggestions = _extractSuggestionsFromAI();

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
        analysisResult: aiRecommendation.value,
        recognizedText: recognizedText.value,
        suggestions: suggestions,
        jobTarget: jobTarget.value,
        detectionResult: detectionResult.value,
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

  // ============================================================
  // SUGGESTIONS & GETTER
  // ============================================================

  List<String> _extractSuggestionsFromAI() {
    final List<String> extracted = [];
    final text = aiRecommendation.value;
    final saranIndex = text.indexOf('SARAN KONTAK MATA');
    if (saranIndex != -1) {
      final saranPart = text.substring(saranIndex);
      final lines = saranPart.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && !trimmed.startsWith('SARAN KONTAK MATA')) {
          extracted.add(trimmed);
        }
      }
    }
    if (extracted.isEmpty) {
      extracted.addAll([
        'Usahakan wajah terlihat minimal 70% dari total sesi.',
        'Kurangi frekuensi menengok ke samping.',
      ]);
    }
    return extracted.take(3).toList();
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
    perQuestionBreaks.clear();
    perQuestionRightBreaks.clear();
    perQuestionLeftBreaks.clear();
    perQuestionUpBreaks.clear();
    perQuestionDownBreaks.clear();

    totalDirectionBreaks['right'] = 0;
    totalDirectionBreaks['left'] = 0;
    totalDirectionBreaks['up'] = 0;
    totalDirectionBreaks['down'] = 0;

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

    _answerTimer?.cancel();
    aiRecommendation.value = '';
    detectionResult.value = null;
    _finalFocusPercentage = null;
    _finalTotalBreaks = null;
    _clearFaceWarning();

    eyeContactLabel.value = '';

    answersWithCorrections.clear();

    _questionStartRightBreaks = 0;
    _questionStartLeftBreaks = 0;
    _questionStartUpBreaks = 0;
    _questionStartDownBreaks = 0;
    _questionStartTotalBreaks = 0;
    _questionStartFocusDuration = 0;
    _questionStartTotalElapsed = 0;
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
  // PER QUESTION DETAILS – DENGAN DATA ARAH
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
        'focusPercentage':
            double.tryParse(item['focusPercentage'] ?? '0') ?? 0.0,
        'breaks': int.tryParse(item['breaks'] ?? '0') ?? 0,
        'breaksRight': int.tryParse(item['breaksRight'] ?? '0') ?? 0,
        'breaksLeft': int.tryParse(item['breaksLeft'] ?? '0') ?? 0,
        'breaksUp': int.tryParse(item['breaksUp'] ?? '0') ?? 0,
        'breaksDown': int.tryParse(item['breaksDown'] ?? '0') ?? 0,
        // smile breakdown per question (from qaHistory fields)
        'totalSmiles': int.tryParse(item['totalSmiles'] ?? '0') ?? 0,
        'authentic': int.tryParse(item['authentic'] ?? '0') ?? 0,
        'fake': int.tryParse(item['fake'] ?? '0') ?? 0,
        'uncertain': int.tryParse(item['uncertain'] ?? '0') ?? 0,
      });
    }
    return details;
  }

  String getWpmRating(int wpm) {
    if (wpm >= 120 && wpm <= 160) return 'Ideal ✓';
    if (wpm > 160) return 'Terlalu Cepat ⚠️';
    return 'Terlalu Lambat ⚠️';
  }

  Color getWpmColor(int wpm) {
    if (wpm >= 120 && wpm <= 160) return const Color(0xFF10B981);
    return const Color(0xFFF59E0B);
  }

  String getWpmRecommendation(int wpm) {
    if (wpm >= 120 && wpm <= 160)
      return '✓ Kecepatan bicara dalam rentang yang baik untuk latihan wawancara.';
    else if (wpm > 160)
      return '⚠️ Terlalu cepat — tambahkan jeda singkat setelah setiap poin penting agar audiens dapat mengikuti.';
    else
      return '⚠️ Terlalu lambat — tambah sedikit energi dan kurangi jeda yang tidak perlu.';
  }
}
