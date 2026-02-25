import 'package:fluent_ai/app/services/notification_service.dart';
import 'package:get/get.dart';
import 'package:fluent_ai/app/services/auth_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    NotificationService.instance.init();
    // permanent biar gak ilang walau Get.offAllNamed()
    Get.put<AuthService>(AuthService(), permanent: true);
  }
}
