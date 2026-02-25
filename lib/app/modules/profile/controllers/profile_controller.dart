import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../services/auth_service.dart';
import '../views/edit_profile_view.dart';

// ✅ ambil dari service yang sudah kamu pakai di ProgressController
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

  // ✅ REAL progres (bukan dummy lagi)
  final narasiAverageScore = 0.0.obs;
  final narasiTotalSessions = 0.obs;
  final hrdAverageScore = 0.0.obs;
  final hrdTotalSessions = 0.obs;

  // ✅ service (sama seperti ProgressController)
  final PracticeFirestoreService narasiFs = PracticeFirestoreService();
  final HrdFirestoreService hrdFs = HrdFirestoreService();

  @override
  void onInit() {
    super.onInit();
    loadAll(); // ✅ load profile + progres
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

      await loadProfileData();
      await loadProgressSummary(daysBack: 30); // ✅ ringkasan real
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

  /// ✅ Hitung ringkasan progres dari Firestore
  /// - Narasi: average dari nervousScore
  /// - HRD: average dari score
  /// - totalSessions: jumlah dokumen sesi
  Future<void> loadProgressSummary({int daysBack = 30}) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: daysBack - 1));

    final startKey = _dateKey(start);
    final endKey = _dateKey(now);

    // ===== Narasi =====
    try {
      final narasiSnap = await narasiFs
          .streamSessionsByDateKeyRange(
            startDateKey: startKey,
            endDateKey: endKey,
          )
          .first;

      final docs = narasiSnap.docs;
      narasiTotalSessions.value = docs.length;

      double sum = 0;
      for (final d in docs) {
        final m = d.data();
        sum += ((m['nervousScore'] ?? 0) as num).toDouble();
      }
      narasiAverageScore.value = docs.isEmpty ? 0.0 : (sum / docs.length);
    } catch (_) {
      // kalau error, jangan crash
      narasiTotalSessions.value = 0;
      narasiAverageScore.value = 0.0;
    }

    // ===== HRD =====
    try {
      final hrdSnap = await hrdFs
          .streamSessionsByDateKeyRange(
            startDateKey: startKey,
            endDateKey: endKey,
          )
          .first;

      final docs = hrdSnap.docs;
      hrdTotalSessions.value = docs.length;

      double sum = 0;
      for (final d in docs) {
        final m = d.data();
        sum += ((m['score'] ?? 0) as num).toDouble();
      }
      hrdAverageScore.value = docs.isEmpty ? 0.0 : (sum / docs.length);
    } catch (_) {
      hrdTotalSessions.value = 0;
      hrdAverageScore.value = 0.0;
    }
  }

  Future<void> refreshProfileData() async => loadAll();

  // ✅ FULL PAGE EDIT
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

  // ✅ LOGOUT bersih (termasuk Google)
  Future<void> logout() async {
    final authService = Get.find<AuthService>();
    await authService.signOut();
    Get.offAllNamed(Routes.LOGIN);
  }

  void navigateToBPSStatisticsWeb() {
    Get.snackbar(
      'Info',
      'Fitur ini bisa diarahkan ke website BPS (dummy dulu)',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
