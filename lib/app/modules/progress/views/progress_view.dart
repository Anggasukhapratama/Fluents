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
  static const Color _primaryBlue = Color(0xFF3B82F6);

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
              Obx(() => _buildSessionHistory()),
            ],
          ),
        );
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

  // ============================================================
  // STATS SUMMARY - TANPA OVERALL
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

          // ===== 3 PARAMETER TERAKHIR =====
          Obx(() {
            final eyeLabel = controller.lastEyeContact.value;
            final smileLabel = controller.lastSmile.value;
            final postureLabel = controller.lastPosture.value;

            return Row(
              children: [
                _paramChip(
                  icon: '👀',
                  label: eyeLabel.isEmpty ? '-' : eyeLabel,
                  color: controller.getLabelColor(eyeLabel),
                ),
                const SizedBox(width: 6),
                _paramChip(
                  icon: '😊',
                  label: smileLabel.isEmpty ? '-' : smileLabel,
                  color: controller.getLabelColor(smileLabel),
                ),
                const SizedBox(width: 6),
                _paramChip(
                  icon: '🧍',
                  label: postureLabel.isEmpty ? '-' : postureLabel,
                  color: controller.getLabelColor(postureLabel),
                ),
              ],
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

  Widget _paramChip({
    required String icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DAILY CHART - GRAFIK 3 PARAMETER (TANPA BAIK/CUKUP/KURANG)
  // ============================================================
  Widget _buildDailyChart() {
    return Obx(() {
      final eyeTrend = controller.eyeTrend;
      final smileTrend = controller.smileTrend;
      final postureTrend = controller.postureTrend;
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

            // Chart dengan 3 line (Eye, Smile, Posture)
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  _buildYAxisLabels(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMultiLineChart(
                      eyeTrend,
                      smileTrend,
                      postureTrend,
                      labels,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ===== LEGEND 3 PARAMETER =====
            _buildLegend(),

            const SizedBox(height: 8),

            // ===== SUMMARY PAKAI LABEL ASLI (BUKAN BAIK/CUKUP/KURANG) =====
            _buildPerformanceSummaryWithLabels(),
          ],
        ),
      );
    });
  }

  // ============================================================
  // TREND INDICATOR - BERDASARKAN PERUBAHAN LABEL
  // ============================================================
  Widget _buildTrendIndicator() {
    final eyeTrend = controller.eyeTrend;
    final smileTrend = controller.smileTrend;
    final postureTrend = controller.postureTrend;

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
    double prevAvg = 0;
    double currAvg = 0;
    int prevCount = 0;
    int currCount = 0;

    for (int i = 0; i < eyeTrend.length; i++) {
      if (i == lastIndex) {
        currAvg += (eyeTrend[i] + smileTrend[i] + postureTrend[i]) / 3;
        currCount++;
      } else if (i == lastIndex - 1) {
        prevAvg += (eyeTrend[i] + smileTrend[i] + postureTrend[i]) / 3;
        prevCount++;
      }
    }

    if (prevCount > 0) prevAvg = prevAvg / prevCount;
    if (currCount > 0) currAvg = currAvg / currCount;

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
  // Y-AXIS LABELS - "TINGGI", "SEDANG", "RENDAH" (NETRAL)
  // ============================================================
  Widget _buildYAxisLabels() {
    final labels = ['Tinggi', 'Sedang', 'Rendah'];
    final colors = [
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];

    return SizedBox(
      width: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          return Text(
            labels[index],
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: colors[index],
              height: 1.0,
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // MULTI LINE CHART - 3 PARAMETER
  // ============================================================
  Widget _buildMultiLineChart(
    List<double> eyeTrend,
    List<double> smileTrend,
    List<double> postureTrend,
    List<String> labels,
  ) {
    final maxPoints = 3.0;

    return CustomPaint(
      painter: MultiLineChartPainter(
        eyeData: eyeTrend,
        smileData: smileTrend,
        postureData: postureTrend,
        labels: labels,
        maxValue: maxPoints,
        eyeColor: const Color(0xFF3B82F6),
        smileColor: const Color(0xFFF59E0B),
        postureColor: const Color(0xFF10B981),
      ),
      size: Size(double.infinity, 200),
    );
  }

  // ============================================================
  // LEGEND - 3 PARAMETER
  // ============================================================
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('👀 Mata', const Color(0xFF3B82F6)),
        const SizedBox(width: 16),
        _legendItem('😊 Senyum', const Color(0xFFF59E0B)),
        const SizedBox(width: 16),
        _legendItem('🧍 Postur', const Color(0xFF10B981)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: _textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PERFORMANCE SUMMARY - PAKAI LABEL ASLI PER PARAMETER
  // ============================================================
  Widget _buildPerformanceSummaryWithLabels() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primaryDark.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Obx(() {
        final eyeTrend = controller.eyeTrend;
        final smileTrend = controller.smileTrend;
        final postureTrend = controller.postureTrend;

        final avgEye = eyeTrend.isNotEmpty
            ? eyeTrend.reduce((a, b) => a + b) / eyeTrend.length
            : 0.0;
        final avgSmile = smileTrend.isNotEmpty
            ? smileTrend.reduce((a, b) => a + b) / smileTrend.length
            : 0.0;
        final avgPosture = postureTrend.isNotEmpty
            ? postureTrend.reduce((a, b) => a + b) / postureTrend.length
            : 0.0;

        // Tentukan label asli berdasarkan rata-rata
        final eyeLabel = _getEyeLabelFromAvg(avgEye);
        final smileLabel = _getSmileLabelFromAvg(avgSmile);
        final postureLabel = _getPostureLabelFromAvg(avgPosture);

        final totalSessions = controller.totalSessions.value;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _labelStat('👀', eyeLabel, _getAvgColor(avgEye.toDouble())),
                Container(width: 1, height: 30, color: _border),
                _labelStat('😊', smileLabel, _getAvgColor(avgSmile.toDouble())),
                Container(width: 1, height: 30, color: _border),
                _labelStat(
                  '🧍',
                  postureLabel,
                  _getAvgColor(avgPosture.toDouble()),
                ),
                Container(width: 1, height: 30, color: _border),
                _labelStat('Total', '$totalSessions sesi', _primaryDark),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Rata-rata label dari 7 hari terakhir',
              style: TextStyle(fontSize: 9, color: _textMuted),
            ),
          ],
        );
      }),
    );
  }

  // ============================================================
  // HELPER: Konversi Rata-rata ke Label Asli per Parameter
  // ============================================================
  String _getEyeLabelFromAvg(double avg) {
    if (avg >= 2.5) return 'Fokus terhadap Pewawancara';
    return 'Tidak Fokus';
  }

  String _getSmileLabelFromAvg(double avg) {
    if (avg >= 2.5) return 'Ramah dan Profesional';
    if (avg >= 1.5) return 'Cukup Ramah';
    return 'Terlalu Tegang';
  }

  String _getPostureLabelFromAvg(double avg) {
    if (avg >= 2.5) return 'Sikap Profesional';
    return 'Kurang Tenang';
  }

  Color _getAvgColor(double avg) {
    if (avg >= 2.5) return const Color(0xFF10B981);
    if (avg >= 1.5) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _labelStat(String icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTERS
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
    });
  }

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
    });
  }

  // ============================================================
  // SESSION HISTORY - TANPA OVERALL LABEL
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
  // HISTORY CARD - TANPA OVERALL LABEL
  // ============================================================
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
          // Row dengan 3 parameter chips
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
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

// ============================================================
// MULTI LINE CHART PAINTER
// ============================================================
class MultiLineChartPainter extends CustomPainter {
  final List<double> eyeData;
  final List<double> smileData;
  final List<double> postureData;
  final List<String> labels;
  final double maxValue;
  final Color eyeColor;
  final Color smileColor;
  final Color postureColor;

  MultiLineChartPainter({
    required this.eyeData,
    required this.smileData,
    required this.postureData,
    required this.labels,
    required this.maxValue,
    required this.eyeColor,
    required this.smileColor,
    required this.postureColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (eyeData.length < 2) return;

    final width = size.width / (eyeData.length - 1);
    final height = size.height;

    _drawLine(canvas, eyeData, eyeColor, width, height);
    _drawLine(canvas, smileData, smileColor, width, height);
    _drawLine(canvas, postureData, postureColor, width, height);

    _drawDots(canvas, eyeData, eyeColor, width, height);
    _drawDots(canvas, smileData, smileColor, width, height);
    _drawDots(canvas, postureData, postureColor, width, height);
  }

  void _drawLine(
    Canvas canvas,
    List<double> data,
    Color color,
    double width,
    double height,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    bool started = false;

    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      final x = i * width;
      final y = value > 0 ? height - (value / maxValue) * height : height;

      if (value > 0) {
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      } else {
        started = false;
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawDots(
    Canvas canvas,
    List<double> data,
    Color color,
    double width,
    double height,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      if (value > 0) {
        final x = i * width;
        final y = height - (value / maxValue) * height;
        canvas.drawCircle(Offset(x, y), 4, paint);

        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(Offset(x, y), 4, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(MultiLineChartPainter oldDelegate) {
    return oldDelegate.eyeData != eyeData ||
        oldDelegate.smileData != smileData ||
        oldDelegate.postureData != postureData;
  }
}
