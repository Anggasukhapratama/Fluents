// lib/app/modules/profile/views/profile_view.dart
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

  // ===== PREMIUM PALETTE =====
  static const _primary = Color(0xFF6366F1);
  static const _primaryDark = Color(0xFF4F46E5);
  static const _primaryLight = Color(0xFF818CF8);
  static const _secondary = Color(0xFF0EA5E9);
  static const _accent = Color(0xFFF43F5E);

  static const _bg = Color(0xFFF8FAFC);
  static const _surface = Colors.white;
  static const _text = Color(0xFF0F172A);
  static const _textSoft = Color(0xFF334155);
  static const _textMuted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _borderLight = Color(0xFFF1F5F9);

  static const _shadowSoft = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 10,
    offset: Offset(0, 4),
  );

  static const _shadowMedium = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 20,
    offset: Offset(0, 8),
  );

  // Helper untuk capitalize first letter (manual, tanpa extension)
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

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
          return _buildErrorState();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshProfileData,
          color: _primary,
          backgroundColor: _surface,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildPremiumHeader(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildQuickStatsSection(),
                      const SizedBox(height: 28),
                      _buildProfileDetailsSection(),
                      const SizedBox(height: 24),
                      _buildSecurityButton(),
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
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                boxShadow: [_shadowSoft],
              ),
              child: const Icon(
                LucideIcons.alertCircle,
                color: Color(0xFFEF4444),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              controller.errorMessage.value,
              style: const TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: controller.refreshProfileData,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= PREMIUM HEADER =================
  Widget _buildPremiumHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: _bg,
      elevation: 0,
      centerTitle: false,
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: 1.0,
        child: const Text(
          'Profil',
          style: TextStyle(
            color: _text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryDark, _primary, _primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _surface,
                          shape: BoxShape.circle,
                          boxShadow: [_shadowMedium],
                        ),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: _primaryLight.withOpacity(0.2),
                          child: Obx(
                            () => Text(
                              controller.username.value.isNotEmpty
                                  ? controller.username.value[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: _primaryDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Name & Email
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(
                              () => Text(
                                controller.username.value.isNotEmpty
                                    ? controller.username.value
                                    : 'Pengguna',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Obx(
                                () => Text(
                                  controller.email.value.isNotEmpty
                                      ? controller.email.value
                                      : 'email@anda.com',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _showLogoutDialog(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.logOut,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ================= QUICK STATS SECTION =================
  Widget _buildQuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hasil Terakhir',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _text,
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '3 Parameter',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ===== CARD 3 PARAMETER TERAKHIR =====
        Obx(() {
          final eyeLabel = controller.lastEyeContact.value;
          final smileLabel = controller.lastSmile.value;
          final postureLabel = controller.lastPosture.value;
          final totalSessions = controller.totalSessions.value;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        LucideIcons.award,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Status Terakhir',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalSessions Sesi Latihan',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.15)),
                const SizedBox(height: 16),

                // 3 Parameter
                Row(
                  children: [
                    _paramChip(
                      icon: '👀',
                      label: eyeLabel.isEmpty ? '-' : eyeLabel,
                      color: controller.getLabelColor(eyeLabel),
                    ),
                    const SizedBox(width: 8),
                    _paramChip(
                      icon: '😊',
                      label: smileLabel.isEmpty ? '-' : smileLabel,
                      color: controller.getLabelColor(smileLabel),
                    ),
                    const SizedBox(width: 8),
                    _paramChip(
                      icon: '🧍',
                      label: postureLabel.isEmpty ? '-' : postureLabel,
                      color: controller.getLabelColor(postureLabel),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.improvementNote.value,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),

        // Stat tambahan (Streak & Level)
        Row(
          children: [
            Expanded(
              child: _buildStatCardSimple(
                icon: LucideIcons.flame,
                title: 'Streak',
                value: controller.getStreakText(),
                color: const Color(0xFFF97316),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCardSimple(
                icon: LucideIcons.star,
                title: 'Level',
                value: controller.getLevelDisplayName(),
                color: _primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _paramChip({
    required String icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk stat card sederhana
  Widget _buildStatCardSimple({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [_shadowSoft],
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= PROFILE DETAILS SECTION =================
  Widget _buildProfileDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Informasi Pribadi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _text,
                letterSpacing: -0.3,
              ),
            ),
            TextButton.icon(
              onPressed: controller.navigateToEditProfile,
              icon: const Icon(LucideIcons.pencil, size: 16, color: _primary),
              label: const Text(
                'Edit',
                style: TextStyle(
                  color: _primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [_shadowSoft],
            border: Border.all(color: _borderLight),
          ),
          child: Column(
            children: [
              Obx(
                () => _buildDetailTile(
                  icon: LucideIcons.user,
                  label: 'Nama Lengkap',
                  value: controller.username.value,
                ),
              ),
              const Divider(
                height: 1,
                indent: 72,
                endIndent: 20,
                color: _borderLight,
              ),
              Obx(
                () => _buildDetailTile(
                  icon: LucideIcons.mail,
                  label: 'Alamat Email',
                  value: controller.email.value,
                ),
              ),
              const Divider(
                height: 1,
                indent: 72,
                endIndent: 20,
                color: _borderLight,
              ),
              Obx(
                () => _buildDetailTile(
                  icon: LucideIcons.user,
                  label: 'Gender',
                  value: _capitalizeFirst(controller.gender.value),
                ),
              ),
              const Divider(
                height: 1,
                indent: 72,
                endIndent: 20,
                color: _borderLight,
              ),
              Obx(
                () => _buildDetailTile(
                  icon: LucideIcons.briefcase,
                  label: 'Pekerjaan Impian',
                  value: controller.occupation.value,
                  isLast: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: _primary),
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
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'Belum diisi',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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

  // ================= SECURITY BUTTON =================
  Widget _buildSecurityButton() {
    return GestureDetector(
      onTap: () {
        Get.bottomSheet(
          _LoginHistorySheet(),
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [_shadowSoft],
          border: Border.all(color: _borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                LucideIcons.shield,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keamanan & Login',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Lihat riwayat perangkat yang login',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: _textMuted, size: 20),
          ],
        ),
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
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.logOut,
                    color: _accent,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Keluar dari Akun?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Kamu perlu login kembali untuk mengakses simulasi AI.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            color: _textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          controller.logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Keluar',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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

// ================= LOGIN HISTORY SHEET =================
class _LoginHistorySheet extends StatelessWidget {
  final controller = Get.put(LoginHistoryController());

  _LoginHistorySheet();

  String formatTimestamp(dynamic ts) {
    try {
      if (ts == null) return 'Waktu tidak diketahui';
      if (ts is Timestamp) {
        final dt = ts.toDate().toLocal();
        return DateFormat('dd MMM yyyy • HH:mm').format(dt);
      }
      if (ts is String) {
        final dt = DateTime.tryParse(ts);
        if (dt != null) {
          return DateFormat('dd MMM yyyy • HH:mm').format(dt.toLocal());
        }
        return ts;
      }
      return ts.toString();
    } catch (_) {
      return ts.toString();
    }
  }

  String _getDeviceIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('android')) return '🤖';
    if (p.contains('ios') || p.contains('iphone')) return '🍎';
    if (p.contains('web')) return '🌐';
    if (p.contains('windows')) return '💻';
    if (p.contains('mac')) return '🖥️';
    return '📱';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: ProfileView._surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ProfileView._border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Riwayat Login',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: ProfileView._text,
                      ),
                    ),
                    IconButton(
                      onPressed: controller.loadHistory,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ProfileView._bg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.refreshCw,
                          size: 16,
                          color: ProfileView._textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: ProfileView._borderLight),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.wifiOff,
                              size: 48,
                              color: ProfileView._textMuted.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              controller.errorMessage.value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: ProfileView._textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (controller.historyList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.history,
                            size: 48,
                            color: ProfileView._textMuted.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada riwayat login',
                            style: TextStyle(
                              color: ProfileView._textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    itemCount: controller.historyList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = controller.historyList[index];
                      final method = (item['method'] ?? 'unknown').toString();
                      final platform = (item['platform'] ?? '').toString();
                      final ip = item['ip_address']?.toString();

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ProfileView._surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ProfileView._borderLight),
                          boxShadow: const [ProfileView._shadowSoft],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: ProfileView._primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  _getDeviceIcon(platform),
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatTimestamp(item['timestamp']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: ProfileView._text,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ProfileView._bg,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          method.toUpperCase(),
                                          style: const TextStyle(
                                            color: ProfileView._textMuted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (platform.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '• $platform',
                                          style: const TextStyle(
                                            color: ProfileView._textMuted,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
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
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  ip,
                                  style: const TextStyle(
                                    color: ProfileView._textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
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
