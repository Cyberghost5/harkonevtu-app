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
    playSound: true,
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
        criticalAlert: true,
      );

      developer.log('Notification permission status: ${settings.authorizationStatus}');

      // 2. Configure Foreground Presentation Options
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Initialize Local Notifications Plugin for Foreground & Data-only Alerts
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

      // 4. Create Android Notification Channel & Request Android 13+ Permissions
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
        await androidPlugin.requestNotificationsPermission();
      }

      // 5. Handle Foreground Notifications (Supports Notification & Data Payloads)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log('Received foreground message: ${message.notification?.title ?? message.data['title']}');
        _showForegroundNotification(message);
      });

      // 6. Handle Notification Tap (App opened from background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log('Notification clicked app opened: ${message.data}');
      });

      // 7. Check Terminated App Launch via Notification
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        developer.log('App opened from terminated state via notification: ${initialMessage.data}');
      }

      // 8. Listen for Token Refresh
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        syncDeviceToken(ApiClient());
      });

      _isInitialized = true;
    } catch (e) {
      developer.log('Failed to initialize NotificationService: $e');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? message.data['subject'] ?? 'Notification';
    final body = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? message.data['description'] ?? '';

    if (title.isNotEmpty || body.isNotEmpty) {
      final androidIcon = message.notification?.android?.smallIcon ?? '@mipmap/ic_launcher';

      _localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: androidIcon,
            playSound: true,
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
      final payload = {
        'fcm_token': token,
        'device_token': token,
        'push_token': token,
        'token': token,
        'device_type': Platform.isIOS ? 'ios' : 'android',
        'platform': Platform.isIOS ? 'ios' : 'android',
      };

      var response = await apiClient.post('/user/device-token', data: payload);
      if (!response.status) {
        response = await apiClient.post('/user/fcm-token', data: payload);
      }
      if (!response.status) {
        response = await apiClient.post('/user/push-token', data: payload);
      }
      if (!response.status) {
        response = await apiClient.post('/user/profile', data: payload);
      }
      if (!response.status) {
        response = await apiClient.post('/device-token', data: payload);
      }
      debugPrint('[FCM] Sync response: status=${response.status}, message=${response.message}');
    } catch (e) {
      developer.log('Device token sync error: $e');
      debugPrint('[FCM ERROR] Device token sync request failed: $e');
    }
  }
}

