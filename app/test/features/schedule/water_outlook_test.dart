import 'package:dor/core/time/amman_time.dart';
import 'package:dor/features/schedule/domain/water_outlook.dart';
import 'package:dor/features/schedule/domain/water_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

WaterSchedule schedule(
  int weekday,
  int hour,
  int durationHours, {
  String id = 's',
  DateTime? from,
  DateTime? to,
}) =>
    WaterSchedule(
      id: id,
      neighborhoodId: 'n',
      weekday: weekday,
      startMinutes: hour * 60,
      durationHours: durationHours,
      effectiveFrom: from,
      effectiveTo: to,
    );

/// Amman wall-clock. 2026-09-27 is a Sunday.
DateTime at(int day, int hour, [int minute = 0]) => DateTime.utc(2026, 9, day, hour, minute);

void main() {
  group('AmmanTime', () {
    test('is UTC+3 regardless of device timezone', () {
      expect(AmmanTime.wallClock(DateTime.utc(2026, 1, 15, 22)), DateTime.utc(2026, 1, 16, 1));
      // No DST in summer either.
      expect(AmmanTime.wallClock(DateTime.utc(2026, 7, 15, 22)), DateTime.utc(2026, 7, 16, 1));
    });

    test('calendarDaysBetween counts date changes, not 24h periods', () {
      expect(AmmanTime.calendarDaysBetween(at(27, 23), at(28, 1)), 1);
      expect(AmmanTime.calendarDaysBetween(at(27, 1), at(27, 23)), 0);
    });
  });

  group('outlook', () {
    test('no schedules means not scheduled', () {
      expect(WaterScheduleCalculator.outlook(const [], at(27, 12)), isA<WaterNotScheduled>());
    });

    test('next window later this week', () {
      // Tuesday 08:00; now is Sunday noon.
      final result = WaterScheduleCalculator.outlook([schedule(DateTime.tuesday, 8, 48)], at(27, 12));
      expect(result, isA<WaterScheduledNext>());
      final next = result as WaterScheduledNext;
      expect(next.window.start, at(29, 8));
      expect(next.window.end, DateTime.utc(2026, 10, 1, 8));
      expect(next.daysUntil, 2);
    });

    test('tomorrow is one day away even if less than 24h', () {
      final result = WaterScheduleCalculator.outlook([schedule(DateTime.monday, 6, 12)], at(27, 22));
      expect((result as WaterScheduledNext).daysUntil, 1);
    });

    test('later today is zero days away', () {
      final result = WaterScheduleCalculator.outlook([schedule(DateTime.sunday, 18, 12)], at(27, 9));
      expect((result as WaterScheduledNext).daysUntil, 0);
    });

    test('inside a window reports it as current', () {
      final result = WaterScheduleCalculator.outlook([schedule(DateTime.sunday, 6, 36)], at(27, 9));
      expect(result, isA<WaterScheduledNow>());
      expect((result as WaterScheduledNow).window.end, at(28, 18));
    });

    test('a multi-day window that started last week is still current', () {
      // Saturday 18:00 for 48h covers Sunday and Monday.
      final result = WaterScheduleCalculator.outlook([schedule(DateTime.saturday, 18, 48)], at(28, 10));
      expect(result, isA<WaterScheduledNow>());
      expect((result as WaterScheduledNow).window.start, at(26, 18));
    });

    test('window end is exclusive', () {
      final result = WaterScheduleCalculator.outlook([schedule(DateTime.sunday, 6, 6)], at(27, 12));
      expect(result, isA<WaterScheduledNext>());
      expect((result as WaterScheduledNext).daysUntil, 7);
    });

    test('window start is inclusive', () {
      final result = WaterScheduleCalculator.outlook([schedule(DateTime.sunday, 6, 6)], at(27, 6));
      expect(result, isA<WaterScheduledNow>());
    });

    test('picks the earliest of several upcoming windows', () {
      final result = WaterScheduleCalculator.outlook([
        schedule(DateTime.wednesday, 18, 12, id: 'wed'),
        schedule(DateTime.saturday, 18, 12, id: 'sat'),
      ], at(27, 12));
      expect((result as WaterScheduledNext).window.schedule.id, 'wed');
    });

    test('overlapping windows report the one lasting longest', () {
      final result = WaterScheduleCalculator.outlook([
        schedule(DateTime.sunday, 6, 6, id: 'short'),
        schedule(DateTime.sunday, 8, 24, id: 'long'),
      ], at(27, 9));
      expect((result as WaterScheduledNow).window.schedule.id, 'long');
    });

    test('respects effective dates', () {
      final s = schedule(DateTime.tuesday, 8, 12, from: DateTime.utc(2026, 10, 5));
      final result = WaterScheduleCalculator.outlook([s], at(27, 12));
      // Tuesday Sep 29 is before the effective date; next is Oct 6.
      expect((result as WaterScheduledNext).window.start, DateTime.utc(2026, 10, 6, 8));
    });

    test('expired schedules are ignored', () {
      final s = schedule(DateTime.tuesday, 8, 12, to: DateTime.utc(2026, 9, 1));
      expect(WaterScheduleCalculator.outlook([s], at(27, 12)), isA<WaterNotScheduled>());
    });
  });

  group('weeklyPattern', () {
    test('runs Saturday to Friday and marks today', () {
      final week = WaterScheduleCalculator.weeklyPattern([schedule(DateTime.tuesday, 8, 48)], at(27, 12));
      expect(week.map((d) => d.weekday), [6, 7, 1, 2, 3, 4, 5]);
      expect(week.where((d) => d.isToday).single.weekday, DateTime.sunday);
      expect(week.firstWhere((d) => d.weekday == DateTime.tuesday).schedules, hasLength(1));
      expect(week.where((d) => d.schedules.isNotEmpty), hasLength(1));
    });

    test('sorts same-day windows by start time and drops expired ones', () {
      final week = WaterScheduleCalculator.weeklyPattern([
        schedule(DateTime.monday, 18, 6, id: 'evening'),
        schedule(DateTime.monday, 6, 6, id: 'morning'),
        schedule(DateTime.monday, 12, 6, id: 'old', to: DateTime.utc(2026, 1, 1)),
      ], at(27, 12));
      final monday = week.firstWhere((d) => d.weekday == DateTime.monday);
      expect(monday.schedules.map((s) => s.id), ['morning', 'evening']);
    });
  });
}
