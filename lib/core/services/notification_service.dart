import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    developer.log('Handling background notification message: ${message.messageId}');
  } catch (e) {
    developer.log('Background FCM initialization error: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important transaction and system alert notifications.',
    importance: Importance.high,
  );

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Request Notification Permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      developer.log('Notification permission status: ${settings.authorizationStatus}');

      // 2. Initialize Local Notifications Plugin for Foreground Alerts
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          developer.log('Notification tapped with payload: ${response.payload}');
        },
      );

      // 3. Create Android Notification Channel
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
      }

      // 4. Handle Foreground Notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log('Received foreground message: ${message.notification?.title}');
        _showForegroundNotification(message);
      });

      // 5. Handle Notification Tap (App opened from background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log('Notification clicked app opened: ${message.data}');
      });

      _isInitialized = true;
    } catch (e) {
      developer.log('Failed to initialize NotificationService: $e');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'NMillenium Alert',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<String?> getDeviceToken() async {
    try {
      final token = await _fcm.getToken();
      debugPrint('[FCM] Retrieved device token: $token');
      return token;
    } catch (e, stackTrace) {
      developer.log('Error getting FCM token: $e');
      debugPrint('[FCM ERROR] Failed to get device token: $e\n$stackTrace');
      return null;
    }
  }

  Future<void> syncDeviceToken(ApiClient apiClient) async {
    try {
      final token = await getDeviceToken();
      if (token == null || token.isEmpty) {
        debugPrint('[FCM] Device token is null/empty. Cannot sync to DB.');
        return;
      }

      debugPrint('[FCM] Syncing device token to backend: $token');
      final response = await apiClient.post(
        '/user/device-token',
        data: {
          'fcm_token': token,
          'device_type': Platform.isIOS ? 'ios' : 'android',
        },
      );
      debugPrint('[FCM] Sync response: status=${response.status}, message=${response.message}');
    } catch (e) {
      developer.log('Device token sync error: $e');
      debugPrint('[FCM ERROR] Device token sync request failed: $e');
    }
  }
}
