import 'package:dor/features/auth/presentation/auth_providers.dart';
import 'package:dor/features/notifications/presentation/notification_prefs_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

void main() {
  late MockProfileRepository profiles;
  late ProviderContainer container;

  setUp(() {
    profiles = MockProfileRepository();
    when(() => profiles.fetchProfile(userId)).thenAnswer((_) async => householdProfile());
    when(
      () => profiles.updateNotificationPrefs(
        any(),
        waterArrival: any(named: 'waterArrival'),
        scheduleReminder: any(named: 'scheduleReminder'),
        scheduleStart: any(named: 'scheduleStart'),
      ),
    ).thenAnswer((_) async {});
    container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(signedInAuth()),
        profileRepositoryProvider.overrideWithValue(profiles),
      ],
      retry: (_, _) => null,
    );
    container
      ..listen(notificationPrefsControllerProvider, (_, _) {})
      ..listen(myProfileProvider, (_, _) {});
  });

  test('turning off the water-day start reminder changes only that preference', () async {
    await container.read(notificationPrefsControllerProvider.notifier).setScheduleStart(false);

    verify(() => profiles.updateNotificationPrefs(userId, scheduleStart: false)).called(1);
    expect(container.read(notificationPrefsControllerProvider).hasError, isFalse);
  });

  test('each switch saves its own preference', () async {
    final notifier = container.read(notificationPrefsControllerProvider.notifier);
    await notifier.setWaterArrival(false);
    await notifier.setScheduleReminder(true);

    verify(() => profiles.updateNotificationPrefs(userId, waterArrival: false)).called(1);
    verify(() => profiles.updateNotificationPrefs(userId, scheduleReminder: true)).called(1);
  });
}
