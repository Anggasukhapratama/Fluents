// lib/app/services/ai_question_service.dart

import 'dart:async';
import 'groq_service.dart';

/// Service untuk generate pertanyaan wawancara menggunakan AI.
/// Menggunakan GroqService (model: llama-3.1-8b-instant) dengan
/// rotasi API Key otomatis di dalam GroqService.
class AiQuestionService {
  final GroqService _groqService = GroqService();

  /// Generate pertanyaan berdasarkan job target dan level
  Future<List<String>> generateQuestions({
    required String jobTarget,
    required String level,
    required int questionCount,
  }) async {
    final levelDesc = _getLevelDescription(level);
    final prompt = '''
Anda adalah HRD profesional yang sedang mewawancarai kandidat untuk posisi: "$jobTarget".

LEVEL WAWANCARA: $levelDesc

PENTING: Buatkan TEPAT $questionCount pertanyaan wawancara (tidak lebih, tidak kurang).
Pertanyaan harus relevan dengan posisi "$jobTarget".

Aturan KETAT:
- Buat TEPAT $questionCount pertanyaan saja
- Setiap pertanyaan dalam satu baris terpisah
- Jangan pakai nomor di awal pertanyaan
- Jangan ada teks tambahan selain pertanyaan
- Bahasa Indonesia yang baik dan benar
- Jangan gunakan format markdown seperti *, -, #, **, ##

Contoh format output untuk $questionCount pertanyaan:
Apa yang membuat Anda tertarik dengan posisi $jobTarget?
Ceritakan tentang pengalaman Anda yang paling relevan dengan bidang ini.
Bagaimana cara Anda mengatasi tantangan dalam pekerjaan?
''';

    try {
      final text = await _groqService.generateText(
        prompt: prompt,
        temperature: 0.7,
        maxTokens: 800,
        fallback: '',
      );

      if (text.isEmpty) {
        print('⚠️ AI response kosong, gunakan fallback');
        return _getFallbackQuestions(jobTarget, questionCount);
      }

      // Parse pertanyaan dengan validasi ketat
      final questions = _parseQuestionsStrict(text, questionCount);
      
      if (questions.length != questionCount) {
        print('⚠️ AI menghasilkan ${questions.length} pertanyaan, diharapkan $questionCount. Gunakan fallback.');
        return _getFallbackQuestions(jobTarget, questionCount);
      }

      print('✅ Berhasil generate $questionCount pertanyaan dari AI');
      return questions;
    } catch (e) {
      print('❌ Error generate questions: $e');
      return _getFallbackQuestions(jobTarget, questionCount);
    }
  }

  /// Parse pertanyaan dengan validasi ketat
  List<String> _parseQuestionsStrict(String text, int expectedCount) {
    final lines = text.split('\n');
    final questions = <String>[];

    for (var line in lines) {
      line = line.trim();
      
      // Skip baris kosong
      if (line.isEmpty) continue;
      
      // Hapus nomor di awal (contoh: "1. " atau "1) ")
      line = line.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '');
      
      // Skip baris yang bukan pertanyaan
      if (line.isEmpty ||
          line.toLowerCase().contains('berikut') ||
          line.toLowerCase().contains('pertanyaan') ||
          line.toLowerCase().contains('contoh') ||
          line.toLowerCase().contains('format') ||
          line.length < 10) { // Pertanyaan terlalu pendek
        continue;
      }
      
      // Pastikan diakhiri dengan tanda tanya
      if (!line.endsWith('?')) {
        line = '$line?';
      }
      
      questions.add(line);
      
      // Stop jika sudah mencapai jumlah yang diinginkan
      if (questions.length >= expectedCount) {
        break;
      }
    }

    return questions;
  }

  /// Koreksi jawaban user per pertanyaan
  Future<String> correctAnswer({
    required String question,
    required String userAnswer,
    required String jobTarget,
  }) async {
    final prompt = '''
Anda HRD untuk posisi "$jobTarget". Nilai jawaban kandidat secara singkat.

PERTANYAAN: $question
JAWABAN: ${userAnswer.isEmpty ? '(tidak menjawab)' : userAnswer}

Tulis 2-3 kalimat singkat saja yang berisi:
- Apakah jawaban relevan/masuk akal dengan pertanyaan
- Saran perbaikan yang konkret

Contoh gaya: "Jawaban kurang nyambung dengan pertanyaan. Sebaiknya jelaskan pengalaman konkret yang relevan. Tambahkan contoh nyata agar lebih meyakinkan."

ATURAN:
- Maksimal 3 kalimat, langsung ke inti
- Bahasa Indonesia, tanpa markdown (* - # **)
- Jika tidak menjawab, sebutkan dan minta tetap mencoba menjawab
''';

    try {
      final correction = await _groqService.generateText(
        prompt: prompt,
        temperature: 0.5,
        maxTokens: 150,
        fallback: '',
      );

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
      await Future.delayed(const Duration(milliseconds: 800));
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
      return 'Anda belum menjawab pertanyaan ini. Cobalah tetap menjawab walau singkat, lalu kembangkan dengan contoh pengalaman yang relevan.';
    }
    return 'Jawaban Anda sudah cukup, namun masih kurang spesifik. Tambahkan contoh konkret dari pengalaman Anda. Gunakan metode STAR (Situasi, Tugas, Aksi, Hasil) agar lebih terstruktur.';
  }
}
