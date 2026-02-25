// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// import '../../../routes/app_pages.dart';

// class AuthGateView extends StatelessWidget {
//   const AuthGateView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Stream auth state Firebase (otomatis session nempel)
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snap) {
//         // loading
//         if (snap.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }

//         final user = snap.data;

//         // kalau sudah login → dashboard
//         if (user != null) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (Get.currentRoute != Routes.DASHBOARD) {
//               Get.offAllNamed(Routes.DASHBOARD);
//             }
//           });
//         } else {
//           // kalau belum login → login
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (Get.currentRoute != Routes.LOGIN) {
//               Get.offAllNamed(Routes.LOGIN);
//             }
//           });
//         }

//         // placeholder biar build tidak null
//         return const Scaffold(body: Center(child: SizedBox()));
//       },
//     );
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_pages.dart';

class AuthGateView extends StatelessWidget {
  const AuthGateView({super.key});

  Future<bool> _hasSeenIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seen_intro') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSeenIntro(),
      builder: (context, introSnap) {
        // loading intro flag
        if (introSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final seenIntro = introSnap.data ?? false;

        // ✅ kalau belum pernah lihat intro → ke INTRO dulu
        if (!seenIntro) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.currentRoute != Routes.INTRO) {
              Get.offAllNamed(Routes.INTRO);
            }
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        // ✅ kalau sudah intro → baru cek auth session
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = snap.data;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (user != null) {
                if (Get.currentRoute != Routes.DASHBOARD) {
                  Get.offAllNamed(Routes.DASHBOARD);
                }
              } else {
                if (Get.currentRoute != Routes.LOGIN) {
                  Get.offAllNamed(Routes.LOGIN);
                }
              }
            });

            return const Scaffold(body: SizedBox.shrink());
          },
        );
      },
    );
  }
}
