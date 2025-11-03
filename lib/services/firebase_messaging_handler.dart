import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
}

class FirebaseMessagingHandler {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final NotificationService _notificationService = NotificationService();

  /// Initialize Firebase Messaging with handlers
  static Future<void> initialize() async {
    try {
      // Set the background messaging handler early on, as a named top-level function
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User granted permission: ${settings.authorizationStatus}');

      // Get and store FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        // Store token will be handled when user logs in
      }

      // Handle token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        // Update token in user document when user is logged in
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
          // Show local notification or update UI
          _handleForegroundMessage(message);
        }
      });

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        debugPrint('Message data: ${message.data}');
        
        // Navigate to specific screen based on notification data
        _handleNotificationTap(message);
      });

      // Check if app was launched from a notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App launched from notification: ${initialMessage.messageId}');
        _handleNotificationTap(initialMessage);
      }

    } catch (e) {
      debugPrint('Error initializing Firebase Messaging: $e');
    }
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    // You can show a local notification here or update the UI
    // For now, we'll just log the message
    debugPrint('Foreground message: ${message.notification?.title}');
    debugPrint('Foreground message body: ${message.notification?.body}');
  }

  /// Handle notification tap navigation
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    
    // Navigate based on notification type or action URL
    if (data.containsKey('actionUrl')) {
      final actionUrl = data['actionUrl'] as String;
      debugPrint('Should navigate to: $actionUrl');
      
      // Here you would implement navigation logic
      // For example, using a global navigator key or a navigation service
      // NavigationService.navigateTo(actionUrl);
    }
    
    // Handle specific notification types
    if (data.containsKey('type')) {
      final type = data['type'] as String;
      switch (type) {
        case 'leave_approved':
        case 'leave_rejected':
          debugPrint('Should navigate to leave requests page');
          break;
        case 'task_assigned':
        case 'task_completed':
          debugPrint('Should navigate to tasks page');
          break;
        case 'claim_approved':
        case 'claim_rejected':
          debugPrint('Should navigate to claims page');
          break;
        case 'payroll_generated':
          debugPrint('Should navigate to payroll page');
          break;
        default:
          debugPrint('Unknown notification type: $type');
      }
    }
  }

  /// Store FCM token for a user
  static Future<void> storeFCMToken(String userId) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _notificationService.storeFCMToken(userId, token);
        debugPrint('FCM token stored for user: $userId');
      }
    } catch (e) {
      debugPrint('Error storing FCM token: $e');
    }
  }

  /// Subscribe to topic for broadcast notifications
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }
}