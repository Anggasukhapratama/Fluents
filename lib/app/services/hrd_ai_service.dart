import 'dart:async';
import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';

class HrdAiTurn {
  final String nextQuestion;
  final String feedback;
  final bool done;
  final int nextIndex;
  final int score; // 1..10 untuk ronde saat ini

  HrdAiTurn({
    required this.nextQuestion,
    required this.feedback,
    required this.done,
    required this.nextIndex,
    required this.score,
  });

  factory HrdAiTurn.fromJson(Map<String, dynamic> j) {
    int toInt(dynamic v, int fallback) {
      if (v is int) return v;
      return int.tryParse((v ?? '').toString()) ?? fallback;
    }

    return HrdAiTurn(
      nextQuestion: (j['nextQuestion'] ?? '').toString(),
      feedback: (j['feedback'] ?? '').toString(),
      done: (j['done'] ?? false) == true,
      nextIndex: toInt(j['nextIndex'], 1),
      score: toInt(j['score'], 7).clamp(1, 10),
    );
  }
}

class HrdSummary {
  final int totalScore; // 0..50
  final List<String> strengths;
  final List<String> improvements;
  final List<Map<String, String>> recommendedMaterials; // {title, reason}

  HrdSummary({
    required this.totalScore,
    required this.strengths,
    required this.improvements,
    required this.recommendedMaterials,
  });

  factory HrdSummary.fromJson(Map<String, dynamic> j) {
    int toInt(dynamic v, int fallback) {
      if (v is int) return v;
      return int.tryParse((v ?? '').toString()) ?? fallback;
    }

    List<String> toStrList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    List<Map<String, String>> toMatList(dynamic v) {
      if (v is! List) return [];
      return v.map((e) {
        if (e is Map) {
          return {
            'title': (e['title'] ?? '').toString(),
            'reason': (e['reason'] ?? '').toString(),
          };
        }
        return {'title': e.toString(), 'reason': ''};
      }).toList();
    }

    return HrdSummary(
      totalScore: toInt(j['totalScore'], 0),
      strengths: toStrList(j['strengths']),
      improvements: toStrList(j['improvements']),
      recommendedMaterials: toMatList(j['recommendedMaterials']),
    );
  }
}

class HrdAiService {
  // =========================
  // Robust JSON helpers
  // =========================

  String _short(String s, {int max = 240}) {
    final t = s.replaceAll('\n', ' ').trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max)}...';
  }

  /// Parser tahan banting:
  /// - buang ```json ``` fence
  /// - ambil JSON object pertama {...}
  /// - decode Map<String,dynamic>
  Map<String, dynamic> _safeParseJsonObject(String raw) {
    String s = raw.trim();

    // buang fence markdown
    s = s.replaceAll(RegExp(r'```(?:json)?', caseSensitive: false), '');
    s = s.replaceAll('```', '');
    s = s.trim();

    // ambil blok object pertama
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(s);
    if (match == null) {
      throw FormatException('Tidak menemukan JSON object. Raw: ${_short(raw)}');
    }

    final jsonStr = match.group(0)!.trim();
    final decoded = json.decode(jsonStr);

    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON bukan object. Raw: ${_short(raw)}');
    }
    return decoded;
  }

  /// STREAM helper: kumpulin chunk jadi satu string final
  Future<(Stream<String> stream, Future<String> finalText)> _streamText(
    Stream<GenerateContentResponse> respStream,
  ) async {
    final controller = StreamController<String>();
    final buffer = StringBuffer();
    final done = Completer<String>();

    () async {
      try {
        await for (final chunk in respStream) {
          final t = chunk.text;
          if (t != null && t.isNotEmpty) {
            buffer.write(t);
            controller.add(buffer.toString());
          }
        }
        done.complete(buffer.toString());
      } catch (e) {
        done.completeError(e);
      } finally {
        await controller.close();
      }
    }();

    return (controller.stream, done.future);
  }

  // =========================
  // Model builders
  // =========================

  GenerativeModel _buildTurnModel({required String jobTarget}) {
    final schema = Schema.object(
      properties: {
        'nextQuestion': Schema.string(),
        'feedback': Schema.string(),
        'score': Schema.integer(),
        'done': Schema.boolean(),
        'nextIndex': Schema.integer(),
      },
    );

    final systemInstruction = Content.text('''
Kamu adalah HRD profesional.
Wawancarai kandidat untuk posisi: "$jobTarget".

Aturan:
- Total 5 pertanyaan.
- Tiap ronde: 1 pertanyaan, lalu setelah jawaban user: beri feedback spesifik + skor 1-10.
- Feedback harus memuat: (1) Kelebihan (2) Kekurangan (3) Saran perbaikan + contoh kalimat lebih baik.
- Jangan beri lebih dari 1 pertanyaan per ronde.

Output wajib JSON valid sesuai schema (tanpa markdown).
{
  "nextQuestion": "string",
  "feedback": "string",
  "score": integer,
  "done": boolean,
  "nextIndex": integer
}
''');

    return FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: systemInstruction,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
        temperature: 0.6,
        maxOutputTokens: 900,
      ),
    );
  }

  GenerativeModel _buildSummaryModel({required String jobTarget}) {
    final schema = Schema.object(
      properties: {
        'totalScore': Schema.integer(),
        'strengths': Schema.array(items: Schema.string()),
        'improvements': Schema.array(items: Schema.string()),
        'recommendedMaterials': Schema.array(
          items: Schema.object(
            properties: {'title': Schema.string(), 'reason': Schema.string()},
          ),
        ),
      },
    );

    final systemInstruction = Content.text('''
Kamu adalah HRD profesional.
Buat ringkasan hasil interview untuk posisi "$jobTarget".
Berikan totalScore (0-50), strengths, improvements, dan recommendedMaterials (materi belajar) yang relevan.
Output wajib JSON sesuai schema.
Bahasa Indonesia.
''');

    return FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: systemInstruction,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
        temperature: 0.4,
        maxOutputTokens: 900,
      ),
    );
  }

  // =========================
  // Public API (STREAM)
  // =========================

  /// Start interview -> pertanyaan 1 (STREAM)
  /// ✅ FIX: safe JSON parse + retry 1x strict
  Future<(Stream<String> stream, Future<HrdAiTurn> result)> startStream({
    required String jobTarget,
  }) async {
    final model = _buildTurnModel(jobTarget: jobTarget);

    Stream<GenerateContentResponse> makeStream({required bool strict}) {
      return model.generateContentStream([
        Content.text(
          strict
              ? 'Mulai interview. Berikan pertanyaan ronde 1. BALAS HANYA JSON VALID (tanpa markdown, tanpa teks lain).'
              : 'Mulai interview. Berikan pertanyaan ronde 1. Pastikan output JSON.',
        ),
      ]);
    }

    final respStream = makeStream(strict: false);
    final (s, finalTextF) = await _streamText(respStream);

    final resultF = () async {
      final txt = await finalTextF;

      try {
        final jsonMap = _safeParseJsonObject(txt);
        return HrdAiTurn.fromJson(jsonMap);
      } catch (_) {
        // retry 1x strict
        final retryStream = makeStream(strict: true);
        final (_, retryFinalTextF) = await _streamText(retryStream);
        final retryTxt = await retryFinalTextF;

        final jsonMap = _safeParseJsonObject(retryTxt);
        return HrdAiTurn.fromJson(jsonMap);
      }
    }();

    return (s, resultF);
  }

  /// Next turn -> feedback ronde i + pertanyaan i+1 (STREAM)
  /// ✅ FIX: safe JSON parse + retry 1x strict (ini yg sering error di ronde 3)
  Future<(Stream<String> stream, Future<HrdAiTurn> result)> nextStream({
    required String jobTarget,
    required int currentIndex,
    required String lastQuestion,
    required String userAnswer,
  }) async {
    final model = _buildTurnModel(jobTarget: jobTarget);

    Stream<GenerateContentResponse> makeStream({required bool strict}) {
      final prompt =
          '''
Ronde saat ini: $currentIndex
Pertanyaan HRD: "$lastQuestion"
Jawaban kandidat: "$userAnswer"

Berikan:
- feedback untuk jawaban ronde ini
- score 1-10 untuk ronde ini
- jika currentIndex < 5: nextQuestion untuk ronde berikutnya + nextIndex=currentIndex+1
- jika currentIndex == 5: done=true, nextQuestion boleh kosong, nextIndex=5

${strict ? 'BALAS HANYA JSON VALID (tanpa markdown, tanpa teks lain).' : 'Output JSON sesuai schema.'}
''';

      return model.generateContentStream([Content.text(prompt)]);
    }

    final respStream = makeStream(strict: false);
    final (s, finalTextF) = await _streamText(respStream);

    final resultF = () async {
      final txt = await finalTextF;

      try {
        final jsonMap = _safeParseJsonObject(txt);
        return HrdAiTurn.fromJson(jsonMap);
      } catch (_) {
        // retry 1x strict
        final retryStream = makeStream(strict: true);
        final (_, retryFinalTextF) = await _streamText(retryStream);
        final retryTxt = await retryFinalTextF;

        final jsonMap = _safeParseJsonObject(retryTxt);
        return HrdAiTurn.fromJson(jsonMap);
      }
    }();

    return (s, resultF);
  }

  /// Summary akhir (non-stream cukup)
  /// ✅ FIX: safe parse juga (kadang ada fence/teks tambahan)
  Future<HrdSummary> buildSummary({
    required String jobTarget,
    required List<Map<String, dynamic>> transcript,
  }) async {
    final model = _buildSummaryModel(jobTarget: jobTarget);

    final res = await model.generateContent([
      Content.text('''
Berikut transcript interview (5 ronde):
${jsonEncode(transcript)}

Buat ringkasan hasil interview.
BALAS HANYA JSON VALID.
'''),
    ]);

    final txt = res.text ?? '{}';
    final jsonMap = _safeParseJsonObject(txt);
    return HrdSummary.fromJson(jsonMap);
  }
}
