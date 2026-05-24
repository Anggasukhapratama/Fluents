import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/routes/app_pages.dart';
import 'app/services/auth_service.dart';
import 'app/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load .env dulu (sebelum service / api dipakai)
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ init notification service + handle tap
  await NotificationService.instance.init(
    onTap: (payload) async {
      // ✅ geter kuat waktu notif diklik
      await NotificationService.instance.vibrateStrong();

      if (payload == null || payload.trim().isEmpty) return;

      // payload contoh:
      // scheduleId=xxx|when=12/01/2026 15:00|note=Frontend

      String when = "-";
      String note = "";

      try {
        final parts = payload.split("|");
        for (final p in parts) {
          if (p.startsWith("when=")) {
            when = p.replaceFirst("when=", "");
          } else if (p.startsWith("note=")) {
            note = p.replaceFirst("note=", "");
          }
        }
      } catch (_) {}

      // ✅ popup cantik
      Get.dialog(
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE7E5E4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Color(0xFFE53935),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Pengingat Jadwal 🔔",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: Get.back,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "⏰ Kamu mengatur jadwal pada:",
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    when,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "📝 Catatan:",
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    note.trim().isEmpty ? "(Tanpa catatan)" : note.trim(),
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                        // ✅ kalau mau langsung ke dashboard
                        // Get.offAllNamed(Routes.DASHBOARD);
                      },
                      child: const Text(
                        "OK",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  // AuthService global
  Get.put<AuthService>(AuthService(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.AUTH_GATE,
      getPages: AppPages.routes,

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black12,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
