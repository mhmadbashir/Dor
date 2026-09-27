import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import 'locations_providers.dart';

class NeighborhoodPickerState {
  const NeighborhoodPickerState({
    this.governorateId,
    this.areaId,
    this.neighborhoodId,
    this.isSaving = false,
    this.saveError,
  });

  final String? governorateId;
  final String? areaId;
  final String? neighborhoodId;
  final bool isSaving;
  final Object? saveError;

  bool get canSave => neighborhoodId != null && !isSaving;

  NeighborhoodPickerState copyWith({bool? isSaving, Object? saveError}) => NeighborhoodPickerState(
    governorateId: governorateId,
    areaId: areaId,
    neighborhoodId: neighborhoodId,
    isSaving: isSaving ?? this.isSaving,
    saveError: saveError,
  );
}

/// Drives the governorate > area > neighborhood cascade.
///
/// Starts from the user's current neighborhood when editing, and skips
/// levels that have a single option (e.g. only one governorate launched).
class NeighborhoodPickerController extends AsyncNotifier<NeighborhoodPickerState> {
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

  Future<void> selectGovernorate(String governorateId) async {
    if (state.value?.governorateId == governorateId) return;
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
    state = AsyncData(
      NeighborhoodPickerState(governorateId: current.governorateId, areaId: areaId),
    );
  }

  void selectNeighborhood(String neighborhoodId) {
    final current = state.value;
    if (current == null) return;
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
