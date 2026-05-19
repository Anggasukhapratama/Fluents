// lib/app/models/narasi_question_model.dart

/// Model untuk menyimpan pertanyaan wawancara dari AI
class NarasiQuestion {
  final String question;
  final int index;

  const NarasiQuestion({required this.question, required this.index});

  factory NarasiQuestion.fromMap(Map<String, dynamic> m, int idx) =>
      NarasiQuestion(question: (m['question'] ?? '').toString(), index: idx);

  Map<String, dynamic> toMap() => {'question': question, 'index': index};
}

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

/// Model untuk menyimpan seluruh sesi dengan koreksi AI
class NarasiSessionWithCorrections {
  final String jobTarget;
  final String level; // medium, hard, advance
  final DateTime createdAt;
  final List<NarasiQuestion> questions;
  final List<NarasiAnswerWithCorrection> answersWithCorrections;

  const NarasiSessionWithCorrections({
    required this.jobTarget,
    required this.level,
    required this.createdAt,
    required this.questions,
    required this.answersWithCorrections,
  });
}
