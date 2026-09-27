import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/push_messaging.dart';

/// FCM for delivery, flutter_local_notifications to show messages that arrive
/// while the app is in the foreground (FCM only displays background ones).
///
/// Uses the native Firebase config files (android/app/google-services.json,
/// ios/Runner/GoogleService-Info.plist). Without them, [initialize] returns
/// false and push is disabled. Not supported on web.
class FirebasePushMessaging implements PushMessaging {
  static const channelId = 'water_alerts';

  final _local = FlutterLocalNotificationsPlugin();
  final _opened = StreamController<PushNotification>.broadcast();
  bool _ready = false;

  @override
  String get platform => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    _ => kIsWeb ? 'web' : 'android',
  };

  @override
  Future<bool> initialize(NotificationChannelText channel) async {
    if (_ready) return true;
    if (kIsWeb) return false;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Push disabled: Firebase is not configured ($e)');
      return false;
    }

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => _opened.add(const PushNotification()),
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            channelId,
            channel.name,
            description: channel.description,
            importance: Importance.high,
          ),
        );

    final messaging = FirebaseMessaging.instance;
    // iOS shows foreground notifications natively when asked to.
    await messaging.setForegroundNotificationPresentationOptions(alert: true, sound: true);
    FirebaseMessaging.onMessage.listen((message) => _showForeground(message, channel));
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _opened.add(_toNotification(m)));
    final initial = await messaging.getInitialMessage();
    if (initial != null) scheduleMicrotask(() => _opened.add(_toNotification(initial)));

    _ready = true;
    return true;
  }

  Future<void> _showForeground(RemoteMessage message, NotificationChannelText channel) async {
    final n = message.notification;
    if (n == null || defaultTargetPlatform != TargetPlatform.android) return;
    await _local.show(
      id: message.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static PushNotification _toNotification(RemoteMessage m) => PushNotification(
    title: m.notification?.title,
    body: m.notification?.body,
    data: m.data.map((k, v) => MapEntry(k, '$v')),
  );

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> token() async {
    if (!_ready) return null;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // FCM needs the APNs token first; it can take a moment after launch.
        for (var i = 0; i < 5 && await FirebaseMessaging.instance.getAPNSToken() == null; i++) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Could not get FCM token: $e');
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh =>
      _ready ? FirebaseMessaging.instance.onTokenRefresh : const Stream.empty();

  @override
  Stream<PushNotification> get onOpened => _opened.stream;

  @override
  Future<void> deleteToken() async {
    if (_ready) await FirebaseMessaging.instance.deleteToken();
  }
}
