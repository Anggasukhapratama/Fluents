import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/progress_controller.dart';

enum _LabelMode { day, week, month }

class ProgressView extends GetView<ProgressController> {
  const ProgressView({super.key});

  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _surface = Colors.white;
  static const Color _text = Color(0xFF0F172A);
  static const Color _textSoft = Color(0xFF475569);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _borderLight = Color(0xFFF1F5F9);

  static const Color _primary = Color(0xFF2563EB);
  static const Color _primarySoft = Color(0xFF3B82F6);
  static const Color _secondary = Color(0xFF8B5CF6);
  static const Color _accent = Color(0xFFEC4899);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);

  static const List<Color> _gradientBlue = [_primary, _primarySoft];
  static const List<Color> _gradientPurple = [_secondary, _accent];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(),
                  const SizedBox(height: 24),
                  const _ModeToggleWidget(),
                  const SizedBox(height: 20),
                  const _StatsOverviewWidget(),
                  const SizedBox(height: 24),
                  const _FilterSectionWidget(),
                  const SizedBox(height: 24),
                  _ChartSectionWidget(
                    title: 'Harian',
                    icon: Icons.calendar_today_rounded,
                    data: controller.daily,
                    labelMode: _LabelMode.day,
                    gradient: _gradientBlue,
                  ),
                  const SizedBox(height: 20),
                  _ChartSectionWidget(
                    title: 'Mingguan',
                    icon: Icons.calendar_view_week_rounded,
                    data: controller.weekly,
                    labelMode: _LabelMode.week,
                    gradient: _gradientPurple,
                  ),
                  const SizedBox(height: 20),
                  _ChartSectionWidget(
                    title: 'Bulanan',
                    icon: Icons.calendar_month_rounded,
                    data: controller.monthly,
                    labelMode: _LabelMode.month,
                    gradient: [_secondary, _primary],
                  ),
                  const SizedBox(height: 24),
                  const _LastCorrectionCardWidget(),
                  const SizedBox(height: 20),
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
      backgroundColor: _surface,
      elevation: 0,
      pinned: true,
      floating: true,
      centerTitle: false,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(12),
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
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.3),
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
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Obx(() {
                final days = controller.daysRange.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Performa Latihan Kamu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pantau perkembangan skill interview kamu',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ProgressView._borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _ModeButton(
                title: 'Latihan Narasi',
                icon: Icons.record_voice_over_rounded,
                isActive: currentMode == ProgressMode.narasi,
                onTap: () => controller.setMode(ProgressMode.narasi),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ModeButton(
                title: 'Simulasi HRD',
                icon: Icons.business_center_rounded,
                isActive: currentMode == ProgressMode.hrd,
                onTap: () => controller.setMode(ProgressMode.hrd),
              ),
            ),
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
      borderRadius: BorderRadius.circular(14),
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
          borderRadius: BorderRadius.circular(14),
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
                color: isActive ? Colors.white : ProgressView._text,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== STATS OVERVIEW WIDGET ====================

class _StatsOverviewWidget extends GetView<ProgressController> {
  const _StatsOverviewWidget();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final totalSessions = controller.daily.fold<int>(
        0,
        (sum, item) => sum + item.count,
      );

      final validItems = controller.daily
          .where((item) => item.count > 0)
          .toList();
      final avgScore = validItems.isEmpty
          ? 0.0
          : validItems.map((item) => item.avgScore).reduce((a, b) => a + b) /
                validItems.length;

      return Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Total Sesi',
              value: '$totalSessions',
              icon: Icons.folder_copy_rounded,
              gradient: ProgressView._gradientBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: 'Rata-rata Skor',
              value: avgScore.isNaN ? '0' : avgScore.toStringAsFixed(0),
              icon: Icons.star_rounded,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProgressView._surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ProgressView._borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: ProgressView._text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: ProgressView._textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProgressView._surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ProgressView._borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter & Tampilan',
            style: TextStyle(
              color: ProgressView._text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
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
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterChip(
                    label: 'Rata-rata Skor',
                    icon: Icons.insights_rounded,
                    isActive: metric == ChartMetric.avgScore,
                    onTap: () => controller.setMetric(ChartMetric.avgScore),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),

          // ✅ PERBAIKAN: PAKAI WRAP AGAR FLEXIBLE
          Obx(() {
            final daysRange = controller.daysRange.value;
            return Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  color: ProgressView._textMuted,
                  size: 18,
                ),
                const Text(
                  'Rentang:',
                  style: TextStyle(
                    color: ProgressView._text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _DateRangeOption(
                  days: 7,
                  label: '7H',
                  isActive: daysRange == 7,
                  onTap: () => controller.setDaysRange(7),
                ),
                _DateRangeOption(
                  days: 14,
                  label: '14H',
                  isActive: daysRange == 14,
                  onTap: () => controller.setDaysRange(14),
                ),
                _DateRangeOption(
                  days: 30,
                  label: '30H',
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: ProgressView._gradientBlue,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isActive ? null : ProgressView._bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? Colors.transparent : ProgressView._border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : ProgressView._textMuted,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : ProgressView._text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? ProgressView._primary : ProgressView._bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.transparent : ProgressView._border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : ProgressView._text,
            fontSize: 10,
            fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProgressView._surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ProgressView._borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: ProgressView._text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
      height: 150,
      decoration: BoxDecoration(
        color: ProgressView._bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              color: ProgressView._textMuted.withOpacity(0.3),
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada data',
              style: TextStyle(
                color: ProgressView._textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
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

    const maxH = 140.0;
    const barW = 28.0;
    const gap = 12.0;

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
                          fontSize: 10,
                          color: ProgressView._text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.first.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: ProgressView._textMuted,
                          fontWeight: FontWeight.w500,
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

// ==================== LAST CORRECTION CARD WIDGET ====================

class _LastCorrectionCardWidget extends GetView<ProgressController> {
  const _LastCorrectionCardWidget();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isNarasi = controller.mode.value == ProgressMode.narasi;
      final lastData = controller.lastDoc.value;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ProgressView._surface, Color(0xFFF9FAFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ProgressView._borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
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
                    gradient: const LinearGradient(
                      colors: [ProgressView._primary, ProgressView._secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isNarasi
                        ? Icons.tips_and_updates_rounded
                        : Icons.feedback_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isNarasi ? 'Koreksi Terakhir' : 'Feedback Terakhir',
                        style: const TextStyle(
                          color: ProgressView._text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // ✅ PERBAIKAN: PAKAI FUNCTION _formatDate
                      Text(
                        _formatDate(lastData),
                        style: TextStyle(
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
            if (lastData != null) ...[
              const SizedBox(height: 20),
              isNarasi
                  ? _NarasiFeedbackWidget(data: lastData)
                  : _HrdFeedbackWidget(data: lastData),
            ],
          ],
        ),
      );
    });
  }

  // ✅ FUNCTION UNTUK FORMAT DATE DENGAN SAFE NULL CHECK
  String _formatDate(Map<String, dynamic>? data) {
    if (data == null) return 'Belum ada data';

    try {
      final createdAt = data['createdAt'];
      if (createdAt == null) return 'Tanggal tidak tersedia';

      // Jika dari Firestore (Timestamp)
      if (createdAt is Timestamp) {
        return DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate());
      }

      // Jika sudah dalam bentuk DateTime
      if (createdAt is DateTime) {
        return DateFormat('dd MMM yyyy, HH:mm').format(createdAt);
      }

      return 'Tanggal tidak valid';
    } catch (e) {
      return 'Tanggal error';
    }
  }
}

class _NarasiFeedbackWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const _NarasiFeedbackWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final suggestions = (data['suggestions'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScoreRow(
          label: 'Confidence',
          value: '${data['nervousLabel'] ?? '-'}',
          score: data['nervousScore'],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: ProgressView._borderLight),
        const SizedBox(height: 12),
        const Text(
          'Saran Perbaikan',
          style: TextStyle(
            color: ProgressView._text,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (suggestions.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ProgressView._bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Tidak ada saran',
              style: TextStyle(color: ProgressView._textMuted, fontSize: 13),
            ),
          )
        else
          ...suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4, right: 8),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: ProgressView._primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s,
                      style: const TextStyle(
                        color: ProgressView._textSoft,
                        fontSize: 13,
                        height: 1.4,
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

class _HrdFeedbackWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HrdFeedbackWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final feedback =
        (data['feedback'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScoreRow(
          label: 'Skor',
          value: '${data['score'] ?? 0}/100',
          score: data['score'],
        ),
        const SizedBox(height: 8),
        _ScoreRow(
          label: 'Points',
          value: '${data['points'] ?? 0}',
          score: data['points'],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: ProgressView._borderLight),
        const SizedBox(height: 12),
        const Text(
          'Feedback',
          style: TextStyle(
            color: ProgressView._text,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (feedback.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ProgressView._bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Belum ada feedback',
              style: TextStyle(color: ProgressView._textMuted, fontSize: 13),
            ),
          )
        else
          ...feedback.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4, right: 8),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: ProgressView._secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                        color: ProgressView._textSoft,
                        fontSize: 13,
                        height: 1.4,
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

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final dynamic score;

  const _ScoreRow({
    required this.label,
    required this.value,
    required this.score,
  });

  Color _getColor() {
    if (score is int) {
      if (score >= 75) return ProgressView._danger;
      if (score >= 45) return ProgressView._warning;
      return ProgressView._success;
    }
    return ProgressView._text;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ProgressView._textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: _getColor(),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
