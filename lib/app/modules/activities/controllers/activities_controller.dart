import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

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

class ActivitiesController extends GetxController {
  final RxList<ActivityItem> activities = <ActivityItem>[].obs;
  final isLoading = false.obs;

  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    listenActivities();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void listenActivities() {
    _sub?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    isLoading.value = true;

    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .orderBy('at', descending: true)
        .limit(80) // ✅ halaman aktivitas biasanya lebih banyak dari dashboard
        .snapshots()
        .listen(
          (snap) {
            final list = snap.docs
                .map((d) => ActivityItem.fromMap(d.data()))
                .toList();
            activities.assignAll(list);
            isLoading.value = false;
          },
          onError: (_) {
            isLoading.value = false;
          },
        );
  }
}



