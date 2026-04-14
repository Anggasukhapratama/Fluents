import 'dart:async';
import 'package:fluent_ai/app/services/practice_firestore_service.dart';
import 'package:fluent_ai/app/services/hrd_firestore_service.dart';
import 'package:get/get.dart';

enum ChartMetric { count, avgScore }

enum ProgressMode { narasi, hrd }

class Agg {
  final String key;
  final int count;
  final double avgScore;
  Agg({required this.key, required this.count, required this.avgScore});
}

class ProgressController extends GetxController {
  final PracticeFirestoreService narasiFs = PracticeFirestoreService();
  final HrdFirestoreService hrdFs = HrdFirestoreService();

  final isLoading = true.obs;
  final errorText = ''.obs;

  final daysRange = 14.obs;

  final mode = ProgressMode.narasi.obs;
  void setMode(ProgressMode m) {
    if (mode.value == m) return;
    mode.value = m;
    listenAll(daysBack: daysRange.value);
    listenLastCorrection();
  }

  final chartMetric = ChartMetric.count.obs;
  void setMetric(ChartMetric m) => chartMetric.value = m;

  final RxList<Agg> daily = <Agg>[].obs;
  final RxList<Agg> weekly = <Agg>[].obs;
  final RxList<Agg> monthly = <Agg>[].obs;

  final lastDoc = Rxn<Map<String, dynamic>>();

  StreamSubscription? _subDaily;
  StreamSubscription? _subLast;

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

  // ✅ PERBAIKAN: Mengambil data overallConfidence untuk mode Narasi
  double _extractScore(Map<String, dynamic> m) {
    if (mode.value == ProgressMode.narasi) {
      return ((m['overallConfidence'] ?? 0) as num).toDouble();
    }
    return ((m['score'] ?? 0) as num).toDouble();
  }

  void listenAll({required int daysBack}) {
    _subDaily?.cancel();
    isLoading.value = true;
    errorText.value = '';

    final now = DateTime.now();
    final start = now.subtract(Duration(days: daysBack - 1));

    final startKey = _dateKey(start);
    final endKey = _dateKey(now);

    final stream = (mode.value == ProgressMode.narasi)
        ? narasiFs.streamSessionsByDateKeyRange(
            startDateKey: startKey,
            endDateKey: endKey,
          )
        : hrdFs.streamSessionsByDateKeyRange(
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

        for (final doc in snap.docs) {
          final m = doc.data();
          final dk = (m['dateKey'] ?? '') as String;
          final mk = (m['monthKey'] ?? '') as String;
          final score = _extractScore(m);

          if (dk.isNotEmpty) {
            dayCount[dk] = (dayCount[dk] ?? 0) + 1;
            dayScoreSum[dk] = (dayScoreSum[dk] ?? 0) + score;

            final dt = _parseDateKey(dk) ?? now;
            final wk = (m['weekKey'] ?? '') as String;
            final wkKey = wk.isNotEmpty ? wk : _weekKey(dt);

            weekCount[wkKey] = (weekCount[wkKey] ?? 0) + 1;
            weekScoreSum[wkKey] = (weekScoreSum[wkKey] ?? 0) + score;
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

  void listenLastCorrection() {
    _subLast?.cancel();

    final stream = (mode.value == ProgressMode.narasi)
        ? narasiFs.streamLastCorrection()
        : hrdFs.streamLastCorrection();

    _subLast = stream.listen((doc) {
      lastDoc.value = doc.data();
    }, onError: (_) {});
  }
}
