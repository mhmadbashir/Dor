import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_providers.dart';
import '../data/supabase_locations_repository.dart';
import '../domain/location_entities.dart';
import '../domain/locations_repository.dart';

final locationsRepositoryProvider = Provider<LocationsRepository>(
  (ref) => SupabaseLocationsRepository(ref.watch(supabaseClientProvider)),
);

final governoratesProvider = FutureProvider.autoDispose<List<Governorate>>(
  (ref) => ref.watch(locationsRepositoryProvider).governorates(),
);

final areasProvider = FutureProvider.autoDispose.family<List<Area>, String>(
  (ref, governorateId) => ref.watch(locationsRepositoryProvider).areas(governorateId),
);

final neighborhoodsProvider = FutureProvider.autoDispose.family<List<Neighborhood>, String>(
  (ref, areaId) => ref.watch(locationsRepositoryProvider).neighborhoods(areaId),
);

final neighborhoodDetailsProvider = FutureProvider.autoDispose.family<NeighborhoodDetails, String>(
  (ref, neighborhoodId) =>
      ref.watch(locationsRepositoryProvider).neighborhoodDetails(neighborhoodId),
);
