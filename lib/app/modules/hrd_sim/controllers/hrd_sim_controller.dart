import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluent_ai/app/models/hrd_question.dart';
import 'package:fluent_ai/app/services/hrd_firestore_service.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../dashboard/controllers/dashboard_controller.dart';

enum HrdStep { intro, countdown, playing, result }

enum HrdMood { veryHappy, happy, neutral, bored, angry }

class HrdSimController extends GetxController {
  // ===== Config =====
  static const int totalQuestions = 5;
  static const int secondsPerQuestion = 15;

  // ===== Services =====
  final HrdFirestoreService hrdFs = HrdFirestoreService();

  // ===== Flow =====
  final step = HrdStep.intro.obs;

  // Countdown
  final countdown = 3.obs;
  Timer? _countdownTimer;

  // Playing
  final questions = <HrdQuestion>[].obs;
  final currentIndex = 0.obs;
  final secondsLeft = secondsPerQuestion.obs;

  // STT buffers
  final recognizedLive = ''.obs;
  final sttConfidence = 0.0.obs;
  final isSessionRunning = false.obs;
  final isListening = false.obs;

  // Button control
  final isRecording = false.obs;
  Timer? _recordingTimer;
  final recordingSeconds = 0.obs;

  // commit delta per question
  String _lastCommittedText = '';

  // Mood
  final mood = HrdMood.neutral.obs;
  DateTime _lastSpeechAt = DateTime.now();

  // Score per question
  final RxList<int> questionScores = <int>[].obs;
  final RxList<String> questionAnswers = <String>[].obs;
  final RxList<int> keywordHits = <int>[].obs;
  final RxList<int> fillerCounts = <int>[].obs;
  final RxList<int> wordCounts = <int>[].obs;

  // Result
  final finalScore = 0.obs;
  final earnedPoints = 0.obs;
  final feedback = <String>[].obs;

  // transcript gabungan untuk UI
  final recognizedFinal = ''.obs;

  // Timers
  Timer? _qTimer;
  Timer? _moodTimer;

  // STT
  final stt.SpeechToText sttEngine = stt.SpeechToText();
  bool _sttReady = false;

  @override
  void onInit() {
    super.onInit();
    _initStt();
  }

  @override
  void onClose() {
    _stopAllTimers();
    _stopStt();
    super.onClose();
  }

  // ================= STT INIT =================
  Future<void> _initStt() async {
    try {
      _sttReady = await sttEngine.initialize(
        onStatus: (status) {
          isListening.value = (status == 'listening');
        },
        onError: (e) {
          final msg = e.errorMsg.toLowerCase();
          final isSoft =
              msg.contains('no match') ||
              msg.contains('timeout') ||
              msg.contains('speech') ||
              msg.contains('error_no_match');

          if (!isSoft && !msg.contains('cancel')) {
            Get.snackbar('STT Error', e.errorMsg);
          }
        },
      );
    } catch (_) {
      _sttReady = false;
    }
  }

  // ================= ACTIONS =================
  void start() {
    _resetAll();
    _pickRandomQuestions();

    countdown.value = 3;
    step.value = HrdStep.countdown;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown.value > 1) {
        countdown.value--;
      } else {
        t.cancel();
        countdown.value = 0;
        _startPlaying();
      }
    });
  }

  void backToIntro() async {
    await _stopAll();
    step.value = HrdStep.intro;
  }

  void stopEarlyToResult() async {
    await _stopAll();
    await _finalizeAndSave();
    step.value = HrdStep.result;
  }

  // ================= RECORDING CONTROLS =================
  Future<void> startRecording() async {
    if (!_sttReady || !sttEngine.isAvailable || !isSessionRunning.value) {
      return;
    }

    isRecording.value = true;
    recordingSeconds.value = 0;

    // Start recording timer
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      recordingSeconds.value++;

      // Auto stop after 10 seconds
      if (recordingSeconds.value >= 10) {
        stopRecording();
        timer.cancel();
      }
    });

    try {
      await sttEngine.listen(
        localeId: 'id_ID',
        partialResults: true,
        onResult: (r) {
          sttConfidence.value = r.confidence;

          final text = r.recognizedWords.trim();
          if (text.isNotEmpty) {
            recognizedLive.value = text;
            _lastSpeechAt = DateTime.now();
          }

          _updateMoodRealtime();
        },
      );
    } catch (_) {
      isRecording.value = false;
      Get.snackbar('Error', 'Gagal memulai rekaman');
    }
  }

  Future<void> stopRecording() async {
    isRecording.value = false;
    _recordingTimer?.cancel();
    recordingSeconds.value = 0;

    try {
      await sttEngine.stop();
    } catch (_) {}
  }

  // ================= INTERNALS =================
  void _resetAll() {
    questionScores.clear();
    questionAnswers.clear();
    keywordHits.clear();
    fillerCounts.clear();
    wordCounts.clear();
    feedback.clear();

    finalScore.value = 0;
    earnedPoints.value = 0;

    recognizedLive.value = '';
    recognizedFinal.value = '';
    sttConfidence.value = 0;

    mood.value = HrdMood.neutral;
    _lastCommittedText = '';
    _lastSpeechAt = DateTime.now();

    currentIndex.value = 0;
    secondsLeft.value = secondsPerQuestion;

    isSessionRunning.value = false;
    isListening.value = false;
    isRecording.value = false;
    recordingSeconds.value = 0;

    _recordingTimer?.cancel();
  }

  void _pickRandomQuestions() {
    final list = List<HrdQuestion>.from(bank);
    list.shuffle(Random());
    questions.assignAll(list.take(totalQuestions));
  }

  HrdQuestion get currentQuestion => questions[currentIndex.value];

  Future<void> _startPlaying() async {
    step.value = HrdStep.playing;
    isSessionRunning.value = true;

    currentIndex.value = 0;
    secondsLeft.value = secondsPerQuestion;
    recognizedLive.value = '';
    _lastCommittedText = '';
    _lastSpeechAt = DateTime.now();

    _startQuestionTimer();
    _startMoodWatcher();
  }

  void _startQuestionTimer() {
    _qTimer?.cancel();
    _qTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!isSessionRunning.value || step.value != HrdStep.playing) {
        t.cancel();
        return;
      }

      if (secondsLeft.value > 1) {
        secondsLeft.value--;
        return;
      }

      secondsLeft.value = 0;
      _commitCurrentAnswer();

      if (currentIndex.value < totalQuestions - 1) {
        currentIndex.value++;
        secondsLeft.value = secondsPerQuestion;

        // reset per question
        recognizedLive.value = '';
        _lastCommittedText = '';
        _lastSpeechAt = DateTime.now();
        isRecording.value = false;
        recordingSeconds.value = 0;

        // Stop any ongoing recording
        await stopRecording();
      } else {
        t.cancel();
        await _stopAll();
        await _finalizeAndSave();
        step.value = HrdStep.result;
      }
    });
  }

  void _startMoodWatcher() {
    _moodTimer?.cancel();
    _moodTimer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (!isSessionRunning.value || step.value != HrdStep.playing) {
        t.cancel();
        return;
      }
      _updateMoodRealtime();
    });
  }

  void _commitCurrentAnswer() {
    final full = recognizedLive.value.trim();

    // delta text per question
    String delta = full;
    if (_lastCommittedText.isNotEmpty && full.startsWith(_lastCommittedText)) {
      delta = full.substring(_lastCommittedText.length).trim();
    }
    _lastCommittedText = full;

    final ans = delta.trim();
    questionAnswers.add(ans);

    final res = _scoreAnswer(ans, currentQuestion.keywords);
    questionScores.add(res.score);
    keywordHits.add(res.hit);
    fillerCounts.add(res.filler);
    wordCounts.add(res.wordCount);

    final qa =
        'Q${currentIndex.value + 1}: ${currentQuestion.question}\n'
        'A: ${ans.isEmpty ? "-" : ans}';
    recognizedFinal.value = recognizedFinal.value.isEmpty
        ? qa
        : '${recognizedFinal.value}\n\n$qa';
  }

  _ScoreResult _scoreAnswer(String answer, List<String> keywords) {
    final a = answer.toLowerCase();

    int hit = 0;
    final missed = <String>[];
    for (final k in keywords) {
      if (k.trim().isEmpty) continue;
      final kl = k.toLowerCase();
      if (a.contains(kl)) {
        hit++;
      } else {
        missed.add(k);
      }
    }

    final words = a.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty);
    final wList = words.toList();
    final fillerCount = wList.where((w) => filler.contains(w.trim())).length;

    final silence = answer.trim().isEmpty;
    final hitRatio = keywords.isEmpty ? 0.0 : hit / keywords.length;

    double score = hitRatio * 60.0;

    final wc = wList.length;
    if (wc >= 18 && wc <= 55) {
      score += 25;
    } else if (wc >= 10) {
      score += 18;
    } else if (wc >= 5) {
      score += 10;
    } else {
      score += 4;
    }

    score -= min(15.0, fillerCount * 3.0);
    if (silence) score -= 20.0;

    if (sttConfidence.value >= 0.75) score += 3;

    return _ScoreResult(
      score: score.clamp(0.0, 100.0).round(),
      hit: hit,
      filler: fillerCount,
      wordCount: wc,
      missedKeywords: missed,
    );
  }

  Future<void> _finalizeAndSave() async {
    if (questionScores.isEmpty) {
      finalScore.value = 0;
    } else {
      finalScore.value =
          (questionScores.reduce((a, b) => a + b) / questionScores.length)
              .round();
    }

    feedback.assignAll(_buildPersonalFeedback());

    final totalHit = keywordHits.isEmpty
        ? 0
        : keywordHits.reduce((a, b) => a + b);
    final bonusFromScore = (finalScore.value / 10).round().clamp(0, 10);
    final bonusFromHit = totalHit.clamp(0, 10);
    final totalFiller = fillerCounts.isEmpty
        ? 0
        : fillerCounts.reduce((a, b) => a + b);
    final penalty = (totalFiller / 3).floor().clamp(0, 5);

    final pts = (10 + bonusFromScore + bonusFromHit - penalty).clamp(5, 30);
    earnedPoints.value = pts;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final now = DateTime.now();
        final mm = now.month.toString().padLeft(2, '0');
        final dd = now.day.toString().padLeft(2, '0');
        final dateKey = '${now.year}-$mm-$dd';
        final monthKey = '${now.year}-$mm';
        final wk = _weekKey(now);

        final details = <Map<String, dynamic>>[];
        for (
          int i = 0;
          i < questions.length && i < questionAnswers.length;
          i++
        ) {
          details.add({
            'qId': questions[i].id,
            'question': questions[i].question,
            'answer': questionAnswers[i],
            'score': (i < questionScores.length) ? questionScores[i] : 0,
            'hit': (i < keywordHits.length) ? keywordHits[i] : 0,
            'filler': (i < fillerCounts.length) ? fillerCounts[i] : 0,
            'wordCount': (i < wordCounts.length) ? wordCounts[i] : 0,
            'keywords': questions[i].keywords,
          });
        }

        await hrdFs.saveSession(
          createdAt: now,
          dateKey: dateKey,
          monthKey: monthKey,
          weekKey: wk,
          score: finalScore.value,
          points: earnedPoints.value,
          scores: questionScores.toList(),
          hits: keywordHits.toList(),
          answers: questionAnswers.toList(),
          details: details,
          feedback: feedback.toList(),
        );
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<DashboardController>()) {
        await Get.find<DashboardController>().addPointsAndLog(
          title: 'Simulasi HRD',
          route: '/hrd',
          points: earnedPoints.value,
        );
      }
    } catch (_) {}
  }

  List<String> _buildPersonalFeedback() {
    final tips = <String>[];

    final avg = finalScore.value;
    final totalHit = keywordHits.isEmpty
        ? 0
        : keywordHits.reduce((a, b) => a + b);
    final totalFiller = fillerCounts.isEmpty
        ? 0
        : fillerCounts.reduce((a, b) => a + b);
    final avgWords = wordCounts.isEmpty
        ? 0.0
        : (wordCounts.reduce((a, b) => a + b) / wordCounts.length);

    if (avg >= 80) {
      tips.add(
        '✅ Overall bagus: jawaban cenderung relevan & cukup terstruktur.',
      );
    } else if (avg >= 60) {
      tips.add(
        '🟡 Overall lumayan: beberapa jawaban sudah kena keyword, tapi masih naik-turun.',
      );
    } else {
      tips.add(
        '🔴 Overall masih perlu latihan: banyak jawaban belum "nempel" ke keyword inti.',
      );
    }

    tips.add(
      '📌 Total keyword hit: $totalHit (dari ${totalQuestions * 3} target kira-kira).',
    );
    if (totalFiller >= 6) {
      tips.add(
        '🗣️ Filler kamu cukup sering ($totalFiller). Coba ganti filler dengan jeda 0.5-1 detik.',
      );
    } else {
      tips.add(
        '🎤 Filler relatif aman ($totalFiller). Tinggal konsistensi aja.',
      );
    }

    if (avgWords < 8) {
      tips.add(
        '⏱️ Jawaban cenderung terlalu pendek (rata-rata ${avgWords.toStringAsFixed(0)} kata). Tambah contoh + hasil.',
      );
    } else if (avgWords > 70) {
      tips.add(
        '📏 Jawaban cenderung kepanjangan (rata-rata ${avgWords.toStringAsFixed(0)} kata). Ringkas: poin → contoh → hasil.',
      );
    } else {
      tips.add(
        '📏 Panjang jawaban cukup ideal (rata-rata ${avgWords.toStringAsFixed(0)} kata).',
      );
    }

    final weakest = <Map<String, dynamic>>[];
    for (int i = 0; i < questions.length; i++) {
      final s = (i < questionScores.length) ? questionScores[i] : 0;
      weakest.add({'i': i, 'score': s});
    }
    weakest.sort((a, b) => (a['score'] as int).compareTo(b['score'] as int));
    final w0 = weakest.isNotEmpty ? weakest.first : null;

    if (w0 != null) {
      final i = w0['i'] as int;
      final q = questions[i];
      final ans = (i < questionAnswers.length) ? questionAnswers[i] : '';
      final res = _scoreAnswer(ans, q.keywords);

      final missed = res.missedKeywords.take(3).toList();
      if (missed.isNotEmpty) {
        tips.add('🧩 Paling perlu dibenerin: Q${i + 1} "${q.question}"');
        tips.add('   Coba sebut minimal 2 keyword ini: ${missed.join(", ")}.');
        tips.add(
          '   Format cepat: Situasi → Aksi → Hasil (1 kalimat tiap bagian).',
        );
      }
    }

    tips.add(
      '⚡ Tips cepat: sebut 1 skill + 1 contoh nyata + 1 hasil terukur untuk tiap jawaban.',
    );
    return tips;
  }

  void _updateMoodRealtime() {
    final ans = recognizedLive.value.trim().toLowerCase();
    final silenceMs = DateTime.now().difference(_lastSpeechAt).inMilliseconds;

    if (ans.isEmpty && silenceMs > 2500) {
      mood.value = HrdMood.bored;
      return;
    }

    final words = ans.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty);
    final fillerCount = words.where((w) => filler.contains(w.trim())).length;

    if (fillerCount >= 5) {
      mood.value = HrdMood.angry;
      return;
    }

    int hit = 0;
    for (final k in currentQuestion.keywords) {
      if (k.trim().isEmpty) continue;
      if (ans.contains(k.toLowerCase())) hit++;
    }

    if (hit >= 3) {
      mood.value = HrdMood.veryHappy;
    } else if (hit >= 2) {
      mood.value = HrdMood.happy;
    } else if (hit >= 1) {
      mood.value = HrdMood.neutral;
    } else {
      if (secondsLeft.value <= 3 && ans.isNotEmpty) {
        mood.value = HrdMood.angry;
      } else {
        mood.value = HrdMood.neutral;
      }
    }
  }

  Future<void> _stopAll() async {
    isSessionRunning.value = false;
    _stopAllTimers();
    await _stopStt();
    await stopRecording();
  }

  void _stopAllTimers() {
    _countdownTimer?.cancel();
    _qTimer?.cancel();
    _moodTimer?.cancel();
    _recordingTimer?.cancel();
  }

  Future<void> _stopStt() async {
    try {
      await sttEngine.stop();
    } catch (_) {}
  }

  // ===== Helpers =====
  String _weekKey(DateTime d) {
    final monday = d.subtract(Duration(days: (d.weekday - DateTime.monday)));
    final year = monday.year;

    DateTime firstMondayOfYear(int y) {
      final jan1 = DateTime(y, 1, 1);
      final shift = (DateTime.monday - jan1.weekday) % 7;
      return jan1.add(Duration(days: shift));
    }

    final firstMonday = firstMondayOfYear(year);
    final diffDays = monday.difference(firstMonday).inDays;
    final weekNum = (diffDays ~/ 7) + 1;
    return '$year-W${weekNum.toString().padLeft(2, '0')}';
  }

  // UI helpers
  String moodEmoji(HrdMood m) {
    switch (m) {
      case HrdMood.veryHappy:
        return '😄';
      case HrdMood.happy:
        return '😊';
      case HrdMood.neutral:
        return '😐';
      case HrdMood.bored:
        return '😴';
      case HrdMood.angry:
        return '😠';
    }
  }

  String moodLabel(HrdMood m) {
    switch (m) {
      case HrdMood.veryHappy:
        return 'Senang sekali';
      case HrdMood.happy:
        return 'Senang';
      case HrdMood.neutral:
        return 'Netral';
      case HrdMood.bored:
        return 'Bosan';
      case HrdMood.angry:
        return 'Kesal';
    }
  }

  // ===== Question bank =====
  final List<HrdQuestion> bank = const [
    HrdQuestion(
      id: 'q1',
      question: 'Ceritakan tentang diri kamu secara singkat.',
      keywords: ['saya', 'pengalaman', 'skill'],
    ),
    HrdQuestion(
      id: 'q2',
      question: 'Apa kelebihan utama kamu?',
      keywords: ['kelebihan', 'belajar', 'disiplin'],
    ),
    HrdQuestion(
      id: 'q3',
      question: 'Apa kekurangan kamu dan bagaimana mengatasinya?',
      keywords: ['kekurangan', 'perbaiki', 'belajar'],
    ),
    HrdQuestion(
      id: 'q4',
      question: 'Kenapa kamu ingin bekerja di perusahaan ini?',
      keywords: ['tertarik', 'kontribusi', 'nilai'],
    ),
    HrdQuestion(
      id: 'q5',
      question: 'Apa pengalaman teamwork yang pernah kamu lakukan?',
      keywords: ['tim', 'kolaborasi', 'komunikasi'],
    ),
    HrdQuestion(
      id: 'q6',
      question: 'Bagaimana kamu menghadapi tekanan deadline?',
      keywords: ['deadline', 'prioritas', 'rencana'],
    ),
    HrdQuestion(
      id: 'q7',
      question: 'Ceritakan konflik di tim dan cara kamu menyelesaikannya.',
      keywords: ['konflik', 'solusi', 'komunikasi'],
    ),
    HrdQuestion(
      id: 'q8',
      question: 'Apa pencapaian yang paling kamu banggakan?',
      keywords: ['pencapaian', 'hasil', 'target'],
    ),
    HrdQuestion(
      id: 'q9',
      question: 'Bagaimana kamu belajar hal baru dengan cepat?',
      keywords: ['belajar', 'latihan', 'konsisten'],
    ),
    HrdQuestion(
      id: 'q10',
      question: 'Apa alasan kamu resign/ingin pindah?',
      keywords: ['tujuan', 'pengembangan', 'karier'],
    ),
    HrdQuestion(
      id: 'q11',
      question: 'Berapa ekspektasi gaji kamu?',
      keywords: ['sesuai', 'negosiasi', 'tanggung'],
    ),
    HrdQuestion(
      id: 'q12',
      question: 'Apa yang kamu lakukan jika melakukan kesalahan kerja?',
      keywords: ['tanggung', 'evaluasi', 'perbaiki'],
    ),
    HrdQuestion(
      id: 'q13',
      question: 'Apa target karier kamu dalam 1-2 tahun?',
      keywords: ['target', 'belajar', 'naik'],
    ),
    HrdQuestion(
      id: 'q14',
      question: 'Bagaimana cara kamu mengatur waktu dan prioritas?',
      keywords: ['prioritas', 'jadwal', 'fokus'],
    ),
    HrdQuestion(
      id: 'q15',
      question: 'Ceritakan proyek yang pernah kamu kerjakan.',
      keywords: ['proyek', 'peran', 'hasil'],
    ),
    HrdQuestion(
      id: 'q16',
      question: 'Apa yang kamu lakukan jika tidak paham tugas?',
      keywords: ['bertanya', 'klarifikasi', 'belajar'],
    ),
    HrdQuestion(
      id: 'q17',
      question: 'Bagaimana kamu berkomunikasi dengan atasan?',
      keywords: ['komunikasi', 'laporan', 'jelas'],
    ),
    HrdQuestion(
      id: 'q18',
      question: 'Apa motivasi kamu bekerja?',
      keywords: ['motivasi', 'berkembang', 'kontribusi'],
    ),
    HrdQuestion(
      id: 'q19',
      question: 'Bagaimana kamu menghadapi kritik?',
      keywords: ['kritik', 'evaluasi', 'perbaiki'],
    ),
    HrdQuestion(
      id: 'q20',
      question: 'Kenapa kami harus memilih kamu?',
      keywords: ['nilai', 'kontribusi', 'hasil'],
    ),
  ];

  final Set<String> filler = const {
    'hmm',
    'emm',
    'em',
    'uh',
    'umm',
    'anu',
    'eh',
    'eee',
    'jadi',
    'kayak',
    'gitu',
    'apa',
    'ya',
    'sih',
  };
}

class _ScoreResult {
  final int score;
  final int hit;
  final int filler;
  final int wordCount;
  final List<String> missedKeywords;

  _ScoreResult({
    required this.score,
    required this.hit,
    required this.filler,
    required this.wordCount,
    required this.missedKeywords,
  });
}
