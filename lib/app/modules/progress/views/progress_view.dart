import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/progress_controller.dart';

enum _LabelMode { day, week, month }

class ProgressView extends GetView<ProgressController> {
  const ProgressView({super.key});

  static const Color _bg = Color(0xFFF4F7FA);
  static const Color _surface = Colors.white;
  static const Color _text = Color(0xFF1E293B);
  static const Color _textSoft = Color(0xFF475569);
  static const Color _textMuted = Color(0xFF94A3B8);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _borderLight = Color(0xFFF1F5F9);

  static const Color _primary = Color(0xFF3B82F6);
  static const Color _primaryDark = Color(0xFF2563EB);
  static const Color _secondary = Color(0xFF8B5CF6);
  static const Color _accent = Color(0xFFEC4899);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);

  static const List<Color> _gradientBlue = [_primary, _primaryDark];
  static const List<Color> _gradientPurple = [_secondary, _accent];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(),
                  const SizedBox(height: 24),
                  const _ModeToggleWidget(),
                  const SizedBox(height: 24),

                  // 🔥 Evaluasi Terakhir (Hero Card) ditaruh paling atas
                  const _LastCorrectionCardWidget(),
                  const SizedBox(height: 28),

                  const Text(
                    'Statistik Performa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _StatsOverviewWidget(),
                  const SizedBox(height: 20),
                  const _FilterSectionWidget(),
                  const SizedBox(height: 24),

                  _ChartSectionWidget(
                    title: 'Tren Harian',
                    icon: Icons.calendar_today_rounded,
                    data: controller.daily,
                    labelMode: _LabelMode.day,
                    gradient: _gradientBlue,
                  ),
                  const SizedBox(height: 20),
                  _ChartSectionWidget(
                    title: 'Tren Mingguan',
                    icon: Icons.calendar_view_week_rounded,
                    data: controller.weekly,
                    labelMode: _LabelMode.week,
                    gradient: _gradientPurple,
                  ),
                  const SizedBox(height: 20),
                  _ChartSectionWidget(
                    title: 'Tren Bulanan',
                    icon: Icons.calendar_month_rounded,
                    data: controller.monthly,
                    labelMode: _LabelMode.month,
                    gradient: [_secondary, _primaryDark],
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: _bg,
      elevation: 0,
      pinned: true,
      floating: true,
      centerTitle: true,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: _text,
          onPressed: () => Get.back(),
        ),
      ),
      title: const Text(
        'Progress Report',
        style: TextStyle(
          color: _text,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: _text,
            onPressed: () =>
                controller.listenAll(daysBack: controller.daysRange.value),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryDark, _primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Obx(() {
                final days = controller.daysRange.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '$days Hari Terakhir',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Performa Latihan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pantau terus perkembangan skill kamu agar siap hadapi HRD sesungguhnya!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MODE TOGGLE WIDGET ====================

class _ModeToggleWidget extends GetView<ProgressController> {
  const _ModeToggleWidget();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentMode = controller.mode.value;
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: ProgressView._surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _ModeButton(
                title: 'Narasi',
                icon: Icons.record_voice_over_rounded,
                isActive: currentMode == ProgressMode.narasi,
                onTap: () => controller.setMode(ProgressMode.narasi),
              ),
            ),
            // const SizedBox(width: 6),
            // Expanded(
            //   child: _ModeButton(
            //     title: 'Simulasi HRD',
            //     icon: Icons.business_center_rounded,
            //     isActive: currentMode == ProgressMode.hrd,
            //     onTap: () => controller.setMode(ProgressMode.hrd),
            //   ),
            // ),
          ],
        ),
      );
    });
  }
}

class _ModeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: ProgressView._gradientBlue,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : ProgressView._textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : ProgressView._textSoft,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== HERO CARD: LAST CORRECTION WIDGET ====================

class _LastCorrectionCardWidget extends GetView<ProgressController> {
  const _LastCorrectionCardWidget();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isNarasi = controller.mode.value == ProgressMode.narasi;
      final lastData = controller.lastDoc.value;

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ProgressView._surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: ProgressView._primary.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: ProgressView._primary.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Top
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ProgressView._primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isNarasi
                        ? Icons.workspace_premium_rounded
                        : Icons.star_border_rounded,
                    color: ProgressView._primaryDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isNarasi ? 'Evaluasi Terakhir' : 'Feedback Terakhir',
                        style: const TextStyle(
                          color: ProgressView._text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(lastData),
                        style: const TextStyle(
                          color: ProgressView._textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (lastData == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Belum ada data latihan.\nAyo mulai simulasi pertamamu!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ProgressView._textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              isNarasi
                  ? _NarasiHeroFeedbackWidget(data: lastData)
                  : _HrdHeroFeedbackWidget(data: lastData),
          ],
        ),
      );
    });
  }

  String _formatDate(Map<String, dynamic>? data) {
    if (data == null) return '';
    try {
      final createdAt = data['createdAt'];
      if (createdAt == null) return 'Tanggal tidak tersedia';

      if (createdAt is Timestamp) {
        return DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate());
      }
      if (createdAt is DateTime) {
        return DateFormat('dd MMM yyyy, HH:mm').format(createdAt);
      }
      return 'Tanggal tidak valid';
    } catch (e) {
      return 'Tanggal error';
    }
  }
}

// KHUSUS TAMPILAN NARASI YANG MENARIK (HERO)
class _NarasiHeroFeedbackWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const _NarasiHeroFeedbackWidget({required this.data});

  Color _getColor(num score) {
    if (score >= 75) return ProgressView._success;
    if (score >= 50) return ProgressView._warning;
    return ProgressView._danger;
  }

  // Logic untuk memunculkan Label/Kategori sesuai standar HRD kita
  String _getEyeLabel(num score) => score >= 70 ? 'Fokus' : 'Terdistraksi';
  String _getPostureLabel(num score) => score >= 60 ? 'Siap' : 'Miring';
  String _getSmileLabel(num score) => score >= 40 ? 'Ramah' : 'Kaku';

  @override
  Widget build(BuildContext context) {
    final suggestions = (data['suggestions'] as List?)?.cast<String>() ?? [];
    final overallConf = data['overallConfidence'] ?? 0;
    final overallLabel = data['overallLabel'] ?? '-';
    final scoreEye = data['scoreEye'] ?? 0;
    final scorePosture = data['scorePosture'] ?? 0;
    final scoreSmile = data['scoreSmile'] ?? 0;

    final mainColor = _getColor(overallConf);

    return Column(
      children: [
        // BIG SCORE SECTION
        Center(
          child: Column(
            children: [
              const Text(
                'Overall Confidence',
                style: TextStyle(
                  color: ProgressView._textSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$overallConf',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: mainColor,
                      letterSpacing: -2,
                    ),
                  ),
                  const Text(
                    '/100',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: ProgressView._textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  overallLabel,
                  style: TextStyle(
                    color: mainColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // 3 BADGES SECTION (Mata, Postur, Senyum) + LABEL
        Row(
          children: [
            Expanded(
              child: _buildMiniStat(
                '👀 Mata',
                scoreEye,
                _getEyeLabel(scoreEye),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStat(
                '🧍 Postur',
                scorePosture,
                _getPostureLabel(scorePosture),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStat(
                '😊 Senyum',
                scoreSmile,
                _getSmileLabel(scoreSmile),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Divider(height: 1, color: ProgressView._borderLight),
        const SizedBox(height: 20),

        // SUGGESTIONS SECTION
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Action Plan / Saran',
            style: TextStyle(
              color: ProgressView._text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (suggestions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ProgressView._success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: ProgressView._success,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Luar biasa! Pertahankan performa profesional ini.',
                    style: TextStyle(
                      color: ProgressView._text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ProgressView._primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: ProgressView._primaryDark,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s,
                      style: const TextStyle(
                        color: ProgressView._textSoft,
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMiniStat(String title, num score, String label) {
    final color = _getColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: ProgressView._bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProgressView._borderLight),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ProgressView._textSoft,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          // Label Kategori (Fokus, Siap, Ramah, dll)
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// KHUSUS TAMPILAN HRD YANG MENARIK
class _HrdHeroFeedbackWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HrdHeroFeedbackWidget({required this.data});

  Color _getColor(num score) {
    if (score >= 75) return ProgressView._success;
    if (score >= 50) return ProgressView._warning;
    return ProgressView._danger;
  }

  @override
  Widget build(BuildContext context) {
    final feedback =
        (data['feedback'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final score = data['score'] ?? 0;
    final mainColor = _getColor(score);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                const Text(
                  'Skor Akhir',
                  style: TextStyle(
                    color: ProgressView._textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$score/100',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: mainColor,
                  ),
                ),
              ],
            ),
            Container(width: 1, height: 40, color: ProgressView._border),
            Column(
              children: [
                const Text(
                  'Total Points',
                  style: TextStyle(
                    color: ProgressView._textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data['points'] ?? 0}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: ProgressView._secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, color: ProgressView._borderLight),
        const SizedBox(height: 20),

        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Catatan HRD',
            style: TextStyle(
              color: ProgressView._text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (feedback.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ProgressView._bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Belum ada feedback mendetail.',
              style: TextStyle(color: ProgressView._textMuted),
            ),
          )
        else
          ...feedback.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ProgressView._secondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 12,
                      color: ProgressView._secondary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                        color: ProgressView._textSoft,
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ==================== STATS OVERVIEW WIDGET ====================

class _StatsOverviewWidget extends GetView<ProgressController> {
  const _StatsOverviewWidget();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ✅ Gunakan method getOverallStats() yang akurat
      final stats = controller.getOverallStats();
      final totalSessions = stats['totalSessions'] as int;
      final avgScore = stats['avgScore'] as double;

      return Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Total Latihan',
              value: '$totalSessions',
              icon: Icons.folder_special_rounded,
              gradient: ProgressView._gradientBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              title: 'Rata-rata Skor',
              value: avgScore.toStringAsFixed(0),
              icon: Icons.auto_awesome_rounded,
              gradient: ProgressView._gradientPurple,
            ),
          ),
        ],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ProgressView._surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: ProgressView._text,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: ProgressView._textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== FILTER SECTION WIDGET ====================

class _FilterSectionWidget extends GetView<ProgressController> {
  const _FilterSectionWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ProgressView._surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Grafik',
            style: TextStyle(
              color: ProgressView._text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final metric = controller.chartMetric.value;
            return Row(
              children: [
                Expanded(
                  child: _FilterChip(
                    label: 'Jumlah Sesi',
                    icon: Icons.stacked_bar_chart_rounded,
                    isActive: metric == ChartMetric.count,
                    onTap: () => controller.setMetric(ChartMetric.count),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FilterChip(
                    label: 'Skor Rata-rata',
                    icon: Icons.insights_rounded,
                    isActive: metric == ChartMetric.avgScore,
                    onTap: () => controller.setMetric(ChartMetric.avgScore),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          Obx(() {
            final daysRange = controller.daysRange.value;
            return Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  color: ProgressView._textMuted,
                  size: 20,
                ),
                const Text(
                  'Rentang Waktu:',
                  style: TextStyle(
                    color: ProgressView._textSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _DateRangeOption(
                  days: 7,
                  label: '7 Hari',
                  isActive: daysRange == 7,
                  onTap: () => controller.setDaysRange(7),
                ),
                _DateRangeOption(
                  days: 14,
                  label: '14 Hari',
                  isActive: daysRange == 14,
                  onTap: () => controller.setDaysRange(14),
                ),
                _DateRangeOption(
                  days: 30,
                  label: '30 Hari',
                  isActive: daysRange == 30,
                  onTap: () => controller.setDaysRange(30),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? ProgressView._primary.withOpacity(0.1)
              : ProgressView._bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? ProgressView._primary.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive
                  ? ProgressView._primaryDark
                  : ProgressView._textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? ProgressView._primaryDark
                    : ProgressView._textSoft,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangeOption extends StatelessWidget {
  final int days;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DateRangeOption({
    required this.days,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? ProgressView._text : ProgressView._bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : ProgressView._textSoft,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ==================== CHART SECTION WIDGET ====================

class _ChartSectionWidget extends GetView<ProgressController> {
  final String title;
  final IconData icon;
  final RxList<Agg> data;
  final _LabelMode labelMode;
  final List<Color> gradient;

  const _ChartSectionWidget({
    required this.title,
    required this.icon,
    required this.data,
    required this.labelMode,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ProgressView._surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: gradient.first.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: gradient.first, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  color: ProgressView._text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Obx(() {
            if (data.isEmpty) {
              return const _EmptyChartWidget();
            }
            return _BarChartWidget(
              items: data,
              labelMode: labelMode,
              metric: controller.chartMetric.value,
              gradient: gradient,
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyChartWidget extends StatelessWidget {
  const _EmptyChartWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: ProgressView._bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ProgressView._borderLight, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              color: ProgressView._textMuted.withOpacity(0.4),
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum ada data rekaman',
              style: TextStyle(
                color: ProgressView._textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final RxList<Agg> items;
  final _LabelMode labelMode;
  final ChartMetric metric;
  final List<Color> gradient;

  const _BarChartWidget({
    required this.items,
    required this.labelMode,
    required this.metric,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final values = items.map((e) {
      if (metric == ChartMetric.count) return e.count.toDouble();
      return e.avgScore;
    }).toList();

    double maxValue = 0;
    for (final v in values) {
      if (v > maxValue) maxValue = v;
    }
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    const maxH = 150.0;
    const barW = 32.0;
    const gap = 16.0;

    return SizedBox(
      height: maxH + 60,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final neededW = items.length * (barW + gap) + 12;
          final shouldScroll = neededW > constraints.maxWidth;

          final row = Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(items.length, (index) {
              final e = items[index];
              final raw = metric == ChartMetric.count
                  ? e.count.toDouble()
                  : e.avgScore;

              final h = (raw / safeMax) * maxH;
              final label = _formatLabel(e.key, labelMode);
              final displayValue = _formatValue(e, metric);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: gap / 2),
                child: SizedBox(
                  width: barW,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        displayValue,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ProgressView._text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.first.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: ProgressView._textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );

          if (!shouldScroll) return Center(child: row);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: row,
          );
        },
      ),
    );
  }

  String _formatValue(Agg e, ChartMetric metric) {
    if (metric == ChartMetric.count) {
      return e.count == 0 ? '' : '${e.count}';
    }
    if (e.count == 0) return '';
    return e.avgScore.toStringAsFixed(0);
  }

  String _formatLabel(String key, _LabelMode mode) {
    switch (mode) {
      case _LabelMode.day:
        try {
          final date = DateFormat('yyyy-MM-dd').parse(key);
          return DateFormat('dd MMM').format(date);
        } catch (_) {
          return key.length >= 5 ? key.substring(5) : key;
        }
      case _LabelMode.week:
        final idx = key.indexOf('-W');
        if (idx >= 0) {
          final weekNum = key.substring(idx + 2);
          return 'W$weekNum';
        }
        return key;
      case _LabelMode.month:
        try {
          final parts = key.split('-');
          if (parts.length >= 2) {
            final month = int.parse(parts[1]);
            return DateFormat('MMM').format(DateTime(2000, month));
          }
        } catch (_) {}
        return key.length >= 5 ? key.substring(5) : key;
    }
  }
}
