import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import '../widgets/circular_progress.dart';
import '../widgets/recent_scan_card.dart';
import 'scan_screen.dart';

/// Home Screen
/// Menampilkan ringkasan status perangkat Sasmita Lens, metrik analisis,
/// dan riwayat pemindaian terbaru untuk petani/operator lokal.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceStatus = ref.watch(deviceStatusProvider);
    final recentScans = ref.watch(recentScansProvider);
    final userProfile = ref.watch(userProfileProvider);
    final stats = ref.watch(statsRiwayatProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar / Header Teks
            SliverToBoxAdapter(
              child: _buildAppBar(context, userProfile),
            ),
            
            // Konten Utama
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  
                  // Kartu Status Perangkat & Sensor Terakhir
                  _DeviceStatusCard(deviceStatus: deviceStatus),
                  
                  const SizedBox(height: 24),
                  
                  // Statistik Ringkasan Pengukuran
                  _buildStatsTitle(context),
                  const SizedBox(height: 16),
                  _buildMetricsRow(context, stats),
                  
                  const SizedBox(height: 28),
                  
                  // Header Riwayat Scan
                  _buildSectionHeader(context, 'Riwayat Pemindaian', 'Lihat Semua', ref),
                  
                  const SizedBox(height: 12),
                  
                  // Daftar Scan Terbaru
                  if (recentScans.isEmpty)
                    _buildEmptyState(context)
                  else
                    ...recentScans.map((scan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RecentScanCard(scan: scan),
                    ),),
                  
                  const SizedBox(height: 100), // Bottom padding untuk navigasi
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
                'Halo, Selamat Datang 👋',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                userProfile['name'],
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${userProfile['sekolah']} | ${userProfile['proyek']}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.primaryGreen,
                  letterSpacing: 0.5,
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

  Widget _buildStatsTitle(BuildContext context) {
    return Text(
      'Ringkasan Kualitas Panen',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, Map<String, int> stats) {
    final total = stats['total'] ?? 0;
    final segar = stats['segar_padat'] ?? 0;
    final busuk = stats['indikasi_busuk'] ?? 0;
    
    final persentaseSegar = total > 0 ? segar / total : 0.0;
    final persentaseSehat = total > 0 ? (total - busuk) / total : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CircularProgressWidget(
          value: total > 0 ? 1.0 : 0.0,
          displayValue: '$total',
          label: 'Total Pindai',
          sublabel: 'BUAH',
          color: AppTheme.primaryGreen,
        ),
        CircularProgressWidget(
          value: persentaseSegar,
          displayValue: total > 0 ? '${(persentaseSegar * 100).toInt()}%' : '0%',
          label: 'Kondisi Segar',
          sublabel: 'GRADE A+',
          color: AppTheme.accentYellow,
        ),
        CircularProgressWidget(
          value: persentaseSehat,
          displayValue: total > 0 ? '${(persentaseSehat * 100).toInt()}%' : '0%',
          label: 'Kelayakan Buah',
          sublabel: 'AMAN SIMPAN',
          color: AppTheme.statusSuccess,
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String action,
    WidgetRef ref,
  ) {
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
          onPressed: () {
            // Pindah ke tab Leaderboard (index 2 di PageView/main layout)
            // Di main_layout, PageView memiliki 4 halaman: Home(0), Device(1), Leaderboard(2), Settings(3)
            ref.read(pageControllerProvider).animateToPage(
                  2,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
          },
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

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: AppTheme.primaryGreen.withOpacity(0.6),
              size: 48,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.08, 1.08),
                duration: 2.seconds,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Riwayat Pemindaian',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sambungkan Sasmita Lens dan lakukan pemindaian buah pertama Anda untuk melihat kualitas di sini.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Buka scan sheet modal
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ScanScreen(),
              );
            },
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
            label: const Text(
              'Mulai Scan Sekarang',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

/// Kartu Informasi Status Perangkat & Hasil Pembacaan Terakhir
class _DeviceStatusCard extends ConsumerWidget {
  const _DeviceStatusCard({required this.deviceStatus});

  final Map<String, dynamic> deviceStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool terhubung = deviceStatus['terhubung'] as bool? ?? false;
    final int uv = deviceStatus['uvTerakhir'] as int? ?? 0;
    final int akustik = deviceStatus['akustikTerakhir'] as int? ?? 0;
    final String kondisi = deviceStatus['kondisiTerakhir'] as String? ?? '—';
    final String statusKode = deviceStatus['statusTerakhir'] as String? ?? '';
    
    Color statusColor = AppTheme.statusError;
    if (terhubung) {
      statusColor = AppTheme.statusSuccess;
    }

    Color kondisiColor = AppTheme.textMuted;
    if (statusKode == 'SEGAR_PADAT') kondisiColor = AppTheme.statusSuccess;
    if (statusKode == 'BELUM_MATANG') kondisiColor = AppTheme.accentOrange;
    if (statusKode == 'MATANG_LUNAK') kondisiColor = AppTheme.statusWarning;
    if (statusKode == 'INDIKASI_BUSUK') kondisiColor = AppTheme.statusError;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Koneksi
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS KONEKSI ALAT',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          terhubung ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                          color: statusColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          terhubung ? 'Sasmita Lens Aktif' : 'Perangkat Terputus',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        terhubung ? 'TERHUBUNG' : 'MATI',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider tipis
          Container(
            height: 1,
            color: AppTheme.borderDark,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),

          if (!terhubung)
            // Tampilan jika terputus
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Hubungkan Sasmita Lens via Bluetooth untuk membaca data pantulan UV (GUVA-S12SD) & resonansi akustik (MAX9814) secara real-time.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Lompat ke tab DeviceSync
                        ref.read(pageControllerProvider).animateToPage(
                              1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.backgroundDarker,
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.borderDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Sambungkan Bluetooth Sekarang',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Tampilan data pengukuran terakhir jika terhubung
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PENGUKURAN TERAKHIR',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                          letterSpacing: 1,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SensorValueWidget(
                          label: 'Pantulan UV',
                          value: uv > 0 ? '$uv' : '—',
                          unit: 'GUVA-S12SD',
                          icon: Icons.lightbulb_outline,
                          color: AppTheme.accentYellow,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SensorValueWidget(
                          label: 'Resonansi Suara',
                          value: akustik > 0 ? '$akustik' : '—',
                          unit: 'Hz (MAX9814)',
                          icon: Icons.hearing_outlined,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundDarker,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kondisi Buah:',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              kondisi,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: kondisiColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Buka scan modal
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const ScanScreen(),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                      label: const Text(
                        'Pindai Buah Baru',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.2, end: 0);
  }
}

/// Widget kecil menampilkan nilai sensor terakhir di dalam kartu
class _SensorValueWidget extends StatelessWidget {
  const _SensorValueWidget({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDarker,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
