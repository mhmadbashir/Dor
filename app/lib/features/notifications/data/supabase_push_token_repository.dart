import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/push_messaging.dart';

class SupabasePushTokenRepository implements PushTokenRepository {
  SupabasePushTokenRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> register(String token, String platform) => guard(
    () => _client.rpc<void>(
      'register_device_token',
      params: {'p_token': token, 'p_platform': platform},
    ),
  );

  @override
  Future<void> unregister(String token) =>
      guard(() => _client.rpc<void>('unregister_device_token', params: {'p_token': token}));
}
