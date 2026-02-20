import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/circular_progress.dart';
import '../widgets/recent_scan_card.dart';

/// Home Screen
/// Displays welcome message, harvest status, metrics, and recent scans
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final harvestStatus = ref.watch(harvestStatusProvider);
    final recentScans = ref.watch(recentScansProvider);
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: _buildAppBar(context, userProfile),
            ),
            
            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  
                  // Harvest Status Card
                  _HarvestStatusCard(harvestStatus: harvestStatus),
                  
                  const SizedBox(height: 24),
                  
                  // Metrics Row
                  _buildMetricsRow(context, harvestStatus),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Scans Header
                  _buildSectionHeader(context, 'Recent Scans', 'View All'),
                  
                  const SizedBox(height: 12),
                  
                  // Recent Scans List
                  ...recentScans.map((scan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RecentScanCard(scan: scan),
                  ),),
                  
                  const SizedBox(height: 100), // Bottom padding for nav bar
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Map<String, dynamic> userProfile) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello,',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome back, ${userProfile['name'].toString().split(' ')[0]}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.textPrimary,
                  size: 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildMetricsRow(BuildContext context, Map<String, dynamic> harvestStatus) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CircularProgressWidget(
          value: harvestStatus['brixLevel'] / 25, // Normalize to 0-1
          displayValue: '${harvestStatus['brixLevel'].toInt()}%',
          label: 'Brix Level',
          sublabel: 'HIGH',
          color: AppTheme.accentOrange,
        ),
        CircularProgressWidget(
          value: harvestStatus['acidity'] / 7, // Normalize to 0-1
          displayValue: '${harvestStatus['acidity']}',
          label: 'Acidity pH',
          sublabel: 'OPTIMAL',
          color: AppTheme.primaryGreen,
        ),
        CircularProgressWidget(
          value: 1,
          displayValue: '✓',
          label: 'Residue',
          sublabel: harvestStatus['residue'].toString().toUpperCase(),
          color: AppTheme.primaryGreen,
          isCheckmark: true,
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }

  Widget _buildSectionHeader(BuildContext context, String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            action,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryGreen,
                ),
          ),
        ),
      ],
    );
  }
}

/// Harvest Status Card Widget
class _HarvestStatusCard extends StatelessWidget {

  const _HarvestStatusCard({required this.harvestStatus});
  final Map<String, dynamic> harvestStatus;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT HARVEST STATUS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppTheme.primaryGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          harvestStatus['plot'],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'GRADE ${harvestStatus['grade']}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Fruit Image
          Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(harvestStatus['imageUrl']),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                
                // Variety label
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VARIETY',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        harvestStatus['variety'],
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                
                // Expand button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: AppTheme.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Stats Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'HARVEST EST.',
                    value: harvestStatus['harvestEst'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    label: 'MATURITY',
                    value: '${harvestStatus['maturity'].toInt()}% Ready',
                    valueColor: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.2, end: 0);
  }
}

/// Stat Box Widget
class _StatBox extends StatelessWidget {

  const _StatBox({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

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
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
