import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../widgets/animated_logo.dart';

/// Animated Splash Screen
/// Features rotating outer border and pulsing laser animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Rotation controller for outer border
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    
    // Pulse controller for laser effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Progress controller for progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Rotation animation (continuous)
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ),);

    // Pulse animation (opacity)
    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ),);

    // Progress animation
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ),);

    // Start animations
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
    _progressController.forward();

    // Navigate to main screen after 3 seconds
    Future.delayed(AppDurations.splash, () {
      if (mounted) {
        _navigateToMain();
      }
    });
  }

  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const _MainPlaceholder(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            
            // Animated Logo with rotating border and pulsing laser
            AnimatedBuilder(
              animation: Listenable.merge([
                _rotationAnimation,
                _pulseAnimation,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(200, 200),
                  painter: AnimatedLogoPainter(
                    rotation: _rotationAnimation.value,
                    pulseOpacity: _pulseAnimation.value,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 40),
            
            // App Name
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Sasmita ',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'Lens',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms)
                .slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 8),
            
            // Decorative line
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.primaryGreen,
                    AppTheme.primaryGreenDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .scaleX(begin: 0, end: 1),
            
            const SizedBox(height: 24),
            
            // Tagline
            Text(
              AppConstants.tagline,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 600.ms),
            
            const SizedBox(height: 8),
            
            // Version
            Text(
              AppConstants.appVersion,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            )
                .animate()
                .fadeIn(delay: 800.ms, duration: 600.ms),
            
            const Spacer(),
            
            // Progress Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Column(
                children: [
                  // Progress Label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SYSTEM CHECK',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.primaryGreen,
                              fontSize: 12,
                            ),
                      ),
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Text(
                            '${(_progressAnimation.value * 100).toInt()}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: AppTheme.borderDark,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryGreen,
                          ),
                          minHeight: 8,
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Status Text
                  Text(
                    'Calibrating sensors...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 1000.ms, duration: 600.ms),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

/// Placeholder widget for navigation
class _MainPlaceholder extends StatelessWidget {
  const _MainPlaceholder();

  @override
  Widget build(BuildContext context) {
    // Import MainLayout here to avoid circular dependency
    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 100)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // Use Navigator to push MainLayout
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AppConstants.routeMain);
          });
        }
        return const Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          body: Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryGreen,
            ),
          ),
        );
      },
    );
  }
}
