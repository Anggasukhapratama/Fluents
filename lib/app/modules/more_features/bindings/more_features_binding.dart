import 'package:get/get.dart';
import '../controllers/more_features_controller.dart';

class MoreFeaturesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MoreFeaturesController>(() => MoreFeaturesController());
  }
}
