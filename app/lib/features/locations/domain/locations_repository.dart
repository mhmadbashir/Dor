import 'device_location.dart';
import 'location_entities.dart';

abstract interface class LocationsRepository {
  Future<List<Governorate>> governorates();

  Future<List<Area>> areas(String governorateId);

  Future<List<Neighborhood>> neighborhoods(String areaId);

  Future<NeighborhoodDetails> neighborhoodDetails(String neighborhoodId);

  /// The served neighborhood closest to [point], or null if none is nearby.
  Future<NeighborhoodDetails?> nearestNeighborhood(GeoPoint point);
}
