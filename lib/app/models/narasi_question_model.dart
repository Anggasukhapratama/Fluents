// lib/app/models/narasi_question_model.dart

/// Model untuk menyimpan jawaban user + koreksi dari AI
class NarasiAnswerWithCorrection {
  final String question;
  final String userAnswer;
  final String aiCorrection; // Koreksi/saran dari AI
  final int? score; // Skor 1-10 (opsional)
  final int speakingSeconds;
  final int wordCount;
  final int wpm;
  final int fillerCount;

  const NarasiAnswerWithCorrection({
    required this.question,
    required this.userAnswer,
    required this.aiCorrection,
    this.score,
    required this.speakingSeconds,
    required this.wordCount,
    required this.wpm,
    required this.fillerCount,
  });

  factory NarasiAnswerWithCorrection.fromMap(Map<String, dynamic> m) =>
      NarasiAnswerWithCorrection(
        question: (m['question'] ?? '').toString(),
        userAnswer: (m['userAnswer'] ?? '').toString(),
        aiCorrection: (m['aiCorrection'] ?? '').toString(),
        score: m['score'] as int?,
        speakingSeconds: (m['speakingSeconds'] ?? 0) as int,
        wordCount: (m['wordCount'] ?? 0) as int,
        wpm: (m['wpm'] ?? 0) as int,
        fillerCount: (m['fillerCount'] ?? 0) as int,
      );

  Map<String, dynamic> toMap() => {
    'question': question,
    'userAnswer': userAnswer,
    'aiCorrection': aiCorrection,
    if (score != null) 'score': score,
    'speakingSeconds': speakingSeconds,
    'wordCount': wordCount,
    'wpm': wpm,
    'fillerCount': fillerCount,
  };
}

