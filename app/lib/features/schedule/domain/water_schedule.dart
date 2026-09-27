/// A recurring weekly supply window for a neighborhood.
class WaterSchedule {
  const WaterSchedule({
    required this.id,
    required this.neighborhoodId,
    required this.weekday,
    required this.startMinutes,
    required this.durationHours,
    this.effectiveFrom,
    this.effectiveTo,
    this.notes,
  }) : assert(weekday >= DateTime.monday && weekday <= DateTime.sunday),
       assert(startMinutes >= 0 && startMinutes < 24 * 60),
       assert(durationHours > 0);

  final String id;
  final String neighborhoodId;

  /// ISO weekday, 1 = Monday ... 7 = Sunday (same as [DateTime.weekday]).
  final int weekday;

  /// Minutes after midnight, Amman time.
  final int startMinutes;
  final int durationHours;

  /// Inclusive date range (wall-clock midnight) during which this entry applies.
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final String? notes;

  Duration get duration => Duration(hours: durationHours);

  /// Whether a window starting on [day] (wall-clock) falls in the effective range.
  bool isEffectiveOn(DateTime day) {
    final date = DateTime.utc(day.year, day.month, day.day);
    if (effectiveFrom case final from? when date.isBefore(from)) return false;
    if (effectiveTo case final to? when date.isAfter(to)) return false;
    return true;
  }
}
