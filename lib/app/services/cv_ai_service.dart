// lib/app/services/cv_ai_service.dart
import 'dart:convert';
import '../models/cv_models.dart';
import 'groq_service.dart';

/// Service analisis CV menggunakan AI.
/// Menggunakan GroqService (model: llama-3.1-8b-instant) dengan
/// rotasi API Key otomatis di dalam GroqService.
class CvAiService {
  final GroqService _groqService = GroqService();

  // ====== PARSE PROFILE ======
  Future<CvProfile> parseProfileFromCvText(String cvText) async {
    final prompt = '''
Kamu adalah parser CV. Ekstrak CV_TEXT menjadi JSON.

RULES:
- Jangan mengarang.
- Kalau tidak ada info tertentu: "" atau [].
- experiences/educations/projects/certificates: bullet singkat.

Output HARUS JSON valid dengan format:
{
  "fullName": "string",
  "headlineRole": "string",
  "dateOfBirth": "string",
  "email": "string",
  "phone": "string",
  "location": "string",
  "summary": "string",
  "skills": ["string"],
  "experiences": ["string"],
  "educations": ["string"],
  "projects": ["string"],
  "certificates": ["string"]
}

CV_TEXT:
${_clip(cvText, 12000)}
''';

    final raw = await _groqService.generateText(
      prompt: prompt,
      temperature: 0.2,
      maxTokens: 2000,
      fallback: '{}',
    );

    final m = _safeJson(raw);
    return m == null ? CvProfile.empty() : CvProfile.fromMap(m);
  }

  // ====== ROLE RECOMMENDATION ======
  Future<CvRoleRecommendation> recommendRole({
    required CvProfile profile,
    required String cvText,
  }) async {
    final prompt = '''
Kamu adalah career matcher. Tentukan 1 pekerjaan/role PALING cocok untuk kandidat ini.

RULES:
- Jangan mengarang. Semua alasan harus mengacu ke data yang ada.
- suggestedRole harus spesifik (contoh: "Flutter Developer", "Data Analyst", "UI/UX Designer").
- fitScore 0..100.
- reasons: 3-6 poin, gunakan bukti dari CV.
- strengths: 3-6 poin.
- gaps: 0-6 poin (kalau ada kekurangan).

Output HARUS JSON valid:
{
  "suggestedRole": "string",
  "fitScore": integer,
  "reasons": ["string"],
  "strengths": ["string"],
  "gaps": ["string"]
}

PROFILE_JSON:
${jsonEncode(profile.toMap())}

CV_TEXT (ringkas):
${_clip(cvText, 8000)}
''';

    final raw = await _groqService.generateText(
      prompt: prompt,
      temperature: 0.35,
      maxTokens: 1500,
      fallback: '{}',
    );

    final m = _safeJson(raw);
    return m == null
        ? CvRoleRecommendation.empty()
        : CvRoleRecommendation.fromMap(m);
  }

  // ====== GENERATE 5 QUESTIONS ======
  Future<List<CvQuestion>> build5Questions({
    required CvProfile profile,
    required CvRoleRecommendation roleRec,
  }) async {
    final prompt = '''
Kamu adalah interviewer. Buat 5 pertanyaan interview yang SPESIFIK berdasarkan CV dan role rekomendasi.
Tidak boleh generik. Pertanyaan harus relevan dan bisa dijawab 1-2 menit.

Output HARUS JSON valid:
{
  "questions": [
    {"q": "string", "focus": "string", "hint": "string"},
    ...5 items total
  ]
}

ROLE_REKOMENDASI:
${jsonEncode(roleRec.toMap())}

KANDIDAT_JSON:
${jsonEncode(profile.toMap())}
''';

    final raw = await _groqService.generateText(
      prompt: prompt,
      temperature: 0.6,
      maxTokens: 1500,
      fallback: _buildFallbackQuestions(),
    );

    final m = _safeJson(raw);
    final rawList = (m?['questions'] as List?) ?? const [];
    final out = rawList
        .where((e) => e is Map)
        .map((e) => CvQuestion.fromMap(Map<String, dynamic>.from(e as Map)))
        .take(5)
        .toList();

    if (out.isEmpty) {
      // Parse fallback
      final fb = _safeJson(_buildFallbackQuestions());
      final fbList = (fb?['questions'] as List?) ?? const [];
      return fbList
          .where((e) => e is Map)
          .map((e) => CvQuestion.fromMap(Map<String, dynamic>.from(e as Map)))
          .take(5)
          .toList();
    }

    return out;
  }

  // ====== GRADE PRACTICE ======
  Future<CvPracticeSummary> gradePractice({
    required CvProfile profile,
    required CvRoleRecommendation roleRec,
    required List<CvPracticeTurn> turns,
  }) async {
    final prompt = '''
Kamu adalah coach interview. Nilai jawaban kandidat berdasarkan CV + role rekomendasi + tanya jawab berikut.
Feedback ringkas, jelas, actionable.

Output HARUS JSON valid:
{
  "overall": "string",
  "strengths": ["string"],
  "improvements": ["string"]
}

ROLE_REKOMENDASI:
${jsonEncode(roleRec.toMap())}

PROFIL_JSON:
${jsonEncode(profile.toMap())}

TANYA_JAWAB:
${jsonEncode(turns.map((e) => e.toMap()).toList())}
''';

    final raw = await _groqService.generateText(
      prompt: prompt,
      temperature: 0.35,
      maxTokens: 1000,
      fallback: _buildFallbackSummary(),
    );

    final m = _safeJson(raw);
    return m == null ? CvPracticeSummary.empty() : CvPracticeSummary.fromMap(m);
  }

  // ====== HELPERS ======
  static String _clip(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);

  static Map<String, dynamic>? _safeJson(String raw) {
    try {
      String cleaned = raw
          .replaceAll(RegExp(r'```(?:json)?', caseSensitive: false), '')
          .replaceAll('```', '')
          .trim();

      // Ambil blok { ... } pertama
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (match != null) cleaned = match.group(0)!;

      final obj = jsonDecode(cleaned);
      if (obj is Map<String, dynamic>) return obj;
      if (obj is Map) return Map<String, dynamic>.from(obj);
      return null;
    } catch (_) {
      return null;
    }
  }

  String _buildFallbackQuestions() {
    return jsonEncode({
      'questions': [
        {'q': 'Ceritakan tentang diri Anda dan latar belakang Anda.', 'focus': 'Profil Umum', 'hint': 'Jelaskan pendidikan dan pengalaman utama Anda.'},
        {'q': 'Apa pencapaian terbesar Anda dalam karir atau pendidikan?', 'focus': 'Pencapaian', 'hint': 'Gunakan metode STAR: Situasi, Tugas, Aksi, Hasil.'},
        {'q': 'Bagaimana cara Anda mengatasi tantangan dalam pekerjaan?', 'focus': 'Problem Solving', 'hint': 'Berikan contoh nyata dari pengalaman Anda.'},
        {'q': 'Apa yang membuat Anda tertarik dengan posisi ini?', 'focus': 'Motivasi', 'hint': 'Hubungkan dengan skill dan tujuan karir Anda.'},
        {'q': 'Di mana Anda melihat diri Anda dalam 5 tahun ke depan?', 'focus': 'Visi Karir', 'hint': 'Tunjukkan ambisi yang realistis dan relevan.'},
      ],
    });
  }

  String _buildFallbackSummary() {
    return jsonEncode({
      'overall': 'Jawaban Anda menunjukkan potensi yang baik. Coba berikan contoh lebih konkret dari pengalaman nyata Anda untuk memperkuat setiap jawaban.',
      'strengths': [
        'Komunikasi yang cukup jelas dan terstruktur',
        'Antusias dan termotivasi untuk berkembang',
      ],
      'improvements': [
        'Berikan contoh konkret menggunakan metode STAR',
        'Perjelas kontribusi spesifik Anda dalam setiap pengalaman',
        'Tingkatkan kepercayaan diri saat menyampaikan jawaban',
      ],
    });
  }
}
