import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Star Rating Widget
/// Interactive star rating with customizable size and color
class StarRating extends StatelessWidget {

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.onRatingChanged,
    this.size = 32,
    this.activeColor,
    this.inactiveColor,
    this.allowHalf = false,
  });
  final int rating;
  final int maxRating;
  final Function(int)? onRatingChanged;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool allowHalf;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starValue = index + 1;
        final isActive = starValue <= rating;

        return GestureDetector(
          onTap: onRatingChanged != null
              ? () => onRatingChanged!(starValue)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isActive ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isActive
                  ? (activeColor ?? AppTheme.accentYellow)
                  : (inactiveColor ?? AppTheme.borderDark),
              size: size,
            ),
          ),
        );
      }),
    );
  }
}

/// Read-only Star Rating Display
class StarRatingDisplay extends StatelessWidget {

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 16,
    this.activeColor,
    this.inactiveColor,
    this.showValue = true,
  });
  final double rating;
  final int maxRating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxRating, (index) {
            final starValue = index + 1;
            IconData icon;
            Color color;

            if (rating >= starValue) {
              icon = Icons.star_rounded;
              color = activeColor ?? AppTheme.accentYellow;
            } else if (rating >= starValue - 0.5) {
              icon = Icons.star_half_rounded;
              color = activeColor ?? AppTheme.accentYellow;
            } else {
              icon = Icons.star_outline_rounded;
              color = inactiveColor ?? AppTheme.borderDark;
            }

            return Icon(
              icon,
              color: color,
              size: size,
            );
          }),
        ),
        if (showValue) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}

/// Rating Badge Widget
class RatingBadge extends StatelessWidget {

  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewCount = 0,
    this.isSmall = false,
  });
  final double rating;
  final int reviewCount;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _getRatingColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: _getRatingColor(),
            size: isSmall ? 12 : 16,
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: isSmall ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: _getRatingColor(),
                ),
          ),
          if (reviewCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '($reviewCount)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: isSmall ? 10 : 12,
                    color: AppTheme.textMuted,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRatingColor() {
    if (rating >= 4.5) return AppTheme.statusSuccess;
    if (rating >= 3.5) return AppTheme.accentYellow;
    if (rating >= 2.5) return AppTheme.accentOrange;
    return AppTheme.statusError;
  }
}
