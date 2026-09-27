import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_providers.dart';
import '../data/supabase_crowd_reports_repository.dart';
import '../domain/crowd_report.dart';
import '../domain/crowd_reports_repository.dart';
import '../domain/live_status.dart';

final crowdReportsRepositoryProvider = Provider<CrowdReportsRepository>(
  (ref) => SupabaseCrowdReportsRepository(ref.watch(supabaseClientProvider)),
);

/// Live per-band status for a neighborhood (Supabase Realtime).
final liveStatusProvider = StreamProvider.autoDispose.family<NeighborhoodLiveStatus, String>(
  (ref, neighborhoodId) => ref.watch(crowdReportsRepositoryProvider).watchStatus(neighborhoodId),
);

class ReportPanelState {
  const ReportPanelState({
    required this.reporting,
    this.submitting,
    this.error,
    this.justReported = false,
  });

  final ReportingState reporting;

  /// The kind being submitted right now, if any.
  final ReportKind? submitting;
  final Object? error;

  /// A report was just accepted (show a thank-you).
  final bool justReported;

  bool canReport(DateTime now) => submitting == null && reporting.canReport(now);
}

/// The signed-in user's reporting for one neighborhood.
class ReportController extends AsyncNotifier<ReportPanelState> {
  ReportController(this.neighborhoodId);

  final String neighborhoodId;

  @override
  Future<ReportPanelState> build() async {
    final repo = ref.watch(crowdReportsRepositoryProvider);
    final (last, rateLimit) = await (repo.myLatestReport(neighborhoodId), repo.rateLimit()).wait;
    return ReportPanelState(
      reporting: ReportingState(lastReport: last, rateLimit: rateLimit),
    );
  }

  Future<void> submit(ReportKind kind) async {
    final current = state.value;
    if (current == null || current.submitting != null) return;
    state = AsyncData(ReportPanelState(reporting: current.reporting, submitting: kind));
    try {
      final report = await ref.read(crowdReportsRepositoryProvider).submit(neighborhoodId, kind);
      if (!ref.mounted) return;
      state = AsyncData(
        ReportPanelState(
          reporting: ReportingState(lastReport: report, rateLimit: current.reporting.rateLimit),
          justReported: true,
        ),
      );
    } on ReportRateLimited catch (e) {
      // Reported from another device; show when they can report again.
      if (!ref.mounted) return;
      state = AsyncData(
        ReportPanelState(
          reporting: ReportingState(
            lastReport: current.reporting.lastReport,
            rateLimit: current.reporting.rateLimit,
            serverNextAllowedAt: e.nextAllowedAt,
          ),
        ),
      );
    } catch (e) {
      if (ref.mounted) state = AsyncData(ReportPanelState(reporting: current.reporting, error: e));
    }
  }
}

final reportControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ReportController, ReportPanelState, String>(ReportController.new);
