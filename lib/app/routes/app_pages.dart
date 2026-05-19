import 'package:get/get.dart';

import '../modules/activities/bindings/activities_binding.dart';
import '../modules/activities/views/activities_view.dart';
import '../modules/ask_hrd/bindings/ask_hrd_binding.dart';
import '../modules/ask_hrd/views/ask_hrd_view.dart';
import '../modules/auth_gate/views/auth_gate_view.dart';
import '../modules/cv_analysis/bindings/cv_analysis_binding.dart';
import '../modules/cv_analysis/views/cv_analysis_view.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_shell_view.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/face_check/bindings/face_check_binding.dart';
import '../modules/face_check/views/face_check_view.dart';
import '../modules/hrd_sim/bindings/hrd_sim_binding.dart';
import '../modules/hrd_sim/views/hrd_sim_view.dart';
import '../modules/intro/bindings/intro_binding.dart';
import '../modules/intro/views/intro_view.dart';
import '../modules/leaderboard/bindings/leaderboard_binding.dart';
import '../modules/leaderboard/views/leaderboard_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/materi/bindings/materi_binding.dart';
import '../modules/materi/views/materi_view.dart';
import '../modules/more_features/bindings/more_features_binding.dart';
import '../modules/more_features/views/more_features_view.dart';
import '../modules/narasi_detect/bindings/narasi_detect_binding.dart';
import '../modules/narasi_detect/views/narasi_detect_view.dart' as nd;
import '../modules/narasi_detect/views/narasi_detect_view.dart';
import '../modules/narasi_detect/views/narasi_practice_view.dart' as np;
import '../modules/narasi_detect/views/narasi_practice_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/progress/bindings/progress_binding.dart';
import '../modules/progress/views/progress_view.dart';
import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/verify_email/bindings/verify_email_binding.dart';
import '../modules/verify_email/views/verify_email_view.dart';
import '../modules/video/bindings/video_binding.dart';
import '../modules/video/views/video_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(name: Routes.AUTH_GATE, page: () => const AuthGateView()),
    GetPage(
      name: _Paths.PROFILE,
      page: () => ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: _Paths.DASHBOARD,
      page: () => const DashboardShellView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: _Paths.VERIFY_EMAIL,
      page: () => const VerifyEmailView(),
      binding: VerifyEmailBinding(),
    ),
    GetPage(
      name: _Paths.MORE_FEATURES,
      page: () => const MoreFeaturesView(),
      binding: MoreFeaturesBinding(),
    ),
    GetPage(
      name: _Paths.NARASI_DETECT,
      page: () => np.NarasiPracticeView(),
      binding: NarasiDetectBinding(),
    ),
    GetPage(
      name: _Paths.PROGRESS,
      page: () => const ProgressView(),
      binding: ProgressBinding(),
    ),
    GetPage(
      name: _Paths.HRD_SIM,
      page: () => const HrdSimView(),
      binding: HrdSimBinding(),
    ),
    GetPage(
      name: _Paths.FACE_CHECK,
      page: () => const FaceCheckView(),
      binding: FaceCheckBinding(),
    ),
    GetPage(
      name: _Paths.VIDEO,
      page: () => const VideoView(),
      binding: VideoBinding(),
    ),
    GetPage(
      name: _Paths.MATERI,
      page: () => const MateriView(),
      binding: MateriBinding(),
    ),
    GetPage(
      name: _Paths.ASK_HRD,
      page: () => const AskHrdView(),
      binding: AskHrdBinding(),
    ),
    GetPage(
      name: _Paths.ACTIVITIES,
      page: () => const ActivitiesView(),
      binding: ActivitiesBinding(),
    ),
    GetPage(
      name: _Paths.INTRO,
      page: () => const IntroView(),
      binding: IntroBinding(),
    ),
    GetPage(
      name: _Paths.LEADERBOARD,
      page: () => const LeaderboardView(),
      binding: LeaderboardBinding(),
    ),
    GetPage(
      name: _Paths.CV_ANALYSIS,
      page: () => const CvAnalysisView(),
      binding: CvAnalysisBinding(),
    ),
  ];
}
