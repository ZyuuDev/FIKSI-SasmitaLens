# Sasmita Lens - Flutter Project Summary

## Project Overview
A comprehensive AgTech mobile application for fruit quality analysis with gamified social features.

## File Structure

```
sasmita_lens/
├── README.md                          # Project documentation
├── PROJECT_SUMMARY.md                 # This file
├── analysis_options.yaml              # Dart linting rules
├── pubspec.yaml                       # Dependencies
├── assets/                            # Static assets
│   ├── images/
│   └── icons/
└── lib/
    ├── main.dart                      # App entry point
    ├── models/                        # Data models
    │   ├── fruit_analysis.dart        # Fruit scan results model
    │   ├── vendor_rating.dart         # Vendor leaderboard model
    │   ├── scan_feed.dart             # Social feed model
    │   └── models.dart                # Barrel export
    ├── providers/                     # Riverpod state management
    │   ├── app_providers.dart         # All app providers
    │   └── providers.dart             # Barrel export
    ├── screens/                       # UI screens
    │   ├── splash_screen.dart         # Animated splash
    │   ├── main_layout.dart           # Bottom nav + PageController
    │   ├── home_screen.dart           # Dashboard with harvest status
    │   ├── device_sync_screen.dart    # Device connection
    │   ├── leaderboard_screen.dart    # Vendor rankings + social feed
    │   ├── settings_screen.dart       # User preferences
    │   ├── scan_screen.dart           # Camera + results sheet
    │   └── screens.dart               # Barrel export
    ├── utils/                         # Utilities
    │   ├── app_theme.dart             # Colors, themes, constants
    │   └── utils.dart                 # Barrel export
    └── widgets/                       # Reusable widgets
        ├── animated_logo.dart         # Custom logo painter
        ├── circular_progress.dart     # Progress indicators
        ├── recent_scan_card.dart      # Scan list items
        ├── scanning_reticle.dart      # Camera overlay
        ├── star_rating.dart           # Rating widget
        └── widgets.dart               # Barrel export
```

## Features Implemented

### 1. Animated Splash Screen (`splash_screen.dart`)
- **AnimationController** for rotation and pulse animations
- Custom `AnimatedLogoPainter` with rotating dotted/dashed circles
- Pulsing laser line effect
- Progress bar with system calibration simulation
- 3-second timer with `Navigator.pushReplacement` fade transition

### 2. Main Layout (`main_layout.dart`)
- **Scaffold** with custom floating BottomNavigationBar
- 5 navigation indexes (0: Home, 1: Device, 2: Scan FAB, 3: Leaderboard, 4: Settings)
- **PageController** for horizontal page swiping
- Center FloatingActionButton with glow animation

### 3. Camera Scan & Bottom Sheet (`scan_screen.dart`)
- Simulated camera view with static fruit image
- **ScanningReticle** widget with animated scanning line
- **showModalBottomSheet** with `isScrollControlled: true`
- Glassmorphism backdrop using `ImageFilter.blur`
- **FruitAnalysis** model with all required fields:
  - type, brix, waterContent, hasResidue, bestBefore
  - storageTips (List<String>)
  - aiRecipes (List<AIRecipe>)
- Social features: Star rating (1-5) + location text field

### 4. Gamified Leaderboard (`leaderboard_screen.dart`)
- **VendorRating** model with points calculation:
  ```dart
  points = (totalScans * 2) + (averageRating * 10) + (freshnessBonus * 5)
  ```
- Sorted vendors by total points (descending)
- Podium display for top 3 vendors
- **ScanFeed** with "X mins ago" timestamp formatting
- Category filters (All, Mangoes, Coffee, Verified, etc.)

### 5. Device Sync (`device_sync_screen.dart`)
- Clean input screen with device ID field
- **TextEditingController** for input handling
- 6-digit alphanumeric validation logic:
  ```dart
  RegExp(r'^[A-Z0-9]{6}$')
  ```
- Success/error SnackBar feedback
- Global state: `isDeviceConnectedProvider`

## State Management (Riverpod)

### Key Providers
```dart
// Navigation
currentTabIndexProvider     // Current bottom nav index
pageControllerProvider      // PageController instance

// Device
deviceConnectionProvider    // Async connection state
isDeviceConnectedProvider   // Boolean connection status
deviceIdProvider           // Connected device ID

// Scan
scanProvider               // Async scan result
currentScanResultProvider  // Current scan data

// Leaderboard
vendorsProvider            // List of vendors
sortedVendorsProvider      // Sorted by points
topVendorsProvider         // Top 3 vendors

// Social
scanFeedProvider           // Feed items list
feedFilterProvider         // Category filter

// Settings
notificationsEnabledProvider
userProfileProvider
userPointsProvider
```

## Theme & Design System

### Colors (AppTheme)
- `primaryGreen`: #00E676
- `backgroundDark`: #0A1F15
- `backgroundCard`: #1A2F24
- `accentOrange`: #FF9800
- `statusSuccess`: #00E676
- `statusError`: #FF5252

### Typography
- Display: 32px Bold
- Headline: 22px SemiBold
- Title: 16px SemiBold
- Body: 14px Regular
- Label: 12px Uppercase

## Dependencies

```yaml
flutter_riverpod: ^2.4.9    # State management
flutter_animate: ^4.3.0      # Physics-based animations
glassmorphism: ^3.0.0        # Glass effects
intl: ^0.18.1               # Date formatting
flutter_svg: ^2.0.9         # SVG support
```

## How to Run

1. Install Flutter SDK 3.0+
2. Run `flutter pub get`
3. Run `flutter run`

## Edge Cases Handled

- Null data in models with default values
- Image loading errors with fallback widgets
- Empty input validation
- Network state handling
- Form validation with user feedback
- Animation disposal in StatefulWidgets

## Custom Widgets

| Widget | Purpose |
|--------|---------|
| AnimatedLogoPainter | Custom splash logo with rotation |
| ScanningReticle | Camera overlay with animated line |
| CircularProgressWidget | Metric display with progress ring |
| StarRating | Interactive 5-star rating |
| StarRatingDisplay | Read-only rating display |
| StatusBadge | Grade/status indicators |
| RecentScanCard | Home screen scan list items |
| QualityScoreCircle | Scan result quality indicator |

## Mock Data

All mock data is provided via static methods:
- `FruitAnalysis.mock()` - Sample scan result
- `MockVendors.getVendors()` - Leaderboard data
- `MockScanFeed.getFeeds()` - Social feed items
