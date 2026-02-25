import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/intro_controller.dart';

class IntroView extends GetView<IntroController> {
  const IntroView({super.key});

  static const Color kPrimaryColor = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ===== TOP BAR (Logo + Skip) =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  // ✅ logo/brand di intro (karena kamu mau 1 page intro aja)
                  Row(
                    children: [
                      // kalau kamu punya logo image:
                      // Image.asset('assets/images/fluent_logo.png', width: 28, height: 28),
                      // const SizedBox(width: 8),
                      const Text(
                        "Fluent",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: controller.skip,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ===== PAGEVIEW =====
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                itemCount: controller.introData.length,
                onPageChanged: controller.onPageChanged,
                itemBuilder: (context, index) {
                  final data = controller.introData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image
                        if ((data["image"] ?? '').isNotEmpty)
                          Image.asset(
                            data["image"]!,
                            width: 280,
                            height: 280,
                            fit: BoxFit.contain,
                          ),

                        const SizedBox(height: 30),

                        // Title
                        Text(
                          data["title"] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Desc
                        Text(
                          data["description"] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ===== DOTS =====
            Obx(() {
              final curr = controller.currentPage.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(controller.introData.length, (i) {
                    final active = i == curr;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? kPrimaryColor : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
              );
            }),

            // ===== BOTTOM BUTTONS =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Obx(() {
                final isLast =
                    controller.currentPage.value ==
                    controller.introData.length - 1;

                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.skip,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Lewati',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLast
                            ? controller.finishIntro
                            : controller.next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isLast ? 'Mulai' : 'Next',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
