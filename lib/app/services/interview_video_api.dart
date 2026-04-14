import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/interview_video.dart';

class InterviewVideoApi {
  final String baseUrl;
  final String apiKey;

  InterviewVideoApi({required this.baseUrl, required this.apiKey});

  Future<List<InterviewVideo>> fetchVideos({
    String? role,
    String? query,
    String sortOrder = 'relevance', // Tambahkan parameter order
  }) async {
    final parts = <String>[];
    if (query != null && query.trim().isNotEmpty) parts.add(query.trim());
    if (role != null && role.trim().isNotEmpty) parts.add(role.trim());
    final q = parts.isEmpty ? 'video wawancara kerja' : parts.join(' ');

    // 1) SEARCH
    final searchUri = Uri.parse('$baseUrl/search').replace(
      queryParameters: {
        'part': 'snippet',
        'type': 'video',
        'maxResults': '15', // Bisa disesuaikan jumlahnya
        'q': q,
        'order': sortOrder,

        // --- TAMBAHKAN 2 BARIS INI ---
        'regionCode': 'ID', // Membatasi pencarian hanya untuk region Indonesia
        'relevanceLanguage':
            'id', // Memprioritaskan video dengan bahasa Indonesia

        // -----------------------------
        'key': apiKey,
      },
    );

    final searchRes = await http.get(searchUri);
    if (searchRes.statusCode != 200) throw Exception('Search Error');

    final searchJson = jsonDecode(searchRes.body);
    final searchItems = (searchJson['items'] as List?) ?? [];

    final candidates = <_Candidate>[];
    for (final it in searchItems) {
      final videoId = it['id']['videoId'] ?? '';
      if (videoId == '') continue;
      candidates.add(
        _Candidate(
          videoId: videoId,
          title: it['snippet']['title'],
          channelTitle: it['snippet']['channelTitle'],
          thumbUrl: it['snippet']['thumbnails']['medium']['url'],
        ),
      );
    }

    if (candidates.isEmpty) return [];

    // 2) GET DETAILS (Status, Duration, and Statistics for ViewCount)
    final detailMap = await _fetchVideoDetails(
      candidates.map((e) => e.videoId).toList(),
    );

    final out = <InterviewVideo>[];
    for (final c in candidates) {
      final info = detailMap[c.videoId];
      if (info == null || !info.embeddable) continue;

      out.add(
        InterviewVideo(
          id: c.videoId,
          title: c.title,
          company: c.channelTitle,
          role: role ?? 'Interview',
          level: 'General',
          durationSec: info.durationSec,
          thumbnailUrl: c.thumbUrl,
          videoUrl: 'https://www.youtube.com/watch?v=${c.videoId}',
          viewCount: info.viewCount, // Sekarang sudah ada datanya
          tags: ['YouTube', role ?? 'Interview'],
        ),
      );
    }
    return out;
  }

  Future<Map<String, _VideoInfo>> _fetchVideoDetails(List<String> ids) async {
    // Tambahkan 'statistics' untuk mendapatkan viewCount
    final uri = Uri.parse('$baseUrl/videos').replace(
      queryParameters: {
        'part': 'status,contentDetails,statistics',
        'id': ids.join(','),
        'key': apiKey,
      },
    );

    final res = await http.get(uri);
    final decoded = jsonDecode(res.body);
    final items = (decoded['items'] as List?) ?? [];

    final map = <String, _VideoInfo>{};
    for (final it in items) {
      final id = it['id'];
      final durationIso = it['contentDetails']['duration'];
      final views = int.tryParse(it['statistics']['viewCount'] ?? '0') ?? 0;

      map[id] = _VideoInfo(
        embeddable: it['status']['embeddable'] ?? false,
        durationSec: _parseDuration(durationIso),
        viewCount: views,
      );
    }
    return map;
  }

  int _parseDuration(String iso) {
    if (!iso.startsWith('PT')) return 0;
    final h = RegExp(r'(\d+)H').firstMatch(iso);
    final m = RegExp(r'(\d+)M').firstMatch(iso);
    final s = RegExp(r'(\d+)S').firstMatch(iso);
    int total = 0;
    if (h != null) total += int.parse(h.group(1)!) * 3600;
    if (m != null) total += int.parse(m.group(1)!) * 60;
    if (s != null) total += int.parse(s.group(1)!);
    return total;
  }
}

class _Candidate {
  final String videoId, title, channelTitle, thumbUrl;
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
  final int viewCount; // Tambahkan ini
  _VideoInfo({
    required this.embeddable,
    required this.durationSec,
    required this.viewCount,
  });
}
