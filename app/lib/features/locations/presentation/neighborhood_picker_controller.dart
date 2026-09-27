import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../domain/device_location.dart';
import '../domain/elevation_band.dart';
import '../domain/localized_name.dart';
import 'locations_providers.dart';

/// Why "use my location" didn't produce a suggestion.
enum LocateProblem {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,

  /// We got a position, but no served neighborhood is near it.
  outsideCoverage,

  /// The lookup itself failed (e.g. network).
  lookupFailed;

  static LocateProblem fromIssue(LocationIssue issue) => switch (issue) {
    LocationIssue.serviceDisabled => serviceDisabled,
    LocationIssue.permissionDenied => permissionDenied,
    LocationIssue.permissionDeniedForever => permissionDeniedForever,
    LocationIssue.unavailable => unavailable,
  };

  /// The user can fix this from system settings.
  bool get isFixableInSettings => this == serviceDisabled || this == permissionDeniedForever;
}

class NeighborhoodPickerState {
  const NeighborhoodPickerState({
    this.governorateId,
    this.areaId,
    this.neighborhoodId,
    this.elevationBand,
    this.elevationSuggested = false,
    this.isSaving = false,
    this.saveError,
    this.isLocating = false,
    this.locateProblem,
    this.detectedName,
  });

  final String? governorateId;
  final String? areaId;
  final String? neighborhoodId;

  /// Where the home sits in the neighborhood; null = "not sure".
  final ElevationBand? elevationBand;

  /// [elevationBand] was suggested from GPS altitude (the user can change it).
  final bool elevationSuggested;

  final bool isSaving;
  final Object? saveError;

  /// A device-location lookup is in progress.
  final bool isLocating;
  final LocateProblem? locateProblem;

  /// Set when the current selection was suggested from the device location.
  final LocalizedName? detectedName;

  bool get canSave => neighborhoodId != null && !isSaving && !isLocating;

  /// Copies everything. Transient messages ([saveError], [locateProblem]) are
  /// cleared unless passed.
  NeighborhoodPickerState copyWith({
    bool? isSaving,
    Object? saveError,
    bool? isLocating,
    LocateProblem? locateProblem,
  }) => NeighborhoodPickerState(
    governorateId: governorateId,
    areaId: areaId,
    neighborhoodId: neighborhoodId,
    elevationBand: elevationBand,
    elevationSuggested: elevationSuggested,
    isSaving: isSaving ?? this.isSaving,
    saveError: saveError,
    isLocating: isLocating ?? this.isLocating,
    locateProblem: locateProblem,
    detectedName: detectedName,
  );

  /// A new place selection; keeps the home's elevation choice.
  NeighborhoodPickerState withPlace({
    String? governorateId,
    String? areaId,
    String? neighborhoodId,
    LocalizedName? detectedName,
  }) => NeighborhoodPickerState(
    governorateId: governorateId,
    areaId: areaId,
    neighborhoodId: neighborhoodId,
    detectedName: detectedName,
    elevationBand: elevationBand,
    elevationSuggested: elevationSuggested,
  );
}

/// Drives the "my home" form: governorate > area > neighborhood, plus the
/// home's elevation within the neighborhood.
///
/// Starts from the user's current home when editing, skips levels that have a
/// single option, and can pre-fill everything from the device location
/// ([useCurrentLocation]), including an elevation suggestion from GPS
/// altitude. The user always confirms by saving.
class NeighborhoodPickerController extends AsyncNotifier<NeighborhoodPickerState> {
  /// Incremented by every location request and manual change, so a slow
  /// location result never overwrites a choice the user made meanwhile
  /// (e.g. while a browser permission prompt is left unanswered).
  int _locateGeneration = 0;

  /// The user picked an elevation themselves; don't override it with GPS.
  bool _elevationChosen = false;

  @override
  Future<NeighborhoodPickerState> build() async {
    final repo = ref.read(locationsRepositoryProvider);
    // watch (not read): in Riverpod 3 an unlistened provider is paused.
    final current = await ref.watch(myProfileProvider.selectAsync((p) => p?.neighborhoodId));
    if (current != null) {
      final profile = ref.read(myProfileProvider).value;
      final details = await repo.neighborhoodDetails(current);
      _elevationChosen = profile?.elevationBand != null;
      return NeighborhoodPickerState(
        governorateId: details.governorate.id,
        areaId: details.area.id,
        neighborhoodId: current,
        elevationBand: profile?.elevationBand,
      );
    }
    final governorates = await repo.governorates();
    if (governorates.length != 1) return const NeighborhoodPickerState();
    return _withSingleArea(const NeighborhoodPickerState(), governorates.single.id);
  }

  Future<NeighborhoodPickerState> _withSingleArea(
    NeighborhoodPickerState base,
    String governorateId,
  ) async {
    final areas = await ref.read(locationsRepositoryProvider).areas(governorateId);
    return base.withPlace(
      governorateId: governorateId,
      areaId: areas.length == 1 ? areas.single.id : null,
    );
  }

  /// Suggests the neighborhood the device is in (and the home's elevation
  /// when altitude is available). Failures leave the current selection
  /// untouched and are reported through [NeighborhoodPickerState.locateProblem].
  Future<void> useCurrentLocation() async {
    final current = state.value;
    if (current == null || current.isLocating || current.isSaving) return;
    final generation = ++_locateGeneration;
    state = AsyncData(current.copyWith(isLocating: true));
    bool superseded() => !ref.mounted || generation != _locateGeneration;

    LocateProblem? problem;
    try {
      final fix = await ref.read(deviceLocationServiceProvider).currentPosition();
      if (superseded()) return;
      final details = await ref.read(locationsRepositoryProvider).nearestNeighborhood(fix.point);
      if (superseded()) return;
      if (details != null) {
        final suggestion = _elevationChosen
            ? null
            : suggestElevationBand(
                altitudeM: fix.altitudeM,
                altitudeAccuracyM: fix.altitudeAccuracyM,
                lowMaxM: details.neighborhood.elevationLowMaxM,
                highMinM: details.neighborhood.elevationHighMinM,
              );
        state = AsyncData(
          NeighborhoodPickerState(
            governorateId: details.governorate.id,
            areaId: details.area.id,
            neighborhoodId: details.neighborhood.id,
            detectedName: details.neighborhood.name,
            elevationBand: suggestion ?? current.elevationBand,
            elevationSuggested: suggestion != null || current.elevationSuggested,
          ),
        );
        return;
      }
      problem = LocateProblem.outsideCoverage;
    } on LocationException catch (e) {
      problem = LocateProblem.fromIssue(e.issue);
    } catch (_) {
      problem = LocateProblem.lookupFailed;
    }
    if (!superseded()) {
      state = AsyncData(current.copyWith(isLocating: false, locateProblem: problem));
    }
  }

  Future<void> openLocationSettings() async {
    final issue = switch (state.value?.locateProblem) {
      LocateProblem.serviceDisabled => LocationIssue.serviceDisabled,
      LocateProblem.permissionDeniedForever => LocationIssue.permissionDeniedForever,
      _ => null,
    };
    if (issue != null) await ref.read(deviceLocationServiceProvider).openSettingsFor(issue);
  }

  Future<void> selectGovernorate(String governorateId) async {
    final current = state.value;
    if (current == null || current.governorateId == governorateId) return;
    _locateGeneration++;
    state = AsyncData(current.withPlace(governorateId: governorateId));
    try {
      final next = await _withSingleArea(current, governorateId);
      // Ignore if the user picked something else meanwhile.
      final now = state.value;
      if (ref.mounted && now?.governorateId == governorateId && now?.areaId == null) {
        state = AsyncData(next);
      }
    } catch (_) {
      // Auto-selection is a convenience; the areas list shows its own error.
    }
  }

  void selectArea(String areaId) {
    final current = state.value;
    if (current == null || current.areaId == areaId) return;
    _locateGeneration++;
    state = AsyncData(current.withPlace(governorateId: current.governorateId, areaId: areaId));
  }

  void selectNeighborhood(String neighborhoodId) {
    final current = state.value;
    if (current == null || current.neighborhoodId == neighborhoodId) return;
    _locateGeneration++;
    state = AsyncData(
      current.withPlace(
        governorateId: current.governorateId,
        areaId: current.areaId,
        neighborhoodId: neighborhoodId,
      ),
    );
  }

  /// [band] null means "not sure".
  void selectElevation(ElevationBand? band) {
    final current = state.value;
    if (current == null) return;
    _elevationChosen = true;
    state = AsyncData(
      NeighborhoodPickerState(
        governorateId: current.governorateId,
        areaId: current.areaId,
        neighborhoodId: current.neighborhoodId,
        detectedName: current.detectedName,
        elevationBand: band,
        isLocating: current.isLocating,
      ),
    );
  }

  /// Saves the home to the profile. Returns true on success.
  Future<bool> save() async {
    final current = state.value;
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (current == null || !current.canSave || userId == null) return false;

    state = AsyncData(current.copyWith(isSaving: true));
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateHome(userId, current.neighborhoodId!, current.elevationBand);
      // Refresh the profile so routing, status and the schedule pick up the change.
      ref.invalidate(myProfileProvider);
      await ref.read(myProfileProvider.future);
      if (ref.mounted) state = AsyncData(current.copyWith(isSaving: false));
      return true;
    } catch (e) {
      if (ref.mounted) state = AsyncData(current.copyWith(isSaving: false, saveError: e));
      return false;
    }
  }
}

final neighborhoodPickerControllerProvider =
    AsyncNotifierProvider.autoDispose<NeighborhoodPickerController, NeighborhoodPickerState>(
      NeighborhoodPickerController.new,
    );
