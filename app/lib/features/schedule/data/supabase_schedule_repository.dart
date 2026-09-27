import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/schedule_repository.dart';
import '../domain/water_schedule.dart';
import 'water_schedule_dto.dart';

class SupabaseScheduleRepository implements ScheduleRepository {
  SupabaseScheduleRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<WaterSchedule>> forNeighborhood(String neighborhoodId) => guard(() async {
    final rows = await _client
        .from('water_schedules')
        .select(WaterScheduleDto.columns)
        .eq('neighborhood_id', neighborhoodId)
        .order('weekday')
        .order('start_time');
    return rows.map(WaterScheduleDto.fromRow).toList();
  });
}
