import 'package:intl/intl.dart';

/// Locale-aware labels for schedule values. Inputs are Amman wall-clock values.
class ScheduleFormatters {
  ScheduleFormatters(this.locale);

  final String locale;

  // 2024-01-01 was a Monday, so adding (weekday - 1) days yields that weekday.
  static final _monday = DateTime.utc(2024, 1, 1);

  String weekdayName(int weekday) =>
      DateFormat.EEEE(locale).format(_monday.add(Duration(days: weekday - 1)));

  String timeOfDay(int minutes) =>
      DateFormat.jm(locale).format(_monday.add(Duration(minutes: minutes)));

  String weekday(DateTime wallClock) => DateFormat.EEEE(locale).format(wallClock);

  String time(DateTime wallClock) => DateFormat.jm(locale).format(wallClock);

  String dayAndTime(DateTime wallClock) => '${weekday(wallClock)} ${time(wallClock)}';
}
