/// A notification the app received or the user opened.
class PushNotification {
  const PushNotification({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;
  final Map<String, String> data;
}

/// Localized text for the Android notification channel.
class NotificationChannelText {
  const NotificationChannelText({required this.name, required this.description});

  final String name;
  final String description;
}

/// Device push messaging (FCM). Implementations must be safe to use when push
/// isn't configured: [initialize] then returns false and everything else no-ops.
abstract interface class PushMessaging {
  /// Returns whether push is available on this build/device.
  Future<bool> initialize(NotificationChannelText channel);

  /// Asks the OS for permission to show notifications. Returns whether granted.
  Future<bool> requestPermission();

  /// The device token, or null if unavailable.
  Future<String?> token();

  Stream<String> get onTokenRefresh;

  /// Notifications the user tapped (including the one that launched the app).
  Stream<PushNotification> get onOpened;

  /// Invalidates the device token (on sign-out).
  Future<void> deleteToken();

  /// 'android' | 'ios' | 'web'
  String get platform;
}

abstract interface class PushTokenRepository {
  Future<void> register(String token, String platform);

  Future<void> unregister(String token);
}
