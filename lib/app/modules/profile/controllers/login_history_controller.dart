import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class LoginHistoryController extends GetxController {
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  // setiap item: {timestamp: Timestamp?, method: String, platform: String, ip_address: String?}
  final historyList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        errorMessage.value = 'User belum login';
        historyList.clear();
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('login_history')
          .where('uid', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      historyList.assignAll(snap.docs.map((d) => d.data()).toList());
    } on FirebaseException catch (e) {
      // 🔥 kalau butuh index, biasanya code = failed-precondition
      errorMessage.value = e.message ?? e.code;
      historyList.clear();
    } catch (e) {
      errorMessage.value = e.toString();
      historyList.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
