import 'package:fluent_ai/app/models/interview_video.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/video_controller.dart';
import 'video_player_view.dart'; // Import view player yang baru dibuat

class VideoView extends GetView<VideoController> {
  const VideoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header Modern & Fun
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4FC3F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tutorial Wawancara 🚀',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => controller.fetch(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Siapkan dirimu sebelum bertemu HRD!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSearchBar(),
              ],
            ),
          ),

          // Chips Kategori
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            child: Row(
              children: const [
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  "Topik Populer",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 10),
            child: _buildCategoryOptions(),
          ),

          // List Video
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                );
              }

              if (controller.videos.isEmpty &&
                  controller.errorText.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.errorText.value,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                itemCount: controller.videos.length,
                itemBuilder: (context, index) {
                  return _buildVideoCard(context, controller.videos[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        onChanged: (v) => controller.setSearch(v),
        decoration: const InputDecoration(
          hintText: 'Cari panduan (misal: gaji)...',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF6C63FF)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildCategoryOptions() {
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _categoryChip("Semua", ""),
            _categoryChip("Tips Umum", "tips umum"),
            _categoryChip("Bahasa Tubuh", "body language"),
            _categoryChip("Tanya Jawab", "pertanyaan jebakan"),
            _categoryChip("Gaji", "negosiasi gaji"),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label, String value) {
    bool isSelected = controller.selectedRole.value == value;
    return GestureDetector(
      onTap: () => controller.pickCategory(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[200]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, InterviewVideo video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        // INI BAGIAN PENTING: Panggil Get.to() untuk membuka video player di dalam aplikasi
        onTap: () => Get.to(() => VideoPlayerView(video: video)),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    video.thumbnailUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 190,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 190,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.video_library,
                        color: Colors.grey,
                        size: 50,
                      ),
                    ),
                  ),
                ),
                // Tombol Play Overlay
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          video.company,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatViews(video.viewCount),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}rb';
    return '$views';
  }
}
