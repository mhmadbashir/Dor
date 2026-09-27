import 'package:dor/core/services/supabase_providers.dart';
import 'package:dor/features/auth/presentation/auth_providers.dart';
import 'package:dor/features/crowd_reports/domain/live_status.dart';
import 'package:dor/features/crowd_reports/presentation/crowd_reports_providers.dart';
import 'package:dor/features/locations/domain/elevation_band.dart';
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
  late FakeCrowdReportsRepository crowd;

  setUp(() => crowd = FakeCrowdReportsRepository());

  List<Override> overrides(DateTime utcNow, {ElevationBand? band}) {
    crowd.now = () => utcNow;
    final profiles = MockProfileRepository();
    final locations = MockLocationsRepository();
    final schedules = MockScheduleRepository();
    when(() => profiles.fetchProfile(userId))
        .thenAnswer((_) async => householdProfile(neighborhoodId: khalda.id, band: band));
    when(() => locations.neighborhoodDetails(khalda.id)).thenAnswer((_) async => khaldaDetails);
    when(() => schedules.forNeighborhood(khalda.id)).thenAnswer((_) async => [khaldaSchedule]);
    return [
      authRepositoryProvider.overrideWithValue(signedInAuth()),
      profileRepositoryProvider.overrideWithValue(profiles),
      locationsRepositoryProvider.overrideWithValue(locations),
      scheduleRepositoryProvider.overrideWithValue(schedules),
      clockProvider.overrideWithValue(() => utcNow),
      crowdReportsRepositoryProvider.overrideWithValue(crowd),
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
    // Western digits in Arabic too.
    expect(find.textContaining(RegExp(r'^الضخ المجدول حتى الخميس 8:00\sص$')), findsOneWidget);
  });

  testWidgets('hilltop home: water reached lower homes, then report', (tester) async {
    final now = DateTime.utc(2026, 9, 29, 7); // Tuesday 10:00 Amman
    await tester.pumpScreen(
      const ScheduleScreen(),
      locale: 'en',
      overrides: overrides(now, band: ElevationBand.high),
    );
    crowd.emit([
      flowing(ElevationBand.low, DateTime.utc(2026, 9, 29, 5), 9), // since 8:00
      const BandStatus(band: ElevationBand.middle, arrivedCount: 2),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Water reached lower homes'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^Flowing lower down since 8:00\sAM')), findsOneWidget);
    expect(find.textContaining('On a hill  · Your home'), findsOneWidget);
    // Unconfirmed levels show how many reports they have.
    expect(find.text('2 reports'), findsOneWidget);
    expect(find.text('No reports'), findsOneWidget);

    await tester.tap(find.byKey(const Key('report-arrived')));
    await tester.pumpAndSettle();

    expect(crowd.submitted, hasLength(1));
    expect(find.text('Thanks for letting your neighbors know!'), findsOneWidget);
    expect(find.textContaining(RegExp(r'report again at 4:00\sPM')), findsOneWidget);
    final button = tester.widget<ButtonStyleButton>(find.byKey(const Key('report-noWater')));
    expect(button.onPressed, isNull, reason: 'one report per 6 hours');
  });

  testWidgets('Arabic: flowing at my level shows confirmations', (tester) async {
    final now = DateTime.utc(2026, 9, 29, 7);
    await tester.pumpScreen(
      const ScheduleScreen(),
      overrides: overrides(now, band: ElevationBand.low),
    );
    crowd.emit([flowing(ElevationBand.low, DateTime.utc(2026, 9, 29, 3), 83)]);
    await tester.pumpAndSettle();

    expect(find.text('المياه واصلة'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^منذ 6:00\sص · 83 تأكيدًا$')), findsOneWidget);
  });
}
