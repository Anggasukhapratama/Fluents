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
  // Kategori default kosong (artinya 'Semua Topik')
  final selectedRole = ''.obs;

  // Sorting selalu kita atur ke 'viewCount' (Terpopuler) di belakang layar
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
      // Jika pengguna memilih kategori spesifik, kita tambahkan ke kata kunci pencarian
      String? roleQuery;
      if (selectedRole.value.isNotEmpty) {
        roleQuery = 'wawancara kerja ${selectedRole.value}';
      }

      final data = await api.fetchVideos(
        role: roleQuery,
        query: query.value.isEmpty ? null : query.value,
        sortOrder:
            selectedSort.value, // Memaksa API mencari yang paling populer
      );

      // Sorting manual tambahan untuk memastikan urutan benar-benar dari views tertinggi
      data.sort((a, b) => b.viewCount.compareTo(a.viewCount));

      videos.assignAll(data);

      if (data.isEmpty) {
        errorText.value = 'Tidak ada video ditemukan.';
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

  void pickCategory(String category) {
    selectedRole.value = category;
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
