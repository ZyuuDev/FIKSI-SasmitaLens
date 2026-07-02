import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scan_feed.dart';
import '../models/vendor_rating.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import '../widgets/star_rating.dart';

/// Leaderboard Screen
/// Menampilkan mitra tani terbaik dan kabar pemindaian kualitas buah secara langsung.
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
            // Header Utama
            SliverToBoxAdapter(
              child: _buildHeader(context, userProfile, userPoints),
            ),
            
            // Konten
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  
                  // Peringkat Mitra Tani Terbaik
                  _buildSectionHeader(context, 'Mitra Tani Terbaik', 'Lihat Semua'),
                  
                  const SizedBox(height: 16),
                  
                  // Podium Tiga Besar
                  _PodiumSection(vendors: topVendors.take(3).toList()),
                  
                  const SizedBox(height: 28),
                  
                  // Kabar Kualitas Buah
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kabar Kualitas',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
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
                            'Live Update',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.statusSuccess,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Filter Kategori
                  _CategoryFilters(),
                  
                  const SizedBox(height: 20),
                  
                  // Daftar Postingan Kabar Kualitas
                  if (feeds.isEmpty)
                    _buildEmptyFeed(context)
                  else
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
                'Papan Peringkat',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mitra Tani & Konsistensi Kualitas',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
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
                const Icon(
                  Icons.emoji_events,
                  color: AppTheme.accentYellow,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '$userPoints Poin',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            action,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyFeed(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      alignment: Alignment.center,
      child: const Text(
        'Tidak ada pembaruan kualitas pada kategori ini.',
        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
      ),
    );
  }
}

/// Podium Section dengan Desain 3D Sederhana dan Indikator Peringkat 1-3
class _PodiumSection extends StatelessWidget {
  const _PodiumSection({required this.vendors});
  final List<VendorRating> vendors;

  @override
  Widget build(BuildContext context) {
    if (vendors.length < 3) return const SizedBox.shrink();

    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Juara 2
          Expanded(
            child: _PodiumItem(
              vendor: vendors[1],
              rank: 2,
              color: AppTheme.accentYellow,
              topOffset: 35,
            ),
          ),
          const SizedBox(width: 12),
          // Juara 1 (Paling Tinggi & Glowing)
          Expanded(
            child: _PodiumItem(
              vendor: vendors[0],
              rank: 1,
              color: AppTheme.primaryGreen,
              isFirst: true,
              topOffset: 0,
            ),
          ),
          const SizedBox(width: 12),
          // Juara 3
          Expanded(
            child: _PodiumItem(
              vendor: vendors[2],
              rank: 3,
              color: AppTheme.accentOrange,
              topOffset: 50,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }
}

/// Item Podium untuk Satu Mitra Tani
class _PodiumItem extends StatelessWidget {
  const _PodiumItem({
    required this.vendor,
    required this.rank,
    required this.color,
    required this.topOffset,
    this.isFirst = false,
  });

  final VendorRating vendor;
  final int rank;
  final Color color;
  final double topOffset;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final double avatarSize = isFirst ? 76 : 58;
    final double fontSize = isFirst ? 13 : 11;

    return Padding(
      padding: EdgeInsets.only(top: topOffset),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFirst ? color.withOpacity(0.5) : AppTheme.borderDark,
            width: isFirst ? 1.5 : 1,
          ),
          boxShadow: isFirst
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.08),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trofi untuk Peringkat 1
            if (isFirst)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.emoji_events,
                  color: AppTheme.accentYellow,
                  size: 24,
                ),
              )
            else
              const SizedBox(height: 12),

            // Avatar & Lencana Rank
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color,
                      width: isFirst ? 3 : 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      vendor.avatarUrl ?? 'https://i.pravatar.cc/150',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return ColoredBox(
                          color: AppTheme.backgroundDarker,
                          child: Icon(
                            Icons.store,
                            color: color,
                            size: isFirst ? 28 : 22,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: -6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: isFirst ? 22 : 18,
                      height: isFirst ? 22 : 18,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.backgroundCard,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: isFirst ? 11 : 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Nama Mitra
            Text(
              vendor.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Poin Kualitas
            Text(
              '${_formatPoints(vendor.totalPoints)} Poin',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isFirst ? color : AppTheme.textMuted,
                    fontWeight: isFirst ? FontWeight.bold : FontWeight.w500,
                    fontSize: isFirst ? 12 : 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPoints(int points) {
    if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}k';
    }
    return points.toString();
  }
}

/// Category Filters (Bahasa Indonesia)
class _CategoryFilters extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ['Semua', 'Mangga', 'Melon', 'Terverifikasi'];
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
                  if (filter == 'Semua')
                    Icon(
                      Icons.grid_view,
                      size: 14,
                      color: isSelected ? Colors.black : AppTheme.textMuted,
                    ),
                  if (filter == 'Mangga')
                    const Text('🥭', style: TextStyle(fontSize: 14)),
                  if (filter == 'Melon')
                    const Text('🍈', style: TextStyle(fontSize: 14)),
                  if (filter == 'Terverifikasi')
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
          // Header Pengguna
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    feed.userAvatar ?? 'https://i.pravatar.cc/150',
                  ),
                ),
                const SizedBox(width: 12),
                
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
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            TextSpan(
                              text: ' baru saja ${feed.actionText} ',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                            TextSpan(
                              text: feed.productName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _getGradeColor(feed.productGrade),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                            ],
                          ),
                          if (feed.location != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
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
          
          // Gambar Produk (jika ada)
          if (feed.productImage != null)
            Stack(
              children: [
                ClipRRect(
                  child: Image.network(
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
                ),
                
                // Lencana Terverifikasi SASMITA
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: feed.isVerified
                          ? AppTheme.statusSuccess.withOpacity(0.9)
                          : feed.isFlagged
                              ? AppTheme.statusError.withOpacity(0.9)
                              : AppTheme.backgroundDark.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
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
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          feed.isVerified
                              ? 'VERIFIED SASMITA'
                              : feed.isFlagged
                                  ? 'TERLAPOR'
                                  : 'TERTUNDA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Hamparan Kualitas Kemanisan
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
                            'SKOR KEMANISAN',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 9,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${feed.qualityScore!.toInt()}%',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (feed.size != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              'UKURAN',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 9,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              feed.size!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          
          // Kaki Postingan
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tampilan Bintang
                StarRatingDisplay(
                  rating: feed.rating.toDouble(),
                ),
                
                // Tombol Reaksi
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
      case 'A+':
        return AppTheme.statusSuccess;
      case 'B':
      case 'B+':
        return AppTheme.accentYellow;
      case 'C':
        return AppTheme.accentOrange;
      default:
        return AppTheme.statusSuccess;
    }
  }
}

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
          size: 16,
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
