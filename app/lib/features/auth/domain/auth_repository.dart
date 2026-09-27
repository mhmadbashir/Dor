import 'phone_number.dart';

abstract interface class AuthRepository {
  /// Emits the signed-in user id, or null when signed out.
  Stream<String?> watchUserId();

  String? get currentUserId;

  Future<void> sendOtp(PhoneNumber phone);

  Future<void> verifyOtp(PhoneNumber phone, String code);

  Future<void> signOut();
}
