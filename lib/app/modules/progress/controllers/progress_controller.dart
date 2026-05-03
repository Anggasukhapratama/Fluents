// lib/app/controllers/progress_controller.dart
import 'dart:async';
import 'package:fluent_ai/app/services/practice_firestore_service.dart';
import 'package:get/get.dart';

enum ChartMetric { count, avgScore }

class Agg {
  final String key;
  final int count;
  final double avgScore;
  Agg({required this.key, required this.count, required this.avgScore});
}

// Model untuk data statistik per kategori
class CategoryStats {
  final String label; // Deskripsi level (Fokus & Percaya Diri, dll)
  final int count; // Jumlah pelanggaran atau frekuensi
  final double score; // Skor 0-100
  final String suggestion; // Saran perbaikan singkat

  CategoryStats({
    required this.label,
    required this.count,
    required this.score,
    required this.suggestion,
  });
}

class ProgressController extends GetxController {
  final PracticeFirestoreService narasiFs = PracticeFirestoreService();

  final isLoading = true.obs;
  final errorText = ''.obs;

  final daysRange = 14.obs;

  final chartMetric = ChartMetric.count.obs;
  void setMetric(ChartMetric m) => chartMetric.value = m;

  final RxList<Agg> daily = <Agg>[].obs;
  final RxList<Agg> weekly = <Agg>[].obs;
  final RxList<Agg> monthly = <Agg>[].obs;

  final lastDoc = Rxn<Map<String, dynamic>>();

  StreamSubscription? _subDaily;
  StreamSubscription? _subLast;

  // Statistik ringkasan
  final totalSessions = 0.obs;
  final avgOverallScore = 0.0.obs;
  final bestScore = 0.obs;
  final consistentStreak = 0.obs;

  // Statistik per kategori (dari data terbaru)
  final latestEyeLabel = ''.obs;
  final latestEyeScore = 0.obs;
  final latestEyeCount = 0.obs;
  final latestSmileLabel = ''.obs;
  final latestSmileScore = 0.obs;
  final latestSmileCount = 0.obs;
  final latestPostureLabel = ''.obs;
  final latestPostureScore = 0.obs;
  final latestPostureCount = 0.obs;
  final latestOverallLabel = ''.obs;
  final latestOverallScore = 0.obs;

  // Rekomendasi terbaru
  final latestSuggestions = <String>[].obs;
  final latestAiRecommendation = ''.obs;

  @override
  void onInit() {
    super.onInit();
    listenAll(daysBack: daysRange.value);
    listenLastCorrection();
  }

  @override
  void onClose() {
    _subDaily?.cancel();
    _subLast?.cancel();
    super.onClose();
  }

  void setDaysRange(int v) {
    daysRange.value = v;
    listenAll(daysBack: v);
  }

  String _dateKey(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String _monthKey(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    return '${d.year}-$mm';
  }

  String _weekKey(DateTime d) {
    final monday = d.subtract(Duration(days: (d.weekday - DateTime.monday)));
    final year = monday.year;
    final firstMonday = _firstMondayOfYear(year);
    final diffDays = monday.difference(firstMonday).inDays;
    final weekNum = (diffDays ~/ 7) + 1;
    return '$year-W${weekNum.toString().padLeft(2, '0')}';
  }

  DateTime _firstMondayOfYear(int year) {
    final jan1 = DateTime(year, 1, 1);
    final shift = (DateTime.monday - jan1.weekday) % 7;
    return jan1.add(Duration(days: shift));
  }

  DateTime? _parseDateKey(String dk) {
    final parts = dk.split('-');
    if (parts.length != 3) return null;
    final yy = int.tryParse(parts[0]);
    final mm = int.tryParse(parts[1]);
    final dd = int.tryParse(parts[2]);
    if (yy == null || mm == null || dd == null) return null;
    return DateTime(yy, mm, dd);
  }

  // Ekstrak skor keseluruhan (0-100)
  double _extractOverallScore(Map<String, dynamic> m) {
    // overallConfidence adalah nilai 0-100 dari detection_result
    return ((m['overallConfidence'] ?? 0) as num).toDouble();
  }

  // Ekstrak data per kategori
  CategoryStats _extractEyeStats(Map<String, dynamic> m) {
    final label = m['eyeLabel'] ?? 'Belum teranalisis';
    final count = (m['eyeCount'] ?? 0) as num;
    final score = (m['eyeScore'] ?? 0) as num;
    final suggestion =
        m['eyeSuggestion'] ?? 'Fokus pada kamera saat berbicara.';
    return CategoryStats(
      label: label.toString(),
      count: count.toInt(),
      score: score.toDouble(),
      suggestion: suggestion.toString(),
    );
  }

  CategoryStats _extractSmileStats(Map<String, dynamic> m) {
    final label = m['smileLabel'] ?? 'Belum teranalisis';
    final count = (m['smileCount'] ?? 0) as num;
    final score = (m['smileScore'] ?? 0) as num;
    final suggestion =
        m['smileSuggestion'] ?? 'Tersenyumlah di awal dan akhir jawaban.';
    return CategoryStats(
      label: label.toString(),
      count: count.toInt(),
      score: score.toDouble(),
      suggestion: suggestion.toString(),
    );
  }

  CategoryStats _extractPostureStats(Map<String, dynamic> m) {
    final label = m['postureLabel'] ?? 'Belum teranalisis';
    final count = (m['postureCount'] ?? 0) as num;
    final score = (m['postureScore'] ?? 0) as num;
    final suggestion = m['postureSuggestion'] ?? 'Duduk tegak dan rileks.';
    return CategoryStats(
      label: label.toString(),
      count: count.toInt(),
      score: score.toDouble(),
      suggestion: suggestion.toString(),
    );
  }

  void listenAll({required int daysBack}) {
    _subDaily?.cancel();
    isLoading.value = true;
    errorText.value = '';

    final now = DateTime.now();
    final start = now.subtract(Duration(days: daysBack - 1));

    final startKey = _dateKey(start);
    final endKey = _dateKey(now);

    final stream = narasiFs.streamSessionsByDateKeyRange(
      startDateKey: startKey,
      endDateKey: endKey,
    );

    _subDaily = stream.listen(
      (snap) {
        final Map<String, int> dayCount = {};
        final Map<String, double> dayScoreSum = {};

        final Map<String, int> weekCount = {};
        final Map<String, double> weekScoreSum = {};

        final Map<String, int> monthCount = {};
        final Map<String, double> monthScoreSum = {};

        // Untuk statistik ringkasan
        int totalSessionCount = 0;
        double totalScoreSum = 0.0;
        int highestScore = 0;

        for (final doc in snap.docs) {
          final m = doc.data();
          final dk = (m['dateKey'] ?? '') as String;
          final mk = (m['monthKey'] ?? '') as String;
          final score = _extractOverallScore(m);

          totalSessionCount++;
          totalScoreSum += score;
          if (score.round() > highestScore) highestScore = score.round();

          if (dk.isNotEmpty) {
            dayCount[dk] = (dayCount[dk] ?? 0) + 1;
            dayScoreSum[dk] = (dayScoreSum[dk] ?? 0) + score;

            final dt = _parseDateKey(dk) ?? now;
            final wk = _weekKey(dt);

            weekCount[wk] = (weekCount[wk] ?? 0) + 1;
            weekScoreSum[wk] = (weekScoreSum[wk] ?? 0) + score;
          }

          if (mk.isNotEmpty) {
            monthCount[mk] = (monthCount[mk] ?? 0) + 1;
            monthScoreSum[mk] = (monthScoreSum[mk] ?? 0) + score;
          } else if (dk.isNotEmpty) {
            final dt = _parseDateKey(dk) ?? now;
            final monthKey = _monthKey(dt);
            monthCount[monthKey] = (monthCount[monthKey] ?? 0) + 1;
            monthScoreSum[monthKey] = (monthScoreSum[monthKey] ?? 0) + score;
          }
        }

        // Update statistik ringkasan
        totalSessions.value = totalSessionCount;
        avgOverallScore.value = totalSessionCount == 0
            ? 0.0
            : totalScoreSum / totalSessionCount;
        bestScore.value = highestScore;

        // Hitung streak konsistensi (sederhana: jumlah hari berturut-turut dengan latihan)
        _calculateConsistentStreak(dayCount);

        // Daily Aggregation
        final dList = <Agg>[];
        DateTime cursor = start;
        while (!cursor.isAfter(now)) {
          final dk = _dateKey(cursor);
          final c = dayCount[dk] ?? 0;
          final sum = dayScoreSum[dk] ?? 0.0;
          final avg = c == 0 ? 0.0 : (sum / c);
          dList.add(Agg(key: dk, count: c, avgScore: avg));
          cursor = cursor.add(const Duration(days: 1));
        }

        final wKeys = weekCount.keys.toList()..sort();
        final wList = wKeys.map((k) {
          final c = weekCount[k] ?? 0;
          final sum = weekScoreSum[k] ?? 0.0;
          final avg = c == 0 ? 0.0 : (sum / c);
          return Agg(key: k, count: c, avgScore: avg);
        }).toList();

        final mKeys = monthCount.keys.toList()..sort();
        final mList = mKeys.map((k) {
          final c = monthCount[k] ?? 0;
          final sum = monthScoreSum[k] ?? 0.0;
          final avg = c == 0 ? 0.0 : (sum / c);
          return Agg(key: k, count: c, avgScore: avg);
        }).toList();

        daily.assignAll(dList);
        weekly.assignAll(wList);
        monthly.assignAll(mList);

        isLoading.value = false;
      },
      onError: (e) {
        errorText.value = e.toString();
        isLoading.value = false;
      },
    );
  }

  void _calculateConsistentStreak(Map<String, int> dayCount) {
    if (dayCount.isEmpty) {
      consistentStreak.value = 0;
      return;
    }

    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final key = _dateKey(date);
      if (dayCount.containsKey(key) && (dayCount[key] ?? 0) > 0) {
        streak++;
      } else {
        break;
      }
    }
    consistentStreak.value = streak;
  }

  void listenLastCorrection() {
    _subLast?.cancel();

    final stream = narasiFs.streamLastCorrection();

    _subLast = stream.listen((doc) {
      final data = doc.data();
      if (data != null) {
        lastDoc.value = data;
        _extractLatestCategoryStats(data);
      }
    }, onError: (_) {});
  }

  void _extractLatestCategoryStats(Map<String, dynamic> data) {
    // Ekstrak data per kategori dari dokumen terbaru
    latestEyeLabel.value = data['eyeLabel'] ?? 'Belum teranalisis';
    latestEyeScore.value = (data['eyeScore'] ?? 0).round();
    latestEyeCount.value = (data['eyeCount'] ?? 0).toInt();

    latestSmileLabel.value = data['smileLabel'] ?? 'Belum teranalisis';
    latestSmileScore.value = (data['smileScore'] ?? 0).round();
    latestSmileCount.value = (data['smileCount'] ?? 0).toInt();

    latestPostureLabel.value = data['postureLabel'] ?? 'Belum teranalisis';
    latestPostureScore.value = (data['postureScore'] ?? 0).round();
    latestPostureCount.value = (data['postureCount'] ?? 0).toInt();

    latestOverallLabel.value = data['overallLabel'] ?? 'Belum teranalisis';
    latestOverallScore.value = (data['overallConfidence'] ?? 0).round();

    // Ekstrak suggestions
    final suggestions = data['suggestions'] as List?;
    if (suggestions != null) {
      latestSuggestions.assignAll(suggestions.map((e) => e.toString()));
    } else {
      latestSuggestions.clear();
    }

    latestAiRecommendation.value = data['aiRecommendation'] ?? '';
  }

  Map<String, dynamic> getOverallStats() {
    int totalSessionsCount = 0;
    double totalScoreWeighted = 0.0;

    for (var item in daily) {
      totalSessionsCount += item.count;
      totalScoreWeighted += item.avgScore * item.count;
    }

    final avgScore = totalSessionsCount == 0
        ? 0.0
        : totalScoreWeighted / totalSessionsCount;

    return {'totalSessions': totalSessionsCount, 'avgScore': avgScore};
  }

  Map<String, dynamic> getLatestPerformance() {
    if (daily.isEmpty) {
      return {'latestScore': 0, 'latestDate': '', 'trend': 'neutral'};
    }

    Agg? latest;
    for (var i = daily.length - 1; i >= 0; i--) {
      if (daily[i].count > 0) {
        latest = daily[i];
        break;
      }
    }

    if (latest == null) {
      return {'latestScore': 0, 'latestDate': '', 'trend': 'neutral'};
    }

    double previousScore = 0;
    for (var i = daily.length - 2; i >= 0; i--) {
      if (daily[i].count > 0) {
        previousScore = daily[i].avgScore;
        break;
      }
    }

    String trend = 'neutral';
    if (previousScore > 0) {
      if (latest.avgScore > previousScore + 5) {
        trend = 'up';
      } else if (latest.avgScore < previousScore - 5) {
        trend = 'down';
      } else {
        trend = 'stable';
      }
    }

    return {
      'latestScore': latest.avgScore,
      'latestDate': latest.key,
      'trend': trend,
      'previousScore': previousScore,
    };
  }
}
