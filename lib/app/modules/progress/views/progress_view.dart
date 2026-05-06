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
              _buildFilterChips(),
              const SizedBox(height: 12),
              _buildSessionHistory(),
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

  // ===== CHART - VERSI SIMPLE & KECIL =====
  Widget _buildDailyChart() {
    final stats = controller.dailyStats;

    // Cari max points untuk scaling
    int maxPoints = 3;
    for (var stat in stats) {
      if (stat.points > maxPoints) maxPoints = stat.points;
    }
    if (maxPoints == 0) maxPoints = 3;

    return Container(
      padding: const EdgeInsets.all(12),
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
          // Title
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 16),
              SizedBox(width: 6),
              Text(
                '7 Hari Terakhir',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chart bars
          SizedBox(
            height: 100, // LEBIH KECIL: 140 -> 100
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: stats.map((stat) {
                final heightPercent = maxPoints > 0
                    ? stat.points / maxPoints
                    : 0.0;
                final barHeight = heightPercent * 60; // LEBIH KECIL: 90 -> 60

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Bar
                        Container(
                          height: stat.sessionCount > 0 ? barHeight : 2.0,
                          decoration: BoxDecoration(
                            color: stat.sessionCount > 0
                                ? controller.getLabelColor(stat.bestLabel)
                                : _border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Day label
                        Text(
                          stat.dayName,
                          style: const TextStyle(
                            fontSize: 9,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dotLegend('Baik', _success),
              const SizedBox(width: 12),
              _dotLegend('Cukup', _warning),
              const SizedBox(width: 12),
              _dotLegend('Kurang', _danger),
            ],
          ),
        ],
      ),
    );
  }

  // ===== LEGEND DOT =====
  Widget _dotLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 9, color: _textMuted)),
      ],
    );
  }

  Widget _chartLegend(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 9, color: _textMuted)),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: controller.levelFilters.map((filter) {
          final isSelected = controller.selectedLevelFilter.value == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter == 'semua'
                    ? 'Semua'
                    : (filter == 'medium'
                          ? 'Menengah'
                          : filter == 'hard'
                          ? 'Mahir'
                          : 'Pro'),
                style: TextStyle(fontSize: 11),
              ),
              selected: isSelected,
              onSelected: (_) => controller.filterByLevel(filter),
              backgroundColor: _surface,
              selectedColor: _primaryGold.withOpacity(0.2),
              checkmarkColor: _primaryGold,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSessionHistory() {
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
              '${filteredSessions.length} sesi',
              style: const TextStyle(color: _textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
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

  // ===== HISTORY CARD =====
  Widget _buildHistoryCard(PracticeSession session) {
    int totalWords = _countTotalWords(session.recognizedText);

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
          // Header
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

          // Metrik
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _mainMetric(
                  icon: Icons.speed_rounded,
                  label: 'WPM',
                  value: '${session.wpm}',
                  subtitle: 'kata/mnt',
                  color: _getWpmColor(session.wpm),
                ),
                Container(width: 1, height: 35, color: _border),
                _mainMetric(
                  icon: Icons.text_fields_rounded,
                  label: 'Pengisi',
                  value: '${session.fillerCount}',
                  subtitle: 'kali',
                  color: _getFillerColor(session.fillerCount),
                ),
                Container(width: 1, height: 35, color: _border),
                _mainMetric(
                  icon: Icons.format_list_numbered_rounded,
                  label: 'Kata',
                  value: '$totalWords',
                  subtitle: 'kata',
                  color: _primaryDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Label deteksi
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

          // Pesan motivasi
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

  // ===== MAIN METRIC =====
  Widget _mainMetric({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: _textMuted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 8, color: _textMuted),
          ),
        ],
      ),
    );
  }

  // ===== WARNA =====
  Color _getWpmColor(int wpm) {
    if (wpm >= 120 && wpm <= 160) return _success;
    if ((wpm >= 80 && wpm < 120) || (wpm > 160 && wpm <= 200)) return _warning;
    return _danger;
  }

  Color _getFillerColor(int fillerCount) {
    if (fillerCount <= 2) return _success;
    if (fillerCount <= 5) return _warning;
    return _danger;
  }

  // ===== HITUNG TOTAL KATA =====
  int _countTotalWords(String recognizedText) {
    if (recognizedText.isEmpty) return 0;
    final cleanText = recognizedText.replaceAll(RegExp(r'[QA]:\s*'), '');
    final words = cleanText
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();
    return words.length;
  }

  // ===== SMALL CHIP =====
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

  // ===== FORMAT TANGGAL =====
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
