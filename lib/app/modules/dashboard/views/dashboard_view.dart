import 'dart:async';

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

  // ===== Fluent Style A (Modern + Soft) =====
  static const _brand = Color(0xFFE53935); // Fluent Red
  static const _brandDark = Color(0xFFC62828);

  static const _bg = Color(0xFFF7F5F2); // soft cream
  static const _surface = Colors.white;

  static const _text = Color(0xFF111827); // slate-900
  static const _muted = Color(0xFF6B7280); // gray-500
  static const _border = Color(0xFFE7E5E4); // stone-200
  static const _shadow = Color(0x1A000000);

  static const _good = Color(0xFF10B981);
  static const _warn = Color(0xFFF97316); // ✅ lebih kelihatan (orange)
  static const _info = Color(0xFF3B82F6);
  static const _purple = Color(0xFF7C3AED);

  // ===== Carousel =====
  final PageController _pageCtrl = PageController(viewportFraction: 0.92);
  final RxInt _heroIndex = 0.obs;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    c = Get.find<DashboardController>();
    bus = Get.find<DashboardPopupBus>();

    // ✅ Popup schedule-time (dari controller) + geter kuat + UI cantik
    ever<Map<String, dynamic>?>(bus.popupEvent, (event) async {
      if (event == null) return;

      await _vibrateStrong();

      await Get.dialog(
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border),
                boxShadow: const [
                  BoxShadow(
                    color: _shadow,
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _brand.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.alarm_rounded, color: _brand),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          event['title']?.toString() ?? 'Pengingat',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: _text,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: Get.back,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event['message']?.toString() ?? '',
                    style: const TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brand,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Get.back();
                              // default: mulai latihan pertama (Narasi)
                              final route = c.homeScreenActions.isNotEmpty
                                  ? c.homeScreenActions.first['route']
                                        ?.toString()
                                  : null;
                              if (route != null) Get.toNamed(route);
                            },
                            child: const Text(
                              'Mulai Latihan Sekarang',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        width: 56,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _brand.withOpacity(0.35)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: Get.back,
                          child: const Icon(Icons.check_rounded, color: _brand),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });

    // welcome dialog (sekali)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!c.hasShownWelcomeMessage.value) {
        Get.defaultDialog(
          title: "Selamat Datang!",
          middleText:
              "Siap latihan hari ini? Yuk tingkatkan confidence kamu 🔥",
          textConfirm: "OK",
          onConfirm: Get.back,
          confirmTextColor: Colors.white,
          buttonColor: _brand,
        );
        c.hasShownWelcomeMessage.value = true;
      }
    });

    // auto-slide carousel (opsional)
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageCtrl.hasClients) return;
      final len = _carouselItems.length;
      if (len <= 1) return;

      final next = (_heroIndex.value + 1) % len;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageCtrl.dispose();
    noteC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _bg,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black.withOpacity(0.03),
          labelStyle: const TextStyle(
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
          hintStyle: const TextStyle(color: _muted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _brand, width: 1.4),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: RefreshIndicator(
            color: _brand,
            onRefresh: c.refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroHeader(),
                  const SizedBox(height: 14),

                  _buildIllustrationCarousel(),
                  const SizedBox(height: 18),

                  _sectionHeader("Mulai Latihan Cepat"),
                  const SizedBox(height: 10),
                  _buildModernActions(),
                  const SizedBox(height: 18),

                  _sectionHeader("Progress Kamu"),
                  const SizedBox(height: 10),
                  _buildProgressPanel(),
                  const SizedBox(height: 18),

                  _sectionHeader("Jadwal Wawancara"),
                  const SizedBox(height: 10),
                  _buildScheduleCard(context),
                  const SizedBox(height: 18),

                  _sectionHeaderRow(
                    "Aktivitas Terakhir",
                    actionText: "Lihat semua",
                    onTap: () =>
                        Get.find<DashboardShellController>().changeTab(1),
                  ),
                  const SizedBox(height: 10),
                  _buildLatestActivities(),

                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ======================= HERO HEADER =======================

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [_brand.withOpacity(0.18), Colors.white.withOpacity(0.92)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _brand.withOpacity(0.18)),
        boxShadow: const [
          BoxShadow(color: _shadow, blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _brand.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _brand.withOpacity(0.16)),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: _brand,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "FLUENT AI",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: _text,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              // ✅ notif icon + badge merah kalau ada schedule
              Obx(() {
                final hasSch = c.nextSchedule.value != null;
                return Stack(
                  children: [
                    IconButton(
                      splashRadius: 22,
                      tooltip: "Notifikasi Jadwal",
                      onPressed: _openScheduleNotificationPanel,
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: _text,
                      ),
                    ),
                    if (hasSch)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: _brand,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => Text(
              "Hi, ${c.userName.value} 👋",
              style: const TextStyle(
                fontSize: 24,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "AI Interview Coach untuk bantu kamu siap kerja.",
            style: TextStyle(
              color: _muted,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Obx(
                () => _miniBadge(
                  icon: Icons.local_fire_department_rounded,
                  label: "Streak ${c.consecutiveDays.value} hari",
                  color: _warn,
                ),
              ),
              const SizedBox(width: 8),
              Obx(
                () => _miniBadge(
                  icon: Icons.star_rounded,
                  label: c.overallAverageScore.value <= 0
                      ? "Avg -"
                      : "Avg ${c.overallAverageScore.value.toStringAsFixed(1)}",
                  color: _brand,
                ),
              ),
              const SizedBox(width: 8),
              Obx(
                () => _miniBadge(
                  icon: Icons.workspace_premium_rounded,
                  label: _shortLevel(c.currentLevel.value),
                  color: _info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final route = c.homeScreenActions.isNotEmpty
                          ? c.homeScreenActions.first['route']?.toString()
                          : null;
                      if (route != null) Get.toNamed(route);
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded),
                        SizedBox(width: 6),
                        Text(
                          "Mulai Latihan",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                width: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _brand.withOpacity(0.35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: Colors.white.withOpacity(0.7),
                  ),
                  onPressed: () {
                    final ask = c.homeScreenActions.firstWhereOrNull(
                      (e) => e['name'].toString().toLowerCase().contains(
                        'tanya hrd',
                      ),
                    );
                    final route = ask?['route']?.toString();
                    if (route != null) Get.toNamed(route);
                  },
                  child: const Icon(Icons.smart_toy_rounded, color: _brand),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16), // ✅ lebih tebal
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.95),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ======================= NOTIF PANEL (tap icon) =======================

  Future<void> _openScheduleNotificationPanel() async {
    // geter halus saat membuka panel
    HapticFeedback.mediumImpact();

    final sch = c.nextSchedule.value;
    if (sch == null) {
      await Get.dialog(
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border),
                boxShadow: const [
                  BoxShadow(
                    color: _shadow,
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _brand.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          color: _brand,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Notifikasi Jadwal",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: _text,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: Get.back,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Belum ada jadwal terdekat.\nYuk pin jadwal dulu biar kamu nggak lupa ✅",
                    style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brand,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                        Get.snackbar(
                          "Info",
                          "Atur jadwal di bagian 'Jadwal Wawancara' 👇",
                          backgroundColor: Colors.white,
                          colorText: _text,
                        );
                      },
                      child: const Text(
                        "Pin Jadwal Sekarang",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }

    final dt = sch['scheduledAt'] as DateTime?;
    final note = (sch['note'] ?? '').toString().trim();
    final when = dt == null ? '-' : _formatDateTime(dt);

    await Get.dialog(
      Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _border),
              boxShadow: const [
                BoxShadow(
                  color: _shadow,
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _brand.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.alarm_rounded, color: _brand),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Jadwal Wawancara Kamu",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: _text,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _brand.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _brand.withOpacity(0.14)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Waktu",
                        style: TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        when,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _text,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Catatan",
                        style: TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note.isEmpty ? "Tanpa catatan" : note,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brand,
                            foregroundColor: Colors.white,
                            elevation: 0,
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
                            "Mulai Latihan",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      width: 56,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _brand.withOpacity(0.35)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: Get.back,
                        child: const Icon(Icons.check_rounded, color: _brand),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ======================= ILUSTRASI CAROUSEL =======================

  List<Map<String, dynamic>> get _carouselItems => [
    {
      "title": "Latihan Interview Harian",
      "subtitle": "Biar kamu makin percaya diri saat ditanya HRD.",
      "icon": Icons.record_voice_over_rounded,
      "bg": _brand,
      "image": "assets/images/ill_interview.png",
    },
    {
      "title": "AI Feedback Real-time",
      "subtitle": "Pantau kontak mata, ekspresi, dan postur kamu.",
      "icon": Icons.auto_awesome_rounded,
      "bg": _info,
      "image": "assets/images/ill_ai_scan.png",
    },
    {
      "title": "Tanya HRD AI",
      "subtitle": "Latihan jawab pertanyaan HRD kapan saja.",
      "icon": Icons.smart_toy_rounded,
      "bg": _good,
      "image": "assets/images/ill_chat.png",
    },
  ];

  Widget _buildIllustrationCarousel() {
    final items = _carouselItems;

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: items.length,
            onPageChanged: (i) => _heroIndex.value = i,
            itemBuilder: (context, i) {
              final it = items[i];
              final Color bg = it["bg"] as Color;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      colors: [
                        bg.withOpacity(0.16),
                        Colors.white.withOpacity(0.92),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: bg.withOpacity(0.18)),
                    boxShadow: const [
                      BoxShadow(
                        color: _shadow,
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: bg.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: bg.withOpacity(0.18)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    it["icon"] as IconData,
                                    size: 16,
                                    color: bg,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "AI Coach",
                                    style: TextStyle(
                                      color: bg,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              it["title"].toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              it["subtitle"].toString(),
                              style: const TextStyle(
                                color: _muted,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            it["image"].toString(),
                            width: 98,
                            height: 98,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              width: 98,
                              height: 98,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _border),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: _muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Obx(() {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (i) {
              final active = _heroIndex.value == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? _brand : Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  // ======================= SECTION HEADERS =======================

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: _text,
      ),
    );
  }

  Widget _sectionHeaderRow(
    String title, {
    String? actionText,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _text,
          ),
        ),
        const Spacer(),
        if (actionText != null)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                actionText,
                style: const TextStyle(
                  color: _brand,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ======================= QUICK ACTIONS =======================

  Widget _buildModernActions() {
    final actions = c.homeScreenActions;
    if (actions.isEmpty)
      return _emptyCard("Belum ada menu. Tambahkan actions di controller.");

    final a0 = actions[0];
    final a1 = actions.length > 1 ? actions[1] : null;
    final a2 = actions.length > 2 ? actions[2] : null;
    final a3 = actions.length > 3 ? actions[3] : null;

    return Column(
      children: [
        _bigActionCard(a0, subtitle: "Latihan bicara & nonverbal + poin"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: a1 == null
                  ? _smallPlaceholder()
                  : _smallActionCard(a1, subtitle: "Interview simulasi"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: a2 == null
                  ? _smallPlaceholder()
                  : _smallActionCard(a2, subtitle: "Chat AI HRD"),
            ),
          ],
        ),
        if (a3 != null) ...[const SizedBox(height: 12), _outlineAction(a3)],
      ],
    );
  }

  Widget _bigActionCard(Map<String, dynamic> a, {required String subtitle}) {
    final name = a['name'].toString();
    final iconName = a['icon_name']?.toString() ?? '';
    final route = a['route']?.toString();
    final pts = _toIntSafe(a['points']);
    final color = _colorFromHex(a['color_hex']?.toString() ?? '#E53935');

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () async {
        if (route == null) return;
        await c.addPointsAndLog(title: name, route: route, points: pts);
        Get.toNamed(route);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: _surface,
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(color: _shadow, blurRadius: 18, offset: Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.16)),
              ),
              child: Icon(_iconFromName(iconName), color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _brand.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _brand.withOpacity(0.12)),
                    ),
                    child: Text(
                      "+$pts poin",
                      style: const TextStyle(
                        color: _brand,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    );
  }

  Widget _smallActionCard(Map<String, dynamic> a, {required String subtitle}) {
    final name = a['name'].toString();
    final iconName = a['icon_name']?.toString() ?? '';
    final route = a['route']?.toString();
    final pts = _toIntSafe(a['points']);
    final color = _colorFromHex(a['color_hex']?.toString() ?? '#E53935');

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        if (route == null) return;
        await c.addPointsAndLog(title: name, route: route, points: pts);
        Get.toNamed(route);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.16)),
              ),
              child: Icon(_iconFromName(iconName), color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w900, color: _text),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "+$pts poin",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlineAction(Map<String, dynamic> a) {
    final route = a['route']?.toString();
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: _brand.withOpacity(0.35)),
          backgroundColor: Colors.white.withOpacity(0.8),
        ),
        onPressed: () {
          if (route != null) Get.toNamed(route);
        },
        icon: const Icon(Icons.grid_view_rounded, color: _brand),
        label: const Text(
          "Lihat fitur lainnya",
          style: TextStyle(fontWeight: FontWeight.w900, color: _brand),
        ),
      ),
    );
  }

  Widget _smallPlaceholder() {
    return Container(
      height: 146,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: const Center(
        child: Text(
          "Coming soon",
          style: TextStyle(color: _muted, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // ======================= PROGRESS =======================

  Widget _buildProgressPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(color: _shadow, blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _progressMetric(
                    icon: Icons.auto_graph_rounded,
                    title: "Rata-rata skor",
                    value: c.overallAverageScore.value <= 0
                        ? "-"
                        : c.overallAverageScore.value.toStringAsFixed(1),
                    color: _brand,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => _progressMetric(
                    icon: Icons.workspace_premium_rounded,
                    title: "Level",
                    value: _formatLevelText(
                      c.currentLevel.value,
                    ), // ✅ Beginner gak tenggelam
                    color: _info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() {
            final maxP = c.maxPointsForCurrentLevel.value;
            final curP = c.pointsInCurrentLevel.value;
            final progress = maxP > 0 ? curP / maxP : 1.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Poin: ${c.totalPoints.value}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _text,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      c.pointsNeededForNextLevelText.value,
                      style: const TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.black.withOpacity(0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(_brand),
                    minHeight: 10,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _progressMetric({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================= SCHEDULE CARD =======================

  Widget _buildScheduleCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(color: _shadow, blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event_note_rounded, size: 20, color: _text),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Atur jadwal latihan / wawancara",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: _text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Obx(() {
              if (c.isLoadingSchedule.value) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(minHeight: 6),
                  ),
                );
              }

              final sch = c.nextSchedule.value;
              if (sch == null) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: const Text(
                    "Belum ada jadwal terdekat. Yuk pin jadwal dulu 👇",
                    style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              final id = sch['id']?.toString() ?? '';
              final dt = sch['scheduledAt'] as DateTime?;
              final note = (sch['note'] ?? '').toString().trim();

              final when = dt == null ? '-' : _formatDateTime(dt);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _brand.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _brand.withOpacity(0.14)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _brand.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.alarm_rounded, color: _brand),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            when,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            note.isEmpty ? "Tanpa catatan" : note,
                            style: const TextStyle(
                              color: _muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: "Hapus jadwal",
                      icon: const Icon(Icons.delete_outline, color: _brandDark),
                      onPressed: () async {
                        if (id.isEmpty) return;

                        final ok = await Get.dialog<bool>(
                          AlertDialog(
                            title: const Text("Hapus jadwal?"),
                            content: const Text(
                              "Jadwal ini akan dihapus permanen.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(result: false),
                                child: const Text("Batal"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _brand,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Get.back(result: true),
                                child: const Text(
                                  "Hapus",
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (ok != true) return;

                        try {
                          await c.deleteSchedule(id);
                          Get.snackbar(
                            "Berhasil",
                            "Jadwal dihapus ✅",
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
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            TextField(
              controller: noteC,
              decoration: const InputDecoration(
                labelText: "Catatan (opsional)",
                hintText: "contoh: posisi Frontend, jam 10 pagi",
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.push_pin_rounded),
                label: const Text(
                  "Pin Jadwal",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                onPressed: () async {
                  final now = DateTime.now();

                  final date = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: DateTime(now.year + 2),
                  );
                  if (date == null) return;

                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(
                      now.add(const Duration(minutes: 30)),
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
                    FocusScope.of(context).unfocus();

                    Get.snackbar(
                      "Berhasil",
                      "Jadwal tersimpan ✅",
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================= ACTIVITIES =======================

  Widget _buildLatestActivities() {
    return Obx(() {
      final items = c.recentActivities;

      if (items.isEmpty) {
        return _emptyCard("Belum ada aktivitas.\nMulai latihan sekarang!");
      }

      return Column(
        children: items.map((a) {
          final t =
              '${a.at.day.toString().padLeft(2, '0')}/${a.at.month.toString().padLeft(2, '0')} '
              '${a.at.hour.toString().padLeft(2, '0')}:${a.at.minute.toString().padLeft(2, '0')}';

          final meta = _activityMetaFromTitle(a.title);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
              boxShadow: const [
                BoxShadow(color: _shadow, blurRadius: 14, offset: Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: meta.color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: meta.color.withOpacity(0.18)),
                  ),
                  child: Icon(meta.icon, size: 22, color: meta.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            t,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: meta.color.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: meta.color.withOpacity(0.16),
                              ),
                            ),
                            child: Text(
                              "+${a.points} poin",
                              style: TextStyle(
                                color: meta.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "Buka lagi",
                  icon: Icon(Icons.chevron_right_rounded, color: meta.color),
                  onPressed: () {
                    if (a.route.isNotEmpty) Get.toNamed(a.route);
                  },
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _muted,
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ======================= HELPERS =======================

  Future<void> _vibrateStrong() async {
    try {
      final canVibrate = await Vibrate.canVibrate;

      if (!canVibrate) {
        HapticFeedback.heavyImpact();
        return;
      }

      // ✅ ini geter lebih terasa
      Vibrate.vibrateWithPauses([
        const Duration(milliseconds: 0),
        const Duration(milliseconds: 450),
        const Duration(milliseconds: 120),
        const Duration(milliseconds: 520),
        const Duration(milliseconds: 120),
        const Duration(milliseconds: 650),
      ]);
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} • '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatLevelText(String raw) {
    // "Lv 1 • Beginner" => "Lv 1\nBeginner"
    if (!raw.contains('•')) return raw;
    final parts = raw.split('•');
    final lv = parts.first.trim();
    final name = parts.last.trim();
    return "$lv\n$name";
  }

  String _shortLevel(String raw) {
    // badge di header: cukup "Lv 1"
    if (!raw.contains('•')) return raw;
    return raw.split('•').first.trim();
  }

  _ActivityMeta _activityMetaFromTitle(String title) {
    final t = title.toLowerCase();

    if (t.contains('materi')) {
      return const _ActivityMeta(icon: Icons.menu_book_rounded, color: _info);
    }
    if (t.contains('narasi')) {
      return const _ActivityMeta(
        icon: Icons.record_voice_over_rounded,
        color: _purple,
      );
    }
    if (t.contains('tanya hrd')) {
      return const _ActivityMeta(icon: Icons.smart_toy_rounded, color: _good);
    }
    if (t.contains('simulasi hrd') || t.contains('hrd sim')) {
      return const _ActivityMeta(icon: Icons.groups_rounded, color: _good);
    }
    if (t.contains('cek wajah') || t.contains('face')) {
      return const _ActivityMeta(
        icon: Icons.face_retouching_natural_rounded,
        color: _info,
      );
    }
    if (t.contains('video')) {
      return const _ActivityMeta(icon: Icons.videocam_rounded, color: _brand);
    }

    return const _ActivityMeta(icon: Icons.bolt_rounded, color: _brand);
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'book-open':
        return LucideIcons.bookOpen;
      case 'users':
        return LucideIcons.users;
      case 'message-circle':
        return LucideIcons.messageCircle;
      case 'help-circle':
        return LucideIcons.helpCircle;
      case 'video':
        return LucideIcons.video;
      case 'scan-face':
        return LucideIcons.scanFace;
      case 'agent':
        return LucideIcons.bot;
      case 'grid':
        return LucideIcons.grid;
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
}

class _ActivityMeta {
  final IconData icon;
  final Color color;
  const _ActivityMeta({required this.icon, required this.color});
}
