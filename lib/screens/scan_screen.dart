import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_theme.dart';
import '../providers/app_providers.dart';
import '../models/fruit_analysis.dart';
import '../widgets/scanning_reticle.dart';
import '../widgets/star_rating.dart';

/// Scan Screen
/// Simulated camera view with animated scanning reticle
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  bool _isScanning = false;
  bool _showResult = false;

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
    });

    // Simulate scanning process
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isScanning = false;
      _showResult = true;
    });

    // Show result bottom sheet
    if (mounted) {
      _showResultSheet();
    }
  }

  void _showResultSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ScanResultSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                ),
                Text(
                  'SASMITA LENS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        letterSpacing: 3,
                      ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.help_outline, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
          
          // Camera View
          Expanded(
            child: Stack(
              children: [
                // Simulated camera feed
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=600',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                // Dark overlay
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
                
                // Scanning Reticle
                const Center(
                  child: ScanningReticle(),
                ),
                
                // AI Analysis Badge
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
                          const SizedBox(width: 8),
                          Text(
                            _isScanning ? 'Analyzing...' : 'AI Analysis Active',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Detection Label
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryGreen),
                      ),
                      child: const Text(
                        'MALUS DOMESTICA • DETECTED',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Scan Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isScanning ? null : _startScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: _isScanning
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Scanning...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Scan Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scan Result Sheet
/// Glassmorphism bottom sheet with fruit analysis data
class ScanResultSheet extends ConsumerStatefulWidget {
  const ScanResultSheet({super.key});

  @override
  ConsumerState<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends ConsumerState<ScanResultSheet> {
  int _userRating = 0;
  final _locationController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: AppTheme.statusError,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isSubmitting = false;
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating submitted successfully!'),
          backgroundColor: AppTheme.statusSuccess,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mock scan result
    final result = FruitAnalysis.mock();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundCard.withOpacity(0.95),
            AppTheme.backgroundDark.withOpacity(0.98),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with quality score
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.variety,
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${result.grade} GRADE',
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                              fontSize: 11,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      result.origin,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Quality Score Circle
                          _QualityScoreCircle(score: result.qualityScore),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Metrics Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _MetricCard(
                            icon: Icons.water_drop_outlined,
                            label: 'Freshness',
                            value: '${result.freshness.toInt()}%',
                            change: '+2%',
                            iconColor: AppTheme.accentBlue,
                          ),
                          _MetricCard(
                            icon: Icons.access_time,
                            label: 'Best Before',
                            value: result.bestBefore,
                            change: '-1 Day',
                            changeColor: AppTheme.accentOrange,
                            iconColor: AppTheme.accentOrange,
                          ),
                          _MetricCard(
                            icon: Icons.water_drop,
                            label: 'Water Content',
                            value: '${result.waterContent.toInt()}%',
                            iconColor: AppTheme.accentBlue,
                          ),
                          _MetricCard(
                            icon: Icons.verified,
                            label: 'Pesticide',
                            value: result.residueStatus,
                            subtitle: 'Verified',
                            iconColor: AppTheme.statusSuccess,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // AI Recommendations
                      Text(
                        'AI Recommendations',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      ...result.aiRecipes.map((recipe) => _RecipeCard(recipe: recipe)),
                      
                      const SizedBox(height: 24),
                      
                      // Rate this fruit
                      Text(
                        'Rate this Fruit',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Star Rating
                      Center(
                        child: StarRating(
                          rating: _userRating,
                          onRatingChanged: (rating) {
                            setState(() {
                              _userRating = rating;
                            });
                          },
                          size: 40,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Location Input
                      TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          hintText: 'Store Name (optional)',
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: AppTheme.textMuted,
                          ),
                          filled: true,
                          fillColor: AppTheme.backgroundDarker,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitRating,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Submit Rating',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

/// Quality Score Circle
class _QualityScoreCircle extends StatelessWidget {

  const _QualityScoreCircle({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primaryGreen,
          width: 4,
        ),
      ),
      child: Center(
        child: Text(
          '${score.toInt()}%',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryGreen,
                fontSize: 20,
              ),
        ),
      ),
    );
  }
}

/// Metric Card
class _MetricCard extends StatelessWidget {

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.change,
    this.subtitle,
    this.iconColor,
    this.changeColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? change;
  final String? subtitle;
  final Color? iconColor;
  final Color? changeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDarker,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.primaryGreen).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              if (change != null)
                Text(
                  change!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: changeColor ?? AppTheme.statusSuccess,
                      ),
                ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.statusSuccess,
                      ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

/// Recipe Card
class _RecipeCard extends StatelessWidget {

  const _RecipeCard({required this.recipe});
  final AIRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDarker,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.timer,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recipe.prepTime,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        recipe.difficulty,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.accentOrange,
                              fontSize: 10,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
