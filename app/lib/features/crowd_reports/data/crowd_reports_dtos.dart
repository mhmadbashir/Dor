import '../../locations/domain/elevation_band.dart';
import '../domain/crowd_report.dart';
import '../domain/live_status.dart';

abstract final class CrowdReportsDtos {
  static CrowdReport report(Map<String, dynamic> row) => CrowdReport(
    id: row['id'] as String,
    kind: ReportKind.fromDb(row['kind'] as String),
    createdAt: DateTime.parse(row['created_at'] as String),
  );

  static BandStatus? bandStatus(Map<String, dynamic> row) {
    final band = ElevationBand.tryParse(row['elevation_band'] as String?);
    if (band == null) return null;
    return BandStatus(
      band: band,
      status: WaterStatus.fromDb(row['status'] as String),
      flowingSince: _time(row['flowing_since']),
      arrivedCount: (row['arrived_count'] as num?)?.toInt() ?? 0,
      noWaterCount: (row['no_water_count'] as num?)?.toInt() ?? 0,
      lastReportAt: _time(row['last_report_at']),
    );
  }

  static DateTime? _time(Object? value) => value == null ? null : DateTime.parse(value as String);
}
