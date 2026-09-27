import '../domain/profile.dart';
import '../domain/user_role.dart';

abstract final class ProfileDto {
  static const columns = 'id, role, full_name, phone, neighborhood_id, locale';

  static Profile fromRow(Map<String, dynamic> row) => Profile(
    id: row['id'] as String,
    role: UserRole.fromName(row['role'] as String),
    fullName: row['full_name'] as String?,
    phone: row['phone'] as String?,
    neighborhoodId: row['neighborhood_id'] as String?,
    locale: (row['locale'] as String?) ?? 'ar',
  );
}
