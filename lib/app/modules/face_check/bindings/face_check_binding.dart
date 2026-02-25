import 'package:get/get.dart';
import '../controllers/face_check_controller.dart';

class FaceCheckBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FaceCheckController>(() => FaceCheckController());
  }
}
