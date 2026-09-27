import '../../locations/domain/elevation_band.dart';
import 'profile.dart';

abstract interface class ProfileRepository {
  Future<Profile> fetchProfile(String userId);

  /// Saves where the user lives; [elevationBand] null means "not sure".
  Future<void> updateHome(String userId, String neighborhoodId, ElevationBand? elevationBand);

  /// Only the preferences passed (non-null) are changed.
  Future<void> updateNotificationPrefs(
    String userId, {
    bool? waterArrival,
    bool? scheduleReminder,
    bool? scheduleStart,
  });

  Future<void> updateLocale(String userId, String locale);
}
