// =============================================================================
// REWARDS SCREEN - Browse & Redeem Rewards
// =============================================================================
// Placeholder for Rewards Catalog screen.
// TODO: Implement full rewards browsing and redemption flow.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// Placeholder RewardsScreen
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rewards'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: const Center(
        child: Text('Rewards Catalog - Coming Soon'),
      ),
    );
  }
}
