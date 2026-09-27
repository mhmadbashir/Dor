import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../locations/domain/elevation_band.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';
import 'profile_dto.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _profiles => _client.from('profiles');

  @override
  Future<Profile> fetchProfile(String userId) => guard(() async {
    final row = await _profiles.select(ProfileDto.columns).eq('id', userId).single();
    return ProfileDto.fromRow(row);
  });

  @override
  Future<void> updateHome(String userId, String neighborhoodId, ElevationBand? elevationBand) =>
      guard(
        () => _profiles
            .update({'neighborhood_id': neighborhoodId, 'elevation_band': elevationBand?.name})
            .eq('id', userId),
      );

  @override
  Future<void> updateNotificationPrefs(
    String userId, {
    bool? waterArrival,
    bool? scheduleReminder,
  }) => guard(
    () => _profiles
        .update({
          'notify_water_arrival': ?waterArrival,
          'notify_schedule_reminder': ?scheduleReminder,
        })
        .eq('id', userId),
  );

  @override
  Future<void> updateLocale(String userId, String locale) =>
      guard(() => _profiles.update({'locale': locale}).eq('id', userId));
}
