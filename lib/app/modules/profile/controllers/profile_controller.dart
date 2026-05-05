// lib/app/modules/profile/controllers/profile_controller.dart
import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluent_ai/app/services/hrd_firestore_service.dart';
import 'package:fluent_ai/app/services/practice_firestore_service.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../services/auth_service.dart';
import '../views/edit_profile_view.dart';
import '../../progress/controllers/progress_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart'; // ✅ Untuk akses streak & level

class ProfileController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // data profil
  final username = ''.obs;
  final email = ''.obs;
  final gender = ''.obs;
  final occupation = ''.obs;

  // ========== DATA DARI PROGRESS (Pengganti average score) ==========
  final bestLabel =
      ''.obs; // Siap Wawancara / Cukup Siap / Butuh Banyak Latihan
  final totalSessions = 0.obs; // Total sesi latihan
  final improvementNote = ''.obs; // Catatan peningkatan

  // ========== DATA DARI DASHBOARD (Untuk tampilan) ==========
  final consecutiveDays = 0.obs;
  final currentLevel = 'Lv 1 • Beginner'.obs;
  final totalPoints = 0.obs;

  // Service
  final PracticeFirestoreService narasiFs = PracticeFirestoreService();
  final HrdFirestoreService hrdFs = HrdFirestoreService();

  // Workers untuk listen ke ProgressController
  Worker? _bestLabelWorker;
  Worker? _totalSessionsWorker;
  Worker? _improvementNoteWorker;

  // Workers untuk listen ke DashboardController
  Worker? _consecutiveDaysWorker;
  Worker? _currentLevelWorker;

  ProgressController get _progressCtrl => Get.find<ProgressController>();
  DashboardController get _dashboardCtrl => Get.find<DashboardController>();

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  @override
  void onClose() {
    _bestLabelWorker?.dispose();
    _totalSessionsWorker?.dispose();
    _improvementNoteWorker?.dispose();
    _consecutiveDaysWorker?.dispose();
    _currentLevelWorker?.dispose();
    super.onClose();
  }

  // ==================== HELPERS ====================

  String normalizeGenderToLower(String raw) {
    final g = raw.trim().toLowerCase();
    if (g == 'laki laki' || g == 'laki-laki' || g == 'pria') return 'laki-laki';
    if (g == 'perempuan' || g == 'wanita') return 'perempuan';
    if (g == 'lainnya' || g == 'other') return 'lainnya';
    return '';
  }

  // ==================== LOAD DATA ====================

  Future<void> loadAll() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await loadProfileData();
      syncWithProgressController();
      syncWithDashboardController();
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

  // ==================== SYNC DENGAN PROGRESS CONTROLLER ====================

  void syncWithProgressController() {
    // Set nilai awal
    bestLabel.value = _progressCtrl.bestLabel.value;
    totalSessions.value = _progressCtrl.totalSessions.value;
    improvementNote.value = _progressCtrl.improvementNote.value;

    // Hentikan worker lama
    _bestLabelWorker?.dispose();
    _totalSessionsWorker?.dispose();
    _improvementNoteWorker?.dispose();

    // Listen perubahan bestLabel
    _bestLabelWorker = ever(_progressCtrl.bestLabel, (label) {
      if (label != null && label.isNotEmpty) {
        bestLabel.value = label;
      }
    });

    // Listen perubahan totalSessions
    _totalSessionsWorker = ever(_progressCtrl.totalSessions, (total) {
      if (total != null) {
        totalSessions.value = total;
      }
    });

    // Listen perubahan improvementNote
    _improvementNoteWorker = ever(_progressCtrl.improvementNote, (note) {
      if (note != null && note.isNotEmpty) {
        improvementNote.value = note;
      }
    });
  }

  // ==================== SYNC DENGAN DASHBOARD CONTROLLER ====================

  void syncWithDashboardController() {
    // Set nilai awal
    consecutiveDays.value = _dashboardCtrl.consecutiveDays.value;
    currentLevel.value = _dashboardCtrl.currentLevel.value;
    totalPoints.value = _dashboardCtrl.totalPoints.value;

    // Hentikan worker lama
    _consecutiveDaysWorker?.dispose();
    _currentLevelWorker?.dispose();

    // Listen perubahan consecutiveDays
    _consecutiveDaysWorker = ever(_dashboardCtrl.consecutiveDays, (days) {
      if (days != null) {
        consecutiveDays.value = days;
      }
    });

    // Listen perubahan currentLevel
    _currentLevelWorker = ever(_dashboardCtrl.currentLevel, (level) {
      if (level != null && level.isNotEmpty) {
        currentLevel.value = level;
      }
    });
  }

  // ==================== PUBLIC METHODS ====================

  Future<void> refreshProfileData() async {
    await _progressCtrl.refreshData(); // Refresh ProgressController dulu
    await loadProfileData(); // Refresh profile data
    // Nilai bestLabel dll akan otomatis update karena sync
  }

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

  Future<void> logout() async {
    final authService = Get.find<AuthService>();
    await authService.signOut();
    Get.offAllNamed(Routes.LOGIN);
  }

  // ==================== HELPER UNTUK UI ====================

  String getShortLabel(String label) {
    switch (label) {
      case 'Siap Wawancara':
        return 'Siap';
      case 'Cukup Siap':
        return 'Cukup';
      case 'Butuh Banyak Latihan':
        return 'Butuh';
      default:
        return label;
    }
  }

  Color getLabelColor(String label) {
    switch (label) {
      case 'Siap Wawancara':
        return const Color(0xFF10B981); // Hijau
      case 'Cukup Siap':
        return const Color(0xFFF59E0B); // Oranye
      case 'Butuh Banyak Latihan':
        return const Color(0xFFEF4444); // Merah
      default:
        return const Color(0xFF64748B);
    }
  }

  String getLevelDisplayName() {
    final level = currentLevel.value;
    if (level.contains('•')) {
      return level.split('•').first.trim();
    }
    return level;
  }

  String getStreakText() {
    final days = consecutiveDays.value;
    if (days == 0) return 'Mulai Hari Ini';
    if (days == 1) return '1 Hari';
    return '$days Hari';
  }
}
