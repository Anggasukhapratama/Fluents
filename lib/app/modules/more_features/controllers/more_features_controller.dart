import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MoreFeaturesController extends GetxController {
  final query = ''.obs;

  final features = <Map<String, dynamic>>[
    {
      'name': 'Video Wawancara',
      'subtitle': 'Rekam & evaluasi',
      'tag': 'Latihan',
      'icon_name': 'video',
      'route': '/video',
      'color': const Color(0xFFE53935), // Fluent red
    },
    {
      'name': 'Latihan Narasi',
      'subtitle': 'Bicara lebih lancar',
      'tag': 'Latihan',
      'icon_name': 'book-open',
      'route': '/narasi-detect',
      'color': const Color(0xFF7C3AED),
    },
    {
      'name': 'Simulasi HRD',
      'subtitle': 'Interview mock',
      'tag': 'Simulasi',
      'icon_name': 'users',
      'route': '/hrd-sim',
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'Tanya HRD AI',
      'subtitle': 'Chat dengan AI',
      'tag': 'AI',
      'icon_name': 'agent',
      'route': '/ask-hrd',
      'color': const Color(0xFF0F766E),
    },

    // ✅ FITUR BARU
    {
      'name': 'Analisis CV AI',
      'subtitle': 'Upload CV → topik latihan',
      'tag': 'AI',
      'icon_name': 'file-search',
      'route': '/cv-analysis',
      'color': const Color(0xFF4F46E5), // indigo
    },

    {
      'name': 'Cek Wajah',
      'subtitle': 'Ekspresi & fokus',
      'tag': 'CV',
      'icon_name': 'scan-face',
      'route': '/face-check',
      'color': const Color(0xFF3B82F6),
    },
    // {
    //   'name': 'Materi Belajar',
    //   'subtitle': 'Tips interview',
    //   'tag': 'Materi',
    //   'icon_name': 'graduation-cap',
    //   'route': '/materi',
    //   'color': const Color(0xFF8B5E34),
    // },
  ].obs;

  List<Map<String, dynamic>> get filtered {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return features;
    return features.where((f) {
      final n = (f['name'] ?? '').toString().toLowerCase();
      final s = (f['subtitle'] ?? '').toString().toLowerCase();
      final t = (f['tag'] ?? '').toString().toLowerCase();
      return n.contains(q) || s.contains(q) || t.contains(q);
    }).toList();
  }
}
