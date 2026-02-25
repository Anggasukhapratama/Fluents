import 'package:fluent_ai/app/modules/ask_hrd/controllers/ask_hrd_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AskHrdView extends GetView<AskHrdController> {
  const AskHrdView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tanya HRD AI'),
        centerTitle: false,
        elevation: 0,
        actions: [
          Obx(() {
            final started = controller.isSessionStarted.value;
            if (!started) return const SizedBox.shrink();
            return IconButton(
              onPressed: controller.isLoading.value || controller.isTyping.value
                  ? null
                  : () => controller.restartSession(),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Mulai sesi baru',
            );
          }),
        ],
      ),
      body: Column(
        children: [
          _TopForm(controller: controller),
          const Divider(height: 1, thickness: 0.5),
          Expanded(child: _ChatList(controller: controller)),
          const Divider(height: 1, thickness: 0.5),
          _HoldToTalkBar(controller: controller),
        ],
      ),
    );
  }
}

class _TopForm extends StatelessWidget {
  final AskHrdController controller;
  const _TopForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Persiapan Interview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.jobTargetCtrl,
            decoration: InputDecoration(
              labelText: 'Target Pekerjaan',
              hintText: 'Contoh: Customer Service, Frontend Developer, dll.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              prefixIcon: const Icon(Icons.work_outline_rounded),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final started = controller.isSessionStarted.value;
            final isLoading = controller.isLoading.value;
            final isTyping = controller.isTyping.value;

            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading || started || isTyping
                    ? null
                    : () => controller.startSession(),
                icon: Icon(
                  started
                      ? Icons.play_arrow_rounded
                      : Icons.play_circle_fill_rounded,
                  size: 20,
                ),
                label: Text(
                  started ? 'Sesi Berjalan' : 'Mulai Interview (5 Pertanyaan)',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            );
          }),
          Obx(() {
            if (!controller.isSessionStarted.value)
              return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: controller.isFinished.value
                              ? Colors.green.shade100
                              : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              controller.isFinished.value
                                  ? Icons.check_circle_rounded
                                  : Icons.timer_rounded,
                              size: 12,
                              color: controller.isFinished.value
                                  ? Colors.green.shade800
                                  : Colors.blue.shade800,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              controller.isFinished.value
                                  ? 'Selesai'
                                  : 'Ronde ${controller.questionIndex.value}/5',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: controller.isFinished.value
                                        ? Colors.green.shade800
                                        : Colors.blue.shade800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (controller.scores.isNotEmpty &&
                          !controller.isFinished.value) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Skor: ${controller.scores.values.last}/10',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade900,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
          Obx(() {
            if (!controller.isTyping.value) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HRD sedang mengetik...',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          if (controller.typingPreview.value.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              controller.typingPreview.value,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  final AskHrdController controller;
  const _ChatList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final msgs = controller.messages;
      if (msgs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.forum_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Mulai Interview HRD',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Isi target kerja kamu dan tekan "Mulai Interview" untuk memulai simulasi wawancara dengan AI HRD',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: controller.scrollCtrl,
        padding: const EdgeInsets.all(16),
        itemCount: msgs.length,
        itemBuilder: (_, i) {
          final m = msgs[i];
          final isUser = m.role == 'user';
          final isTyping = m.type == 'typing';
          final isInfo = m.type == 'info';
          final isSummary = m.type == 'summary';

          if (isTyping)
            return const SizedBox.shrink(); // Sudah ditampilkan di _TopForm

          Color bubbleColor;
          Color textColor;
          Alignment align;
          BorderRadius borderRadius;

          if (isUser) {
            bubbleColor = Theme.of(context).colorScheme.primary;
            textColor = Theme.of(context).colorScheme.onPrimary;
            align = Alignment.centerRight;
            borderRadius = const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            );
          } else if (isInfo) {
            bubbleColor = Theme.of(context).colorScheme.surfaceVariant;
            textColor = Theme.of(context).colorScheme.onSurfaceVariant;
            align = Alignment.center;
            borderRadius = BorderRadius.circular(12);
          } else if (isSummary) {
            bubbleColor = Colors.green.shade50;
            textColor = Theme.of(context).colorScheme.onSurface;
            align = Alignment.centerLeft;
            borderRadius = BorderRadius.circular(16);
          } else {
            bubbleColor = Theme.of(context).colorScheme.surface;
            textColor = Theme.of(context).colorScheme.onSurface;
            align = Alignment.centerLeft;
            borderRadius = const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            );
          }

          return Align(
            alignment: align,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: Column(
                crossAxisAlignment: isUser || isInfo
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isInfo && !isSummary)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? bubbleColor.withOpacity(0.2)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getIconForType(m.type),
                              size: 10,
                              color: isUser ? textColor : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getTitleForType(m.type),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isUser
                                        ? textColor
                                        : Colors.grey.shade700,
                                  ),
                            ),
                            if (m.index > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '#${m.index}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: isUser
                                          ? textColor.withOpacity(0.8)
                                          : Colors.grey.shade600,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: borderRadius,
                      border: isSummary
                          ? Border.all(color: Colors.green.shade200, width: 1)
                          : null,
                      boxShadow: [
                        if (!isInfo && !isSummary)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isUser || isInfo
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (isSummary)
                          Row(
                            children: [
                              Icon(
                                Icons.celebration_rounded,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ringkasan Interview',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                              ),
                            ],
                          ),
                        if (isSummary) const SizedBox(height: 8),
                        Text(
                          m.content,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: textColor, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'question':
        return Icons.question_answer_rounded;
      case 'answer':
        return Icons.mic_rounded;
      case 'feedback':
        return Icons.feedback_rounded;
      case 'summary':
        return Icons.summarize_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getTitleForType(String type) {
    switch (type) {
      case 'question':
        return 'PERTANYAAN';
      case 'answer':
        return 'JAWABAN';
      case 'feedback':
        return 'FEEDBACK';
      case 'summary':
        return 'RINGKASAN';
      default:
        return 'INFO';
    }
  }
}

class _HoldToTalkBar extends StatelessWidget {
  final AskHrdController controller;
  const _HoldToTalkBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Obx(() {
        final started = controller.isSessionStarted.value;
        final finished = controller.isFinished.value;
        final loading = controller.isLoading.value;
        final listening = controller.isListening.value;
        final typing = controller.isTyping.value;
        final canTalk = started && !finished && !loading && !typing;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.liveTranscript.value.isNotEmpty || listening)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: listening
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: listening
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2)
                          : Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: listening ? 24 : 0,
                        child: listening
                            ? Icon(
                                Icons.mic_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          listening
                              ? (controller.liveTranscript.value.isEmpty
                                    ? 'Mendengarkan...'
                                    : controller.liveTranscript.value)
                              : controller.liveTranscript.value,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: listening
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              GestureDetector(
                onLongPressStart: canTalk
                    ? (_) => controller.startListening()
                    : null,
                onLongPressEnd: canTalk
                    ? (_) => controller.stopListeningAndSend()
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _getButtonColor(
                      context,
                      finished,
                      canTalk,
                      listening,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: canTalk && !listening
                        ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getButtonIcon(finished, listening, canTalk, typing),
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _getButtonText(
                            finished,
                            loading,
                            canTalk,
                            listening,
                            typing,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                finished
                    ? 'Interview selesai. Lihat ringkasan di atas.'
                    : 'Tahan tombol untuk berbicara, lepaskan untuk mengirim',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Color _getButtonColor(
    BuildContext context,
    bool finished,
    bool canTalk,
    bool listening,
  ) {
    if (finished) return Colors.grey;
    if (!canTalk) return Colors.grey.shade400;
    if (listening) return Theme.of(context).colorScheme.error;
    return Theme.of(context).colorScheme.primary;
  }

  IconData _getButtonIcon(
    bool finished,
    bool listening,
    bool canTalk,
    bool typing,
  ) {
    if (finished) return Icons.check_circle_rounded;
    if (listening) return Icons.mic_rounded;
    if (typing) return Icons.keyboard_rounded;
    if (!canTalk) return Icons.mic_off_rounded;
    return Icons.mic_none_rounded;
  }

  String _getButtonText(
    bool finished,
    bool loading,
    bool canTalk,
    bool listening,
    bool typing,
  ) {
    if (finished) return 'Sesi Interview Selesai';
    if (loading) return 'Memproses jawaban...';
    if (typing) return 'HRD sedang mengetik...';
    if (listening) return 'Lepaskan untuk mengirim jawaban';
    if (!canTalk) return 'Mulai interview untuk berbicara';
    return 'Tahan untuk merekam jawaban';
  }
}
