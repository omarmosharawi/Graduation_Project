// =============================================================================
// NOTIFICATIONS SCREEN - Activity & Updates
// =============================================================================
// Displays notification timeline from Firestore including:
// - Points earned from recycling
// - Rewards redeemed
// - Rank/badge achievements
// - System announcements (from admin)
// =============================================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_auth_service.dart';

/// Notification type enum
enum NotificationType {
  pointsEarned,
  rewardRedeemed,
  achievement,
  announcement,
}

/// Unified notification item (combines user notifications + global announcements)
class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final bool isAnnouncement;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.isAnnouncement = false,
  });
}

/// NotificationsScreen displays all user notifications from Firestore
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<FirebaseAuthService>();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              authService.markAllNotificationsAsRead();
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(color: AppColors.textOnPrimary),
            ),
          ),
        ],
      ),
      body: _NotificationsList(authService: authService),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  final FirebaseAuthService authService;

  const _NotificationsList({required this.authService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationItem>>(
      stream: _getMergedNotificationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final notifications = snapshot.data!;

        // Group notifications by date
        final today = <NotificationItem>[];
        final yesterday = <NotificationItem>[];
        final older = <NotificationItem>[];

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final yesterdayStart = todayStart.subtract(const Duration(days: 1));

        for (final item in notifications) {
          if (item.timestamp.isAfter(todayStart)) {
            today.add(item);
          } else if (item.timestamp.isAfter(yesterdayStart)) {
            yesterday.add(item);
          } else {
            older.add(item);
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Today
            if (today.isNotEmpty) ...[
              _buildSectionHeader('Today'),
              ...today.map((item) => _NotificationCard(
                item: item,
                onTap: () {
                  if (!item.isAnnouncement) {
                    authService.markNotificationAsRead(item.id);
                  }
                  if (item.type == 'rewardRedeemed') {
                    context.push(RoutePaths.offers);
                  }
                },
              )),
              const SizedBox(height: 16),
            ],
            // Yesterday
            if (yesterday.isNotEmpty) ...[
              _buildSectionHeader('Yesterday'),
              ...yesterday.map((item) => _NotificationCard(
                item: item,
                onTap: () {
                  if (!item.isAnnouncement) {
                    authService.markNotificationAsRead(item.id);
                  }
                  if (item.type == 'rewardRedeemed') {
                    context.push(RoutePaths.offers);
                  }
                },
              )),
              const SizedBox(height: 16),
            ],
            // Older
            if (older.isNotEmpty) ...[
              _buildSectionHeader('Older'),
              ...older.map((item) => _NotificationCard(
                item: item,
                onTap: () {
                  if (!item.isAnnouncement) {
                    authService.markNotificationAsRead(item.id);
                  }
                  if (item.type == 'rewardRedeemed') {
                    context.push(RoutePaths.offers);
                  }
                },
              )),
            ],
          ],
        );
      },
    );
  }

  /// Merge user notifications with global announcements
  Stream<List<NotificationItem>> _getMergedNotificationsStream() {
    final userId = authService.currentUser?.id;
    if (userId == null) return Stream.value([]);

    // User notifications stream
    final userNotificationsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return NotificationItem(
                id: doc.id,
                type: data['type'] ?? 'general',
                title: data['title'] ?? 'Notification',
                message: data['message'] ?? '',
                timestamp: _parseDateTime(data['timestamp']),
                isRead: data['isRead'] ?? false,
                isAnnouncement: false,
              );
            }).toList());

    // Global announcements stream
    final announcementsStream = FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return NotificationItem(
                id: doc.id,
                type: 'announcement',
                title: data['title'] ?? 'Announcement',
                message: data['message'] ?? '',
                timestamp: _parseDateTime(data['createdAt']),
                isRead: true, // Announcements don't have read state
                isAnnouncement: true,
              );
            }).toList());

    // Combine both streams
    late StreamController<List<NotificationItem>> controller;
    StreamSubscription? sub1;
    StreamSubscription? sub2;
    List<NotificationItem> userList = [];
    List<NotificationItem> annList = [];

    void emit() {
      if (controller.isClosed) return;
      final combined = [...userList, ...annList];
      combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      controller.add(combined);
    }

    controller = StreamController<List<NotificationItem>>.broadcast(
      onListen: () {
        sub1 = userNotificationsStream.listen((data) {
          userList = data;
          emit();
        });
        sub2 = announcementsStream.listen((data) {
          annList = data;
          emit();
        });
      },
      onCancel: () {
        sub1?.cancel();
        sub2?.cancel();
      },
    );

    return controller.stream;
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!\nStart recycling to get updates.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Notification card widget
class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: item.isRead ? AppColors.surface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: item.isAnnouncement 
            ? Border.all(color: AppColors.secondary.withOpacity(0.5), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTypeColor(item.type).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTypeIcon(item.type),
                    color: _getTypeColor(item.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.isAnnouncement)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ANNOUNCEMENT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTimestamp(item.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                // Unread indicator
                if (!item.isRead && !item.isAnnouncement)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'points_earned':
        return Icons.add_circle;
      case 'rewardRedeemed':
        return Icons.card_giftcard;
      case 'achievement':
        return Icons.emoji_events;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'points_earned':
        return AppColors.success;
      case 'rewardRedeemed':
        return AppColors.primary;
      case 'achievement':
        return AppColors.secondary;
      case 'announcement':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
