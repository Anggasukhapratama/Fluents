import 'dart:async';

import 'package:fluent_ai/app/modules/progress/controllers/progress_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../controllers/dashboard_controller.dart';
import '../controllers/dashboard_shell_controller.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final DashboardController c;
  late final DashboardPopupBus bus;

  final noteC = TextEditingController();

  // ===== TEMA BARU: MERAH AGAK OREN (Sunset/Deep Orange) =====
  static const _brand = Color(0xFFFF5722); // Merah agak Oren
  static const _brandDark = Color(0xFFD84315);
  static const _brandLight = Color(0xFFFBE9E7); // Background tipisnya

  // Sentuhan Biru untuk variasi (Sesuai request)
  static const _accentBlue = Color(0xFF3B82F6);

  static const _bg = Color(0xFFF8FAFC); // Very light slate for background
  static const _surface = Colors.white;

  static const _text = Color(0xFF0F172A); // Slate 900
  static const _muted = Color(0xFF64748B); // Slate 500
  static const _border = Color(0xFFE2E8F0); // Slate 200

  // Soft, diffuse shadow for modern look
  static const _shadow = BoxShadow(
    color: Color(0x08000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  @override
  void initState() {
    super.initState();
    c = Get.find<DashboardController>();
    bus = Get.find<DashboardPopupBus>();

    // Popup logic
    ever<Map<String, dynamic>?>(bus.popupEvent, (event) async {
      if (event == null) return;
      await _vibrateStrong();
      _showModernPopup(
        event['title']?.toString() ?? 'Pengingat',
        event['message']?.toString() ?? '',
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!c.hasShownWelcomeMessage.value) {
        _showWelcomeDialog();
        c.hasShownWelcomeMessage.value = true;
      }
    });
  }

  @override
  void dispose() {
    noteC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _brand,
          backgroundColor: _surface,
          onRefresh: c.refreshDashboard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _buildModernAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatsRow(),
                    const SizedBox(height: 28),

                    _buildHeroBanner(),
                    const SizedBox(height: 32),

                    _sectionTitle("Eksplorasi Fitur"),
                    const SizedBox(height: 16),
                    // UI Bento Grid (Fixed Overflow)
                    _buildBentoFeatureExplore(),
                    const SizedBox(height: 32),

                    _sectionTitle("Perjalanan Karirmu"),
                    const SizedBox(height: 16),
                    _buildModernProgress(),
                    const SizedBox(height: 32),

                    _sectionTitle("Jadwal Wawancara"),
                    const SizedBox(height: 16),
                    _buildModernSchedule(),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle("Aktivitas Terakhir"),
                        GestureDetector(
                          // Arahkan ke Log (Index 2)
                          onTap: () =>
                              Get.find<DashboardShellController>().changeTab(2),
                          child: const Text(
                            "Lihat Semua",
                            style: TextStyle(
                              color: _brand,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRecentActivities(),

                    const SizedBox(height: 100), // Spacing for bottom nav
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================= UI COMPONENTS =======================

  SliverAppBar _buildModernAppBar() {
    return SliverAppBar(
      backgroundColor: _bg,
      elevation: 0,
      pinned: true,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _brand.withOpacity(0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: _brandLight,
              child: Obx(
                () => Text(
                  c.userName.value.isNotEmpty
                      ? c.userName.value[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: _brand,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Selamat datang kembali,",
                style: TextStyle(
                  fontSize: 12,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Obx(
                () => Text(
                  c.userName.value,
                  style: const TextStyle(
                    fontSize: 18,
                    color: _text,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Obx(() {
          final hasSch = c.nextSchedule.value != null;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 20),
                decoration: const BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                  boxShadow: [_shadow],
                ),
                child: IconButton(
                  icon: const Icon(LucideIcons.bell, color: _text, size: 20),
                  onPressed: _openScheduleNotificationPanel,
                ),
              ),
              if (hasSch)
                Positioned(
                  top: 12,
                  right: 22,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: _surface, width: 2),
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [_shadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(
            () => _statItem(
              LucideIcons.flame,
              "Streak",
              "${c.consecutiveDays.value} Hari",
              const Color(0xFFF97316),
            ),
          ),
          Container(width: 1, height: 30, color: _border),

          // BEST LABEL (Pengganti Avg Score)
          Obx(() {
            final bestLabel = _getBestLabelFromProgress();
            final totalSessions = _getTotalSessionsFromProgress();
            return _statItem(
              LucideIcons.trophy,
              "Best",
              bestLabel.isEmpty ? "-" : _shortLabel(bestLabel),
              _getLabelColor(bestLabel),
              subtitle: "$totalSessions sesi", // Pakai subtitle
            );
          }),
          Container(width: 1, height: 30, color: _border),

          Obx(
            () => _statItem(
              LucideIcons.award,
              "Level",
              _shortLevel(c.currentLevel.value),
              _brand,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method untuk ambil best label dari ProgressController
  String _getBestLabelFromProgress() {
    try {
      final progressCtrl = Get.find<ProgressController>();
      return progressCtrl.bestLabel.value;
    } catch (_) {
      return '';
    }
  }

  // Helper method untuk ambil total sesi dari ProgressController
  int _getTotalSessionsFromProgress() {
    try {
      final progressCtrl = Get.find<ProgressController>();
      return progressCtrl.totalSessions.value;
    } catch (_) {
      return 0;
    }
  }

  // Short label untuk tampilan compact
  String _shortLabel(String label) {
    switch (label) {
      case 'Siap Wawancara':
        return 'Siap';
      case 'Cukup Siap':
        return 'Cukup';
      case 'Butuh Banyak Latihan':
        return 'Butuh';
      default:
        return label;
    }
  }

  // Warna untuk label
  Color _getLabelColor(String label) {
    switch (label) {
      case 'Siap Wawancara':
        return const Color(0xFF10B981); // Hijau
      case 'Cukup Siap':
        return const Color(0xFFF59E0B); // Oranye
      case 'Butuh Banyak Latihan':
        return const Color(0xFFEF4444); // Merah
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _statItem(
    IconData icon,
    String label,
    String value,
    Color color, {
    String? subtitle, // Tambahkan ini
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: _text,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [_brandDark, _brand],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _brand.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "AI INTERVIEW COACH",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Tingkatkan rasa\npercaya dirimu hari ini.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _brandDark,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              final route = c.homeScreenActions.isNotEmpty
                  ? c.homeScreenActions.first['route']?.toString()
                  : null;
              if (route != null) Get.toNamed(route);
            },
            child: const Text(
              "Mulai Simulasi",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 DESAIN BENTO UI YANG BARU (BEBAS OVERFLOW) 🔥
  Widget _buildBentoFeatureExplore() {
    final actions = c.homeScreenActions;
    if (actions.isEmpty) return const SizedBox();

    final a0 = actions.isNotEmpty ? actions[0] : null;
    final a1 = actions.length > 1 ? actions[1] : null;
    final a2 = actions.length > 2 ? actions[2] : null;
    final a3 = actions.length > 3 ? actions[3] : null;

    return Column(
      children: [
        // Kartu Utama (Lebar / Full Width) - Height dinamis
        if (a0 != null) _buildPremiumWideCard(a0),

        // Dua Kartu Kecil Berdampingan
        if (a1 != null || a2 != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              if (a1 != null)
                Expanded(
                  child: _buildPremiumSquareCard(
                    a1,
                    overrideColor: _accentBlue,
                  ),
                ), // Biru sedikit
              if (a1 != null && a2 != null) const SizedBox(width: 16),
              if (a2 != null)
                Expanded(
                  child: _buildPremiumSquareCard(
                    a2,
                    overrideColor: const Color(0xFF10B981),
                  ),
                ), // Hijau (Tanya HRD)
            ],
          ),
        ],

        // Tombol Outlined Ekstra
        if (a3 != null) ...[
          const SizedBox(height: 16),
          _buildOutlineActionCard(a3),
        ],
      ],
    );
  }

  Widget _buildPremiumWideCard(Map<String, dynamic> a) {
    final name = a['name'].toString();
    final iconName = a['icon_name']?.toString() ?? '';
    final route = a['route']?.toString();
    final pts = _toIntSafe(a['points']);

    return InkWell(
      onTap: () async {
        if (route == null) return;
        await c.addPointsAndLog(title: name, route: route, points: pts);
        Get.toNamed(route);
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity, // Tidak ada height paksa (bebas overflow)
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF416C),
              Color(0xFFFF4B2B),
            ], // Gradien Merah ke Oren Cantik
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4B2B).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Icon raksasa transparan di pojok
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                _iconFromName(iconName),
                size: 130,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            // Konten asli (Padding menentukan tinggi stack)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _iconFromName(iconName),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "+$pts Poin",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Latih Public Speaking & Non-Verbal",
                    maxLines: 2,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSquareCard(
    Map<String, dynamic> a, {
    Color? overrideColor,
  }) {
    final name = a['name'].toString();
    final iconName = a['icon_name']?.toString() ?? '';
    final route = a['route']?.toString();
    final pts = _toIntSafe(a['points']);
    final color = overrideColor ?? _brand;

    return InkWell(
      onTap: () async {
        if (route == null) return;
        await c.addPointsAndLog(title: name, route: route, points: pts);
        Get.toNamed(route);
      },
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 1.0, // Dijamin proporsional (kotak) dan gak akan overflow
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border, width: 0.8),
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
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconFromName(iconName),
                      color: color,
                      size: 22,
                    ),
                  ),
                  if (pts > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "+$pts",
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _text,
                  fontSize: 15,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Mulai Sesi",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineActionCard(Map<String, dynamic> a) {
    final name = a['name'].toString();
    final iconName = a['icon_name']?.toString() ?? '';
    final route = a['route']?.toString();

    return InkWell(
      onTap: () {
        if (route != null) Get.toNamed(route);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border, width: 1.5),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_iconFromName(iconName), color: _muted, size: 20),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 0.5),
        boxShadow: const [_shadow],
      ),
      child: Obx(() {
        final maxP = c.maxPointsForCurrentLevel.value;
        final curP = c.pointsInCurrentLevel.value;
        final progress = maxP > 0 ? curP / maxP : 1.0;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Total Poin",
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${c.totalPoints.value}",
                      style: const TextStyle(
                        color: _text,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _brandLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    c.pointsNeededForNextLevelText.value,
                    style: const TextStyle(
                      color: _brand,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: _bg,
                valueColor: const AlwaysStoppedAnimation<Color>(_brand),
                minHeight: 8,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildModernSchedule() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 0.5),
        boxShadow: const [_shadow],
      ),
      child: Obx(() {
        if (c.isLoadingSchedule.value) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 3, color: _brand),
          );
        }

        final sch = c.nextSchedule.value;
        if (sch == null) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border, style: BorderStyle.solid),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.calendarX, color: _muted, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Belum ada jadwal terdekat. Yuk jadwalkan sesi latihanmu!",
                        style: TextStyle(
                          color: _muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: _brand),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(
                    LucideIcons.calendarPlus,
                    size: 18,
                    color: _brand,
                  ),
                  label: const Text(
                    "Buat Jadwal Baru",
                    style: TextStyle(
                      color: _brand,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: _showAddScheduleSheet,
                ),
              ),
            ],
          );
        }

        final id = sch['id']?.toString() ?? '';
        final dt = sch['scheduledAt'] as DateTime?;
        final note = (sch['note'] ?? '').toString().trim();
        final when = dt == null ? '-' : _formatDateTime(dt);

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _brandLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.calendarClock,
                    color: _brand,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        when,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _text,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note.isEmpty ? "Persiapan Wawancara" : note,
                        style: const TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.trash2,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  onPressed: () => _deleteScheduleConfirm(id),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildRecentActivities() {
    return Obx(() {
      final items = c.recentActivities;
      if (items.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: const Text(
            "Belum ada rekam jejak. Gas latihan!",
            style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length > 3
            ? 3
            : items.length, // Show max 3 on dashboard
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final a = items[index];
          final meta = _activityMetaFromTitle(a.title);
          final time =
              '${a.at.day.toString().padLeft(2, '0')}/${a.at.month.toString().padLeft(2, '0')} • ${a.at.hour.toString().padLeft(2, '0')}:${a.at.minute.toString().padLeft(2, '0')}';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border, width: 0.5),
              boxShadow: const [_shadow],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: meta.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(meta.icon, size: 18, color: meta.color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _text,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "+${a.points}",
                  style: TextStyle(
                    color: meta.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: _text,
        letterSpacing: -0.3,
      ),
    );
  }

  // ======================= BOTTOM SHEETS & DIALOGS =======================

  void _showAddScheduleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Buat Pengingat Latihan",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Konsistensi adalah kunci. Kapan kamu mau latihan lagi?",
              style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: noteC,
              decoration: InputDecoration(
                labelText: "Catatan (Opsional)",
                hintText: "Cth: Latihan Postur & Senyum",
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _brand, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: DateTime(now.year + 2),
                    builder: (context, child) => Theme(
                      data: ThemeData.light().copyWith(
                        primaryColor: _brand,
                        colorScheme: const ColorScheme.light(primary: _brand),
                      ),
                      child: child!,
                    ),
                  );
                  if (date == null) return;

                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(
                      now.add(const Duration(minutes: 30)),
                    ),
                    builder: (context, child) => Theme(
                      data: ThemeData.light().copyWith(
                        primaryColor: _brand,
                        colorScheme: const ColorScheme.light(primary: _brand),
                      ),
                      child: child!,
                    ),
                  );
                  if (time == null) return;

                  final scheduledAt = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );

                  try {
                    await c.saveInterviewSchedule(
                      scheduledAt: scheduledAt,
                      note: noteC.text.trim(),
                    );
                    noteC.clear();
                    Get.back(); // close sheet
                    Get.snackbar(
                      "Sip!",
                      "Jadwal berhasil disimpan.",
                      backgroundColor: Colors.white,
                      colorText: _text,
                    );
                  } catch (e) {
                    Get.snackbar(
                      "Gagal",
                      e.toString(),
                      backgroundColor: Colors.white,
                      colorText: _text,
                    );
                  }
                },
                child: const Text(
                  "Pilih Waktu & Simpan",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWelcomeDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _brandLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.rocket, color: _brand, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                "Siap Berlatih?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Konsisten latihan tiap hari bikin peluang karirmu makin bersinar. Yuk mulai sekarang!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: Get.back,
                  child: const Text(
                    "Ayo Mulai!",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModernPopup(String title, String message) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                  LucideIcons.alarmClock,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: Get.back,
                      child: const Text(
                        "Tutup",
                        style: TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                        final route = c.homeScreenActions.isNotEmpty
                            ? c.homeScreenActions.first['route']?.toString()
                            : null;
                        if (route != null) Get.toNamed(route);
                      },
                      child: const Text(
                        "Mulai",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openScheduleNotificationPanel() {
    HapticFeedback.mediumImpact();
    final sch = c.nextSchedule.value;
    if (sch == null) {
      Get.snackbar(
        "Info",
        "Belum ada jadwal. Scroll ke bawah untuk menambah jadwal.",
        backgroundColor: Colors.white,
        colorText: _text,
      );
    } else {
      Get.snackbar(
        "Jadwal Mendatang",
        "${_formatDateTime(sch['scheduledAt'] as DateTime)} - ${sch['note']}",
        backgroundColor: Colors.white,
        colorText: _text,
      );
    }
  }

  void _deleteScheduleConfirm(String id) async {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.trash2,
                color: Color(0xFFEF4444),
                size: 32,
              ),
              const SizedBox(height: 16),
              const Text(
                "Hapus Jadwal?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Jadwal ini akan dihapus permanen.",
                style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: Get.back,
                      child: const Text(
                        "Batal",
                        style: TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        Get.back();
                        await c.deleteSchedule(id);
                        Get.snackbar(
                          "Berhasil",
                          "Jadwal dihapus",
                          backgroundColor: Colors.white,
                          colorText: _text,
                        );
                      },
                      child: const Text(
                        "Hapus",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================= HELPERS =======================

  Future<void> _vibrateStrong() async {
    try {
      if (await Vibrate.canVibrate) {
        Vibrate.vibrateWithPauses([
          const Duration(milliseconds: 400),
          const Duration(milliseconds: 100),
          const Duration(milliseconds: 400),
        ]);
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _shortLevel(String raw) {
    if (!raw.contains('•')) return raw;
    return raw.split('•').first.trim();
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'book-open':
        return LucideIcons.mic;
      case 'users':
        return LucideIcons.users;
      case 'agent':
        return LucideIcons.bot;
      case 'grid':
        return LucideIcons.layoutGrid;
      default:
        return LucideIcons.activity;
    }
  }

  Color _colorFromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return _brand;
    }
  }

  int _toIntSafe(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  _ActivityMeta _activityMetaFromTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('narasi'))
      return const _ActivityMeta(
        icon: LucideIcons.mic,
        color: Color(0xFF8B5CF6),
      );
    if (t.contains('tanya hrd'))
      return const _ActivityMeta(
        icon: LucideIcons.bot,
        color: Color(0xFF10B981),
      );
    if (t.contains('simulasi') || t.contains('hrd sim'))
      return const _ActivityMeta(
        icon: LucideIcons.users,
        color: Color(0xFFF59E0B),
      );
    return const _ActivityMeta(icon: LucideIcons.zap, color: _brand);
  }
}

class _ActivityMeta {
  final IconData icon;
  final Color color;
  const _ActivityMeta({required this.icon, required this.color});
}
