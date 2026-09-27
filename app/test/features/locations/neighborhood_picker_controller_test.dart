import 'dart:async';

import 'package:dor/features/auth/presentation/auth_providers.dart';
import 'package:dor/features/locations/domain/device_location.dart';
import 'package:dor/features/locations/presentation/locations_providers.dart';
import 'package:dor/features/locations/presentation/neighborhood_picker_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

void main() {
  late MockLocationsRepository locations;
  late MockProfileRepository profiles;
  late MockDeviceLocationService device;

  ProviderContainer makeContainer({String? currentNeighborhood}) {
    when(() => profiles.fetchProfile(userId))
        .thenAnswer((_) async => householdProfile(neighborhoodId: currentNeighborhood));
    final container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(signedInAuth()),
        profileRepositoryProvider.overrideWithValue(profiles),
        locationsRepositoryProvider.overrideWithValue(locations),
        deviceLocationServiceProvider.overrideWithValue(device),
      ],
      retry: (_, _) => null,
    );
    container.listen(neighborhoodPickerControllerProvider, (_, _) {});
    return container;
  }

  setUpAll(registerFallbacks);

  setUp(() {
    device = MockDeviceLocationService();
    locations = MockLocationsRepository();
    profiles = MockProfileRepository();
    when(() => locations.governorates()).thenAnswer((_) async => [amman]);
    when(() => locations.areas(amman.id)).thenAnswer((_) async => [tlaaAlAliArea, markaArea]);
    when(() => locations.areas(irbid.id)).thenAnswer((_) async => [markaArea]);
  });

  test('auto-selects the only governorate for new users', () async {
    final container = makeContainer();
    final state = await container.read(neighborhoodPickerControllerProvider.future);

    expect(state.governorateId, amman.id);
    expect(state.areaId, isNull, reason: 'Amman has two areas');
    expect(state.canSave, isFalse);
  });

  test('auto-selects a single area after choosing a governorate', () async {
    when(() => locations.governorates()).thenAnswer((_) async => [amman, irbid]);
    final container = makeContainer();
    final notifier = container.read(neighborhoodPickerControllerProvider.notifier);
    expect(
      (await container.read(neighborhoodPickerControllerProvider.future)).governorateId,
      isNull,
    );

    await notifier.selectGovernorate(irbid.id);

    expect(container.read(neighborhoodPickerControllerProvider).value!.areaId, markaArea.id);
  });

  test('starts from the current neighborhood when editing', () async {
    when(() => locations.neighborhoodDetails(khalda.id)).thenAnswer((_) async => khaldaDetails);
    final container = makeContainer(currentNeighborhood: khalda.id);

    final state = await container.read(neighborhoodPickerControllerProvider.future);

    expect(state.governorateId, amman.id);
    expect(state.areaId, tlaaAlAliArea.id);
    expect(state.neighborhoodId, khalda.id);
  });

  test('changing a parent level clears the levels below it', () async {
    final container = makeContainer();
    final notifier = container.read(neighborhoodPickerControllerProvider.notifier);
    await container.read(neighborhoodPickerControllerProvider.future);

    notifier
      ..selectArea(tlaaAlAliArea.id)
      ..selectNeighborhood(khalda.id);
    expect(container.read(neighborhoodPickerControllerProvider).value!.canSave, isTrue);

    notifier.selectArea(markaArea.id);
    final state = container.read(neighborhoodPickerControllerProvider).value!;
    expect(state.areaId, markaArea.id);
    expect(state.neighborhoodId, isNull);
  });

  test('save persists the neighborhood and refreshes the profile', () async {
    final container = makeContainer();
    final notifier = container.read(neighborhoodPickerControllerProvider.notifier);
    await container.read(neighborhoodPickerControllerProvider.future);
    notifier
      ..selectArea(tlaaAlAliArea.id)
      ..selectNeighborhood(khalda.id);

    when(() => profiles.updateNeighborhood(userId, khalda.id)).thenAnswer((_) async {});
    when(() => profiles.fetchProfile(userId))
        .thenAnswer((_) async => householdProfile(neighborhoodId: khalda.id));

    expect(await notifier.save(), isTrue);
    verify(() => profiles.updateNeighborhood(userId, khalda.id)).called(1);
    expect((await container.read(myProfileProvider.future))!.neighborhoodId, khalda.id);
  });

  test('save failure is exposed and the selection kept', () async {
    final container = makeContainer();
    final notifier = container.read(neighborhoodPickerControllerProvider.notifier);
    await container.read(neighborhoodPickerControllerProvider.future);
    notifier
      ..selectArea(tlaaAlAliArea.id)
      ..selectNeighborhood(khalda.id);
    when(() => profiles.updateNeighborhood(any(), any())).thenThrow(Exception('offline'));

    expect(await notifier.save(), isFalse);
    final state = container.read(neighborhoodPickerControllerProvider).value!;
    expect(state.saveError, isNotNull);
    expect(state.neighborhoodId, khalda.id);
    expect(state.isSaving, isFalse);
  });

  group('useCurrentLocation', () {
    Future<(ProviderContainer, NeighborhoodPickerController)> ready() async {
      final container = makeContainer();
      await container.read(neighborhoodPickerControllerProvider.future);
      return (container, container.read(neighborhoodPickerControllerProvider.notifier));
    }

    NeighborhoodPickerState stateOf(ProviderContainer c) =>
        c.read(neighborhoodPickerControllerProvider).value!;

    test('fills the whole cascade from the detected neighborhood', () async {
      when(() => device.currentPosition()).thenAnswer((_) async => inKhalda);
      when(() => locations.nearestNeighborhood(inKhalda)).thenAnswer((_) async => khaldaDetails);
      final (container, notifier) = await ready();

      final pending = notifier.useCurrentLocation();
      expect(stateOf(container).isLocating, isTrue);
      expect(stateOf(container).canSave, isFalse, reason: 'no saving while locating');
      await pending;

      final state = stateOf(container);
      expect(state.isLocating, isFalse);
      expect(state.governorateId, amman.id);
      expect(state.areaId, tlaaAlAliArea.id);
      expect(state.neighborhoodId, khalda.id);
      expect(state.detectedName, khalda.name);
      expect(state.canSave, isTrue);
    });

    test('a manual choice made while locating wins over a late result', () async {
      final position = Completer<GeoPoint>();
      when(() => device.currentPosition()).thenAnswer((_) => position.future);
      when(() => locations.nearestNeighborhood(any())).thenAnswer((_) async => khaldaDetails);
      final (container, notifier) = await ready();

      final pending = notifier.useCurrentLocation();
      notifier
        ..selectArea(tlaaAlAliArea.id)
        ..selectNeighborhood(tlaaAlAli.id);
      expect(stateOf(container).isLocating, isFalse);
      expect(stateOf(container).canSave, isTrue);

      position.complete(inKhalda); // e.g. the permission prompt answered late
      await pending;

      expect(stateOf(container).neighborhoodId, tlaaAlAli.id);
      expect(stateOf(container).detectedName, isNull);
      verifyNever(() => locations.nearestNeighborhood(any()));
    });

    test('a manual change clears the detected label', () async {
      when(() => device.currentPosition()).thenAnswer((_) async => inKhalda);
      when(() => locations.nearestNeighborhood(inKhalda)).thenAnswer((_) async => khaldaDetails);
      final (container, notifier) = await ready();
      await notifier.useCurrentLocation();

      notifier.selectNeighborhood(tlaaAlAli.id);

      expect(stateOf(container).detectedName, isNull);
      expect(stateOf(container).neighborhoodId, tlaaAlAli.id);
    });

    for (final (issue, problem) in [
      (LocationIssue.serviceDisabled, LocateProblem.serviceDisabled),
      (LocationIssue.permissionDenied, LocateProblem.permissionDenied),
      (LocationIssue.permissionDeniedForever, LocateProblem.permissionDeniedForever),
      (LocationIssue.unavailable, LocateProblem.unavailable),
    ]) {
      test('reports $issue and keeps the manual selection', () async {
        when(() => device.currentPosition()).thenThrow(LocationException(issue));
        final (container, notifier) = await ready();
        notifier.selectArea(markaArea.id);

        await notifier.useCurrentLocation();

        final state = stateOf(container);
        expect(state.locateProblem, problem);
        expect(state.isLocating, isFalse);
        expect(state.areaId, markaArea.id);
        verifyNever(() => locations.nearestNeighborhood(any()));
      });
    }

    test('reports when no served neighborhood is nearby', () async {
      when(() => device.currentPosition()).thenAnswer((_) async => const GeoPoint(29.53, 35.0));
      when(() => locations.nearestNeighborhood(any())).thenAnswer((_) async => null);
      final (container, notifier) = await ready();

      await notifier.useCurrentLocation();

      expect(stateOf(container).locateProblem, LocateProblem.outsideCoverage);
      expect(stateOf(container).neighborhoodId, isNull);
    });

    test('reports lookup failures', () async {
      when(() => device.currentPosition()).thenAnswer((_) async => inKhalda);
      when(() => locations.nearestNeighborhood(any())).thenThrow(Exception('offline'));
      final (container, notifier) = await ready();

      await notifier.useCurrentLocation();

      expect(stateOf(container).locateProblem, LocateProblem.lookupFailed);
    });

    test('open settings targets the right screen', () async {
      when(() => device.currentPosition())
          .thenThrow(const LocationException(LocationIssue.serviceDisabled));
      when(() => device.openSettingsFor(any())).thenAnswer((_) async {});
      final (_, notifier) = await ready();
      await notifier.useCurrentLocation();

      await notifier.openLocationSettings();

      verify(() => device.openSettingsFor(LocationIssue.serviceDisabled)).called(1);
    });
  });
}
