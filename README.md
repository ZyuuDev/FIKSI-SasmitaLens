# Sasmita Lens

Futuristic AgTech Solutions - A comprehensive fruit quality analysis mobile application built with Flutter.

## Features

### 1. Animated Splash Screen
- Custom animated logo with rotating outer border
- Pulsing laser effect using `AnimationController`
- Progress indicator with system calibration simulation
- Smooth fade transition to main layout after 3 seconds

### 2. Main Layout & Custom Bottom Navigation
- Scaffold with floating custom BottomNavigationBar
- 5 navigation indexes with center FloatingActionButton
- PageController for smooth page swiping
- Animated transitions between screens

### 3. Camera Scan & Dynamic Bottom Sheet
- Simulated camera view with animated scanning reticle
- `flutter_animate` package for physics-based animations
- Glassmorphism bottom sheet with blur backdrop
- Comprehensive fruit analysis display:
  - Brix level, water content, freshness
  - Pesticide/residue status
  - Best before date
  - AI-generated recipes
- Social features: star rating and location tagging

### 4. Gamified Leaderboard & Social Feed
- Vendor points calculation algorithm:
  - `(Total Scans * 2) + (Average Rating * 10) + (Freshness Consistency Bonus)`
- Top verified vendors podium display
- Real-time social feed with "X mins ago" timestamps
- Category filters (All, Mangoes, Coffee, Verified, etc.)

### 5. Device Sync Logic
- 6-digit alphanumeric Sasmita Lens ID validation
- Connection state management with Riverpod
- Success/error SnackBar feedback
- Battery level and connection status display

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Animations**: flutter_animate
- **UI Components**: Material Design 3, Custom Painters
- **Utilities**: intl (date formatting)

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── fruit_analysis.dart   # Fruit scan results
│   ├── vendor_rating.dart    # Vendor leaderboard data
│   └── scan_feed.dart        # Social feed items
├── providers/                # Riverpod state management
│   └── app_providers.dart    # All app state providers
├── screens/                  # UI screens
│   ├── splash_screen.dart    # Animated splash
│   ├── main_layout.dart      # Bottom nav layout
│   ├── home_screen.dart      # Dashboard
│   ├── device_sync_screen.dart
│   ├── leaderboard_screen.dart
│   ├── settings_screen.dart
│   └── scan_screen.dart      # Camera & results
├── utils/                    # Utilities
│   └── app_theme.dart        # Colors, themes, constants
└── widgets/                  # Reusable widgets
    ├── animated_logo.dart
    ├── circular_progress.dart
    ├── recent_scan_card.dart
    ├── scanning_reticle.dart
    └── star_rating.dart
```

## Getting Started

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd sasmita_lens
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.9
  flutter_animate: ^4.3.0
  cupertino_icons: ^1.0.6
  glassmorphism: ^3.0.0
  intl: ^0.18.1
  flutter_svg: ^2.0.9
```

## Design System

### Colors
- **Primary Green**: `#00E676`
- **Background Dark**: `#0A1F15`
- **Card Background**: `#1A2F24`
- **Accent Orange**: `#FF9800`
- **Success**: `#00E676`
- **Warning**: `#FFC107`
- **Error**: `#FF5252`

### Typography
- Headlines: Inter/SF Pro, Bold
- Body: Inter/SF Pro, Regular
- Labels: Uppercase, Letter-spacing 1.5

## Key Implementation Details

### AnimationController Usage (Splash Screen)
```dart
_rotationController = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 8),
);
_rotationController.repeat();
```

### Riverpod State Management
```dart
final isDeviceConnectedProvider = StateProvider<bool>((ref) => false);
final deviceConnectionProvider = StateNotifierProvider<...>(...);
```

### Custom Bottom Navigation
```dart
Custom BottomNavigationBar with:
- 5 navigation items
- Center FloatingActionButton
- PageController for page swiping
```

### Glassmorphism Bottom Sheet
```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
  child: Container(...)
)
```

## License

This project is proprietary and confidential.

## Author

Sasmita AgTech Solutions
