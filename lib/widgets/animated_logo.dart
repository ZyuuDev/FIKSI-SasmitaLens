import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Custom Painter for Animated Logo
/// Draws rotating outer border circles and pulsing inner laser
class AnimatedLogoPainter extends CustomPainter {

  AnimatedLogoPainter({
    required this.rotation,
    required this.pulseOpacity,
  });
  final double rotation;
  final double pulseOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;

    // Draw outer rotating dotted circle
    _drawDottedCircle(
      canvas,
      center,
      baseRadius * 0.85,
      rotation,
      AppTheme.primaryGreen.withOpacity(0.4),
    );

    // Draw middle rotating dashed circle (opposite direction)
    _drawDashedCircle(
      canvas,
      center,
      baseRadius * 0.70,
      -rotation * 1.5,
      AppTheme.primaryGreen.withOpacity(0.6),
    );

    // Draw inner solid circle
    final innerCirclePaint = Paint()
      ..color = AppTheme.primaryGreen.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(
      center,
      baseRadius * 0.55,
      innerCirclePaint,
    );

    // Draw pulsing laser line (horizontal)
    final laserPaint = Paint()
      ..color = AppTheme.primaryGreen.withOpacity(pulseOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawLine(
      Offset(center.dx - baseRadius * 0.5, center.dy),
      Offset(center.dx + baseRadius * 0.5, center.dy),
      laserPaint,
    );

    // Draw center logo (leaf/eye shape)
    _drawCenterLogo(canvas, center, baseRadius * 0.35);
  }

  void _drawDottedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Color color,
  ) {
    const dotCount = 24;
    const dotSize = 3.0;

    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * math.pi * i / dotCount) + rotation;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), dotSize, paint);
    }
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Color color,
  ) {
    const dashCount = 12;
    const dashLength = 0.3; // radians

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (2 * math.pi * i / dashCount) + rotation;

      final path = Path();
      path.addArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashLength,
      );

      canvas.drawPath(path, paint);
    }
  }

  void _drawCenterLogo(Canvas canvas, Offset center, double size) {
    // Draw the main leaf/eye shape
    final path = Path();

    // Create a stylized leaf/eye shape
    final halfWidth = size * 0.8;
    final halfHeight = size * 0.6;

    path.moveTo(center.dx - halfWidth, center.dy);

    // Top curve
    path.quadraticBezierTo(
      center.dx,
      center.dy - halfHeight * 1.5,
      center.dx + halfWidth,
      center.dy,
    );

    // Bottom curve
    path.quadraticBezierTo(
      center.dx,
      center.dy + halfHeight * 1.5,
      center.dx - halfWidth,
      center.dy,
    );

    path.close();

    // Fill with gradient
    const gradient = LinearGradient(
      colors: [
        AppTheme.primaryGreen,
        AppTheme.primaryGreenDark,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final rect = Rect.fromCenter(
      center: center,
      width: size * 2,
      height: size * 2,
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    // Draw inner detail (pupil/vein)
    final detailPath = Path();
    final detailWidth = size * 0.25;
    final detailHeight = size * 0.4;

    detailPath.moveTo(center.dx - detailWidth, center.dy);
    detailPath.quadraticBezierTo(
      center.dx - detailWidth * 0.5,
      center.dy - detailHeight,
      center.dx,
      center.dy - detailHeight * 0.5,
    );
    detailPath.quadraticBezierTo(
      center.dx + detailWidth * 0.3,
      center.dy,
      center.dx,
      center.dy + detailHeight * 0.5,
    );
    detailPath.quadraticBezierTo(
      center.dx - detailWidth * 0.5,
      center.dy + detailHeight,
      center.dx - detailWidth,
      center.dy,
    );
    detailPath.close();

    final detailPaint = Paint()
      ..color = AppTheme.backgroundDark.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawPath(detailPath, detailPaint);

    // Draw center dot
    final centerDotPaint = Paint()
      ..color = AppTheme.primaryGreenLight
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      size * 0.1,
      centerDotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant AnimatedLogoPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.pulseOpacity != pulseOpacity;
  }
}

/// Simplified Logo Widget for use in other screens
class SasmitaLogo extends StatelessWidget {

  const SasmitaLogo({
    super.key,
    this.size = 60,
    this.animate = false,
  });
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (animate) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 2 * math.pi),
        duration: const Duration(seconds: 8),
        builder: (context, rotation, child) {
          return CustomPaint(
            size: Size(size, size),
            painter: AnimatedLogoPainter(
              rotation: rotation,
              pulseOpacity: 1,
            ),
          );
        },
      );
    }

    return CustomPaint(
      size: Size(size, size),
      painter: AnimatedLogoPainter(
        rotation: 0,
        pulseOpacity: 1,
      ),
    );
  }
}

/// Logo with glow effect
class GlowingLogo extends StatelessWidget {

  const GlowingLogo({
    super.key,
    this.size = 80,
  });
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SasmitaLogo(size: size, animate: true),
    );
  }
}
