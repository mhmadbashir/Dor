import '../../locations/domain/elevation_band.dart';
import 'user_role.dart';

class Profile {
  const Profile({
    required this.id,
    required this.role,
    this.fullName,
    this.phone,
    this.neighborhoodId,
    this.locale = 'ar',
    this.elevationBand,
    this.notifyWaterArrival = true,
    this.notifyScheduleReminder = true,
    this.notifyScheduleStart = true,
  });

  final String id;
  final UserRole role;
  final String? fullName;
  final String? phone;
  final String? neighborhoodId;
  final String locale;

  /// Null when the user is not sure.
  final ElevationBand? elevationBand;
  final bool notifyWaterArrival;
  final bool notifyScheduleReminder;
  final bool notifyScheduleStart;

  bool get hasNeighborhood => neighborhoodId != null;

  @override
  bool operator ==(Object other) =>
      other is Profile &&
      other.id == id &&
      other.role == role &&
      other.fullName == fullName &&
      other.phone == phone &&
      other.neighborhoodId == neighborhoodId &&
      other.locale == locale &&
      other.elevationBand == elevationBand &&
      other.notifyWaterArrival == notifyWaterArrival &&
      other.notifyScheduleReminder == notifyScheduleReminder &&
      other.notifyScheduleStart == notifyScheduleStart;

  @override
  int get hashCode => Object.hash(
    id,
    role,
    fullName,
    phone,
    neighborhoodId,
    locale,
    elevationBand,
    notifyWaterArrival,
    notifyScheduleReminder,
    notifyScheduleStart,
  );
}
