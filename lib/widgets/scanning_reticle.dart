import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/app_theme.dart';

/// Scanning Reticle Widget
/// Animated scanning frame with corner brackets and scanning line
class ScanningReticle extends StatefulWidget {

  const ScanningReticle({
    super.key,
    this.size = 250,
  });
  final double size;

  @override
  State<ScanningReticle> createState() => _ScanningReticleState();
}

class _ScanningReticleState extends State<ScanningReticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scanLineAnimation = Tween<double>(
      begin: -1,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ),);

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Corner brackets
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: CornerBracketPainter(),
          ),

          // Animated scanning line
          AnimatedBuilder(
            animation: _scanLineAnimation,
            builder: (context, child) {
              return Positioned(
                top: (widget.size / 2) + (_scanLineAnimation.value * widget.size / 2 * 0.8),
                left: widget.size * 0.1,
                right: widget.size * 0.1,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.primaryGreen.withOpacity(0.8),
                        AppTheme.primaryGreen.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Center target
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Corner dots
          Positioned(
            top: widget.size * 0.15,
            left: widget.size * 0.15,
            child: _buildCornerDot(),
          ),
          Positioned(
            top: widget.size * 0.15,
            right: widget.size * 0.15,
            child: _buildCornerDot(),
          ),
          Positioned(
            bottom: widget.size * 0.15,
            left: widget.size * 0.15,
            child: _buildCornerDot(),
          ),
          Positioned(
            bottom: widget.size * 0.15,
            right: widget.size * 0.15,
            child: _buildCornerDot(),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.5),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}

/// Corner Bracket Custom Painter
class CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final cornerLength = size.width * 0.25;
    const strokeWidth = 3.0;

    // Top-left corner
    _drawCorner(
      canvas,
      paint,
      Offset(strokeWidth, strokeWidth),
      cornerLength,
      true,
      true,
    );

    // Top-right corner
    _drawCorner(
      canvas,
      paint,
      Offset(size.width - strokeWidth, strokeWidth),
      cornerLength,
      false,
      true,
    );

    // Bottom-left corner
    _drawCorner(
      canvas,
      paint,
      Offset(strokeWidth, size.height - strokeWidth),
      cornerLength,
      true,
      false,
    );

    // Bottom-right corner
    _drawCorner(
      canvas,
      paint,
      Offset(size.width - strokeWidth, size.height - strokeWidth),
      cornerLength,
      false,
      false,
    );
  }

  void _drawCorner(
    Canvas canvas,
    Paint paint,
    Offset corner,
    double length,
    bool isLeft,
    bool isTop,
  ) {
    final path = Path();

    // Horizontal line
    path.moveTo(
      corner.dx,
      corner.dy,
    );
    path.lineTo(
      isLeft ? corner.dx + length : corner.dx - length,
      corner.dy,
    );

    // Vertical line
    path.moveTo(
      corner.dx,
      corner.dy,
    );
    path.lineTo(
      corner.dx,
      isTop ? corner.dy + length : corner.dy - length,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated Scanning Frame
class AnimatedScanFrame extends StatefulWidget {

  const AnimatedScanFrame({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });
  final double width;
  final double height;
  final Widget child;

  @override
  State<AnimatedScanFrame> createState() => _AnimatedScanFrameState();
}

class _AnimatedScanFrameState extends State<AnimatedScanFrame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Content
        widget.child,

        // Animated border
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size(widget.width, widget.height),
              painter: AnimatedBorderPainter(
                progress: _controller.value,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Animated Border Painter
class AnimatedBorderPainter extends CustomPainter {

  AnimatedBorderPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    const cornerRadius = 20.0;

    // Draw animated corners
    final animatedLength = size.width * 0.3 * progress;

    // Top-left corner animation
    path.moveTo(0, cornerRadius);
    path.lineTo(0, math.max(0, cornerRadius - animatedLength));
    path.moveTo(0, 0);
    path.lineTo(math.min(size.width * 0.3 * progress, cornerRadius), 0);

    // Top-right corner animation
    path.moveTo(size.width, cornerRadius);
    path.lineTo(size.width, math.max(0, cornerRadius - animatedLength));
    path.moveTo(size.width, 0);
    path.lineTo(
      size.width - math.min(size.width * 0.3 * progress, cornerRadius),
      0,
    );

    // Bottom-left corner animation
    path.moveTo(0, size.height - cornerRadius);
    path.lineTo(0, size.height - math.max(0, cornerRadius - animatedLength));
    path.moveTo(0, size.height);
    path.lineTo(math.min(size.width * 0.3 * progress, cornerRadius), size.height);

    // Bottom-right corner animation
    path.moveTo(size.width, size.height - cornerRadius);
    path.lineTo(
      size.width,
      size.height - math.max(0, cornerRadius - animatedLength),
    );
    path.moveTo(size.width, size.height);
    path.lineTo(
      size.width - math.min(size.width * 0.3 * progress, cornerRadius),
      size.height,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant AnimatedBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
