import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';

/// Recent Scan Card Widget
/// Displays a single recent scan item
class RecentScanCard extends StatelessWidget {

  const RecentScanCard({
    required this.scan, super.key,
  });
  final Map<String, dynamic> scan;

  @override
  Widget build(BuildContext context) {
    final time = scan['time'] as DateTime;
    final grade = scan['grade'] as String;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          // Scan Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              scan['image'],
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 56,
                  height: 56,
                  color: AppTheme.backgroundDarker,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: AppTheme.textMuted,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Scan Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan['name'],
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(time),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                ),
              ],
            ),
          ),
          
          // Grade Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getGradeColor(grade).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Grade $grade',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    color: _getGradeColor(grade),
                  ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return DateFormat('MMM d, yyyy').format(time);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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

/// Metric Card Widget
class MetricCard extends StatelessWidget {

  const MetricCard({
    required this.icon, required this.label, required this.value, super.key,
    this.sublabel,
    this.iconColor,
    this.valueColor,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? sublabel;
  final Color? iconColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.primaryGreen).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppTheme.primaryGreen,
                size: 24,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Label
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
            
            const SizedBox(height: 4),
            
            // Value
            Row(
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: valueColor,
                      ),
                ),
                if (sublabel != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    sublabel!,
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
    );
  }
}

/// Info Row Widget
class InfoRow extends StatelessWidget {

  const InfoRow({
    required this.label, required this.value, super.key,
    this.valueColor,
    this.trailing,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ],
    );
  }
}

/// Status Badge Widget
class StatusBadge extends StatelessWidget {

  const StatusBadge({
    required this.text, super.key,
    this.type = StatusType.success,
    this.isSmall = false,
  });
  final String text;
  final StatusType type;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(isSmall ? 12 : 20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (type == StatusType.success) ...[
            Container(
              width: isSmall ? 5 : 6,
              height: isSmall ? 5 : 6,
              decoration: BoxDecoration(
                color: _getForegroundColor(),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: isSmall ? 4 : 6),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: isSmall ? 9 : 11,
                  color: _getForegroundColor(),
                ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case StatusType.success:
        return AppTheme.statusSuccess;
      case StatusType.warning:
        return AppTheme.statusWarning;
      case StatusType.error:
        return AppTheme.statusError;
      case StatusType.info:
        return AppTheme.statusInfo;
    }
  }

  Color _getForegroundColor() {
    switch (type) {
      case StatusType.success:
        return AppTheme.statusSuccess;
      case StatusType.warning:
        return AppTheme.statusWarning;
      case StatusType.error:
        return AppTheme.statusError;
      case StatusType.info:
        return AppTheme.statusInfo;
    }
  }
}

enum StatusType {
  success,
  warning,
  error,
  info,
}
