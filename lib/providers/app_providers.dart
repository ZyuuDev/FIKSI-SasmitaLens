import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fruit_analysis.dart';
import '../models/scan_feed.dart';
import '../models/vendor_rating.dart';

// ==================== Navigation State ====================

/// Current tab index provider
final currentTabIndexProvider = StateProvider<int>((ref) => 0);

/// Page controller provider for main layout
final pageControllerProvider = Provider<PageController>((ref) {
  return PageController();
});

// ==================== Device Connection State ====================

/// Device connection state
final isDeviceConnectedProvider = StateProvider<bool>((ref) => false);

/// Device ID provider
final deviceIdProvider = StateProvider<String?>((ref) => null);

/// Device connection notifier
class DeviceConnectionNotifier extends StateNotifier<AsyncValue<bool>> {
  DeviceConnectionNotifier() : super(const AsyncValue.data(false));

  /// Validate and connect device
  Future<void> connectDevice(String deviceId) async {
    state = const AsyncValue.loading();
    
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Validate device ID (6-digit alphanumeric)
      final isValid = _validateDeviceId(deviceId);
      
      if (isValid) {
        state = const AsyncValue.data(true);
      } else {
        throw Exception('Invalid Device ID. Please enter a valid 6-digit code.');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Disconnect device
  void disconnect() {
    state = const AsyncValue.data(false);
  }

  /// Validate device ID format
  bool _validateDeviceId(String deviceId) {
    // Remove any prefixes like "SAS-" or "-Lens"
    final cleanId = deviceId
        .replaceAll('SAS-', '')
        .replaceAll('-Lens', '')
        .replaceAll('-', '')
        .trim();
    
    // Check if it's exactly 6 alphanumeric characters
    final regex = RegExp(r'^[A-Z0-9]{6}$');
    return regex.hasMatch(cleanId.toUpperCase());
  }

  /// Format device ID for display
  String formatDeviceId(String deviceId) {
    final cleanId = deviceId.replaceAll(RegExp('[^A-Z0-9]'), '').toUpperCase();
    if (cleanId.length >= 6) {
      return 'SAS-${cleanId.substring(0, 4)}-Lens';
    }
    return deviceId;
  }
}

/// Device connection provider
final deviceConnectionProvider = StateNotifierProvider<DeviceConnectionNotifier, AsyncValue<bool>>((ref) {
  return DeviceConnectionNotifier();
});

// ==================== Scan State ====================

/// Scanning state provider
final isScanningProvider = StateProvider<bool>((ref) => false);

/// Current scan result provider
final currentScanResultProvider = StateProvider<FruitAnalysis?>((ref) => null);

/// Scan history provider
final scanHistoryProvider = StateProvider<List<FruitAnalysis>>((ref) => []);

/// Scan notifier for managing scan operations
class ScanNotifier extends StateNotifier<AsyncValue<FruitAnalysis?>> {
  ScanNotifier() : super(const AsyncValue.data(null));

  /// Perform a scan
  Future<void> performScan() async {
    state = const AsyncValue.loading();
    
    try {
      // Simulate scanning delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Generate mock result
      final result = FruitAnalysis.mock();
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Clear current scan
  void clearScan() {
    state = const AsyncValue.data(null);
  }

  /// Submit rating for a scan
  Future<void> submitRating({
    required String scanId,
    required int rating,
    String? location,
  }) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // In a real app, this would update the backend
      debugPrint('Rating submitted: $rating for scan $scanId at $location');
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      rethrow;
    }
  }
}

/// Scan provider
final scanProvider = StateNotifierProvider<ScanNotifier, AsyncValue<FruitAnalysis?>>((ref) {
  return ScanNotifier();
});

// ==================== Leaderboard State ====================

/// Vendors list provider
final vendorsProvider = StateProvider<List<VendorRating>>((ref) {
  return MockVendors.getVendors();
});

/// Sorted vendors by points
final sortedVendorsProvider = Provider<List<VendorRating>>((ref) {
  final vendors = ref.watch(vendorsProvider);
  return vendors.sortedByPoints().withUpdatedRanks();
});

/// Top 3 vendors provider
final topVendorsProvider = Provider<List<VendorRating>>((ref) {
  final vendors = ref.watch(sortedVendorsProvider);
  return vendors.take(3).toList();
});

/// Leaderboard category filter
final leaderboardFilterProvider = StateProvider<String>((ref) => 'All');

// ==================== Social Feed State ====================

/// Scan feed provider
final scanFeedProvider = StateProvider<List<ScanFeed>>((ref) {
  return MockScanFeed.getFeeds();
});

/// Feed category filter
final feedFilterProvider = StateProvider<String>((ref) => 'All');

/// Filtered feed provider
final filteredFeedProvider = Provider<List<ScanFeed>>((ref) {
  final feeds = ref.watch(scanFeedProvider);
  final filter = ref.watch(feedFilterProvider);
  
  if (filter == 'All') return feeds;
  return MockScanFeed.getFeedsByCategory(filter);
});

/// User points provider
final userPointsProvider = StateProvider<int>((ref) => 2450);

// ==================== Settings State ====================

/// Notifications enabled provider
final notificationsEnabledProvider = StateProvider<bool>((ref) => true);

/// Dark mode provider (app is always dark mode)
final isDarkModeProvider = StateProvider<bool>((ref) => true);

/// User profile provider
final userProfileProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'name': 'Alex Chen',
    'email': 'alex.chen@email.com',
    'avatar': 'https://i.pravatar.cc/150?img=13',
    'membership': 'Pro Member',
    'joinedDate': DateTime(2023, 6, 15),
  };
});

/// App version provider
final appVersionProvider = Provider<String>((ref) => 'v2.4.1');

// ==================== UI State ====================

/// Bottom sheet visibility provider
final isBottomSheetOpenProvider = StateProvider<bool>((ref) => false);

/// Loading state provider
final isLoadingProvider = StateProvider<bool>((ref) => false);

/// Error message provider
final errorMessageProvider = StateProvider<String?>((ref) => null);

/// Success message provider
final successMessageProvider = StateProvider<String?>((ref) => null);

// ==================== Harvest Status State ====================

/// Current harvest status provider
final harvestStatusProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'plot': 'Plot B-4, Sasmita Farms',
    'grade': 'A',
    'variety': 'Alphonso Gold',
    'harvestEst': '2.4 Tons',
    'maturity': 92.0,
    'brixLevel': 18.0,
    'acidity': 4.2,
    'residue': 'Clean',
    'imageUrl': 'https://images.unsplash.com/photo-1553279768-865429fa0078?w=400',
  };
});

// ==================== Recent Scans State ====================

/// Recent scans provider for home screen
final recentScansProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [
    {
      'id': 'scan_001',
      'name': 'Plot A-12 Sample',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'grade': 'A',
      'image': 'https://images.unsplash.com/photo-1553279768-865429fa0078?w=100',
    },
    {
      'id': 'scan_002',
      'name': 'Plot C-08 Sample',
      'time': DateTime.now().subtract(const Duration(hours: 5)),
      'grade': 'B+',
      'image': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=100',
    },
    {
      'id': 'scan_003',
      'name': 'Plot D-03 Sample',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'grade': 'A+',
      'image': 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=100',
    },
  ];
});
