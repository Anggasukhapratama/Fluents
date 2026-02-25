import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../controllers/more_features_controller.dart';

class MoreFeaturesView extends GetView<MoreFeaturesController> {
  const MoreFeaturesView({super.key});

  // ===== theme =====
  static const _bg = Color(0xFFF7F5F2);
  static const _surface = Colors.white;
  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE7E5E4);
  static const _shadow = Color(0x1A000000);

  IconData _iconFromName(String name) {
    switch (name) {
      case 'video':
        return LucideIcons.video;
      case 'book-open':
        return LucideIcons.bookOpen;
      case 'users':
        return LucideIcons.users;
      case 'scan-face':
        return LucideIcons.scanFace;
      case 'graduation-cap':
        return LucideIcons.graduationCap;
      case 'agent':
        return LucideIcons.bot;

      // ✅ icon untuk Analisis CV AI
      case 'file-search':
        return LucideIcons.fileSearch;

      default:
        return LucideIcons.grid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Lainnya',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _text,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Info",
            onPressed: () {
              Get.snackbar(
                "Fluent AI",
                "Pilih fitur yang ingin kamu coba 🔥",
                backgroundColor: Colors.white,
                colorText: _text,
              );
            },
            icon: const Icon(Icons.info_outline_rounded, color: _text),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              _buildSearch(),
              const SizedBox(height: 14),
              Expanded(child: _buildGrid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(color: _shadow, blurRadius: 16, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => controller.query.value = v,
              decoration: const InputDecoration(
                hintText: 'Cari fitur… (AI, Latihan, CV)',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Obx(() {
            final has = controller.query.value.trim().isNotEmpty;
            if (!has) return const SizedBox.shrink();
            return IconButton(
              splashRadius: 18,
              onPressed: () => controller.query.value = '',
              icon: const Icon(Icons.close_rounded, color: _muted),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Obx(() {
      final items = controller.filtered;

      if (items.isEmpty) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: const Text(
              "Tidak ada fitur yang cocok.\nCoba kata lain ya 🙂",
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
            ),
          ),
        );
      }

      return GridView.builder(
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (context, i) {
          final f = items[i];
          final name = (f['name'] ?? '').toString();
          final subtitle = (f['subtitle'] ?? '').toString();
          final tag = (f['tag'] ?? '').toString();
          final iconName = (f['icon_name'] ?? '').toString();
          final route = f['route'] as String?;
          final color = f['color'] as Color;

          return _FeatureCard(
            name: name,
            subtitle: subtitle,
            tag: tag,
            color: color,
            icon: _iconFromName(iconName),
            onTap: () {
              if (route == null) {
                Get.snackbar(
                  "Info",
                  "$name segera hadir 🚀",
                  backgroundColor: Colors.white,
                  colorText: _text,
                );
                return;
              }
              Get.toNamed(route);
            },
          );
        },
      );
    });
  }
}

class _FeatureCard extends StatefulWidget {
  final String name;
  final String subtitle;
  final String tag;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.name,
    required this.subtitle,
    required this.tag,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE7E5E4);
  static const _shadow = Color(0x1A000000);

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(color: _shadow, blurRadius: 16, offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: widget.color.withOpacity(0.16)),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 22),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: widget.color.withOpacity(0.16)),
                    ),
                    child: Text(
                      widget.tag,
                      style: TextStyle(
                        color: widget.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _text,
                  fontSize: 14,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    "Buka",
                    style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: widget.color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
