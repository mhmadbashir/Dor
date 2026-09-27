import 'localized_name.dart';

class Governorate {
  const Governorate({required this.id, required this.name});

  final String id;
  final LocalizedName name;
}

class Area {
  const Area({required this.id, required this.governorateId, required this.name});

  final String id;
  final String governorateId;
  final LocalizedName name;
}

class Neighborhood {
  const Neighborhood({
    required this.id,
    required this.areaId,
    required this.name,
    this.centerLat,
    this.centerLng,
    this.elevationLowMaxM,
    this.elevationHighMinM,
  });

  final String id;
  final String areaId;
  final LocalizedName name;
  final double? centerLat;
  final double? centerLng;

  /// Altitude thresholds (meters) used to suggest a home's elevation band.
  final double? elevationLowMaxM;
  final double? elevationHighMinM;
}

/// A neighborhood together with its parent area and governorate.
class NeighborhoodDetails {
  const NeighborhoodDetails({
    required this.neighborhood,
    required this.area,
    required this.governorate,
  });

  final Neighborhood neighborhood;
  final Area area;
  final Governorate governorate;
}
