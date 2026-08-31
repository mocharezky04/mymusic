import 'dart:math' as math;

import 'package:flutter/material.dart';

class EqBars extends StatefulWidget {
  const EqBars({
    super.key,
    this.active = false,
    this.color,
    this.barCount = 4,
    this.height = 14,
    this.width = 16,
  });

  final bool active;
  final Color? color;
  final int barCount;
  final double height;
  final double width;

  @override
  State<EqBars> createState() => _EqBarsState();
}

class _EqBarsState extends State<EqBars> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(EqBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _EqPainter(
            progress: widget.active ? _controller.value : 0.25,
            color: color,
            barCount: widget.barCount,
          ),
          size: Size(widget.width, widget.height),
        );
      },
    );
  }
}

class _EqPainter extends CustomPainter {
  _EqPainter({
    required this.progress,
    required this.color,
    required this.barCount,
  });

  final double progress;
  final Color color;
  final int barCount;

  @override
  void paint(Canvas canvas, Size size) {
    final gap = 3.0;
    final barWidth = (size.width - gap * (barCount - 1)) / barCount;
    final paint = Paint()..color = color;
    for (var i = 0; i < barCount; i++) {
      final wave = 0.5 + 0.5 * math.sin(progress * math.pi * 2 + i * 2.3);
      final height = 0.28 * size.height + 0.72 * size.height * wave;
      final x = i * (barWidth + gap);
      final top = size.height - height;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barWidth, height),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EqPainter old) =>
      old.progress != progress || old.color != color || old.barCount != barCount;
}