import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluent_ai/app/modules/profile/controllers/login_history_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends StatelessWidget {
  final ProfileController controller = Get.find<ProfileController>();

  ProfileView({super.key});

  // ===== MODERN PALETTE (Tech & Professional AI Theme) =====
  static const _primary = Color(0xFF4F46E5); // Deep Indigo
  static const _primaryLight = Color(0xFF6366F1); // Indigo Light
  static const _secondary = Color(0xFF0EA5E9); // Ocean Blue

  static const _bg = Color(0xFFF1F5F9); // Latar belakang Slate terang
  static const _surface = Colors.white;
  static const _text = Color(0xFF0F172A); // Hampir hitam
  static const _textSoft = Color(0xFF334155);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  static const _shadow = BoxShadow(
    color: Color(0x0A000000), // Shadow sangat halus
    blurRadius: 20,
    offset: Offset(0, 10),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Obx(() {
        if (controller.isLoading.value && controller.username.value.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primary),
            ),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorState(context);
        }

        return RefreshIndicator(
          onRefresh: controller.refreshProfileData,
          color: _primary,
          backgroundColor: _surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _buildModernHeader(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildProgressSummarySection(context),
                      const SizedBox(height: 24),
                      _buildProfileDetailsSection(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ================= ERROR STATE =================
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                color: Color(0xFFEF4444),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              controller.errorMessage.value,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              onPressed: controller.refreshProfileData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= MODERN HEADER (OVERLAPPING) =================
  Widget _buildModernHeader(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ModernHeaderDelegate(
        controller: controller,
        onLogout: () => _showLogoutDialog(context),
        expandedHeight: 280, // Tinggi area header
      ),
    );
  }

  // ================= SUMMARY SECTION =================
  Widget _buildProgressSummarySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Statistik Performa",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _text,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => _buildProgressStatCard(
                  title: "Narasi",
                  averageScore: controller.narasiAverageScore.value,
                  totalSessions: controller.narasiTotalSessions.value,
                  icon: LucideIcons.mic,
                  gradient: const [
                    Color(0xFF8B5CF6),
                    Color(0xFF6D28D9),
                  ], // Purple
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Obx(
                () => _buildProgressStatCard(
                  title: "HRD",
                  averageScore: controller.hrdAverageScore.value,
                  totalSessions: controller.hrdTotalSessions.value,
                  icon: LucideIcons.briefcase,
                  gradient: const [
                    Color(0xFF0EA5E9),
                    Color(0xFF0284C7),
                  ], // Blue
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressStatCard({
    required String title,
    required double averageScore,
    required int totalSessions,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [_shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            averageScore.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: _text,
              letterSpacing: -1,
            ),
          ),
          const Text(
            "Rata-rata Skor",
            style: TextStyle(
              fontSize: 12,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.checkCircle2, size: 14, color: _muted),
                const SizedBox(width: 6),
                Text(
                  "$totalSessions Sesi",
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSoft,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= DETAILS SECTION =================
  Widget _buildProfileDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Informasi Pribadi",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _text,
                letterSpacing: -0.5,
              ),
            ),
            TextButton.icon(
              icon: const Icon(LucideIcons.edit3, size: 16, color: _primary),
              label: const Text(
                "Edit",
                style: TextStyle(
                  color: _primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: controller.navigateToEditProfile,
              style: TextButton.styleFrom(
                backgroundColor: _primary.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [_shadow],
          ),
          child: Column(
            children: [
              Obx(
                () => _buildProfileItem(
                  icon: LucideIcons.userCheck,
                  label: 'Nama Lengkap',
                  value: controller.username.value,
                ),
              ),
              const Divider(height: 1, thickness: 1, color: _bg),
              Obx(
                () => _buildProfileItem(
                  icon: LucideIcons.atSign,
                  label: 'Alamat Email',
                  value: controller.email.value,
                ),
              ),
              const Divider(height: 1, thickness: 1, color: _bg),
              Obx(
                () => _buildProfileItem(
                  icon: LucideIcons.users,
                  label: 'Gender',
                  value: controller.gender.value.capitalizeFirst ?? '',
                ),
              ),
              const Divider(height: 1, thickness: 1, color: _bg),
              Obx(
                () => _buildProfileItem(
                  icon: LucideIcons.target,
                  label: 'Pekerjaan Impian',
                  value: controller.occupation.value,
                  isLast: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Get.bottomSheet(
                _LoginHistorySheet(),
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
              );
            },
            icon: const Icon(
              LucideIcons.shieldCheck,
              color: _textSoft,
              size: 20,
            ),
            label: const Text(
              "Riwayat Keamanan & Login",
              style: TextStyle(
                color: _textSoft,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _surface,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: _border, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: 16.0, bottom: isLast ? 16.0 : 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 20, color: _primaryLight),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'Belum diisi',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= LOGOUT DIALOG =================
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.logOut,
                    color: Color(0xFFEF4444),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Keluar Akun?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kamu harus login kembali untuk bisa mengakses simulasi AI. Yakin ingin keluar sekarang?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: Navigator.of(context).pop,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: _muted,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          controller.logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Keluar',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================= CUSTOM HEADER DELEGATE =================
// Mengatur UI overlapping yang mengecil otomatis saat di-scroll ke bawah
class _ModernHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ProfileController controller;
  final VoidCallback onLogout;
  final double expandedHeight;

  _ModernHeaderDelegate({
    required this.controller,
    required this.onLogout,
    required this.expandedHeight,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Progress dari 0.0 (full) ke 1.0 (shrink/mengecil jadi AppBar biasa)
    final progress = shrinkOffset / maxExtent;
    final isExpanded = progress < 0.5;

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        // 1. Background Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [ProfileView._primaryLight, ProfileView._primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Pola transparan (Opsional biar nggak terlalu polos)
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),

        // 2. AppBar Elements (Title & Logout Button)
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Judul muncul kalau di-scroll
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isExpanded ? 0.0 : 1.0,
                child: const Text(
                  'Profil Saya',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.logOut, color: Colors.white),
                onPressed: onLogout,
              ),
            ],
          ),
        ),

        // 3. User Info (Menghilang saat di-scroll)
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          left: 20,
          right: 20,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isExpanded ? 1.0 : 0.0,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Obx(
                  () => Text(
                    controller.username.value.isNotEmpty
                        ? controller.username.value
                        : 'Nama Pengguna',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Obx(
                    () => Text(
                      controller.email.value.isNotEmpty
                          ? controller.email.value
                          : 'email@anda.com',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. Overlapping Avatar (Floating di tengah garis batas gradient & body)
        Positioned(
          bottom: -40, // Separuh keluar dari header
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isExpanded ? 1.0 : 0.0,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: ProfileView._bg, // Sama dengan background scaffold
                  shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ProfileView._primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white,
                    child: Obx(
                      () => Text(
                        controller.username.value.isNotEmpty
                            ? controller.username.value[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 36,
                          color: ProfileView._primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => kToolbarHeight + 40; // Ditambah safe area

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

// ================= LOGIN HISTORY SHEET =================
class _LoginHistorySheet extends StatelessWidget {
  final controller = Get.put(LoginHistoryController());

  _LoginHistorySheet({super.key});

  String formatTimestamp(dynamic ts) {
    try {
      if (ts == null) return 'Waktu tidak diketahui';
      if (ts is Timestamp) {
        final dt = ts.toDate().toLocal();
        return DateFormat('dd MMM yyyy, HH:mm').format(dt);
      }
      if (ts is String) {
        final dt = DateTime.tryParse(ts);
        if (dt != null) {
          return DateFormat('dd MMM yyyy, HH:mm').format(dt.toLocal());
        }
        return ts;
      }
      return ts.toString();
    } catch (_) {
      return ts.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.only(top: 12),
          decoration: const BoxDecoration(
            color: ProfileView._surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: ProfileView._border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Riwayat Login',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: ProfileView._text,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: controller.loadHistory,
                      icon: const Icon(
                        LucideIcons.refreshCw,
                        color: ProfileView._text,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: ProfileView._bg, thickness: 2, height: 24),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ProfileView._primary,
                      ),
                    );
                  }

                  if (controller.errorMessage.value.isNotEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          controller.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: ProfileView._muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }

                  if (controller.historyList.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada rekam jejak perangkat.',
                        style: TextStyle(
                          color: ProfileView._muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: controller.historyList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = controller.historyList[index];
                      final method = (item['method'] ?? 'unknown').toString();
                      final platform = (item['platform'] ?? '').toString();
                      final ip = item['ip_address']?.toString();

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ProfileView._surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: ProfileView._border,
                            width: 0.8,
                          ),
                          boxShadow: const [ProfileView._shadow],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ProfileView._primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.smartphone,
                                color: ProfileView._primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatTimestamp(item['timestamp']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: ProfileView._text,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${method.toUpperCase()} ${platform.isNotEmpty ? ' • $platform' : ''}',
                                    style: const TextStyle(
                                      color: ProfileView._muted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (ip != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: ProfileView._bg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  ip,
                                  style: const TextStyle(
                                    color: ProfileView._muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
