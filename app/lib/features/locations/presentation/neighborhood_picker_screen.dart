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
class NeighborhoodPickerScreen extends ConsumerWidget {
  const NeighborhoodPickerScreen({super.key, required this.isOnboarding});

  final bool isOnboarding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(neighborhoodPickerControllerProvider);
    final controller = ref.read(neighborhoodPickerControllerProvider.notifier);

    Future<void> onSave() async {
      final saved = await controller.save();
      if (saved && !isOnboarding && context.mounted) context.pop();
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isOnboarding,
        title: Text(isOnboarding ? l10n.appTitle : l10n.settingsNeighborhood),
      ),
      body: SafeArea(
        child: AsyncValueView(
          value: state,
          onRetry: () => ref.invalidate(neighborhoodPickerControllerProvider),
          data: (selection) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (isOnboarding) ...[
                Text(l10n.onboardingTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(l10n.onboardingSubtitle),
                const SizedBox(height: 24),
              ],
              _LevelDropdown(
                fieldKey: const Key('governorateDropdown'),
                label: l10n.governorateLabel,
                options: ref
                    .watch(governoratesProvider)
                    .whenData((list) => [for (final g in list) (id: g.id, name: g.name)]),
                selectedId: selection.governorateId,
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
                    : Text(isOnboarding ? l10n.continueButton : l10n.save),
              ),
            ],
          ),
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
    required this.onChanged,
    required this.onRetry,
  });

  final Key fieldKey;
  final String label;
  final AsyncValue<List<_Option>> options;
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;

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
          // Re-create when the selection changes from outside (auto-select).
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
          onChanged: items.isEmpty ? null : (id) => id == null ? null : onChanged(id),
        );
      },
    );
  }
}
