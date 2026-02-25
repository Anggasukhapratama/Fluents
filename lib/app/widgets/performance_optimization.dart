import 'package:flutter/material.dart';

class OptimizedImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const OptimizedImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheHeight: height != null ? (height! * 2).toInt() : null,
      cacheWidth: width != null ? (width! * 2).toInt() : null,
      filterQuality: FilterQuality.medium,
      isAntiAlias: true,
    );
  }
}

class DebouncedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Duration debounceDuration;

  const DebouncedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  @override
  State<DebouncedButton> createState() => _DebouncedButtonState();
}

class _DebouncedButtonState extends State<DebouncedButton> {
  bool _isLoading = false;
  DateTime? _lastPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _handleTap,
      child: widget.child,
    );
  }

  void _handleTap() {
    final now = DateTime.now();

    // Debounce logic
    if (_lastPressed != null &&
        now.difference(_lastPressed!) < widget.debounceDuration) {
      return;
    }

    _lastPressed = now;

    setState(() => _isLoading = true);

    widget.onPressed();

    // Reset loading state after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }
}
