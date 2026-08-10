// lib/app/modules/profile/controllers/profile_controller.dart
import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluent_ai/app/services/practice_firestore_service.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../services/auth_service.dart';
import '../views/edit_profile_view.dart';
import '../../progress/controllers/progress_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

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

  // ===== PERUBAHAN: Kontak mata + ringkasan senyum terakhir =====
  final lastEyeContact = ''.obs;
  final lastEyeContactPct = 0.0.obs;
  final lastSmile = ''.obs; // label dominasi senyum terakhir
  final lastSmileCount = 0.obs;
  final totalSessions = 0.obs;
  final improvementNote = ''.obs;

  // ===== DATA DARI DASHBOARD =====
  final consecutiveDays = 0.obs;
  final currentLevel = 'Lv 1 • Beginner'.obs;
  final totalPoints = 0.obs;

  // Service
  final PracticeFirestoreService narasiFs = PracticeFirestoreService();

  // Workers
  Worker? _lastEyeContactWorker;
  Worker? _lastEyeContactPctWorker;
  Worker? _lastSmileWorker;
  Worker? _lastSmileCountWorker;
  Worker? _totalSessionsWorker;
  Worker? _improvementNoteWorker;

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
    _lastEyeContactWorker?.dispose();
    _lastEyeContactPctWorker?.dispose();
    _lastSmileWorker?.dispose();
    _lastSmileCountWorker?.dispose();
    _totalSessionsWorker?.dispose();
    _improvementNoteWorker?.dispose();
    _consecutiveDaysWorker?.dispose();
    _currentLevelWorker?.dispose();
    super.onClose();
  }

  String normalizeGenderToLower(String raw) {
    final g = raw.trim().toLowerCase();
    if (g == 'laki laki' || g == 'laki-laki' || g == 'pria') return 'laki-laki';
    if (g == 'perempuan' || g == 'wanita') return 'perempuan';
    if (g == 'lainnya' || g == 'other') return 'lainnya';
    return '';
  }

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

  void syncWithProgressController() {
    // Set nilai awal
    lastEyeContact.value = _progressCtrl.lastEyeContact.value;
    lastEyeContactPct.value = _progressCtrl.lastEyeContactPercentage.value;
    lastSmile.value = _progressCtrl.lastSmileLabel.value;
    lastSmileCount.value = _progressCtrl.lastSmileCount.value;
    totalSessions.value = _progressCtrl.totalSessions.value;
    improvementNote.value = _progressCtrl.improvementNote.value;

    _lastEyeContactWorker?.dispose();
    _lastEyeContactPctWorker?.dispose();
    _lastSmileWorker?.dispose();
    _lastSmileCountWorker?.dispose();
    _totalSessionsWorker?.dispose();
    _improvementNoteWorker?.dispose();

    _lastEyeContactWorker = ever(_progressCtrl.lastEyeContact, (label) {
      if (label != null && label.isNotEmpty) {
        lastEyeContact.value = label;
      }
    });

    // sink untuk persentase kontak mata terakhir
    _lastEyeContactPctWorker = ever(_progressCtrl.lastEyeContactPercentage, (pct) {
      if (pct != null) {
        lastEyeContactPct.value = (pct as num).toDouble();
      }
    });

    _lastSmileWorker = ever(_progressCtrl.lastSmileLabel, (label) {
      if (label != null) {
        lastSmile.value = label;
      }
    });

    _lastSmileCountWorker = ever(_progressCtrl.lastSmileCount, (count) {
      if (count != null) {
        lastSmileCount.value = count as int;
      }
    });

    _totalSessionsWorker = ever(_progressCtrl.totalSessions, (total) {
      if (total != null) {
        totalSessions.value = total;
      }
    });

    _improvementNoteWorker = ever(_progressCtrl.improvementNote, (note) {
      if (note != null && note.isNotEmpty) {
        improvementNote.value = note;
      }
    });
  }

  void syncWithDashboardController() {
    consecutiveDays.value = _dashboardCtrl.consecutiveDays.value;
    currentLevel.value = _dashboardCtrl.currentLevel.value;
    totalPoints.value = _dashboardCtrl.totalPoints.value;

    _consecutiveDaysWorker?.dispose();
    _currentLevelWorker?.dispose();

    _consecutiveDaysWorker = ever(_dashboardCtrl.consecutiveDays, (days) {
      if (days != null) {
        consecutiveDays.value = days;
      }
    });

    _currentLevelWorker = ever(_dashboardCtrl.currentLevel, (level) {
      if (level != null && level.isNotEmpty) {
        currentLevel.value = level;
      }
    });
  }

  Future<void> refreshProfileData() async {
    await _progressCtrl.refreshData();
    await loadProfileData();
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

  // ===== HELPER UNTUK UI =====
  Color getLabelColor(String label) {
    if (label.contains('Fokus terhadap Pewawancara') ||
        label.contains('Ideal')) {
      return const Color(0xFF10B981);
    }
    if (label.contains('Sesekali') || label.contains('Terlalu Lama')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFFEF4444);
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
