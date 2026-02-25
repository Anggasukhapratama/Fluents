import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/cv_models.dart';

class CvAiService {
  // ====== MODEL: PARSE PROFILE ======
  GenerativeModel _profileModel() {
    final schema = Schema.object(
      properties: {
        'fullName': Schema.string(),
        'headlineRole': Schema.string(),
        'dateOfBirth': Schema.string(),
        'email': Schema.string(),
        'phone': Schema.string(),
        'location': Schema.string(),
        'summary': Schema.string(),
        'skills': Schema.array(items: Schema.string()),
        'experiences': Schema.array(items: Schema.string()),
        'educations': Schema.array(items: Schema.string()),
        'projects': Schema.array(items: Schema.string()),
        'certificates': Schema.array(items: Schema.string()),
      },
      optionalProperties: const [
        'dateOfBirth',
        'email',
        'phone',
        'location',
        'experiences',
        'educations',
        'projects',
        'certificates',
      ],
    );

    return FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
        temperature: 0.2,
      ),
      systemInstruction: Content.text(
        'Kamu adalah parser CV. Ekstrak informasi yang benar-benar ada di CV. '
        'Jika tidak ada, isi "" atau [] dan jangan mengarang.',
      ),
    );
  }

  // ====== MODEL: ROLE RECOMMENDATION ======
  GenerativeModel _roleModel() {
    final schema = Schema.object(
      properties: {
        'suggestedRole': Schema.string(),
        'fitScore': Schema.integer(),
        'reasons': Schema.array(items: Schema.string(), maxItems: 6),
        'strengths': Schema.array(items: Schema.string(), maxItems: 6),
        'gaps': Schema.array(items: Schema.string(), maxItems: 6),
      },
      optionalProperties: const ['fitScore', 'reasons', 'strengths', 'gaps'],
    );

    return FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
        temperature: 0.35,
      ),
      systemInstruction: Content.text(
        'Kamu adalah career matcher. Tentukan pekerjaan paling cocok berdasarkan isi CV. '
        'Jangan mengarang pengalaman/skill yang tidak ada di CV. '
        'Berikan alasan yang mengacu ke data CV (skill, pengalaman, project, sertifikat).',
      ),
    );
  }

  // ====== MODEL: QUESTIONS ======
  GenerativeModel _questionsModel() {
    final schema = Schema.object(
      properties: {
        'questions': Schema.array(
          maxItems: 5,
          items: Schema.object(
            properties: {
              'q': Schema.string(),
              'focus': Schema.string(),
              'hint': Schema.string(),
            },
            optionalProperties: const ['hint'],
          ),
        ),
      },
    );

    return FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
        temperature: 0.6,
      ),
      systemInstruction: Content.text(
        'Kamu adalah interviewer. Buat 5 pertanyaan interview yang SPESIFIK berdasarkan CV dan role rekomendasi. '
        'Tidak boleh generik. Pertanyaan harus relevan dan bisa dijawab 1–2 menit.',
      ),
    );
  }

  // ====== MODEL: FEEDBACK ======
  GenerativeModel _feedbackModel() {
    final schema = Schema.object(
      properties: {
        'overall': Schema.string(),
        'strengths': Schema.array(items: Schema.string(), maxItems: 5),
        'improvements': Schema.array(items: Schema.string(), maxItems: 6),
      },
      optionalProperties: const ['strengths', 'improvements'],
    );

    return FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
        temperature: 0.35,
      ),
      systemInstruction: Content.text(
        'Kamu adalah coach interview. Nilai jawaban kandidat berdasarkan CV + role rekomendasi + praktik interview yang baik. '
        'Feedback ringkas, jelas, actionable.',
      ),
    );
  }

  Future<CvProfile> parseProfileFromCvText(String cvText) async {
    final model = _profileModel();
    final prompt =
        '''
Ekstrak CV_TEXT menjadi JSON sesuai schema.

RULES:
- Jangan mengarang.
- Kalau tidak ada info tertentu: "" atau [].
- experiences/educations/projects/certificates: bullet singkat.

CV_TEXT:
${_clip(cvText, 12000)}
''';

    final res = await model.generateContent([Content.text(prompt)]);
    final m = _safeJson(res.text ?? '');
    return m == null ? CvProfile.empty() : CvProfile.fromMap(m);
  }

  Future<CvRoleRecommendation> recommendRole({
    required CvProfile profile,
    required String cvText,
  }) async {
    final model = _roleModel();
    final prompt =
        '''
Tentukan 1 pekerjaan/role PALING cocok untuk kandidat ini, dan jelaskan kenapa.

RULES:
- Jangan mengarang. Semua alasan harus nyambung ke data yang ada (skills/experiences/projects/certificates/summary).
- suggestedRole harus spesifik (contoh: "Flutter Developer", "Data Analyst", "UI/UX Designer", dll).
- fitScore 0..100 (perkiraan kecocokan).
- reasons: 3-6 poin, gunakan bukti dari CV.
- strengths: 3-6 poin.
- gaps: 0-6 poin (kalau ada kekurangan).

PROFILE_JSON:
${jsonEncode(profile.toMap())}

CV_TEXT (ringkas):
${_clip(cvText, 8000)}
''';

    final res = await model.generateContent([Content.text(prompt)]);
    final m = _safeJson(res.text ?? '');
    return m == null
        ? CvRoleRecommendation.empty()
        : CvRoleRecommendation.fromMap(m);
  }

  Future<List<CvQuestion>> build5Questions({
    required CvProfile profile,
    required CvRoleRecommendation roleRec,
  }) async {
    final model = _questionsModel();
    final prompt =
        '''
Buat 5 pertanyaan interview paling relevan berdasarkan profil kandidat + role rekomendasi.
OUTPUT: JSON dengan key "questions" berisi 5 item.

ROLE_REKOMENDASI:
${jsonEncode(roleRec.toMap())}

KANDIDAT_JSON:
${jsonEncode(profile.toMap())}
''';

    final res = await model.generateContent([Content.text(prompt)]);
    final m = _safeJson(res.text ?? '');
    final raw = (m?['questions'] as List?) ?? const [];
    final out = raw
        .where((e) => e is Map)
        .map((e) => CvQuestion.fromMap(Map<String, dynamic>.from(e as Map)))
        .take(5)
        .toList();
    return out;
  }

  Future<CvPracticeSummary> gradePractice({
    required CvProfile profile,
    required CvRoleRecommendation roleRec,
    required List<CvPracticeTurn> turns,
  }) async {
    final model = _feedbackModel();
    final prompt =
        '''
Berikan feedback berdasarkan profil kandidat + role rekomendasi + tanya jawab berikut.
OUTPUT JSON sesuai schema.

ROLE_REKOMENDASI:
${jsonEncode(roleRec.toMap())}

PROFIL_JSON:
${jsonEncode(profile.toMap())}

TANYA_JAWAB:
${jsonEncode(turns.map((e) => e.toMap()).toList())}
''';

    final res = await model.generateContent([Content.text(prompt)]);
    final m = _safeJson(res.text ?? '');
    return m == null ? CvPracticeSummary.empty() : CvPracticeSummary.fromMap(m);
  }

  static String _clip(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);

  static Map<String, dynamic>? _safeJson(String raw) {
    try {
      final cleaned = raw
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final obj = jsonDecode(cleaned);
      if (obj is Map<String, dynamic>) return obj;
      if (obj is Map) return Map<String, dynamic>.from(obj);
      return null;
    } catch (_) {
      return null;
    }
  }
}
