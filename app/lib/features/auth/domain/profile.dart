import 'user_role.dart';

class Profile {
  const Profile({
    required this.id,
    required this.role,
    this.fullName,
    this.phone,
    this.neighborhoodId,
    this.locale = 'ar',
  });

  final String id;
  final UserRole role;
  final String? fullName;
  final String? phone;
  final String? neighborhoodId;
  final String locale;

  bool get hasNeighborhood => neighborhoodId != null;

  @override
  bool operator ==(Object other) =>
      other is Profile &&
      other.id == id &&
      other.role == role &&
      other.fullName == fullName &&
      other.phone == phone &&
      other.neighborhoodId == neighborhoodId &&
      other.locale == locale;

  @override
  int get hashCode => Object.hash(id, role, fullName, phone, neighborhoodId, locale);
}
