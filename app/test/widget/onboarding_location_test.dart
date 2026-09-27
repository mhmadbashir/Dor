import 'package:dor/features/auth/presentation/auth_providers.dart';
import 'package:dor/features/locations/domain/device_location.dart';
import 'package:dor/features/locations/presentation/locations_providers.dart';
import 'package:dor/features/locations/presentation/neighborhood_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

void main() {
  setUpAll(registerFallbacks);

  late MockDeviceLocationService device;
  late MockLocationsRepository locations;

  List<Override> overrides() {
    final profiles = MockProfileRepository();
    when(() => profiles.fetchProfile(userId)).thenAnswer((_) async => householdProfile());
    when(() => locations.governorates()).thenAnswer((_) async => [amman]);
    when(() => locations.areas(amman.id)).thenAnswer((_) async => [tlaaAlAliArea, markaArea]);
    when(() => locations.neighborhoods(tlaaAlAliArea.id))
        .thenAnswer((_) async => [khalda, tlaaAlAli]);
    return [
      authRepositoryProvider.overrideWithValue(signedInAuth()),
      profileRepositoryProvider.overrideWithValue(profiles),
      locationsRepositoryProvider.overrideWithValue(locations),
      deviceLocationServiceProvider.overrideWithValue(device),
    ];
  }

  setUp(() {
    device = MockDeviceLocationService();
    locations = MockLocationsRepository();
    when(() => device.canOpenSettings).thenReturn(true);
  });

  testWidgets('onboarding detects the neighborhood automatically', (tester) async {
    when(() => device.currentPosition()).thenAnswer((_) async => khaldaFix);
    when(() => locations.nearestNeighborhood(inKhalda)).thenAnswer((_) async => khaldaDetails);

    await tester.pumpScreen(
      const NeighborhoodPickerScreen(isOnboarding: true),
      locale: 'en',
      overrides: overrides(),
    );

    expect(find.byKey(const Key('detectedCard')), findsOneWidget);
    expect(find.textContaining('We found Khalda'), findsOneWidget);
    // The cascade is filled and the user can confirm.
    expect(find.text('Khalda'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('saveNeighborhoodButton')), 200);
    final save = tester.widget<FilledButton>(find.byKey(const Key('saveNeighborhoodButton')));
    expect(save.onPressed, isNotNull);
  });

  testWidgets('blocked permission offers settings and manual choice (Arabic)', (tester) async {
    when(() => device.currentPosition())
        .thenThrow(const LocationException(LocationIssue.permissionDeniedForever));

    await tester.pumpScreen(
      const NeighborhoodPickerScreen(isOnboarding: true),
      overrides: overrides(),
    );

    expect(find.byKey(const Key('locateProblemCard')), findsOneWidget);
    expect(find.text('فتح الإعدادات'), findsOneWidget);
    expect(find.text('أو اختر يدويًا'), findsOneWidget);
    expect(find.byKey(const Key('areaDropdown')), findsOneWidget);
  });

  testWidgets('changing neighborhood from settings does not auto-locate', (tester) async {
    await tester.pumpScreen(
      const NeighborhoodPickerScreen(isOnboarding: false),
      locale: 'en',
      overrides: overrides(),
    );

    verifyNever(() => device.currentPosition());
    expect(find.byKey(const Key('useLocationButton')), findsOneWidget);
  });
}
