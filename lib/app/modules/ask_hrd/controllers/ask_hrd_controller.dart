import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluent_ai/app/services/hrd_ai_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:fluent_ai/app/modules/dashboard/controllers/dashboard_controller.dart';

class HrdMessage {
  final String role; // assistant | user
  final String type; // question | answer | feedback | info | summary | typing
  String content; // mutable untuk update streaming
  final int index; // ronde 1..5

  HrdMessage({
    required this.role,
    required this.type,
    required this.content,
    required this.index,
  });

  Map<String, dynamic> toMap() => {
    'role': role,
    'type': type,
    'content': content,
    'index': index,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class AskHrdController extends GetxController {
  // UI controllers
  final jobTargetCtrl = TextEditingController();
  final scrollCtrl = ScrollController();

  // State
  final isLoading = false.obs;
  final isSessionStarted = false.obs;
  final isFinished = false.obs;

  final isTyping = false.obs; // HRD sedang mengetik (streaming)
  final typingPreview = ''.obs; // teks yang lagi di-stream

  final questionIndex = 0.obs; // 0 sebelum mulai, 1..5 saat berjalan
  final sessionId = RxnString();

  // Chat
  final messages = <HrdMessage>[].obs;
  String _lastQuestion = '';

  // Skor per ronde
  final scores = <int, int>{}.obs; // index -> score (1..10)

  // Voice
  final isListening = false.obs;
  final liveTranscript = ''.obs;
  final _speech = stt.SpeechToText();

  // Firebase
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // AI
  final HrdAiService _ai = HrdAiService();

  StreamSubscription<String>? _typingSub;

  User? get _user => _auth.currentUser;

  @override
  void onInit() {
    super.onInit();

    // Auto-scroll tiap ada perubahan messages
    ever<List<HrdMessage>>(messages, (_) => _scrollToBottom());
  }

  @override
  void onClose() {
    _typingSub?.cancel();
    scrollCtrl.dispose();
    jobTargetCtrl.dispose();
    super.onClose();
  }

  void _scrollToBottom() {
    // kasih delay sedikit biar list sudah render
    Future.delayed(const Duration(milliseconds: 60), () {
      if (!scrollCtrl.hasClients) return;
      scrollCtrl.animateTo(
        scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> restartSession() async {
    // mark old session finished (optional)
    final sid = sessionId.value;
    if (sid != null) {
      try {
        await _db.collection('hrd_sessions').doc(sid).update({
          'status': 'finished',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    // reset state
    _typingSub?.cancel();
    isTyping.value = false;
    typingPreview.value = '';

    isLoading.value = false;
    isSessionStarted.value = false;
    isFinished.value = false;

    questionIndex.value = 0;
    sessionId.value = null;
    _lastQuestion = '';

    messages.clear();
    scores.clear();
    liveTranscript.value = '';

    // start baru (langsung)
    await startSession();
  }

  Future<void> startSession() async {
    final jobTarget = jobTargetCtrl.text.trim();
    if (jobTarget.isEmpty) {
      Get.snackbar('Oops', 'Isi dulu target kerja kamu');
      return;
    }
    if (_user == null) {
      Get.snackbar('Oops', 'Kamu harus login dulu');
      return;
    }

    isLoading.value = true;
    try {
      final doc = _db.collection('hrd_sessions').doc();
      sessionId.value = doc.id;

      await doc.set({
        'uid': _user!.uid,
        'status': 'active',
        'jobTarget': jobTarget,
        'questionIndex': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ TARUH DI SINI: tambah poin + catat aktivitas
      await _awardStartPoints();

      // placeholder typing message (akan diupdate streaming)
      isTyping.value = true;
      final typingMsg = HrdMessage(
        role: 'assistant',
        type: 'typing',
        content: 'HRD sedang mengetik…',
        index: 1,
      );
      messages.add(typingMsg);

      final (stream, resultF) = await _ai.startStream(jobTarget: jobTarget);

      _typingSub?.cancel();
      _typingSub = stream.listen((partial) {
        typingPreview.value = partial;
        messages.refresh();
      });

      final turn = await resultF;

      _typingSub?.cancel();
      isTyping.value = false;
      typingPreview.value = '';

      // HAPUS typing, lalu tambahkan question beneran
      messages.remove(typingMsg);

      questionIndex.value = 1;
      isSessionStarted.value = true;
      isFinished.value = false;

      _lastQuestion = turn.nextQuestion;

      await _addMessage(
        HrdMessage(
          role: 'assistant',
          type: 'question',
          content: _lastQuestion,
          index: 1,
        ),
      );

      await _addMessage(
        HrdMessage(
          role: 'assistant',
          type: 'info',
          content:
              'Tahan tombol mic untuk menjawab. Lepas untuk kirim jawaban.',
          index: 1,
        ),
      );
    } catch (e) {
      isTyping.value = false;
      typingPreview.value = '';
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _awardStartPoints() async {
    if (!Get.isRegistered<DashboardController>()) return;

    try {
      final dash = Get.find<DashboardController>();
      await dash.addPointsAndLog(
        title: 'Tanya HRD AI',
        route: Get.currentRoute, // biar tombol "Buka lagi" balik ke halaman ini
        points: 10,
      );
    } catch (_) {}
  }

  // ===== Voice (hold-to-talk) =====
  Future<void> startListening() async {
    if (!isSessionStarted.value || isFinished.value) return;
    if (isLoading.value || isTyping.value) return;

    final available = await _speech.initialize(
      onError: (e) => Get.snackbar('Voice error', e.errorMsg),
    );

    if (!available) {
      Get.snackbar('Oops', 'Speech recognition tidak tersedia di device ini');
      return;
    }

    liveTranscript.value = '';
    isListening.value = true;

    await _speech.listen(
      localeId: 'id_ID',
      listenMode: stt.ListenMode.confirmation,
      onResult: (result) => liveTranscript.value = result.recognizedWords,
    );
  }

  Future<void> stopListeningAndSend() async {
    if (!isListening.value) return;

    isListening.value = false;
    await _speech.stop();

    final text = liveTranscript.value.trim();
    if (text.isEmpty) {
      Get.snackbar('Info', 'Tidak ada suara terdeteksi');
      return;
    }
    await sendAnswer(text);
  }

  // ===== Chat logic =====
  Future<void> sendAnswer(String answerText) async {
    final sid = sessionId.value;
    if (sid == null) return;
    if (isFinished.value) return;

    final idx = questionIndex.value;
    if (idx < 1 || idx > 5) return;

    final jobTarget = jobTargetCtrl.text.trim();
    if (jobTarget.isEmpty) return;

    isLoading.value = true;
    try {
      // save user answer
      await _addMessage(
        HrdMessage(
          role: 'user',
          type: 'answer',
          content: answerText,
          index: idx,
        ),
      );

      // typing placeholder (feedback+question will come)
      isTyping.value = true;
      final typingMsg = HrdMessage(
        role: 'assistant',
        type: 'typing',
        content: 'HRD sedang mengetik…',
        index: idx,
      );
      messages.add(typingMsg);

      final (stream, resultF) = await _ai.nextStream(
        jobTarget: jobTarget,
        currentIndex: idx,
        lastQuestion: _lastQuestion,
        userAnswer: answerText,
      );

      _typingSub?.cancel();
      _typingSub = stream.listen((partial) {
        typingPreview.value =
            partial; // mentah (JSON) tapi cukup untuk indikator
        typingMsg.content = 'HRD sedang mengetik…';
        messages.refresh();
      });

      final turn = await resultF;

      _typingSub?.cancel();
      isTyping.value = false;
      typingPreview.value = '';

      // remove typing message, then add real messages (lebih rapi)
      messages.remove(typingMsg);

      // score untuk ronde ini
      scores[idx] = turn.score;

      await _addMessage(
        HrdMessage(
          role: 'assistant',
          type: 'feedback',
          content: '${turn.feedback}\n\nSkor ronde ini: ${turn.score}/10',
          index: idx,
        ),
      );

      if (idx >= 5 || turn.done == true) {
        isFinished.value = true;

        await _db.collection('hrd_sessions').doc(sid).update({
          'status': 'finished',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _addFinalSummary(jobTarget: jobTarget);

        return;
      }

      // next question
      final nextIdx = idx + 1;
      questionIndex.value = nextIdx;

      await _db.collection('hrd_sessions').doc(sid).update({
        'questionIndex': nextIdx,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _lastQuestion = turn.nextQuestion;

      await _addMessage(
        HrdMessage(
          role: 'assistant',
          type: 'question',
          content: _lastQuestion,
          index: nextIdx,
        ),
      );
    } catch (e) {
      isTyping.value = false;
      typingPreview.value = '';
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
      liveTranscript.value = '';
    }
  }

  Future<void> _addFinalSummary({required String jobTarget}) async {
    // total score 0..50
    final total = List.generate(
      5,
      (i) => scores[i + 1] ?? 0,
    ).fold<int>(0, (a, b) => a + b);

    // transcript ringkas untuk AI summary
    final transcript = <Map<String, dynamic>>[];
    for (int i = 1; i <= 5; i++) {
      final q =
          messages
              .lastWhereOrNull((m) => m.type == 'question' && m.index == i)
              ?.content ??
          '';
      final a =
          messages
              .lastWhereOrNull((m) => m.type == 'answer' && m.index == i)
              ?.content ??
          '';
      final f =
          messages
              .lastWhereOrNull((m) => m.type == 'feedback' && m.index == i)
              ?.content ??
          '';
      transcript.add({
        'index': i,
        'question': q,
        'answer': a,
        'feedback': f,
        'score': scores[i] ?? 0,
      });
    }

    // build summary (AI)
    HrdSummary? summary;
    try {
      summary = await _ai.buildSummary(
        jobTarget: jobTarget,
        transcript: transcript,
      );
    } catch (_) {
      summary = null;
    }

    final sb = StringBuffer();
    sb.writeln('✅ Interview selesai!');
    sb.writeln('Total skor: $total/50');

    if (summary != null) {
      if (summary.strengths.isNotEmpty) {
        sb.writeln('\nKelebihan:');
        for (final s in summary.strengths.take(4)) {
          sb.writeln('• $s');
        }
      }
      if (summary.improvements.isNotEmpty) {
        sb.writeln('\nYang perlu ditingkatkan:');
        for (final s in summary.improvements.take(4)) {
          sb.writeln('• $s');
        }
      }
      if (summary.recommendedMaterials.isNotEmpty) {
        sb.writeln('\nRekomendasi materi belajar:');
        for (final m in summary.recommendedMaterials.take(5)) {
          final title = m['title'] ?? '';
          final reason = m['reason'] ?? '';
          if (reason.trim().isEmpty) {
            sb.writeln('• $title');
          } else {
            sb.writeln('• $title — $reason');
          }
        }
      }
    } else {
      // fallback rekomendasi sederhana (tanpa AI)
      sb.writeln('\nRekomendasi materi belajar (fallback):');
      if (total <= 25) {
        sb.writeln('• STAR Method (struktur jawaban)');
        sb.writeln('• Latihan narasi: perkenalan diri & pengalaman proyek');
        sb.writeln('• Komunikasi: jawaban singkat, jelas, relevan');
      } else {
        sb.writeln('• Perkuat data/angka di jawaban (impact & metric)');
        sb.writeln('• Latihan pertanyaan behavioral lanjutan');
        sb.writeln('• Latihan penutup: “kenapa kami harus hire kamu?”');
      }
    }

    await _addMessage(
      HrdMessage(
        role: 'assistant',
        type: 'summary',
        content: sb.toString(),
        index: 5,
      ),
    );

    await _addMessage(
      HrdMessage(
        role: 'assistant',
        type: 'info',
        content: 'Kamu bisa tekan “Ulang sesi” untuk interview baru.',
        index: 5,
      ),
    );
  }

  Future<void> _addMessage(HrdMessage msg) async {
    messages.add(msg);
    await _saveMessageToFirestore(msg);
  }

  Future<void> _saveMessageToFirestore(HrdMessage msg) async {
    final sid = sessionId.value;
    if (sid == null) return;
    await _db
        .collection('hrd_sessions')
        .doc(sid)
        .collection('messages')
        .add(msg.toMap());
  }
}

extension _LastWhereOrNullExt<E> on List<E> {
  E? lastWhereOrNull(bool Function(E) test) {
    for (int i = length - 1; i >= 0; i--) {
      final v = this[i];
      if (test(v)) return v;
    }
    return null;
  }
}
