/// Jordan has been on permanent UTC+3 since October 2022 (no DST), so Amman
/// time is a fixed offset and no timezone database is needed.
///
/// Wall-clock values are represented as UTC [DateTime]s whose fields read as
/// Amman local time. This keeps date arithmetic free of device-timezone and
/// DST effects; never treat these values as real instants.
abstract final class AmmanTime {
  static const utcOffset = Duration(hours: 3);

  /// Amman wall-clock time for an [instant].
  static DateTime wallClock(DateTime instant) => instant.toUtc().add(utcOffset);

  /// Midnight (wall clock) of the day containing [wallClock].
  static DateTime startOfDay(DateTime wallClock) =>
      DateTime.utc(wallClock.year, wallClock.month, wallClock.day);

  /// Whole calendar days from [from] to [to] (both wall clock).
  static int calendarDaysBetween(DateTime from, DateTime to) =>
      startOfDay(to).difference(startOfDay(from)).inDays;
}
