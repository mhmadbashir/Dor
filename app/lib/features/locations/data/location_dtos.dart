import '../domain/localized_name.dart';
import '../domain/location_entities.dart';

abstract final class LocationDtos {
  static LocalizedName _name(Map<String, dynamic> row) =>
      LocalizedName(ar: row['name_ar'] as String, en: row['name_en'] as String);

  static Governorate governorate(Map<String, dynamic> row) =>
      Governorate(id: row['id'] as String, name: _name(row));

  static Area area(Map<String, dynamic> row) => Area(
    id: row['id'] as String,
    governorateId: row['governorate_id'] as String,
    name: _name(row),
  );

  static Neighborhood neighborhood(Map<String, dynamic> row) => Neighborhood(
    id: row['id'] as String,
    areaId: row['area_id'] as String,
    name: _name(row),
    centerLat: (row['center_lat'] as num?)?.toDouble(),
    centerLng: (row['center_lng'] as num?)?.toDouble(),
  );

  /// Parses `neighborhoods` joined as `*, area:areas(*, governorate:governorates(*))`.
  static NeighborhoodDetails details(Map<String, dynamic> row) {
    final areaRow = row['area'] as Map<String, dynamic>;
    final governorateRow = areaRow['governorate'] as Map<String, dynamic>;
    return NeighborhoodDetails(
      neighborhood: neighborhood(row),
      area: area(areaRow),
      governorate: governorate(governorateRow),
    );
  }
}
