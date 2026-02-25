import 'package:fluent_ai/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:fluent_ai/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MateriController extends GetxController {
  final query = ''.obs;
  final selectedCategory = 'Semua'.obs;
  final completedIds = <String>{}.obs;
  final inProgressIds = <String>{}.obs;

  // Warna untuk setiap kategori
  final Map<String, Color> categoryColors = {
    'Semua': Colors.grey,
    'HR Basics': Colors.blue,
    'Perkenalan': Colors.green,
    'STAR': Colors.orange,
    'Gaji': Colors.purple,
    'Online Interview': Colors.teal,
    'Role: Frontend': Colors.amber,
    'Role: Backend': Colors.deepOrange,
    'Technical': Colors.red,
  };

  final categories = <String>[
    'Semua',
    'HR Basics',
    'Perkenalan',
    'STAR',
    'Gaji',
    'Online Interview',
    'Role: Frontend',
    'Role: Backend',
    'Technical',
  ].obs;

  // DATA MATERI LENGKAP DENGAN LATIHAN & RESOURCES
  final items = <Map<String, dynamic>>[
    {
      'id': 'intro_60s',
      'category': 'Perkenalan',
      'title': 'Perkenalan Diri 60 Detik',
      'subtitle': 'Script siap pakai + struktur aman untuk interview',
      'minutes': 6,
      'level': 'Mudah',
      'icon': Icons.waving_hand,
      'content': [
        'Struktur: Nama + posisi incaran + highlight pengalaman + bukti + closing.',
        'Contoh:',
        '"Halo, saya Angga. Saya tertarik di posisi Flutter Developer. Selama kuliah saya fokus membangun aplikasi mobile dengan Firebase & GetX, termasuk fitur autentikasi, dashboard, dan modul latihan interview. Saya terbiasa kerja dengan target dan iterasi cepat. Saya berharap bisa berkontribusi di tim untuk membangun produk yang rapi dan scalable."',
        'Tips Penting:',
        '• Fokus pada pencapaian yang relevan dengan posisi',
        '• Gunakan angka/metrik jika memungkinkan',
        '• Jangan terlalu lama, maksimal 90 detik',
        '• Praktekkan dengan suara keras minimal 3x',
      ],
      'actions': [
        {
          'text': 'Latih 3x dengan timer 2 menit',
          'type': 'practice',
          'instructions': [
            'Siapkan timer selama 2 menit',
            'Bacakan script perkenalan dengan suara jelas',
            'Catat waktu: idealnya 60-90 detik',
            'Ulangi 3x untuk meningkatkan kelancaran',
          ],
          'tips':
              'Berhenti jika melebihi 2 menit, latihan fokus pada singkat dan padat',
        },
        {
          'text': 'Rekam suara & evaluasi',
          'type': 'record',
          'instructions': [
            'Gunakan voice recorder/HP',
            'Rekam tanpa melihat catatan',
            'Dengarkan kembali rekaman',
            'Evaluasi: kecepatan, kejelasan, confidence',
          ],
          'tips':
              'Perhatikan intonasi dan jeda. Hindari "eee..." atau "mmm..."',
        },
        {
          'text': 'Perbaiki 1 kalimat terlemah',
          'type': 'improve',
          'instructions': [
            'Identifikasi kalimat paling tidak yakin',
            'Tulis ulang dengan struktur lebih baik',
            'Tambahkan contoh/metrik jika perlu',
            'Latih kalimat baru 5x',
          ],
          'tips':
              'Contoh perbaikan: "Saya bisa Flutter" → "Saya telah build 3 app Flutter dengan rating 4.8+"',
        },
      ],
      'resources': [
        '📝 Template Script Perkenalan:\nNama: ______\nPosisi: ______\nPengalaman: ______\nBukti: ______\nClosing: ______',
        '🎥 Contoh Video: "Perkenalan 60 detik yang efektif" - cari di YouTube',
        '✅ Checklist Poin Penting:\n- Eye contact virtual\n- Senyum\n- Postur tegap\n- Volume suara stabil',
      ],
    },
    {
      'id': 'hr_strength_weakness',
      'category': 'HR Basics',
      'title': 'Strength & Weakness',
      'subtitle': 'Jawaban aman tanpa red flag',
      'minutes': 8,
      'level': 'Mudah',
      'icon': Icons.balance,
      'content': [
        'Strength: pilih 1-2 kekuatan utama + contoh nyata + dampak.',
        'Contoh strength:',
        '"Saya sangat detail-oriented. Di project terakhir, saya menemukan bug kecil yang ternyata mencegah memory leak. Akhirnya performa app meningkat 15%."',
        '',
        'Weakness: pilih kelemahan yang tidak fatal + upaya perbaikan + progress.',
        'Contoh weakness aman:',
        '"Dulu saya suka terlalu detail dan perfeksionis, sekarang saya pakai timeboxing & prioritas dengan teknik Pomodoro. Hasilnya, produktivitas naik 30% tanpa kualitas menurun."',
        '',
        'Hindari:',
        '• Kelemahan yang critical untuk pekerjaan',
        '• "Saya workaholic" (klise)',
        '• Jawaban "Saya tidak punya kelemahan"',
      ],
      'actions': [
        {
          'text': 'Tulis 2 strength dengan contoh spesifik',
          'type': 'write',
          'instructions': [
            'Strength 1: Pilih skill utama (contoh: problem-solving)',
            'Contoh nyata: "Saat project deadline maju 1 minggu, saya buat priority matrix"',
            'Hasil: "Tim bisa fokus di task critical, deliver tepat waktu"',
            'Strength 2: Pilih soft skill (contoh: teamwork)',
          ],
          'tips': 'Gunakan formula: Skill + Contoh + Dampak Terukur',
        },
        {
          'text': 'Tulis 1 weakness + rencana perbaikan',
          'type': 'write',
          'instructions': [
            'Pilih weakness yang bisa diperbaiki (contoh: public speaking)',
            'Rencana: "Ikut toastmasters, latihan presentasi 2x/minggu"',
            'Progress: "Sudah improve 30% dalam 3 bulan"',
            'Closing: "Masih terus berlatih untuk lebih baik"',
          ],
          'tips':
              'JANGAN pilih weakness critical untuk job. Contoh aman: terlalu detail, perfeksionis, baru belajar skill tertentu',
        },
        {
          'text': 'Roleplay dengan teman/keluarga',
          'type': 'practice',
          'instructions': [
            'Minta teman bertanya: "Apa kelebihan dan kekuranganmu?"',
            'Jawab tanpa catatan, natural',
            'Minta feedback: natural? meyakinkan?',
            'Adjust berdasarkan feedback',
          ],
          'tips': 'Rekam roleplay untuk evaluasi mandiri',
        },
      ],
      'resources': [
        '📋 Daftar 20 Strength yang Disukai HR:\n1. Adaptability\n2. Problem-solving\n3. Team collaboration\n4. Attention to detail\n5. Time management',
        '⚠️ 10 Weakness yang AMAN:\n1. Public speaking (dengan rencana improve)\n2. Terlalu detail (dengan timeboxing)\n3. Bilang "tidak" (belajar prioritas)\n4. Skill baru (sedang dipelajari)\n5. Multitasking (belajar fokus)',
        '🔄 Template Jawaban:\n"Strength saya adalah ______. Contohnya ketika ______. Hasilnya ______.\n\nWeakness saya ______. Saya improve dengan ______. Progressnya ______."',
      ],
    },
    {
      'id': 'star_template',
      'category': 'STAR',
      'title': 'Template STAR Method',
      'subtitle': 'Jawaban rapih untuk pertanyaan pengalaman kerja',
      'minutes': 10,
      'level': 'Menengah',
      'icon': Icons.star,
      'content': [
        'S (Situation): konteks singkat (1-2 kalimat).',
        'Contoh: "Di project mobile app untuk UMKM, tim kami harus launch dalam 2 bulan dengan resource terbatas."',
        '',
        'T (Task): tanggung jawab spesifik kamu.',
        'Contoh: "Saya bertanggung jawab untuk mengembangkan modul payment dan integrasi dengan 3 payment gateway."',
        '',
        'A (Action): langkah konkret yang kamu lakukan.',
        'Contoh: "Saya research payment provider, implement clean architecture untuk payment module, buat unit test 90% coverage, dan collaborate dengan backend team untuk API design."',
        '',
        'R (Result): hasil terukur (angka kalau bisa).',
        'Contoh: "App launch tepat waktu, payment success rate 99.8%, dan mendapatkan rating 4.8 di Play Store dari 500+ user."',
        '',
        'Tip: fokus 60% waktu di Action + Result.',
      ],
      'actions': [
        {
          'text': 'Buat cerita STAR dari project terakhir',
          'type': 'create',
          'instructions': [
            'Pilih 1 project terakhir/relevan',
            'S (Situation): "Project mobile app UMKM, deadline 2 bulan"',
            'T (Task): "Saya handle module payment & user auth"',
            'A (Action): "Research provider, implement clean arch, buat 50+ unit test"',
            'R (Result): "Success rate 99.8%, rating 4.8, launch tepat waktu"',
          ],
          'tips': 'Fokus 60% pada Action & Result. Gunakan angka/metrik.',
        },
        {
          'text': 'Presentasi STAR dalam 2 menit',
          'type': 'practice',
          'instructions': [
            'Timer 2 menit',
            'Presentasi tanpa catatan',
            'Record presentasi',
            'Evaluasi: apakah semua bagian STAR jelas?',
            'Adjust timing: Situation (20s), Task (20s), Action (50s), Result (30s)',
          ],
          'tips': 'Practice sampai bisa dalam 2 menit tanpa terburu-buru',
        },
        {
          'text': 'Tambah metrik & angka di Result',
          'type': 'improve',
          'instructions': [
            'Review Result section',
            'Tambah angka: % improvement, jumlah user, rating, waktu',
            'Contoh: "User engagement naik 40%" bukan "user engagement naik"',
            'Contoh: "Reduce bug reports 70%" bukan "fewer bugs"',
          ],
          'tips':
              'HR suka angka. Even estimasi lebih baik daripada tanpa angka.',
        },
      ],
      'resources': [
        '⭐ Template STAR Lengkap:\nSITUATION:\n______\n\nTASK:\n______\n\nACTION:\n1. ______\n2. ______\n3. ______\n\nRESULT:\n- Metrik 1: ______\n- Metrik 2: ______\n- Learning: ______',
        '📊 Contoh Metrik untuk Result:\n- Performance improvement: __%\n- Cost reduction: __%\n- Time saved: __ hours/days\n- User growth: __ users/%\n- Error reduction: __%\n- Rating increase: __ stars',
        '🎯 5 Pertanyaan Interview Cocok Pakai STAR:\n1. "Ceritakan pencapaian terbesar"\n2. "Bagaimana handle difficult situation?"\n3. "Contoh ketika solve complex problem"\n4. "Pengalaman bekerja dalam tim"\n5. "Bagaimana handle missed deadline?"',
      ],
    },
    {
      'id': 'salary_negotiation',
      'category': 'Gaji',
      'title': 'Negosiasi Gaji',
      'subtitle': 'Script sopan dan strategi efektif',
      'minutes': 7,
      'level': 'Menengah',
      'icon': Icons.attach_money,
      'content': [
        'Strategi:',
        '1. Research range gaji di kota & industri',
        '2. Tentukan range acceptable (min - ideal)',
        '3. Tunda sebut angka pertama jika bisa',
        '',
        'Kalimat aman:',
        '"Boleh saya tahu range budget untuk posisi ini?"',
        '"Berdasarkan riset & pengalaman saya 3 tahun di Flutter, saya melihat range untuk posisi ini di Jakarta sekitar Rp 15-20 juta. Bagaimana dengan range di perusahaan ini?"',
        '"Saya terbuka untuk negosiasi tergantung benefit package dan growth opportunity."',
        '',
        'Jangan:',
        '• Sebut angka tanpa riset',
        '• Terima tawaran pertama langsung',
        '• Fokus hanya pada gaji pokok',
        '',
        'Negotiable items:',
        '• THR & bonus',
        '• Asuransi kesehatan',
        '• Flexible hours',
        '• Remote work allowance',
        '• Training budget',
      ],
      'actions': [
        {
          'text': 'Research salary range di 3 sumber',
          'type': 'research',
          'instructions': [
            'Sumber 1: Glassdoor (cari company + position)',
            'Sumber 2: LinkedIn Salary Insights',
            'Sumber 3: Forum lokal (Facebook group IT Indonesia)',
            'Catat: Range untuk 1-3 tahun experience di Jakarta',
            'Tentukan: Min (Rp __), Target (Rp __), Max (Rp __)',
          ],
          'tips': 'Adjust berdasarkan skill khusus (Flutter, Firebase, etc.)',
        },
        {
          'text': 'Tulis script negosiasi',
          'type': 'write',
          'instructions': [
            'Script 1 (jika ditanya expected): "Berdasarkan research saya range untuk posisi ini di Jakarta sekitar Rp 15-20jt. Saya open to discussion berdasarkan overall package."',
            'Script 2 (jika ditanya current): "Saat ini di range Rp __, saya looking untuk growth opportunity dengan range Rp __."',
            'Script 3 (jika offer terlalu rendah): "Thank you untuk offer. Based on market research & my experience, I was expecting around Rp __. Is there flexibility?"',
          ],
          'tips': 'JANGAN sebut angka pertama. Tanya range mereka dulu.',
        },
        {
          'text': 'Roleplay negosiasi gaji',
          'type': 'practice',
          'instructions': [
            'Partner sebagai HR: "Berapa expected salary?"',
            'Kamu jawab dengan script',
            'HR: "Itu di atas budget kami, maksimal Rp 12jt"',
            'Kamu: "Saya understand budget constraints. Bagaimana dengan benefit lain? Remote work? Bonus? Training budget?"',
            'Practice 3 skenario berbeda',
          ],
          'tips':
              'Negosiasi bukan cuma gaji pokok. Benefit package juga penting.',
        },
      ],
      'resources': [
        '💰 Salary Range Flutter Developer 2024 (Jakarta):\n- Junior (0-2 tahun): Rp 8-12jt\n- Mid (2-4 tahun): Rp 12-18jt\n- Senior (4+ tahun): Rp 18-25jt+\n* Adjust berdasarkan perusahaan & skill khusus',
        '📝 Negotiation Script Templates:\n\nJika ditanya expected salary:\n"Berdasarkan riset saya untuk posisi [Job Title] dengan [X tahun] pengalaman di area [Location], range yang saya lihat adalah [Range]. Saya terbuka untuk diskusi tergantung benefit package dan growth opportunity."',
        '🎯 5 Hal yang Bisa Di-negotiate Selain Gaji:\n1. THR & bonus structure\n2. Asuransi kesehatan keluarga\n3. Remote work allowance\n4. Training/conference budget\n5. Equity/stock options (untuk startup)',
      ],
    },
    {
      'id': 'online_setup',
      'category': 'Online Interview',
      'title': 'Setup Interview Online',
      'subtitle': 'Checklist teknis dan persiapan ruang',
      'minutes': 5,
      'level': 'Mudah',
      'icon': Icons.videocam,
      'content': [
        'Hardware Checklist:',
        '✓ Kamera sejajar mata (gunakan tripod/stack buku)',
        '✓ Lighting dari depan (jangan dari belakang)',
        '✓ Mic eksternal atau earphone dengan mic',
        '✓ Internet backup (hotspot/tethering)',
        '',
        'Software Checklist:',
        '✓ Test platform (Zoom/Google Meet)',
        '✓ Close aplikasi tidak perlu',
        '✓ Siapkan portofolio di tab terpisah',
        '✓ Print CV sebagai cadangan',
        '',
        'Environment:',
        '✓ Background rapi/netral',
        '✓ Ruang tenang, tidak ada gangguan',
        '✓ Notifikasi dimatikan',
        '✓ Air minum dekat',
        '',
        '30 Menit Sebelum:',
        '✓ Test recording 1 menit',
        '✓ Cek framing & lighting',
        '✓ Pastikan baterai >80%',
        '✓ Login 5 menit lebih awal',
      ],
      'actions': [
        {
          'text': 'Cek mic & kamera',
          'type': 'check',
          'instructions': [
            'Buka camera app & test video',
            'Record audio 10 detik & play',
            'Test dengan teman via video call',
            'Pastikan tidak ada echo/noise',
          ],
          'tips': 'Gunakan earphone untuk mengurangi echo',
        },
        {
          'text': 'Test lighting & background',
          'type': 'check',
          'instructions': [
            'Posisikan light source di depan',
            'Hindari backlight dari jendela',
            'Cek background: rapi & profesional',
            'Test dengan virtual background jika perlu',
          ],
          'tips': 'Gunakan lampu meja atau ring light untuk lighting konsisten',
        },
        {
          'text': 'Siapkan portofolio & notes',
          'type': 'prepare',
          'instructions': [
            'Buka portofolio/GitHub di tab terpisah',
            'Print/simpan CV di desktop',
            'Siapkan notes: questions untuk interviewer',
            'Siapkan water bottle & tissue',
          ],
          'tips': 'Bookmark important projects untuk quick access',
        },
      ],
      'resources': [
        '💡 Lighting Setup Guide:\n- Main light: depan wajah, 45 derajat\n- Fill light: sisi kiri/kanan\n- Back light: belakang kepala\n- Gunakan 3-point lighting untuk hasil terbaik',
        '🎥 Background Virtual Templates:\n1. Blur background\n2. Office virtual background\n3. Simple bookshelf\n4. Neutral color wall\n* Download dari Zoom/Teams',
        '📶 Internet Speed Test Tools:\n- speedtest.net\n- fast.com\n- Minimal 5 Mbps upload/download\n- Test 1 jam sebelum interview',
      ],
    },
    {
      'id': 'frontend_common',
      'category': 'Role: Frontend',
      'title': 'Frontend: Pertanyaan Teknis Umum',
      'subtitle': 'Yang sering ditanya HR & technical interviewer',
      'minutes': 12,
      'level': 'Menengah',
      'icon': Icons.code,
      'content': [
        '1. State Management:',
        '• Kapan pakai GetX vs Provider vs BLoC?',
        '• Bagaimana handle state complex app?',
        '• Contoh implementasi di project nyata',
        '',
        '2. Performance Optimization:',
        '• Lazy loading untuk list besar',
        '• Image caching & compression',
        '• Code splitting & tree shaking',
        '• Memoization dengan const & final',
        '',
        '3. Architecture & Best Practices:',
        '• Clean Architecture di Flutter',
        '• Folder structure scalable',
        '• Error handling & logging',
        '• Testing strategy (unit, widget, integration)',
        '',
        '4. UI/UX Considerations:',
        '• Accessibility (a11y) guidelines',
        '• Responsive design patterns',
        '• Dark/light theme implementation',
        '• Internationalization (i18n)',
        '',
        '5. Package Management:',
        '• Cara pilih package yang reliable',
        '• Version conflict resolution',
        '• Custom package development',
      ],
      'actions': [
        {
          'text': 'Siapkan 2 project untuk diceritakan',
          'type': 'prepare',
          'instructions': [
            'Project 1: Pilih project terkompleks',
            'Siapkan: Problem, Solution, Architecture, Challenges, Results',
            'Project 2: Pilih project dengan business impact jelas',
            'Siapkan: Business goal, Your role, Technical decisions, Outcome',
            'Pastikan bisa cerita dalam 3-5 menit per project',
          ],
          'tips': 'Pilih project yang relevan dengan posisi dilamar',
        },
        {
          'text': 'Jawab 3 pertanyaan teknis umum',
          'type': 'practice',
          'instructions': [
            'Q1: "State management, kapan pakai GetX vs Provider?"\nA: "GetX untuk project kecil-medium, Provider untuk complex state. Saya pilih berdasarkan..."',
            'Q2: "Bagaimana optimize Flutter app performance?"\nA: "Lazy loading, image caching, const constructor, avoid rebuilds..."',
            'Q3: "Pengalaman dengan CI/CD untuk Flutter?"\nA: "Saya pakai Codemagic/Fastlane untuk auto build, test, deploy..."',
            'Record jawaban, evaluasi kelancaran',
          ],
          'tips':
              'Jawab dengan struktur: Penjelasan + Contoh pengalaman + Best practices',
        },
        {
          'text': 'Review architecture project terakhir',
          'type': 'review',
          'instructions': [
            'Buka project Flutter terakhir',
            'Review: Folder structure, Separation of concerns',
            'Check: State management implementation',
            'Evaluate: Error handling strategy',
            'Note: Apa yang bisa diperbaiki?',
          ],
          'tips':
              'Siapkan untuk pertanyaan: "Jika rebuild project ini, apa yang akan kamu ubah?"',
        },
      ],
      'resources': [
        '🧠 10 Pertanyaan Teknis Flutter Umum:\n1. Lifecycle widget\n2. Difference Stateless vs Stateful\n3. BuildContext adalah?\n4. Key dalam Flutter\n5. Async dalam Dart\n6. Null safety\n7. Mixin vs Inheritance\n8. Stream vs Future\n9. Package favorit & kenapa\n10. Testing strategy',
        '🏗️ Clean Architecture Checklist:\n- Data layer terpisah\n- Business logic di domain\n- Presentation layer clean\n- Dependency injection\n- Test coverage minimal 70%\n- Error handling konsisten',
        '⚡ Performance Optimization Tips:\n1. Use const constructors\n2. Implement ListView.builder untuk list panjang\n3. Cache images dengan cached_network_image\n4. Avoid rebuilds dengan Provider select\n5. Use isolates untuk heavy computation\n6. Lazy load modules',
      ],
    },
    {
      'id': 'backend_common',
      'category': 'Role: Backend',
      'title': 'Backend: Pertanyaan Teknis',
      'subtitle': 'Database, API, dan system design',
      'minutes': 15,
      'level': 'Menengah',
      'icon': Icons.storage,
      'content': [
        '1. Database Design:',
        '• Normalization vs denormalization',
        '• Indexing strategy & optimization',
        '• Transaction & locking mechanism',
        '',
        '2. API Design:',
        '• REST vs GraphQL vs gRPC',
        '• Authentication & authorization',
        '• Rate limiting & throttling',
        '• Versioning strategy',
        '',
        '3. System Design:',
        '• Scalability patterns',
        '• Caching strategy (Redis, Memcached)',
        '• Message queues (RabbitMQ, Kafka)',
        '• Microservices vs monolith',
        '',
        '4. Security:',
        '• SQL injection prevention',
        '• XSS & CSRF protection',
        '• Data encryption at rest & transit',
        '• API security best practices',
        '',
        '5. Performance:',
        '• Query optimization',
        '• Connection pooling',
        '• Load balancing',
        '• Monitoring & logging',
      ],
      'actions': [
        {
          'text': 'Design database schema sederhana',
          'type': 'design',
          'instructions': [
            'Pilih case: E-commerce app',
            'Design tables: Users, Products, Orders, OrderItems',
            'Tentukan relationships & foreign keys',
            'Add indexes untuk frequently queried columns',
          ],
          'tips': 'Normalize untuk consistency, denormalize untuk performance',
        },
        {
          'text': 'Buat API design untuk CRUD',
          'type': 'create',
          'instructions': [
            'Design REST API untuk Products:',
            'GET /api/products (list with pagination)',
            'POST /api/products (create)',
            'PUT /api/products/{id} (update)',
            'DELETE /api/products/{id} (soft delete)',
            'Include: authentication, validation, error responses',
          ],
          'tips':
              'Gunakan status codes yang tepat: 200, 201, 400, 401, 404, 500',
        },
        {
          'text': 'System design scenario',
          'type': 'practice',
          'instructions': [
            'Scenario: "Design URL shortening service seperti bit.ly"',
            'Requirements: 100M users, 1B URLs/month',
            'Design: API, database, caching, scaling',
            'Consider: hash generation, redirects, analytics',
          ],
          'tips':
              'Start dengan requirements, lalu high-level design, lalu detail components',
        },
      ],
      'resources': [
        '🗄️ Database Design Patterns:\n- One-to-one, One-to-many, Many-to-many\n- Indexing strategies\n- Partitioning & sharding\n- ACID properties\n- CAP theorem',
        '🔐 API Security Checklist:\n1. HTTPS only\n2. API key authentication\n3. Rate limiting\n4. Input validation\n5. SQL injection prevention\n6. CORS configuration',
        '📈 System Design Resources:\n- "Designing Data-Intensive Applications"\n- System Design Primer (GitHub)\n- High Scalability blog\n- AWS/GCP architecture diagrams',
      ],
    },
    {
      'id': 'behavioral_questions',
      'category': 'HR Basics',
      'title': 'Pertanyaan Behavioral',
      'subtitle': 'Cara jawab conflict, pressure, teamwork',
      'minutes': 9,
      'level': 'Menengah',
      'icon': Icons.psychology,
      'content': [
        'Common Questions:',
        '• "Ceritakan ketika kamu punya conflict dengan tim"',
        '• "Bagaimana kamu handle tight deadline?"',
        '• "Contoh ketika kamu mengambil inisiatif"',
        '',
        'Framework Jawaban:',
        '1. Situasi (singkat)',
        '2. Challenge/Problem',
        '3. Action yang kamu ambil',
        '4. Result/Outcome',
        '5. Learning/Reflection',
        '',
        'Contoh (Conflict Resolution):',
        'S: "Di project agile, dev dan QA sering miscommunication tentang bug priority."',
        'C: "Bug critical ditandai minor, menyebabkan release delay."',
        'A: "Saya initiate daily sync meeting, buat clear bug classification rubric, implement kanban board visible untuk semua."',
        'R: "Bug resolution time turun 40%, miscommunication berkurang drastis."',
        'L: "Communication tool harus disesuaikan dengan team dynamics."',
      ],
      'actions': [
        {
          'text': 'Prepare 3 behavioral stories',
          'type': 'prepare',
          'instructions': [
            'Story 1: Conflict resolution dengan tim',
            'Story 2: Handling tight deadline/pressure',
            'Story 3: Taking initiative/leadership',
            'Tulis dalam format STAR',
            'Practice telling each story in 2 minutes',
          ],
          'tips': 'Pilih stories yang show different skills & situations',
        },
        {
          'text': 'Practice STAR framework',
          'type': 'practice',
          'instructions': [
            'Pilih 1 behavioral question',
            'Jawab menggunakan STAR dalam 2 menit',
            'Record jawaban',
            'Evaluate: semua bagian STAR clear?',
            'Adjust untuk lebih concise jika perlu',
          ],
          'tips':
              'Time yourself: S (20s) + T (20s) + A (50s) + R (30s) = 2 menit',
        },
        {
          'text': 'Record & evaluate answers',
          'type': 'record',
          'instructions': [
            'Record jawaban untuk 3 pertanyaan behavioral',
            'Listen back dan evaluate:',
            '- Clarity & structure',
            '- Confidence level',
            '- Specific examples',
            '- Learning/reflection',
          ],
          'tips': 'Minta teman/mentor untuk feedback jika possible',
        },
      ],
      'resources': [
        '❓ 20 Pertanyaan Behavioral Umum:\n1. Tell me about yourself\n2. Why do you want this job?\n3. Why should we hire you?\n4. Where do you see yourself in 5 years?\n5. What is your greatest achievement?\n6. Describe a difficult work situation\n7. How do you handle stress?\n8. What are your salary expectations?',
        '⭐ Behavioral STAR Template:\nSITUATION: [2-3 kalimat]\nTASK: [Your specific responsibility]\nACTION: [What YOU did, steps taken]\nRESULT: [Measurable outcome + learning]',
        '📋 Evaluation Rubric:\n- Structure: 1-5\n- Clarity: 1-5\n- Relevance: 1-5\n- Examples: 1-5\n- Confidence: 1-5\nTarget: Total score 20+',
      ],
    },
  ].obs;

  List<Map<String, dynamic>> get filteredItems {
    final q = query.value.trim().toLowerCase();
    final cat = selectedCategory.value;

    return items.where((it) {
      final title = (it['title'] ?? '').toString().toLowerCase();
      final subtitle = (it['subtitle'] ?? '').toString().toLowerCase();
      final category = (it['category'] ?? '').toString();

      final matchesCat = cat == 'Semua' ? true : category == cat;
      final matchesQuery = q.isEmpty
          ? true
          : (title.contains(q) ||
                subtitle.contains(q) ||
                category.toLowerCase().contains(q));

      return matchesCat && matchesQuery;
    }).toList();
  }

  double get progress {
    if (items.isEmpty) return 0;
    return completedIds.length / items.length;
  }

  String get progressText {
    final percent = (progress * 100).toInt();
    return '$percent% selesai • ${completedIds.length} / ${items.length} materi';
  }

  void setQuery(String v) => query.value = v;

  void pickCategory(String c) => selectedCategory.value = c;

  Future<void> toggleComplete(String id, {Map<String, dynamic>? item}) async {
    final wasCompleted = completedIds.contains(id);

    if (wasCompleted) {
      completedIds.remove(id);
      update();
      return;
    }

    // ✅ tandai selesai dulu
    completedIds.add(id);
    update();

    // ✅ kasih poin + log aktivitas ke dashboard
    try {
      final dash = Get.find<DashboardController>();

      final title = (item?['title'] ?? '').toString();
      final level = (item?['level'] ?? '').toString();
      final minutes = (item?['minutes'] ?? 0) is int
          ? (item?['minutes'] ?? 0) as int
          : ((item?['minutes'] ?? 0) as num).toInt();

      final points = _materiPointsFromLevel(level, minutes: minutes);

      await dash.addPointsAndLog(
        title: title.isEmpty ? 'Materi Belajar' : 'Materi: $title',
        route: Routes.MATERI, // pastikan ada di app_pages.dart
        points: points,
      );
    } catch (_) {
      // kalau dash belum ter-registered atau user belum login, ya skip aja
    }
  }

  void toggleInProgress(String id) {
    if (inProgressIds.contains(id)) {
      inProgressIds.remove(id);
    } else {
      inProgressIds.add(id);
    }
    update();
  }

  Color getCategoryColor(String category) {
    return categoryColors[category] ?? Colors.grey;
  }

  Color getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'mudah':
        return Colors.greenAccent;
      case 'menengah':
        return Colors.amber;
      case 'sulit':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Color getActionColor(String type) {
    switch (type) {
      case 'practice':
        return Colors.blueAccent;
      case 'record':
        return Colors.purpleAccent;
      case 'write':
        return Colors.greenAccent;
      case 'research':
        return Colors.orangeAccent;
      case 'prepare':
        return Colors.tealAccent;
      case 'check':
        return Colors.cyanAccent;
      case 'create':
        return Colors.pinkAccent;
      case 'improve':
        return Colors.lightGreenAccent;
      case 'design':
        return Colors.deepPurpleAccent;
      case 'review':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData getActionIcon(String type) {
    switch (type) {
      case 'practice':
        return Icons.repeat;
      case 'record':
        return Icons.mic;
      case 'write':
        return Icons.edit;
      case 'research':
        return Icons.search;
      case 'prepare':
        return Icons.checklist;
      case 'check':
        return Icons.verified;
      case 'create':
        return Icons.add_circle;
      case 'improve':
        return Icons.trending_up;
      case 'design':
        return Icons.architecture;
      case 'review':
        return Icons.reviews;
      default:
        return Icons.task;
    }
  }

  int _materiPointsFromLevel(String level, {int minutes = 0}) {
    final lv = level.toLowerCase().trim();

    int base;
    if (lv.contains('mudah'))
      base = 5;
    else if (lv.contains('menengah'))
      base = 10;
    else if (lv.contains('sulit'))
      base = 15;
    else
      base = 8;

    // bonus kecil dari durasi (opsional)
    if (minutes >= 10) base += 2;
    if (minutes >= 15) base += 3;

    return base;
  }
}
