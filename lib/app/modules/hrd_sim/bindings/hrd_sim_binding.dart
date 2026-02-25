import 'package:get/get.dart';
import '../controllers/hrd_sim_controller.dart';

class HrdSimBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HrdSimController>(() => HrdSimController(), fenix: true);
  }
}
