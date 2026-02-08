// =============================================================================
// RANKINGS SCREEN - Leaderboard
// =============================================================================
// Displays user rankings based on recycling activity.
//
// Features:
// - Weekly and All-Time tabs
// - Top 3 podium display
// - Full leaderboard list
// - Current user position highlight
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_auth_service.dart';

/// Leaderboard entry model
class LeaderboardEntry {
  final String rank;
  final String name;
  final int points;
  final String avatarLetter;
  final bool isCurrentUser;
  final String odId; // User ID

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.points,
    required this.avatarLetter,
    this.isCurrentUser = false,
    this.odId = '',
  });

  factory LeaderboardEntry.fromAppUser(AppUser user, int position, String? currentUserId) {
    return LeaderboardEntry(
      rank: position.toString(),
      name: user.name,
      points: user.totalPoints,
      avatarLetter: user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
      isCurrentUser: user.id == currentUserId,
      odId: user.id,
    );
  }
}

/// RankingsScreen displays the leaderboard
class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<LeaderboardEntry> _leaderboardData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadLeaderboard();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadLeaderboard();
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    
    final authService = context.read<FirebaseAuthService>();
    final currentUserId = authService.currentUser?.id;
    
    try {
      final users = _tabController.index == 0 
          ? await authService.getWeeklyLeaderboard()
          : await authService.getLeaderboard();
      
      _leaderboardData = users.asMap().entries.map((entry) {
        return LeaderboardEntry.fromAppUser(entry.value, entry.key + 1, currentUserId);
      }).toList();
    } catch (e) {
      _leaderboardData = [];
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // ---------------------------------------------------------------
            // Header
            // ---------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Leaderboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tab bar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textOnPrimary,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'Weekly'),
                        Tab(text: 'All-Time'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---------------------------------------------------------------
            // Leaderboard Content
            // ---------------------------------------------------------------
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _leaderboardData.isEmpty
                        ? _buildEmptyState()
                        : _buildLeaderboard(_leaderboardData),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'No rankings yet',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Start recycling to appear on the leaderboard!',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(List<LeaderboardEntry> data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top 3 Podium
        if (data.length >= 3) _buildPodium(data.take(3).toList()),
        const SizedBox(height: 24),

        // Rest of the list
        ...data.skip(3).map((entry) => _LeaderboardTile(entry: entry)),

        // Current user position
        const SizedBox(height: 16),
        _buildCurrentUserCard(),

        const SizedBox(height: 80), // Bottom nav padding
      ],
    );
  }

  /// Build the top 3 podium
  Widget _buildPodium(List<LeaderboardEntry> topThree) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        _PodiumItem(
          entry: topThree[1],
          height: 100,
          color: const Color(0xFFC0C0C0), // Silver
          position: 2,
        ),
        const SizedBox(width: 8),
        // 1st place
        _PodiumItem(
          entry: topThree[0],
          height: 130,
          color: const Color(0xFFFFD700), // Gold
          position: 1,
        ),
        const SizedBox(width: 8),
        // 3rd place
        _PodiumItem(
          entry: topThree[2],
          height: 80,
          color: const Color(0xFFCD7F32), // Bronze
          position: 3,
        ),
      ],
    );
  }

  /// Build current user card (showing their actual rank)
  Widget _buildCurrentUserCard() {
    final authService = context.read<FirebaseAuthService>();
    final user = authService.currentUser;
    if (user == null) return const SizedBox.shrink();

    // Find user's position in the leaderboard
    final userPosition = _leaderboardData.indexWhere((e) => e.isCurrentUser);
    final rankDisplay = userPosition >= 0 ? '#${userPosition + 1}' : '#-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            rankDisplay,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'YOU',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${user.totalPoints} points',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Removed hardcoded +3 - would need actual rank change tracking
        ],
      ),
    );
  }
}

/// Podium item widget
class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final Color color;
  final int position;

  const _PodiumItem({
    required this.entry,
    required this.height,
    required this.color,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              entry.avatarLetter,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Name
        SizedBox(
          width: 80,
          child: Text(
            entry.name.split(' ').first,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Points
        Text(
          '${entry.points}',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        // Podium block
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withOpacity(0.7)],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Text(
              '$position',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Leaderboard tile widget
class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: entry.isCurrentUser
            ? Border.all(color: AppColors.primary)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: entry.isCurrentUser
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.avatarLetter,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Row(
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        entry.isCurrentUser ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (entry.isCurrentUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'YOU',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Points
          Text(
            '${entry.points} pts',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
