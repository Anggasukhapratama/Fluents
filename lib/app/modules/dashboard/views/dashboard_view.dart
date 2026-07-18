// lib/app/modules/dashboard/views/dashboard_view.dart
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

  // ===== TEMA BARU: MERAH AGAK OREN (Sunset/Red Orange) =====
  static const _primary = Color(0xFFE85D04); // Merah Oren terang
  static const _primaryLight = Color(0xFFF48C06);
  static const _primaryDark = Color(0xFFDC2F02);
  static const _secondary = Color(0xFFFFBA08); // Kuning keemasan
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _danger = Color(0xFFEF4444);

  static const _bg = Color(0xFFF8F9FA);
  static const _surface = Colors.white;
  static const _text = Color(0xFF212529);
  static const _textLight = Color(0xFF6C757D);
  static const _border = Color(0xFFE9ECEF);

  static const _shadowSmall = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
  static const _shadowMedium = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 16,
    offset: Offset(0, 6),
  );

  @override
  void initState() {
    super.initState();
    c = Get.find<DashboardController>();
    bus = Get.find<DashboardPopupBus>();

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
          color: _primary,
          backgroundColor: _surface,
          onRefresh: c.refreshDashboard,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 12),
                    _buildWelcomeCard(),
                    const SizedBox(height: 20),
                    _buildStatRow(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      title: 'Fitur Unggulan',
                      subtitle: 'Geser untuk lihat semua fitur',
                    ),
                    const SizedBox(height: 12),
                    _buildHorizontalFeatureList(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      title: 'Perjalanan Karirmu',
                      subtitle: 'Pantau progress dan pencapaianmu',
                    ),
                    const SizedBox(height: 12),
                    _buildProgressCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      title: 'Jadwal Wawancara',
                      subtitle: 'Atur pengingat latihanmu',
                    ),
                    const SizedBox(height: 12),
                    _buildScheduleCard(),
                    const SizedBox(height: 24),
                    _buildRecentActivitySection(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================= APP BAR =======================

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: _bg,
      elevation: 0,
      pinned: true,
      toolbarHeight: 70,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primary, _secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Obx(
                () => Text(
                  c.userName.value.isNotEmpty
                      ? c.userName.value[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${_getGreeting()} 👋',
                style: const TextStyle(
                  fontSize: 11,
                  color: _textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Obx(
                () => Text(
                  c.userName.value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _text,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            children: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                  boxShadow: [_shadowSmall],
                ),
                child: IconButton(
                  icon: Icon(
                    LucideIcons.bell,
                    size: 20,
                    color: hasSch ? _primary : _textLight,
                  ),
                  onPressed: _openScheduleNotificationPanel,
                ),
              ),
              if (hasSch)
                Positioned(
                  top: 12,
                  right: 18,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 18) return 'Selamat Siang';
    return 'Selamat Malam';
  }

  // ======================= WELCOME CARD =======================

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.sparkles, size: 10, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'AI POWERED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tingkatkan\nKepercayaan Diri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Latihan wawancara dengan AI Coach',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                _buildGradientButton(
                  text: 'Mulai Latihan',
                  onTap: () {
                    final route = c.homeScreenActions.isNotEmpty
                        ? c.homeScreenActions.first['route']?.toString()
                        : null;
                    if (route != null) Get.toNamed(route);
                  },
                  isWhite: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.bot, size: 48, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onTap,
    bool isWhite = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isWhite ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isWhite ? null : Border.all(color: Colors.white, width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isWhite ? _primary : Colors.white,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ===== STAT ROW - PERUBAHAN: bestPerformance & latestStatus =====
  // ============================================================

  Widget _buildStatRow() {
    return Obx(() {
      return Row(
        children: [
          Expanded(
            child: _buildStatTile(
              icon: LucideIcons.flame,
              label: 'Streak',
              value: '${c.consecutiveDays.value}',
              suffix: 'hari',
              color: const Color(0xFFF97316),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatTile(
              icon: LucideIcons.calendar,
              label: 'Sesi',
              value: '${c.totalSessions.value}',
              suffix: 'latihan',
              color: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatTile(
              icon: LucideIcons.award,
              label: 'Level',
              value: _shortLevel(c.currentLevel.value),
              suffix: '',
              color: _primary,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required String suffix,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [_shadowSmall],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _textLight,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              if (suffix.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  suffix,
                  style: const TextStyle(
                    fontSize: 9,
                    color: _textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ===== SHORT LABEL - PERUBAHAN: handle format baru =====
  // ============================================================

  String _shortLabel(String label) {
    // Handle format baru dari ProgressController
    if (label.contains('Sangat Baik') || label == '🌟 Sangat Baik (5-6)') {
      return 'Sangat Baik';
    }
    if (label.contains('Baik') || label == '✅ Baik (3-4)') {
      return 'Baik';
    }
    if (label.contains('Cukup') || label == '⚠️ Cukup (2)') {
      return 'Cukup';
    }
    if (label.contains('Perlu Latihan') || label == '💪 Perlu Latihan (0-1)') {
      return 'Berlatih';
    }
    // Fallback untuk label lama
    switch (label) {
      case 'Sangat Percaya Diri':
        return 'Sangat PD';
      case 'Siap Wawancara':
        return 'Siap';
      case 'Cukup Baik':
        return 'Cukup';
      case 'Perlu Banyak Latihan':
        return 'Berlatih';
      default:
        return label;
    }
  }

  String _shortLevel(String raw) {
    if (!raw.contains('•')) return raw;
    return raw.split('•').first.trim();
  }

  // ============================================================
  // ===== HAPUS: _getLatestLabelFromProgress() =====
  // ============================================================

  // ======================= HORIZONTAL FEATURE LIST =======================

  Widget _buildHorizontalFeatureList() {
    final actions = c.homeScreenActions;

    final features = [
      if (actions.isNotEmpty) actions[0],
      if (actions.length > 1) actions[1],
      if (actions.length > 2) actions[2],
      if (actions.length > 3) actions[3],
    ];

    final defaultFeatures = [
      {
        'name': 'Latihan Narasi',
        'icon_name': 'mic',
        'color_hex': '#8B5CF6',
        'description': 'Latih public speaking',
        'points': 5,
        'route': '/narasi-detect',
      },
      {
        'name': 'Video Wawancara',
        'icon_name': 'video',
        'color_hex': '#FF5722',
        'description': 'Rekam & evaluasi',
        'points': 10,
        'route': '/video',
      },
      {
        'name': 'Analisis CV AI',
        'icon_name': 'file-search',
        'color_hex': '#4F46E5',
        'description': 'Upload CV',
        'points': 8,
        'route': '/cv-analysis',
      },
      {
        'name': 'Cek Wajah',
        'icon_name': 'scan-face',
        'color_hex': '#0EA5E9',
        'description': 'Ekspresi & fokus',
        'points': 5,
        'route': '/face-check',
      },
    ];

    final displayFeatures = features
        .where((f) => f != null)
        .cast<Map<String, dynamic>>()
        .toList();
    final finalFeatures = displayFeatures.isEmpty
        ? defaultFeatures
        : displayFeatures.take(4).toList();

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: finalFeatures.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final feature = finalFeatures[index];
          return _buildFeatureCard(feature);
        },
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    final name = feature['name'].toString();
    final description = (feature['description'] ?? 'Mulai latihan').toString();
    final iconName = feature['icon_name']?.toString() ?? 'activity';
    final route = feature['route']?.toString();
    final pts = _toIntSafe(feature['points']);
    final colorHex = feature['color_hex']?.toString() ?? '#E85D04';
    final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));

    return GestureDetector(
      onTap: () async {
        if (route == null) return;
        await c.addPointsAndLog(title: name, route: route, points: pts);
        Get.toNamed(route);
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: [_shadowSmall],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconFromName(iconName),
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 10, color: _textLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(LucideIcons.star, size: 10, color: _secondary),
                const SizedBox(width: 4),
                Text(
                  '+$pts',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'mic':
        return LucideIcons.mic;
      case 'video':
        return LucideIcons.video;
      case 'file-search':
        return LucideIcons.fileSearch;
      case 'scan-face':
        return LucideIcons.scanFace;
      case 'book-open':
        return LucideIcons.bookOpen;
      case 'bot':
        return LucideIcons.bot;
      default:
        return LucideIcons.activity;
    }
  }

  // ======================= PROGRESS CARD =======================

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [_shadowSmall],
      ),
      child: Obx(() {
        final maxP = c.maxPointsForCurrentLevel.value;
        final curP = c.pointsInCurrentLevel.value;
        final progress = maxP > 0 ? curP / maxP : 1.0;
        final totalPoints = c.totalPoints.value;

        return Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(LucideIcons.star, color: _primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.currentLevel.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '$totalPoints',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _text,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'total poin',
                            style: TextStyle(fontSize: 11, color: _textLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    c.pointsNeededForNextLevelText.value,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: _border,
                valueColor: AlwaysStoppedAnimation<Color>(_primary),
                minHeight: 6,
              ),
            ),
          ],
        );
      }),
    );
  }

  // ======================= SCHEDULE CARD =======================

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [_shadowSmall],
      ),
      child: Obx(() {
        if (c.isLoadingSchedule.value) {
          return const Center(
            child: SizedBox(
              height: 70,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primary,
                ),
              ),
            ),
          );
        }

        final sch = c.nextSchedule.value;
        if (sch == null) {
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(LucideIcons.calendar, color: _primary, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Belum ada jadwal latihan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textLight,
                  ),
                ),
              ),
              _buildSmallButton(
                text: 'Buat',
                onTap: _showAddScheduleSheet,
                color: _primary,
              ),
            ],
          );
        }

        final id = sch['id']?.toString() ?? '';
        final dt = sch['scheduledAt'] as DateTime?;
        final note = (sch['note'] ?? '').toString().trim();
        final when = dt == null ? '-' : _formatDateTime(dt);
        final isToday = dt != null && _isToday(dt);

        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isToday ? LucideIcons.bellRing : LucideIcons.calendar,
                color: _primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'HARI INI',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: _danger,
                        ),
                      ),
                    ),
                  Text(
                    when,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _text,
                      fontSize: 13,
                    ),
                  ),
                  if (note.isNotEmpty)
                    Text(
                      note,
                      style: const TextStyle(color: _textLight, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(LucideIcons.trash2, color: _danger, size: 18),
              onPressed: () => _deleteScheduleConfirm(id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSmallButton({
    required String text,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Hari ini, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    final days = dt.difference(now).inDays;
    if (days == 1)
      return 'Besok, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ======================= RECENT ACTIVITIES =======================

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              title: 'Aktivitas Terakhir',
              subtitle: 'Rekam jejak latihanmu',
            ),
            GestureDetector(
              onTap: () => Get.find<DashboardShellController>().changeTab(2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(LucideIcons.arrowRight, size: 10, color: _primary),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          final items = c.recentActivities;
          if (items.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.activity, size: 32, color: _textLight),
                  const SizedBox(height: 8),
                  const Text(
                    'Belum ada aktivitas',
                    style: TextStyle(
                      color: _textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          final displayItems = items.length > 3
              ? items.take(3).toList()
              : items.toList();

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final a = displayItems[index];
              final meta = _activityMetaFromTitle(a.title);
              final time = _formatTimeAgo(a.at);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: meta.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(meta.icon, size: 18, color: meta.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _text,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            time,
                            style: const TextStyle(
                              color: _textLight,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+${a.points}',
                        style: TextStyle(
                          color: _success,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays} hari lalu';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _text,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 11, color: _textLight)),
      ],
    );
  }

  _ActivityMeta _activityMetaFromTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('narasi'))
      return const _ActivityMeta(
        icon: LucideIcons.mic,
        color: Color(0xFF8B5CF6),
      );
    if (t.contains('video'))
      return const _ActivityMeta(
        icon: LucideIcons.video,
        color: Color(0xFFFF5722),
      );
    if (t.contains('cv'))
      return const _ActivityMeta(
        icon: LucideIcons.fileSearch,
        color: Color(0xFF4F46E5),
      );
    if (t.contains('wajah') || t.contains('face'))
      return const _ActivityMeta(
        icon: LucideIcons.scanFace,
        color: Color(0xFF0EA5E9),
      );
    return const _ActivityMeta(icon: LucideIcons.activity, color: _primary);
  }

  // ======================= DIALOGS & BOTTOM SHEETS =======================

  void _showAddScheduleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buat Jadwal Latihan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Atur pengingat untuk latihan rutin',
              style: TextStyle(
                color: _textLight,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: noteC,
              decoration: InputDecoration(
                labelText: 'Catatan',
                hintText: 'Contoh: Latihan postur & kontak mata',
                labelStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
                        primaryColor: _primary,
                        colorScheme: ColorScheme.light(primary: _primary),
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
                        primaryColor: _primary,
                        colorScheme: ColorScheme.light(primary: _primary),
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
                    Get.back();
                    Get.snackbar(
                      'Berhasil!',
                      'Jadwal latihan telah disimpan',
                      backgroundColor: Colors.white,
                      colorText: _text,
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  } catch (e) {
                    Get.snackbar(
                      'Gagal',
                      e.toString(),
                      backgroundColor: Colors.white,
                      colorText: _text,
                    );
                  }
                },
                child: const Text(
                  'Pilih Waktu & Simpan',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primary, _primaryLight]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Siap Berlatih?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Latihan rutin setiap hari akan membantumu\nlebih percaya diri saat wawancara nanti!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textLight,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: Get.back,
                  child: const Text(
                    'Mulai Sekarang',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.bellRing,
                  color: _danger,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textLight,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: Get.back,
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          color: _textLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                        'Mulai',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
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
        'Info',
        'Belum ada jadwal latihan',
        backgroundColor: Colors.white,
        colorText: _text,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } else {
      final dt = sch['scheduledAt'] as DateTime?;
      Get.snackbar(
        'Jadwal Mendatang',
        '${_formatDateTime(dt ?? DateTime.now())} - ${sch['note'] ?? 'Latihan Wawancara'}',
        backgroundColor: Colors.white,
        colorText: _text,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _deleteScheduleConfirm(String id) async {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.trash2, color: _danger, size: 36),
              const SizedBox(height: 14),
              const Text(
                'Hapus Jadwal?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Jadwal ini akan dihapus permanen',
                style: TextStyle(
                  color: _textLight,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: Get.back,
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: _textLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        Get.back();
                        await c.deleteSchedule(id);
                        Get.snackbar(
                          'Berhasil',
                          'Jadwal telah dihapus',
                          backgroundColor: Colors.white,
                          colorText: _text,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      child: const Text(
                        'Hapus',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
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

  Future<void> _vibrateStrong() async {
    try {
      if (await Vibrate.canVibrate) {
        Vibrate.vibrateWithPauses([
          const Duration(milliseconds: 300),
          const Duration(milliseconds: 100),
          const Duration(milliseconds: 300),
        ]);
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }

  int _toIntSafe(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }
}

class _ActivityMeta {
  final IconData icon;
  final Color color;
  const _ActivityMeta({required this.icon, required this.color});
}
