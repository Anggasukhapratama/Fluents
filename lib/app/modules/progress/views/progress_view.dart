// lib/app/views/progress_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/progress_controller.dart';

enum _LabelMode { day, week, month }

class ProgressView extends GetView<ProgressController> {
  const ProgressView({super.key});

  // ==================== DESIGN SYSTEM ====================
  static const Color _bg = Color(0xFFF0F4F8);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textBody = Color(0xFF334155);
  static const Color _textMuted = Color(0xFF94A3B8);
  static const Color _border = Color(0xFFE2E8F0);

  // Warna untuk 3 kategori
  static const Color _eyeColor = Color(0xFF3B82F6); // Biru - Kontak Mata
  static const Color _smileColor = Color(0xFFF59E0B); // Emas - Ekspresi
  static const Color _postureColor = Color(0xFF10B981); // Hijau - Postur
  static const Color _gold = Color(0xFFD4AF37);

  // Level warna
  static const Color _levelExcellent = Color(0xFF10B981);
  static const Color _levelGood = Color(0xFF3B82F6);
  static const Color _levelWarning = Color(0xFFF59E0B);
  static const Color _levelBad = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            controller.listenAll(daysBack: controller.daysRange.value);
            controller.listenLastCorrection();
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeroHeader(),
                    const SizedBox(height: 20),

                    // ===== 3 KATEGORI UTAMA (RADIAL PROGRESS) =====
                    const _ThreeCategoriesCard(),
                    const SizedBox(height: 20),

                    // ===== EVALUASI TERBARU =====
                    const _LatestEvaluationCard(),
                    const SizedBox(height: 24),

                    // ===== STATISTIK RINGKASAN =====
                    const _StatsSummaryRow(),
                    const SizedBox(height: 24),

                    // ===== FILTER & CHART =====
                    const _FilterSectionWidget(),
                    const SizedBox(height: 20),

                    _ChartSectionWidget(
                      title: 'Tren Harian',
                      icon: Icons.calendar_today_rounded,
                      data: controller.daily,
                      labelMode: _LabelMode.day,
                      color: _eyeColor,
                    ),
                    const SizedBox(height: 20),

                    _ChartSectionWidget(
                      title: 'Tren Mingguan',
                      icon: Icons.calendar_view_week_rounded,
                      data: controller.weekly,
                      labelMode: _LabelMode.week,
                      color: _smileColor,
                    ),
                    const SizedBox(height: 20),

                    _ChartSectionWidget(
                      title: 'Tren Bulanan',
                      icon: Icons.calendar_month_rounded,
                      data: controller.monthly,
                      labelMode: _LabelMode.month,
                      color: _postureColor,
                    ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
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
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: _textDark,
          onPressed: () => Get.back(),
        ),
      ),
      title: const Text(
        'Gudang Bakat',
        style: TextStyle(
          color: _textDark,
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
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: _textDark,
            onPressed: () {
              controller.listenAll(daysBack: controller.daysRange.value);
              controller.listenLastCorrection();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2540), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  color: _gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: _gold,
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
                    color: Colors.white.withOpacity(0.15),
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
            'Perkembanganmu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pantau 3 aspek kunci: Kontak Mata, Ekspresi, dan Postur',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 3 KATEGORI UTAMA DENGAN RADIAL PROGRESS ====================
class _ThreeCategoriesCard extends GetView<ProgressController> {
  const _ThreeCategoriesCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ProgressView._surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analisis 3 Dimensi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ProgressView._textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Berdasarkan latihan terakhirmu',
              style: TextStyle(fontSize: 12, color: ProgressView._textMuted),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _CategoryRadial(
                  title: 'Kontak Mata',
                  icon: Icons.visibility_rounded,
                  score: controller.latestEyeScore.value,
                  label: controller.latestEyeLabel.value,
                  count: controller.latestEyeCount.value,
                  color: ProgressView._eyeColor,
                ),
                const SizedBox(width: 12),
                _CategoryRadial(
                  title: 'Ekspresi',
                  icon: Icons.mood_rounded,
                  score: controller.latestSmileScore.value,
                  label: controller.latestSmileLabel.value,
                  count: controller.latestSmileCount.value,
                  color: ProgressView._smileColor,
                ),
                const SizedBox(width: 12),
                _CategoryRadial(
                  title: 'Postur',
                  icon: Icons.accessibility_new_rounded,
                  score: controller.latestPostureScore.value,
                  label: controller.latestPostureLabel.value,
                  count: controller.latestPostureCount.value,
                  color: ProgressView._postureColor,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _CategoryRadial extends StatelessWidget {
  final String title;
  final IconData icon;
  final int score;
  final String label;
  final int count;
  final Color color;

  const _CategoryRadial({
    required this.title,
    required this.icon,
    required this.score,
    required this.label,
    required this.count,
    required this.color,
  });

  Color _getScoreColor(int score) {
    if (score >= 80) return ProgressView._levelExcellent;
    if (score >= 60) return ProgressView._levelGood;
    if (score >= 40) return ProgressView._levelWarning;
    return ProgressView._levelBad;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(score);
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                    const Text(
                      'poin',
                      style: TextStyle(
                        fontSize: 10,
                        color: ProgressView._textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ProgressView._textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scoreColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (count > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$count x pelanggaran',
                style: const TextStyle(
                  fontSize: 9,
                  color: ProgressView._textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==================== EVALUASI TERBARU (HERO CARD) ====================
class _LatestEvaluationCard extends GetView<ProgressController> {
  const _LatestEvaluationCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasData = controller.lastDoc.value != null;

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF8FAFE), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: ProgressView._gold.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ProgressView._gold.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                    color: ProgressView._gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: ProgressView._gold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evaluasi Terakhir',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ProgressView._textDark,
                        ),
                      ),
                      Text(
                        _formatDate(controller.lastDoc.value),
                        style: const TextStyle(
                          fontSize: 11,
                          color: ProgressView._textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (!hasData)
              const _EmptyEvaluationWidget()
            else
              const _EvaluationContentWidget(),
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
      DateTime dateTime;
      if (createdAt is Timestamp) {
        dateTime = createdAt.toDate();
      } else if (createdAt is DateTime) {
        dateTime = createdAt;
      } else {
        return 'Tanggal tidak valid';
      }
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    } catch (e) {
      return 'Tanggal error';
    }
  }
}

class _EmptyEvaluationWidget extends StatelessWidget {
  const _EmptyEvaluationWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.insights_rounded,
              size: 48,
              color: ProgressView._textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada data latihan',
              style: TextStyle(
                color: ProgressView._textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mulai latihan interview pertamamu sekarang!',
              style: TextStyle(color: ProgressView._textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvaluationContentWidget extends GetView<ProgressController> {
  const _EvaluationContentWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Overall Score
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ProgressView._textDark.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Skor Keseluruhan',
                      style: TextStyle(
                        fontSize: 12,
                        color: ProgressView._textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${controller.latestOverallScore.value}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: ProgressView._textDark,
                      ),
                    ),
                    const Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 14,
                        color: ProgressView._textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 50, color: ProgressView._border),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Level',
                      style: TextStyle(
                        fontSize: 12,
                        color: ProgressView._textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getLevelColor(
                          controller.latestOverallLabel.value,
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        controller.latestOverallLabel.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _getLevelColor(
                            controller.latestOverallLabel.value,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3 Category Mini Stats
        Row(
          children: [
            _MiniCategoryStat(
              title: 'Kontak Mata',
              label: controller.latestEyeLabel.value,
              score: controller.latestEyeScore.value,
              color: ProgressView._eyeColor,
            ),
            const SizedBox(width: 12),
            _MiniCategoryStat(
              title: 'Ekspresi',
              label: controller.latestSmileLabel.value,
              score: controller.latestSmileScore.value,
              color: ProgressView._smileColor,
            ),
            const SizedBox(width: 12),
            _MiniCategoryStat(
              title: 'Postur',
              label: controller.latestPostureLabel.value,
              score: controller.latestPostureScore.value,
              color: ProgressView._postureColor,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Suggestion / Action Plan
        if (controller.latestSuggestions.isNotEmpty) ...[
          const Divider(color: ProgressView._border),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: ProgressView._gold,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Action Plan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ProgressView._textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...controller.latestSuggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4, right: 10),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: ProgressView._gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s,
                      style: const TextStyle(
                        fontSize: 13,
                        color: ProgressView._textBody,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getLevelColor(String label) {
    if (label == 'Percaya Diri') return ProgressView._levelExcellent;
    if (label == 'Cukup Percaya Diri') return ProgressView._levelGood;
    return ProgressView._levelWarning;
  }
}

class _MiniCategoryStat extends StatelessWidget {
  final String title;
  final String label;
  final int score;
  final Color color;

  const _MiniCategoryStat({
    required this.title,
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== STATISTIK RINGKASAN ====================
class _StatsSummaryRow extends GetView<ProgressController> {
  const _StatsSummaryRow();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = controller.getOverallStats();
      final latest = controller.getLatestPerformance();

      return Row(
        children: [
          _StatSummaryCard(
            title: 'Total Latihan',
            value: '${stats['totalSessions']}',
            icon: Icons.folder_special_rounded,
            color: ProgressView._eyeColor,
          ),
          const SizedBox(width: 14),
          _StatSummaryCard(
            title: 'Rata-rata Skor',
            value: (stats['avgScore'] as double).toStringAsFixed(0),
            icon: Icons.auto_awesome_rounded,
            color: ProgressView._gold,
            suffix: 'pts',
          ),
          const SizedBox(width: 14),
          _StatSummaryCard(
            title: 'Konsistensi',
            value: '${controller.consistentStreak.value}',
            icon: Icons.local_fire_department_rounded,
            color: ProgressView._postureColor,
            suffix: 'hari',
          ),
        ],
      );
    });
  }
}

class _StatSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? suffix;

  const _StatSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: ProgressView._surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: ProgressView._textDark,
              ),
            ),
            if (suffix != null)
              Text(
                suffix!,
                style: const TextStyle(
                  fontSize: 10,
                  color: ProgressView._textMuted,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ProgressView._textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== FILTER SECTION ====================
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
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Grafik',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ProgressView._textDark,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final metric = controller.chartMetric.value;
            return Row(
              children: [
                _FilterChip(
                  label: 'Jumlah Sesi',
                  icon: Icons.stacked_bar_chart_rounded,
                  isActive: metric == ChartMetric.count,
                  onTap: () => controller.setMetric(ChartMetric.count),
                ),
                const SizedBox(width: 12),
                _FilterChip(
                  label: 'Skor Rata-rata',
                  icon: Icons.insights_rounded,
                  isActive: metric == ChartMetric.avgScore,
                  onTap: () => controller.setMetric(ChartMetric.avgScore),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          Obx(() {
            final daysRange = controller.daysRange.value;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  color: ProgressView._textMuted,
                  size: 18,
                ),
                const Text(
                  'Rentang:',
                  style: TextStyle(
                    color: ProgressView._textMuted,
                    fontSize: 13,
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? ProgressView._eyeColor.withOpacity(0.1)
                : ProgressView._bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? ProgressView._eyeColor.withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive
                    ? ProgressView._eyeColor
                    : ProgressView._textMuted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? ProgressView._eyeColor
                      : ProgressView._textMuted,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
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
          color: isActive ? ProgressView._textDark : ProgressView._bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : ProgressView._textMuted,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ==================== CHART SECTION ====================
class _ChartSectionWidget extends GetView<ProgressController> {
  final String title;
  final IconData icon;
  final RxList<Agg> data;
  final _LabelMode labelMode;
  final Color color;

  const _ChartSectionWidget({
    required this.title,
    required this.icon,
    required this.data,
    required this.labelMode,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ProgressView._surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ProgressView._textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() {
            if (data.isEmpty) {
              return const _EmptyChartWidget();
            }
            return _BarChartWidget(
              items: data,
              labelMode: labelMode,
              metric: controller.chartMetric.value,
              color: color,
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
      height: 140,
      decoration: BoxDecoration(
        color: ProgressView._bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProgressView._border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 40,
              color: ProgressView._textMuted.withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            const Text(
              'Belum ada data',
              style: TextStyle(
                color: ProgressView._textMuted,
                fontSize: 13,
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
  final Color color;

  const _BarChartWidget({
    required this.items,
    required this.labelMode,
    required this.metric,
    required this.color,
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

    const maxH = 120.0;
    const barW = 28.0;
    const gap = 12.0;

    return SizedBox(
      height: maxH + 50,
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
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: ProgressView._textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: h,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
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
