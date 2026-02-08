// =============================================================================
// BADGES SCREEN - User's Earned Badges
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_auth_service.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  // Default badges if Firestore badges collection is empty
  static const List<Map<String, dynamic>> _defaultBadges = [
    {
      'id': 'first_bottle',
      'name': 'First Steps',
      'description': 'Recycle your first bottle',
      'icon': '🍼',
      'requirement': 'recycledCount',
      'threshold': 1,
    },
    {
      'id': 'recycler_10',
      'name': 'Getting Started',
      'description': 'Recycle 10 items',
      'icon': '♻️',
      'requirement': 'recycledCount',
      'threshold': 10,
    },
    {
      'id': 'recycler_50',
      'name': 'Eco Warrior',
      'description': 'Recycle 50 items',
      'icon': '🌱',
      'requirement': 'recycledCount',
      'threshold': 50,
    },
    {
      'id': 'recycler_100',
      'name': 'Century Club',
      'description': 'Recycle 100 items',
      'icon': '🏆',
      'requirement': 'recycledCount',
      'threshold': 100,
    },
    {
      'id': 'points_500',
      'name': 'Points Collector',
      'description': 'Earn 500 total points',
      'icon': '⭐',
      'requirement': 'totalPoints',
      'threshold': 500,
    },
    {
      'id': 'points_1000',
      'name': 'Points Master',
      'description': 'Earn 1000 total points',
      'icon': '🌟',
      'requirement': 'totalPoints',
      'threshold': 1000,
    },
    {
      'id': 'points_5000',
      'name': 'Points Legend',
      'description': 'Earn 5000 total points',
      'icon': '💫',
      'requirement': 'totalPoints',
      'threshold': 5000,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<FirebaseAuthService>();
    final user = authService.currentUser;
    final earnedBadges = user?.badges ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Badges'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: authService.getAllBadges(),
        builder: (context, snapshot) {
          final badges = snapshot.data?.isNotEmpty == true 
              ? snapshot.data! 
              : _defaultBadges;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Earned',
                      value: earnedBadges.length.toString(),
                      icon: Icons.emoji_events,
                    ),
                    _StatItem(
                      label: 'Total',
                      value: badges.length.toString(),
                      icon: Icons.military_tech,
                    ),
                    _StatItem(
                      label: 'Recycled',
                      value: (user?.recycledCount ?? 0).toString(),
                      icon: Icons.recycling,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Badges Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  final isEarned = earnedBadges.contains(badge['id']);
                  return _BadgeItem(badge: badge, isEarned: isEarned);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final Map<String, dynamic> badge;
  final bool isEarned;

  const _BadgeItem({required this.badge, required this.isEarned});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEarned
              ? AppColors.secondary.withOpacity(0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isEarned
              ? Border.all(color: AppColors.secondary, width: 2)
              : Border.all(color: AppColors.textHint.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge['icon'] ?? '🏅',
              style: TextStyle(
                fontSize: 32,
                color: isEarned ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge['name'] ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isEarned ? AppColors.textPrimary : AppColors.textHint,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isEarned)
              Icon(
                Icons.lock,
                size: 12,
                color: AppColors.textHint,
              ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              badge['icon'] ?? '🏅',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              badge['name'] ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge['description'] ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isEarned
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isEarned ? '✓ Earned!' : 'Required: ${badge['threshold']} ${badge['requirement']}',
                style: TextStyle(
                  color: isEarned ? AppColors.success : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
