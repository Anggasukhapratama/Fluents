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
          style: TextStyle(fontWeight: FontWeight.bold),
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
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsSummary(),
                const SizedBox(height: 20),
                _buildDailyChart(),
                const SizedBox(height: 20),
                _buildFilterChips(),
                const SizedBox(height: 16),
                _buildSessionHistory(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insights_outlined, size: 80, color: _textMuted),
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
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/narasi-practice'),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Mulai Latihan Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGold,
              foregroundColor: _primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryDark, const Color(0xFF1E3A5F)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: _primaryGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total ${controller.totalSessions.value} Latihan',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${controller.totalPoints.value} Poin Terkumpul',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              _statItem(
                'Label Terbaik',
                controller.bestLabel.value,
                controller.getLabelColor(controller.bestLabel.value),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              _statItem(
                'Terakhir',
                controller.latestLabel.value,
                controller.getLabelColor(controller.latestLabel.value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: _primaryGold, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.improvementNote.value,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
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
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChart() {
    final stats = controller.dailyStats;

    // Cari nilai maksimum untuk scaling chart
    int maxPoints = 3; // Default max 3 poin
    for (var stat in stats) {
      if (stat.points > maxPoints) maxPoints = stat.points;
    }
    if (maxPoints == 0) maxPoints = 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 20),
              SizedBox(width: 8),
              Text(
                'Aktivitas 7 Hari Terakhir',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(stats.length, (index) {
                final stat = stats[index];
                final heightPercent = stat.points / maxPoints;
                final barHeight = heightPercent * 120; // Max 120px

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (stat.sessionCount > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: controller
                                .getLabelColor(stat.bestLabel)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            stat.bestLabel == 'Siap Wawancara'
                                ? '★'
                                : (stat.bestLabel == 'Cukup Siap' ? '●' : '○'),
                            style: TextStyle(
                              fontSize: 10,
                              color: controller.getLabelColor(stat.bestLabel),
                            ),
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: stat.sessionCount > 0 ? barHeight : 4,
                        width: 28,
                        decoration: BoxDecoration(
                          color: stat.sessionCount > 0
                              ? controller.getLabelColor(stat.bestLabel)
                              : _border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stat.dayName,
                        style: const TextStyle(fontSize: 11, color: _textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stat.shortDate,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chartLegend('★ Siap Wawancara', _success),
              const SizedBox(width: 16),
              _chartLegend('● Cukup Siap', _warning),
              const SizedBox(width: 16),
              _chartLegend('○ Butuh Latihan', _danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: _textMuted)),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: controller.levelFilters.map((filter) {
          final isSelected = controller.selectedLevelFilter.value == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter == 'semua'
                    ? 'Semua Level'
                    : (filter == 'medium'
                          ? 'Menengah'
                          : filter == 'hard'
                          ? 'Mahir'
                          : 'Profesional'),
              ),
              selected: isSelected,
              onSelected: (_) => controller.filterByLevel(filter),
              backgroundColor: _surface,
              selectedColor: _primaryGold.withOpacity(0.2),
              checkmarkColor: _primaryGold,
              labelStyle: TextStyle(
                color: isSelected ? _primaryGold : _textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSessionHistory() {
    final filteredSessions = controller.getFilteredSessions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Latihan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${filteredSessions.length} sesi',
              style: const TextStyle(color: _textMuted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredSessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final session = filteredSessions[index];
            return _buildHistoryCard(session);
          },
        ),
      ],
    );
  }

  Widget _buildHistoryCard(PracticeSession session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: controller
                          .getLabelColor(session.overallLabel)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      session.overallLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: controller.getLabelColor(session.overallLabel),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryDark.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      controller.getLevelDisplayName(session.difficulty),
                      style: const TextStyle(fontSize: 11, color: _textMuted),
                    ),
                  ),
                ],
              ),
              Text(
                _formatDate(session.createdAt),
                style: const TextStyle(fontSize: 11, color: _textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniMetric('WPM', session.wpm.toString()),
              _miniMetric('Kata', session.fillerCount.toString()),
              _miniMetric(
                'Poin',
                _labelToPointsShort(session.overallLabel).toString(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _smallChip(
                session.eyeContactLabel,
                controller.getLabelColor(session.eyeContactLabel),
              ),
              _smallChip(
                session.smileLabel,
                controller.getLabelColor(session.smileLabel),
              ),
              _smallChip(
                session.postureLabel,
                controller.getLabelColor(session.postureLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: _textMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _smallChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  int _labelToPointsShort(String label) {
    switch (label) {
      case 'Siap Wawancara':
        return 3;
      case 'Cukup Siap':
        return 2;
      case 'Butuh Banyak Latihan':
        return 1;
      default:
        return 0;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
