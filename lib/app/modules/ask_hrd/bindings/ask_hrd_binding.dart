import 'package:get/get.dart';

import '../controllers/ask_hrd_controller.dart';

class AskHrdBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AskHrdController>(
      () => AskHrdController(),
    );
  }
}
