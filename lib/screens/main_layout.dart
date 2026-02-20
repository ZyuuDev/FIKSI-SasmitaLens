import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_theme.dart';
import '../providers/app_providers.dart';
import 'home_screen.dart';
import 'device_sync_screen.dart';
import 'leaderboard_screen.dart';
import 'settings_screen.dart';
import 'scan_screen.dart';

/// Main Layout with Custom Bottom Navigation
/// Features 5 navigation items with center FloatingActionButton
class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = ref.read(pageControllerProvider);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(currentTabIndexProvider.notifier).state = index;
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      // Center button - open scan modal
      _openScanModal();
    } else {
      // Navigate to page
      final pageIndex = index > 2 ? index - 1 : index;
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openScanModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ScanScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentTabIndexProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: const [
          HomeScreen(),
          DeviceSyncScreen(),
          LeaderboardScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _CustomBottomNavigationBar(
        currentIndex: currentIndex == 2 ? 3 : (currentIndex > 1 ? currentIndex + 1 : currentIndex),
        onTap: _onItemTapped,
      ),
    );
  }
}

/// Custom Bottom Navigation Bar
/// Features 5 items with center FloatingActionButton
class _CustomBottomNavigationBar extends StatelessWidget {

  const _CustomBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });
  final int currentIndex;
  final Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Home
            _NavItem(
              icon: Icons.home_rounded,
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            
            // Device Sync
            _NavItem(
              icon: Icons.qr_code_scanner_rounded,
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            
            // Center Scan Button
            _CenterScanButton(
              onTap: () => onTap(2),
            ),
            
            // Leaderboard
            _NavItem(
              icon: Icons.leaderboard_rounded,
              isSelected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            
            // Settings
            _NavItem(
              icon: Icons.person_outline_rounded,
              isSelected: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    ).animate().slideY(
          begin: 1,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOut,
        );
  }
}

/// Navigation Item Widget
class _NavItem extends StatelessWidget {

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppTheme.primaryGreen : AppTheme.textMuted,
          size: 24,
        ),
      ),
    );
  }
}

/// Center Scan Button Widget
class _CenterScanButton extends StatelessWidget {

  const _CenterScanButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppTheme.primaryGreen,
              AppTheme.primaryGreenDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.black,
          size: 32,
        ),
      )
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 1.5.seconds,
            curve: Curves.easeInOut,
          ),
    );
  }
}
