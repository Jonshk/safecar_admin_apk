// lib/screens/splash_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/sc_theme.dart';
import 'main_nav_screen.dart';

/// Splash animado de Flutter. Distinto de la pantalla nativa de Android
/// (launch_background) que se ve ANTES de esto mientras el motor
/// arranca — esta es la que corre ya con Dart/Flutter vivo: dial,
/// texto, barra de progreso indeterminada, y firma "Powered by Pixova".
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sweep;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _sweep = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, anim, __) => const MainNavScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SC.bg,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _sweep,
                  builder: (context, _) => CustomPaint(
                    size: const Size(140, 90),
                    painter: _SplashDialPainter(fraction: _sweep.value),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    children: [
                      Text('SAFE CAR', style: SC.display(size: 24)),
                      const SizedBox(height: 4),
                      Text(
                        'ADMIN CONSOLE',
                        style: SC.body(size: 11, color: SC.textMuted)
                            .copyWith(letterSpacing: 3),
                      ),
                      const SizedBox(height: 28),
                      const _ProgressTrack(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 36,
            child: FadeTransition(
              opacity: _textFade,
              child: Column(
                children: [
                  Text(
                    'POWERED BY',
                    style: SC.body(size: 9, color: SC.textMuted)
                        .copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'PIXOVA',
                    style: SC.display(size: 13, color: SC.textSecondary)
                        .copyWith(letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de progreso indeterminada, propia (sin Material default),
/// consistente con el resto de la identidad — un segmento naranja
/// que recorre el track de izquierda a derecha en loop.
class _ProgressTrack extends StatefulWidget {
  const _ProgressTrack();
  @override
  State<_ProgressTrack> createState() => _ProgressTrackState();
}

class _ProgressTrackState extends State<_ProgressTrack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Container(
          color: SC.border,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Align(
                alignment: Alignment(
                  -1 + 4 * _controller.value.clamp(0.0, 1.0),
                  0,
                ),
                child: FractionallySizedBox(
                  widthFactor: 0.32,
                  child: Container(color: SC.orange),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SplashDialPainter extends CustomPainter {
  final double fraction;
  _SplashDialPainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height;
    final r = size.width * 0.42;
    final stroke = size.width * 0.085;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    final track = Paint()
      ..color = SC.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = SC.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, track);
    canvas.drawArc(rect, math.pi, math.pi * fraction, false, fill);

    final angle = math.pi + math.pi * fraction;
    final nx = cx + r * math.cos(angle);
    final ny = cy + r * math.sin(angle);
    final dotPaint = Paint()..color = SC.textPrimary;
    canvas.drawCircle(Offset(nx, ny), stroke * 0.45, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SplashDialPainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}