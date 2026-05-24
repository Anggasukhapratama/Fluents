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
      'color': const Color(0xFFFF5722), // Deep Orange / Sunset
    },
    {
      'name': 'Latihan Narasi',
      'subtitle': 'Bicara lebih lancar',
      'tag': 'Latihan',
      'icon_name': 'mic',
      'route': '/narasi-detect',
      'color': const Color(0xFF8B5CF6), // Purple
    },
    {
      'name': 'Analisis CV AI',
      'subtitle': 'Upload CV → topik latihan',
      'tag': 'AI',
      'icon_name': 'file-search',
      'route': '/cv-analysis',
      'color': const Color(0xFF4F46E5), // Indigo
    },
    {
      'name': 'Latihan Ekspresi',
      'subtitle': 'Ekspresi & kontak mata',
      'tag': 'Latihan',
      'icon_name': 'scan-face',
      'route': '/face-check',
      'color': const Color(0xFF0EA5E9), // Light Blue
    },
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
