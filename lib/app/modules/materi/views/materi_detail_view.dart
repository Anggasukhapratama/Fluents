import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/materi_controller.dart';

class MateriDetailView extends GetView<MateriController> {
  final Map<String, dynamic> item;
  const MateriDetailView({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final id = item['id'].toString();
    final title = item['title'].toString();
    final category = item['category'].toString();
    final level = item['level'].toString();
    final minutes = (item['minutes'] ?? 0).toString();
    final icon = item['icon'] as IconData? ?? Icons.menu_book;
    final categoryColor = controller.getCategoryColor(category);
    final levelColor = controller.getLevelColor(level);
    final resources =
        (item['resources'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final isCompleted = controller.completedIds.contains(id);
    final isInProgress = controller.inProgressIds.contains(id);

    final content =
        (item['content'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final actions =
        (item['actions'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0B0B0F),
            foregroundColor: Colors.white,
            elevation: 0,
            expandedHeight: 160,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      categoryColor.withOpacity(0.3),
                      const Color(0xFF0B0B0F).withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
              onPressed: () => Get.back(),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Get.snackbar(
                    'Berbagi',
                    'Materi "$title" berhasil disalin',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: categoryColor.withOpacity(0.9),
                    colorText: Colors.white,
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.share, size: 20),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          categoryColor.withOpacity(0.15),
                          categoryColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: categoryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: categoryColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: categoryColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: categoryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item['subtitle'].toString(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Stats
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _statItem(
                            Icons.timer_outlined,
                            '$minutes mnt',
                            'Durasi',
                            Colors.blueAccent,
                          ),
                        ),
                        Expanded(
                          child: _statItem(
                            Icons.bar_chart,
                            level,
                            'Level',
                            levelColor,
                          ),
                        ),
                        Expanded(
                          child: _statItem(
                            Icons.format_list_bulleted,
                            '${content.length}',
                            'Poin',
                            Colors.purpleAccent,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress Buttons
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              controller.toggleInProgress(id);
                              Get.snackbar(
                                isInProgress ? 'Paused' : 'Started',
                                isInProgress
                                    ? 'Latihan dijeda'
                                    : 'Mulai mengerjakan latihan',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: isInProgress
                                    ? Colors.orange.withOpacity(0.9)
                                    : Colors.blueAccent.withOpacity(0.9),
                                colorText: Colors.white,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInProgress
                                  ? Colors.orange.withOpacity(0.2)
                                  : Colors.blueAccent.withOpacity(0.2),
                              foregroundColor: isInProgress
                                  ? Colors.orange
                                  : Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isInProgress
                                      ? Colors.orange.withOpacity(0.5)
                                      : Colors.blueAccent.withOpacity(0.5),
                                ),
                              ),
                            ),
                            icon: Icon(
                              isInProgress ? Icons.pause : Icons.play_arrow,
                              size: 18,
                            ),
                            label: Text(
                              isInProgress ? 'Jeda' : 'Mulai',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              // ✅ toggle + poin + activity (di controller)
                              await controller.toggleComplete(id, item: item);

                              // ✅ ambil status TERBARU setelah toggle
                              final isCompletedNow = controller.completedIds
                                  .contains(id);

                              Get.snackbar(
                                isCompletedNow ? 'Completed' : 'Unmarked',
                                isCompletedNow
                                    ? 'Materi selesai dikerjakan! +poin ✅'
                                    : 'Materi belum selesai',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: isCompletedNow
                                    ? Colors.greenAccent.withOpacity(0.9)
                                    : Colors.grey.withOpacity(0.9),
                                colorText: Colors.white,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              // ✅ style pakai status TERBARU juga (biar nggak “telat”)
                              backgroundColor:
                                  (controller.completedIds.contains(id))
                                  ? Colors.greenAccent.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.1),
                              foregroundColor:
                                  (controller.completedIds.contains(id))
                                  ? Colors.greenAccent
                                  : Colors.white,
                              padding: const EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: (controller.completedIds.contains(id))
                                      ? Colors.greenAccent.withOpacity(0.5)
                                      : Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ),
                            child: Icon(
                              (controller.completedIds.contains(id))
                                  ? Icons.check
                                  : Icons.check_circle_outline,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content Section
                  _sectionTitle('Materi Pembelajaran'),
                  const SizedBox(height: 12),
                  ..._buildContent(content),
                  const SizedBox(height: 24),

                  // Practice Section
                  if (actions.isNotEmpty) ...[
                    _sectionTitle('Latihan Praktis'),
                    const SizedBox(height: 12),
                    ..._buildActions(actions),
                    const SizedBox(height: 24),
                  ],

                  // Resources Section
                  if (resources.isNotEmpty) ...[
                    _sectionTitle('Resources Tambahan'),
                    const SizedBox(height: 12),
                    ..._buildResources(resources),
                    const SizedBox(height: 24),
                  ],

                  // Notes Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber.withOpacity(0.8),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tips Sukses',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Praktekkan materi ini minimal 2-3 kali sebelum interview. '
                          'Rekam jawaban Anda dan evaluasi untuk perbaikan berkelanjutan.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        t,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
        ),
      ],
    );
  }

  List<Widget> _buildContent(List<String> content) {
    return content.map((text) {
      if (text.isEmpty) {
        return const SizedBox(height: 12);
      }

      final isBullet =
          text.startsWith('•') ||
          text.startsWith('-') ||
          text.startsWith('✓') ||
          RegExp(r'^\d+\.').hasMatch(text);

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBullet)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 10),
                child: Icon(Icons.circle, color: Colors.greenAccent, size: 6),
              ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildActions(List<Map<String, dynamic>> actions) {
    return actions.asMap().entries.map((entry) {
      final index = entry.key;
      final action = entry.value;
      final text = action['text']?.toString() ?? '';
      final type = action['type']?.toString() ?? '';
      final color = controller.getActionColor(type);
      final icon = controller.getActionIcon(type);

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        child: ElevatedButton(
          onPressed: () {
            _showActionDetail(action);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.15),
            foregroundColor: color,
            padding: const EdgeInsets.all(14),
            alignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color.withOpacity(0.3)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'LATIHAN ${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.7),
                size: 14,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildResources(List<String> resources) {
    return resources.map((resource) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: () {
            _showResourceDetail(resource);
          },
          leading: Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.description, color: Colors.blueAccent, size: 16),
          ),
          title: Text(
            resource.split(':')[0],
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            resource.contains(':') ? resource.split(':')[1].trim() : resource,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withOpacity(0.5),
            size: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          minLeadingWidth: 0,
        ),
      );
    }).toList();
  }

  void _showActionDetail(Map<String, dynamic> action) {
    final text = action['text']?.toString() ?? '';
    final type = action['type']?.toString() ?? '';
    final instructions =
        (action['instructions'] as List?)?.cast<String>() ?? [];
    final tips = action['tips']?.toString() ?? '';
    final color = controller.getActionColor(type);
    final icon = controller.getActionIcon(type);

    Get.bottomSheet(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1F),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Instructions
              const Text(
                'LANGKAH-LANGKAH:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...instructions.asMap().entries.map((entry) {
                final idx = entry.key;
                final instruction = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          instruction,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Tips
              if (tips.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'TIPS PENTING:',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tips,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _startPracticeSession(action);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'MULAI LATIHAN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 50,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showResourceDetail(String resource) {
    Get.defaultDialog(
      title: '📚 Resource',
      titleStyle: const TextStyle(color: Colors.white, fontSize: 18),
      backgroundColor: const Color(0xFF1A1A1F),
      content: SizedBox(
        width: Get.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Text(
                  resource,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gunakan resource ini untuk mendalami materi.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      confirm: ElevatedButton(
        onPressed: () => Get.back(),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        child: const Text('OK'),
      ),
    );
  }

  void _startPracticeSession(Map<String, dynamic> action) {
    final type = action['type']?.toString() ?? '';
    final text = action['text']?.toString() ?? '';
    final color = controller.getActionColor(type);

    switch (type) {
      case 'practice':
        _startPracticeTimer(text, color);
        break;
      case 'record':
        _startRecordingSession(text, color);
        break;
      case 'write':
        _openWritingSession(text, color);
        break;
      case 'research':
        _startResearchTask(text, color);
        break;
      case 'create':
        _startCreationTask(text, color);
        break;
      case 'improve':
        _startImprovementTask(text, color);
        break;
      case 'prepare':
        _startPreparationTask(text, color);
        break;
      case 'review':
        _startReviewTask(text, color);
        break;
      case 'check':
        _startCheckTask(text, color);
        break;
      case 'design':
        _startDesignTask(text, color);
        break;
      default:
        Get.snackbar(
          'Latihan Dimulai',
          'Mulai: $text',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blueAccent.withOpacity(0.9),
          colorText: Colors.white,
        );
    }
  }

  void _startPracticeTimer(String taskName, Color color) {
    int seconds = 120; // 2 menit default

    if (taskName.contains('3 menit')) seconds = 180;
    if (taskName.contains('5 menit')) seconds = 300;
    if (taskName.contains('2 menit')) seconds = 120;

    bool isRunning = true;
    int remainingSeconds = seconds;

    Get.defaultDialog(
      title: '⏱️ Timer Latihan',
      titleStyle: const TextStyle(color: Colors.white, fontSize: 18),
      backgroundColor: const Color(0xFF1A1A1F),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Fokus pada latihan sampai timer habis',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: remainingSeconds / seconds,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      color: color,
                    ),
                  ),
                  Text(
                    '${(remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                taskName,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Text(
                'Tips: Tarik napas dalam, mulai dengan percaya diri!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
          Get.snackbar(
            'Latihan Selesai!',
            'Selamat! Kamu telah menyelesaikan latihan.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.greenAccent.withOpacity(0.9),
            colorText: Colors.white,
          );
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
        child: const Text('SELESAI'),
      ),
    );
  }

  void _startRecordingSession(String taskName, Color color) {
    Get.defaultDialog(
      title: '🎤 Rekam Latihan',
      titleStyle: const TextStyle(color: Colors.white, fontSize: 18),
      backgroundColor: const Color(0xFF1A1A1F),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic, color: color, size: 50),
          const SizedBox(height: 16),
          const Text(
            'Siap merekam jawaban Anda',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            taskName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tips Recording:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '1. Gunakan ruang tenang\n'
            '2. Jarak mic 15-20 cm dari mulut\n'
            '3. Speak clearly & confidently\n'
            '4. Dengarkan kembali untuk evaluasi',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
          // Simulasi recording
          Get.snackbar(
            '🎤 Recording Dimulai',
            'Rekaman sedang berlangsung...',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: color.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );

          Future.delayed(const Duration(seconds: 2), () {
            Get.snackbar(
              'Rekaman Selesai',
              'Simpan rekaman untuk evaluasi diri',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.greenAccent.withOpacity(0.9),
              colorText: Colors.white,
            );
          });
        },
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: const Text('MULAI REKAM'),
      ),
    );
  }

  void _openWritingSession(String taskName, Color color) {
    TextEditingController writingController = TextEditingController();

    Get.defaultDialog(
      title: '✍️ Tulis Jawaban',
      titleStyle: const TextStyle(color: Colors.white, fontSize: 18),
      backgroundColor: const Color(0xFF1A1A1F),
      content: SizedBox(
        width: Get.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              taskName,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: writingController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: 'Tulis jawaban Anda di sini...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Simpan untuk referensi interview nanti',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      confirm: ElevatedButton(
        onPressed: () {
          if (writingController.text.trim().isNotEmpty) {
            Get.back();
            Get.snackbar(
              'Tersimpan!',
              'Jawaban telah disimpan untuk latihan',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.greenAccent.withOpacity(0.9),
              colorText: Colors.white,
            );
          }
        },
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: const Text('SIMPAN'),
      ),
    );
  }

  void _startResearchTask(String taskName, Color color) {
    Get.defaultDialog(
      title: '🔍 Research Task',
      titleStyle: const TextStyle(color: Colors.white, fontSize: 18),
      backgroundColor: const Color(0xFF1A1A1F),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, color: color, size: 50),
          const SizedBox(height: 16),
          Text(
            taskName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sumber yang direkomendasikan:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '• Glassdoor\n'
            '• LinkedIn Salary Insights\n'
            '• Tech forums lokal\n'
            '• Company reviews',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
          Get.snackbar(
            'Research Dimulai',
            'Buka browser untuk mencari informasi',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: color.withOpacity(0.9),
            colorText: Colors.white,
          );
        },
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: const Text('BUKA BROWSER'),
      ),
    );
  }

  void _startCheckTask(String taskName, Color color) {
    List<bool> checklist = List.filled(4, false);

    Get.defaultDialog(
      title: '✅ Checklist Task',
      titleStyle: const TextStyle(color: Colors.white, fontSize: 18),
      backgroundColor: const Color(0xFF1A1A1F),
      content: StatefulBuilder(
        builder: (context, setState) {
          return SizedBox(
            width: Get.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  taskName,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ...[
                  'Test microphone',
                  'Check camera',
                  'Test internet',
                  'Prepare notes',
                ].asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return CheckboxListTile(
                    title: Text(
                      item,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    value: checklist[index],
                    onChanged: (value) {
                      setState(() {
                        checklist[index] = value ?? false;
                      });
                    },
                    activeColor: color,
                    checkColor: Colors.white,
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
          Get.snackbar(
            'Checklist Selesai',
            'Persiapan interview telah diperiksa',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.greenAccent.withOpacity(0.9),
            colorText: Colors.white,
          );
        },
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: const Text('SIMPAN CHECKLIST'),
      ),
    );
  }

  // Fungsi-fungsi lainnya untuk type yang berbeda
  void _startCreationTask(String taskName, Color color) {
    Get.defaultDialog(
      title: '🛠️ Create Task',
      titleStyle: const TextStyle(color: Colors.white, fontSize: 18),
      backgroundColor: const Color(0xFF1A1A1F),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_circle, color: color, size: 50),
          const SizedBox(height: 16),
          Text(
            taskName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 20),
          const Text(
            'Mulai membuat:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '• STAR story dari project\n'
            '• API design document\n'
            '• Architecture diagram\n'
            '• Implementation plan',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () => Get.back(),
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: const Text('MULAI'),
      ),
    );
  }

  void _startDesignTask(String taskName, Color color) {
    Get.defaultDialog(
      title: '🏗️ Design Task',
      titleStyle: const TextStyle(color: Colors.white, fontSize: 18),
      backgroundColor: const Color(0xFF1A1A1F),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.architecture, color: color, size: 50),
          const SizedBox(height: 16),
          Text(
            taskName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pertimbangan design:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '• Scalability\n'
            '• Maintainability\n'
            '• Performance\n'
            '• Security',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () => Get.back(),
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: const Text('DESIGN'),
      ),
    );
  }

  void _startImprovementTask(String taskName, Color color) {
    Get.defaultDialog(
      title: '📈 Improvement Task',
      titleStyle: const TextStyle(color: Colors.white, fontSize: 18),
      backgroundColor: const Color(0xFF1A1A1F),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, color: color, size: 50),
          const SizedBox(height: 16),
          Text(
            taskName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 20),
          const Text(
            'Area improvement:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '• Add metrics to results\n'
            '• Improve clarity\n'
            '• Strengthen examples\n'
            '• Optimize timing',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () => Get.back(),
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: const Text('PERBAIKI'),
      ),
    );
  }

  void _startPreparationTask(String taskName, Color color) {
    Get.defaultDialog(
      title: '📋 Preparation Task',
      titleStyle: const TextStyle(color: Colors.white, fontSize: 18),
      backgroundColor: const Color(0xFF1A1A1F),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist, color: color, size: 50),
          const SizedBox(height: 16),
          Text(
            taskName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 20),
          const Text(
            'Siapkan:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '• Project examples\n'
            '• Technical explanations\n'
            '• Portfolio links\n'
            '• Questions for interviewer',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () => Get.back(),
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: const Text('SIAPKAN'),
      ),
    );
  }

  void _startReviewTask(String taskName, Color color) {
    Get.defaultDialog(
      title: '🔍 Review Task',
      titleStyle: const TextStyle(color: Colors.white, fontSize: 18),
      backgroundColor: const Color(0xFF1A1A1F),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.reviews, color: color, size: 50),
          const SizedBox(height: 16),
          Text(
            taskName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aspect to review:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '• Code architecture\n'
            '• Best practices\n'
            '• Performance issues\n'
            '• Security concerns',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () => Get.back(),
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: const Text('REVIEW'),
      ),
    );
  }
}
