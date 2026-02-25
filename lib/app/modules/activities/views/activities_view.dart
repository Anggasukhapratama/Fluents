import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/activities_controller.dart';

class ActivitiesView extends GetView<ActivitiesController> {
  const ActivitiesView({super.key});

  static const _accent = Color(0xFF0B1220);
  static const _muted = Color(0xFF64748B);
  static const _bg = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Aktivitas'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _accent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.activities.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.activities.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada aktivitas.\nMulai latihan sekarang!',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => controller.listenActivities(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = controller.activities[i];

                final timeText =
                    '${a.at.day.toString().padLeft(2, '0')}/'
                    '${a.at.month.toString().padLeft(2, '0')}/${a.at.year} '
                    '${a.at.hour.toString().padLeft(2, '0')}:'
                    '${a.at.minute.toString().padLeft(2, '0')}';

                final fc = _featureColorFromTitle(a.title);

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (a.route.isNotEmpty) Get.toNamed(a.route);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: fc.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.history, size: 20, color: fc),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: _accent,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    timeText,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: fc.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '+${a.points} poin',
                                      style: TextStyle(
                                        color: fc,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: fc),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  // ✅ sama kayak dashboard (tinggal copy)
  Color _featureColorFromTitle(String title) {
    final t = title.toLowerCase();

    if (t.contains('materi')) return const Color(0xFF0D9488); // teal-600
    if (t.contains('narasi')) return const Color(0xFF7C3AED); // purple
    if (t.contains('tanya hrd')) return const Color(0xFF065F46); // emerald-800
    if (t.contains('simulasi hrd') || t.contains('hrd sim')) {
      return const Color(0xFF10B981); // green
    }
    if (t.contains('cek wajah') || t.contains('face')) {
      return const Color(0xFF4F46E5); // indigo
    }
    if (t.contains('video')) return const Color(0xFFEF4444); // red-500

    return _accent;
  }
}
