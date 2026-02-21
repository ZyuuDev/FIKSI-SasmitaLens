import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../utils/app_theme.dart';

/// Settings Screen
/// User profile, device info, and app preferences
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final isDeviceConnected = ref.watch(isDeviceConnectedProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final appVersion = ref.watch(appVersionProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(context),
            ),
            
            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),
                  
                  // Profile Card
                  _ProfileCard(userProfile: userProfile),
                  
                  const SizedBox(height: 20),
                  
                  // Device Card
                  _DeviceCard(
                    isConnected: isDeviceConnected,
                    batteryLevel: 78,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // General Section
                  const _SectionTitle(title: 'GENERAL'),
                  
                  const SizedBox(height: 12),
                  
                  // Settings Items
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    trailing: Switch(
                      value: notificationsEnabled,
                      onChanged: (value) {
                        ref.read(notificationsEnabledProvider.notifier).state = value;
                      },
                      activeColor: AppTheme.primaryGreen,
                    ),
                  ),
                  
                  _SettingsItem(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    subtitle: 'Dark',
                    onTap: () {},
                  ),
                  
                  _SettingsItem(
                    icon: Icons.center_focus_strong,
                    title: 'Calibrate Lens',
                    onTap: () {},
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Privacy & Support Section
                  const _SectionTitle(title: 'PRIVACY & SUPPORT'),
                  
                  const SizedBox(height: 12),
                  
                  _SettingsItem(
                    icon: Icons.shield_outlined,
                    title: 'Data & Privacy',
                    onTap: () {},
                  ),
                  
                  _SettingsItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Version
                  Center(
                    child: Text(
                      'Sasmita Lens App $appVersion',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Bottom padding
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your lens & preferences',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
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
            child: const Icon(
              Icons.search,
              color: AppTheme.textPrimary,
              size: 24,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

/// Profile Card Widget
class _ProfileCard extends StatelessWidget {

  const _ProfileCard({required this.userProfile});
  final Map<String, dynamic> userProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage(userProfile['avatar']),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.statusSuccess,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.backgroundCard,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile['name'],
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  userProfile['membership'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryGreen,
                      ),
                ),
              ],
            ),
          ),
          
          // Edit Button
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }
}

/// Device Card Widget
class _DeviceCard extends StatelessWidget {

  const _DeviceCard({
    required this.isConnected,
    required this.batteryLevel,
  });
  final bool isConnected;
  final double batteryLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Device Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: AppTheme.primaryGreen,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Device Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sasmita Lens V2',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isConnected
                                ? AppTheme.statusSuccess
                                : AppTheme.statusError,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected ? 'CONNECTED' : 'DISCONNECTED',
                          style: TextStyle(
                            color: isConnected
                                ? AppTheme.statusSuccess
                                : AppTheme.statusError,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Battery Indicator
              SizedBox(
                width: 50,
                height: 50,
                child: CustomPaint(
                  painter: _BatteryRingPainter(
                    level: batteryLevel / 100,
                    color: _getBatteryColor(batteryLevel),
                  ),
                  child: Center(
                    child: Text(
                      '${batteryLevel.toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Last Sync & Manage Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAST SYNC',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 9,
                          color: AppTheme.textMuted,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Just now',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Manage',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Color _getBatteryColor(double level) {
    if (level >= 50) return AppTheme.statusSuccess;
    if (level >= 20) return AppTheme.accentYellow;
    return AppTheme.statusError;
  }
}

/// Battery Ring Painter
class _BatteryRingPainter extends CustomPainter {

  _BatteryRingPainter({
    required this.level,
    required this.color,
  });
  final double level;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = AppTheme.borderDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159 * level;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryRingPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.color != color;
  }
}

/// Section Title Widget
class _SectionTitle extends StatelessWidget {

  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 12,
            color: AppTheme.textMuted,
            letterSpacing: 1.5,
          ),
    );
  }
}

/// Settings Item Widget
class _SettingsItem extends StatelessWidget {

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
              )
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textMuted,
                  )
                : null),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
