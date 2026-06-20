import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/fruit_analysis.dart';

// ============================================================
//  BLUETOOTH SERVICE — Komunikasi dengan ESP32 SASMITA LENS
//  Protocol: Bluetooth Classic SPP (Serial Port Profile)
//  Data: JSON per baris — {"uv":XXX,"acoustic":XXX,"status":"...","score":XX}
// ============================================================

/// Model data sensor dari ESP32
class SensorData {
  SensorData({
    required this.uvAktual,
    required this.gemaAkustik,
    required this.status,
    required this.score,
    required this.loop,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Parse dari JSON string ESP32
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      uvAktual:    json['uv']         as int? ?? 0,
      gemaAkustik: json['acoustic']   as int? ?? 0,
      status:      json['status']     as String? ?? 'TIDAK_DIKETAHUI',
      score:       json['score']      as int? ?? 0,
      loop:        json['loop']       as int? ?? 0,
    );
  }

  final int uvAktual;
  final int gemaAkustik;
  final String status;
  final int score;
  final int loop;
  final DateTime timestamp;

  /// Konversi status ESP32 ke FruitAnalysis untuk UI existing
  FruitAnalysis toFruitAnalysis() {
    final grade      = _scoreToGrade(score);
    final bestBefore = _statusToBestBefore(status);

    return FruitAnalysis(
      id:            'scan_${timestamp.millisecondsSinceEpoch}',
      type:          'Buah',
      brix:          _uvToBrix(uvAktual),
      waterContent:  _acousticToWaterContent(gemaAkustik),
      freshness:     score.toDouble(),
      hasResidue:    false,
      bestBefore:    bestBefore,
      daysUntilExpiry: _statusToDays(status),
      qualityScore:  score.toDouble(),
      grade:         grade,
      storageTips:   _getStorageTips(status),
      aiRecipes:     [],
      scannedAt:     timestamp,
    );
  }

  String _scoreToGrade(int s) {
    if (s >= 80) return 'A+';
    if (s >= 65) return 'A';
    if (s >= 50) return 'B+';
    if (s >= 35) return 'B';
    return 'C';
  }

  String _statusToBestBefore(String s) {
    switch (s) {
      case 'SEGAR_PADAT':    return '5-7 Hari';
      case 'BELUM_MATANG':   return '3-5 Hari';
      case 'MATANG_LUNAK':   return '1-2 Hari';
      case 'INDIKASI_BUSUK': return 'Segera Konsumsi';
      default:               return 'Tidak Diketahui';
    }
  }

  int _statusToDays(String s) {
    switch (s) {
      case 'SEGAR_PADAT':    return 7;
      case 'BELUM_MATANG':   return 4;
      case 'MATANG_LUNAK':   return 2;
      case 'INDIKASI_BUSUK': return 0;
      default:               return 3;
    }
  }

  double _uvToBrix(int uv) => (uv / 4000.0 * 20).clamp(0, 25);
  double _acousticToWaterContent(int a) => (100 - (a / 4000.0 * 30)).clamp(60, 95);

  List<String> _getStorageTips(String s) {
    switch (s) {
      case 'SEGAR_PADAT':
        return ['Simpan di kulkas 0-4°C', 'Tahan 5-7 hari', 'Cuci sebelum dikonsumsi'];
      case 'BELUM_MATANG':
        return ['Simpan di suhu ruang', 'Tunggu 2-3 hari agar matang', 'Jangan simpan di kulkas'];
      case 'MATANG_LUNAK':
        return ['Konsumsi segera', 'Bisa disimpan di kulkas 1-2 hari', 'Cocok untuk jus'];
      case 'INDIKASI_BUSUK':
        return ['Periksa visual dengan seksama', 'Hindari konsumsi jika berbau', 'Buang jika ada jamur'];
      default:
        return ['Lakukan scan ulang', 'Periksa posisi sensor ke buah'];
    }
  }
}

// ============================================================
//  BLUETOOTH MANAGER — Kelola koneksi ke ESP32
// ============================================================

class BluetoothManager extends ChangeNotifier {
  BluetoothConnection? _koneksi;
  String _buffer = '';

  bool   _terhubung    = false;
  bool   _sedangCari   = false;
  String _statusPesan  = 'Belum terhubung';
  List<BluetoothDevice> _daftarDevice = [];
  SensorData? _dataTerakhir;

  // Stream controller untuk data sensor real-time
  final _streamController = StreamController<SensorData>.broadcast();

  bool              get terhubung    => _terhubung;
  bool              get sedangCari   => _sedangCari;
  String            get statusPesan  => _statusPesan;
  List<BluetoothDevice> get daftarDevice => _daftarDevice;
  SensorData?       get dataTerakhir => _dataTerakhir;
  Stream<SensorData> get dataStream  => _streamController.stream;

  /// Minta izin Bluetooth (Android)
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

  /// Scan perangkat Bluetooth terdekat
  Future<void> scanDevice() async {
    try {
      final izinOk = await mintaIzin();
      if (!izinOk) return;

      _sedangCari  = true;
      _daftarDevice = [];
      _statusPesan  = 'Mencari perangkat SASMITA-LENS...';
      notifyListeners();

      // Ambil perangkat yang sudah pernah di-pair
      final paired = await FlutterBluetoothSerial.instance.getBondedDevices();
      _daftarDevice = paired;

      _sedangCari = false;
      _statusPesan = _daftarDevice.isEmpty
          ? 'Tidak ada perangkat. Pair "SASMITA-LENS" di Pengaturan Bluetooth dulu.'
          : 'Ditemukan ${_daftarDevice.length} perangkat';
      notifyListeners();
    } on Exception catch (e) {
      _sedangCari  = false;
      _statusPesan = 'Error scan: $e';
      notifyListeners();
    }
  }

  /// Hubungkan ke ESP32 berdasarkan alamat MAC
  Future<bool> hubungkan(BluetoothDevice device) async {
    try {
      _statusPesan = 'Menghubungkan ke ${device.name}...';
      notifyListeners();

      _koneksi = await BluetoothConnection.toAddress(device.address);

      _terhubung   = true;
      _statusPesan = 'Terhubung ke ${device.name}';
      notifyListeners();

      // Dengarkan data dari ESP32
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

  /// Proses data byte masuk dari ESP32, parse JSON per baris
  void _prosesDataMasuk(Uint8List data) {
    _buffer += utf8.decode(data, allowMalformed: true);

    // Proses baris yang sudah lengkap (ditandai newline \n)
    while (_buffer.contains('\n')) {
      final idx  = _buffer.indexOf('\n');
      final baris = _buffer.substring(0, idx).trim();
      _buffer = _buffer.substring(idx + 1);

      if (baris.isEmpty) continue;

      try {
        final json    = jsonDecode(baris) as Map<String, dynamic>;
        final sensor  = SensorData.fromJson(json);
        _dataTerakhir = sensor;
        _streamController.add(sensor);
        notifyListeners();
      } on FormatException catch (e) {
        // Abaikan baris yang bukan JSON (misal output Serial Plotter)
        debugPrint('[BT] Bukan JSON ($e): $baris');
      } on Exception catch (e) {
        debugPrint('[BT] Parse error: $e');
      }
    }
  }

  /// Tangani koneksi terputus
  void _tanganiPutus() {
    _terhubung   = false;
    _statusPesan = 'Koneksi terputus';
    _koneksi     = null;
    notifyListeners();
  }

  /// Putuskan koneksi manual
  Future<void> putuskan() async {
    try {
      await _koneksi?.close();
    } on Exception catch (_) {}
    _koneksi     = null;
    _terhubung   = false;
    _statusPesan = 'Belum terhubung';
    _dataTerakhir = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamController.close();
    _koneksi?.close();
    super.dispose();
  }
}

// ============================================================
//  RIVERPOD PROVIDERS
// ============================================================

/// Provider utama BluetoothManager (ChangeNotifier)
final bluetoothManagerProvider = ChangeNotifierProvider<BluetoothManager>(
  (ref) => BluetoothManager(),
);

/// Provider status koneksi (bool)
final btTerhubungProvider = Provider<bool>((ref) {
  return ref.watch(bluetoothManagerProvider).terhubung;
});

/// Provider data sensor terbaru
final sensorDataProvider = Provider<SensorData?>((ref) {
  return ref.watch(bluetoothManagerProvider).dataTerakhir;
});

/// Provider stream data sensor real-time
final sensorStreamProvider = StreamProvider<SensorData>((ref) {
  return ref.watch(bluetoothManagerProvider).dataStream;
});

/// Provider daftar device Bluetooth yang sudah di-pair
final daftarDeviceProvider = Provider<List<BluetoothDevice>>((ref) {
  return ref.watch(bluetoothManagerProvider).daftarDevice;
});

/// Provider status pesan koneksi
final statusPesanBtProvider = Provider<String>((ref) {
  return ref.watch(bluetoothManagerProvider).statusPesan;
});
