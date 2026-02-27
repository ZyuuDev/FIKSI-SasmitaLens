import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/app_theme.dart';

/// Animated Splash Screen
/// Features a per-component animated Sasmita Lens logo on a rich green background
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // --- Animation Controllers ---
  late AnimationController _borderController;   // golden border rotate-in entrance
  late AnimationController _ringSpinController; // continuous slow ring rotation
  late AnimationController _eyeController;      // eye fade-in
  late AnimationController _beamController;     // light beams shoot out
  late AnimationController _leafController;     // leaf scale-in
  late AnimationController _moleculeController; // molecule dots fade-in
  late AnimationController _pulseController;    // continuous pulse glow
  late AnimationController _progressController; // loading bar
  late AnimationController _sweepController;    // diagonal light sweep

  // --- Animations ---
  late Animation<double> _borderScale;
  late Animation<double> _borderRotation;  // entrance spin (0 → 2π once)
  late Animation<double> _ringSpinAngle;   // continuous slow spin (0 → 2π looping)
  late Animation<double> _eyeOpacity;
  late Animation<double> _eyeScale;
  late Animation<double> _beamLength;
  late Animation<double> _leafScale;
  late Animation<double> _leafOpacity;
  late Animation<double> _moleculeOpacity;
  late Animation<double> _pulseOpacity;
  late Animation<double> _progressAnim;
  late Animation<double> _sweepProgress;  // light sweep 0→1 (off-screen left → off-screen right)

  @override
  void initState() {
    super.initState();

    // Controller: golden border entrance animate-in (0.8s)
    _borderController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _borderScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _borderController, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)),
    );
    _borderRotation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.linear),
    );

    // Controller: continuous slow ring rotation — 12s per full revolution
    _ringSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );
    _ringSpinAngle = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _ringSpinController, curve: Curves.linear),
    );

    // Controller: eye fade+scale 600ms, starts after border
    _eyeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _eyeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _eyeController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _eyeScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _eyeController, curve: Curves.elasticOut),
    );

    // Controller: light beams shoot out 700ms after eye
    _beamController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _beamLength = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _beamController, curve: Curves.easeOutCubic),
    );

    // Controller: leaf scale-in 600ms
    _leafController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _leafScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _leafController, curve: Curves.elasticOut),
    );
    _leafOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _leafController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    // Controller: molecule fade-in 500ms
    _moleculeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _moleculeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _moleculeController, curve: Curves.easeIn),
    );

    // Controller: continuous glow pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseOpacity = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Controller: progress bar 3.5s
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500));
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Controller: light sweep — 700ms sweep, repeats via loop with 2.6s gap
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _sweepProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sweepController, curve: Curves.easeInOut),
    );

    // --- Sequence the animations ---
    _startSequence();

    // Navigate after splash
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) _navigateToMain();
    });
  }

  Future<void> _startSequence() async {
    // Step 1: border entrance (0ms)
    await _borderController.forward();

    // Step 1b: immediately begin slow continuous ring spin
    _ringSpinController.repeat();

    // Step 2: eye appears (50ms gap)
    await Future.delayed(const Duration(milliseconds: 50));
    await _eyeController.forward();

    // Step 3: beams shoot (100ms gap)
    await Future.delayed(const Duration(milliseconds: 100));
    await _beamController.forward();

    // Step 4: leaf appears concurrently with beams
    _leafController.forward();

    // Step 5: molecules fade in (200ms after beams start)
    await Future.delayed(const Duration(milliseconds: 200));
    await _moleculeController.forward();

    // Step 6: continuous pulse + progress bar begin
    _pulseController.repeat(reverse: true);
    _progressController.forward();

    // Step 7: light sweep starts after 400ms, then loops every ~3.3s
    await Future.delayed(const Duration(milliseconds: 400));
    _runSweepLoop();
  }

  /// Loops the light sweep: 700ms sweep → 2600ms rest → repeat
  Future<void> _runSweepLoop() async {
    while (mounted) {
      await _sweepController.forward(from: 0.0);
      _sweepController.reset();
      await Future.delayed(const Duration(milliseconds: 2600));
    }
  }

  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const _MainPlaceholder(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _borderController.dispose();
    _ringSpinController.dispose();
    _eyeController.dispose();
    _beamController.dispose();
    _leafController.dispose();
    _moleculeController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Rich green gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF012B0E), // very dark green
              Color(0xFF014D1A), // deep forest green
              Color(0xFF026020), // medium rich green
              Color(0xFF013D12), // dark green bottom
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Main Logo ──
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _borderController,
                    _ringSpinController,
                    _eyeController,
                    _beamController,
                    _leafController,
                    _moleculeController,
                    _pulseController,
                    _sweepController,
                  ]),
                  builder: (context, child) {
                    // Gabungkan rotation entrance + continuous spin
                    final combinedRotation =
                        _borderRotation.value + _ringSpinAngle.value;
                    return CustomPaint(
                      size: const Size(260, 260),
                      painter: _SasmitaLogoPainter(
                        borderScale: _borderScale.value,
                        borderRotation: combinedRotation,
                        eyeOpacity: _eyeOpacity.value,
                        eyeScale: _eyeScale.value,
                        beamLength: _beamLength.value,
                        leafScale: _leafScale.value,
                        leafOpacity: _leafOpacity.value,
                        moleculeOpacity: _moleculeOpacity.value,
                        pulseOpacity: _pulseOpacity.value,
                        sweepProgress: _sweepProgress.value,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

              // ── "SASMITA" text ──
              Text(
                'SASMITA',
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
              )
                  .animate()
                  .fadeIn(delay: 1400.ms, duration: 700.ms)
                  .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 4),

              // ── "── LENS ──" decorated line ──
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 30, height: 2, color: const Color(0xFFD4AF37)),
                  const SizedBox(width: 10),
                  const Text(
                    'L E N S',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(width: 30, height: 2, color: const Color(0xFFD4AF37)),
                ],
              )
                  .animate()
                  .fadeIn(delay: 1700.ms, duration: 600.ms)
                  .scaleX(begin: 0, end: 1, curve: Curves.easeOutCubic),

              const SizedBox(height: 14),

              // ── Tagline ──
              const Text(
                'Kearifan Tani, Presisi Digital.',
                style: TextStyle(
                  color: Color(0xFFB8D4A8),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1,
                ),
              )
                  .animate()
                  .fadeIn(delay: 2100.ms, duration: 700.ms),

              const Spacer(flex: 2),

              // ── Progress Section ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Column(
                  children: [
                    // Label row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'INITIALIZING',
                          style: TextStyle(
                            color: Color(0xFF69F0AE),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _progressAnim,
                          builder: (context, _) {
                            return Text(
                              '${(_progressAnim.value * 100).toInt()}%',
                              style: const TextStyle(
                                color: Color(0xFF69F0AE),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: AnimatedBuilder(
                        animation: _progressAnim,
                        builder: (context, _) {
                          return LinearProgressIndicator(
                            value: _progressAnim.value,
                            backgroundColor: const Color(0xFF1A4A2A),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF00E676),
                            ),
                            minHeight: 6,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Mempersiapkan sistem analisis...',
                      style: TextStyle(
                        color: Color(0xFF5A8A6A),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 2400.ms, duration: 600.ms),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Custom Painter: draws ALL logo components individually
// ─────────────────────────────────────────────────────────
class _SasmitaLogoPainter extends CustomPainter {
  const _SasmitaLogoPainter({
    required this.borderScale,
    required this.borderRotation,
    required this.eyeOpacity,
    required this.eyeScale,
    required this.beamLength,
    required this.leafScale,
    required this.leafOpacity,
    required this.moleculeOpacity,
    required this.pulseOpacity,
    required this.sweepProgress,
  });

  final double borderScale;
  final double borderRotation;
  final double eyeOpacity;
  final double eyeScale;
  final double beamLength;
  final double leafScale;
  final double leafOpacity;
  final double moleculeOpacity;
  final double pulseOpacity;
  final double sweepProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final outerR = size.width / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(borderScale);
    canvas.translate(-cx, -cy);

    // 1. ── Inner white/cream circle background ──
    final bgPaint = Paint()
      ..color = const Color(0xFFF5F5F0)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerR * 0.72, bgPaint);

    // 2. ── Golden ornate outer border ──
    _drawOrnateGoldenBorder(canvas, center, outerR, borderRotation);

    canvas.restore();

    // 3. ── Eye symbol (animates separately) ──
    if (eyeOpacity > 0) {
      canvas.save();
      canvas.translate(cx, cy - outerR * 0.10);
      canvas.scale(eyeScale * borderScale);
      canvas.translate(-cx, -(cy - outerR * 0.10));
      _drawEye(canvas, center.dx, cy - outerR * 0.10, outerR * 0.38, eyeOpacity);
      canvas.restore();
    }

    // 4. ── Light beams shoot from eye pupil ──
    if (beamLength > 0 && eyeOpacity > 0.5 && borderScale > 0.5) {
      _drawLightBeams(canvas, center.dx, cy - outerR * 0.10, outerR * 0.58, beamLength, eyeOpacity * beamLength);
    }

    // 5. ── Leaf ──
    if (leafOpacity > 0 && borderScale > 0.5) {
      canvas.save();
      final leafCX = cx - outerR * 0.25;
      final leafCY = cy + outerR * 0.22;
      canvas.translate(leafCX, leafCY);
      canvas.scale(leafScale * borderScale);
      canvas.translate(-leafCX, -leafCY);
      _drawLeaf(canvas, leafCX, leafCY, outerR * 0.28, leafOpacity);
      canvas.restore();
    }

    // 6. ── Molecular structure ──
    if (moleculeOpacity > 0 && borderScale > 0.5) {
      _drawMolecule(canvas, cx + outerR * 0.18, cy + outerR * 0.30, outerR * 0.22, moleculeOpacity * borderScale);
    }

    // 7. ── Glow halo behind circle ──
    _drawGlowHalo(canvas, center, outerR, pulseOpacity * borderScale);

    // 8. ── Light sweep (diagonal shimmer, top-left → bottom-right) ──
    if (sweepProgress > 0 && borderScale > 0.8) {
      _drawLightSweep(canvas, center, outerR, sweepProgress);
    }
  }

  // ── GOLDEN ORNATE BORDER ──
  void _drawOrnateGoldenBorder(Canvas canvas, Offset center, double outerR, double rotation) {
    const Color gold = Color(0xFFD4AF37);
    const Color darkGreen = Color(0xFF014D1A);

    // Outer gold ring wide
    final outerRingPaint = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerR * 0.12;
    canvas.drawCircle(center, outerR * 0.88, outerRingPaint);

    // Inner gold ring thin
    final innerRingPaint = Paint()
      ..color = gold.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerR * 0.03;
    canvas.drawCircle(center, outerR * 0.82, innerRingPaint);
    canvas.drawCircle(center, outerR * 0.93, innerRingPaint);

    // Decorative segments on the border
    const int segments = 24;
    for (int i = 0; i < segments; i++) {
      final angle = (2 * math.pi * i / segments) + rotation;
      final alternating = i % 2 == 0;

      // Outer petal shape
      final petalPaint = Paint()
        ..color = alternating ? darkGreen : gold.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      final x = center.dx + outerR * 0.88 * math.cos(angle);
      final y = center.dy + outerR * 0.88 * math.sin(angle);

      canvas.drawCircle(Offset(x, y), outerR * 0.04, petalPaint);

      // Small gold dot accent between petals
      final angle2 = angle + (math.pi / segments);
      final x2 = center.dx + outerR * 0.88 * math.cos(angle2);
      final y2 = center.dy + outerR * 0.88 * math.sin(angle2);

      final dotPaint = Paint()
        ..color = gold.withOpacity(0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x2, y2), outerR * 0.02, dotPaint);
    }

    // Curved filigree arcs (batik-like)
    const int arcs = 8;
    final arcPaint = Paint()
      ..color = darkGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerR * 0.025
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < arcs; i++) {
      final startAngle = (2 * math.pi * i / arcs) + rotation;
      final path = Path();
      path.addArc(
        Rect.fromCircle(center: center, radius: outerR * 0.88),
        startAngle,
        math.pi / arcs * 0.5,
      );
      canvas.drawPath(path, arcPaint);
    }
  }

  // ── EYE SYMBOL ──
  void _drawEye(Canvas canvas, double cx, double cy, double size, double opacity) {
    final center = Offset(cx, cy);
    const Color darkGreen = Color(0xFF014D1A);

    // Eye outline (leaf/almond shape)
    final eyePath = Path();
    final halfW = size * 0.95;
    final halfH = size * 0.42;
    eyePath.moveTo(cx - halfW, cy);
    eyePath.quadraticBezierTo(cx, cy - halfH * 1.8, cx + halfW, cy);
    eyePath.quadraticBezierTo(cx, cy + halfH * 1.3, cx - halfW, cy);
    eyePath.close();

    final eyeStrokePaint = Paint()
      ..color = darkGreen.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(eyePath, eyeStrokePaint);

    // Iris circle
    final irisPaint = Paint()
      ..color = darkGreen.withOpacity(opacity * 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.30, irisPaint);

    // Spiral pupil (concentric arcs)
    final spiralPaint = Paint()
      ..color = darkGreen.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.04
      ..strokeCap = StrokeCap.round;

    for (int i = 3; i > 0; i--) {
      final r = size * 0.08 * i;
      canvas.drawCircle(center, r, spiralPaint);
    }

    // Pupil dot
    final pupilPaint = Paint()
      ..color = darkGreen.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.07, pupilPaint);

    // Eyelashes (upper lashes)
    final lashPaint = Paint()
      ..color = darkGreen.withOpacity(opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.03
      ..strokeCap = StrokeCap.round;

    for (int i = -2; i <= 2; i++) {
      final lashX = cx + (i * halfW / 2.5);
      final lashTopY = cy - halfH * 1.6;
      canvas.drawLine(Offset(lashX, lashTopY), Offset(lashX, lashTopY - size * 0.15), lashPaint);
    }
  }

  // ── LIGHT BEAMS ──
  void _drawLightBeams(Canvas canvas, double eyeCX, double eyeCY, double maxLength, double progress, double opacity) {
    // Three beams from pupil center: red=top-right, yellow=right, green=bottom-right
    final beamColors = [
      const Color(0xFFE53935), // red
      const Color(0xFFFFD600), // yellow
      const Color(0xFF00C853), // green
    ];
    // Angles (in radians): slightly fanning down-right
    final angles = [
      math.pi * 0.10,  // shallow up-right
      math.pi * 0.20,  // middle right
      math.pi * 0.32,  // more down-right
    ];

    for (int i = 0; i < 3; i++) {
      final endX = eyeCX + maxLength * progress * math.cos(angles[i]);
      final endY = eyeCY + maxLength * progress * math.sin(angles[i]);

      // Beam glow
      final glowPaint = Paint()
        ..color = beamColors[i].withOpacity(opacity * 0.35)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawLine(Offset(eyeCX, eyeCY), Offset(endX, endY), glowPaint);

      // Beam core
      final beamPaint = Paint()
        ..color = beamColors[i].withOpacity(opacity * 0.9)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(eyeCX, eyeCY), Offset(endX, endY), beamPaint);
    }
  }

  // ── LEAF ──
  void _drawLeaf(Canvas canvas, double cx, double cy, double size, double opacity) {
    final leafPath = Path();
    leafPath.moveTo(cx, cy - size);
    leafPath.cubicTo(
      cx + size * 0.7, cy - size * 0.5,
      cx + size * 0.8, cy + size * 0.3,
      cx, cy + size * 0.6,
    );
    leafPath.cubicTo(
      cx - size * 0.6, cy + size * 0.1,
      cx - size * 0.5, cy - size * 0.6,
      cx, cy - size,
    );
    leafPath.close();

    // Leaf gradient fill
    final leafRect = Rect.fromCenter(center: Offset(cx, cy), width: size * 2, height: size * 2);
    final leafGradient = LinearGradient(
      colors: [
        const Color(0xFF1B5E20).withOpacity(opacity),
        const Color(0xFF388E3C).withOpacity(opacity),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    final leafFillPaint = Paint()
      ..shader = leafGradient.createShader(leafRect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leafPath, leafFillPaint);

    // Central vein
    final veinPaint = Paint()
      ..color = const Color(0xFF81C784).withOpacity(opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy - size * 0.9), Offset(cx, cy + size * 0.5), veinPaint);

    // Side veins
    for (int i = 1; i <= 3; i++) {
      final vy = cy - size * 0.5 + (i * size * 0.3);
      canvas.drawLine(Offset(cx, vy), Offset(cx + size * 0.4, vy - size * 0.1), veinPaint);
      canvas.drawLine(Offset(cx, vy), Offset(cx - size * 0.35, vy - size * 0.1), veinPaint);
    }
  }

  // ── MOLECULAR STRUCTURE ──
  void _drawMolecule(Canvas canvas, double baseX, double baseY, double size, double opacity) {
    const Color darkGreen = Color(0xFF014D1A);

    final nodePaint = Paint()
      ..color = darkGreen.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final bondPaint = Paint()
      ..color = darkGreen.withOpacity(opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Define atom positions
    final nodes = [
      Offset(baseX, baseY),
      Offset(baseX + size * 0.5, baseY - size * 0.3),
      Offset(baseX + size * 0.6, baseY + size * 0.25),
      Offset(baseX - size * 0.4, baseY + size * 0.3),
      Offset(baseX - size * 0.45, baseY - size * 0.25),
      Offset(baseX + size * 0.15, baseY - size * 0.55),
    ];

    // Bonds
    final bonds = [
      [0, 1], [0, 2], [0, 3], [0, 4], [1, 5], [1, 2],
    ];
    for (final b in bonds) {
      canvas.drawLine(nodes[b[0]], nodes[b[1]], bondPaint);
    }

    // Atoms (small circles)
    for (final node in nodes) {
      canvas.drawCircle(node, size * 0.09, nodePaint);
      final fillPaint = Paint()
        ..color = const Color(0xFFF5F5F0).withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(node, size * 0.065, fillPaint);
    }
  }

  // ── GLOW HALO ──
  void _drawGlowHalo(Canvas canvas, Offset center, double outerR, double opacity) {
    final glowPaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(opacity * 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, outerR * 1.05, glowPaint);

    final innerGlowPaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(opacity * 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, outerR * 0.8, innerGlowPaint);
  }

  // ── LIGHT SWEEP (diagonal shimmer from top-left to bottom-right) ──
  void _drawLightSweep(Canvas canvas, Offset center, double outerR, double progress) {
    canvas.save();

    // Clip seluruh sapuan ke dalam lingkaran logo (termasuk border luar)
    final clipCircle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: outerR * 0.96));
    canvas.clipPath(clipCircle);

    // Pindah pivot ke tengah canvas, lalu putar 45° agar sapuan arah diagonal
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4); // 45 derajat: top-left → bottom-right

    // Lebar band sapuan (lebih lebar = kilauan lebih tebal)
    final bandHalfWidth = outerR * 0.18;

    // Posisi band bergerak dari -outerR*1.6 ke +outerR*1.6
    // (dimulai dari luar kiri atas, berakhir di luar kanan bawah)
    final sweepX = (progress * (outerR * 3.2)) - outerR * 1.6;

    final gradRect = Rect.fromLTRB(
      sweepX - bandHalfWidth, -outerR * 1.5,
      sweepX + bandHalfWidth,  outerR * 1.5,
    );

    // Gradient dari transparan → putih terang → transparan
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(gradRect);

    canvas.drawRect(gradRect, sweepPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SasmitaLogoPainter old) =>
      old.borderScale != borderScale ||
      old.borderRotation != borderRotation ||
      old.eyeOpacity != eyeOpacity ||
      old.eyeScale != eyeScale ||
      old.beamLength != beamLength ||
      old.leafScale != leafScale ||
      old.leafOpacity != leafOpacity ||
      old.moleculeOpacity != moleculeOpacity ||
      old.pulseOpacity != pulseOpacity ||
      old.sweepProgress != sweepProgress;
}

// ─────────────────────────────────────────────────────────
// Placeholder for navigation
// ─────────────────────────────────────────────────────────
class _MainPlaceholder extends StatelessWidget {
  const _MainPlaceholder();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 100)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AppConstants.routeMain);
          });
        }
        return const Scaffold(
          backgroundColor: Color(0xFF012B0E),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF00E676)),
          ),
        );
      },
    );
  }
}
