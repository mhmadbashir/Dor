import 'package:dor/core/services/supabase_providers.dart';
import 'package:dor/features/auth/presentation/auth_providers.dart';
import 'package:dor/features/locations/presentation/locations_providers.dart';
import 'package:dor/features/schedule/presentation/schedule_providers.dart';
import 'package:dor/features/schedule/presentation/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

void main() {
  List<Override> overrides(DateTime utcNow) {
    final profiles = MockProfileRepository();
    final locations = MockLocationsRepository();
    final schedules = MockScheduleRepository();
    when(() => profiles.fetchProfile(userId))
        .thenAnswer((_) async => householdProfile(neighborhoodId: khalda.id));
    when(() => locations.neighborhoodDetails(khalda.id)).thenAnswer((_) async => khaldaDetails);
    when(() => schedules.forNeighborhood(khalda.id)).thenAnswer((_) async => [khaldaSchedule]);
    return [
      authRepositoryProvider.overrideWithValue(signedInAuth()),
      profileRepositoryProvider.overrideWithValue(profiles),
      locationsRepositoryProvider.overrideWithValue(locations),
      scheduleRepositoryProvider.overrideWithValue(schedules),
      clockProvider.overrideWithValue(() => utcNow),
    ];
  }

  testWidgets('shows the next water day in English', (tester) async {
    // Sunday 2026-09-27 12:00 Amman = 09:00 UTC; Khalda gets water Tuesday 8 AM.
    await tester.pumpScreen(
      const ScheduleScreen(),
      locale: 'en',
      overrides: overrides(DateTime.utc(2026, 9, 27, 9)),
    );

    expect(find.text('Khalda'), findsOneWidget);
    expect(find.text('Next water day'), findsOneWidget);
    expect(find.text('In 2 days'), findsOneWidget);
    // intl separates "AM" with a narrow no-break space.
    expect(find.textContaining(RegExp(r'^Tuesday, 8:00\sAM$')), findsOneWidget);
    // Week list starts on Saturday; today (Sunday) is highlighted.
    expect(find.byKey(const ValueKey('weekday-6')), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^8:00\sAM · 48 hours$')), findsOneWidget);
  });

  testWidgets('shows the current window in Arabic during the water day', (tester) async {
    // Wednesday 2026-09-30 10:00 Amman, inside Tuesday 08:00 + 48h.
    await tester.pumpScreen(
      const ScheduleScreen(),
      overrides: overrides(DateTime.utc(2026, 9, 30, 7)),
    );

    expect(find.text('خلدا'), findsOneWidget);
    expect(find.text('اليوم دورك في المياه'), findsOneWidget);
    expect(find.textContaining('الضخ المجدول حتى الخميس'), findsOneWidget);
  });
}
