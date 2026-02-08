// =============================================================================
// MAIN SCAFFOLD - Bottom Navigation Container
// =============================================================================
// This widget provides the main app scaffold with a custom bottom navigation
// bar featuring a prominent center QR code button.
//
// Navigation Items:
// 1. Home      - Dashboard with offers
// 2. Profile   - User profile and settings
// 3. QR Code   - Central action button (identify at kiosk)
// 4. Rankings  - Leaderboard
// 5. Map       - Kiosk locations
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';

/// MainScaffold wraps the main app content with a custom bottom navigation bar.
/// The center item (QR Code) is elevated and styled differently to draw attention.
class MainScaffold extends StatelessWidget {
  /// The child widget to display (current route's screen)
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ---------------------------------------------------------------------------
      // Main Content Area
      // ---------------------------------------------------------------------------
      body: child,

      // ---------------------------------------------------------------------------
      // Bottom Navigation Bar
      // ---------------------------------------------------------------------------
      bottomNavigationBar: _buildBottomNavBar(context),

      // ---------------------------------------------------------------------------
      // Floating QR Code Button (overlays bottom nav)
      // ---------------------------------------------------------------------------
      floatingActionButton: _buildQrCodeButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// -------------------------------------------------------------------------
  /// Bottom Navigation Bar Builder
  /// -------------------------------------------------------------------------
  /// Creates a custom bottom app bar with navigation items.
  Widget _buildBottomNavBar(BuildContext context) {
    // Get current route to determine selected tab
    final String currentRoute = GoRouterState.of(context).uri.toString();

    return BottomAppBar(
      // Notch for the floating action button
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: AppColors.surface,
      elevation: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home
            _NavBarItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
              isSelected: currentRoute == RoutePaths.home,
              onTap: () => context.go(RoutePaths.home),
            ),
            // Profile
            _NavBarItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              isSelected: currentRoute == RoutePaths.profile,
              onTap: () => context.go(RoutePaths.profile),
            ),
            // Spacer for FAB
            const SizedBox(width: 48),
            // Rankings
            _NavBarItem(
              icon: Icons.leaderboard_outlined,
              activeIcon: Icons.leaderboard,
              label: 'Ranking',
              isSelected: currentRoute == RoutePaths.rankings,
              onTap: () => context.go(RoutePaths.rankings),
            ),
            // Map
            _NavBarItem(
              icon: Icons.map_outlined,
              activeIcon: Icons.map,
              label: 'Map',
              isSelected: currentRoute == RoutePaths.map,
              onTap: () => context.go(RoutePaths.map),
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// QR Code Floating Action Button
  /// -------------------------------------------------------------------------
  /// Central, prominent button for accessing the QR code screen.
  Widget _buildQrCodeButton(BuildContext context) {
    final String currentRoute = GoRouterState.of(context).uri.toString();
    final bool isSelected = currentRoute == RoutePaths.qrCode;

    return FloatingActionButton(
      onPressed: () => context.go(RoutePaths.qrCode),
      backgroundColor: isSelected ? AppColors.secondary : AppColors.primary,
      elevation: isSelected ? 8 : 4,
      child: const Icon(
        Icons.qr_code_2,
        size: 32,
        color: AppColors.textOnPrimary,
      ),
    );
  }
}

/// -----------------------------------------------------------------------------
/// Navigation Bar Item Widget
/// -----------------------------------------------------------------------------
/// Individual navigation item with icon and label.

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: 24,
            ),
            const SizedBox(height: 2),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
