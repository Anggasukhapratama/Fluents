import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/interview_video.dart';

class InterviewVideoApi {
  final String baseUrl; // pakai: https://www.googleapis.com/youtube/v3
  final String apiKey;

  InterviewVideoApi({required this.baseUrl, required this.apiKey});

  /// Ambil video dari YouTube:
  /// 1) search.list => dapat videoId + snippet
  /// 2) videos.list(part=status,contentDetails) => filter embeddable + ambil durasi
  Future<List<InterviewVideo>> fetchVideos({
    String? role,
    String? level,
    String? query,
  }) async {
    // Keyword gabungan
    final parts = <String>[];
    if (query != null && query.trim().isNotEmpty) parts.add(query.trim());
    if (role != null && role.trim().isNotEmpty) parts.add(role.trim());
    if (level != null && level.trim().isNotEmpty) parts.add('$level interview');
    final q = parts.isEmpty ? 'video wawancara kerja' : parts.join(' ');

    // 1) SEARCH
    final searchUri = Uri.parse('$baseUrl/search').replace(
      queryParameters: {
        'part': 'snippet',
        'type': 'video',
        'maxResults': '15',
        'q': q,
        'safeSearch': 'moderate',
        'order': 'relevance',
        'key': apiKey,
      },
    );

    final searchRes = await http.get(searchUri);
    if (searchRes.statusCode != 200) {
      throw Exception(
        'YouTube search error ${searchRes.statusCode}: ${searchRes.body}',
      );
    }

    final searchJson = jsonDecode(searchRes.body) as Map<String, dynamic>;
    final searchItems = (searchJson['items'] as List?) ?? [];

    // kumpulin kandidat video
    final candidates = <_Candidate>[];
    for (final it in searchItems) {
      final m = (it as Map).cast<String, dynamic>();
      final id = (m['id'] as Map?)?.cast<String, dynamic>();
      final snippet = (m['snippet'] as Map?)?.cast<String, dynamic>();
      final videoId = (id?['videoId'] ?? '').toString();
      if (videoId.isEmpty) continue;

      final title = (snippet?['title'] ?? 'Video').toString();
      final channelTitle = (snippet?['channelTitle'] ?? 'YouTube').toString();

      final thumbs = (snippet?['thumbnails'] as Map?)?.cast<String, dynamic>();
      final medium = (thumbs?['medium'] as Map?)?.cast<String, dynamic>();
      final thumbUrl = (medium?['url'] ?? '').toString();

      candidates.add(
        _Candidate(
          videoId: videoId,
          title: title,
          channelTitle: channelTitle,
          thumbUrl: thumbUrl,
        ),
      );
    }

    if (candidates.isEmpty) return [];

    // 2) DETAILS: status.embeddable + contentDetails.duration
    final detailMap = await _fetchVideoStatusAndDuration(
      candidates.map((e) => e.videoId).toList(),
    );

    // Build final list (skip not embeddable)
    final out = <InterviewVideo>[];
    for (final c in candidates) {
      final info = detailMap[c.videoId];
      if (info == null) continue;

      // filter embeddable
      if (!info.embeddable) continue;

      out.add(
        InterviewVideo(
          id: c.videoId,
          title: c.title,
          company: c.channelTitle,
          role: role ?? 'Interview',
          level: level ?? 'General',
          durationSec: info.durationSec,
          thumbnailUrl: c.thumbUrl,
          videoUrl: 'https://www.youtube.com/watch?v=${c.videoId}',
          tags: [
            'YouTube',
            'Interview',
            if (role != null && role.isNotEmpty) role,
            if (level != null && level.isNotEmpty) level,
          ],
        ),
      );
    }

    return out;
  }

  /// Rekomendasi chip (lokal)
  Future<List<String>> fetchRecommendedRoles({required String job}) async {
    final map = <String, List<String>>{
      'Frontend': ['Frontend', 'React', 'Flutter', 'UI/UX', 'Web'],
      'Backend': ['Backend', 'API', 'Node.js', 'Laravel', 'Golang'],
      'HR': ['HR', 'Recruitment', 'Interview HR', 'People Ops'],
      'Akuntansi': ['Akuntansi', 'Finance', 'Auditor', 'Tax'],
      'Marketing': ['Marketing', 'Digital Marketing', 'Content', 'Branding'],
    };
    return map[job] ?? ['Frontend', 'Backend', 'HR', 'Akuntansi'];
  }

  Future<Map<String, _VideoInfo>> _fetchVideoStatusAndDuration(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return {};

    // YouTube batas id per request biasanya aman <= 50
    final uri = Uri.parse('$baseUrl/videos').replace(
      queryParameters: {
        'part': 'status,contentDetails',
        'id': ids.take(50).join(','),
        'key': apiKey,
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      // kalau error, jangan bikin crash total, tapi lempar biar terlihat
      throw Exception(
        'YouTube videos.list error ${res.statusCode}: ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (decoded['items'] as List?) ?? [];

    final map = <String, _VideoInfo>{};
    for (final it in items) {
      final m = (it as Map).cast<String, dynamic>();
      final id = (m['id'] ?? '').toString();
      if (id.isEmpty) continue;

      final status = (m['status'] as Map?)?.cast<String, dynamic>();
      final content = (m['contentDetails'] as Map?)?.cast<String, dynamic>();

      final embeddable = status?['embeddable'] == true;
      final durationIso = (content?['duration'] ?? '').toString();

      map[id] = _VideoInfo(
        embeddable: embeddable,
        durationSec: _parseIso8601DurationToSeconds(durationIso),
      );
    }

    return map;
  }

  int _parseIso8601DurationToSeconds(String iso) {
    // contoh: PT1H2M3S, PT15M, PT45S
    if (iso.isEmpty || !iso.startsWith('PT')) return 0;

    int hours = 0, minutes = 0, seconds = 0;

    final h = RegExp(r'(\d+)H').firstMatch(iso);
    final m = RegExp(r'(\d+)M').firstMatch(iso);
    final s = RegExp(r'(\d+)S').firstMatch(iso);

    if (h != null) hours = int.tryParse(h.group(1) ?? '0') ?? 0;
    if (m != null) minutes = int.tryParse(m.group(1) ?? '0') ?? 0;
    if (s != null) seconds = int.tryParse(s.group(1) ?? '0') ?? 0;

    return hours * 3600 + minutes * 60 + seconds;
  }
}

class _Candidate {
  final String videoId;
  final String title;
  final String channelTitle;
  final String thumbUrl;

  _Candidate({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.thumbUrl,
  });
}

class _VideoInfo {
  final bool embeddable;
  final int durationSec;

  _VideoInfo({required this.embeddable, required this.durationSec});
}
