import 'package:cloud_firestore/cloud_firestore.dart';

class CvProfile {
  final String fullName;
  final String headlineRole;
  final String dateOfBirth; // "" kalau tidak ada
  final String email;
  final String phone;
  final String location;

  final String summary;
  final List<String> skills;
  final List<String> experiences; // bullet singkat
  final List<String> educations; // bullet singkat
  final List<String> projects; // bullet singkat
  final List<String> certificates;

  const CvProfile({
    required this.fullName,
    required this.headlineRole,
    required this.dateOfBirth,
    required this.email,
    required this.phone,
    required this.location,
    required this.summary,
    required this.skills,
    required this.experiences,
    required this.educations,
    required this.projects,
    required this.certificates,
  });

  factory CvProfile.empty() => const CvProfile(
    fullName: '',
    headlineRole: '',
    dateOfBirth: '',
    email: '',
    phone: '',
    location: '',
    summary: '',
    skills: [],
    experiences: [],
    educations: [],
    projects: [],
    certificates: [],
  );

  factory CvProfile.fromMap(Map<String, dynamic> m) => CvProfile(
    fullName: (m['fullName'] ?? '').toString(),
    headlineRole: (m['headlineRole'] ?? '').toString(),
    dateOfBirth: (m['dateOfBirth'] ?? '').toString(),
    email: (m['email'] ?? '').toString(),
    phone: (m['phone'] ?? '').toString(),
    location: (m['location'] ?? '').toString(),
    summary: (m['summary'] ?? '').toString(),
    skills: ((m['skills'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    experiences: ((m['experiences'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    educations: ((m['educations'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    projects: ((m['projects'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    certificates: ((m['certificates'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
  );

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'headlineRole': headlineRole,
    'dateOfBirth': dateOfBirth,
    'email': email,
    'phone': phone,
    'location': location,
    'summary': summary,
    'skills': skills,
    'experiences': experiences,
    'educations': educations,
    'projects': projects,
    'certificates': certificates,
  };
}

class CvRoleRecommendation {
  final String suggestedRole;
  final int fitScore; // 0..100
  final List<String> reasons;
  final List<String> strengths;
  final List<String> gaps;
  final Map<String, double> breakdown; // tambahan

  const CvRoleRecommendation({
    required this.suggestedRole,
    required this.fitScore,
    required this.reasons,
    required this.strengths,
    required this.gaps,
    this.breakdown = const {},
  });

  factory CvRoleRecommendation.empty() => const CvRoleRecommendation(
    suggestedRole: '',
    fitScore: 0,
    reasons: [],
    strengths: [],
    gaps: [],
    breakdown: {},
  );

  factory CvRoleRecommendation.fromMap(Map<String, dynamic> m) {
    // parsing breakdown
    final breakdownRaw = (m['breakdown'] as Map?) ?? {};
    final breakdown = breakdownRaw.map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    );

    return CvRoleRecommendation(
      suggestedRole: (m['suggestedRole'] ?? '').toString(),
      fitScore: (m['fitScore'] ?? 0) is num
          ? (m['fitScore'] as num).toInt()
          : 0,
      reasons: ((m['reasons'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      strengths: ((m['strengths'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      gaps: ((m['gaps'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      breakdown: breakdown,
    );
  }

  Map<String, dynamic> toMap() => {
    'suggestedRole': suggestedRole,
    'fitScore': fitScore,
    'reasons': reasons,
    'strengths': strengths,
    'gaps': gaps,
    'breakdown': breakdown,
  };
}

class CvQuestion {
  final String q;
  final String focus;
  final String hint;

  CvQuestion({required this.q, required this.focus, required this.hint});

  factory CvQuestion.fromMap(Map<String, dynamic> m) => CvQuestion(
    q: (m['q'] ?? '').toString(),
    focus: (m['focus'] ?? '').toString(),
    hint: (m['hint'] ?? '').toString(),
  );

  Map<String, dynamic> toMap() => {'q': q, 'focus': focus, 'hint': hint};
}

class CvPracticeTurn {
  final int index;
  final String question;
  final String answer;

  CvPracticeTurn({
    required this.index,
    required this.question,
    required this.answer,
  });

  Map<String, dynamic> toMap() => {
    'index': index,
    'question': question,
    'answer': answer,
  };
}

class CvPracticeSummary {
  final String overall;
  final List<String> strengths;
  final List<String> improvements;

  CvPracticeSummary({
    required this.overall,
    required this.strengths,
    required this.improvements,
  });

  factory CvPracticeSummary.empty() => CvPracticeSummary(
    overall: '',
    strengths: const [],
    improvements: const [],
  );

  factory CvPracticeSummary.fromMap(Map<String, dynamic> m) =>
      CvPracticeSummary(
        overall: (m['overall'] ?? '').toString(),
        strengths: ((m['strengths'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        improvements: ((m['improvements'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

class CvAiResult {
  final String id;
  final String fileName;
  final String status; // processing | done | error
  final DateTime? createdAt;

  final int charCount;
  final CvProfile profile;
  final CvRoleRecommendation roleRec;
  final List<CvQuestion> questions;

  final String errorMessage;

  CvAiResult({
    required this.id,
    required this.fileName,
    required this.status,
    required this.createdAt,
    required this.charCount,
    required this.profile,
    required this.roleRec,
    required this.questions,
    required this.errorMessage,
  });

  factory CvAiResult.fromDoc(DocumentSnapshot doc) {
    final m = (doc.data() as Map<String, dynamic>?) ?? {};
    final ts = m['createdAt'];
    DateTime? dt;
    if (ts is Timestamp) dt = ts.toDate();

    final profileRaw = m['profile'];
    final profileMap = profileRaw is Map
        ? Map<String, dynamic>.from(profileRaw)
        : <String, dynamic>{};

    final roleRaw = m['roleRec'];
    final roleMap = roleRaw is Map
        ? Map<String, dynamic>.from(roleRaw)
        : <String, dynamic>{};

    final qsRaw = (m['questions'] as List?) ?? const [];
    final qs = qsRaw
        .where((e) => e is Map)
        .map((e) => CvQuestion.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return CvAiResult(
      id: doc.id,
      fileName: (m['fileName'] ?? 'CV.pdf').toString(),
      status: (m['status'] ?? 'processing').toString(),
      createdAt: dt,
      charCount: (m['charCount'] ?? 0) is num
          ? (m['charCount'] as num).toInt()
          : 0,
      profile: profileMap.isEmpty
          ? CvProfile.empty()
          : CvProfile.fromMap(profileMap),
      roleRec: roleMap.isEmpty
          ? CvRoleRecommendation.empty()
          : CvRoleRecommendation.fromMap(roleMap),
      questions: qs,
      errorMessage: (m['errorMessage'] ?? '').toString(),
    );
  }
}
