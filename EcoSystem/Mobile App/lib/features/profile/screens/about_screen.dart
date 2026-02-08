// =============================================================================
// ABOUT SCREEN - About REward App
// =============================================================================

import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About REward'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '♻️',
                  style: TextStyle(fontSize: 60),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Name
            const Text(
              'REward',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Text(
              'Recycle • Reward',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: AppColors.textHint),
            ),

            const SizedBox(height: 32),

            // Mission
            _InfoCard(
              icon: Icons.eco,
              title: 'Our Mission',
              content: 'REward aims to make recycling rewarding and accessible. We believe small actions can create big changes for our environment.',
            ),

            _InfoCard(
              icon: Icons.recycling,
              title: 'How It Works',
              content: 'Deposit your recyclables at any REward RVM kiosk, earn points for each item, and redeem points for real rewards from our partners.',
            ),

            _InfoCard(
              icon: Icons.handshake,
              title: 'Our Partners',
              content: 'We work with leading brands like Papa Johns, Kazyon, and more to bring you exclusive discounts and offers.',
            ),

            const SizedBox(height: 24),

            // Stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(value: '10K+', label: 'Users'),
                  _StatItem(value: '50K+', label: 'Items Recycled'),
                  _StatItem(value: '20+', label: 'Kiosks'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Social Links
            const Text(
              'Follow Us',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialButton(icon: Icons.facebook, onTap: () {}),
                const SizedBox(width: 16),
                _SocialButton(icon: Icons.camera_alt, onTap: () {}),
                const SizedBox(width: 16),
                _SocialButton(icon: Icons.alternate_email, onTap: () {}),
              ],
            ),

            const SizedBox(height: 32),

            // Footer
            Text(
              '© 2025 REward App',
              style: TextStyle(color: AppColors.textHint),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Privacy Policy'),
                ),
                const Text('•'),
                TextButton(
                  onPressed: () {},
                  child: const Text('Terms of Service'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}
