import 'package:fluent_ai/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:get/get.dart';
import 'package:fluent_ai/app/models/interview_video.dart';
import 'package:fluent_ai/app/services/interview_video_api.dart';

class VideoController extends GetxController {
  final InterviewVideoApi api = InterviewVideoApi(
    baseUrl: 'https://www.googleapis.com/youtube/v3',
    apiKey: 'AIzaSyAZu5dJKHDNcagVHvkWHvgJdmr8ZfP9J7I',
  );

  final isLoading = false.obs;
  final errorText = ''.obs;

  final query = ''.obs;
  final selectedRole = ''.obs;
  final selectedLevel = 'junior'.obs;

  final recommendedRoles = <String>[].obs;
  final videos = <InterviewVideo>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadLocalRecommendations();
    fetch();
  }

  // ✅ UPDATE: Rekomendasi berdasarkan teknik wawancara
  void _loadLocalRecommendations() {
    final categories = [
      'Wawancara Dasar',
      'Perilaku & Karakter',
      'Teknis & Skill',
      'Negosiasi Gaji',
      'Tips Persiapan',
      'Body Language',
      'Do & Don\'t',
      'Jawaban Cerdas',
      'Confidence',
      'Tanya Balik',
      'Komunikasi Efektif',
      'Storytelling',
      'Handling Stress',
      'Follow-up Email',
      'Portfolio Review',
    ];

    recommendedRoles.assignAll(categories);

    if (selectedRole.value.isEmpty && recommendedRoles.isNotEmpty) {
      selectedRole.value = recommendedRoles.first;
    }
  }

  Future<void> fetch() async {
    isLoading.value = true;
    errorText.value = '';

    try {
      final data = await api.fetchVideos(
        role: selectedRole.value.isEmpty ? null : selectedRole.value,
        level: selectedLevel.value.isEmpty ? null : selectedLevel.value,
        query: query.value.isEmpty ? null : query.value,
      );

      videos.assignAll(data);

      if (data.isEmpty) {
        errorText.value =
            'Tidak ada video ditemukan. Coba ganti kategori atau kata kunci.';
      }
    } catch (e) {
      videos.clear();
      errorText.value = 'Gagal memuat video. Periksa koneksi internet.';
    } finally {
      isLoading.value = false;
    }
  }

  void setSearch(String text) {
    query.value = text;
    fetch();
  }

  void pickRole(String role) {
    selectedRole.value = role;
    fetch();
  }

  void pickLevel(String level) {
    selectedLevel.value = level;
    fetch();
  }

  Future<void> logStartToDashboard() async {
    try {
      if (Get.isRegistered<DashboardController>()) {
        await Get.find<DashboardController>().addPointsAndLog(
          title: 'Video Panduan Wawancara',
          route: '/video',
          points: 2,
        );
      }
    } catch (_) {}
  }
}
