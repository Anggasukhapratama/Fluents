// lib/app/modules/progress/views/progress_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/progress_controller.dart';
import '../../../models/practice_session_model.dart';

class ProgressView extends GetView<ProgressController> {
  const ProgressView({super.key});

  static const Color _primaryDark = Color(0xFF0A2540);
  static const Color _primaryGold = Color(0xFFD4AF37);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surfaceLight = Color(0xFFF8FAFE);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceLight,
      appBar: AppBar(
        title: const Text(
          'Progress Latihan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => controller.refreshData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.sessions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memuat data latihan...'),
              ],
            ),
          );
        }

        if (controller.sessions.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async => controller.refreshData(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatsSummary(),
              const SizedBox(height: 16),
              _buildDailyChart(),
              const SizedBox(height: 16),
              _buildLevelFilter(),
              const SizedBox(height: 12),
              _buildJobFilter(),
              const SizedBox(height: 12),
              Obx(() => _buildSessionHistory()),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights_outlined, size: 64, color: _textMuted),
            const SizedBox(height: 16),
            Text(
              'Belum ada latihan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lakukan latihan wawancara pertama Anda',
              style: TextStyle(color: _textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/narasi-practice'),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Mulai Latihan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGold,
                foregroundColor: _primaryDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryDark, const Color(0xFF1E3A5F)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: _primaryGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total ${controller.totalSessions.value} Latihan',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${controller.totalPoints.value} Poin Terkumpul',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.2), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _statItem(
                'Label Terbaik',
                controller.bestLabel.value,
                controller.getLabelColor(controller.bestLabel.value),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.2),
              ),
              _statItem(
                'Terakhir',
                controller.latestLabel.value,
                controller.getLabelColor(controller.latestLabel.value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: _primaryGold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.improvementNote.value,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ===== GRAFIK BARU (LINE CHART + BAR CHART) =====
  // ============================================================

  Widget _buildDailyChart() {
    return Obx(() {
      final stats = controller.dailyStats;
      final trend = controller.performanceTrend;
      final labels = controller.trendLabels;

      if (stats.isEmpty || stats.every((s) => s.sessionCount == 0)) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Icon(Icons.bar_chart_rounded, size: 48, color: _textMuted),
              const SizedBox(height: 12),
              Text(
                'Belum ada data latihan 7 hari terakhir',
                style: TextStyle(color: _textMuted, fontSize: 13),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.insights_rounded, size: 18, color: _primaryDark),
                    SizedBox(width: 6),
                    Text(
                      'Tren Performa 7 Hari',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _primaryDark,
                      ),
                    ),
                  ],
                ),
                _buildTrendIndicator(),
              ],
            ),

            const SizedBox(height: 16),

            // Chart Area
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  _buildYAxisLabels(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChartArea(stats),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Legend
            _buildLegend(),

            const SizedBox(height: 8),

            // Summary
            _buildPerformanceSummary(stats),
          ],
        ),
      );
    });
  }

  Widget _buildTrendIndicator() {
    final trend = controller.performanceTrend;
    if (trend.length < 2) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _textMuted.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Data terbatas',
          style: TextStyle(fontSize: 10, color: _textMuted),
        ),
      );
    }

    final lastTwo = trend.sublist(trend.length - 2);
    final isUp = lastTwo[1] > lastTwo[0];
    final isSame = lastTwo[1] == lastTwo[0];

    if (isSame) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _warning.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.horizontal_rule, size: 14, color: _warning),
            const SizedBox(width: 4),
            Text(
              'Stabil',
              style: TextStyle(fontSize: 10, color: _warning),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isUp ? _success : _danger).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: isUp ? _success : _danger,
          ),
          const SizedBox(width: 4),
          Text(
            isUp ? 'Meningkat' : 'Menurun',
            style: TextStyle(
              fontSize: 10,
              color: isUp ? _success : _danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYAxisLabels() {
    final labels = ['Sangat\nPercaya', 'Siap\nWawancara', 'Cukup\nBaik', 'Perlu\nLatihan'];
    final colors = [
      const Color(0xFF059669),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];

    return SizedBox(
      width: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          return Text(
            labels[index],
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: colors[index],
              height: 1.0,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildChartArea(List<DailyStat> stats) {
    final trend = controller.performanceTrend;
    final labels = controller.trendLabels;
    final maxPoints = 4;

    return Stack(
      children: [
        // Grid lines
        ...List.generate(4, (index) {
          final yPosition = (index / 4) * 180;
          return Positioned(
            left: 0,
            right: 0,
            top: yPosition,
            child: Container(
              height: 1,
              color: _border.withOpacity(0.5),
            ),
          );
        }),

        // Bar Chart
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: stats.asMap().entries.map((entry) {
            final index = entry.key;
            final stat = entry.value;
            final points = stat.points;
            final height = maxPoints > 0 ? (points / maxPoints) * 160 : 0;
            final hasData = stat.sessionCount > 0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: hasData ? height.clamp(4.0, 160.0).toDouble() : 2.0,
                      decoration: BoxDecoration(
                        gradient: hasData
                            ? LinearGradient(
                                colors: [
                                  controller.getLabelColor(stat.bestLabel),
                                  controller.getLabelColor(stat.bestLabel).withOpacity(0.6),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              )
                            : null,
                        color: hasData ? null : _border.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels.isNotEmpty && index < labels.length
                          ? labels[index]
                          : stat.dayName,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: hasData ? _primaryDark : _textMuted,
                      ),
                    ),
                    if (hasData)
                      Text(
                        '${stat.sessionCount}',
                        style: TextStyle(
                          fontSize: 8,
                          color: _textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // Line Chart
        if (trend.length >= 2 && trend.any((t) => t > 0))
          Positioned.fill(
            child: CustomPaint(
              painter: LineChartPainter(
                data: trend,
                maxValue: 4,
                color: _primaryGold,
              ),
            ),
          ),

        // Dot markers
        if (trend.length >= 2 && trend.any((t) => t > 0))
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend.asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value;
                final yPosition = maxPoints > 0 ? 160 - (value / maxPoints) * 160 : 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (value > 0)
                          Container(
                            margin: EdgeInsets.only(bottom: yPosition.toDouble()),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: controller.trendColors.isNotEmpty &&
                                      index < controller.trendColors.length
                                  ? controller.trendColors[index]
                                  : _primaryGold,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Sangat Percaya Diri', const Color(0xFF059669)),
        const SizedBox(width: 12),
        _legendItem('Siap Wawancara', const Color(0xFF10B981)),
        const SizedBox(width: 12),
        _legendItem('Cukup Baik', const Color(0xFFF59E0B)),
        const SizedBox(width: 12),
        _legendItem('Perlu Latihan', const Color(0xFFEF4444)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: _textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceSummary(List<DailyStat> stats) {
    final totalSessions = stats.fold(0, (sum, s) => sum + s.sessionCount);
    final daysWithData = stats.where((s) => s.sessionCount > 0).length;

    double avgPoints = 0;
    int count = 0;
    for (var stat in stats) {
      if (stat.sessionCount > 0) {
        avgPoints += stat.points;
        count++;
      }
    }
    if (count > 0) avgPoints = avgPoints / count;

    String performanceText;
    Color performanceColor;
    if (avgPoints >= 3.5) {
      performanceText = '🌟 Performa Sangat Baik!';
      performanceColor = const Color(0xFF059669);
    } else if (avgPoints >= 2.5) {
      performanceText = '👍 Performa Baik, Pertahankan!';
      performanceColor = const Color(0xFF10B981);
    } else if (avgPoints >= 1.5) {
      performanceText = '📈 Terus Tingkatkan!';
      performanceColor = const Color(0xFFF59E0B);
    } else {
      performanceText = '💪 Perlu Latihan Lebih Banyak';
      performanceColor = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: performanceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: performanceColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryStat('Total Sesi', '$totalSessions', _primaryDark),
          Container(width: 1, height: 30, color: _border),
          _summaryStat('Hari Aktif', '$daysWithData/7', _primaryDark),
          Container(width: 1, height: 30, color: _border),
          _summaryStat('Rata-rata', '${avgPoints.toStringAsFixed(1)}', performanceColor),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: _textMuted,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ===== FILTER LEVEL =====
  // ============================================================

  Widget _buildLevelFilter() {
    return Obx(() {
      final isActive = controller.selectedLevel.value != 'Semua Level';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? _primaryDark.withOpacity(0.3) : _border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 18,
              color: isActive ? _primaryDark : _textMuted,
            ),
            const SizedBox(width: 10),
            Text(
              'Level:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? _primaryDark : _textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: controller.selectedLevel.value,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isActive ? _primaryDark : _textMuted,
                    size: 20,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? _primaryDark : _textDark,
                  ),
                  onChanged: (v) => controller.setLevel(v!),
                  items: controller.levelOptions
                      .map<DropdownMenuItem<String>>((String v) {
                    return DropdownMenuItem<String>(
                      value: v,
                      child: Text(v),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (isActive)
              GestureDetector(
                onTap: () => controller.setLevel('Semua Level'),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _danger.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, size: 16, color: _danger),
                ),
              ),
          ],
        ),
      );
    });
  }

  // ============================================================
  // ===== FILTER PEKERJAAN =====
  // ============================================================

  Widget _buildJobFilter() {
    return Obx(() {
      final isActive = controller.selectedJob.value != 'Semua Pekerjaan';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? _primaryDark.withOpacity(0.3) : _border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.work_outline_rounded,
              size: 18,
              color: isActive ? _primaryDark : _textMuted,
            ),
            const SizedBox(width: 10),
            Text(
              'Pekerjaan:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? _primaryDark : _textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: controller.selectedJob.value,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isActive ? _primaryDark : _textMuted,
                    size: 20,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? _primaryDark : _textDark,
                  ),
                  onChanged: (v) => controller.setJob(v!),
                  items: controller.jobOptions
                      .map<DropdownMenuItem<String>>((String v) {
                    return DropdownMenuItem<String>(
                      value: v,
                      child: Text(
                        v,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (isActive)
              GestureDetector(
                onTap: () => controller.setJob('Semua Pekerjaan'),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _danger.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, size: 16, color: _danger),
                ),
              ),
          ],
        ),
      );
    });
  }

  // ============================================================
  // ===== SESSION HISTORY =====
  // ============================================================

  Widget _buildSessionHistory() {
    // Baca nilai filter agar Obx mendeteksi perubahan dan rebuild otomatis
    // ignore: unused_local_variable
    final _watchJob = controller.selectedJob.value;
    // ignore: unused_local_variable
    final _watchLevel = controller.selectedLevel.value;
    // ignore: unused_local_variable
    final _watchStatus = controller.selectedStatus.value;
    // ignore: unused_local_variable
    final _watchSessions = controller.sessions.length;

    final filteredSessions = controller.getFilteredSessions();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Latihan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              '${filteredSessions.length} sesi ditampilkan',
              style: const TextStyle(color: _textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Dropdown Status
        Builder(builder: (context) {
          final isActive = controller.selectedStatus.value != 'Semua Status';
          final allSessions = controller.getSessionsForStatusFilter();
          int totalStatusCount = allSessions.length;

          Map<String, int> statusCount = {};
          for (var status in controller.statusOptions) {
            if (status == 'Semua Status') continue;
            final count = allSessions
                .where((s) => s.overallLabel == status)
                .length;
            statusCount[status] = count;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? _primaryDark.withOpacity(0.3) : _border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  size: 16,
                  color: isActive ? _primaryDark : _textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? _primaryDark : _textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: controller.selectedStatus.value,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isActive ? _primaryDark : _textMuted,
                        size: 18,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? _primaryDark : _textDark,
                      ),
                      onChanged: (v) => controller.setStatus(v!),
                      items: controller.statusOptions
                          .map<DropdownMenuItem<String>>((String v) {
                        final count = v == 'Semua Status'
                            ? totalStatusCount
                            : (statusCount[v] ?? 0);
                        return DropdownMenuItem<String>(
                          value: v,
                          child: Row(
                            children: [
                              if (v != 'Semua Status')
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: controller.getLabelColor(v),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (v != 'Semua Status') const SizedBox(width: 8),
                              Text('$v ($count)'),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (isActive)
                  GestureDetector(
                    onTap: () => controller.setStatus('Semua Status'),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: _danger.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, size: 14, color: _danger),
                    ),
                  ),
              ],
            ),
          );
        }),

        const SizedBox(height: 10),

        if (filteredSessions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.filter_list_off, size: 48, color: _textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada sesi dengan filter ini',
                    style: TextStyle(color: _textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => controller.resetAllFilters(),
                    child: const Text('Reset Filter'),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredSessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final session = filteredSessions[index];
              return _buildHistoryCard(session);
            },
          ),
      ],
    );
  }

  Widget _buildHistoryCard(PracticeSession session) {
    int totalWords = _countTotalWords(session.recognizedText);
    final wpmColor = controller.getWpmColor(session.wpm);
    final wpmRating = controller.getWpmRating(session.wpm);
    final fillerColor = controller.getFillerColor(session.fillerCount);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: controller
                          .getLabelColor(session.overallLabel)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session.overallLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: controller.getLabelColor(session.overallLabel),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryDark.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.getLevelDisplayName(session.difficulty),
                      style: const TextStyle(fontSize: 10, color: _textMuted),
                    ),
                  ),
                ],
              ),
              Text(
                _formatDate(session.createdAt),
                style: const TextStyle(fontSize: 10, color: _textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.speed_rounded, color: wpmColor, size: 16),
                      const SizedBox(height: 2),
                      const Text(
                        'WPM',
                        style: TextStyle(fontSize: 9, color: _textMuted),
                      ),
                      Text(
                        '${session.wpm}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: wpmColor,
                        ),
                      ),
                      Text(
                        wpmRating,
                        style: TextStyle(fontSize: 8, color: wpmColor),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 45, color: _border),
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        Icons.text_fields_rounded,
                        color: fillerColor,
                        size: 16,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Pengisi',
                        style: TextStyle(fontSize: 9, color: _textMuted),
                      ),
                      Text(
                        '${session.fillerCount}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: fillerColor,
                        ),
                      ),
                      Text(
                        'kali',
                        style: TextStyle(fontSize: 8, color: fillerColor),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 45, color: _border),
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        Icons.format_list_numbered_rounded,
                        color: _primaryDark,
                        size: 16,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Kata',
                        style: TextStyle(fontSize: 9, color: _textMuted),
                      ),
                      Text(
                        '$totalWords',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _primaryDark,
                        ),
                      ),
                      const Text(
                        'kata',
                        style: TextStyle(fontSize: 8, color: _textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _smallChip(
                '👀 ${session.eyeContactLabel}',
                controller.getLabelColor(session.eyeContactLabel),
              ),
              _smallChip(
                '😊 ${session.smileLabel}',
                controller.getLabelColor(session.smileLabel),
              ),
              _smallChip(
                '🧍 ${session.postureLabel}',
                controller.getLabelColor(session.postureLabel),
              ),
            ],
          ),
          if (session.confidenceMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: _primaryGold, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      session.confidenceMessage,
                      style: const TextStyle(fontSize: 10, color: _textDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _smallChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  int _countTotalWords(String recognizedText) {
    if (recognizedText.isEmpty) return 0;
    final lines = recognizedText.split('\n');
    int totalWords = 0;
    for (final line in lines) {
      if (line.startsWith('A:')) {
        final answer = line.replaceFirst('A:', '').trim();
        if (answer.isNotEmpty && answer != '(tidak ada jawaban)') {
          totalWords += answer.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        }
      }
    }
    return totalWords;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m lalu';
    if (difference.inHours < 24) return '${difference.inHours}j lalu';
    if (difference.inDays < 7) return '${difference.inDays}h lalu';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ============================================================
// ===== LINE CHART PAINTER =====
// ============================================================

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;
  final Color color;

  LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    final width = size.width / (data.length - 1);
    final height = size.height;

    double? previousX;
    double? previousY;

    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      final x = i * width;
      final y = value > 0 ? height - (value / maxValue) * height : height;

      if (value > 0) {
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        previousX = x;
        previousY = y;
      } else {
        if (previousX != null && previousY != null) {
          final dashPaint = Paint()
            ..color = color.withOpacity(0.3)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

          final dashPath = Path()
            ..moveTo(previousX!, previousY!)
            ..lineTo(x, y);
          canvas.drawPath(dashPath, dashPaint);
        }
        previousX = null;
        previousY = null;
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}