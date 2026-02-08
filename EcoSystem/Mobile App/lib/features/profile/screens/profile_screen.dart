// =============================================================================
// PROFILE SCREEN - User Profile & Settings
// =============================================================================
// User profile screen displaying:
// - Profile picture and name
// - Points balance (current & total)
// - My Coupons section
// - Points history link
// - Support and settings options
// - Logout button
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_auth_service.dart';

/// ProfileScreen displays user information and account options
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<FirebaseAuthService>();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ---------------------------------------------------------------
              // Profile Header
              // ---------------------------------------------------------------
              _ProfileHeader(user: user),

              const SizedBox(height: 24),

              // ---------------------------------------------------------------
              // Points Cards
              // ---------------------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: _PointsCard(
                      title: 'Current Points',
                      points: user?.currentPoints ?? 0,
                      icon: Icons.stars,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PointsCard(
                      title: 'Total Earned',
                      points: user?.totalPoints ?? 0,
                      icon: Icons.trending_up,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ---------------------------------------------------------------
              // Menu Items
              // ---------------------------------------------------------------
              _MenuSection(
                title: 'My Account',
                items: [
                  _MenuItem(
                    icon: Icons.qr_code_2,
                    title: 'My QR Code',
                    subtitle: 'Show at recycling kiosks',
                    onTap: () => context.go(RoutePaths.qrCode),
                  ),
                  _MenuItem(
                    icon: Icons.confirmation_number,
                    title: 'My Coupons',
                    subtitle: 'View redeemed rewards',
                    onTap: () => context.push(RoutePaths.coupons),
                  ),
                  _MenuItem(
                    icon: Icons.history,
                    title: 'Points History',
                    subtitle: 'View all transactions',
                    onTap: () => context.push(RoutePaths.pointsHistory),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _MenuSection(
                title: 'Achievements',
                items: [
                  _MenuItem(
                    icon: Icons.emoji_events,
                    title: 'Badges',
                    subtitle: 'View earned badges',
                    trailing: _BadgeCount(count: user?.badges.length ?? 0),
                    onTap: () => context.push(RoutePaths.badges),
                  ),
                  FutureBuilder<int>(
                    future: authService.getUserRankPosition(),
                    builder: (context, snapshot) {
                      final rank = snapshot.data ?? 0;
                      return _MenuItem(
                        icon: Icons.leaderboard,
                        title: 'My Ranking',
                        subtitle: 'View your position',
                        trailing: Text(
                          rank > 0 ? '#$rank' : '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        onTap: () => context.go(RoutePaths.rankings),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _MenuSection(
                title: 'Support',
                items: [
                  _MenuItem(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    subtitle: 'FAQs and guides',
                    onTap: () => context.push(RoutePaths.helpCenter),
                  ),
                  _MenuItem(
                    icon: Icons.info_outline,
                    title: 'About REward',
                    subtitle: 'App version 1.0.0',
                    onTap: () => context.push(RoutePaths.about),
                  ),
                  // Admin Dashboard - only visible for admins
                  if (user?.isAdmin == true)
                    _MenuItem(
                      icon: Icons.admin_panel_settings,
                      title: 'Admin Dashboard',
                      subtitle: 'Manage offers and users',
                      onTap: () => context.push(RoutePaths.adminDashboard),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // ---------------------------------------------------------------
              // Logout Button
              // ---------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Show confirmation dialog
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Logout',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      await authService.logout();
                      context.go(RoutePaths.login);
                    }
                  },
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),

              const SizedBox(height: 100), // Bottom nav padding
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile header with avatar and user info
class _ProfileHeader extends StatelessWidget {
  final AppUser? user;

  const _ProfileHeader({this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              user?.name.isNotEmpty == true
                  ? user!.name[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Name
        Text(
          user?.name ?? 'User',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        // Email
        Text(
          user?.email ?? 'user@email.com',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        // Rank badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium,
                size: 16,
                color: _getRankColor(user?.rank ?? 'Bronze'),
              ),
              const SizedBox(width: 4),
              Text(
                user?.rank ?? 'Bronze',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getRankColor(user?.rank ?? 'Bronze'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Edit Profile Button
        OutlinedButton.icon(
          onPressed: () => context.push(RoutePaths.editProfile),
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Edit Profile'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'Platinum':
        return const Color(0xFF9CA3AF);
      case 'Gold':
        return const Color(0xFFFBBF24);
      case 'Silver':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFFCD7F32);
    }
  }
}

/// Points display card
class _PointsCard extends StatelessWidget {
  final String title;
  final int points;
  final IconData icon;
  final Color color;

  const _PointsCard({
    required this.title,
    required this.points,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            '$points',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu section with title and items
class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _MenuSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Menu item widget
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: trailing ?? const Icon(
        Icons.chevron_right,
        color: AppColors.textHint,
      ),
    );
  }
}

/// Badge count indicator
class _BadgeCount extends StatelessWidget {
  final int count;

  const _BadgeCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
