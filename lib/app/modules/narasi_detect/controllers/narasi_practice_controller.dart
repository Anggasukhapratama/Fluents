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

// ===== DIPERBARUI: Tambah step jobInput =====
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
  final AiQuestionService aiQuestionService = AiQuestionService(); // BARU

  late final FlutterTts flutterTts;
  final isTtsSpeaking = false.obs;
  final soundEnabled = true.obs;

  // ===== BARU: Job Target =====
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

  // ===== BARU: Simpan transkrip yg sudah di-commit di sesi jawaban ini =====
  // Ini supaya kalau user diam lama (STT auto-stop), lalu mulai ngomong lagi,
  // transkrip lama tidak hilang dan tetap di-append
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

  // ===== BARU: Menyimpan koreksi AI per jawaban =====
  final RxList<NarasiAnswerWithCorrection> answersWithCorrections =
      <NarasiAnswerWithCorrection>[].obs;
  final isGeneratingCorrections = false.obs;

  // ========== WPM & FILLER (PER PERTANYAAN + SPEAKING TIME) ==========
  final wordsPerMinute = 0.obs;
  final fillerCount = 0.obs;
  final totalWordsSpoken = 0.obs;
  final totalFillersCount = 0.obs;
  final RxList<String> allRecognizedWords = <String>[].obs;

  // === PER-QUESTION METRICS ===
  final RxList<int> perQuestionWpm = <int>[].obs;
  final RxList<int> perQuestionSpeakingSeconds = <int>[].obs;
  final RxList<int> perQuestionWordCount = <int>[].obs;

  // Speaking time tracker
  Stopwatch? _speakingStopwatch;
  bool _isSpeakingNow = false;

  // Data untuk jawaban saat ini (belum di-commit)
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

  // ===== HAPUS hrdQuestions static (tidak dipakai lagi) =====

  int _questionCountForLevel(PracticeLevel level) {
    // SEMUA LEVEL = 5 PERTANYAAN
    return 5; // ← DULU: medium=5, hard=6, advance=6
  }

  // ===== DURASI TETAP BERBEDA =====
  int _answerSecondsForLevel(PracticeLevel level) {
    switch (level) {
      case PracticeLevel.medium:
        return 20; // 20 detik
      case PracticeLevel.hard:
        return 25; // 25 detik
      case PracticeLevel.advance:
        return 30; // 30 detik
    }
  }

  // ==================== HELPER METHODS ====================

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

  // ==================== LIFECYCLE ====================

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

  // ==================== TTS ====================

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

  // ==================== FLOW BARU ====================

  void startToInstructions() {
    step.value = PracticeStep.instructions;
  }

  void nextToJobInput() {
    step.value = PracticeStep.jobInput;
  }

  // ===== BARU: Submit job target =====
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

  // ===== PILIH LEVEL (DIMODIFIKASI dengan Guard Clause) =====
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

  // ===== BARU: Generate pertanyaan dari AI =====
  Future<void> _buildScriptFromAI() async {
    final level = selectedLevel.value;
    final questionCount = _questionCountForLevel(level);
    final target = jobTarget.value;

    if (target.isEmpty) {
      Get.snackbar('Error', 'Job target tidak boleh kosong');
      step.value = PracticeStep.jobInput;
      return;
    }

    // Tampilkan loading
    isAiProcessing.value = true;
    aiProcessingMessage.value =
        'AI sedang menyusun $questionCount pertanyaan wawancara...';

    try {
      final questions = await aiQuestionService.generateQuestions(
        jobTarget: target,
        level: _getLevelString(level),
        questionCount: questionCount,
      );

      // Validasi ketat jumlah pertanyaan
      if (questions.length != questionCount) {
        print(
          '⚠️ AI menghasilkan ${questions.length} pertanyaan, diharapkan $questionCount',
        );
        _buildFallbackQuestions();
        return;
      }

      // Validasi kualitas pertanyaan
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
      'Di mana Anda melihat diri Anda dalam 5 tahun ke depan?',
      'Mengapa kami harus memilih Anda dibandingkan kandidat lain?',
      'Ceritakan tentang tantangan terbesar yang pernah Anda hadapi.',
      'Bagaimana Anda menangani konflik dalam tim?',
    ];

    // Pastikan tepat sesuai count yang diminta
    final selectedQuestions = fallbacks.take(count).toList();

    // Double check jumlahnya
    if (selectedQuestions.length != count) {
      print(
        '❌ Fallback questions tidak sesuai jumlah: ${selectedQuestions.length} vs $count',
      );
      // Tambah pertanyaan generic jika kurang
      while (selectedQuestions.length < count) {
        selectedQuestions.add(
          'Ceritakan pengalaman Anda yang relevan dengan $target.',
        );
      }
    }

    scriptLines.assignAll(selectedQuestions);
    currentIndex.value = 0;
    currentLine.value = scriptLines.isNotEmpty ? scriptLines.first : '';
    _resetAll();

    print(
      '✅ Fallback questions loaded: ${scriptLines.length} pertanyaan untuk level ${level.name}',
    );
  }

  // ==================== STT ====================

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

  // ==================== SESSION FLOW ====================

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

    // HITUNG KATA DARI SELURUH TEKS YANG DIUCAPKAN (bukan tambahan)
    final currentWords = _countWords(spoken);
    _currentAnswerWordCount =
        currentWords; // Langsung pakai total kata, bukan tambahan

    // Hitung total kata dari history + current
    int totalWordsFromHistory = 0;
    for (final item in qaHistory) {
      totalWordsFromHistory += _countWords(item['a'] ?? '');
    }
    totalWordsSpoken.value = totalWordsFromHistory + _currentAnswerWordCount;

    // Hitung filler
    final currentFillers = _countFillers(spoken);
    int totalFillers = 0;
    for (final item in qaHistory) {
      totalFillers += _countFillers(item['a'] ?? '');
    }
    fillerCount.value = totalFillers + currentFillers;
    totalFillersCount.value = fillerCount.value;

    // HITUNG WPM REAL-TIME dengan speaking seconds yang sudah berjalan
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
      print('📊 FINAL WPM STATS (per question):');
      print('   Per-question WPM: $perQuestionWpm');
      print('   Average WPM: ${wordsPerMinute.value}');
      print(
        '   Total speaking time: ${perQuestionSpeakingSeconds.fold(0, (sum, s) => sum + s)} seconds',
      );
      print('   Total words: $totalWords');
    }
  }

  void _finalizeFillers() {
    int totalFillers = 0;
    for (final item in qaHistory) {
      totalFillers += _countFillers(item['a'] ?? '');
    }
    fillerCount.value = totalFillers;
    totalFillersCount.value = totalFillers;
    if (kDebugMode) {
      print(
        '🗣️ FINAL FILLER: $totalFillers dari ${totalWordsSpoken.value} kata',
      );
    }
  }

  void _startSilenceMonitor() {}

  // ==================== ANSWER PHASE ====================

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

    // Reset saved transcript untuk jawaban baru
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

  // ==================== COMMIT TRANSCRIPT ====================

  void _commitLineTranscript() {
    final lineText = currentLineRecognized.value.trim();
    final currentQ = currentLine.value;

    // Cek apakah sudah pernah di-commit untuk pertanyaan ini
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
        '📝 Q&A #${qaHistory.length} - Words: $finalWordCount, Speaking: ${finalSpeakingSeconds}s, WPM: $finalWpm, Fillers: $finalFillers',
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
    _savedTranscriptForCurrentAnswer = ''; // Reset untuk jawaban berikutnya
  }

  // ==================== STOP SESSION & GENERATE CORRECTIONS ====================

  Future<void> stopSession({required bool goResult}) async {
    // Prevent multiple calls
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

    // Commit transcript hanya jika sedang menjawab dan ada jawaban
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

    // ===== BARU: Generate koreksi AI untuk semua jawaban =====
    await _generateAllCorrections();

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

  // ===== BARU: Generate koreksi untuk semua jawaban =====
  Future<void> _generateAllCorrections() async {
    if (qaHistory.isEmpty) return;

    isGeneratingCorrections.value = true;
    answersWithCorrections.clear();

    final target = jobTarget.value;
    final totalQuestions = qaHistory.length;

    // Reset progress
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

      // Jeda antar request untuk menghindari rate limit
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Wait semua dengan error handling
    final results = await Future.wait(futures, eagerError: false);

    // Filter yang berhasil
    final successfulResults = results
        .whereType<NarasiAnswerWithCorrection>()
        .toList();

    // Sort berdasarkan urutan pertanyaan
    successfulResults.sort((a, b) => a.question.compareTo(b.question));

    answersWithCorrections.assignAll(successfulResults);

    print(
      '📊 Koreksi selesai: ${successfulResults.length} berhasil dari $totalQuestions',
    );

    // Jika ada yang gagal, tampilkan pesan singkat tapi tetap lanjut
    if (successfulResults.length < totalQuestions) {
      final failedCount = totalQuestions - successfulResults.length;
      print('⚠️ $failedCount koreksi gagal/timeout, menggunakan fallback');
      // Tidak perlu tampilkan error ke user, langsung lanjut aja
    }

    isGeneratingCorrections.value = false;
    aiProcessingMessage.value = ''; // Clear message
  }

  // Method untuk generate satu koreksi dengan timeout
  Future<NarasiAnswerWithCorrection?> _generateSingleCorrectionWithTimeout({
    required String question,
    required String answer,
    required String jobTarget,
    required int index,
    required int total,
  }) async {
    // Update progress
    aiProcessingMessage.value = '⏳ Menganalisis jawaban ${index + 1}/$total...';

    try {
      // Gunakan timeout 15 detik per request
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

      // Ambil metrics dari qaHistory
      final item = qaHistory[index];
      final wpm = int.tryParse(item['wpm'] ?? '0') ?? 0;
      final speakingSeconds = int.tryParse(item['speakingSeconds'] ?? '0') ?? 0;
      final wordCount = int.tryParse(item['wordCount'] ?? '0') ?? 0;
      final fillers = int.tryParse(item['fillers'] ?? '0') ?? 0;

      return NarasiAnswerWithCorrection(
        question: question,
        userAnswer: answer,
        aiCorrection: correction.first, // Ambil dari Future.wait
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

  // ==================== SAVE TO FIRESTORE ====================

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
    final moments = detect.enthusiasmMomentCount.value;
    if (moments >= 2 && moments <= 5) {
      return 'Ekspresi antusias sudah ideal. Pertahankan momen antusias yang natural ini!';
    } else if (moments == 1) {
      return 'Tunjukkan antusiasme sedikit lebih banyak, terutama di awal & akhir wawancara.';
    } else if (moments >= 6 && moments <= 9) {
      return 'Antusiasme cukup, tapi jangan terlalu sering tersenyum agar terlihat profesional.';
    } else if (moments >= 10) {
      return 'Senyum terlalu sering bisa terlihat tidak natural. Coba lebih natural dan rileks.';
    } else {
      return 'Cobalah menunjukkan antusiasme 2-5 kali selama wawancara, terutama di momen yang tepat.';
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

  // ==================== GENERATE AI RECOMMENDATION ====================

  // Ganti method _generateAiRecommendation() dengan versi yang lebih lengkap

  Future<void> _generateAiRecommendation() async {
    final totalLeftEye = detect.lookAwayLeftCount.value;
    final totalRightEye = detect.lookAwayRightCount.value;
    final totalDownEye = detect.lookDownCount.value;
    final totalEye = totalLeftEye + totalRightEye + totalDownEye;

    final totalSmile = detect.smileCount.value;
    final totalNeutral = detect.neutralCount.value;

    // ===== Momen Antusias (logika baru: count-based) =====
    final enthusiasmMoments = detect.getEnthusiasmMomentCount();

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

    if (totalPoints == 6) {
      overallLabelValue = 'Sangat Percaya Diri';
      motivationMessage =
          'Luar biasa! Anda menunjukkan performa sempurna dan sangat percaya diri!';
    } else if (totalPoints >= 4 && totalPoints <= 5 && !hasZeroPoint) {
      overallLabelValue = 'Siap Wawancara';
      motivationMessage =
          'Selamat! Anda sudah siap menghadapi wawancara. Terus pertahankan!';
    } else if (totalPoints >= 2 && totalPoints <= 3) {
      overallLabelValue = 'Cukup Baik';
      motivationMessage =
          'Performa Anda cukup baik, terus latih kemampuan Anda agar lebih percaya diri!';
    } else {
      overallLabelValue = 'Perlu Banyak Latihan';
      motivationMessage =
          'Jangan berkecil hati! Latihan rutin akan membawa perubahan besar!';
    }

    eyeContactLabel.value = eyeLabelValue;
    smileLabel.value = smileLabelValue;
    postureLabel.value = postureLabelValue;
    overallLabel.value = overallLabelValue;
    confidenceMessage.value = motivationMessage;

    // ========== PROMPT RINGKAS ==========
    final detailedPrompt =
        '''
Anda HRD. Buat analisis SANGAT SINGKAT dari data ini.

DATA:
- Kontak Mata: $eyeLabelValue ($eyePoints/2), tidak fokus $totalEye kali
- Ekspresi: $smileLabelValue ($smilePoints/2), antusias $enthusiasmMoments kali
- Postur: $postureLabelValue ($posturePoints/2), tidak stabil $totalHead kali
- Kecepatan: ${wordsPerMinute.value} WPM (ideal 130-160)
- Filler: ${fillerCount.value} kali
- Total: $totalPoints/$maxPoints — "$overallLabelValue"

FORMAT (ikuti persis, jangan lebih panjang):

KESIMPULAN:
[1 kalimat inti saja]

POIN UTAMA:
Kontak Mata: $eyeLabelValue ($eyePoints/2)
Ekspresi: $smileLabelValue ($smilePoints/2)
Postur: $postureLabelValue ($posturePoints/2)

REKOMENDASI:
1. [saran singkat]
2. [saran singkat]
3. [saran singkat]

MOTIVASI:
[1 kalimat pendek]

ATURAN: Tanpa markdown (* - # **). Tidak ada penjelasan tambahan. Maksimal 70 kata total.
''';

    String result;
    try {
      result = await aiService.generateRecommendationWithDetailedPrompt(
        detailedPrompt,
      );
      if (result.isEmpty) {
        result = _getFallbackDetailAnalysis(overallLabelValue);
      }
    } catch (e) {
      print('❌ Gagal generate AI recommendation: $e');
      result = _getFallbackDetailAnalysis(overallLabelValue);
    }

    final cleanResult = result
        .replaceAll(RegExp(r'[*_\-]{3,}'), '')
        .replaceAll(RegExp(r'[*]{2,}'), '')
        .replaceAll('━', '')
        .replaceAll('─', '')
        .trim();

    aiRecommendation.value = cleanResult;
  }

  // Tambahkan method fallback (versi ringkas)
  String _getFallbackDetailAnalysis(String overallLabel) {
    if (overallLabel == 'Sangat Percaya Diri' ||
        overallLabel == 'Siap Wawancara') {
      return '''
KESIMPULAN:
Performa wawancara Anda sudah sangat baik.

POIN UTAMA:
Kontak Mata: Fokus & Percaya Diri (2/2)
Ekspresi: Antusias & Profesional (2/2)
Postur: Tenang & Profesional (2/2)

REKOMENDASI:
1. Pertahankan kontak mata ke kamera
2. Jaga senyum natural saat menjawab
3. Pertahankan ritme bicara yang ideal

MOTIVASI:
Anda siap wawancara! Pertahankan ini.
''';
    } else if (overallLabel == 'Cukup Baik') {
      return '''
KESIMPULAN:
Performa cukup baik, masih bisa ditingkatkan.

POIN UTAMA:
Kontak Mata: Cukup Baik (1/2)
Ekspresi: Cukup Antusias (1/2)
Postur: Cukup Stabil (1/2)

REKOMENDASI:
1. Tatap kamera seperti menatap HRD
2. Tunjukkan 2-5 momen antusias
3. Duduk tegak dengan sandaran punggung

MOTIVASI:
Anda di jalur yang tepat! Terus latihan.
''';
    } else {
      return '''
KESIMPULAN:
Performa masih perlu banyak latihan.

POIN UTAMA:
Kontak Mata: Perlu Latihan (0-1/2)
Ekspresi: Perlu Latihan (0-1/2)
Postur: Perlu Latihan (0-1/2)

REKOMENDASI:
1. Latih kontak mata 5 menit per hari
2. Tunjukkan senyum natural 2-5 kali
3. Duduk tegak, kaki menapak lantai

MOTIVASI:
Jangan menyerah! Latihan rutin membantu.
''';
    }
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

  // ==================== RESET ====================

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
    overallLabel.value = '';
    confidenceMessage.value = '';

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

  // ===== BARU: Untuk detail analisis perilaku =====
  Future<String> getDetailedBehaviorAnalysis() async {
    final d = detect;

    final lookLeft = d.lookAwayLeftCount.value;
    final lookRight = d.lookAwayRightCount.value;
    final lookDown = d.lookDownCount.value;
    final totalEye = lookLeft + lookRight + lookDown;

    final smileTotal = d.smileCount.value;
    final neutralTotal = d.neutralCount.value;

    final headLeft = d.headTiltLeftCount.value;
    final headRight = d.headTiltRightCount.value;
    final headDown = d.headDownCount.value;
    final totalHead = headLeft + headRight + headDown;

    final eyePoints = d.getEyeContactPoints();
    final smilePoints = d.getFacialExpressionPoints();
    final posturePoints = d.getPosturePoints();
    final totalPoints = eyePoints + smilePoints + posturePoints;

    return await aiService.generateBehaviorDetailAnalysis(
      eyeLabel: eyeContactLabel.value,
      eyeViolations: totalEye,
      smileLabel: smileLabel.value,
      smileCount: smileTotal,
      neutralCount: neutralTotal,
      postureLabel: postureLabel.value,
      postureViolations: totalHead,
      totalPoints: totalPoints,
      maxPoints: 6,
      overallLabel: overallLabel.value,
      lookLeftCount: lookLeft,
      lookRightCount: lookRight,
      lookDownCount: lookDown,
      headTiltLeftCount: headLeft,
      headTiltRightCount: headRight,
      headDownCount: headDown,
      wpm: wordsPerMinute.value,
      fillerCount: fillerCount.value,
      totalWords: totalWordsSpoken.value,
      enthusiasmMoments: d.getEnthusiasmMomentCount(),
      smilePoints: smilePoints,
    );
  }
}
