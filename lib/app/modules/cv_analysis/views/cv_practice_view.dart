import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cv_analysis_controller.dart';

class CvPracticeView extends GetView<CvAnalysisController> {
  const CvPracticeView({super.key});

  // Fluent-ish warm gradient (red -> orange)
  static const _bg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF1F2), // very light red
      Color(0xFFFFF7ED), // very light orange
      Color(0xFFFFFBEB), // warm light
    ],
  );

  static const _accentRed = Color(0xFFEF4444);
  static const _accentOrange = Color(0xFFF97316);
  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final answerCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      // penting: biar body resize, tapi kita tetap aman karena tombol di bottomNavigationBar
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(gradient: _bg),
        child: SafeArea(
          child: Obx(() {
            // state guard
            if (controller.turns.isEmpty) {
              return _loadingPage();
            }

            final sum = controller.practiceSummary.value;
            if (sum != null && sum.overall.isNotEmpty) {
              return _summaryPage(sum);
            }

            final idx = controller.activeQIndex.value;
            final turn = controller.turns[idx];

            return Column(
              children: [
                _topBar(idx: idx, total: controller.turns.length),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // SingleChildScrollView biar aman saat keyboard muncul + konten bisa scroll
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _progressCard(idx + 1, controller.turns.length),
                                const SizedBox(height: 12),

                                _questionCard(
                                  number: idx + 1,
                                  question: turn.question,
                                ),
                                const SizedBox(height: 12),

                                // Answer card (flexible height but still nice)
                                _answerCard(controller: answerCtrl),

                                const SizedBox(height: 12),
                                _hintRow(),
                                const SizedBox(height: 10),

                                // spacer biar tombol nggak nempel ke konten
                                const Spacer(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ),
      ),

      // tombol selalu aman (ikut keyboard)
      bottomNavigationBar: Obx(() {
        if (controller.turns.isEmpty) return const SizedBox.shrink();

        final idx = controller.activeQIndex.value;
        final isLast = idx == controller.turns.length - 1;
        final loading = controller.isSubmittingAnswer.value;

        final safeBottom = MediaQuery.of(context).padding.bottom; // gesture bar
        final kbBottom = MediaQuery.of(context).viewInsets.bottom; // keyboard
        final bottom = kbBottom > 0 ? kbBottom : safeBottom;

        return SafeArea(
          top: false,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottom),
            child: Row(
              children: [
                _softButton(
                  onTap: loading
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          if (idx > 0) controller.activeQIndex.value = idx - 1;
                        },
                  icon: Icons.arrow_back_rounded,
                  label: 'Kembali',
                  enabled: !loading && idx > 0,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _primaryButton(
                    loading: loading,
                    isLast: isLast,
                    onTap: loading
                        ? null
                        : () async {
                            final ans = answerCtrl.text;
                            FocusScope.of(context).unfocus();
                            await controller.submitAnswerAndNext(ans);
                            // clear kalau sudah berpindah / selesai
                            if (ans.trim().isNotEmpty &&
                                (controller.activeQIndex.value != idx ||
                                    controller.practiceSummary.value != null)) {
                              answerCtrl.clear();
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ===== UI widgets =====

  Widget _topBar({required int idx, required int total}) {
    final step = idx + 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.close_rounded, color: _text),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Latihan Interview',
                  style: TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pertanyaan $step dari $total',
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _pill(text: 'Fluent', icon: Icons.auto_awesome_rounded),
        ],
      ),
    );
  }

  Widget _progressCard(int current, int total) {
    final v = total == 0 ? 0.0 : (current / total);
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, color: _accentRed),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Progress',
                  style: TextStyle(color: _text, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '$current/$total',
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 10,
              backgroundColor: _accentOrange.withOpacity(0.16),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.lerp(_accentRed, _accentOrange, v) ?? _accentRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionCard({required int number, required String question}) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _badge('$number', from: _accentRed, to: _accentOrange),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pertanyaan',
                  style: TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(Icons.record_voice_over_rounded, color: _accentOrange),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question,
            style: const TextStyle(
              color: _text,
              fontWeight: FontWeight.w900,
              height: 1.35,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Jawab singkat, jelas, dan kasih contoh impact.',
            style: TextStyle(
              color: _muted.withOpacity(0.95),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _answerCard({required TextEditingController controller}) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jawaban kamu',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: TextField(
              controller: controller,
              minLines: 6,
              maxLines: 10,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(14, 12, 14, 12),
                hintText:
                    'Tulis jawaban kamu di sini…\n'
                    'Tips: gunakan format STAR (Situation, Task, Action, Result).',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.lightbulb_rounded, color: _accentRed, size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Kalau ada angka/hasil (mis: “naik 20%”), sebutkan ya.',
                  style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hintRow() {
    return Row(
      children: [
        Expanded(
          child: _miniChip(
            icon: Icons.schedule_rounded,
            text: 'Target 1–2 menit',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniChip(
            icon: Icons.tips_and_updates_rounded,
            text: 'Fokus impact',
          ),
        ),
      ],
    );
  }

  Widget _loadingPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: _glassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(height: 6),
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text(
                'Menyiapkan latihan…',
                style: TextStyle(color: _text, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 4),
              Text(
                'Sebentar ya 🙂',
                style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryPage(dynamic sum) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: ListView(
        children: [
          _topBar(
            idx: controller.turns.length - 1,
            total: controller.turns.length,
          ),
          const SizedBox(height: 8),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Feedback',
                  style: TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  sum.overall ?? '',
                  style: const TextStyle(color: _text, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kekuatan',
                  style: TextStyle(color: _text, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                ...(sum.strengths as List? ?? const []).map<Widget>(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• $e',
                      style: const TextStyle(color: _text, height: 1.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perlu ditingkatkan',
                  style: TextStyle(color: _text, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                ...(sum.improvements as List? ?? const []).map<Widget>(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• $e',
                      style: const TextStyle(color: _text, height: 1.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _primaryButton(
            loading: false,
            isLast: true,
            labelOverride: 'Selesai',
            onTap: () => Get.back(),
          ),
        ],
      ),
    );
  }

  // ===== Small UI helpers =====

  Widget _glassCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.72),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: child,
  );

  Widget _pill({required String text, required IconData icon}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.78),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: _border),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: _accentRed),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: _text, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );

  Widget _badge(String text, {required Color from, required Color to}) =>
      Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [from, to]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      );

  Widget _miniChip({required IconData icon, required String text}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.72),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: Row(
      children: [
        Icon(icon, color: _accentOrange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _text, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );

  Widget _softButton({
    required VoidCallback? onTap,
    required IconData icon,
    required String label,
    required bool enabled,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(enabled ? 0.78 : 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(icon, color: enabled ? _text : _muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: enabled ? _text : _muted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton({
    required bool loading,
    required bool isLast,
    required VoidCallback? onTap,
    String? labelOverride,
  }) {
    final label =
        labelOverride ?? (isLast ? 'Selesai & Feedback' : 'Jawab & Lanjut');
    final icon = isLast
        ? Icons.check_circle_rounded
        : Icons.arrow_forward_rounded;

    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _accentRed,
              Color.lerp(_accentRed, _accentOrange, 0.55) ?? _accentOrange,
              _accentOrange,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _accentOrange.withOpacity(0.28),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
