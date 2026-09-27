enum ReportKind {
  arrived('arrived'),
  noWater('no_water');

  const ReportKind(this.dbName);

  final String dbName;

  static ReportKind fromDb(String value) => values.firstWhere((k) => k.dbName == value);
}

class CrowdReport {
  const CrowdReport({required this.id, required this.kind, required this.createdAt});

  final String id;
  final ReportKind kind;
  final DateTime createdAt;
}

/// Thrown when the user already reported within the rate-limit window.
class ReportRateLimited implements Exception {
  const ReportRateLimited(this.nextAllowedAt);

  final DateTime nextAllowedAt;

  @override
  String toString() => 'ReportRateLimited(until $nextAllowedAt)';
}

/// The user's reporting situation for their neighborhood.
class ReportingState {
  const ReportingState({this.lastReport, required this.rateLimit, this.serverNextAllowedAt});

  final CrowdReport? lastReport;
  final Duration rateLimit;

  /// Set when the server rejected a report (e.g. one made from another device).
  final DateTime? serverNextAllowedAt;

  DateTime? get nextAllowedAt {
    final fromLast = lastReport?.createdAt.add(rateLimit);
    final fromServer = serverNextAllowedAt;
    if (fromLast == null) return fromServer;
    if (fromServer == null) return fromLast;
    return fromLast.isAfter(fromServer) ? fromLast : fromServer;
  }

  bool canReport(DateTime now) {
    final next = nextAllowedAt;
    return next == null || !now.isBefore(next);
  }
}
