import '../domain/water_schedule.dart';

abstract final class WaterScheduleDto {
  static const columns =
      'id, neighborhood_id, weekday, start_time, duration_hours, effective_from, effective_to, notes';

  static WaterSchedule fromRow(Map<String, dynamic> row) => WaterSchedule(
    id: row['id'] as String,
    neighborhoodId: row['neighborhood_id'] as String,
    weekday: row['weekday'] as int,
    startMinutes: parseTimeOfDay(row['start_time'] as String),
    durationHours: row['duration_hours'] as int,
    effectiveFrom: _date(row['effective_from']),
    effectiveTo: _date(row['effective_to']),
    notes: row['notes'] as String?,
  );

  /// Parses Postgres `time` text (`HH:MM[:SS]`) into minutes after midnight.
  static int parseTimeOfDay(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    final d = DateTime.parse(value as String);
    return DateTime.utc(d.year, d.month, d.day);
  }
}
