import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/async_value_view.dart';
import '../domain/localized_name.dart';
import 'locations_providers.dart';
import 'neighborhood_picker_controller.dart';

/// Used both for onboarding (no back button, router moves on after save)
/// and for changing the neighborhood from settings (pops after save).
///
/// During onboarding the neighborhood is detected from the device location
/// straight away; the manual pickers remain as the fallback.
class NeighborhoodPickerScreen extends ConsumerStatefulWidget {
  const NeighborhoodPickerScreen({super.key, required this.isOnboarding});

  final bool isOnboarding;

  @override
  ConsumerState<NeighborhoodPickerScreen> createState() => _NeighborhoodPickerScreenState();
}

class _NeighborhoodPickerScreenState extends ConsumerState<NeighborhoodPickerScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.isOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoLocate());
    }
  }

  Future<void> _autoLocate() async {
    try {
      await ref.read(neighborhoodPickerControllerProvider.future);
    } catch (_) {
      return; // The screen shows the load error with a retry button.
    }
    if (mounted) await ref.read(neighborhoodPickerControllerProvider.notifier).useCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(neighborhoodPickerControllerProvider);
    final controller = ref.read(neighborhoodPickerControllerProvider.notifier);

    Future<void> onSave() async {
      final saved = await controller.save();
      if (saved && !widget.isOnboarding && context.mounted) context.pop();
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isOnboarding,
        title: Text(widget.isOnboarding ? l10n.appTitle : l10n.settingsNeighborhood),
      ),
      body: SafeArea(
        child: AsyncValueView(
          value: state,
          onRetry: () => ref.invalidate(neighborhoodPickerControllerProvider),
          data: (selection) {
            // Pickers stay usable while locating; a manual choice wins.
            final enabled = !selection.isSaving;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (widget.isOnboarding) ...[
                  Text(l10n.onboardingTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(l10n.onboardingSubtitle),
                  const SizedBox(height: 24),
                ],
                _LocationSection(selection: selection),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.locationOrChooseManually,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                _LevelDropdown(
                  fieldKey: const Key('governorateDropdown'),
                  label: l10n.governorateLabel,
                  options: ref
                      .watch(governoratesProvider)
                      .whenData((list) => [for (final g in list) (id: g.id, name: g.name)]),
                  selectedId: selection.governorateId,
                  enabled: enabled,
                  onChanged: controller.selectGovernorate,
                  onRetry: () => ref.invalidate(governoratesProvider),
                ),
                const SizedBox(height: 16),
                if (selection.governorateId case final governorateId?)
                  _LevelDropdown(
                    fieldKey: const Key('areaDropdown'),
                    label: l10n.areaLabel,
                    options: ref
                        .watch(areasProvider(governorateId))
                        .whenData((list) => [for (final a in list) (id: a.id, name: a.name)]),
                    selectedId: selection.areaId,
                    enabled: enabled,
                    onChanged: controller.selectArea,
                    onRetry: () => ref.invalidate(areasProvider(governorateId)),
                  ),
                const SizedBox(height: 16),
                if (selection.areaId case final areaId?)
                  _LevelDropdown(
                    fieldKey: const Key('neighborhoodDropdown'),
                    label: l10n.neighborhoodLabel,
                    options: ref
                        .watch(neighborhoodsProvider(areaId))
                        .whenData((list) => [for (final n in list) (id: n.id, name: n.name)]),
                    selectedId: selection.neighborhoodId,
                    enabled: enabled,
                    onChanged: controller.selectNeighborhood,
                    onRetry: () => ref.invalidate(neighborhoodsProvider(areaId)),
                  ),
                const SizedBox(height: 24),
                if (selection.saveError case final error?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      l10n.errorMessage(error),
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                FilledButton(
                  key: const Key('saveNeighborhoodButton'),
                  onPressed: selection.canSave ? onSave : null,
                  child: selection.isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.isOnboarding ? l10n.continueButton : l10n.save),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "Use my location" button, progress, detected result or problem message.
class _LocationSection extends ConsumerWidget {
  const _LocationSection({required this.selection});

  final NeighborhoodPickerState selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final controller = ref.read(neighborhoodPickerControllerProvider.notifier);
    final languageCode = Localizations.localeOf(context).languageCode;

    final useLocationButton = OutlinedButton.icon(
      key: const Key('useLocationButton'),
      onPressed: selection.isSaving ? null : controller.useCurrentLocation,
      icon: const Icon(Icons.my_location),
      label: Text(l10n.locationUseCurrent),
    );

    if (selection.isLocating) {
      return _InfoCard(
        key: const Key('locatingCard'),
        color: theme.colorScheme.surfaceContainerHighest,
        leading: const SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        message: l10n.locationLocating,
      );
    }

    if (selection.detectedName case final name?) {
      return _InfoCard(
        key: const Key('detectedCard'),
        color: theme.colorScheme.primaryContainer,
        leading: const Icon(Icons.location_on),
        message: l10n.locationDetected(name.resolve(languageCode)),
      );
    }

    if (selection.locateProblem case final problem?) {
      final canOpenSettings =
          problem.isFixableInSettings && ref.read(deviceLocationServiceProvider).canOpenSettings;
      return _InfoCard(
        key: const Key('locateProblemCard'),
        color: theme.colorScheme.surfaceContainerHighest,
        leading: const Icon(Icons.location_off_outlined),
        message: switch (problem) {
          LocateProblem.serviceDisabled => l10n.locationServiceDisabled,
          LocateProblem.permissionDenied => l10n.locationPermissionDenied,
          LocateProblem.permissionDeniedForever => l10n.locationPermissionDeniedForever,
          LocateProblem.unavailable => l10n.locationUnavailable,
          LocateProblem.outsideCoverage => l10n.locationOutsideCoverage,
          LocateProblem.lookupFailed => l10n.errorUnknown,
        },
        actions: [
          if (canOpenSettings)
            TextButton(
              onPressed: controller.openLocationSettings,
              child: Text(l10n.locationOpenSettings),
            ),
          TextButton(
            key: const Key('retryLocationButton'),
            onPressed: controller.useCurrentLocation,
            child: Text(l10n.retry),
          ),
        ],
      );
    }

    return useLocationButton;
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    super.key,
    required this.color,
    required this.leading,
    required this.message,
    this.actions = const [],
  });

  final Color color;
  final Widget leading;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            if (actions.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(spacing: 8, children: actions),
              ),
          ],
        ),
      ),
    );
  }
}

typedef _Option = ({String id, LocalizedName name});

class _LevelDropdown extends StatelessWidget {
  const _LevelDropdown({
    required this.fieldKey,
    required this.label,
    required this.options,
    required this.selectedId,
    required this.enabled,
    required this.onChanged,
    required this.onRetry,
  });

  final Key fieldKey;
  final String label;
  final AsyncValue<List<_Option>> options;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;

    return KeyedSubtree(key: fieldKey, child: _field(context, l10n, languageCode));
  }

  Widget _field(BuildContext context, AppLocalizations l10n, String languageCode) {
    return options.when(
      loading: () => InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: const LinearProgressIndicator(),
      ),
      error: (error, _) => InputDecorator(
        decoration: InputDecoration(labelText: label, errorText: l10n.errorMessage(error)),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ),
      ),
      data: (items) {
        final hasSelection = items.any((o) => o.id == selectedId);
        return DropdownButtonFormField<String>(
          // Re-create when the selection changes from outside (auto-select, location).
          key: ValueKey((fieldKey, hasSelection ? selectedId : null)),
          initialValue: hasSelection ? selectedId : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            helperText: items.isEmpty ? l10n.noOptions : null,
          ),
          items: [
            for (final o in items)
              DropdownMenuItem(value: o.id, child: Text(o.name.resolve(languageCode))),
          ],
          onChanged: items.isEmpty || !enabled ? null : (id) => id == null ? null : onChanged(id),
        );
      },
    );
  }
}
