import 'dart:async';

import 'package:dor/features/auth/domain/auth_repository.dart';
import 'package:dor/features/auth/domain/phone_number.dart';
import 'package:dor/features/auth/domain/profile.dart';
import 'package:dor/features/auth/domain/profile_repository.dart';
import 'package:dor/features/auth/domain/user_role.dart';
import 'package:dor/features/crowd_reports/domain/crowd_report.dart';
import 'package:dor/features/crowd_reports/domain/crowd_reports_repository.dart';
import 'package:dor/features/crowd_reports/domain/live_status.dart';
import 'package:dor/features/locations/domain/elevation_band.dart';
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

Profile householdProfile({String? neighborhoodId, String locale = 'ar', ElevationBand? band}) =>
    Profile(
      id: userId,
      role: UserRole.household,
      neighborhoodId: neighborhoodId,
      locale: locale,
      elevationBand: band,
    );

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
  elevationLowMaxM: 960,
  elevationHighMinM: 1020,
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
const khaldaFix = DeviceFix(inKhalda);

/// In-memory crowd reports backend with a controllable live status stream.
class FakeCrowdReportsRepository implements CrowdReportsRepository {
  FakeCrowdReportsRepository({this.latest, this.limit = const Duration(hours: 6)});

  final _status = StreamController<NeighborhoodLiveStatus>.broadcast();
  CrowdReport? latest;
  final Duration limit;
  DateTime Function() now = DateTime.now;
  Object? submitError;
  final submitted = <ReportKind>[];

  var _current = NeighborhoodLiveStatus(const []);

  void emit(List<BandStatus> bands) => _status.add(_current = NeighborhoodLiveStatus(bands));

  @override
  Stream<NeighborhoodLiveStatus> watchStatus(String neighborhoodId) async* {
    // Like Supabase: the current snapshot first, then changes.
    yield _current;
    yield* _status.stream;
  }

  @override
  Future<CrowdReport?> myLatestReport(String neighborhoodId) async => latest;

  @override
  Future<Duration> rateLimit() async => limit;

  @override
  Future<CrowdReport> submit(String neighborhoodId, ReportKind kind) async {
    if (submitError case final e?) throw e;
    submitted.add(kind);
    return latest = CrowdReport(id: 'r${submitted.length}', kind: kind, createdAt: now());
  }
}

BandStatus flowing(ElevationBand band, DateTime since, int count) =>
    BandStatus(band: band, status: WaterStatus.flowing, flowingSince: since, arrivedCount: count);
