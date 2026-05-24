import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluent_ai/app/models/cv_models.dart';
import 'package:fluent_ai/app/services/cv_ai_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class CvAnalysisController extends GetxController {
  final isLoadingList = true.obs;
  final isAnalyzing = false.obs;
  final errorText = ''.obs;

  final RxList<CvAiResult> results = <CvAiResult>[].obs;
  final Rxn<CvAiResult> selected = Rxn<CvAiResult>();

  // practice
  final isGeneratingQuestions = false.obs;
  final isSubmittingAnswer = false.obs;
  final RxInt activeQIndex = 0.obs;
  final RxList<CvPracticeTurn> turns = <CvPracticeTurn>[].obs;
  final Rxn<CvPracticeSummary> practiceSummary = Rxn<CvPracticeSummary>();

  final int maxPdfMb;
  final CvAiService _ai = CvAiService();

  CvAnalysisController({this.maxPdfMb = 3});

  CollectionReference<Map<String, dynamic>> _col(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cv_analysis');
  }

  @override
  void onInit() {
    super.onInit();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        results.clear();
        selected.value = null;
        errorText.value = 'Silakan login dulu untuk memakai Analisis CV AI.';
        isLoadingList.value = false;
        return;
      }
      errorText.value = '';
      _listen(user.uid);
    });
  }

  void _listen(String uid) {
    isLoadingList.value = true;

    _col(uid)
        .orderBy('createdAt', descending: true)
        .limit(40)
        .snapshots()
        .listen(
          (snap) {
            final list = snap.docs.map((d) => CvAiResult.fromDoc(d)).toList();
            results.assignAll(list);

            final sel = selected.value;
            if (sel != null) {
              try {
                selected.value = list.firstWhere((e) => e.id == sel.id);
              } catch (_) {}
            }

            isLoadingList.value = false;
          },
          onError: (e) {
            errorText.value = e.toString();
            isLoadingList.value = false;
          },
        );
  }

  // ===== PDF TEXT EXTRACT (Syncfusion) =====
  Future<String> _extractPdfText({String? path, Uint8List? bytes}) async {
    Uint8List data;

    if (bytes != null && bytes.isNotEmpty) {
      data = bytes;
    } else {
      if (path == null || path.isEmpty) return '';
      data = await File(path).readAsBytes();
    }

    final doc = PdfDocument(inputBytes: data);
    try {
      return PdfTextExtractor(doc).extractText();
    } finally {
      doc.dispose();
    }
  }

  Future<void> analyzePdfCv() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar(
        'Login dulu',
        'User belum login',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: kIsWeb,
    );
    if (pick == null || pick.files.isEmpty) return;

    final f = pick.files.single;

    final maxBytes = maxPdfMb * 1024 * 1024;
    if (f.size > maxBytes) {
      Get.snackbar(
        'Ukuran terlalu besar',
        'Max ${maxPdfMb}MB. File kamu ${(f.size / (1024 * 1024)).toStringAsFixed(2)}MB',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!kIsWeb && (f.path == null || f.path!.isEmpty)) {
      Get.snackbar(
        'Gagal',
        'Path file tidak tersedia. Jalankan di Android/iOS.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isAnalyzing.value = true;

    try {
      final docRef = _col(user.uid).doc();

      // init doc
      await docRef.set({
        'fileName': f.name,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'processing',
        'charCount': 0,
        'profile': CvProfile.empty().toMap(),
        'roleRec': CvRoleRecommendation.empty().toMap(),
        'questions': [],
        'errorMessage': '',
        'practicePointsAwarded': false,
      });

      final text = await _extractPdfText(path: f.path, bytes: f.bytes);
      final clean = text.trim();

      if (clean.isEmpty) {
        await docRef.update({
          'status': 'error',
          'errorMessage':
              'Gagal membaca isi PDF (text kosong / PDF berupa gambar).',
        });
        return;
      }

      // 1) parse profile
      final profile = await _ai.parseProfileFromCvText(clean);

      // 2) recommend role + reasons
      final roleRec = await _ai.recommendRole(profile: profile, cvText: clean);

      await docRef.update({
        'status': 'done',
        'charCount': clean.length,
        'profile': profile.toMap(),
        'roleRec': roleRec.toMap(),
        'errorMessage': '',
      });

      Get.snackbar(
        'Selesai',
        'CV berhasil diparsing + role cocok ditemukan ✅',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Gagal', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isAnalyzing.value = false;
    }
  }

  // ===== Practice flow =====
  Future<bool> startPractice(CvAiResult r) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar(
        'Login dulu',
        'User belum login',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    isGeneratingQuestions.value = true;
    practiceSummary.value = null;
    turns.clear();
    activeQIndex.value = 0;

    try {
      // kalau sudah ada 5 questions
      if (r.questions.length >= 5) {
        _initTurnsFromQuestions(r.questions);
        await _awardCvPracticePointsOnce(uid: user.uid, cvDocId: r.id);
        return true;
      }

      final qs = await _ai.build5Questions(
        profile: r.profile,
        roleRec: r.roleRec,
      );
      if (qs.length < 5)
        throw Exception('AI belum menghasilkan 5 pertanyaan. Coba ulang.');

      await _col(
        user.uid,
      ).doc(r.id).update({'questions': qs.map((e) => e.toMap()).toList()});

      // update selected snapshot
      selected.value = CvAiResult(
        id: r.id,
        fileName: r.fileName,
        status: r.status,
        createdAt: r.createdAt,
        charCount: r.charCount,
        profile: r.profile,
        roleRec: r.roleRec,
        questions: qs,
        errorMessage: r.errorMessage,
      );

      _initTurnsFromQuestions(qs);
      await _awardCvPracticePointsOnce(uid: user.uid, cvDocId: r.id);
      return true;
    } catch (e) {
      Get.snackbar('Gagal', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isGeneratingQuestions.value = false;
    }
  }

  void _initTurnsFromQuestions(List<CvQuestion> qs) {
    turns.assignAll(
      List.generate(
        qs.length,
        (i) => CvPracticeTurn(index: i, question: qs[i].q, answer: ''),
      ),
    );
  }

  Future<void> submitAnswerAndNext(String answer) async {
    final idx = activeQIndex.value;
    if (idx < 0 || idx >= turns.length) return;

    final a = answer.trim();
    if (a.isEmpty) {
      Get.snackbar(
        'Kosong',
        'Jawaban belum diisi',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmittingAnswer.value = true;
    try {
      final t = turns[idx];
      turns[idx] = CvPracticeTurn(
        index: t.index,
        question: t.question,
        answer: a,
      );
      turns.refresh();

      if (idx < turns.length - 1) {
        activeQIndex.value = idx + 1;
      } else {
        await _finishPractice();
      }
    } finally {
      isSubmittingAnswer.value = false;
    }
  }

  Future<void> _finishPractice() async {
    final r = selected.value;
    if (r == null) return;

    final sum = await _ai.gradePractice(
      profile: r.profile,
      roleRec: r.roleRec,
      turns: turns,
    );
    practiceSummary.value = sum;
    Get.snackbar(
      'Selesai',
      'Latihan selesai ✅',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _awardCvPracticePointsOnce({
    required String uid,
    required String cvDocId,
  }) async {
    final cvRef = _col(uid).doc(cvDocId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(cvRef);
      final data = snap.data() ?? {};
      final awarded = (data['practicePointsAwarded'] == true);
      if (awarded) return;

      // 1) mark awarded
      tx.update(cvRef, {'practicePointsAwarded': true});

      // 2) add points to user
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      tx.set(userRef, {
        'pointsTotal': FieldValue.increment(3),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3) add activity log
      final actRef = userRef.collection('activities').doc();
      tx.set(actRef, {
        'uid': uid,
        'title': 'Analisis CV • Mulai Latihan',
        'route': '/cv_analysis',
        'points': 3,
        'at': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  // ===== UI Helpers =====
  void open(CvAiResult r) => selected.value = r;

  Future<void> deleteResult(CvAiResult r) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _col(user.uid).doc(r.id).delete();
      if (selected.value?.id == r.id) selected.value = null;

      Get.snackbar(
        'Dihapus',
        'Data analisis berhasil dihapus',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Gagal', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
}
