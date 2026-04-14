class InterviewVideo {
  final String id;
  final String title;
  final String company;
  final String role;
  final String level;
  final int durationSec;
  final String thumbnailUrl;
  final String videoUrl;
  final List<String> tags;
  final int viewCount; // Tambahkan ini

  InterviewVideo({
    required this.id,
    required this.title,
    required this.company,
    required this.role,
    required this.level,
    required this.durationSec,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.tags,
    this.viewCount = 0, // Default 0
  });
}
