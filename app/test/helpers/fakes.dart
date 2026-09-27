import 'dart:async';

import 'package:dor/features/auth/domain/auth_repository.dart';
import 'package:dor/features/auth/domain/phone_number.dart';
import 'package:dor/features/auth/domain/profile.dart';
import 'package:dor/features/auth/domain/profile_repository.dart';
import 'package:dor/features/auth/domain/user_role.dart';
import 'package:dor/features/locations/domain/device_location.dart';
import 'package:dor/features/locations/domain/localized_name.dart';
import 'package:dor/features/locations/domain/location_entities.dart';
import 'package:dor/features/locations/domain/locations_repository.dart';
import 'package:dor/features/schedule/domain/schedule_repository.dart';
import 'package:dor/features/schedule/domain/water_schedule.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockLocationsRepository extends Mock implements LocationsRepository {}

class MockScheduleRepository extends Mock implements ScheduleRepository {}

class MockDeviceLocationService extends Mock implements DeviceLocationService {}

void registerFallbacks() {
  registerFallbackValue(PhoneNumber.tryParse('0790000000')!);
  registerFallbackValue(const GeoPoint(0, 0));
  registerFallbackValue(LocationIssue.unavailable);
}

const userId = 'user-1';

Profile householdProfile({String? neighborhoodId, String locale = 'ar'}) =>
    Profile(id: userId, role: UserRole.household, neighborhoodId: neighborhoodId, locale: locale);

const amman = Governorate(
  id: 'gov-amman',
  name: LocalizedName(ar: 'عمّان', en: 'Amman'),
);
const irbid = Governorate(
  id: 'gov-irbid',
  name: LocalizedName(ar: 'إربد', en: 'Irbid'),
);
const tlaaAlAliArea = Area(
  id: 'area-tlaa',
  governorateId: 'gov-amman',
  name: LocalizedName(ar: 'تلاع العلي وأم السماق وخلدا', en: "Tla' Al-Ali, Um Al-Summaq & Khalda"),
);
const markaArea = Area(
  id: 'area-marka',
  governorateId: 'gov-amman',
  name: LocalizedName(ar: 'ماركا', en: 'Marka'),
);
const khalda = Neighborhood(
  id: 'nb-khalda',
  areaId: 'area-tlaa',
  name: LocalizedName(ar: 'خلدا', en: 'Khalda'),
);
const tlaaAlAli = Neighborhood(
  id: 'nb-tlaa',
  areaId: 'area-tlaa',
  name: LocalizedName(ar: 'تلاع العلي', en: "Tla' Al-Ali"),
);

const khaldaDetails = NeighborhoodDetails(
  neighborhood: khalda,
  area: tlaaAlAliArea,
  governorate: amman,
);

/// Tuesday 08:00 for 48h, as in seed.sql.
const khaldaSchedule = WaterSchedule(
  id: 's1',
  neighborhoodId: 'nb-khalda',
  weekday: DateTime.tuesday,
  startMinutes: 8 * 60,
  durationHours: 48,
);

/// An auth repository whose user id can be changed from the test.
MockAuthRepository signedInAuth([String? id = userId]) {
  final auth = MockAuthRepository();
  final controller = StreamController<String?>.broadcast();
  when(() => auth.currentUserId).thenReturn(id);
  when(auth.watchUserId).thenAnswer((_) => controller.stream);
  return auth;
}

/// A point a few hundred meters from Khalda's center.
const inKhalda = GeoPoint(31.9975, 35.8370);
