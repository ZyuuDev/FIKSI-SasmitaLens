import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scan_feed.dart';
import '../models/vendor_rating.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import '../widgets/star_rating.dart';

/// Leaderboard Screen
/// Displays top verified vendors and social feed
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topVendors = ref.watch(topVendorsProvider);
    final feeds = ref.watch(filteredFeedProvider);
    final userPoints = ref.watch(userPointsProvider);
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(context, userProfile, userPoints),
            ),
            
            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),
                  
                  // Top Verified Vendors
                  _buildSectionHeader(context, 'Top Verified Vendors', 'View All'),
                  
                  const SizedBox(height: 16),
                  
                  // Podium
                  _PodiumSection(vendors: topVendors.take(3).toList()),
                  
                  const SizedBox(height: 24),
                  
                  // Category Filters
                  _CategoryFilters(),
                  
                  const SizedBox(height: 24),
                  
                  // Quality Feed Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.statusSuccess,
                              shape: BoxShape.circle,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .fadeIn(duration: 500.ms)
                              .fadeOut(duration: 500.ms),
                          const SizedBox(width: 8),
                          Text(
                            'Live Updates',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.statusSuccess,
                                ),
                          ),
                        ],
                      ),
                      Text(
                        'Quality Feed',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Feed Items
                  ...feeds.map((feed) => _FeedCard(feed: feed)),
                  
                  const SizedBox(height: 100), // Bottom padding
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> userProfile, int userPoints) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quality Feed',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.statusSuccess,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fadeIn(duration: 500.ms)
                      .fadeOut(duration: 500.ms),
                  const SizedBox(width: 8),
                  Text(
                    'Live Updates',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.statusSuccess,
                        ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(userProfile['avatar']),
                ),
                const SizedBox(width: 8),
                Text(
                  '$userPoints pts',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
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

/// Podium Section with Top 3 Vendors
class _PodiumSection extends StatelessWidget {

  const _PodiumSection({required this.vendors});
  final List<VendorRating> vendors;

  @override
  Widget build(BuildContext context) {
    if (vendors.length < 3) return const SizedBox.shrink();

    return SizedBox(
      height: 160,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          _PodiumItem(
            vendor: vendors[1],
            rank: 2,
            height: 100,
            color: AppTheme.accentYellow,
          ),
          
          const SizedBox(width: 16),
          
          // 1st Place
          _PodiumItem(
            vendor: vendors[0],
            rank: 1,
            height: 130,
            color: AppTheme.primaryGreen,
            isFirst: true,
          ),
          
          const SizedBox(width: 16),
          
          // 3rd Place
          _PodiumItem(
            vendor: vendors[2],
            rank: 3,
            height: 80,
            color: AppTheme.accentOrange,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }
}

/// Podium Item Widget
class _PodiumItem extends StatelessWidget {

  const _PodiumItem({
    required this.vendor,
    required this.rank,
    required this.height,
    required this.color,
    this.isFirst = false,
  });
  final VendorRating vendor;
  final int rank;
  final double height;
  final Color color;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: isFirst ? 70 : 55,
              height: isFirst ? 70 : 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: isFirst ? 4 : 3,
                ),
                boxShadow: isFirst
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: ClipOval(
                child: Image.network(
                  vendor.avatarUrl ?? 'https://i.pravatar.cc/150',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return ColoredBox(
                      color: AppTheme.backgroundCard,
                      child: Icon(
                        Icons.store,
                        color: color,
                        size: isFirst ? 32 : 24,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Rank badge
            Positioned(
              top: 0,
              child: Container(
                width: isFirst ? 24 : 20,
                height: isFirst ? 24 : 20,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.backgroundDark,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: isFirst ? 12 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            
            // Crown for 1st place
            if (isFirst)
              const Positioned(
                top: -15,
                child: Icon(
                  Icons.emoji_events,
                  color: AppTheme.accentYellow,
                  size: 28,
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Vendor Name
        SizedBox(
          width: 80,
          child: Text(
            vendor.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Points
        Text(
          '${vendor.totalPoints.toStringAsFixed(0)} pts',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
        
        const SizedBox(height: 8),
        
        // Podium bar
        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.6),
                color.withOpacity(0.2),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Category Filters
class _CategoryFilters extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ['All', 'Mangoes', 'Coffee', 'Apples', 'Verified'];
    final selectedFilter = ref.watch(feedFilterProvider);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              ref.read(feedFilterProvider.notifier).state = filter;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen
                    : AppTheme.backgroundCard,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filter == 'All')
                    Icon(
                      Icons.grid_view,
                      size: 14,
                      color: isSelected ? Colors.black : AppTheme.textMuted,
                    ),
                  if (filter == 'Mangoes')
                    const Text('🥭', style: TextStyle(fontSize: 14)),
                  if (filter == 'Coffee')
                    const Text('☕', style: TextStyle(fontSize: 14)),
                  if (filter == 'Apples')
                    const Text('🍎', style: TextStyle(fontSize: 14)),
                  if (filter == 'Verified')
                    Icon(
                      Icons.verified,
                      size: 14,
                      color: isSelected ? Colors.black : AppTheme.textMuted,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    filter,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected ? Colors.black : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Feed Card Widget
class _FeedCard extends StatelessWidget {

  const _FeedCard({required this.feed});
  final ScanFeed feed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    feed.userAvatar ?? 'https://i.pravatar.cc/150',
                  ),
                ),
                const SizedBox(width: 12),
                
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: feed.userName,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            TextSpan(
                              text: ' ${feed.actionText} ',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                            TextSpan(
                              text: feed.productName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _getGradeColor(feed.productGrade),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            feed.formattedTimeAgo,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                          ),
                          if (feed.location != null) ...[
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              feed.location!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // More options
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.more_horiz,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          
          // Product Image
          if (feed.productImage != null)
            Stack(
              children: [
                Image.network(
                  feed.productImage!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 180,
                      color: AppTheme.backgroundDarker,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: AppTheme.textMuted,
                      ),
                    );
                  },
                ),
                
                // Verification/Flag Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: feed.isVerified
                          ? AppTheme.statusSuccess.withOpacity(0.9)
                          : feed.isFlagged
                              ? AppTheme.statusError.withOpacity(0.9)
                              : AppTheme.backgroundDark.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          feed.isVerified
                              ? Icons.verified
                              : feed.isFlagged
                                  ? Icons.warning
                                  : Icons.info,
                          color: feed.isVerified || feed.isFlagged
                              ? Colors.white
                              : AppTheme.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          feed.isVerified
                              ? 'SASMITA VERIFIED'
                              : feed.isFlagged
                                  ? 'FLAGGED'
                                  : 'PENDING',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Quality overlay
                if (feed.qualityScore != null)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SWEETNESS',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 9,
                                  color: AppTheme.textMuted,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${feed.qualityScore!.toInt()}%',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (feed.size != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              'SIZE',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 9,
                                    color: AppTheme.textMuted,
                                  ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              feed.size!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Rating
                StarRatingDisplay(
                  rating: feed.rating.toDouble(),
                  size: 18,
                ),
                
                // Actions
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.thumb_up_outlined,
                      count: feed.likes,
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline,
                      count: feed.comments,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return AppTheme.statusSuccess;
      case 'B':
        return AppTheme.accentYellow;
      case 'C':
        return AppTheme.accentOrange;
      default:
        return AppTheme.statusSuccess;
    }
  }
}

/// Action Button Widget
class _ActionButton extends StatelessWidget {

  const _ActionButton({
    required this.icon,
    required this.count,
  });
  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
              ),
        ),
      ],
    );
  }
}
