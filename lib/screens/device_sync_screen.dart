import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/bluetooth_service.dart';
import '../utils/app_theme.dart';

/// Device Sync Screen — Bluetooth Real Connection
/// Menggantikan input Device ID manual dengan scan Bluetooth nyata ke ESP32
class DeviceSyncScreen extends ConsumerStatefulWidget {
  const DeviceSyncScreen({super.key});

  @override
  ConsumerState<DeviceSyncScreen> createState() => _DeviceSyncScreenState();
}

class _DeviceSyncScreenState extends ConsumerState<DeviceSyncScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-scan saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bluetoothManagerProvider).scanDevice();
    });
  }

  Future<void> _hubungkanDevice(BluetoothDevice device) async {
    final btManager = ref.read(bluetoothManagerProvider);
    final berhasil  = await btManager.hubungkan(device);

    if (!mounted) return;

    if (berhasil) {
      ref.read(isDeviceConnectedProvider.notifier).state = true;
      ref.read(deviceIdProvider.notifier).state = device.name ?? device.address;
      _tampilSnackbar('✅ Terhubung ke ${device.name}', sukses: true);
    } else {
      _tampilSnackbar('❌ Gagal terhubung. Coba lagi.', sukses: false);
    }
  }

  void _putuskan() {
    ref.read(bluetoothManagerProvider).putuskan();
    ref.read(isDeviceConnectedProvider.notifier).state = false;
    ref.read(deviceIdProvider.notifier).state = null;
  }

  void _tampilSnackbar(String pesan, {required bool sukses}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: sukses ? AppTheme.statusSuccess : AppTheme.statusError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final btManager   = ref.watch(bluetoothManagerProvider);
    final terhubung   = ref.watch(btTerhubungProvider);
    final deviceId    = ref.watch(deviceIdProvider);
    final dataSensor  = ref.watch(sensorDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox(),
        title: Text(
          'SASMITA LENS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 3),
        ),
        centerTitle: true,
        actions: [
          if (!terhubung)
            IconButton(
              onPressed: btManager.sedangCari ? null : () => btManager.scanDevice(),
              icon: Icon(
                Icons.refresh,
                color: btManager.sedangCari ? AppTheme.textMuted : AppTheme.primaryGreen,
              ),
              tooltip: 'Scan ulang',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Status icon
            _DeviceStatusIcon(terhubung: terhubung, sedangCari: btManager.sedangCari)
                .animate()
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // Status pesan
            Text(
              btManager.statusPesan,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),

            const SizedBox(height: 32),

            // Konten berdasarkan state
            if (terhubung)
              _PanelTerhubung(
                deviceId:   deviceId ?? 'SASMITA-LENS',
                dataSensor: dataSensor,
                onPutuskan: _putuskan,
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0)
            else
              _PanelDaftarDevice(
                daftarDevice:    btManager.daftarDevice,
                sedangCari:      btManager.sedangCari,
                onHubungkan:     _hubungkanDevice,
                onScanUlang:     btManager.scanDevice,
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Ikon status perangkat
// ─────────────────────────────────────────────
class _DeviceStatusIcon extends StatelessWidget {
  const _DeviceStatusIcon({required this.terhubung, required this.sedangCari});
  final bool terhubung;
  final bool sedangCari;

  @override
  Widget build(BuildContext context) {
    final warna = terhubung ? AppTheme.statusSuccess : AppTheme.primaryGreen;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140, height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: warna.withOpacity(0.08),
          ),
        ),
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: terhubung ? AppTheme.statusSuccess.withOpacity(0.15) : AppTheme.backgroundCard,
            border: Border.all(color: warna.withOpacity(0.3), width: 2),
          ),
          child: Icon(
            terhubung
                ? Icons.bluetooth_connected
                : sedangCari
                    ? Icons.bluetooth_searching
                    : Icons.bluetooth,
            color: warna,
            size: 40,
          ),
        )
            .animate(onPlay: (c) => sedangCari ? c.repeat(reverse: true) : null)
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.05, 1.05),
              duration: 800.ms,
            ),
        Positioned(
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: warna,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              terhubung ? 'CONNECTED' : sedangCari ? 'SCANNING...' : 'BLUETOOTH',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Panel daftar device (belum terhubung)
// ─────────────────────────────────────────────
class _PanelDaftarDevice extends StatelessWidget {
  const _PanelDaftarDevice({
    required this.daftarDevice,
    required this.sedangCari,
    required this.onHubungkan,
    required this.onScanUlang,
  });
  final List<BluetoothDevice> daftarDevice;
  final bool sedangCari;
  final Future<void> Function(BluetoothDevice) onHubungkan;
  final Future<void> Function() onScanUlang;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perangkat Bluetooth Tersedia',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Pastikan ESP32 sudah menyala dan Bluetooth HP aktif.\n'
            'Pair "SASMITA-LENS" di Pengaturan Bluetooth terlebih dahulu.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
          ),
          const SizedBox(height: 20),

          if (sedangCari)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            )
          else if (daftarDevice.isEmpty)
            _EmptyDeviceHint(onScanUlang: onScanUlang)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: daftarDevice.length,
              itemBuilder: (ctx, i) {
                final device = daftarDevice[i];
                final adalahSasmita = (device.name ?? '').contains('SASMITA');
                return _DeviceListTile(
                  device:        device,
                  adalahSasmita: adalahSasmita,
                  onTap:         () => onHubungkan(device),
                );
              },
            ),

          const SizedBox(height: 16),

          // Tombol scan ulang
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: sedangCari ? null : onScanUlang,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: const BorderSide(color: AppTheme.primaryGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Scan Ulang'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Tile satu device Bluetooth
// ─────────────────────────────────────────────
class _DeviceListTile extends StatelessWidget {
  const _DeviceListTile({
    required this.device,
    required this.adalahSasmita,
    required this.onTap,
  });
  final BluetoothDevice device;
  final bool adalahSasmita;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: adalahSasmita
            ? AppTheme.primaryGreen.withOpacity(0.08)
            : AppTheme.backgroundDarker,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: adalahSasmita ? AppTheme.primaryGreen.withOpacity(0.4) : AppTheme.borderDark,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.bluetooth,
          color: adalahSasmita ? AppTheme.primaryGreen : AppTheme.textMuted,
        ),
        title: Text(
          device.name ?? 'Unknown Device',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: adalahSasmita ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        subtitle: Text(
          device.address,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
        trailing: adalahSasmita
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SASMITA',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : const Icon(Icons.chevron_right, color: AppTheme.textMuted),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Hint saat tidak ada device
// ─────────────────────────────────────────────
class _EmptyDeviceHint extends StatelessWidget {
  const _EmptyDeviceHint({required this.onScanUlang});
  final Future<void> Function() onScanUlang;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentOrange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.bluetooth_disabled, color: AppTheme.accentOrange, size: 40),
          const SizedBox(height: 12),
          Text(
            'Tidak ada perangkat ditemukan.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '1. Nyalakan ESP32 SASMITA LENS\n'
            '2. Buka Pengaturan → Bluetooth\n'
            '3. Pair perangkat "SASMITA-LENS"\n'
            '4. Kembali ke sini dan scan ulang',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Panel setelah terhubung
// ─────────────────────────────────────────────
class _PanelTerhubung extends StatelessWidget {
  const _PanelTerhubung({
    required this.deviceId,
    required this.dataSensor,
    required this.onPutuskan,
  });
  final String deviceId;
  final SensorData? dataSensor;
  final VoidCallback onPutuskan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          // Badge terhubung
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.statusSuccess.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.statusSuccess.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.statusSuccess, size: 48),
                const SizedBox(height: 12),
                Text(deviceId,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                const Text('CONNECTED',
                    style: TextStyle(
                      color: AppTheme.statusSuccess,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      fontSize: 12,
                    )),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Live data dari ESP32
          if (dataSensor != null) ...[
            Text('Data Live dari Sensor',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SensorCard(
                    label: 'UV Fluoresensi',
                    nilai: dataSensor!.uvAktual.toString(),
                    ikon: Icons.wb_sunny,
                    warna: AppTheme.accentOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SensorCard(
                    label: 'Gema Akustik',
                    nilai: dataSensor!.gemaAkustik.toString(),
                    ikon: Icons.graphic_eq,
                    warna: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDarker,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _statusToEmoji(dataSensor!.status),
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statusToLabel(dataSensor!.status),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Skor Kualitas: ${dataSensor!.score}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            const SizedBox(height: 12),
            const Text(
              'Menunggu data dari ESP32...',
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            const LinearProgressIndicator(
              color: AppTheme.primaryGreen,
              backgroundColor: AppTheme.backgroundDarker,
            ),
            const SizedBox(height: 20),
          ],

          // Tombol putuskan
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onPutuskan,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.statusError,
                side: const BorderSide(color: AppTheme.statusError),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              child: const Text('Putuskan Koneksi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _statusToEmoji(String s) {
    switch (s) {
      case 'SEGAR_PADAT':    return '✅';
      case 'MATANG_LUNAK':   return '⚠️';
      case 'BELUM_MATANG':   return '🟡';
      case 'INDIKASI_BUSUK': return '❌';
      default:               return '🔍';
    }
  }

  String _statusToLabel(String s) {
    switch (s) {
      case 'SEGAR_PADAT':    return 'Segar & Padat';
      case 'MATANG_LUNAK':   return 'Matang / Lunak';
      case 'BELUM_MATANG':   return 'Belum Matang';
      case 'INDIKASI_BUSUK': return 'Indikasi Busuk';
      default:               return 'Tidak Diketahui';
    }
  }
}

// ─────────────────────────────────────────────
//  Widget: Kartu nilai sensor kecil
// ─────────────────────────────────────────────
class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.label,
    required this.nilai,
    required this.ikon,
    required this.warna,
  });
  final String label;
  final String nilai;
  final IconData ikon;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warna.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warna.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(ikon, color: warna, size: 24),
          const SizedBox(height: 6),
          Text(
            nilai,
            style: TextStyle(
              color: warna,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
