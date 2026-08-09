import 'package:get/get.dart';

import '../controllers/profile_controller.dart';
import '../../progress/controllers/progress_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure ProgressController exists so ProfileController can safely Find it
    Get.lazyPut<ProgressController>(() => ProgressController(), fenix: true);

    Get.lazyPut<ProfileController>(
      () => ProfileController(),
    );
  }
}
