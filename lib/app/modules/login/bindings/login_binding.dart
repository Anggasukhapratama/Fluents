import 'package:get/get.dart';
import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // fenix: true => kalau controller kehapus, GetX akan bikin ulang saat dibutuhkan
    Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
  }
}
