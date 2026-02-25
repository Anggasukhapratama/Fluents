import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_pages.dart';

class IntroController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  Timer? _timer;

  final List<Map<String, String>> introData = [
    {
      "image": "assets/images/intro1.png",
      "title": "Welcome to Fluent! 🚀",
      "description": "Tingkatin skill ngomong lo biar makin pede!",
    },
    {
      "image": "assets/images/intro2.png",
      "title": "Cepat & Efektif! ⏩",
      "description": "Latihan langsung pake AI, biar lo makin lancar ngomong.",
    },
    {
      "image": "assets/images/intro3.png",
      "title": "Fluent pake AI! 🤖",
      "description":
          "Cek ekspresi lo & dapetin feedback real-time biar makin jago!",
    },
  ];

  @override
  void onInit() {
    super.onInit();
    _startAutoScroll(); // kalau gak mau auto scroll, comment aja baris ini
  }

  @override
  void onClose() {
    _timer?.cancel();
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) => currentPage.value = index;

  void next() {
    if (currentPage.value < introData.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      finishIntro();
    }
  }

  void skip() {
    pageController.animateToPage(
      introData.length - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> finishIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_intro', true);

    // ✅ balik ke AUTH_GATE biar dia yang decide: dashboard/login
    Get.offAllNamed(Routes.AUTH_GATE);
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      final lastIndex = introData.length - 1;
      final nextIndex = currentPage.value == lastIndex
          ? 0
          : currentPage.value + 1;

      currentPage.value = nextIndex;
      pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }
}
