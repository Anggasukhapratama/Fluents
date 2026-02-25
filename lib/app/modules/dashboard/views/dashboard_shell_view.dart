import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/dashboard_shell_controller.dart';
import 'dashboard_view.dart';

import '../../leaderboard/controllers/leaderboard_controller.dart';
import '../../leaderboard/views/leaderboard_view.dart';

import '../../activities/views/activities_view.dart';
import '../../progress/views/progress_view.dart';
import '../../profile/views/profile_view.dart';

class DashboardShellView extends StatelessWidget {
  const DashboardShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = Get.find<DashboardShellController>();

    // ✅ FIX: karena LeaderboardView pakai GetView<LeaderboardController>
    // dan kita pakai IndexedStack (bukan route), maka controller harus di-inject manual.
    if (!Get.isRegistered<LeaderboardController>()) {
      Get.put(LeaderboardController(), permanent: true);
    }

    return Obx(() {
      return Scaffold(
        body: IndexedStack(
          index: shell.tabIndex.value,
          children: [
            const DashboardView(),
            const LeaderboardView(),
            const ActivitiesView(),
            const ProgressView(),
            ProfileView(),
          ],
        ),

        // ✅ Modern bottom nav (lebih soft & elegan)
        bottomNavigationBar: _ModernBottomNav(shell: shell),
      );
    });
  }
}

// ===================== MODERN NAVBAR =====================
class _ModernBottomNav extends StatelessWidget {
  final DashboardShellController shell;
  const _ModernBottomNav({required this.shell});

  static const _brand = Color(0xFFE53935); // Fluent red
  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _navItem(index: 0, icon: Icons.home_rounded, label: 'Home'),
          _navItem(index: 1, icon: Icons.emoji_events_rounded, label: 'Rank'),
          _navItem(index: 2, icon: Icons.history_rounded, label: 'Log'),
          _navItem(index: 3, icon: Icons.trending_up_rounded, label: 'Progres'),
          _navItem(index: 4, icon: Icons.person_rounded, label: 'Profil'),
        ],
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: Obx(() {
        final active = shell.tabIndex.value == index;

        return GestureDetector(
          onTap: () => shell.changeTab(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? _brand.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: active ? _brand : _muted),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: active ? _text : _muted,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
