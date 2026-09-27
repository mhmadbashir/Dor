import 'water_schedule.dart';

abstract interface class ScheduleRepository {
  Future<List<WaterSchedule>> forNeighborhood(String neighborhoodId);
}
