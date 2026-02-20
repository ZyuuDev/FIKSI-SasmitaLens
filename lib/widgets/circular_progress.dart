import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/app_theme.dart';

/// Circular Progress Widget
/// Displays a circular progress indicator with label
class CircularProgressWidget extends StatelessWidget {

  const CircularProgressWidget({
    super.key,
    required this.value,
    required this.displayValue,
    required this.label,
    required this.sublabel,
    required this.color,
    this.isCheckmark = false,
    this.size = 90,
  });
  final double value; // 0.0 to 1.0
  final String displayValue;
  final String label;
  final String sublabel;
  final Color color;
  final bool isCheckmark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Circular Progress
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CircularProgressPainter(
              progress: value.clamp(0.0, 1.0),
              color: color,
              backgroundColor: AppTheme.borderDark,
              strokeWidth: 6,
            ),
            child: Center(
              child: isCheckmark
                  ? Icon(
                      Icons.check,
                      color: color,
                      size: 32,
                    )
                  : Text(
                      displayValue,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Label
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        
        const SizedBox(height: 2),
        
        // Sublabel
        Text(
          sublabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 11,
                color: color,
              ),
        ),
      ],
    );
  }
}

/// Custom Painter for Circular Progress
class _CircularProgressPainter extends CustomPainter {

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Quality Score Circle Widget
class QualityScoreCircle extends StatelessWidget {

  const QualityScoreCircle({
    super.key,
    required this.score,
    this.size = 70,
  });
  final double score; // 0-100
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircularProgressPainter(
          progress: score / 100,
          color: color,
          backgroundColor: AppTheme.borderDark,
          strokeWidth: 4,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.toInt()}%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return AppTheme.statusSuccess;
    if (score >= 70) return AppTheme.accentYellow;
    return AppTheme.statusError;
  }
}

/// Battery/Connection Indicator
class ConnectionIndicator extends StatelessWidget { // 0-100

  const ConnectionIndicator({
    super.key,
    required this.isConnected,
    required this.batteryLevel,
  });
  final bool isConnected;
  final double batteryLevel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Connection dot
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConnected ? AppTheme.statusSuccess : AppTheme.statusError,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isConnected ? 'CONNECTED' : 'DISCONNECTED',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 10,
                color: isConnected ? AppTheme.statusSuccess : AppTheme.statusError,
              ),
        ),
        const SizedBox(width: 12),
        
        // Battery indicator
        SizedBox(
          width: 24,
          height: 12,
          child: CustomPaint(
            painter: _BatteryPainter(
              level: batteryLevel / 100,
              color: _getBatteryColor(batteryLevel),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${batteryLevel.toInt()}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
              ),
        ),
      ],
    );
  }

  Color _getBatteryColor(double level) {
    if (level >= 50) return AppTheme.statusSuccess;
    if (level >= 20) return AppTheme.accentYellow;
    return AppTheme.statusError;
  }
}

/// Battery Custom Painter
class _BatteryPainter extends CustomPainter {

  _BatteryPainter({
    required this.level,
    required this.color,
  });
  final double level;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppTheme.textMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Battery body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width - 2, size.height),
      const Radius.circular(2),
    );

    canvas.drawRRect(bodyRect, borderPaint);

    // Battery tip
    final tipRect = Rect.fromLTWH(
      size.width - 2,
      size.height * 0.25,
      2,
      size.height * 0.5,
    );
    canvas.drawRect(tipRect, Paint()..color = AppTheme.textMuted);

    // Fill level
    final fillWidth = (size.width - 4) * level;
    if (fillWidth > 0) {
      final fillRect = Rect.fromLTWH(
        2,
        2,
        fillWidth,
        size.height - 4,
      );
      canvas.drawRect(fillRect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.color != color;
  }
}
