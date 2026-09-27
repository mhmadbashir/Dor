import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../crowd_reports/presentation/widgets/live_status_card.dart';
import '../domain/water_outlook.dart';
import 'schedule_formatters.dart';
import 'schedule_providers.dart';

/// Household home: the neighborhood's next water day and weekly pattern.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final overview = ref.watch(scheduleOverviewProvider);
    final languageCode = Localizations.localeOf(context).languageCode;

    Future<void> refresh() => ref.refresh(myNeighborhoodScheduleProvider.future);

    return Scaffold(
      appBar: AppBar(
        title: overview.value == null
            ? Text(l10n.scheduleTitle)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(overview.value!.data.details.neighborhood.name.resolve(languageCode)),
                  Text(
                    overview.value!.data.details.area.name.resolve(languageCode),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
        actions: [
          IconButton(
            key: const Key('settingsButton'),
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: AsyncValueView(
        value: overview,
        onRetry: () => ref.invalidate(myNeighborhoodScheduleProvider),
        data: (data) => data == null
            ? const SizedBox.shrink()
            : RefreshIndicator(
                onRefresh: refresh,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    LiveStatusCard(
                      neighborhoodId: data.data.details.neighborhood.id,
                      homeBand: ref.watch(myProfileProvider).value?.elevationBand,
                    ),
                    const SizedBox(height: 16),
                    _OutlookCard(outlook: data.outlook),
                    const SizedBox(height: 24),
                    Text(l10n.scheduleWeekTitle, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _WeekCard(week: data.week),
                    const SizedBox(height: 16),
                    Text(
                      l10n.scheduleDisclaimer,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _OutlookCard extends StatelessWidget {
  const _OutlookCard({required this.outlook});

  final WaterOutlook outlook;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final fmt = ScheduleFormatters(Localizations.localeOf(context).toLanguageTag());

    final (icon, color, title, headline, detail) = switch (outlook) {
      WaterScheduledNow(:final window) => (
        Icons.water_drop,
        theme.colorScheme.primaryContainer,
        l10n.scheduleNowTitle,
        null,
        l10n.scheduleNowBody(fmt.dayAndTime(window.end)),
      ),
      WaterScheduledNext(:final window, :final daysUntil) => (
        Icons.schedule,
        theme.colorScheme.secondaryContainer,
        l10n.scheduleNextTitle,
        l10n.scheduleNextIn(daysUntil),
        l10n.scheduleNextAt(fmt.weekday(window.start), fmt.time(window.start)),
      ),
      WaterNotScheduled() => (
        Icons.water_drop_outlined,
        theme.colorScheme.surfaceContainerHighest,
        l10n.scheduleNone,
        null,
        null,
      ),
    };

    return Card(
      key: const Key('outlookCard'),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  if (headline != null) Text(headline, style: theme.textTheme.headlineSmall),
                  if (detail != null) Text(detail, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week});

  final List<WeekdayPlan> week;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final fmt = ScheduleFormatters(Localizations.localeOf(context).toLanguageTag());

    return Card(
      child: Column(
        children: [
          for (final day in week)
            ListTile(
              key: ValueKey('weekday-${day.weekday}'),
              selected: day.isToday,
              leading: Icon(day.schedules.isEmpty ? Icons.water_drop_outlined : Icons.water_drop),
              title: Text(fmt.weekdayName(day.weekday)),
              subtitle: day.schedules.isEmpty
                  ? Text(l10n.scheduleNoWater)
                  : Text(
                      day.schedules
                          .map(
                            (s) =>
                                l10n.scheduleWindow(fmt.timeOfDay(s.startMinutes), s.durationHours),
                          )
                          .join('\n'),
                    ),
              trailing: day.isToday ? Chip(label: Text(l10n.today)) : null,
              textColor: day.schedules.isEmpty ? theme.colorScheme.onSurfaceVariant : null,
            ),
        ],
      ),
    );
  }
}
