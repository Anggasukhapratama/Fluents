// lib/app/modules/dashboard/controllers/dashboard_controller.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/notification_service.dart';
import '../../../routes/app_pages.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../progress/controllers/progress_controller.dart';

class ActivityItem {
  final String title;
  final String route;
  final int points;
  final DateTime at;

  ActivityItem({
    required this.title,
    required this.route,
    required this.points,
    required this.at,
  });

  Map<String, dynamic> toMap(String uid) => {
    'uid': uid,
    'title': title,
    'route': route,
    'points': points,
    'at': Timestamp.fromDate(at),
  };

  static ActivityItem fromMap(Map<String, dynamic> m) {
    final ts = m['at'];
    return ActivityItem(
      title: (m['title'] ?? '').toString(),
      route: (m['route'] ?? '').toString(),
      points: (m['points'] ?? 0) is int
          ? (m['points'] ?? 0) as int
          : ((m['points'] ?? 0) as num).toInt(),
      at: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

class DashboardController extends GetxController {
  final userName = 'User'.obs;
  final hasShownWelcomeMessage = false.obs;

  // ✅ Data dari ProgressController (sync otomatis)
  final bestLabel = ''.obs;
  final totalSessions = 0.obs;
  final improvementNote = ''.obs;

  /// streak absensi harian
  final consecutiveDays = 0.obs;

  // Gamification
  final totalPoints = 0.obs;
  final currentLevel = 'Lv 1 • Beginner'.obs;
  final pointsInCurrentLevel = 0.obs;
  final maxPointsForCurrentLevel = 1000.obs;
  final pointsNeededForNextLevelText = '1000 poin lagi'.obs;

  // Aktivitas terakhir
  final RxList<ActivityItem> recentActivities = <ActivityItem>[].obs;

  final homeScreenActions = <Map<String, dynamic>>[
    {
      'name': 'Latihan Narasi',
      'icon_name': 'book-open',
      'color_hex': '#7C3AED',
      'points': 5,
      'route': Routes.NARASI_DETECT,
    },
    {
      'name': 'Tanya HRD AI',
      'icon_name': 'agent',
      'color_hex': '#065F46',
      'points': 10,
      'route': Routes.ASK_HRD,
    },
    {
      'name': 'Lainnya',
      'icon_name': 'grid',
      'color_hex': '#0B1220',
      'points': 0,
      'route': Routes.MORE_FEATURES,
    },
  ];

  // Jadwal
  final nextSchedule = Rxn<Map<String, dynamic>>();
  final isLoadingSchedule = false.obs;

  static const _kLastSchedulePopupId = 'last_schedule_popup_id';
  Timer? _scheduleWatcher;

  // Streak (SharedPreferences)
  static const _kStreakCountPrefix = 'streak_count_';
  static const _kStreakLastDayPrefix = 'streak_last_day_';

  // Subscriptions
  StreamSubscription? _subActivities;
  StreamSubscription? _subUserDoc;

  // Workers untuk listen ke ProgressController (bukan StreamSubscription)
  Worker? _bestLabelWorker;
  Worker? _totalSessionsWorker;
  Worker? _improvementNoteWorker;

  // Referensi ke ProgressController
  ProgressController get _progressCtrl => Get.find<ProgressController>();

  @override
  void onInit() {
    super.onInit();
    loadUserName();
    loadNextSchedule();
    recordDailyCheckIn();
    listenUserPoints();
    listenRecentActivities();

    // ✅ Sync dengan ProgressController
    syncWithProgressController();

    _scheduleWatcher = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _tickScheduleWatcher();
    });
  }

  @override
  void onClose() {
    _scheduleWatcher?.cancel();
    _subActivities?.cancel();
    _subUserDoc?.cancel();

    // Dispose workers
    _bestLabelWorker?.dispose();
    _totalSessionsWorker?.dispose();
    _improvementNoteWorker?.dispose();

    super.onClose();
  }

  // ==================== SYNC WITH PROGRESS CONTROLLER ====================

  void syncWithProgressController() {
    // Set nilai awal
    bestLabel.value = _progressCtrl.bestLabel.value;
    totalSessions.value = _progressCtrl.totalSessions.value;
    improvementNote.value = _progressCtrl.improvementNote.value;

    // Hentikan worker lama jika ada
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

  // ======================= LEVELING =======================

  List<int> _levelThresholds() => [1000, 15000, 30000, 60000, 100000];

  int _levelFromPoints(int p) {
    final t = _levelThresholds();
    for (int i = 0; i < t.length; i++) {
      if (p < t[i]) return i + 1;
    }
    return t.length;
  }

  int _levelCap(int level) => _levelThresholds()[(level - 1).clamp(0, 4)];
  int _levelBase(int level) => level <= 1 ? 0 : _levelThresholds()[level - 2];

  String _levelName(int lvl) {
    switch (lvl) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Intermediate';
      case 3:
        return 'Advanced';
      case 4:
        return 'Expert';
      case 5:
        return 'Master';
      default:
        return 'Beginner';
    }
  }

  void _applyLevelUIFromPoints(int p) {
    final lvl = _levelFromPoints(p);
    final base = _levelBase(lvl);
    final cap = _levelCap(lvl);

    totalPoints.value = p;
    currentLevel.value = 'Lv $lvl • ${_levelName(lvl)}';

    pointsInCurrentLevel.value = (p - base).clamp(0, cap - base);
    maxPointsForCurrentLevel.value = (cap - base);

    final needed = (cap - p).clamp(0, 999999999);
    pointsNeededForNextLevelText.value = (lvl >= 5)
        ? 'MAX'
        : '$needed poin lagi';
  }

  void listenUserPoints() {
    _subUserDoc?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _subUserDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
          final data = doc.data() ?? {};
          final p = data['pointsTotal'] ?? 0;
          final points = p is int ? p : (p as num).toInt();
          _applyLevelUIFromPoints(points);
        }, onError: (_) {});
  }

  Future<void> addPointsAndLog({
    required String title,
    required String route,
    int points = 5,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await userRef.set({
      'pointsTotal': FieldValue.increment(points),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final act = ActivityItem(
      title: title,
      route: route,
      points: points,
      at: DateTime.now(),
    );
    await userRef.collection('activities').add(act.toMap(uid));
  }

  void listenRecentActivities() {
    _subActivities?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _subActivities = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .orderBy('at', descending: true)
        .limit(6)
        .snapshots()
        .listen((snap) {
          final list = snap.docs
              .map((d) => ActivityItem.fromMap(d.data()))
              .toList();
          recentActivities.assignAll(list);
        }, onError: (_) {});
  }

  // ======================= SCHEDULE WATCHER =======================

  Future<void> _tickScheduleWatcher() async {
    final sch = nextSchedule.value;
    if (sch == null) return;

    final dt = sch['scheduledAt'] as DateTime?;
    if (dt == null) return;

    final now = DateTime.now();
    if (!dt.isAfter(now)) {
      await maybeShowSchedulePopup();
      await loadNextSchedule();
    }
  }

  // ======================= USERNAME =======================

  Future<void> loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dn = (user.displayName ?? '').trim();
    if (dn.isNotEmpty) {
      userName.value = dn;
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (snap.exists) {
        final data = snap.data() ?? {};
        final u = (data['username'] ?? '').toString().trim();
        if (u.isNotEmpty) {
          userName.value = u;
          return;
        }
      }
    } catch (_) {}

    final email = user.email ?? '';
    if (email.contains('@')) userName.value = email.split('@').first;
  }

  Future<void> refreshDashboard() async {
    await loadUserName();
    await loadNextSchedule();
    await loadStreak();
    // Refresh ProgressController data
    await _progressCtrl.refreshData();
    // Update local values
    bestLabel.value = _progressCtrl.bestLabel.value;
    totalSessions.value = _progressCtrl.totalSessions.value;
    improvementNote.value = _progressCtrl.improvementNote.value;
  }

  // ======================= SCHEDULE CRUD =======================

  Future<void> saveInterviewSchedule({
    required DateTime scheduledAt,
    String note = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User belum login');

    final docRef = await FirebaseFirestore.instance
        .collection('interview_schedule')
        .add({
          'uid': user.uid,
          'scheduledAt': Timestamp.fromDate(scheduledAt),
          'note': note,
          'createdAt': FieldValue.serverTimestamp(),
        });

    try {
      await NotificationService.instance.scheduleTriple(
        scheduleId: docRef.id,
        at: scheduledAt,
        title: 'Waktunya Wawancara!',
        note: note.trim(),
      );
    } catch (_) {}

    await loadNextSchedule();
  }

  Future<void> deleteSchedule(String scheduleId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User belum login');

    final ref = FirebaseFirestore.instance
        .collection('interview_schedule')
        .doc(scheduleId);

    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data() ?? {};
    if ((data['uid'] ?? '') != user.uid) {
      throw Exception('Tidak punya akses menghapus jadwal ini');
    }

    await NotificationService.instance.cancelTriple(scheduleId);
    await ref.delete();
    await loadNextSchedule();
  }

  Future<void> loadNextSchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      isLoadingSchedule.value = true;

      final now = DateTime.now();
      final snap = await FirebaseFirestore.instance
          .collection('interview_schedule')
          .where('uid', isEqualTo: user.uid)
          .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('scheduledAt', descending: false)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        nextSchedule.value = null;
        return;
      }

      final doc = snap.docs.first;
      final data = doc.data();

      final ts = data['scheduledAt'];
      DateTime? dt;
      if (ts is Timestamp) dt = ts.toDate();

      nextSchedule.value = {
        'id': doc.id,
        'scheduledAt': dt,
        'note': (data['note'] ?? '').toString(),
      };

      await maybeShowSchedulePopup();
    } finally {
      isLoadingSchedule.value = false;
    }
  }

  Future<void> maybeShowSchedulePopup() async {
    final sch = nextSchedule.value;
    if (sch == null) return;

    final id = sch['id']?.toString() ?? '';
    final dt = sch['scheduledAt'] as DateTime?;
    if (id.isEmpty || dt == null) return;

    final now = DateTime.now();
    if (dt.isAfter(now)) return;

    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString(_kLastSchedulePopupId) ?? '';
    if (lastId == id) return;

    await prefs.setString(_kLastSchedulePopupId, id);

    Get.find<DashboardPopupBus>().showSchedulePopup(
      title: 'Waktunya Wawancara!',
      message: (sch['note']?.toString().trim().isNotEmpty ?? false)
          ? sch['note'].toString()
          : 'Ayo mulai latihan sekarang 🔥',
    );
  }

  // ===================== STREAK ABSENSI HARIAN =====================

  String _uidOrEmpty() => FirebaseAuth.instance.currentUser?.uid ?? '';

  String _dayKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  int _daysDiff(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  Future<void> recordDailyCheckIn() async {
    final uid = _uidOrEmpty();
    if (uid.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final countKey = '$_kStreakCountPrefix$uid';
    final lastKey = '$_kStreakLastDayPrefix$uid';

    final now = DateTime.now();
    final todayKey = _dayKey(now);

    final lastDay = prefs.getString(lastKey);
    int streak = prefs.getInt(countKey) ?? 0;

    if (lastDay == null) {
      streak = 1;
    } else if (lastDay == todayKey) {
      consecutiveDays.value = streak;
      return;
    } else {
      final lastDate = DateTime(
        int.parse(lastDay.substring(0, 4)),
        int.parse(lastDay.substring(4, 6)),
        int.parse(lastDay.substring(6, 8)),
      );

      final diff = _daysDiff(lastDate, now);

      if (diff == 1) {
        streak = (streak <= 0) ? 1 : (streak + 1);
      } else {
        streak = 1;
      }
    }

    await prefs.setInt(countKey, streak);
    await prefs.setString(lastKey, todayKey);

    consecutiveDays.value = streak;
  }

  Future<void> loadStreak() async {
    final uid = _uidOrEmpty();
    if (uid.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final countKey = '$_kStreakCountPrefix$uid';
    final lastKey = '$_kStreakLastDayPrefix$uid';

    final lastDay = prefs.getString(lastKey);
    final streak = prefs.getInt(countKey) ?? 0;

    if (lastDay == null) {
      consecutiveDays.value = 0;
      return;
    }

    final lastDate = DateTime(
      int.parse(lastDay.substring(0, 4)),
      int.parse(lastDay.substring(4, 6)),
      int.parse(lastDay.substring(6, 8)),
    );

    final now = DateTime.now();
    final diff = _daysDiff(lastDate, now);

    if (diff <= 1) {
      consecutiveDays.value = streak;
    } else {
      consecutiveDays.value = 0;
      await prefs.setInt(countKey, 0);
    }
  }
}

class DashboardPopupBus extends GetxService {
  void showSchedulePopup({required String title, required String message}) {
    _popupEvent.value = {
      'title': title,
      'message': message,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
  }

  final _popupEvent = Rxn<Map<String, dynamic>>();
  Rxn<Map<String, dynamic>> get popupEvent => _popupEvent;
}
