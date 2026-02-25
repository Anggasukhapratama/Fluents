import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../controllers/hrd_sim_controller.dart';

// ===== Theme Colors =====
const Color _bgColor = Color(0xFFF8FAFC);
const Color _cardColor = Colors.white;
const Color _textColor = Color(0xFF0F172A);
const Color _mutedColor = Color(0xFF64748B);
const Color _borderColor = Color(0xFFE2E8F0);
const Color _tealColor = Color(0xFF0D9488);
const Color _navyColor = Color(0xFF0B1220);
const Color _amberColor = Color(0xFFF59E0B);
const Color _redColor = Color(0xFFEF4444);
const Color _greenColor = Color(0xFF10B981);
const Color _blueColor = Color(0xFF3B82F6);
const Color _orangeColor = Color(0xFFFB923C);

class HrdSimView extends GetView<HrdSimController> {
  const HrdSimView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _textColor),
        title: const Text(
          'Simulasi Interview HRD',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: [
          Obx(() {
            if (controller.step.value == HrdStep.playing) {
              return IconButton(
                icon: const Icon(Icons.flag_rounded),
                tooltip: 'Akhiri sesi',
                onPressed: controller.stopEarlyToResult,
                color: _redColor,
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          switch (controller.step.value) {
            case HrdStep.intro:
              return _IntroPanel(onStart: controller.start);
            case HrdStep.countdown:
              return _CountdownPanel(count: controller.countdown.value);
            case HrdStep.playing:
              return _PlayingPanel(controller: controller);
            case HrdStep.result:
              return _ResultPanel(controller: controller);
          }
        }),
      ),
    );
  }
}

// ================== INTRO ==================
class _IntroPanel extends StatelessWidget {
  const _IntroPanel({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎯 Mode Interview Simulasi',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Latihan interview dengan 5 pertanyaan acak.\n'
                  'Setiap pertanyaan punya waktu 15 detik.\n'
                  'TEKAN & TAHAN tombol mikrofon untuk merekam jawaban (maks 10 detik).',
                  style: TextStyle(color: _mutedColor, height: 1.5),
                ),
                const SizedBox(height: 16),
                const _InfoRow(
                  icon: LucideIcons.timer,
                  text: 'Total 75 detik (5×15 detik)',
                  color: _amberColor,
                ),
                const SizedBox(height: 10),
                const _InfoRow(
                  icon: LucideIcons.mic,
                  text: 'Rekam dengan tombol (press & hold) maks 10 detik',
                  color: _orangeColor,
                ),
                const SizedBox(height: 10),
                const _InfoRow(
                  icon: LucideIcons.smile,
                  text: 'Emoji HRD berubah sesuai jawaban',
                  color: _greenColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '📝 Cara Menggunakan',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 10),
                _StrategyItem(
                  number: '1',
                  title: 'Tekan & Tahan',
                  description: 'Tekan tombol mikrofon untuk mulai merekam',
                ),
                _StrategyItem(
                  number: '2',
                  title: 'Bicara',
                  description: 'Bicara jawaban Anda (maksimal 10 detik)',
                ),
                _StrategyItem(
                  number: '3',
                  title: 'Lepaskan',
                  description: 'Lepaskan tombol untuk menghentikan rekaman',
                ),
                _StrategyItem(
                  number: '4',
                  title: 'Ulangi',
                  description: 'Tekan lagi jika perlu menambah jawaban',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: const Text(
                'Mulai Simulasi',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tealColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: onStart,
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategyItem extends StatelessWidget {
  const _StrategyItem({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _tealColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _tealColor.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: _tealColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(color: _mutedColor, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================== COUNTDOWN ==================
class _CountdownPanel extends StatelessWidget {
  const _CountdownPanel({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Siap...',
            style: TextStyle(
              color: _mutedColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            count > 0 ? '$count' : 'GO!',
            style: TextStyle(
              fontSize: count > 0 ? 64 : 48,
              fontWeight: FontWeight.w900,
              color: count > 0 ? _tealColor : _greenColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ================== PLAYING ==================
class _PlayingPanel extends StatelessWidget {
  const _PlayingPanel({required this.controller});
  final HrdSimController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: _cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Obx(() {
            final i = controller.currentIndex.value + 1;
            final left = controller.secondsLeft.value;
            final total = HrdSimController.secondsPerQuestion;
            final progress = (total - left) / total;

            return Column(
              children: [
                Row(
                  children: [
                    _ProgressChip(
                      icon: Icons.question_answer_rounded,
                      label: 'Soal $i/${HrdSimController.totalQuestions}',
                      color: _tealColor,
                    ),
                    const Spacer(),
                    _ProgressChip(
                      icon: Icons.timer_rounded,
                      label: '$left detik',
                      color: left > 5 ? _blueColor : _redColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: _borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.7 ? _redColor : _tealColor,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Obx(() {
                  final m = controller.mood.value;
                  return _CardBox(
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: _bgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _borderColor),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            controller.moodEmoji(m),
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.moodLabel(m),
                                style: const TextStyle(
                                  color: _textColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Fokus keyword + contoh nyata.',
                                style: TextStyle(
                                  color: _mutedColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                _CardBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.question_mark_rounded,
                            size: 20,
                            color: _blueColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pertanyaan',
                            style: TextStyle(
                              color: _mutedColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Obx(() {
                            final recording = controller.isRecording.value;
                            return Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: recording ? _redColor : _mutedColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  recording ? 'Merekam' : 'Siap',
                                  style: TextStyle(
                                    color: recording ? _redColor : _mutedColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Obx(() {
                        return Text(
                          controller.currentQuestion.question,
                          style: const TextStyle(
                            color: _textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.4,
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      _KeywordChips(controller: controller),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _CardBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.mic_rounded,
                            size: 20,
                            color: _tealColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Jawaban Kamu',
                            style: TextStyle(
                              color: _textColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Obx(() {
                            final conf = (controller.sttConfidence.value * 100)
                                .clamp(0, 100)
                                .toStringAsFixed(0);
                            return Text(
                              'Conf: $conf%',
                              style: TextStyle(
                                color: controller.sttConfidence.value > 0.7
                                    ? _greenColor
                                    : _amberColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Obx(() {
                        final answer = controller.recognizedLive.value.trim();
                        return Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(
                            minHeight: 140,
                            maxHeight: 240,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _bgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _borderColor),
                          ),
                          child: answer.isEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.mic_none_rounded,
                                      size: 32,
                                      color: _mutedColor,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Tekan tombol untuk mulai merekam',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _mutedColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : SingleChildScrollView(
                                  child: SelectableText(
                                    answer,
                                    style: const TextStyle(
                                      color: _textColor,
                                      fontSize: 16,
                                      height: 1.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        );
                      }),
                      const SizedBox(height: 16),

                      // Recording Timer
                      Obx(() {
                        if (controller.isRecording.value) {
                          return Column(
                            children: [
                              LinearProgressIndicator(
                                value: controller.recordingSeconds.value / 10,
                                backgroundColor: _borderColor,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  controller.recordingSeconds.value >= 8
                                      ? _redColor
                                      : _greenColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rekaman: ${controller.recordingSeconds.value}/10 detik',
                                style: TextStyle(
                                  color: controller.recordingSeconds.value >= 8
                                      ? _redColor
                                      : _greenColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox();
                      }),

                      const SizedBox(height: 16),

                      // Recording Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: Obx(() {
                          final isRecording = controller.isRecording.value;
                          final seconds = controller.recordingSeconds.value;

                          return GestureDetector(
                            onTapDown: (_) async {
                              if (!isRecording && seconds < 10) {
                                await controller.startRecording();
                              }
                            },
                            onTapUp: (_) async {
                              if (isRecording) {
                                await controller.stopRecording();
                              }
                            },
                            onTapCancel: () async {
                              if (isRecording) {
                                await controller.stopRecording();
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isRecording ? _redColor : _tealColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: isRecording
                                        ? _redColor.withOpacity(0.3)
                                        : _tealColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isRecording
                                        ? Icons.mic_rounded
                                        : Icons.mic_none_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isRecording
                                        ? 'LEPASKAN UNTUK BERHENTI'
                                        : 'TEKAN & TAHAN UNTUK MULAI',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: _mutedColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tekan & tahan tombol untuk merekam. Rekaman otomatis berhenti setelah 10 detik.',
                              style: TextStyle(
                                color: _mutedColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Restart'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _mutedColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(color: _borderColor),
                        ),
                        onPressed: controller.start,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.flag_rounded),
                        label: const Text('Selesai'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tealColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: controller.stopEarlyToResult,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KeywordChips extends StatelessWidget {
  const _KeywordChips({required this.controller});
  final HrdSimController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final kws = controller.currentQuestion.keywords;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keyword Penting:',
            style: TextStyle(
              color: _mutedColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kws.map((k) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _tealColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _tealColor.withOpacity(0.3)),
                ),
                child: Text(
                  k,
                  style: const TextStyle(
                    color: _tealColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}

class _ProgressChip extends StatelessWidget {
  const _ProgressChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ================== RESULT ==================
class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.controller});
  final HrdSimController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Obx(() {
            final score = controller.finalScore.value;
            final points = controller.earnedPoints.value;

            Color scoreColor;
            if (score >= 80) {
              scoreColor = _greenColor;
            } else if (score >= 60) {
              scoreColor = _tealColor;
            } else if (score >= 40) {
              scoreColor = _amberColor;
            } else {
              scoreColor = _redColor;
            }

            return Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: scoreColor.withOpacity(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    score >= 60
                        ? Icons.emoji_events_rounded
                        : Icons.insights_rounded,
                    size: 32,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hasil Simulasi',
                        style: TextStyle(
                          color: _mutedColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$score/100',
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '+$points poin diperoleh',
                        style: const TextStyle(
                          color: _mutedColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 28),
                  color: _tealColor,
                  onPressed: controller.start,
                  tooltip: 'Ulangi simulasi',
                ),
              ],
            );
          }),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.feedback_rounded,
                          size: 20,
                          color: _blueColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Feedback HRD (Sesi Terakhir)',
                          style: TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final list = controller.feedback.toList();
                      if (list.isEmpty) {
                        return Text(
                          'Belum ada feedback.',
                          style: TextStyle(color: _mutedColor),
                        );
                      }
                      return Column(
                        children: list.map((t) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.arrow_right_rounded,
                                  size: 20,
                                  color: _tealColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t,
                                    style: const TextStyle(
                                      color: _textColor,
                                      height: 1.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(
                          Icons.list_alt_rounded,
                          size: 20,
                          color: _blueColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Detail Jawaban',
                          style: TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Obx(() {
                final qs = controller.questions.toList();
                final scores = controller.questionScores.toList();
                final hits = controller.keywordHits.toList();
                final answers = controller.questionAnswers.toList();

                return Column(
                  children: List.generate(qs.length, (i) {
                    final q = qs[i].question;
                    final s = i < scores.length ? scores[i] : 0;
                    final h = i < hits.length ? hits[i] : 0;
                    final a = i < answers.length ? answers[i] : '';

                    Color sc;
                    if (s >= 80)
                      sc = _greenColor;
                    else if (s >= 60)
                      sc = _tealColor;
                    else if (s >= 40)
                      sc = _amberColor;
                    else
                      sc = _redColor;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q${i + 1}. $q',
                            style: const TextStyle(
                              color: _textColor,
                              fontWeight: FontWeight.w900,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ScoreChip(
                                icon: Icons.score_rounded,
                                label: 'Skor: $s',
                                color: sc,
                              ),
                              _ScoreChip(
                                icon: Icons.key_rounded,
                                label: 'Keyword: $h',
                                color: _blueColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Jawaban:',
                            style: TextStyle(
                              color: _mutedColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _borderColor),
                            ),
                            child: a.trim().isEmpty
                                ? Text(
                                    '-',
                                    style: TextStyle(
                                      color: _mutedColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : SelectableText(
                                    a,
                                    style: const TextStyle(
                                      color: _textColor,
                                      height: 1.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  }),
                );
              }),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text(
                    'Kembali',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tealColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: controller.backToIntro,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ================== SHARED ==================
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardBox extends StatelessWidget {
  const _CardBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
