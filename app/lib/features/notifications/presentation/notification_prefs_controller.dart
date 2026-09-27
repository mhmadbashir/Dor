import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';

/// Saves the user's notification preferences to their profile.
class NotificationPrefsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> setWaterArrival(bool enabled) => _save(waterArrival: enabled);

  Future<void> setScheduleReminder(bool enabled) => _save(scheduleReminder: enabled);

  Future<void> setScheduleStart(bool enabled) => _save(scheduleStart: enabled);

  Future<void> _save({bool? waterArrival, bool? scheduleReminder, bool? scheduleStart}) async {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(profileRepositoryProvider)
          .updateNotificationPrefs(
            userId,
            waterArrival: waterArrival,
            scheduleReminder: scheduleReminder,
            scheduleStart: scheduleStart,
          );
      ref.invalidate(myProfileProvider);
      await ref.read(myProfileProvider.future);
    });
  }
}

final notificationPrefsControllerProvider =
    NotifierProvider.autoDispose<NotificationPrefsController, AsyncValue<void>>(
      NotificationPrefsController.new,
    );
