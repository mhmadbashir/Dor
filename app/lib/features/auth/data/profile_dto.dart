import '../../locations/domain/elevation_band.dart';
import '../domain/profile.dart';
import '../domain/user_role.dart';

abstract final class ProfileDto {
  static const columns =
      'id, role, full_name, phone, neighborhood_id, locale, elevation_band, '
      'notify_water_arrival, notify_schedule_reminder';

  static Profile fromRow(Map<String, dynamic> row) => Profile(
    id: row['id'] as String,
    role: UserRole.fromName(row['role'] as String),
    fullName: row['full_name'] as String?,
    phone: row['phone'] as String?,
    neighborhoodId: row['neighborhood_id'] as String?,
    locale: (row['locale'] as String?) ?? 'ar',
    elevationBand: ElevationBand.tryParse(row['elevation_band'] as String?),
    notifyWaterArrival: (row['notify_water_arrival'] as bool?) ?? true,
    notifyScheduleReminder: (row['notify_schedule_reminder'] as bool?) ?? true,
  );
}
