import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/bluetooth_service.dart';
import '../utils/app_theme.dart';

/// Recent Scan Card Widget
/// Displays a single recent scan item from SensorData
class RecentScanCard extends StatelessWidget {
  const RecentScanCard({
    required this.scan,
    super.key,
  });

  final SensorData scan;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(scan.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Glowing status emoji container instead of image
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  statusColor.withOpacity(0.25),
                  statusColor.withOpacity(0.05),
                ],
                radius: 0.8,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                scan.emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Scan Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pemindaian #${scan.loop}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                // Raw metrics
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildMetricChip(
                      context,
                      Icons.graphic_eq_rounded,
                      'AMP',
                      '${scan.ampRaw}${scan.isAmpValid ? " ✓" : " ✗"}',
                      statusColor,
                    ),
                    _buildMetricChip(
                      context,
                      Icons.hearing_outlined,
                      'Resonansi',
                      '${scan.gemaAkustik} Hz',
                      statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTime(scan.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),

          // Condition Badge & Grade
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withOpacity(0.25),
                  ),
                ),
                child: Text(
                  scan.labelKondisi,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Grade ${scan.grade}',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildMetricChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDarker,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 3),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return DateFormat('dd MMM, HH:mm').format(time);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SEGAR_PADAT':
        return AppTheme.statusSuccess;
      case 'MATANG_LUNAK':
        return AppTheme.statusWarning;
      case 'BELUM_MATANG':
        return AppTheme.accentOrange;
      case 'INDIKASI_BUSUK':
        return AppTheme.statusError;
      default:
        return AppTheme.textMuted;
    }
  }
}
