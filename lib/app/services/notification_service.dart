import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _inited = false;

  // ✅ Channel (Android)
  static const String _channelId = "fluent_schedule_channel";
  static const String _channelName = "Fluent AI Reminder";
  static const String _channelDesc = "Pengingat jadwal latihan wawancara";

  // ================= INIT =================
  /// Panggil sekali di main.dart
  /// - onTap: callback saat user tap notif
  Future<void> init({Function(String? payload)? onTap}) async {
    if (_inited) return;

    // timezone
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // init platform settings
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) async {
        if (onTap != null) onTap(resp.payload);
      },
    );

    await _requestPermissions();
    _inited = true;
  }

  Future<void> _requestPermissions() async {
    // Android 13+ notif permission
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // iOS permission
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ================= DETAILS =================

  AndroidNotificationDetails _androidDetails({
    required String bigTitle,
    required String bigBody,
  }) {
    return AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,

      importance: Importance.max,
      priority: Priority.high,

      // ✅ notif lebih “cantik” dan kebaca
      styleInformation: BigTextStyleInformation(
        bigBody,
        contentTitle: bigTitle,
        summaryText: "Fluent AI",
      ),

      playSound: true,
      enableVibration: true,

      // ✅ vibrasi notif sistem (untuk jam 15:00 walau app mati)
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 600]),

      // Heads-up
      fullScreenIntent: true,

      icon: '@mipmap/ic_launcher',
    );
  }

  NotificationDetails _details({
    required String bigTitle,
    required String bigBody,
  }) => NotificationDetails(
    android: _androidDetails(bigTitle: bigTitle, bigBody: bigBody),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    ),
  );

  // ================= MANUAL VIBRATE (in-app / on tap) =================

  /// ✅ geter manual (misal saat notif ditap atau popup muncul)
  Future<void> vibrateStrong() async {
    try {
      final canVibrate = await Vibrate.canVibrate;
      if (!canVibrate) return;

      Vibrate.feedback(FeedbackType.heavy);
      await Future.delayed(const Duration(milliseconds: 280));
      Vibrate.feedback(FeedbackType.heavy);
    } catch (_) {}
  }

  // ================= SAFE SCHEDULER =================

  Future<void> _scheduleSafe({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime time,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        time,
        _details(bigTitle: title, bigBody: body),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // fallback kalau exact ditolak (beberapa vendor/MIUI)
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        time,
        _details(bigTitle: title, bigBody: body),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  int _baseIdFromScheduleId(String scheduleId) {
    return scheduleId.hashCode.abs() % 100000;
  }

  // ================= PUBLIC API =================

  /// ✅ Jadwalkan notif 3x: at, +10 detik, +20 detik
  /// note: catatan dari user (boleh kosong)
  Future<void> scheduleTriple({
    required String scheduleId,
    required DateTime at,
    required String title,
    required String note,
  }) async {
    await init();

    final now = DateTime.now();
    if (!at.isAfter(now)) return;

    final baseId = _baseIdFromScheduleId(scheduleId);

    final when =
        "${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}/${at.year} "
        "${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}";

    final cleanNote = note.trim();
    final bodyText = cleanNote.isNotEmpty
        ? "⏰ Jadwal: $when\n📝 Catatan: $cleanNote\n\nTap untuk melihat detail."
        : "⏰ Jadwal: $when\n📝 Catatan: (Tanpa catatan)\n\nTap untuk melihat detail.";

    // ✅ payload untuk diparse di main.dart
    final payload = "scheduleId=$scheduleId|when=$when|note=$cleanNote";

    final times = [
      at,
      at.add(const Duration(seconds: 10)),
      at.add(const Duration(seconds: 20)),
    ];

    for (int i = 0; i < times.length; i++) {
      final tzTime = tz.TZDateTime.from(times[i], tz.local);
      await _scheduleSafe(
        id: baseId + i,
        title: title,
        body: bodyText,
        time: tzTime,
        payload: payload,
      );
    }
  }

  /// ❌ Cancel notif triple
  Future<void> cancelTriple(String scheduleId) async {
    await init();
    final base = _baseIdFromScheduleId(scheduleId);
    await _plugin.cancel(base);
    await _plugin.cancel(base + 1);
    await _plugin.cancel(base + 2);
  }

  /// (Optional) cancel semua notif
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
