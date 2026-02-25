import 'package:fluent_ai/app/modules/activities/controllers/activities_controller.dart';
import 'package:get/get.dart';

import '../controllers/dashboard_controller.dart';
import '../controllers/dashboard_shell_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/controllers/login_history_controller.dart';

// ✅ tambahin ini
import '../../progress/controllers/progress_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(DashboardPopupBus(), permanent: true);

    Get.lazyPut<DashboardController>(() => DashboardController(), fenix: true);
    Get.lazyPut<DashboardShellController>(
      () => DashboardShellController(),
      fenix: true,
    );

    // ✅ penting untuk tab profil
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
    Get.lazyPut<LoginHistoryController>(
      () => LoginHistoryController(),
      fenix: true,
    );

    // ✅ FIX: biar ProgressView tidak error "ProgressController not found"
    Get.lazyPut<ProgressController>(() => ProgressController(), fenix: true);
    // ✅ FIX: biar ActivitiesView tidak error "ActivitiesController not found"
    Get.lazyPut<ActivitiesController>(
      () => ActivitiesController(),
      fenix: true,
    );
  }
}
