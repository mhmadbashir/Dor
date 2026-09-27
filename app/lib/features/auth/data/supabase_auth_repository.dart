import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/auth_repository.dart';
import '../domain/phone_number.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  @override
  Stream<String?> watchUserId() =>
      _auth.onAuthStateChange.map((state) => state.session?.user.id).distinct();

  @override
  String? get currentUserId => _auth.currentUser?.id;

  @override
  Future<void> sendOtp(PhoneNumber phone) =>
      guard(() => _auth.signInWithOtp(phone: phone.e164, shouldCreateUser: true));

  @override
  Future<void> verifyOtp(PhoneNumber phone, String code) =>
      guard(() => _auth.verifyOTP(phone: phone.e164, token: code, type: OtpType.sms));

  @override
  Future<void> signOut() => guard(() => _auth.signOut());
}
