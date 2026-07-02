import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/fruit_analysis.dart';

// ============================================================
//  BLUETOOTH SERVICE — Komunikasi dengan ESP32 SASMITA LENS v4
//  Protocol  : Bluetooth Classic SPP (Serial Port Profile)
//  Nama BT   : SASMITA-LENS
//
//  KONTRAK DATA dari ESP32 (AKUSTIK ONLY — tidak ada UV/fluoresensi):
//    Hasil scan  : {"acoustic":F,"status":"...","loop":N,"bat":-1,"freq":F,"amp":P,"conf":C}
//    Notifikasi  : {"status":"KALIBRASI"|"SIAP"|"SCANNING"|"TIDUR"}
//
//  Field JSON:
//    acoustic / freq = Frekuensi Resonansi weighted-average (Hz)
//    amp             = Amplitudo rata-rata shot valid (peak-to-peak ADC)
//    conf            = Confidence akustik 0-100 (konsistensi 5 shot)
//    status          : SEGAR_PADAT | BELUM_MATANG | MATANG_LUNAK | INDIKASI_BUSUK
//    bat             : -1 = tidak tersedia
//    Field 'uv'      : TIDAK ADA — tidak ada sensor optik
//
//  Perintah dari App ke ESP32:
//    SCAN        → 5-shot acoustic impulse + FFT → kirim JSON hasil
//    KALIBRASI   → Reset referensi akustik
//    STREAM_ON   → Mulai streaming scan otomatis ~1.5 detik sekali
//    STREAM_OFF  → Hentikan streaming
//    DEBUG_AMP   → Tembak 1 shot, kirim amp saja (cek mic)
//    TIDUR       → ESP32 masuk Deep Sleep (sentuh kawat GPIO32 untuk bangun)
// ============================================================

// ============================================================
//  STATUS NOTIFIKASI dari ESP32 (bukan data sensor)
// ============================================================
const Set<String> _statusNotifikasi = {
  'KALIBRASI',
  'SIAP',
  'TIDUR',
  'SCANNING',
  'ERROR',
};

/// Model data sensor dari ESP32 SASMITA LENS v4 (Akustik ONLY)
/// Format JSON: {"acoustic":420,"status":"SEGAR_PADAT","loop":1,"bat":-1,"freq":420,"amp":185,"conf":87}
/// Keterangan:
///   acoustic / freq = Frekuensi Resonansi weighted-average (Hz) → kekerasan buah
///   amp             = Amplitudo rata-rata shot valid (peak-to-peak ADC)
///   conf            = Confidence akustik 0-100 (konsistensi antar shot — untuk AI & UI)
///   TIDAK ADA field uv — tidak ada sensor optik
class SensorData {

  /// Parse dari JSON string ESP32
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      gemaAkustik: _parseInt(json['acoustic']),
      status:      json['status']  as String? ?? 'TIDAK_DIKETAHUI',
      loop:        _parseInt(json['loop']),
      bat:         _parseInt(json['bat'] ?? -1),
      freqHz:      _parseInt(json['freq']  ?? json['acoustic']),
      ampRaw:      _parseInt(json['amp']   ?? 0),
      confPct:     _parseInt(json['conf']  ?? 0),
    );
  }

  SensorData({
    required this.gemaAkustik,
    required this.status,
    required this.loop,
    this.bat     = -1,
    this.freqHz  = 0,
    this.ampRaw  = 0,
    this.confPct = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Helper parse angka aman
  static int _parseInt(dynamic value) {
    if (value is int)    return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.replaceAll(RegExp(r'[^0-9\-]'), '')) ?? 0;
    return 0;
  }

  final int    gemaAkustik;  // Frekuensi Resonansi Hz (weighted average 5 shot)
  final String status;
  final int    loop;
  final int    bat;          // -1 = tidak tersedia
  final int    freqHz;       // alias gemaAkustik
  final int    ampRaw;       // amplitudo getaran peak-to-peak (ADC counts)
  final int    confPct;      // confidence akustik 0-100
  final DateTime timestamp;

  /// Apakah ini data pengukuran buah (bukan notifikasi)
  bool get isHasilScan => !_statusNotifikasi.contains(status);

  /// Apakah sinyal akustik valid (amp cukup besar)
  bool get isAmpValid => ampRaw > 25;

  /// Label kondisi buah dalam Bahasa Indonesia
  String get labelKondisi {
    switch (status) {
      case 'SEGAR_PADAT':     return 'Segar & Padat';
      case 'MATANG_LUNAK':    return 'Matang / Lunak';
      case 'BELUM_MATANG':    return 'Belum Matang';
      case 'INDIKASI_BUSUK':  return 'Indikasi Busuk';
      case 'TIDAK_DIKETAHUI': return 'Tidak Diketahui';
      case 'KALIBRASI':       return 'Kalibrasi Berjalan...';
      case 'SIAP':            return 'Kalibrasi Selesai';
      case 'TIDUR':           return 'ESP32 Tidur';
      default:                return status;
    }
  }

  /// Emoji kondisi buah
  String get emoji {
    switch (status) {
      case 'SEGAR_PADAT':    return '✅';
      case 'MATANG_LUNAK':   return '⚠️';
      case 'BELUM_MATANG':   return '🟡';
      case 'INDIKASI_BUSUK': return '❌';
      case 'KALIBRASI':      return '🔄';
      case 'SIAP':           return '✔️';
      case 'TIDUR':          return '😴';
      default:               return '🔍';
    }
  }

  /// Grade kualitas berdasarkan status akustik
  String get grade {
    switch (status) {
      case 'SEGAR_PADAT':    return 'A+';
      case 'BELUM_MATANG':   return 'B+';
      case 'MATANG_LUNAK':   return 'B';
      case 'INDIKASI_BUSUK': return 'C';
      default:               return '?';
    }
  }

  /// Estimasi ketahanan simpan
  String get bestBefore {
    switch (status) {
      case 'SEGAR_PADAT':    return '5–7 Hari';
      case 'BELUM_MATANG':   return '3–5 Hari';
      case 'MATANG_LUNAK':   return '1–2 Hari';
      case 'INDIKASI_BUSUK': return 'Segera Periksa';
      default:               return '-';
    }
  }

  /// Skor kualitas 0-100
  int get skor {
    switch (status) {
      case 'SEGAR_PADAT':    return 92;
      case 'BELUM_MATANG':   return 75;
      case 'MATANG_LUNAK':   return 65;
      case 'INDIKASI_BUSUK': return 20;
      default:               return 0;
    }
  }

  /// Warna indikator berdasarkan status (untuk UI)
  String get warnaSaranPenyimpanan {
    switch (status) {
      case 'SEGAR_PADAT':    return 'green';
      case 'BELUM_MATANG':   return 'yellow';
      case 'MATANG_LUNAK':   return 'orange';
      case 'INDIKASI_BUSUK': return 'red';
      default:               return 'grey';
    }
  }

  /// Saran penyimpanan berdasarkan status akustik
  List<String> get saranPenyimpanan {
    switch (status) {
      case 'SEGAR_PADAT':
        return [
          'Simpan di kulkas 0–4°C',
          'Tahan 5–7 hari',
          'Cuci sebelum dikonsumsi',
        ];
      case 'BELUM_MATANG':
        return [
          'Simpan di suhu ruang',
          'Tunggu 2–3 hari agar matang',
          'Jangan simpan di kulkas dulu',
        ];
      case 'MATANG_LUNAK':
        return [
          'Konsumsi segera atau olah',
          'Bisa disimpan di kulkas 1–2 hari',
          'Cocok untuk jus atau olahan',
        ];
      case 'INDIKASI_BUSUK':
        return [
          'Periksa visual dengan seksama',
          'Hindari konsumsi jika berbau tidak wajar',
          'Pisahkan dari buah segar lainnya',
        ];
      default:
        return [
          'Lakukan scan ulang',
          'Dekatkan sensor ke buah 1–3 cm',
          'Kalibrasi ulang jika perlu',
        ];
    }
  }

  int _statusToDays(String s) {
    switch (s) {
      case 'SEGAR_PADAT':    return 6;
      case 'BELUM_MATANG':   return 4;
      case 'MATANG_LUNAK':   return 1;
      case 'INDIKASI_BUSUK': return 0;
      default:               return 2;
    }
  }

  /// Estimasi kadar air dari frekuensi akustik
  /// Buah lunak (freq rendah) → kadar air lebih tinggi
  double _freqToWaterContent(int hz) =>
      (100 - ((hz - 150).clamp(0, 1650) / 1650.0 * 30)).clamp(60, 95);

  /// Konversi ke FruitAnalysis untuk kompatibilitas widget lama
  FruitAnalysis toFruitAnalysis() {
    return FruitAnalysis(
      id:            'scan_${timestamp.millisecondsSinceEpoch}',
      type:          'Buah',
      variety:       labelKondisi,
      brix:          (confPct / 100.0 * 18).clamp(0, 25), // estimasi dari confidence
      waterContent:  _freqToWaterContent(gemaAkustik),
      freshness:     skor.toDouble(),
      hasResidue:    false,
      residueStatus: 'Aman',
      bestBefore:    bestBefore,
      daysUntilExpiry: _statusToDays(status),
      qualityScore:  skor.toDouble(),
      grade:         grade,
      storageTips:   saranPenyimpanan,
      aiRecipes:     [],
      scannedAt:     timestamp,
    );
  }
}

// ============================================================
//  MODEL NOTIFIKASI dari ESP32 (status/event, bukan hasil scan)
// ============================================================
class ESP32Notifikasi {

  factory ESP32Notifikasi.fromJson(Map<String, dynamic> json) {
    return ESP32Notifikasi(
      status: json['status'] as String? ?? '',
      pesan:  json['pesan']  as String?,
    );
  }

  const ESP32Notifikasi({
    required this.status,
    this.pesan,
    DateTime? waktu,
  }) : waktu = waktu ?? const _NowDateTime();

  final String  status;
  final String? pesan;
  final DateTime waktu;
}

// Helper class untuk const DateTime.now()
class _NowDateTime implements DateTime {
  const _NowDateTime();
  @override dynamic noSuchMethod(Invocation invocation) => DateTime.now();
}

// ============================================================
//  BLUETOOTH MANAGER — Kelola koneksi ke ESP32
// ============================================================
class BluetoothManager extends ChangeNotifier {
  BluetoothConnection? _koneksi;
  String _buffer = '';

  bool   _terhubung   = false;
  bool   _sedangCari  = false;
  String _statusPesan = 'Belum terhubung';
  List<BluetoothDevice> _daftarDevice = [];

  SensorData?      _dataTerakhir;
  ESP32Notifikasi? _notifikasiTerakhir;
  bool             _sedangScan = false;

  // Stream untuk data sensor (hasil scan buah)
  final _streamSensor     = StreamController<SensorData>.broadcast();
  // Stream untuk notifikasi ESP32 (KALIBRASI, SIAP, TIDUR, dll.)
  final _streamNotifikasi = StreamController<ESP32Notifikasi>.broadcast();
  // Stream untuk raw string (mode debugging)
  final _streamRaw        = StreamController<String>.broadcast();

  bool              get terhubung          => _terhubung;
  bool              get sedangCari         => _sedangCari;
  bool              get sedangScan         => _sedangScan;
  String            get statusPesan        => _statusPesan;
  List<BluetoothDevice> get daftarDevice   => _daftarDevice;
  SensorData?       get dataTerakhir       => _dataTerakhir;
  ESP32Notifikasi?  get notifikasiTerakhir => _notifikasiTerakhir;
  Stream<SensorData>      get dataStream   => _streamSensor.stream;
  Stream<ESP32Notifikasi> get notifStream  => _streamNotifikasi.stream;
  Stream<String>          get rawDataStream => _streamRaw.stream;

  // ── Izin Bluetooth ─────────────────────────────────────────
  Future<bool> mintaIzin() async {
    try {
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      final semuaOk = statuses.values.every((s) => s.isGranted);
      if (!semuaOk) {
        _statusPesan = 'Izin Bluetooth ditolak. Aktifkan di Pengaturan.';
        notifyListeners();
      }
      return semuaOk;
    } on Exception catch (e) {
      _statusPesan = 'Gagal minta izin: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Scan perangkat Bluetooth ──────────────────────────────
  Future<void> scanDevice() async {
    try {
      final izinOk = await mintaIzin();
      if (!izinOk) return;

      _sedangCari   = true;
      _daftarDevice = [];
      _statusPesan  = 'Mencari SASMITA-LENS...';
      notifyListeners();

      final paired = await FlutterBluetoothSerial.instance.getBondedDevices();
      _daftarDevice = paired;

      _sedangCari = false;
      _statusPesan = _daftarDevice.isEmpty
          ? 'Tidak ada perangkat. Pair "SASMITA-LENS" di Pengaturan Bluetooth.'
          : 'Ditemukan ${_daftarDevice.length} perangkat';
      notifyListeners();
    } on Exception catch (e) {
      _sedangCari  = false;
      _statusPesan = 'Error scan: $e';
      notifyListeners();
    }
  }

  // ── Hubungkan ke ESP32 ──────────────────────────────────────
  Future<bool> hubungkan(BluetoothDevice device) async {
    try {
      _statusPesan = 'Menghubungkan ke ${device.name}...';
      notifyListeners();

      _koneksi = await BluetoothConnection.toAddress(device.address);

      _terhubung   = true;
      _statusPesan = 'Terhubung ke ${device.name}';
      notifyListeners();

      _koneksi!.input!.listen(
        _prosesDataMasuk,
        onDone: _tanganiPutus,
        onError: (e) {
          debugPrint('[BT] Error stream: $e');
          _tanganiPutus();
        },
        cancelOnError: false,
      );

      return true;
    } on Exception catch (e) {
      _terhubung   = false;
      _statusPesan = 'Gagal terhubung: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Proses Data Masuk dari ESP32 ──────────────────────────
  void _prosesDataMasuk(Uint8List data) {
    _buffer += utf8.decode(data, allowMalformed: true);

    while (_buffer.contains('\n')) {
      final idx   = _buffer.indexOf('\n');
      final baris = _buffer.substring(0, idx).trim();
      _buffer     = _buffer.substring(idx + 1);

      if (baris.isEmpty) continue;

      // Kirim ke raw stream untuk debug monitor
      _streamRaw.add(baris);

      try {
        final json   = jsonDecode(baris) as Map<String, dynamic>;
        final status = json['status'] as String? ?? '';

        if (_statusNotifikasi.contains(status)) {
          // Notifikasi (bukan data scan)
          final notif = ESP32Notifikasi.fromJson(json);
          _notifikasiTerakhir = notif;
          _streamNotifikasi.add(notif);

          if (status == 'KALIBRASI') {
            _statusPesan = '🔄 Kalibrasi sedang berjalan...';
          } else if (status == 'SIAP') {
            _statusPesan = '✅ Kalibrasi selesai — siap scan';
          } else if (status == 'TIDUR') {
            _statusPesan = '😴 ESP32 masuk mode tidur';
          } else if (status == 'SCANNING') {
            _statusPesan = '🔬 Sedang mengukur akustik...';
          }

          notifyListeners();
        } else {
          // Data sensor hasil scan buah
          final sensor   = SensorData.fromJson(json);
          _dataTerakhir  = sensor;
          _sedangScan    = false;
          _streamSensor.add(sensor);
          _statusPesan   = 'Data scan diterima — ${sensor.labelKondisi}';
          notifyListeners();
        }
      } on FormatException catch (e) {
        debugPrint('[BT] Bukan JSON: $e | baris: $baris');
      } on Exception catch (e) {
        debugPrint('[BT] Parse error: $e');
      }
    }
  }

  // ── Kirim Teks Perintah ke ESP32 ─────────────────────────
  Future<bool> kirimPerintah(String perintah) async {
    if (!_terhubung || _koneksi == null) {
      debugPrint('[BT] Tidak bisa kirim — belum terhubung');
      return false;
    }
    try {
      _koneksi!.output.add(utf8.encode('$perintah\n'));
      await _koneksi!.output.allSent;
      debugPrint('[BT] Perintah terkirim: $perintah');
      return true;
    } on Exception catch (e) {
      debugPrint('[BT] Gagal kirim perintah: $e');
      return false;
    }
  }

  // ── Perintah Spesifik (Akustik ONLY) ────────────────────

  /// SCAN — ESP32 akan tembak 5-shot akustik, FFT, kirim JSON hasil
  Future<bool> scan() async {
    _sedangScan  = true;
    _statusPesan = '🔬 Perintah SCAN dikirim ke ESP32...';
    notifyListeners();
    return kirimPerintah('SCAN');
  }

  /// KALIBRASI — Reset referensi akustik
  Future<bool> kalibrasi() async {
    _statusPesan = '🔄 Memulai kalibrasi akustik...';
    notifyListeners();
    return kirimPerintah('KALIBRASI');
  }

  /// STREAM_ON — Mulai streaming scan otomatis
  Future<bool> streamOn()  => kirimPerintah('STREAM_ON');

  /// STREAM_OFF — Hentikan streaming
  Future<bool> streamOff() => kirimPerintah('STREAM_OFF');

  /// DEBUG_AMP — Tembak 1 shot, cek amp mic (untuk diagnosa)
  Future<bool> debugAmp()  => kirimPerintah('DEBUG_AMP');

  /// TIDUR — ESP32 masuk Deep Sleep (sentuh kawat GPIO32 untuk bangun)
  Future<bool> tidur() async {
    _statusPesan = '😴 Mengirim perintah TIDUR ke ESP32...';
    notifyListeners();
    return kirimPerintah('TIDUR');
  }

  // ── Putus Koneksi ──────────────────────────────────────────
  void _tanganiPutus() {
    _terhubung   = false;
    _sedangScan  = false;
    _statusPesan = 'Koneksi terputus';
    _koneksi     = null;
    notifyListeners();
  }

  Future<void> putuskan() async {
    try { await _koneksi?.close(); } on Exception catch (_) {}
    _koneksi      = null;
    _terhubung    = false;
    _sedangScan   = false;
    _statusPesan  = 'Belum terhubung';
    _dataTerakhir = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSensor.close();
    _streamNotifikasi.close();
    _streamRaw.close();
    _koneksi?.close();
    super.dispose();
  }
}

// ============================================================
//  RIVERPOD PROVIDERS
// ============================================================

final bluetoothManagerProvider = ChangeNotifierProvider<BluetoothManager>(
  (ref) => BluetoothManager(),
);

final btTerhubungProvider = Provider<bool>((ref) {
  return ref.watch(bluetoothManagerProvider).terhubung;
});

final sensorDataProvider = Provider<SensorData?>((ref) {
  return ref.watch(bluetoothManagerProvider).dataTerakhir;
});

final sensorStreamProvider = StreamProvider<SensorData>((ref) {
  return ref.watch(bluetoothManagerProvider).dataStream;
});

final notifStreamProvider = StreamProvider<ESP32Notifikasi>((ref) {
  return ref.watch(bluetoothManagerProvider).notifStream;
});

final daftarDeviceProvider = Provider<List<BluetoothDevice>>((ref) {
  return ref.watch(bluetoothManagerProvider).daftarDevice;
});

final statusPesanBtProvider = Provider<String>((ref) {
  return ref.watch(bluetoothManagerProvider).statusPesan;
});

final sedangScanProvider = Provider<bool>((ref) {
  return ref.watch(bluetoothManagerProvider).sedangScan;
});
