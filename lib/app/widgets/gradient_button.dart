import 'package:flutter/material.dart';

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: (widget.onPressed == null || widget.loading)
                  ? [
                      const Color(0xFF991B1B).withOpacity(0.6),
                      const Color(0xFFEA580C).withOpacity(0.6),
                    ]
                  : _isPressed
                  ? [
                      const Color(0xFF7F1D1D), // Lebih gelap saat ditekan
                      const Color(0xFFC2410C),
                    ]
                  : _isHovered
                  ? [
                      const Color(
                        0xFFB91C1C,
                      ), // Sedikit lebih terang saat hover
                      const Color(0xFFF97316),
                    ]
                  : const [
                      Color(0xFF991B1B), // Normal state
                      Color(0xFFEA580C),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: (widget.onPressed == null || widget.loading)
                ? []
                : _isPressed
                ? [
                    BoxShadow(
                      color: const Color(0xFF991B1B).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.text,
                    style: TextStyle(
                      color: (widget.onPressed == null || widget.loading)
                          ? Colors.white.withOpacity(0.7)
                          : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
