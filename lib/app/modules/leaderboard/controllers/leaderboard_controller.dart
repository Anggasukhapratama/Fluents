import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class LeaderboardUser {
  final String uid;
  final String name;
  final String email;
  final String gender;
  final String job;
  final int pointsTotal;
  final String? photoUrl;

  LeaderboardUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.gender,
    required this.job,
    required this.pointsTotal,
    this.photoUrl,
  });

  factory LeaderboardUser.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};

    return LeaderboardUser(
      uid: doc.id,
      name: (m['username'] ?? m['name'] ?? 'User').toString(),
      email: (m['email'] ?? '').toString(),
      gender: (m['gender'] ?? '-').toString(),
      job: (m['desiredJob'] ?? m['occupation'] ?? '-').toString(),
      pointsTotal: ((m['pointsTotal'] ?? 0) as num).toInt(),
      photoUrl: m['photoUrl']?.toString(),
    );
  }
}

class LeaderboardController extends GetxController {
  final isLoading = true.obs;
  final RxList<LeaderboardUser> users = <LeaderboardUser>[].obs;
  final RxInt currentUserRank = 0.obs;

  String myUid() => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    listenLeaderboard();
  }

  void listenLeaderboard() {
    isLoading.value = true;

    FirebaseFirestore.instance
        .collection('users')
        .orderBy('pointsTotal', descending: true)
        .limit(50)
        .snapshots()
        .listen(
          (snap) {
            final list = snap.docs
                .map((d) => LeaderboardUser.fromDoc(d))
                .toList();
            users.assignAll(list);

            // Cari ranking user saat ini
            final currentUid = myUid();
            final index = list.indexWhere((user) => user.uid == currentUid);
            currentUserRank.value = index >= 0 ? index + 1 : 0;

            isLoading.value = false;
          },
          onError: (_) {
            isLoading.value = false;
          },
        );
  }
}
