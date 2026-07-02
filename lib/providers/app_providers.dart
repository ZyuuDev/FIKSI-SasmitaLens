import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scan_feed.dart';
import '../models/vendor_rating.dart';
import '../providers/bluetooth_service.dart';

// ==================== Navigation State ====================

final currentTabIndexProvider = StateProvider<int>((ref) => 0);

final pageControllerProvider = Provider<PageController>((ref) {
  return PageController();
});

// ==================== Device Connection State ====================

final isDeviceConnectedProvider = Provider<bool>((ref) {
  return ref.watch(btTerhubungProvider);
});

final deviceIdProvider = StateProvider<String?>((ref) => null);

// ==================== Scan History State ====================

/// Scan history — menyimpan riwayat scan dari ESP32
class ScanHistoryNotifier extends StateNotifier<List<SensorData>> {
  ScanHistoryNotifier() : super([]);

  void tambahScan(SensorData data) {
    if (!data.isHasilScan) return;
    state = [data, ...state];
    if (state.length > 100) {
      state = state.take(100).toList();
    }
  }

  void hapusSemua() => state = [];

  void hapusSatu(int index) {
    final newList = [...state];
    newList.removeAt(index);
    state = newList;
  }
}

final scanHistoryProvider =
    StateNotifierProvider<ScanHistoryNotifier, List<SensorData>>(
  (ref) => ScanHistoryNotifier(),
);

/// Statistik ringkasan riwayat scan — AKUSTIK ONLY
final statsRiwayatProvider = Provider<Map<String, int>>((ref) {
  final riwayat = ref.watch(scanHistoryProvider);
  final stats = <String, int>{
    'total':           riwayat.length,
    'segar_padat':     0,
    'matang_lunak':    0,
    'belum_matang':    0,
    'indikasi_busuk':  0,
    'tidak_diketahui': 0,
  };
  for (final scan in riwayat) {
    switch (scan.status) {
      case 'SEGAR_PADAT':    stats['segar_padat']     = (stats['segar_padat']     ?? 0) + 1; break;
      case 'MATANG_LUNAK':   stats['matang_lunak']    = (stats['matang_lunak']    ?? 0) + 1; break;
      case 'BELUM_MATANG':   stats['belum_matang']    = (stats['belum_matang']    ?? 0) + 1; break;
      case 'INDIKASI_BUSUK': stats['indikasi_busuk']  = (stats['indikasi_busuk']  ?? 0) + 1; break;
      default:               stats['tidak_diketahui'] = (stats['tidak_diketahui'] ?? 0) + 1;
    }
  }
  return stats;
});

// ==================== Scan State ====================

final isScanningProvider       = StateProvider<bool>((ref) => false);
final currentScanResultProvider = StateProvider<SensorData?>((ref) => null);

// ==================== Leaderboard State ====================

final vendorsProvider = StateProvider<List<VendorRating>>((ref) {
  return MockVendors.getVendors();
});

final sortedVendorsProvider = Provider<List<VendorRating>>((ref) {
  final vendors = ref.watch(vendorsProvider);
  return vendors.sortedByPoints().withUpdatedRanks();
});

final topVendorsProvider = Provider<List<VendorRating>>((ref) {
  final vendors = ref.watch(sortedVendorsProvider);
  return vendors.take(3).toList();
});

final leaderboardFilterProvider = StateProvider<String>((ref) => 'All');

// ==================== Social Feed State ====================

final scanFeedProvider = StateProvider<List<ScanFeed>>((ref) {
  return MockScanFeed.getFeeds();
});

final feedFilterProvider = StateProvider<String>((ref) => 'Semua');

final filteredFeedProvider = Provider<List<ScanFeed>>((ref) {
  final feeds  = ref.watch(scanFeedProvider);
  final filter = ref.watch(feedFilterProvider);
  if (filter == 'All' || filter == 'Semua') return feeds;
  return MockScanFeed.getFeedsByCategory(filter);
});

final userPointsProvider = StateProvider<int>((ref) => 1250);

// ==================== Settings State ====================

final notificationsEnabledProvider = StateProvider<bool>((ref) => true);
final isDarkModeProvider           = StateProvider<bool>((ref) => true);

final userProfileProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'name':       'Fairuz',
    'email':      'sasmitalens@smkn1bantul.sch.id',
    'avatar':     '',
    'membership': 'FIKSI 2026 — SMK N 1 Bantul',
    'joinedDate': DateTime(2026, 6),
    'sekolah':    'SMK Negeri 1 Bantul',
    'proyek':     'SASMITA LENS',
  };
});

/// Versi app — v4 sesuai firmware
final appVersionProvider = Provider<String>((ref) => 'v4.0');

// ==================== UI State ====================

final isBottomSheetOpenProvider = StateProvider<bool>((ref) => false);
final isLoadingProvider         = StateProvider<bool>((ref) => false);
final errorMessageProvider      = StateProvider<String?>((ref) => null);
final successMessageProvider    = StateProvider<String?>((ref) => null);

// ==================== Device Status State ====================

/// Status perangkat untuk Home Screen — AKUSTIK ONLY, tidak ada UV
final deviceStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final terhubung  = ref.watch(btTerhubungProvider);
  final dataSensor = ref.watch(sensorDataProvider);

  return {
    'terhubung':          terhubung,
    'statusLabel':        terhubung ? 'Terhubung' : 'Tidak Terhubung',
    'akustikTerakhir':    dataSensor?.gemaAkustik ?? 0,
    'freqTerakhir':       dataSensor?.freqHz      ?? 0,
    'ampTerakhir':        dataSensor?.ampRaw       ?? 0,
    'confTerakhir':       dataSensor?.confPct      ?? 0,
    'kondisiTerakhir':    dataSensor?.labelKondisi ?? '—',
    'statusTerakhir':     dataSensor?.status       ?? '',
    'waktuTerakhir':      dataSensor?.timestamp,
    'baterai':            dataSensor?.bat ?? -1,
    'ampValid':           dataSensor?.isAmpValid ?? false,
    // TIDAK ADA 'uvTerakhir' — tidak ada sensor optik
  };
});

/// 5 scan terakhir untuk Home Screen
final recentScansProvider = Provider<List<SensorData>>((ref) {
  final riwayat = ref.watch(scanHistoryProvider);
  return riwayat.take(5).toList();
});

// ==================== Threshold Settings (AKUSTIK ONLY) ====================

/// Ambang frekuensi: freq >= ini → keras/belum matang
final akustikPadatMinProvider = StateProvider<int>((ref) => 500);

/// Ambang frekuensi: freq <= ini → lunak/matang
final akustikLunakMaxProvider = StateProvider<int>((ref) => 330);

/// Ambang amplitudo minimum (di bawah ini → sinyal tidak valid / indikasi busuk)
final ampMinValidProvider = StateProvider<int>((ref) => 25);
