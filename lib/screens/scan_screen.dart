import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/app_providers.dart';
import '../providers/bluetooth_service.dart';
import '../providers/fruit_ai_service.dart';
import '../utils/app_theme.dart';
import '../widgets/scanning_reticle.dart';

/// Scan Screen — Mengirim perintah SCAN ke ESP32, lalu tampilkan hasil
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  bool _isScanning = false;
  StreamSubscription<SensorData>? _sub;
  String _scanMsg = '';

  final FruitAiService _ai = FruitAiService();
  bool _aiReady = false;
  HasilAI? _hasilAI;

  @override
  void initState() {
    super.initState();
    // Muat model AI (jika ada). App tetap jalan walau model belum tersedia.
    _ai.load().then((_) {
      if (mounted) setState(() => _aiReady = true);
    }).catchError((Object e) {
      debugPrint('[AI] Model belum siap (mode sensor-only): $e');
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ai.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    final btManager = ref.read(bluetoothManagerProvider);

    if (!btManager.terhubung) {
      _showSnack('⚠️ Hubungkan ESP32 SASMITA LENS dulu di tab Perangkat',
          warna: AppTheme.accentOrange,);
      return;
    }

    setState(() {
      _isScanning = true;
      _scanMsg    = 'Mengirim perintah ke ESP32...';
    });

    // ── Langkah 1: Kamera + AI (opsional, jika model siap) ──
    _hasilAI = null;
    if (_aiReady) {
      setState(() => _scanMsg = '📷 Memotret buah untuk AI...');
      try {
        _hasilAI = await _scanKamera();
      } on Exception catch (e) {
        debugPrint('[AI] Gagal klasifikasi: $e');
      }
      if (!mounted) return;
    }

    // ── Langkah 2: Kirim perintah SCAN ke ESP32 ──
    setState(() => _scanMsg = 'Mengirim perintah ke ESP32...');
    final terkirim = await btManager.scan();
    if (!terkirim) {
      setState(() { _isScanning = false; _scanMsg = ''; });
      _showSnack('❌ Gagal mengirim perintah. Periksa koneksi.', warna: AppTheme.statusError);
      return;
    }

    setState(() { _scanMsg = '🔬 Mengukur... 5 impuls akustik + fluoresensi BH1750'; });

    // Tunggu respons JSON dari ESP32 (maks 8 detik)
    final completer = Completer<SensorData?>();
    _sub?.cancel();
    _sub = btManager.dataStream.listen((data) {
      if (!completer.isCompleted && data.isHasilScan) {
        completer.complete(data);
      }
    });

    // Timeout 12 detik (5-shot akustik ~2.5 detik + fluoresensi ~0.5 detik + margin)
    Future.delayed(const Duration(seconds: 12), () {
      if (!completer.isCompleted) completer.complete(null);
    });

    final hasil = await completer.future;
    _sub?.cancel();

    if (!mounted) return;

    setState(() { _isScanning = false; _scanMsg = ''; });

    if (hasil != null) {
      // Simpan ke riwayat
      ref.read(scanHistoryProvider.notifier).tambahScan(hasil);
      _showResultSheet(hasil);
    } else {
      _showSnack('⏱️ Timeout. Coba scan lagi.', warna: AppTheme.statusWarning);
    }
  }

  void _showSnack(String msg, {Color? warna}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: warna ?? AppTheme.backgroundCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<HasilAI?> _scanKamera() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 640,
    );
    if (x == null) return null;
    return _ai.klasifikasi(File(x.path));
  }

  void _showResultSheet(SensorData hasil) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScanResultSheet(hasil: hasil, ai: _hasilAI),
    );
  }

  @override
  Widget build(BuildContext context) {
    final terhubung = ref.watch(btTerhubungProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // ── Handle bar ───────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44, height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.textPrimary, size: 20,),
                ),
                Column(
                  children: [
                    Text('SCAN BUAH',
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(letterSpacing: 3, fontSize: 13),),
                    Text('SASMITA LENS',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppTheme.textMuted, fontSize: 10),),
                  ],
                ),
                IconButton(
                  onPressed: () => _showPanduanDialog(context),
                  icon: const Icon(Icons.info_outline_rounded,
                      color: AppTheme.textMuted, size: 20,),
                ),
              ],
            ),
          ),

          // ── Camera / Sensor View ─────────────────────────
          Expanded(
            child: Stack(
              children: [
                // Background visual sensor
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.backgroundDarker,
                        AppTheme.primaryGreen.withOpacity(0.04),
                      ],
                    ),
                    border: Border.all(
                      color: _isScanning
                          ? AppTheme.primaryGreen.withOpacity(0.5)
                          : AppTheme.borderDark,
                      width: _isScanning ? 1.5 : 1,
                    ),
                  ),
                ),

                // UV Glow effect saat scanning
                if (_isScanning)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6A00FF).withOpacity(0.18),
                          Colors.transparent,
                        ],
                        radius: 0.7,
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .fadeIn(duration: 800.ms)
                   .fadeOut(duration: 800.ms),

                // Scanning Reticle
                const Center(child: ScanningReticle()),

                // Status badge atas
                Positioned(
                  top: 36, left: 0, right: 0,
                  child: Center(
                    child: _StatusBadge(
                      isScanning: _isScanning,
                      terhubung: terhubung,
                      scanMsg: _scanMsg,
                    ),
                  ),
                ),

                // Sensor type badge
                Positioned(
                  top: 96, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6,),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.primaryGreen.withOpacity(0.5),),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sensors, color: AppTheme.primaryGreen, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'AKUSTIK + FLUORESENSI BH1750',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Petunjuk di tengah-bawah view
                if (!_isScanning)
                  Positioned(
                    bottom: 32, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8,),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          terhubung
                              ? 'Tempelkan sensor ke permukaan buah\nlalu tekan tombol SCAN'
                              : 'Hubungkan ESP32 di tab Perangkat dulu',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Sensor Value Preview (jika sudah ada data) ────
          _SensorPreviewBar(),

          // ── Tombol SCAN ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: (_isScanning || !terhubung) ? null : _startScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: terhubung
                      ? AppTheme.primaryGreen
                      : AppTheme.backgroundCard,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor:
                      AppTheme.primaryGreen.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),),
                  elevation: 0,
                ),
                child: _isScanning
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black.withOpacity(0.7),
                              strokeWidth: 2.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(_scanMsg.isEmpty ? 'Scanning...' : 'Mengukur...',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600,),),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            terhubung
                                ? Icons.document_scanner_rounded
                                : Icons.bluetooth_disabled_rounded,
                            size: 22,
                            color: terhubung ? Colors.black : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            terhubung ? 'Scan Buah Sekarang' : 'Hubungkan Dulu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: terhubung ? Colors.black : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPanduanDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cara Scan Buah',
            style: TextStyle(color: AppTheme.textPrimary),),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanduanItem(no: '1', teks: 'Pastikan ESP32 terhubung via Bluetooth'),
            _PanduanItem(no: '2', teks: 'Tempelkan kepala corong sensor rapat ke permukaan buah'),
            _PanduanItem(no: '3', teks: 'Tekan SCAN — ESP32 akan tembak 5 impuls akustik + ukur fluoresensi (~3 detik)'),
            _PanduanItem(no: '4', teks: 'Tunggu hasil + confidence score muncul di layar'),
            _PanduanItem(no: '5', teks: 'Confidence ≥ 70% = data andal. Jika rendah, tempelkan lebih rapat lalu scan ulang'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: const Text('Mengerti', style: TextStyle(color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }
}

class _PanduanItem extends StatelessWidget {
  const _PanduanItem({required this.no, required this.teks});
  final String no;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(no,
                style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,),),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(teks,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13,),),
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.isScanning,
    required this.terhubung,
    required this.scanMsg,
  });
  final bool isScanning;
  final bool terhubung;
  final String scanMsg;

  @override
  Widget build(BuildContext context) {
    final Color warna = isScanning
        ? AppTheme.accentOrange
        : terhubung
            ? AppTheme.primaryGreen
            : AppTheme.statusError;
    final String label = isScanning
        ? (scanMsg.isNotEmpty ? scanMsg : 'Scanning...')
        : terhubung
            ? 'Sensor Aktif — Siap Scan'
            : 'ESP32 Belum Terhubung';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: warna.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.3, 1.3),
                  duration: 700.ms,),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,),),
        ],
      ),
    );
  }
}

// ── Sensor Preview Bar ────────────────────────────────────────
class _SensorPreviewBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(sensorDataProvider);
    if (data == null) return const SizedBox(height: 8);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniSensor(
            ikon: Icons.graphic_eq_rounded,
            label: 'Frekuensi (Hz)',
            nilai: '${data.gemaAkustik}',
            warna: AppTheme.primaryGreen,
          ),
          Container(width: 1, height: 32, color: AppTheme.borderDark),
          _MiniSensor(
            ikon: Icons.graphic_eq_rounded,
            label: 'Akustik (Hz)',
            nilai: '${data.gemaAkustik}',
            warna: AppTheme.primaryGreen,
          ),
          Container(width: 1, height: 32, color: AppTheme.borderDark),
          _MiniSensor(
            ikon: Icons.verified_rounded,
            label: 'Conf.',
            nilai: '${data.confPct}%',
            subtitle: data.labelKondisi,
            warna: data.confPct >= 70
                ? AppTheme.primaryGreen
                : data.confPct >= 40
                    ? AppTheme.accentOrange
                    : AppTheme.statusError,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _MiniSensor extends StatelessWidget {
  const _MiniSensor({
    required this.ikon,
    required this.label,
    required this.nilai,
    required this.warna,
    this.subtitle,
  });
  final IconData ikon;
  final String label;
  final String nilai;
  final Color warna;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, color: warna, size: 16),
        const SizedBox(height: 4),
        Text(nilai,
            style: TextStyle(
                color: warna,
                fontSize: subtitle == null ? 16 : 20,
                fontWeight: FontWeight.w700,),),
        if (subtitle != null)
          Text(subtitle!,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 9,),
              textAlign: TextAlign.center,),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 9,),),
      ],
    );
  }
}

// ============================================================
//  Scan Result Sheet — Hasil scan dari ESP32
// ============================================================
class ScanResultSheet extends ConsumerStatefulWidget {
  const ScanResultSheet({required this.hasil, this.ai, super.key});
  final SensorData hasil;
  final HasilAI? ai;

  @override
  ConsumerState<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends ConsumerState<ScanResultSheet> {
  String _jenisBuah = '';
  final _ctrlJenis  = TextEditingController();

  @override
  void dispose() {
    _ctrlJenis.dispose();
    super.dispose();
  }

  Color get _warnaPrimary {
    switch (widget.hasil.status) {
      case 'SEGAR_PADAT':    return AppTheme.primaryGreen;
      case 'MATANG_LUNAK':   return AppTheme.accentYellow;
      case 'BELUM_MATANG':   return AppTheme.accentOrange;
      case 'INDIKASI_BUSUK': return AppTheme.statusError;
      default:               return AppTheme.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hasil;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundCard.withOpacity(0.98),
            AppTheme.backgroundDark.withOpacity(0.99),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 44, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header hasil
                      _HasilHeader(hasil: h, warnaPrimary: _warnaPrimary),
                      const SizedBox(height: 24),

                      // Verdikt fusi (kamera AI + akustik + UV)
                      _VerdiktFusiCard(ai: widget.ai, hasil: h),
                      const SizedBox(height: 24),

                      // Grid metrik sensor
                      _MetrikGrid(hasil: h),
                      const SizedBox(height: 24),

                      // Bar UV Reflectance + Akustik
                      _SensorBarSection(hasil: h),
                      const SizedBox(height: 24),

                      // Saran penyimpanan
                      _SaranSection(saran: h.saranPenyimpanan),
                      const SizedBox(height: 20),

                      // Input jenis buah (opsional, untuk labeling data)
                      Text('Jenis Buah (Opsional)',
                          style: Theme.of(context).textTheme.titleLarge,),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _ctrlJenis,
                        onChanged: (v) => _jenisBuah = v,
                        decoration: const InputDecoration(
                          hintText: 'cth: Mangga Gedong Gincu',
                          prefixIcon: Icon(Icons.eco_outlined,
                              color: AppTheme.textMuted,),
                        ),
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 24),

                      // Tombol tutup
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _warnaPrimary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),),
                            elevation: 0,
                          ),
                          child: const Text('Tutup & Simpan ke Riwayat',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700,),),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ── Hasil Header ──────────────────────────────────────────────
class _HasilHeader extends StatelessWidget {
  const _HasilHeader({required this.hasil, required this.warnaPrimary});
  final SensorData hasil;
  final Color warnaPrimary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emoji + kondisi
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hasil.emoji,
                  style: const TextStyle(fontSize: 40),),
              const SizedBox(height: 8),
              Text(hasil.labelKondisi,
                  style: Theme.of(context).textTheme.headlineMedium,),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4,),
                    decoration: BoxDecoration(
                      color: warnaPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('GRADE ${hasil.grade}',
                        style: TextStyle(
                          color: warnaPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4,),
                    decoration: BoxDecoration(
                      color: AppTheme.borderDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Loop #${hasil.loop}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Skor lingkaran
        Container(
          width: 76, height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: warnaPrimary, width: 3.5),
          ),
          child: Center(
            child: Text('${hasil.skor}%',
                style: TextStyle(
                    color: warnaPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,),),
          ),
        ),
      ],
    );
  }
}

// ── Metrik Grid ───────────────────────────────────────────────
class _MetrikGrid extends StatelessWidget {
  const _MetrikGrid({required this.hasil});
  final SensorData hasil;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _MetrikCard(
          ikon: Icons.graphic_eq_rounded,
          label: 'Amplitudo Mic',
          nilai: '${hasil.ampRaw}',
          subtitle: hasil.isAmpValid ? 'Sinyal Valid' : 'Sinyal Lemah',
          warna: hasil.isAmpValid ? AppTheme.accentBlue : AppTheme.statusError,
        ),
        _MetrikCard(
          ikon: Icons.graphic_eq_rounded,
          label: 'Frek. Resonansi',
          nilai: '${hasil.gemaAkustik} Hz',
          subtitle: 'MAX9814 × 5 shot',
          warna: AppTheme.primaryGreen,
        ),
        _MetrikCard(
          ikon: Icons.schedule_rounded,
          label: 'Tahan Simpan',
          nilai: hasil.bestBefore,
          warna: AppTheme.accentBlue,
        ),
        _MetrikCard(
          ikon: Icons.analytics_outlined,
          label: 'Confidence AI',
          nilai: '${hasil.confPct}%',
          subtitle: hasil.confPct >= 70
              ? 'Data Andal'
              : hasil.confPct >= 40
                  ? 'Cukup'
                  : 'Tempelkan Rapat',
          warna: hasil.confPct >= 70
              ? AppTheme.primaryGreen
              : hasil.confPct >= 40
                  ? AppTheme.accentOrange
                  : AppTheme.statusError,
        ),
      ],
    );
  }
}

class _MetrikCard extends StatelessWidget {
  const _MetrikCard({
    required this.ikon,
    required this.label,
    required this.nilai,
    required this.warna,
    this.subtitle,
  });
  final IconData ikon;
  final String label;
  final String nilai;
  final Color warna;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDarker,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: warna.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ikon, color: warna, size: 18),
          ),
          const Spacer(),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppTheme.textMuted, fontSize: 10),),
          const SizedBox(height: 2),
          Text(nilai,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontSize: 15),),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 9,),),
        ],
      ),
    );
  }
}

// ── Sensor Bar Section ────────────────────────────────────────
class _SensorBarSection extends StatelessWidget {
  const _SensorBarSection({required this.hasil});
  final SensorData hasil;

  @override
  Widget build(BuildContext context) {
    // BH1750 lock-in: nilai tipikal 0–500 lux untuk pendaran buah (MTreg=254)
    final ampPct    = (hasil.ampRaw / 500.0).clamp(0.0, 1.0);
    // Acoustic: 150–1800 Hz → normalisasi ke 0–1
    final akustikPct = ((hasil.gemaAkustik - 150).clamp(0, 1650) / 1650.0);
    final confPct   = (hasil.confPct / 100.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pembacaan Sensor',
            style: Theme.of(context).textTheme.titleLarge,),
        const SizedBox(height: 12),
        _SensorBar(
          label: 'Amplitudo Mic MAX9814 (ADC p-p)',
          nilai: hasil.ampRaw,
          satuan: '',
          maxNilai: 500,
          pct: ampPct,
          warna: hasil.isAmpValid ? AppTheme.accentBlue : AppTheme.statusError,
        ),
        const SizedBox(height: 10),
        _SensorBar(
          label: 'Frekuensi Resonansi Akustik (Hz)',
          nilai: hasil.gemaAkustik,
          satuan: 'Hz',
          maxNilai: 1800,
          pct: akustikPct,
          warna: AppTheme.primaryGreen,
        ),
        const SizedBox(height: 10),
        _SensorBar(
          label: 'Confidence Data Akustik (5 shot)',
          nilai: hasil.confPct,
          satuan: '%',
          maxNilai: 100,
          pct: confPct,
          warna: hasil.confPct >= 70
              ? AppTheme.primaryGreen
              : hasil.confPct >= 40
                  ? AppTheme.accentOrange
                  : AppTheme.statusError,
        ),
        const SizedBox(height: 8),
        Text(
          '⚠️  Nilai threshold masih estimasi. Kalibrasi dengan data buah nyata.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

class _SensorBar extends StatelessWidget {
  const _SensorBar({
    required this.label,
    required this.nilai,
    required this.pct,
    required this.warna,
    this.satuan = '',
    this.maxNilai = 100,
  });
  final String label;
  final int nilai;
  final double pct;
  final Color warna;
  final String satuan;
  final int maxNilai;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12,),),
            Text('$nilai $satuan',
                style: TextStyle(
                    color: warna,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,),),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppTheme.backgroundDarker,
            valueColor: AlwaysStoppedAnimation(warna),
          ),
        ),
      ],
    );
  }
}

// ── Saran Penyimpanan Section ─────────────────────────────────
class _SaranSection extends StatelessWidget {
  const _SaranSection({required this.saran});
  final List<String> saran;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Saran Penanganan',
            style: Theme.of(context).textTheme.titleLarge,),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundDarker,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: saran
                .map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              color: AppTheme.primaryGreen, size: 18,),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(tip,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,),),
                          ),
                        ],
                      ),
                    ),)
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ── Verdikt Fusi (Kamera AI + Akustik + UV) ───────────────────
String verdiktFusi(HasilAI? ai, SensorData s) {
  if (s.status == 'INDIKASI_BUSUK') return 'Indikasi Tidak Layak';
  final keras = s.status == 'BELUM_MATANG' || s.status == 'SEGAR_PADAT';
  if (ai == null) return s.labelKondisi; // sensor-only
  final l = ai.label.toLowerCase();
  final warnaMatang = l.contains('matang') || l.contains('lunak') ||
      l.contains('ripe') || l.contains('kuning') || l.contains('oranye');
  if (warnaMatang && !keras) return 'Matang Optimal';
  if (!warnaMatang && keras) return 'Belum Matang';
  return 'Setengah Matang';
}

class _VerdiktFusiCard extends StatelessWidget {
  const _VerdiktFusiCard({required this.ai, required this.hasil});
  final HasilAI? ai;
  final SensorData hasil;

  @override
  Widget build(BuildContext context) {
    final a = ai;
    final verdikt = verdiktFusi(a, hasil);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 16),
              SizedBox(width: 6),
              Text('VERDIKT FUSI (Kamera + Sensor)',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),),
            ],
          ),
          const SizedBox(height: 8),
          Text(verdikt,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),),
          const SizedBox(height: 12),
          _kanal(
            '📷 Kamera AI',
            a == null
                ? 'Tidak aktif (model belum dipasang)'
                : '${a.labelRapi} • ${(a.confidence * 100).toStringAsFixed(0)}%',
          ),
          const SizedBox(height: 4),
          _kanal('🔊 Akustik (Fr)', '${hasil.gemaAkustik} Hz → ${hasil.labelKondisi}'),
          const SizedBox(height: 4),
          _kanal('📶 Amplitudo Mic', '${hasil.ampRaw} (${hasil.isAmpValid ? "✓ valid" : "✗ lemah"})'),
        ],
      ),
    );
  }

  Widget _kanal(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(val,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),),
        ),
      ],
    );
  }
}
