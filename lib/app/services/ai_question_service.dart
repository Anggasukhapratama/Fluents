// lib/app/services/ai_question_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';

/// Service untuk generate pertanyaan wawancara menggunakan AI Gemini
class AiQuestionService {
  static const String _modelName = 'gemini-2.5-flash-lite';

  /// Generate pertanyaan berdasarkan job target dan level
  /// @param jobTarget: jenis pekerjaan (contoh: "Frontend Developer")
  /// @param level: 'medium', 'hard', 'advance'
  /// @param questionCount: jumlah pertanyaan (5 untuk medium, 6 untuk hard/advance)
  /// @return List<String> daftar pertanyaan
  Future<List<String>> generateQuestions({
    required String jobTarget,
    required String level,
    required int questionCount,
  }) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: _modelName,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 800,
        ),
      );

      final levelDesc = _getLevelDescription(level);
      final prompt =
          '''
Anda adalah HRD profesional yang sedang mewawancarai kandidat untuk posisi: "$jobTarget".

LEVEL WAWANCARA: $levelDesc

Buatkan $questionCount pertanyaan wawancara yang sesuai dengan level ini.
Pertanyaan harus relevan dengan posisi "$jobTarget".

Aturan:
- Setiap pertanyaan dalam satu baris
- Jangan pakai nomor di awal pertanyaan
- Jangan ada teks tambahan selain pertanyaan
- Bahasa Indonesia yang baik dan benar

Contoh format output:
Apa yang membuat Anda tertarik dengan posisi $jobTarget?
Ceritakan tentang pengalaman Anda yang paling relevan dengan bidang ini.
Bagaimana cara Anda mengatasi tantangan dalam pekerjaan?
''';

      final response = await model.generateContent([Content.text(prompt)]);

      final text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        return _getFallbackQuestions(jobTarget, questionCount);
      }

      // Parse pertanyaan (satu per baris)
      final lines = text.split('\n');
      final questions = <String>[];

      for (var line in lines) {
        line = line.trim();
        // Hapus nomor di awal (contoh: "1. " atau "1) ")
        line = line.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '');
        if (line.isNotEmpty &&
            !line.contains('Berikut') &&
            !line.contains('pertanyaan')) {
          questions.add(line);
        }
      }

      // Batasi sesuai jumlah yang diminta
      if (questions.length > questionCount) {
        return questions.take(questionCount).toList();
      }

      if (questions.isEmpty) {
        return _getFallbackQuestions(jobTarget, questionCount);
      }

      return questions;
    } catch (e) {
      print('❌ Error generate questions: $e');
      return _getFallbackQuestions(jobTarget, questionCount);
    }
  }

  /// Koreksi jawaban user per pertanyaan
  /// @param question: pertanyaan dari AI
  /// @param userAnswer: jawaban user (hasil speech-to-text)
  /// @param jobTarget: jenis pekerjaan
  /// @return String koreksi/saran perbaikan
  Future<String> correctAnswer({
    required String question,
    required String userAnswer,
    required String jobTarget,
  }) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: _modelName,
        generationConfig: GenerationConfig(
          temperature: 0.6,
          maxOutputTokens: 300,
        ),
      );

      final prompt =
          '''
Anda adalah HRD profesional yang memberikan feedback untuk wawancara posisi "$jobTarget".

PERTANYAAN: $question

JAWABAN KANDIDAT: ${userAnswer.isEmpty ? '(tidak menjawab)' : userAnswer}

Beri feedback singkat (maksimal 50 kata) yang mencakup:
1. Kelebihan dari jawaban (jika ada)
2. Kekurangan/saran perbaikan
3. Contoh kalimat jawaban yang lebih baik

Format jawaban langsung tanpa salam pembuka/penutup.
''';

      final response = await model.generateContent([Content.text(prompt)]);

      String correction = response.text?.trim() ?? '';
      if (correction.isEmpty) {
        return _getFallbackCorrection(userAnswer);
      }

      return correction;
    } catch (e) {
      print('❌ Error correct answer: $e');
      return _getFallbackCorrection(userAnswer);
    }
  }

  /// Generate semua koreksi untuk seluruh sesi (batch)
  Future<List<String>> batchCorrectAnswers({
    required List<String> questions,
    required List<String> userAnswers,
    required String jobTarget,
  }) async {
    final corrections = <String>[];

    for (int i = 0; i < questions.length; i++) {
      final correction = await correctAnswer(
        question: questions[i],
        userAnswer: userAnswers[i],
        jobTarget: jobTarget,
      );
      corrections.add(correction);

      // Beri jeda agar tidak kena rate limit
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return corrections;
  }

  String _getLevelDescription(String level) {
    switch (level) {
      case 'medium':
        return 'Pemula - Pertanyaan dasar tentang motivasi, pendidikan, dan keahlian dasar';
      case 'hard':
        return 'Menengah - Pertanyaan tentang pengalaman kerja, tantangan, dan problem solving';
      case 'advance':
        return 'Lanjutan - Pertanyaan strategis, leadership, dan studi kasus kompleks';
      default:
        return 'Pemula';
    }
  }

  List<String> _getFallbackQuestions(String jobTarget, int count) {
    final fallbacks = [
      'Ceritakan tentang diri Anda secara singkat.',
      'Apa yang membuat Anda tertarik dengan posisi $jobTarget?',
      'Apa keahlian utama Anda yang relevan dengan posisi ini?',
      'Bagaimana cara Anda mengatasi tekanan dalam pekerjaan?',
      'Apa pencapaian terbesar Anda sejauh ini?',
      'Di mana Anda melihat diri Anda dalam 5 tahun ke depan?',
      'Mengapa kami harus memilih Anda dibandingkan kandidat lain?',
    ];

    return fallbacks.take(count).toList();
  }

  String _getFallbackCorrection(String userAnswer) {
    if (userAnswer.isEmpty) {
      return '⚠️ Sebaiknya jawab pertanyaan dengan jelas dan spesifik. Latihan menjawab akan membantu Anda lebih percaya diri.';
    }
    return '✅ Jawaban Anda sudah cukup baik. Untuk meningkatkan, coba berikan contoh konkret dan gunakan metode STAR (Situasi, Tugas, Aksi, Hasil).';
  }
}
