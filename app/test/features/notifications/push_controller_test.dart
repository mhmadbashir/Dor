import 'dart:async';

import 'package:dor/features/auth/presentation/auth_providers.dart';
import 'package:dor/features/notifications/domain/push_messaging.dart';
import 'package:dor/features/notifications/presentation/push_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class FakePush implements PushMessaging {
  bool available = true;
  bool granted = true;
  String? currentToken = 'fcm-token-1';
  final refresh = StreamController<String>.broadcast();
  final opened = StreamController<PushNotification>.broadcast();
  bool deleted = false;
  NotificationChannelText? channel;

  @override
  Future<bool> initialize(NotificationChannelText channel) async {
    this.channel = channel;
    return available;
  }

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<String?> token() async => currentToken;

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Stream<PushNotification> get onOpened => opened.stream;

  @override
  Future<void> deleteToken() async => deleted = true;

  @override
  String get platform => 'android';
}

class MockPushTokenRepository extends Mock implements PushTokenRepository {}

void main() {
  late FakePush push;
  late MockPushTokenRepository tokens;
  late MockAuthRepository auth;

  ProviderContainer start() {
    final c = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        pushMessagingProvider.overrideWithValue(push),
        pushTokenRepositoryProvider.overrideWithValue(tokens),
      ],
      retry: (_, _) => null,
    );
    c.listen(pushControllerProvider, (_, _) {});
    return c;
  }

  Future<void> settle() =>
      Future<void>.delayed(Duration.zero).then((_) => Future<void>.delayed(Duration.zero));

  setUp(() {
    push = FakePush();
    tokens = MockPushTokenRepository();
    auth = signedInAuth();
    when(() => tokens.register(any(), any())).thenAnswer((_) async {});
    when(() => tokens.unregister(any())).thenAnswer((_) async {});
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  test('registers the device token for the signed-in user, with a localized channel', () async {
    final c = start();
    await settle();

    verify(() => tokens.register('fcm-token-1', 'android')).called(1);
    expect(c.read(pushControllerProvider), PushStatus.enabled);
    expect(push.channel!.name, 'تنبيهات المياه');
  });

  test('re-registers when FCM rotates the token', () async {
    start();
    await settle();
    push.refresh.add('fcm-token-2');
    await settle();

    verify(() => tokens.register('fcm-token-2', 'android')).called(1);
  });

  test('does nothing when Firebase is not configured', () async {
    push.available = false;
    final c = start();
    await settle();

    verifyNever(() => tokens.register(any(), any()));
    expect(c.read(pushControllerProvider), PushStatus.unavailable);
  });

  test('respects a refused notification permission', () async {
    push.granted = false;
    final c = start();
    await settle();

    verifyNever(() => tokens.register(any(), any()));
    expect(c.read(pushControllerProvider), PushStatus.denied);
  });

  test('does nothing while signed out', () async {
    auth = signedInAuth(null);
    start();
    await settle();

    verifyNever(() => tokens.register(any(), any()));
  });

  test('sign-out detaches the device before ending the session', () async {
    final c = start();
    await settle();

    await c.read(pushControllerProvider.notifier).signOut();

    verifyInOrder([() => tokens.unregister('fcm-token-1'), () => auth.signOut()]);
    expect(push.deleted, isTrue);
  });
}
