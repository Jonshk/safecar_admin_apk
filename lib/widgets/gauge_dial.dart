// lib/widgets/gauge_dial.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/sc_theme.dart';

/// Dial tipo tacómetro: un arco de fondo apagado y un arco de color que
/// "barre" desde 0 hasta [value]/[maxValue] cuando el widget aparece,
/// como la aguja de un carro arrancando. El número en el centro sube
/// en sincronía con el barrido (efecto odómetro).
class GaugeDial extends StatefulWidget {
  final int value;
  final int maxValue;
  final Color color;
  final String label;
  final Duration delay;

  const GaugeDial({
    super.key,
    required this.value,
    required this.label,
    this.maxValue = 10,
    this.color = SC.orange,
    this.delay = Duration.zero,
  });

  @override
  State<GaugeDial> createState() => _GaugeDialState();
}

class _GaugeDialState extends State<GaugeDial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sweep;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _sweep = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fraction = (widget.value / widget.maxValue).clamp(0.0, 1.0);
    return Column(
      children: [
        AnimatedBuilder(
          animation: _sweep,
          builder: (context, _) {
            final animatedFraction = fraction * _sweep.value;
            return CustomPaint(
              size: const Size(78, 50),
              painter: _DialPainter(
                fraction: animatedFraction,
                color: widget.color,
                trackColor: SC.border,
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        AnimatedBuilder(
          animation: _sweep,
          builder: (context, _) {
            final shown = (widget.value * _sweep.value).round();
            return Text(
              shown.toString().padLeft(2, '0'),
              style: SC.mono(size: 20, color: widget.color),
            );
          },
        ),
        const SizedBox(height: 2),
        Text(
          widget.label,
          style: SC.body(size: 10, color: SC.textSecondary),
        ),
      ],
    );
  }
}

class _DialPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color trackColor;

  _DialPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  static const _startAngle = math.pi; // 180°
  static const _sweepAngleTotal = math.pi; // medio círculo

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 6, size.width - 12, (size.height - 6) * 2 - 12);
    final strokeWidth = 6.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _startAngle, _sweepAngleTotal, false, trackPaint);
    if (fraction > 0) {
      canvas.drawArc(rect, _startAngle, _sweepAngleTotal * fraction, false, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}