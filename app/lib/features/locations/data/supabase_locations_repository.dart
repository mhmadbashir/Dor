import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/location_entities.dart';
import '../domain/locations_repository.dart';
import 'location_dtos.dart';

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
        .select('id, area_id, name_ar, name_en, center_lat, center_lng')
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
          'id, area_id, name_ar, name_en, center_lat, center_lng, '
          'area:areas(id, governorate_id, name_ar, name_en, '
          'governorate:governorates(id, name_ar, name_en))',
        )
        .eq('id', neighborhoodId)
        .single();
    return LocationDtos.details(row);
  });
}
