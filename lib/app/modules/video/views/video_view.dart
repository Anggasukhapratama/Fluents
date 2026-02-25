import 'package:fluent_ai/app/models/interview_video.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/video_controller.dart';

class VideoView extends GetView<VideoController> {
  const VideoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0F0F1A),
            foregroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            floating: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Video Panduan Wawancara',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1A1A2E).withOpacity(0.9),
                      const Color(0xFF0F0F1A).withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: controller.fetch,
                icon: const Icon(Icons.refresh_rounded, size: 24),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: _buildContent(context), // PASS CONTEXT HERE
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtitle
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Text(
            'Pelajari teknik wawancara dari para expert dan tingkatkan peluangmu',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
        ),

        // Search Bar
        _searchBar(),
        const SizedBox(height: 4),

        // Experience Level
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Text(
                  'LEVEL PENGALAMAN',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _filters(),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Categories
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            'KATEGORI WAWANCARA',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _recommendations(),
        const SizedBox(height: 8),

        // Video Count
        Obx(() {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.video_library_rounded,
                  color: const Color(0xFF6C63FF),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${controller.videos.length} Video Tersedia',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (controller.isLoading.value)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),

        // Video List - FIX: Pass context directly
        _listBuilder(context),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 0,
            ),
          ],
        ),
        child: TextField(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Cari tips: "confidence", "body language", "gaji"...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.search_rounded,
                color: const Color(0xFF6C63FF),
                size: 24,
              ),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 20,
            ),
            suffixIcon: Obx(() {
              if (controller.query.isNotEmpty) {
                return IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  onPressed: () {
                    controller.setSearch('');
                  },
                );
              }
              return const SizedBox.shrink(); // FIX: Return SizedBox instead of null
            }),
          ),
          onChanged: (value) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (value == controller.query.value) {
                controller.setSearch(value);
              }
            });
          },
        ),
      ),
    );
  }

  Widget _filters() {
    return Obx(() {
      final level = controller.selectedLevel.value;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _levelChip(
            '🏆 Junior',
            level == 'junior',
            () => controller.pickLevel('junior'),
            const Color(0xFF4FC3F7),
          ),
          _levelChip(
            '⚡ Mid',
            level == 'mid',
            () => controller.pickLevel('mid'),
            const Color(0xFFBA68C8),
          ),
          _levelChip(
            '👑 Senior',
            level == 'senior',
            () => controller.pickLevel('senior'),
            const Color(0xFFFFB74D),
          ),
          _levelChip(
            '🎯 All Level',
            level == 'all',
            () => controller.pickLevel('all'),
            const Color(0xFF81C784),
          ),
        ],
      );
    });
  }

  Widget _recommendations() {
    return Obx(() {
      final rec = controller.recommendedRoles;
      return SizedBox(
        height: 50,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: rec.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final role = rec[i];
            final selected = controller.selectedRole.value == role;
            return _categoryChip(
              role,
              selected,
              () => controller.pickRole(role),
            );
          },
        ),
      );
    });
  }

  // FIX: New method that properly handles context
  Widget _listBuilder(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.videos.isEmpty) {
        return _loadingView();
      }

      if (controller.errorText.value.isNotEmpty && controller.videos.isEmpty) {
        return _errorView();
      }

      if (controller.videos.isEmpty) {
        return _emptyView();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: controller.videos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (_, i) {
            final v = controller.videos[i];
            return _videoCard(context, v);
          },
        ),
      );
    });
  }

  Widget _videoCard(BuildContext context, InterviewVideo v) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () async {
          await controller.logStartToDashboard();
          await _openYoutube(context, v.videoUrl);
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: const Color(0xFF6C63FF).withOpacity(0.2),
        highlightColor: const Color(0xFF6C63FF).withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.02),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 180,
                      color: Colors.white.withOpacity(0.05),
                      child: v.thumbnailUrl.isNotEmpty
                          ? Image.network(
                              v.thumbnailUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                        color: const Color(0xFF6C63FF),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.videocam_off_rounded,
                                    color: Colors.white.withOpacity(0.3),
                                    size: 50,
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.white.withOpacity(0.4),
                                size: 60,
                              ),
                            ),
                    ),
                    // Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.5, 1],
                          ),
                        ),
                      ),
                    ),
                    // Play Button & Duration
                    Positioned(
                      bottom: 12,
                      left: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _fmtDuration(v.durationSec),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      v.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Channel/Company
                    Row(
                      children: [
                        Icon(
                          Icons.account_circle_rounded,
                          color: Colors.white.withOpacity(0.6),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            v.company.isNotEmpty
                                ? v.company
                                : 'Expert Interview',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Tags
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _infoPill(
                          v.role.isEmpty ? 'General Tips' : v.role,
                          Icons.tips_and_updates_rounded,
                          const Color(0xFF4FC3F7),
                        ),
                        _infoPill(
                          v.level.isEmpty
                              ? 'All Level'
                              : v.level.capitalizeFirst!,
                          Icons.workspace_premium_rounded,
                          const Color(0xFFBA68C8),
                        ),
                        _infoPill(
                          'YouTube',
                          Icons.video_collection_rounded,
                          const Color(0xFFFF7043),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Expert Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: const Color(0xFF6C63FF),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Expert Verified Tips',
                            style: TextStyle(
                              color: const Color(0xFF6C63FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelChip(
    String label,
    bool selected,
    VoidCallback onTap,
    Color color,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withOpacity(0.2),
          highlightColor: color.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? color.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? color.withOpacity(0.6)
                    : Colors.white.withOpacity(0.1),
                width: selected ? 2 : 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String label, bool selected, VoidCallback onTap) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          splashColor: const Color(0xFF6C63FF).withOpacity(0.2),
          highlightColor: const Color(0xFF6C63FF).withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF6C63FF).withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: selected
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withOpacity(0.1),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: const Color(0xFF6C63FF),
                    size: 16,
                  ),
                if (selected) const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withOpacity(0.8),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoPill(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingView() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: const Color(0xFF6C63FF),
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            'Memuat Panduan Wawancara...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Menyiapkan video terbaik untukmu',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red.withOpacity(0.7),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            controller.errorText.value,
            style: const TextStyle(color: Colors.redAccent, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: controller.fetch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              elevation: 2,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.video_library_outlined,
              color: Colors.white.withOpacity(0.3),
              size: 50,
            ),
          ),
          const SizedBox(height: 25),
          Text(
            'Belum Ada Video',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Coba pilih kategori lain atau gunakan kata kunci berbeda untuk menemukan video panduan wawancara',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () {
              controller.setSearch('');
              controller.pickRole('Wawancara Dasar');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
              foregroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: const Color(0xFF6C63FF).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: const Text('Lihat Wawancara Dasar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openYoutube(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Link video tidak tersedia'),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!ok) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal membuka YouTube'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Terjadi kesalahan'),
            backgroundColor: Colors.red.withOpacity(0.9),
          ),
        );
      }
    }
  }

  String _fmtDuration(int sec) {
    if (sec <= 0) return '--:--';
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;

    if (h > 0) {
      return '${h}h ${m}m';
    } else if (m > 0) {
      return '${m}m ${s}s';
    } else {
      return '${s}s';
    }
  }
}
