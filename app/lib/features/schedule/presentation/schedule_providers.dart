import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_providers.dart';
import '../../../core/time/amman_time.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../locations/domain/location_entities.dart';
import '../../locations/presentation/locations_providers.dart';
import '../data/supabase_schedule_repository.dart';
import '../domain/schedule_repository.dart';
import '../domain/water_outlook.dart';
import '../domain/water_schedule.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => SupabaseScheduleRepository(ref.watch(supabaseClientProvider)),
);

/// Amman wall-clock time, re-emitted every minute so countdowns stay fresh.
final ammanNowProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield AmmanTime.wallClock(clock());
  yield* Stream.periodic(const Duration(minutes: 1), (_) => AmmanTime.wallClock(clock()));
});

class MyNeighborhoodSchedule {
  const MyNeighborhoodSchedule({required this.details, required this.schedules});

  final NeighborhoodDetails details;
  final List<WaterSchedule> schedules;
}

/// The signed-in user's neighborhood and its schedule entries.
final myNeighborhoodScheduleProvider = FutureProvider.autoDispose<MyNeighborhoodSchedule?>((
  ref,
) async {
  final profile = await ref.watch(myProfileProvider.future);
  final neighborhoodId = profile?.neighborhoodId;
  if (neighborhoodId == null) return null;
  final (details, schedules) = await (
    ref.watch(neighborhoodDetailsProvider(neighborhoodId).future),
    ref.watch(scheduleRepositoryProvider).forNeighborhood(neighborhoodId),
  ).wait;
  return MyNeighborhoodSchedule(details: details, schedules: schedules);
});

class ScheduleOverview {
  const ScheduleOverview({required this.data, required this.outlook, required this.week});

  final MyNeighborhoodSchedule data;
  final WaterOutlook outlook;
  final List<WeekdayPlan> week;
}

final scheduleOverviewProvider = Provider.autoDispose<AsyncValue<ScheduleOverview?>>((ref) {
  final data = ref.watch(myNeighborhoodScheduleProvider);
  final now = ref.watch(ammanNowProvider).value ?? AmmanTime.wallClock(ref.watch(clockProvider)());
  return data.whenData((d) {
    if (d == null) return null;
    return ScheduleOverview(
      data: d,
      outlook: WaterScheduleCalculator.outlook(d.schedules, now),
      week: WaterScheduleCalculator.weeklyPattern(d.schedules, now),
    );
  });
});
