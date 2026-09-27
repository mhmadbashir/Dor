import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/device_location.dart';
import '../domain/location_entities.dart';
import '../domain/locations_repository.dart';
import 'location_dtos.dart';

abstract final class LocationColumns {
  static const neighborhood =
      'id, area_id, name_ar, name_en, center_lat, center_lng, elevation_low_max_m, elevation_high_min_m';
}

class SupabaseLocationsRepository implements LocationsRepository {
  SupabaseLocationsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Governorate>> governorates() => guard(() async {
    final rows = await _client.from('governorates').select('id, name_ar, name_en').order('name_en');
    return rows.map(LocationDtos.governorate).toList();
  });

  @override
  Future<List<Area>> areas(String governorateId) => guard(() async {
    final rows = await _client
        .from('areas')
        .select('id, governorate_id, name_ar, name_en')
        .eq('governorate_id', governorateId)
        .order('name_en');
    return rows.map(LocationDtos.area).toList();
  });

  @override
  Future<List<Neighborhood>> neighborhoods(String areaId) => guard(() async {
    final rows = await _client
        .from('neighborhoods')
        .select(LocationColumns.neighborhood)
        .eq('area_id', areaId)
        .eq('is_active', true)
        .order('name_en');
    return rows.map(LocationDtos.neighborhood).toList();
  });

  @override
  Future<NeighborhoodDetails> neighborhoodDetails(String neighborhoodId) => guard(() async {
    final row = await _client
        .from('neighborhoods')
        .select(
          '${LocationColumns.neighborhood}, '
          'area:areas(id, governorate_id, name_ar, name_en, '
          'governorate:governorates(id, name_ar, name_en))',
        )
        .eq('id', neighborhoodId)
        .single();
    return LocationDtos.details(row);
  });

  @override
  Future<NeighborhoodDetails?> nearestNeighborhood(GeoPoint point) => guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'nearest_neighborhood',
      params: {'p_lat': point.latitude, 'p_lng': point.longitude},
    );
    if (rows.isEmpty) return null;
    final id = (rows.first as Map<String, dynamic>)['neighborhood_id'] as String;
    return neighborhoodDetails(id);
  });
}
