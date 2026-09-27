import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/supabase_providers.dart';
import '../../../locations/domain/elevation_band.dart';
import '../../../schedule/presentation/schedule_formatters.dart';
import '../../../schedule/presentation/schedule_providers.dart';
import '../../domain/crowd_report.dart';
import '../../domain/live_status.dart';
import '../crowd_reports_providers.dart';
import '../elevation_labels.dart';

/// "Water right now": neighbors' confirmations for the user's level, the
/// status at each elevation, and one-tap report buttons.
class LiveStatusCard extends ConsumerWidget {
  const LiveStatusCard({super.key, required this.neighborhoodId, required this.homeBand});

  final String neighborhoodId;
  final ElevationBand? homeBand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final status = ref.watch(liveStatusProvider(neighborhoodId));

    return Card(
      key: const Key('liveStatusCard'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.liveTitle, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            status.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) =>
                  Text(l10n.errorMessage(e), style: TextStyle(color: theme.colorScheme.error)),
              data: (live) => _StatusBody(live: live, homeBand: homeBand),
            ),
            const Divider(height: 24),
            _ReportPanel(neighborhoodId: neighborhoodId),
          ],
        ),
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({required this.live, required this.homeBand});

  final NeighborhoodLiveStatus live;
  final ElevationBand? homeBand;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final fmt = ScheduleFormatters(Localizations.localeOf(context).toLanguageTag());

    final (icon, color, title, detail) = switch (live.headlineFor(homeBand)) {
      FlowingHere(:final since, :final confirmations) => (
        Icons.water_drop,
        theme.colorScheme.primary,
        l10n.liveFlowing,
        l10n.liveFlowingDetail(fmt.instantTime(since), confirmations),
      ),
      FlowingBelow(:final since) => (
        Icons.water_drop_outlined,
        theme.colorScheme.tertiary,
        l10n.liveFlowingBelow,
        l10n.liveFlowingBelowDetail(fmt.instantTime(since)),
      ),
      NoWaterHere(:final reports) => (
        Icons.format_color_reset_outlined,
        theme.colorScheme.error,
        l10n.liveNoWater,
        l10n.liveNoWaterDetail(reports),
      ),
      NoConfirmations() => (
        Icons.help_outline,
        theme.colorScheme.onSurfaceVariant,
        l10n.liveUnknown,
        l10n.liveUnknownDetail,
      ),
    };

    final myBand = ElevationBand.effective(homeBand);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, key: const Key('liveHeadline'), style: theme.textTheme.titleLarge),
                  Text(detail, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Hilltop first, like the neighborhood itself.
        for (final band in live.topDown) _BandRow(status: band, isMine: band.band == myBand),
      ],
    );
  }
}

class _BandRow extends StatelessWidget {
  const _BandRow({required this.status, required this.isMine});

  final BandStatus status;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final (label, color) = switch (status.status) {
      WaterStatus.flowing => (l10n.bandFlowing, theme.colorScheme.primary),
      WaterStatus.noWater => (l10n.bandNoWater, theme.colorScheme.error),
      // Some reports, but not enough to confirm either way.
      WaterStatus.unknown => (
        status.arrivedCount + status.noWaterCount == 0
            ? l10n.bandUnknown
            : l10n.bandReports(status.arrivedCount + status.noWaterCount),
        theme.colorScheme.onSurfaceVariant,
      ),
    };
    return Padding(
      key: ValueKey('band-${status.band.name}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            switch (status.band) {
              ElevationBand.high => Icons.landscape_outlined,
              ElevationBand.middle => Icons.home_outlined,
              ElevationBand.low => Icons.water_outlined,
            },
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: l10n.elevationLabel(status.band),
                children: [
                  if (isMine)
                    TextSpan(
                      text: '  · ${l10n.liveYourLevel}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

class _ReportPanel extends ConsumerWidget {
  const _ReportPanel({required this.neighborhoodId});

  final String neighborhoodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final fmt = ScheduleFormatters(Localizations.localeOf(context).toLanguageTag());
    final panel = ref.watch(reportControllerProvider(neighborhoodId));
    // Re-evaluate every minute so the buttons re-enable on time.
    ref.watch(ammanNowProvider);
    final now = ref.watch(clockProvider)();

    return panel.when(
      loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text(l10n.errorMessage(e)),
      data: (state) {
        final controller = ref.read(reportControllerProvider(neighborhoodId).notifier);
        final enabled = state.canReport(now);
        final last = state.reporting.lastReport;
        final next = state.reporting.nextAllowedAt;

        Widget button(ReportKind kind, IconData icon, String label) => Expanded(
          child: FilledButton.tonalIcon(
            key: Key('report-${kind.name}'),
            onPressed: enabled ? () => controller.submit(kind) : null,
            icon: state.submitting == kind
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon),
            label: Text(label),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                button(ReportKind.arrived, Icons.water_drop, l10n.reportArrived),
                const SizedBox(width: 12),
                button(ReportKind.noWater, Icons.format_color_reset, l10n.reportNoWater),
              ],
            ),
            if (state.justReported) ...[
              const SizedBox(height: 8),
              Text(l10n.reportThanks, style: theme.textTheme.bodyMedium),
            ],
            if (last != null && !enabled && state.submitting == null) ...[
              const SizedBox(height: 8),
              Text(switch (last.kind) {
                ReportKind.arrived => l10n.reportedArrivedAt(fmt.instantTime(last.createdAt)),
                ReportKind.noWater => l10n.reportedNoWaterAt(fmt.instantTime(last.createdAt)),
              }, style: theme.textTheme.bodySmall),
            ],
            if (next != null && !enabled && state.submitting == null)
              Text(
                l10n.reportNextAllowed(fmt.instantTime(next)),
                key: const Key('reportNextAllowed'),
                style: theme.textTheme.bodySmall,
              ),
            if (state.error case final error?) ...[
              const SizedBox(height: 8),
              Text(l10n.errorMessage(error), style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        );
      },
    );
  }
}
