import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../controllers/more_features_controller.dart';

class MoreFeaturesView extends GetView<MoreFeaturesController> {
  const MoreFeaturesView({super.key});

  // ===== MODERN PALETTE (Sama persis dengan Dashboard) =====
  static const _bg = Color(0xFFF8FAFC);
  static const _surface = Colors.white;
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  static const _shadow = BoxShadow(
    color: Color(0x08000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  IconData _iconFromName(String name) {
    switch (name) {
      case 'video':
        return LucideIcons.video;
      case 'mic':
        return LucideIcons.mic;
      case 'users':
        return LucideIcons.users;
      case 'scan-face':
        return LucideIcons.scanFace;
      case 'graduation-cap':
        return LucideIcons.graduationCap;
      case 'bot':
        return LucideIcons.bot;
      case 'file-search':
        return LucideIcons.fileSearch;
      default:
        return LucideIcons.layoutGrid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: const Text(
          'Eksplorasi Fitur',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _text,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            decoration: const BoxDecoration(
              color: _surface,
              shape: BoxShape.circle,
              boxShadow: [_shadow],
            ),
            child: IconButton(
              tooltip: "Info",
              onPressed: () {
                Get.snackbar(
                  "Fluent AI",
                  "Pilih fitur yang ingin kamu coba 🔥",
                  backgroundColor: Colors.white,
                  colorText: _text,
                );
              },
              icon: const Icon(LucideIcons.info, color: _text, size: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              _buildModernSearch(),
              const SizedBox(height: 24),
              Expanded(child: _buildGrid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 0.8),
        boxShadow: const [_shadow],
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, color: _muted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (v) => controller.query.value = v,
              style: const TextStyle(
                color: _text,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              decoration: const InputDecoration(
                hintText: 'Cari fitur (Cth: AI, CV)...',
                hintStyle: TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Obx(() {
            final has = controller.query.value.trim().isNotEmpty;
            if (!has) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () {
                controller.query.value = '';
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _muted.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.x, color: _muted, size: 16),
              ),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _border, width: 0.8),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.searchX, color: _muted, size: 40),
                SizedBox(height: 16),
                Text(
                  "Fitur tidak ditemukan.\nCoba kata kunci lain ya!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.88, // Memberikan ruang ekstra agar tidak overflow
        ),
        itemBuilder: (context, i) {
          final f = items[i];
          final name = (f['name'] ?? '').toString();
          final subtitle = (f['subtitle'] ?? '').toString();
          final tag = (f['tag'] ?? '').toString();
          final iconName = (f['icon_name'] ?? '').toString();
          final route = f['route'] as String?;
          final color = f['color'] as Color;

          return _PremiumFeatureCard(
            name: name,
            subtitle: subtitle,
            tag: tag,
            color: color,
            icon: _iconFromName(iconName),
            onTap: () {
              if (route == null) {
                Get.snackbar(
                  "Segera Hadir",
                  "$name masih dalam tahap pengembangan 🚀",
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

class _PremiumFeatureCard extends StatefulWidget {
  final String name;
  final String subtitle;
  final String tag;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _PremiumFeatureCard({
    required this.name,
    required this.subtitle,
    required this.tag,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PremiumFeatureCard> createState() => _PremiumFeatureCardState();
}

class _PremiumFeatureCardState extends State<_PremiumFeatureCard> {
  bool _pressed = false;

  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _shadow = BoxShadow(
    color: Color(0x08000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border, width: 0.8),
            boxShadow: const [_shadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.tag,
                      style: TextStyle(
                        color: widget.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _text,
                  fontSize: 15,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    "Mulai",
                    style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.arrowRight, size: 14, color: widget.color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
