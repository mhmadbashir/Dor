import 'package:dor/features/schedule/data/water_schedule_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a Supabase row', () {
    final s = WaterScheduleDto.fromRow({
      'id': 'id-1',
      'neighborhood_id': 'nb-1',
      'weekday': 7,
      'start_time': '06:30:00',
      'duration_hours': 36,
      'effective_from': '2026-10-01',
      'effective_to': null,
      'notes': 'note',
    });
    expect(s.weekday, DateTime.sunday);
    expect(s.startMinutes, 6 * 60 + 30);
    expect(s.durationHours, 36);
    expect(s.effectiveFrom, DateTime.utc(2026, 10, 1));
    expect(s.effectiveTo, isNull);
  });

  test('parseTimeOfDay handles HH:MM', () {
    expect(WaterScheduleDto.parseTimeOfDay('18:00'), 18 * 60);
  });
}
