// lib/app/modules/progress/views/progress_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  static const Color _primaryBlue = Color(0xFF3B82F6);

  String _eyeContactDisplayLabel(String label) {
    switch (label) {
      case 'Terlalu Sedikit':
        return 'Kontak Mata Terlalu Sedikit';
      case 'Terlalu Lama':
        return 'Anda Terlalu Fokus';
      case 'Ideal':
        return 'Kontak Mata Ideal';
      default:
        return label.isEmpty ? 'Kontak Mata Tidak Terdeteksi' : label;
    }
  }

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
        try {
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
            color: _primaryGold,
            backgroundColor: _surface,
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
                _buildSessionHistory(),
              ],
            ),
          );
        } catch (e, st) {
          if (kDebugMode) {
            print('[ProgressView] build error: $e\n$st');
          }
          return _buildErrorPlaceholder(e.toString());
        }
      }),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
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

  Widget _buildErrorPlaceholder(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Terjadi kesalahan menampilkan Progress. Silakan refresh.\n${msg}',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          IconButton(
            onPressed: () => controller.refreshData(),
            icon: Icon(Icons.refresh_rounded, color: _primaryGold),
          )
        ],
      ),
    );
  }

  // ============================================================
  // STATS SUMMARY - HANYA KONTAK MATA (dengan perbaikan overflow)
  // ============================================================
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

          // ===== KONTAK MATA TERAKHIR - perbaiki layout dan posisioning =====
          Builder(builder: (_) {
            final eyeLabel = controller.lastEyeContact.value;
            final color = controller.getLabelColor(eyeLabel);
            final mapped = _eyeContactDisplayLabel(eyeLabel);
            final pct = controller.lastEyeContactPercentage.value;
            final pctStr = pct > 0 ? '${pct.toStringAsFixed(1)}% fokus' : '';
            final smile = controller.lastSmileLabel.value;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Kontak Mata
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('👀', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              eyeLabel.isEmpty ? '-' : mapped,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (pct > 0)
                              Text(
                                pctStr,
                                style: TextStyle(fontSize: 11, color: color.withOpacity(0.9)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Senyum
                  if (smile.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Divider(color: color.withOpacity(0.2), height: 1),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('😊', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                smile,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text('Ekspresi Senyum', style: TextStyle(fontSize: 11, color: Colors.orangeAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),

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

  // ============================================================
  // DAILY CHART - BAR CHART MODERN
  // ============================================================
  Widget _buildDailyChart() {
      final eyeTrend = controller.eyeTrend;
      final labels = controller.trendLabels;

      if (eyeTrend.isEmpty || eyeTrend.every((e) => e == 0)) {
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

      // Hitung rata-rata dan label dominan
      final avgEye = eyeTrend.reduce((a, b) => a + b) / eyeTrend.length;
      final dominantLabel = _getEyeLabelFromAvg(avgEye);
      final dominantColor = _getAvgColor(avgEye);

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
                      'Tren Kontak Mata 7 Hari',
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

            // ===== BAR CHART =====
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  // Sumbu Y
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        '100%',
                        style: TextStyle(
                          fontSize: 10,
                          color: _success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '50%',
                        style: TextStyle(
                          fontSize: 10,
                          color: _warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '0%',
                        style: TextStyle(
                          fontSize: 10,
                          color: _danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Bar chart
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(eyeTrend.length, (index) {
                        final value = eyeTrend[index];
                        final maxVal = 100.0;
                        final height = (value / maxVal) * 150;
                        final barColor = _getBarColor(value);
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: height.clamp(4.0, 150.0),
                              width: 20,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [barColor, barColor.withOpacity(0.6)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              labels[index],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== CARD RINGKASAN =====
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dominantColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dominantColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _statLabel(
                      'Rata-rata',
                      _getRatingLabel(avgEye),
                      dominantColor,
                    ),
                  ),
                  Container(width: 1, height: 30, color: _border),
                  Expanded(
                    child: _statLabel('Mata', _eyeContactDisplayLabel(dominantLabel), dominantColor),
                  ),
                  Container(width: 1, height: 30, color: _border),
                  Expanded(
                    child: _statLabel(
                      'Senyum',
                      controller.lastSmileLabel.value.isNotEmpty ? controller.lastSmileLabel.value : '-',
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  // ============================================================
  // HELPER UNTUK CHART
  // ============================================================
  Color _getBarColor(double value) {
    if (value >= 75) return _success;
    if (value >= 50) return _warning;
    return _danger;
  }

  String _getRatingLabel(double avg) {
    if (avg >= 75) return 'Sangat Baik';
    if (avg >= 50) return 'Cukup';
    return 'Kurang';
  }

  String _getEyeLabelFromAvg(double avg) {
    if (avg >= 75) return 'Ideal';
    if (avg >= 50) return 'Kurang Fokus';
    return 'Tidak Fokus';
  }

  Color _getAvgColor(double avg) {
    if (avg >= 75) return _success;
    if (avg >= 50) return _warning;
    return _danger;
  }

  Widget _statLabel(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _textMuted),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTrendIndicator() {
    final eyeTrend = controller.eyeTrend;
    if (eyeTrend.length < 2) {
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

    final lastIndex = eyeTrend.length - 1;
    final prevAvg = eyeTrend[lastIndex - 1];
    final currAvg = eyeTrend[lastIndex];

    final isUp = currAvg > prevAvg;
    final isSame = currAvg == prevAvg;

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
            Text('Stabil', style: TextStyle(fontSize: 10, color: _warning)),
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
            style: TextStyle(fontSize: 10, color: isUp ? _success : _danger),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERS (tidak berubah)
  // ============================================================
  Widget _buildLevelFilter() {
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
                  items: controller.levelOptions.map<DropdownMenuItem<String>>((
                    String v,
                  ) {
                    return DropdownMenuItem<String>(value: v, child: Text(v));
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
  }

  Widget _buildJobFilter() {
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
                  items: controller.jobOptions.map<DropdownMenuItem<String>>((
                    String v,
                  ) {
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
  }

  // ============================================================
  // SESSION HISTORY
  // ============================================================
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
              '${filteredSessions.length} sesi ditampilkan',
              style: const TextStyle(color: _textMuted, fontSize: 11),
            ),
          ],
        ),
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

  // ============================================================
  // HISTORY CARD - HANYA KONTAK MATA
  // ============================================================
  Widget _buildHistoryCard(PracticeSession session) {
    int totalWords = _countTotalWords(session.recognizedText);
    final wpmColor = controller.getWpmColor(session.wpm);
    final wpmRating = controller.getWpmRating(session.wpm);
    final fillerColor = controller.getFillerColor(session.fillerCount);
    final eyeColor = controller.getLabelColor(session.eyeContactLabel);

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
          // Row dengan kontak mata
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _smallChip('👀 ${_eyeContactDisplayLabel(session.eyeContactLabel)}', eyeColor),
                    if (session.detectionResult?.smileResult?.dominantLabel != null && session.detectionResult!.smileResult!.dominantLabel.isNotEmpty)
                      _smallChip('😊 ${session.detectionResult!.smileResult!.dominantLabel}', Colors.orange),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          const SizedBox(height: 10),

          // Metrics
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

          // Job target & tanggal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (session.jobTarget.isNotEmpty)
                Expanded(
                  child: Text(
                    '🎯 ${session.jobTarget}',
                    style: const TextStyle(fontSize: 11, color: _textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Text(
                _formatDate(session.createdAt),
                style: const TextStyle(fontSize: 10, color: _textMuted),
              ),
            ],
          ),
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
          totalWords += answer
              .split(RegExp(r'\s+'))
              .where((w) => w.isNotEmpty)
              .length;
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
