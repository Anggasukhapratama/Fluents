import 'package:flutter/material.dart';

class SolidButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  const SolidButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: (onPressed == null || loading) ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD32F2F), // Warna solid merah
        foregroundColor: Colors.white, // Teks solid putih
        disabledBackgroundColor: const Color(0xFFD32F2F).withOpacity(0.5),
        disabledForegroundColor: Colors.white.withOpacity(0.7),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: const Color(0xFFD32F2F).withOpacity(0.3),
      ),
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white, // Loading indicator solid putih
              ),
            )
          : Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
    );
  }
}
