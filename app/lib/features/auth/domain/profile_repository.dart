import '../../locations/domain/elevation_band.dart';
import 'profile.dart';

abstract interface class ProfileRepository {
  Future<Profile> fetchProfile(String userId);

  /// Saves where the user lives; [elevationBand] null means "not sure".
  Future<void> updateHome(String userId, String neighborhoodId, ElevationBand? elevationBand);

  Future<void> updateNotificationPrefs(String userId, {bool? waterArrival, bool? scheduleReminder});

  Future<void> updateLocale(String userId, String locale);
}
