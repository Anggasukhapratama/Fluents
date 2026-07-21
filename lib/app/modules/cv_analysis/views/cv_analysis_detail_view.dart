import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cv_analysis_controller.dart';
import 'cv_practice_view.dart';

class CvAnalysisDetailView extends GetView<CvAnalysisController> {
  const CvAnalysisDetailView({super.key});

  static const _bg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FAFF), Color(0xFFF0F4FF), Color(0xFFE8F0FF)],
  );

  static const _text = Color(0xFF1A1F36);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE2E8F0);
  static const _accent = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _bg),
        child: SafeArea(
          child: Obx(() {
            final r = controller.selected.value;
            if (r == null) return _center('Data tidak ditemukan.');

            if (r.status == 'processing')
              return _center('Sedang menganalisis…', loader: true);
            if (r.status == 'error')
              return _center(
                r.errorMessage.isEmpty ? 'Terjadi error.' : r.errorMessage,
              );

            final p = r.profile;
            final role = r.roleRec.suggestedRole.trim();
            final score = r.roleRec.fitScore;

            return Column(
              children: [
                _topBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      _hero(r.fileName, r.charCount),
                      const SizedBox(height: 12),

                      // ===== ROLE RECOMMENDATION CARD =====
                      _section('Rekomendasi Pekerjaan'),
                      _roleCard(
                        role: role.isEmpty ? '-' : role,
                        score: score,
                        reasons: r.roleRec.reasons,
                        strengths: r.roleRec.strengths,
                        gaps: r.roleRec.gaps,
                        breakdown: r.roleRec.breakdown,
                      ),

                      const SizedBox(height: 12),
                      _section('Identitas'),
                      _kv('Nama', p.fullName),
                      _kv('Role (di CV)', p.headlineRole),
                      _kv('Tgl Lahir', p.dateOfBirth),
                      _kv('Email', p.email),
                      _kv('No HP', p.phone),
                      _kv('Lokasi', p.location),

                      const SizedBox(height: 12),
                      _section('Ringkasan'),
                      _cardText(p.summary.isEmpty ? '-' : p.summary),

                      const SizedBox(height: 12),
                      _section('Skills'),
                      _chips(p.skills),

                      const SizedBox(height: 12),
                      _section('Pengalaman'),
                      _bullets(p.experiences),

                      const SizedBox(height: 12),
                      _section('Pendidikan'),
                      _bullets(p.educations),

                      const SizedBox(height: 12),
                      _section('Project'),
                      _bullets(p.projects),

                      const SizedBox(height: 12),
                      _section('Sertifikat'),
                      _bullets(p.certificates),

                      // Tombol latihan (dikomentari, terserah Anda)
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_rounded, color: _text),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Detail Analisis',
              style: TextStyle(
                color: _text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(Icons.auto_awesome_rounded, color: _accent),
        ],
      ),
    );
  }

  Widget _hero(String fileName, int chars) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.description_rounded, color: _accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$chars karakter terbaca',
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleCard({
    required String role,
    required int score,
    required List<String> reasons,
    required List<String> strengths,
    required List<String> gaps,
    required Map<String, double> breakdown,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work_rounded, color: _accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  role,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              if (score > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _accent.withOpacity(0.18)),
                  ),
                  child: Text(
                    'Kecocokan: $score%',
                    style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Kenapa cocok:',
            style: TextStyle(color: _muted, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _bulletList(reasons.isEmpty ? const ['-'] : reasons),

          const SizedBox(height: 10),
          const Text(
            'Kekuatan pendukung:',
            style: TextStyle(color: _muted, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _bulletList(strengths.isEmpty ? const ['-'] : strengths),

          if (gaps.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Yang perlu dilengkapi:',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            _bulletList(gaps),
          ],

          // ===== BREAKDOWN =====
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: _border),
            const SizedBox(height: 10),
            const Text(
              'Rincian Kecocokan per Aspek:',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...breakdown.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        _getCategoryLabel(entry.key),
                        style: const TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (entry.value / 100).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: _border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          entry.value >= 70
                              ? const Color(0xFF10B981)
                              : (entry.value >= 50
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFEF4444)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${entry.value.round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getCategoryLabel(String key) {
    switch (key) {
      case 'skillMatch':
        return 'Skill';
      case 'experienceMatch':
        return 'Pengalaman';
      case 'educationMatch':
        return 'Pendidikan';
      case 'projectMatch':
        return 'Proyek';
      case 'certificateMatch':
        return 'Sertifikat';
      default:
        return key;
    }
  }

  Widget _bulletList(List<String> items) => Column(
    children: items
        .map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(fontWeight: FontWeight.w900, color: _text),
                ),
                Expanded(
                  child: Text(
                    e,
                    style: const TextStyle(color: _text, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: const TextStyle(
        color: _text,
        fontWeight: FontWeight.w900,
        fontSize: 16,
      ),
    ),
  );

  Widget _kv(String k, String v) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            k,
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            v.trim().isEmpty ? '-' : v,
            style: const TextStyle(color: _text, height: 1.35),
          ),
        ),
      ],
    ),
  );

  Widget _cardText(String t) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: Text(t, style: const TextStyle(color: _text, height: 1.4)),
  );

  Widget _chips(List<String> items) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: items.isEmpty
        ? const Text('-', style: TextStyle(color: _muted))
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _accent.withOpacity(0.18)),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
  );

  Widget _bullets(List<String> items) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: items.isEmpty
        ? const Text('-', style: TextStyle(color: _muted))
        : Column(
            children: items
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _text,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e,
                            style: const TextStyle(color: _text, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
  );

  Widget _center(String msg, {bool loader = false}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: _accent, size: 44),
          if (loader) ...[
            const SizedBox(height: 12),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _text,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}
