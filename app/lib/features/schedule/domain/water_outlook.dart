import '../../../core/time/amman_time.dart';
import 'water_schedule.dart';

/// One concrete occurrence of a [WaterSchedule] (wall-clock times).
class WaterWindow {
  const WaterWindow({required this.schedule, required this.start, required this.end});

  final WaterSchedule schedule;
  final DateTime start;
  final DateTime end;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);
}

sealed class WaterOutlook {
  const WaterOutlook();
}

/// A scheduled window is in progress.
class WaterScheduledNow extends WaterOutlook {
  const WaterScheduledNow(this.window);
  final WaterWindow window;
}

/// The next scheduled window, [daysUntil] calendar days away (0 = later today).
class WaterScheduledNext extends WaterOutlook {
  const WaterScheduledNext(this.window, this.daysUntil);
  final WaterWindow window;
  final int daysUntil;
}

/// Nothing is scheduled in the look-ahead period.
class WaterNotScheduled extends WaterOutlook {
  const WaterNotScheduled();
}

/// One day of the recurring weekly pattern.
class WeekdayPlan {
  const WeekdayPlan({required this.weekday, required this.schedules, required this.isToday});

  final int weekday;
  final List<WaterSchedule> schedules;
  final bool isToday;
}

abstract final class WaterScheduleCalculator {
  /// How far ahead to look for the next window.
  static const lookAhead = Duration(days: 15);

  /// The Jordanian week runs Saturday to Friday.
  static const weekOrder = [
    DateTime.saturday,
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  ];

  /// All windows overlapping [from, to), sorted by start.
  static List<WaterWindow> windowsBetween(
    List<WaterSchedule> schedules,
    DateTime from,
    DateTime to,
  ) {
    if (schedules.isEmpty) return const [];
    // Start early enough to catch long windows that began before [from].
    final longest = schedules.map((s) => s.durationHours).reduce((a, b) => a > b ? a : b);
    var day = AmmanTime.startOfDay(from).subtract(Duration(days: (longest / 24).ceil()));
    final lastDay = AmmanTime.startOfDay(to);

    final windows = <WaterWindow>[];
    while (!day.isAfter(lastDay)) {
      for (final s in schedules) {
        if (s.weekday != day.weekday || !s.isEffectiveOn(day)) continue;
        final start = day.add(Duration(minutes: s.startMinutes));
        final end = start.add(s.duration);
        if (end.isAfter(from) && start.isBefore(to)) {
          windows.add(WaterWindow(schedule: s, start: start, end: end));
        }
      }
      day = day.add(const Duration(days: 1));
    }
    windows.sort((a, b) => a.start.compareTo(b.start));
    return windows;
  }

  /// What a household should expect, as of wall-clock [now].
  static WaterOutlook outlook(List<WaterSchedule> schedules, DateTime now) {
    final windows = windowsBetween(schedules, now, now.add(lookAhead));
    final current = windows.where((w) => w.contains(now)).toList();
    if (current.isNotEmpty) {
      // If windows overlap, report the one that lasts longest.
      current.sort((a, b) => b.end.compareTo(a.end));
      return WaterScheduledNow(current.first);
    }
    for (final w in windows) {
      if (w.start.isAfter(now)) {
        return WaterScheduledNext(w, AmmanTime.calendarDaysBetween(now, w.start));
      }
    }
    return const WaterNotScheduled();
  }

  /// The recurring pattern Saturday..Friday, limited to entries that are
  /// in effect this coming week.
  static List<WeekdayPlan> weeklyPattern(List<WaterSchedule> schedules, DateTime now) {
    final today = AmmanTime.startOfDay(now);
    final active = schedules.where((s) {
      // In effect on at least one of the next 7 days.
      for (var i = 0; i < 7; i++) {
        if (s.isEffectiveOn(today.add(Duration(days: i)))) return true;
      }
      return false;
    });
    return [
      for (final weekday in weekOrder)
        WeekdayPlan(
          weekday: weekday,
          isToday: weekday == today.weekday,
          schedules: active.where((s) => s.weekday == weekday).toList()
            ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes)),
        ),
    ];
  }
}
