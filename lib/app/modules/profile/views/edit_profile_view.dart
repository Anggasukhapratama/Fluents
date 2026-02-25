import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final ProfileController c = Get.find<ProfileController>();

  late final TextEditingController nameC;
  late final TextEditingController jobC;

  // ✅ dropdown harus pakai label yang persis sama dengan items
  String genderLabel = 'Laki-laki';

  static const genderItems = ['Laki-laki', 'Perempuan', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    nameC = TextEditingController(text: c.username.value);
    jobC = TextEditingController(text: c.occupation.value);

    // ✅ NORMALISASI dari data firestore (biasanya lowercase: perempuan)
    final raw = c.gender.value.trim().toLowerCase();
    if (raw == 'perempuan') {
      genderLabel = 'Perempuan';
    } else if (raw == 'lainnya') {
      genderLabel = 'Lainnya';
    } else if (raw == 'laki-laki' || raw == 'laki laki') {
      genderLabel = 'Laki-laki';
    } else {
      genderLabel = 'Laki-laki';
    }

    // ✅ Safety: pastikan value ada di items
    if (!genderItems.contains(genderLabel)) {
      genderLabel = 'Laki-laki';
    }
  }

  @override
  void dispose() {
    nameC.dispose();
    jobC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newName = nameC.text.trim();
    final newJob = jobC.text.trim();

    if (newName.isEmpty || newJob.isEmpty) {
      Get.snackbar('Gagal', 'Nama & pekerjaan wajib diisi');
      return;
    }

    final ok = await c.updateProfile(
      newUsername: newName,
      newGenderLabel: genderLabel,
      newOccupation: newJob,
    );

    if (!ok) {
      Get.snackbar('Gagal', 'Tidak dapat memperbarui profil');
      return;
    }

    // ✅ balik dulu ke profil
    Get.back();

    // ✅ kasih jeda dikit biar snackbar pasti muncul setelah pindah halaman
    Future.delayed(const Duration(milliseconds: 150), () {
      Get.snackbar('Berhasil', 'Profil berhasil diperbarui');
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: Get.back,
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderCard(
                      title: 'Perbarui Profil Kamu',
                      subtitle: 'Agar pengalaman latihan lebih personal.',
                      icon: Icons.edit_rounded,
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Nama',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameC,
                      textInputAction: TextInputAction.next,
                      enabled: !c.isLoading.value,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan nama',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Gender',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: genderLabel,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.wc_rounded),
                      ),
                      items: genderItems
                          .map(
                            (g) => DropdownMenuItem<String>(
                              value: g,
                              child: Text(g),
                            ),
                          )
                          .toList(),
                      onChanged: c.isLoading.value
                          ? null
                          : (v) {
                              if (v == null) return;
                              setState(() => genderLabel = v);
                            },
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Pekerjaan yang Diinginkan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: jobC,
                      enabled: !c.isLoading.value,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Software Engineer',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      onSubmitted: (_) {
                        if (!c.isLoading.value) _save();
                      },
                    ),
                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pastikan data benar sebelum disimpan.',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // bottom action bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: c.isLoading.value ? null : Get.back,
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: c.isLoading.value ? null : _save,
                          child: c.isLoading.value
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
