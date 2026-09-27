import 'profile.dart';

abstract interface class ProfileRepository {
  Future<Profile> fetchProfile(String userId);

  Future<void> updateNeighborhood(String userId, String neighborhoodId);

  Future<void> updateLocale(String userId, String locale);
}
