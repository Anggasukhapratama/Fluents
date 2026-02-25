import 'package:get/get.dart';

import '../controllers/narasi_detect_controller.dart';
import '../controllers/narasi_practice_controller.dart';

class NarasiDetectBinding extends Bindings {
  @override
  void dependencies() {
    // 1) Detect dulu, karena PracticeController butuh Get.find<NarasiDetectController>()
    Get.put<NarasiDetectController>(NarasiDetectController(), permanent: true);

    // 2) Baru Practice
    Get.lazyPut<NarasiPracticeController>(() => NarasiPracticeController());
  }
}
