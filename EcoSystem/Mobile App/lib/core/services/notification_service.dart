// =============================================================================
// NOTIFICATION SERVICE - Firebase Cloud Messaging
// =============================================================================
// Handles push notifications for:
// - Points earned from recycling
// - New offers added
// - Admin announcements
// =============================================================================

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/logger.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('Background message: ${message.notification?.title}');
}

/// Notification Service for FCM
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    // Request permission
    await _requestPermission();
    
    // Initialize local notifications (for foreground)
    await _initLocalNotifications();
    
    // Get FCM token
    _fcmToken = await _messaging.getToken();
    AppLogger.info('FCM Token: $_fcmToken');

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      AppLogger.info('FCM Token refreshed: $token');
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Subscribe to topics
    await subscribeToTopics();
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    AppLogger.info('Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications for foreground display
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        AppLogger.info('Notification tapped: ${response.payload}');
      },
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'reward_notifications',
      'REward Notifications',
      description: 'Notifications for points, offers, and announcements',
      importance: Importance.high,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle foreground message - show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info('Foreground message: ${message.notification?.title}');
    
    final notification = message.notification;
    if (notification != null) {
      showLocalNotification(
        title: notification.title ?? 'REward',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle when user taps notification to open app
  void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.info('Message opened app: ${message.notification?.title}');
    // Navigate based on message data if needed
  }

  /// Show local notification (for foreground)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'reward_notifications',
      'REward Notifications',
      channelDescription: 'Notifications for points, offers, and announcements',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Subscribe to notification topics
  Future<void> subscribeToTopics() async {
    await _messaging.subscribeToTopic('all_users');
    await _messaging.subscribeToTopic('offers_updates');
    AppLogger.info('Subscribed to notification topics');
  }

  /// Unsubscribe from topics (for logout)
  Future<void> unsubscribeFromTopics() async {
    await _messaging.unsubscribeFromTopic('all_users');
    await _messaging.unsubscribeFromTopic('offers_updates');
    AppLogger.info('Unsubscribed from notification topics');
  }

  /// Store FCM token in user document
  Future<void> saveTokenToFirestore(String userId) async {
    if (_fcmToken == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('FCM token saved for user: $userId');
    } catch (e) {
      AppLogger.error('Failed to save FCM token: $e');
    }
  }

  /// Send notification to specific user (server-side - for reference)
  /// This should be called from your Hostinger API, not directly from app
  /// Uses Firebase Admin SDK or HTTP v1 API
  static Map<String, dynamic> buildPointsNotification({
    required String fcmToken,
    required int points,
    required int itemCount,
  }) {
    return {
      'to': fcmToken,
      'notification': {
        'title': 'Points Earned! 🎉',
        'body': 'You earned $points points for recycling $itemCount items!',
      },
      'data': {
        'type': 'points_earned',
        'points': points.toString(),
      },
    };
  }

  /// Send push notification to a topic (for announcements)
  /// Note: This requires FCM server key - works for testing but should be done server-side
  Future<bool> sendPushToTopic({
    required String topic,
    required String title,
    required String body,
  }) async {
    // For now, just show local notification as demo
    // Real FCM topic sending requires server key which shouldn't be in app
    AppLogger.info('Push to topic $topic: $title');
    
    // Show local notification for the sender's device
    await showLocalNotification(
      title: title,
      body: body,
      payload: 'topic:$topic',
    );
    
    return true;
  }
}
