import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/leaderboard_controller.dart';

class LeaderboardView extends GetView<LeaderboardController> {
  const LeaderboardView({super.key});

  // ===== MODERN THEME =====
  static const _bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FAFF), Color(0xFFF0F4FF), Color(0xFFE8F0FF)],
  );

  static const _surface = Colors.white;
  static const _text = Color(0xFF1A1F36);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE2E8F0);
  static const _shadow = Color(0x12000000);
  static const _accent = Color(0xFF4F46E5);
  static const _accentLight = Color(0xFF818CF8);

  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFC0C0C0);
  static const _bronze = Color(0xFFCD7F32);
  static const _goldGradient = LinearGradient(
    colors: [Color(0xFFFFF8E1), Color(0xFFFFF3BF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const _silverGradient = LinearGradient(
    colors: [Color(0xFFF5F7FA), Color(0xFFE4E7EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const _bronzeGradient = LinearGradient(
    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== UTILITY FUNCTIONS =====
  Color _rankColor(int index) {
    if (index == 0) return _gold;
    if (index == 1) return _silver;
    if (index == 2) return _bronze;
    return _accent;
  }

  Gradient _rankGradient(int index) {
    if (index == 0) return _goldGradient;
    if (index == 1) return _silverGradient;
    if (index == 2) return _bronzeGradient;
    return const LinearGradient(
      colors: [Colors.white, Color(0xFFF8FAFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  String _rankLabel(int index) {
    if (index == 0) return "JUARA 1";
    if (index == 1) return "JUARA 2";
    if (index == 2) return "JUARA 3";
    return "RANK ${index + 1}";
  }

  Future<void> _refresh() async {
    controller.listenLeaderboard();
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ===== HEADER =====
              _buildAppBar(),

              // ===== CONTENT =====
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.users.isEmpty) {
                    return _buildLoading();
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: _accent,
                    backgroundColor: Colors.white,
                    displacement: 40,
                    child: _buildContent(),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== APP BAR =====
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_rounded, color: _text),
          ),
          const SizedBox(width: 8),
          const Text(
            "Leaderboard",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _text,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Obx(() {
            final rank = controller.currentUserRank.value;
            if (rank > 0) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accent, _accentLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  "Rank #$rank",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              );
            }
            return const SizedBox();
          }),
          IconButton(
            onPressed: _refresh,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: _accent,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== LOADING STATE =====
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(_accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Memuat ranking...",
            style: TextStyle(
              color: _muted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ===== MAIN CONTENT =====
  Widget _buildContent() {
    final users = controller.users;

    if (users.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard(),
        const SizedBox(height: 24),

        if (users.length >= 3) _buildPodium(users),
        if (users.length >= 3) const SizedBox(height: 32),

        _buildRankingList(users),
        const SizedBox(height: 80),
      ],
    );
  }

  // ===== EMPTY STATE =====
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: _border, width: 2),
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                size: 50,
                color: _muted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Belum Ada Ranking",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Jadilah yang pertama mendapatkan poin\nuntuk mencapai puncak leaderboard!",
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                shadowColor: _accent.withOpacity(0.3),
              ),
              child: const Text(
                "Refresh",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== INFO CARD =====
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accent, _accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.leaderboard_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ranking Langsung",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Diupdate real-time berdasarkan poin latihan.\nLakukan lebih banyak latihan untuk naik ranking!",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== PODIUM SECTION (CLEAN + NO OVERFLOW + JOB & GENDER) =====
  Widget _buildPodium(List<LeaderboardUser> users) {
    final top3 = users.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Top 3",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 360,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (top3.length > 1) _buildPodiumCard(top3[1], 1, height: 255),
              if (top3.isNotEmpty) _buildPodiumCard(top3[0], 0, height: 305),
              if (top3.length > 2) _buildPodiumCard(top3[2], 2, height: 240),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumCard(
    LeaderboardUser user,
    int index, {
    required double height,
  }) {
    final isMe = user.uid == controller.myUid();
    final color = _rankColor(index);
    final gradient = _rankGradient(index);

    final jobText = (user.job.isNotEmpty && user.job != '-') ? user.job : '';
    final genderText = (user.gender.isNotEmpty && user.gender != '-')
        ? user.gender
        : '';

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Rank Badge
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(color: color.withOpacity(0.15)),
                child: Text(
                  _rankLabel(index),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Content (all inside, so no overlay/ketutup)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 44, 12, 12),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: user.photoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(29),
                                  child: Image.network(
                                    user.photoUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : "?",
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 10),

                        // Name
                        SizedBox(
                          width: 98,
                          child: Text(
                            user.name.split(' ').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _text,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),

                        // Job (1 line, subtle)
                        if (jobText.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 110,
                            child: Text(
                              jobText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],

                        // Gender chip (small, centered)
                        if (genderText.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _miniChip(
                            icon: Icons.person_outline,
                            text: genderText,
                            color: color,
                          ),
                        ],

                        const SizedBox(height: 10),

                        // Points
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${user.pointsTotal}",
                            style: TextStyle(
                              color: color,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        const Text(
                          "poin",
                          style: TextStyle(
                            color: _muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        if (isMe) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "ANDA",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Crown for 1st place
            if (index == 0)
              Positioned(
                top: -18,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _gold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===== RANKING LIST =====
  Widget _buildRankingList(List<LeaderboardUser> users) {
    final rest = users.length > 3 ? users.sublist(3) : <LeaderboardUser>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Semua Ranking",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
        const SizedBox(height: 16),
        if (rest.isEmpty)
          _buildEmptyRankings()
        else
          ...rest.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            final rank = index + 4;
            final isMe = user.uid == controller.myUid();
            return _buildRankingCard(user, rank, isMe);
          }),
      ],
    );
  }

  Widget _buildEmptyRankings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 48,
            color: _muted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            "Ranking lainnya akan muncul",
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Lanjutkan latihan untuk melihat lebih banyak user",
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard(LeaderboardUser user, int rank, bool isMe) {
    final isTop10 = rank <= 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMe ? _accent.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? _accent.withOpacity(0.3) : _border,
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTop10
                  ? _accent.withOpacity(0.1)
                  : _muted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTop10
                    ? _accent.withOpacity(0.3)
                    : _muted.withOpacity(0.2),
              ),
            ),
            child: Center(
              child: Text(
                "$rank",
                style: TextStyle(
                  color: isTop10 ? _accent : _muted,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "ANDA",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.job.isNotEmpty ? user.job : "Tidak ada pekerjaan",
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _infoChip(
                      icon: Icons.email_outlined,
                      text: user.email.split('@').first,
                    ),
                    if (user.gender.isNotEmpty && user.gender != '-')
                      _infoChip(icon: Icons.person_outline, text: user.gender),
                  ],
                ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isTop10
                        ? [_accent, _accentLight]
                        : [_muted.withOpacity(0.1), _muted.withOpacity(0.2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${user.pointsTotal}",
                  style: TextStyle(
                    color: isTop10 ? Colors.white : _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "poin",
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _accent),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: _text,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
        ],
      ),
    );
  }
}
