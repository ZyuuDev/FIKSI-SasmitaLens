import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import '../screens/raw_data_screen.dart';

/// Settings Screen
/// Berisi informasi profil pengguna, informasi alat Sasmita Lens,
/// pengaturan umum, dan kalibrasi ambang batas sensor secara real-time.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final deviceStatus = ref.watch(deviceStatusProvider);
    final isDeviceConnected = deviceStatus['terhubung'] as bool? ?? false;
    final batteryVal = deviceStatus['baterai'] as int? ?? -1;
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final appVersion = ref.watch(appVersionProvider);

    // Thresholds akustik — tidak ada UV
    final akustikPadatMin = ref.watch(akustikPadatMinProvider);
    final akustikLunakMax = ref.watch(akustikLunakMaxProvider);
    final ampMinValid     = ref.watch(ampMinValidProvider);

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
            
            // Konten
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  
                  // Kartu Profil Pengguna
                  _ProfileCard(userProfile: userProfile),
                  
                  const SizedBox(height: 20),
                  
                  // Kartu Informasi Perangkat Sasmita Lens
                  _DeviceCard(
                    isConnected: isDeviceConnected,
                    batteryLevel: batteryVal,
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // Bagian Ambang Batas Sensor (Kalibrasi Lanjutan)
                  const _SectionTitle(title: 'KALIBRASI AMBANG BATAS SENSOR'),
                  const SizedBox(height: 12),
                  _buildThresholdSettingsCard(
                    context,
                    ref,
                    akustikPadatMin: akustikPadatMin,
                    akustikLunakMax: akustikLunakMax,
                    ampMinValid: ampMinValid,
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // Pengaturan Umum
                  const _SectionTitle(title: 'PENGATURAN UMUM'),
                  const SizedBox(height: 12),
                  
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifikasi Suara & Getar',
                    trailing: Switch(
                      value: notificationsEnabled,
                      onChanged: (value) {
                        ref.read(notificationsEnabledProvider.notifier).state = value;
                      },
                      activeThumbColor: AppTheme.primaryGreen,
                    ),
                  ),
                  
                  _SettingsItem(
                    icon: Icons.palette_outlined,
                    title: 'Tema Aplikasi',
                    subtitle: 'Mode Gelap (Bawaan)',
                    onTap: () {},
                  ),

                  _SettingsItem(
                    icon: Icons.terminal_outlined,
                    title: 'Mode Bebas Scan (Raw Data)',
                    subtitle: 'Monitor serial ESP32',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RawDataScreen()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Info & Bantuan
                  const _SectionTitle(title: 'BANTUAN & INFORMASI'),
                  const SizedBox(height: 12),
                  
                  _SettingsItem(
                    icon: Icons.shield_outlined,
                    title: 'Kebijakan Privasi Data',
                    onTap: () {},
                  ),
                  
                  _SettingsItem(
                    icon: Icons.help_outline,
                    title: 'Pusat Bantuan & Panduan',
                    onTap: () {},
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Versi Aplikasi
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Sasmita Lens App $appVersion',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textMuted,
                              ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'SMK Negeri 1 Bantul • FIKSI 2026',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                'Pengaturan',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kelola kalibrasi & profil alat Anda',
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
              Icons.settings_suggest,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildThresholdSettingsCard(
    BuildContext context,
    WidgetRef ref, {
    required int akustikPadatMin,
    required int akustikLunakMax,
    required int ampMinValid,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info kalibrasi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryGreen, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kalibrasi dengan buah nyata: dekatkan modul ke buah keras (mentah) dan lunak (matang), lalu catat nilai FREQ dari Raw Monitor.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Slider 1: Batas Akustik Keras (FREQ_KERAS_MIN)
          _buildSliderItem(
            context: context,
            title: 'FREQ Keras Min',
            subtitle: 'Frekuensi akustik ≥ ini → Buah keras / belum matang',
            value: akustikPadatMin.toDouble(),
            min: 100,
            max: 1800,
            unit: ' Hz',
            color: AppTheme.primaryGreen,
            onChanged: (val) {
              ref.read(akustikPadatMinProvider.notifier).state = val.toInt();
            },
          ),
          const SizedBox(height: 18),

          // Slider 2: Batas Akustik Lunak (FREQ_LUNAK_MAX)
          _buildSliderItem(
            context: context,
            title: 'FREQ Lunak Max',
            subtitle: 'Frekuensi akustik ≤ ini → Buah lunak / matang',
            value: akustikLunakMax.toDouble(),
            min: 50,
            max: 600,
            unit: ' Hz',
            color: AppTheme.accentOrange,
            onChanged: (val) {
              ref.read(akustikLunakMaxProvider.notifier).state = val.toInt();
            },
          ),
          const SizedBox(height: 18),

          // Slider 3: Amplitudo Minimum Valid (AMP_BUSUK_MAX)
          _buildSliderItem(
            context: context,
            title: 'AMP Minimum Valid',
            subtitle: 'Amplitudo mic ≤ ini → Sinyal tidak valid / indikasi busuk',
            value: ampMinValid.toDouble(),
            min: 5,
            max: 100,
            unit: '',
            color: AppTheme.statusError,
            onChanged: (val) {
              ref.read(ampMinValidProvider.notifier).state = val.toInt();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required String unit,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            Text(
              '${value.toInt()}$unit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: AppTheme.borderDark,
            thumbColor: color,
            overlayColor: color.withOpacity(0.15),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Kartu Informasi Profil Pengguna
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
          // Inisial Nama Pengguna jika tidak ada avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
                child: Text(
                  userProfile['name'][0].toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
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
          
          // Informasi Pengguna
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile['name'],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  userProfile['membership'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  userProfile['email'],
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          
          // Tombol Edit Profil
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

/// Kartu Detail Alat Sasmita Lens
class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.isConnected,
    required this.batteryLevel,
  });

  final bool isConnected;
  final int batteryLevel; // -1 jika tidak ada pembagi tegangan

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
              // Icon Alat
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
              
              // Info Hubungan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SASMITA LENS v4',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                          isConnected ? 'TERKONEKSI' : 'TERPUTUS',
                          style: TextStyle(
                            color: isConnected
                                ? AppTheme.statusSuccess
                                : AppTheme.statusError,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Persentase Baterai
              if (isConnected)
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CustomPaint(
                    painter: _BatteryRingPainter(
                      level: batteryLevel >= 0 ? batteryLevel / 100.0 : 0.0,
                      color: batteryLevel >= 0 ? _getBatteryColor(batteryLevel.toDouble()) : AppTheme.textMuted,
                      hasBattery: batteryLevel >= 0,
                    ),
                    child: Center(
                      child: Text(
                        batteryLevel >= 0 ? '$batteryLevel%' : '—',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Sinkronisasi Terakhir
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SINKRONISASI TERAKHIR',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 9,
                          color: AppTheme.textMuted,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected ? 'Baru saja' : 'Belum sinkron',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              
              // Indikator firmware
              const Text(
                'Firmware: v4.0 Akustik',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
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

/// Painter Cincin Baterai
class _BatteryRingPainter extends CustomPainter {
  _BatteryRingPainter({
    required this.level,
    required this.color,
    required this.hasBattery,
  });

  final double level;
  final Color color;
  final bool hasBattery;

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

    if (hasBattery) {
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
  }

  @override
  bool shouldRepaint(covariant _BatteryRingPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.color != color || oldDelegate.hasBattery != hasBattery;
  }
}

/// Teks Judul Seksi Pengaturan
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 11,
            color: AppTheme.textMuted,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

/// Item Daftar Pengaturan
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
            color: AppTheme.primaryGreen.withOpacity(0.12),
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
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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
