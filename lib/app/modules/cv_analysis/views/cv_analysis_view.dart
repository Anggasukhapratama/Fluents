import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cv_analysis_controller.dart';
import 'cv_analysis_detail_view.dart';

class CvAnalysisView extends GetView<CvAnalysisController> {
  const CvAnalysisView({super.key});

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
          child: Column(
            children: [
              _header(),
              Expanded(
                child: Obx(() {
                  final err = controller.errorText.value.trim();
                  if (err.isNotEmpty) return _error(err);

                  if (controller.isLoadingList.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    children: [
                      _infoCard(),
                      const SizedBox(height: 14),
                      const Text(
                        'Riwayat',
                        style: TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (controller.results.isEmpty)
                        _emptyState()
                      else
                        ..._list(),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Obx(() {
        final loading = controller.isAnalyzing.value;
        final disabled =
            loading || controller.errorText.value.trim().isNotEmpty;

        return FloatingActionButton.extended(
          onPressed: disabled ? null : controller.analyzePdfCv,
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.picture_as_pdf_rounded),
          label: Text(loading ? 'Menganalisis…' : 'Upload & Parse CV'),
        );
      }),
    );
  }

  Widget _header() {
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
              'Analisis CV AI',
              style: TextStyle(
                color: _text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(Icons.auto_awesome_rounded, color: _accent),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: const Text(
        'Upload PDF → diparse jadi profil → AI rekomendasikan pekerjaan paling cocok + alasan → lalu jadi pertanyaan latihan.',
        style: TextStyle(color: _text, height: 1.35),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Text(
        'Belum ada data. Klik tombol Upload & Parse CV.',
        style: TextStyle(color: _muted),
      ),
    );
  }

  List<Widget> _list() {
    return controller.results.map((r) {
      Color c;
      String label;

      if (r.status == 'done') {
        c = const Color(0xFF10B981);
        label = 'Selesai';
      } else if (r.status == 'error') {
        c = const Color(0xFFEF4444);
        label = 'Gagal';
      } else {
        c = const Color(0xFFF59E0B);
        label = 'Diproses';
      }

      final role = r.roleRec.suggestedRole.trim();
      final subtitle = r.status == 'done'
          ? '${r.charCount} karakter • ${role.isEmpty ? (r.profile.headlineRole.isEmpty ? "Role belum terbaca" : r.profile.headlineRole) : "Cocok: $role"}'
          : (r.status == 'error'
                ? (r.errorMessage.isEmpty ? 'Terjadi error' : r.errorMessage)
                : 'Sedang diproses…');

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            controller.open(r);
            Get.to(() => const CvAnalysisDetailView());
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.description_rounded, color: c),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: c.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: c,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus',
                  onPressed: () => controller.deleteResult(r),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _error(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock_outline_rounded, color: _accent, size: 42),
              SizedBox(height: 12),
              Text(
                'Silakan login dulu untuk memakai fitur ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
