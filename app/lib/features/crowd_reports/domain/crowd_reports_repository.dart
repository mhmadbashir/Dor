import 'crowd_report.dart';
import 'live_status.dart';

abstract interface class CrowdReportsRepository {
  /// Live per-band status; emits on every change.
  Stream<NeighborhoodLiveStatus> watchStatus(String neighborhoodId);

  /// The signed-in user's most recent report for [neighborhoodId], if any.
  Future<CrowdReport?> myLatestReport(String neighborhoodId);

  /// How long users must wait between reports for the same neighborhood.
  Future<Duration> rateLimit();

  /// Throws [ReportRateLimited] when reporting again too soon.
  Future<CrowdReport> submit(String neighborhoodId, ReportKind kind);
}
