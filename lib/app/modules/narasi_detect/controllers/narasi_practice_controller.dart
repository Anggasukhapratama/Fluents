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

  final wordsPerMinute = 0.obs;
  final fillerCount = 0.obs;
  final fluencyScore = 0.0.obs;
  DateTime? _sessionStart;
  DateTime? _lastSpeechAt;
  Timer? _silenceTimer;

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
      _isSessionSaved = false; // Reset flag saat mulai sesi baru
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

  final isAiProcessing = false.obs;
  final aiProcessingMessage = 'Sedang menganalisis hasil...'.obs;

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
    _finalizeFluency();

    if (goResult) {
      step.value = PracticeStep.result;
      // Tampilkan loading
      isAiProcessing.value = true;
      aiProcessingMessage.value =
          '⏳ AI sedang menganalisis hasil latihan Anda...';
    }

    await _generateAiRecommendation();

    // ==================== SIMPAN KE FIRESTORE ====================
    if (goResult && !_isSessionSaved) {
      await _saveSessionToFirestore();
      _isSessionSaved = true;
    }

    if (goResult) {
      isAiProcessing.value = false;
      aiProcessingMessage.value = '';
    }
  }

  /// Menyimpan sesi latihan ke Firestore
  Future<void> _saveSessionToFirestore() async {
    try {
      // Ekstrak suggestions dari AI recommendation
      final List<String> suggestions = _extractSuggestionsFromAI();

      // Buat DetectionResultModel
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

      // Buat session object
      final session = PracticeSession(
        createdAt: DateTime.now(),
        dateKey: DateFormat('yyyyMMdd').format(DateTime.now()),
        monthKey: DateFormat('yyyyMM').format(DateTime.now()),
        difficulty: _getLevelString(selectedLevel.value),
        scriptLineCount: scriptLines.length,
        wpm: wordsPerMinute.value,
        fluency: fluencyScore.value,
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

      // Simpan ke Firestore
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

  /// Ekstrak saran dari AI recommendation
  List<String> _extractSuggestionsFromAI() {
    final List<String> extracted = [];
    final text = aiRecommendation.value;

    // Cari bagian SARAN:
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

    // Fallback jika tidak ketemu
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
    // ==================== DATA MENTAH ====================
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

    // ==================== LABEL PER KATEGORI ====================
    final eyeLabelValue = detect.getEyeLevelLabel();
    final smileLabelValue = detect.getSmileLevelLabel();
    final postureLabelValue = detect.getPostureLevelLabel();

    // ==================== HITUNG POIN ====================
    final eyePoints = detect.getEyeContactPoints();
    final smilePoints = detect.getFacialExpressionPoints();
    final posturePoints = detect.getPosturePoints();
    final totalPoints = eyePoints + smilePoints + posturePoints;
    final maxPoints = 6;
    final hasZeroPoint =
        (eyePoints == 0 || smilePoints == 0 || posturePoints == 0);

    // ==================== OVERALL LABEL & MOTIVASI ====================
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

    // Update UI labels (Rx observer)
    eyeContactLabel.value = eyeLabelValue;
    smileLabel.value = smileLabelValue;
    postureLabel.value = postureLabelValue;
    overallLabel.value = overallLabelValue;
    confidenceMessage.value = motivationMessage;

    // ==================== BUAT RINCIAN POIN UNTUK TAMPILAN ====================
    String getPointEmoji(int points) {
      if (points == 2) return '✅';
      if (points == 1) return '⚠️';
      return '❌';
    }

    String getPointExplanationText(int points) {
      if (points == 2) return 'Sangat baik, pertahankan!';
      if (points == 1) return 'Cukup, masih bisa ditingkatkan';
      return 'Perlu banyak latihan lagi';
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

    // ==================== PROMPT KE AI ====================
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

    // ==================== PANGGIL AI ====================
    final recommendation = await aiService
        .generateRecommendationWithDetailedPrompt(detailedPrompt);

    // Bersihkan dari karakter aneh
    final cleanRecommendation = recommendation
        .replaceAll(RegExp(r'[*_\-]{3,}'), '')
        .replaceAll(RegExp(r'[*]{2,}'), '')
        .replaceAll('━', '')
        .replaceAll('─', '')
        .trim();

    // ==================== FULL RESULT (DENGAN RINCIAN POIN) ====================
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
   Kecepatan bicara: ${wordsPerMinute.value} WPM
   Kata pengisi: ${fillerCount.value} kali
   Kelancaran: ${fluencyScore.value.round()} poin

5. HASIL OVERALL
   Status: $overallLabelValue
   Total Poin: $totalPoints/$maxPoints
   $motivationMessage

$rincianPoin

REKOMENDASI AI:
$cleanRecommendation
''';

    // ==================== TAMPILKAN KE UI ====================
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

    // Hentikan semua timer
    _countdownTimer?.cancel();
    _answerTimer?.cancel();
    _silenceTimer?.cancel();
    _sttRestartTimer?.cancel();
    _faceWarningTimer?.cancel();

    // Hentikan TTS dan STT
    _stopTts();
    _stopSttHard();

    // Hentikan deteksi kamera jika sesi berjalan
    if (isSessionRunning.value) {
      isSessionRunning.value = false;
      detect.stop();
    }

    // Reset semua state
    _resetAll();

    // ✅ KEMBALI KE INSTRUCTIONS, BUKAN CHOOSE
    step.value = PracticeStep.instructions;

    print("Step setelah diubah: ${step.value}");
  }
}
