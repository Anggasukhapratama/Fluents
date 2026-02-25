class InterviewVideo {
  final String id; // videoId
  final String title;
  final String company; // channel title
  final String role;
  final String level;
  final int durationSec;
  final String thumbnailUrl;
  final String videoUrl;
  final List<String> tags;

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
  });
}
