import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../domain/device_location.dart';
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
    this.isSaving = false,
    this.saveError,
    this.isLocating = false,
    this.locateProblem,
    this.detectedName,
  });

  final String? governorateId;
  final String? areaId;
  final String? neighborhoodId;
  final bool isSaving;
  final Object? saveError;

  /// A device-location lookup is in progress.
  final bool isLocating;
  final LocateProblem? locateProblem;

  /// Set when the current selection was suggested from the device location.
  final LocalizedName? detectedName;

  bool get canSave => neighborhoodId != null && !isSaving && !isLocating;

  /// Copies the selection. Transient messages ([saveError], [locateProblem])
  /// are cleared unless passed.
  NeighborhoodPickerState copyWith({
    bool? isSaving,
    Object? saveError,
    bool? isLocating,
    LocateProblem? locateProblem,
  }) => NeighborhoodPickerState(
    governorateId: governorateId,
    areaId: areaId,
    neighborhoodId: neighborhoodId,
    isSaving: isSaving ?? this.isSaving,
    saveError: saveError,
    isLocating: isLocating ?? this.isLocating,
    locateProblem: locateProblem,
    detectedName: detectedName,
  );
}

/// Drives the governorate > area > neighborhood cascade.
///
/// Starts from the user's current neighborhood when editing, skips levels
/// that have a single option, and can pre-fill everything from the device
/// location ([useCurrentLocation]); the user always confirms by saving.
class NeighborhoodPickerController extends AsyncNotifier<NeighborhoodPickerState> {
  /// Incremented by every location request and manual change, so a slow
  /// location result never overwrites a choice the user made meanwhile
  /// (e.g. while a browser permission prompt is left unanswered).
  int _locateGeneration = 0;

  @override
  Future<NeighborhoodPickerState> build() async {
    final repo = ref.read(locationsRepositoryProvider);
    // watch (not read): in Riverpod 3 an unlistened provider is paused.
    final current = await ref.watch(myProfileProvider.selectAsync((p) => p?.neighborhoodId));
    if (current != null) {
      final details = await repo.neighborhoodDetails(current);
      return NeighborhoodPickerState(
        governorateId: details.governorate.id,
        areaId: details.area.id,
        neighborhoodId: current,
      );
    }
    final governorates = await repo.governorates();
    if (governorates.length != 1) return const NeighborhoodPickerState();
    return _withSingleArea(governorates.single.id);
  }

  Future<NeighborhoodPickerState> _withSingleArea(String governorateId) async {
    final areas = await ref.read(locationsRepositoryProvider).areas(governorateId);
    return NeighborhoodPickerState(
      governorateId: governorateId,
      areaId: areas.length == 1 ? areas.single.id : null,
    );
  }

  /// Suggests the neighborhood the device is in. Failures leave the current
  /// selection untouched and are reported through [NeighborhoodPickerState.locateProblem].
  Future<void> useCurrentLocation() async {
    final current = state.value;
    if (current == null || current.isLocating || current.isSaving) return;
    final generation = ++_locateGeneration;
    state = AsyncData(current.copyWith(isLocating: true));
    bool superseded() => !ref.mounted || generation != _locateGeneration;

    LocateProblem? problem;
    try {
      final point = await ref.read(deviceLocationServiceProvider).currentPosition();
      if (superseded()) return;
      final details = await ref.read(locationsRepositoryProvider).nearestNeighborhood(point);
      if (superseded()) return;
      if (details != null) {
        state = AsyncData(
          NeighborhoodPickerState(
            governorateId: details.governorate.id,
            areaId: details.area.id,
            neighborhoodId: details.neighborhood.id,
            detectedName: details.neighborhood.name,
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
    final problem = state.value?.locateProblem;
    final issue = switch (problem) {
      LocateProblem.serviceDisabled => LocationIssue.serviceDisabled,
      LocateProblem.permissionDeniedForever => LocationIssue.permissionDeniedForever,
      _ => null,
    };
    if (issue != null) await ref.read(deviceLocationServiceProvider).openSettingsFor(issue);
  }

  Future<void> selectGovernorate(String governorateId) async {
    if (state.value?.governorateId == governorateId) return;
    _locateGeneration++;
    state = AsyncData(NeighborhoodPickerState(governorateId: governorateId));
    try {
      final next = await _withSingleArea(governorateId);
      // Ignore if the user picked something else meanwhile.
      if (ref.mounted &&
          state.value?.governorateId == governorateId &&
          state.value?.areaId == null) {
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
    state = AsyncData(
      NeighborhoodPickerState(governorateId: current.governorateId, areaId: areaId),
    );
  }

  void selectNeighborhood(String neighborhoodId) {
    final current = state.value;
    if (current == null || current.neighborhoodId == neighborhoodId) return;
    _locateGeneration++;
    state = AsyncData(
      NeighborhoodPickerState(
        governorateId: current.governorateId,
        areaId: current.areaId,
        neighborhoodId: neighborhoodId,
      ),
    );
  }

  /// Saves the selection to the profile. Returns true on success.
  Future<bool> save() async {
    final current = state.value;
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (current == null || !current.canSave || userId == null) return false;

    state = AsyncData(current.copyWith(isSaving: true));
    try {
      await ref.read(profileRepositoryProvider).updateNeighborhood(userId, current.neighborhoodId!);
      // Refresh the profile so routing and the schedule pick up the change.
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
