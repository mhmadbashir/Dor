import 'package:dor/features/auth/presentation/auth_providers.dart';
import 'package:dor/features/locations/presentation/locations_providers.dart';
import 'package:dor/features/locations/presentation/neighborhood_picker_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

void main() {
  late MockLocationsRepository locations;
  late MockProfileRepository profiles;

  ProviderContainer makeContainer({String? currentNeighborhood}) {
    when(() => profiles.fetchProfile(userId))
        .thenAnswer((_) async => householdProfile(neighborhoodId: currentNeighborhood));
    final container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(signedInAuth()),
        profileRepositoryProvider.overrideWithValue(profiles),
        locationsRepositoryProvider.overrideWithValue(locations),
      ],
      retry: (_, _) => null,
    );
    container.listen(neighborhoodPickerControllerProvider, (_, _) {});
    return container;
  }

  setUp(() {
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
    expect((await container.read(neighborhoodPickerControllerProvider.future)).governorateId, isNull);

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
}
