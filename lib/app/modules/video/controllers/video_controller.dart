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

  // Selalu gunakan viewCount untuk sorting
  final selectedSort = 'viewCount'.obs;

  final videos = <InterviewVideo>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    errorText.value = '';

    try {
      String? roleQuery;
      if (selectedRole.value.isNotEmpty) {
        roleQuery = 'wawancara kerja ${selectedRole.value}';
      }

      final data = await api.fetchVideos(
        role: roleQuery,
        query: query.value.isEmpty ? null : query.value,
        sortOrder: selectedSort.value,
      );

      // API sudah mengurutkan berdasarkan viewCount,
      // tapi kita sort lagi untuk memastikan
      data.sort((a, b) => b.viewCount.compareTo(a.viewCount));

      videos.assignAll(data);

      if (data.isEmpty) {
        errorText.value = 'Tidak ada video berbahasa Indonesia ditemukan.';
      }
    } catch (e) {
      videos.clear();
      errorText.value = 'Gagal memuat video. Periksa koneksi internet Anda.';
    } finally {
      isLoading.value = false;
    }
  }

  void setSearch(String text) {
    query.value = text;
    fetch();
  }

  void pickCategory(String category) {
    selectedRole.value = category;
    fetch();
  }

  // Fungsi untuk menampilkan views dengan format yang lebih baik
  String formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M views';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K views';
    }
    return '$views views';
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
