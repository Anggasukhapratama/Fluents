import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../services/auth_service.dart';
import '../views/edit_profile_view.dart';

import 'package:fluent_ai/app/services/practice_firestore_service.dart';
import 'package:fluent_ai/app/services/hrd_firestore_service.dart';

class ProfileController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // data profil
  final username = ''.obs;
  final email = ''.obs;
  final gender = ''.obs; // lowercase
  final occupation = ''.obs;

  // REAL progres
  final narasiAverageScore = 0.0.obs;
  final narasiTotalSessions = 0.obs;
  final hrdAverageScore = 0.0.obs;
  final hrdTotalSessions = 0.obs;

  // service
  final PracticeFirestoreService narasiFs = PracticeFirestoreService();
  final HrdFirestoreService hrdFs = HrdFirestoreService();

  // Menyimpan stream agar tidak terjadi memory leak saat halaman ditutup
  StreamSubscription? _narasiSub;
  StreamSubscription? _hrdSub;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  @override
  void onClose() {
    // Batalkan stream saat controller dihancurkan
    _narasiSub?.cancel();
    _hrdSub?.cancel();
    super.onClose();
  }

  // ===== Helpers =====
  String normalizeGenderToLower(String raw) {
    final g = raw.trim().toLowerCase();
    if (g == 'laki laki' || g == 'laki-laki' || g == 'pria') return 'laki-laki';
    if (g == 'perempuan' || g == 'wanita') return 'perempuan';
    if (g == 'lainnya' || g == 'other') return 'lainnya';
    return '';
  }

  String _dateKey(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<void> loadAll() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Tunggu data profil (nama, email, dll) selesai diambil
      await loadProfileData();

      // Mulai mendengarkan (listen) perubahan data progres
      loadProgressSummary(daysBack: 30);
    } catch (e) {
      errorMessage.value = 'Gagal memuat data profil';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadProfileData() async {
    final user = _auth.currentUser;
    if (user == null) {
      errorMessage.value = 'User belum login';
      return;
    }

    email.value = user.email ?? '';
    username.value = user.displayName ?? '';

    final snap = await _db.collection('users').doc(user.uid).get();
    if (snap.exists) {
      final data = snap.data()!;
      gender.value = normalizeGenderToLower((data['gender'] ?? '').toString());
      occupation.value = (data['desiredJob'] ?? '').toString();
    }
  }

  /// Hitung ringkasan progres dari Firestore dengan metode LISTEN (Realtime)
  void loadProgressSummary({int daysBack = 30}) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: daysBack - 1));

    final startKey = _dateKey(start);
    final endKey = _dateKey(now);

    // Cancel stream lama sebelum membuat yang baru (misal saat user tap refresh)
    _narasiSub?.cancel();
    _hrdSub?.cancel();

    // ===== Narasi =====
    _narasiSub = narasiFs
        .streamSessionsByDateKeyRange(
          startDateKey: startKey,
          endDateKey: endKey,
        )
        .listen(
          (snap) {
            final docs = snap.docs;
            narasiTotalSessions.value = docs.length;

            double sum = 0;
            for (final d in docs) {
              final m = d.data() as Map<String, dynamic>;
              // Pakai overallConfidence sesuai Progress Report
              sum += ((m['overallConfidence'] ?? 0) as num).toDouble();
            }
            narasiAverageScore.value = docs.isEmpty ? 0.0 : (sum / docs.length);
          },
          onError: (e) {
            print("Error ambil progres Narasi: $e");
          },
        );

    // ===== HRD =====
    _hrdSub = hrdFs
        .streamSessionsByDateKeyRange(
          startDateKey: startKey,
          endDateKey: endKey,
        )
        .listen(
          (snap) {
            final docs = snap.docs;
            hrdTotalSessions.value = docs.length;

            double sum = 0;
            for (final d in docs) {
              final m = d.data() as Map<String, dynamic>;
              // Pakai score untuk HRD
              sum += ((m['score'] ?? 0) as num).toDouble();
            }
            hrdAverageScore.value = docs.isEmpty ? 0.0 : (sum / docs.length);
          },
          onError: (e) {
            print("Error ambil progres HRD: $e");
          },
        );
  }

  Future<void> refreshProfileData() async => loadAll();

  void navigateToEditProfile() {
    Get.to(() => const EditProfileView());
  }

  Future<bool> updateProfile({
    required String newUsername,
    required String newGenderLabel,
    required String newOccupation,
  }) async {
    try {
      isLoading.value = true;

      final user = _auth.currentUser;
      if (user == null) return false;

      final normalizedGender = normalizeGenderToLower(newGenderLabel);

      await user.updateDisplayName(newUsername);

      await _db.collection('users').doc(user.uid).set({
        'username': newUsername,
        'gender': normalizedGender,
        'desiredJob': newOccupation,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      username.value = newUsername;
      gender.value = normalizedGender;
      occupation.value = newOccupation;

      return true;
    } catch (e) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // LOGOUT bersih
  Future<void> logout() async {
    final authService = Get.find<AuthService>();
    await authService.signOut();
    Get.offAllNamed(Routes.LOGIN);
  }
}
