import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/bluetooth_service.dart';
import '../utils/app_theme.dart';

/// Device Sync Screen — Bluetooth Real Connection
/// Menampilkan daftar perangkat BT, panel kontrol ESP32 setelah terhubung
class DeviceSyncScreen extends ConsumerStatefulWidget {
  const DeviceSyncScreen({super.key});

  @override
  ConsumerState<DeviceSyncScreen> createState() => _DeviceSyncScreenState();
}

class _DeviceSyncScreenState extends ConsumerState<DeviceSyncScreen> {
  StreamSubscription<ESP32Notifikasi>? _notifSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bluetoothManagerProvider).scanDevice();
      _listenNotif();
    });
  }

  void _listenNotif() {
    _notifSub = ref.read(bluetoothManagerProvider).notifStream.listen((notif) {
      if (!mounted) return;
      String msg = '';
      Color warna = AppTheme.primaryGreen;
      switch (notif.status) {
        case 'KALIBRASI':
          msg = '🔄 Kalibrasi baseline sedang berjalan...';
          warna = AppTheme.accentOrange;
          break;
        case 'SIAP':
          msg = '✅ Kalibrasi akustik selesai — siap scan';
          warna = AppTheme.statusSuccess;
          break;
        case 'TIDUR':
          msg = '😴 ESP32 memasuki mode tidur. Sentuh kawat GPIO32 untuk membangunkan.';
          warna = AppTheme.accentBlue;
          break;
        case 'SCANNING':
          msg = '🔬 ESP32 sedang mengukur buah...';
          warna = AppTheme.primaryGreen;
          break;
        case 'UV_ON':
          msg = '🔦 UV LED menyala';
          warna = AppTheme.accentOrange;
          break;
        case 'UV_OFF':
          msg = 'UV LED mati';
          warna = AppTheme.textMuted;
          break;
        case 'BLINK_DONE':
          msg = '✔️ Blink selesai';
          warna = AppTheme.primaryGreen;
          break;
      }
      if (msg.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),);
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _hubungkan(BluetoothDevice device) async {
    final bt    = ref.read(bluetoothManagerProvider);
    final ok    = await bt.hubungkan(device);
    if (!mounted) return;
    if (ok) {
      ref.read(deviceIdProvider.notifier).state = device.name ?? device.address;
      _showSnack('✅ Terhubung ke ${device.name}', sukses: true);
    } else {
      _showSnack('❌ Gagal terhubung. Coba lagi.', sukses: false);
    }
  }

  void _putuskan() {
    ref.read(bluetoothManagerProvider).putuskan();
    ref.read(deviceIdProvider.notifier).state = null;
  }

  void _showSnack(String msg, {required bool sukses}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: sukses ? AppTheme.statusSuccess : AppTheme.statusError,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),);
  }

  @override
  Widget build(BuildContext context) {
    final bt       = ref.watch(bluetoothManagerProvider);
    final terhubung = ref.watch(btTerhubungProvider);
    final deviceId  = ref.watch(deviceIdProvider);
    final data      = ref.watch(sensorDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox(),
        title: Column(
          children: [
            Text('PERANGKAT',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(letterSpacing: 3, fontSize: 13),),
            Text('SASMITA LENS',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppTheme.textMuted, fontSize: 10),),
          ],
        ),
        centerTitle: true,
        actions: [
          if (!terhubung)
            IconButton(
              onPressed: bt.sedangCari ? null : bt.scanDevice,
              icon: Icon(
                Icons.refresh_rounded,
                color: bt.sedangCari ? AppTheme.textMuted : AppTheme.primaryGreen,
              ),
              tooltip: 'Scan ulang',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Status icon
            _DeviceStatusIcon(terhubung: terhubung, sedangCari: bt.sedangCari)
                .animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // Status pesan
            Text(
              bt.statusPesan,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),

            const SizedBox(height: 28),

            // Panel utama
            if (terhubung)
              _PanelTerhubung(
                deviceId:   deviceId ?? 'SASMITA-LENS',
                dataSensor: data,
                onPutuskan: _putuskan,
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0)
            else
              _PanelDaftarDevice(
                daftarDevice: bt.daftarDevice,
                sedangCari:   bt.sedangCari,
                onHubungkan:  _hubungkan,
                onScanUlang:  bt.scanDevice,
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
            color: warna.withOpacity(0.07),
          ),
        ),
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: terhubung
                ? AppTheme.statusSuccess.withOpacity(0.15)
                : AppTheme.backgroundCard,
            border: Border.all(color: warna.withOpacity(0.3), width: 2),
          ),
          child: Icon(
            terhubung
                ? Icons.bluetooth_connected_rounded
                : sedangCari
                    ? Icons.bluetooth_searching_rounded
                    : Icons.bluetooth_rounded,
            color: warna,
            size: 42,
          ),
        )
            .animate(onPlay: (c) => sedangCari ? c.repeat(reverse: true) : null)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.06, 1.06),
              duration: 800.ms,
            ),
        Positioned(
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
                color: warna, borderRadius: BorderRadius.circular(12),),
            child: Text(
              terhubung
                  ? 'TERHUBUNG'
                  : sedangCari
                      ? 'MENCARI...'
                      : 'BLUETOOTH',
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,),
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
          Text('Perangkat Bluetooth Tersedia',
              style: Theme.of(context).textTheme.headlineSmall,),
          const SizedBox(height: 8),
          Text(
            'Pastikan ESP32 sudah menyala dan Bluetooth HP aktif.\n'
            'Pair "SASMITA-LENS" di Pengaturan Bluetooth terlebih dahulu.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.textMuted),
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
            _EmptyHint(onScanUlang: onScanUlang)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: daftarDevice.length,
              itemBuilder: (_, i) {
                final d = daftarDevice[i];
                final isSasmita = (d.name ?? '').contains('SASMITA');
                return _DeviceTile(
                  device: d,
                  isSasmita: isSasmita,
                  onTap: () => onHubungkan(d),
                );
              },
            ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 48,
            child: OutlinedButton.icon(
              onPressed: sedangCari ? null : onScanUlang,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: const BorderSide(color: AppTheme.primaryGreen),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Scan Ulang'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Tile satu device
// ─────────────────────────────────────────────
class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.isSasmita,
    required this.onTap,
  });
  final BluetoothDevice device;
  final bool isSasmita;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSasmita
            ? AppTheme.primaryGreen.withOpacity(0.08)
            : AppTheme.backgroundDarker,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSasmita
              ? AppTheme.primaryGreen.withOpacity(0.4)
              : AppTheme.borderDark,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.bluetooth_rounded,
          color: isSasmita ? AppTheme.primaryGreen : AppTheme.textMuted,
        ),
        title: Text(
          device.name ?? 'Unknown',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: isSasmita ? FontWeight.w700 : FontWeight.w400,),
        ),
        subtitle: Text(device.address,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),),
        trailing: isSasmita
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(8),),
                child: const Text('SASMITA',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,),),
              )
            : const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Hint saat tidak ada device
// ─────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.onScanUlang});
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
          const Icon(Icons.bluetooth_disabled_rounded,
              color: AppTheme.accentOrange, size: 40,),
          const SizedBox(height: 12),
          Text('Tidak ada perangkat ditemukan.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,),
          const SizedBox(height: 8),
          Text(
            '1. Nyalakan ESP32 SASMITA LENS\n'
            '2. Buka Pengaturan → Bluetooth\n'
            '3. Pair "SASMITA-LENS"\n'
            '4. Kembali ke sini dan tekan Scan Ulang',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Panel setelah terhubung — DATA + KONTROL
// ─────────────────────────────────────────────
class _PanelTerhubung extends ConsumerStatefulWidget {
  const _PanelTerhubung({
    required this.deviceId,
    required this.dataSensor,
    required this.onPutuskan,
  });
  final String deviceId;
  final SensorData? dataSensor;
  final VoidCallback onPutuskan;

  @override
  ConsumerState<_PanelTerhubung> createState() => _PanelTerhubungState();
}

class _PanelTerhubungState extends ConsumerState<_PanelTerhubung> {
  bool _loadingScan = false;
  bool _loadingKal = false;

  Future<void> _scan() async {
    setState(() => _loadingScan = true);
    final bt = ref.read(bluetoothManagerProvider);
    final ok = await bt.scan();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Gagal mengirim SCAN'),
        backgroundColor: AppTheme.statusError,
      ),);
    }
    // State akan diupdate oleh stream listener di parent
    if (mounted) setState(() => _loadingScan = false);
  }

  Future<void> _kalibrasi() async {
    setState(() => _loadingKal = true);
    // Ingatkan user untuk menutup sensor
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kalibrasi Akustik',
            style: TextStyle(color: AppTheme.textPrimary),),
        content: const Text(
          'Kalibrasi baseline akustik:\n\n'
          '• Jauhkan modul dari buah\n'
          '• Pastikan lingkungan tenang\n'
          '• Tekan OK untuk mulai',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal',
                style: TextStyle(color: AppTheme.textMuted),),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('OK, Mulai'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(bluetoothManagerProvider).kalibrasi();
    }
    if (mounted) setState(() => _loadingKal = false);
  }

  // _toggleUv dan _blink3x dihapus — tidak ada UV LED di versi akustik only

  Future<void> _tidur() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tidurkan ESP32?',
            style: TextStyle(color: AppTheme.textPrimary),),
        content: const Text(
          'ESP32 akan masuk Deep Sleep.\n\n'
          'Untuk membangunkan, sentuh kawat sensor sentuh (GPIO32) selama ±1 detik.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal',
                style: TextStyle(color: AppTheme.textMuted),),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tidurkan'),
          ),
        ],
      ),
    );
    if (konfirmasi ?? false) {
      await ref.read(bluetoothManagerProvider).tidur();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.dataSensor;

    return Column(
      children: [
        // ── Panel Data Sensor Live ─────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Column(
            children: [
              // Badge terhubung
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.statusSuccess.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.statusSuccess.withOpacity(0.3),),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.statusSuccess, size: 44,),
                    const SizedBox(height: 10),
                    Text(widget.deviceId,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,),
                    const SizedBox(height: 4),
                    const Text('TERHUBUNG',
                        style: TextStyle(
                            color: AppTheme.statusSuccess,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            fontSize: 11,),),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Data sensor live
              if (data != null) ...[
                Text('Data Live dari Sensor',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.textSecondary),),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SensorCard(
                        label: 'Amplitudo Mic',
                        sublabel: 'MAX9814 (ADC p-p)',
                        nilai: data.ampRaw.toString(),
                        ikon: Icons.graphic_eq_rounded,
                        warna: data.isAmpValid ? AppTheme.accentBlue : AppTheme.statusError,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SensorCard(
                        label: 'Gema Akustik',
                        sublabel: 'MAX9814',
                        nilai: data.gemaAkustik.toString(),
                        ikon: Icons.graphic_eq_rounded,
                        warna: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDarker,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(data.emoji,
                          style: const TextStyle(fontSize: 28),),
                      const SizedBox(height: 6),
                      Text(data.labelKondisi,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),),
                      Text('Tahan simpan: ${data.bestBefore}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textMuted),),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                const Text('Menunggu data dari ESP32...',
                    style: TextStyle(color: AppTheme.textMuted),),
                const SizedBox(height: 8),
                const LinearProgressIndicator(
                  color: AppTheme.primaryGreen,
                  backgroundColor: AppTheme.backgroundDarker,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Panel Kontrol ESP32 ────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.backgroundCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded,
                      color: AppTheme.primaryGreen, size: 18,),
                  const SizedBox(width: 8),
                  Text('Kontrol ESP32',
                      style: Theme.of(context).textTheme.titleLarge,),
                ],
              ),
              const SizedBox(height: 16),

              // Tombol SCAN
              _KontrolTombol(
                ikon: Icons.document_scanner_rounded,
                label: 'Scan Buah',
                sublabel: 'Kirim perintah SCAN ke ESP32',
                warna: AppTheme.primaryGreen,
                loading: _loadingScan,
                onTap: _loadingScan ? null : _scan,
              ),
              const SizedBox(height: 10),

              // Tombol KALIBRASI
              _KontrolTombol(
                ikon: Icons.tune_rounded,
                label: 'Kalibrasi Akustik',
                sublabel: 'Reset referensi akustik baseline',
                warna: AppTheme.accentOrange,
                loading: _loadingKal,
                onTap: _loadingKal ? null : _kalibrasi,
              ),
              const SizedBox(height: 16),

              // Kontrol Streaming & Sleep
              Text('Kontrol Lanjutan',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.textMuted, fontSize: 11),),
              const SizedBox(height: 8),
              Row(
                children: [
                  // STREAM ON
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ref.read(bluetoothManagerProvider).streamOn(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12,),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.primaryGreen.withOpacity(0.4),),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.waves_rounded,
                                color: AppTheme.primaryGreen, size: 24,),
                            SizedBox(height: 4),
                            Text('STREAM',
                                style: TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,),),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // STREAM OFF
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ref.read(bluetoothManagerProvider).streamOff(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12,),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundDarker,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.stop_circle_outlined,
                                color: AppTheme.textMuted, size: 24,),
                            SizedBox(height: 4),
                            Text('STOP',
                                style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,),),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // TIDUR
                  Expanded(
                    child: GestureDetector(
                      onTap: _tidur,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12,),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundDarker,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.accentBlue.withOpacity(0.4),),
                        ),
                        child: const Column(
                          children: [
                            Text('😴', style: TextStyle(fontSize: 22)),
                            SizedBox(height: 4),
                            Text('TIDUR',
                                style: TextStyle(
                                    color: AppTheme.accentBlue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,),),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Tombol Putus Koneksi ───────────────────────────
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: widget.onPutuskan,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.statusError,
              side: const BorderSide(color: AppTheme.statusError),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),),
            ),
            icon: const Icon(Icons.bluetooth_disabled_rounded, size: 18),
            label: const Text('Putuskan Koneksi',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Tombol kontrol besar
// ─────────────────────────────────────────────
class _KontrolTombol extends StatelessWidget {
  const _KontrolTombol({
    required this.ikon,
    required this.label,
    required this.sublabel,
    required this.warna,
    this.loading = false,
    this.onTap,
  });
  final IconData ikon;
  final String label;
  final String sublabel;
  final Color warna;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: warna.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: warna.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: warna.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: loading
                    ? SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: warna, strokeWidth: 2.5,),)
                    : Icon(ikon, color: warna, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: warna,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,),),
                    const SizedBox(height: 2),
                    Text(sublabel,
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11,),),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: warna.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widget: Kartu nilai sensor
// ─────────────────────────────────────────────
class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.label,
    required this.sublabel,
    required this.nilai,
    required this.ikon,
    required this.warna,
  });
  final String label;
  final String sublabel;
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
          Text(nilai,
              style: TextStyle(
                  color: warna, fontWeight: FontWeight.w800, fontSize: 22,),),
          Text(label,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),),
          Text(sublabel,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
              textAlign: TextAlign.center,),
        ],
      ),
    );
  }
}
