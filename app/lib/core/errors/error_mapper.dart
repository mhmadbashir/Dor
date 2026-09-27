import 'package:supabase_flutter/supabase_flutter.dart';

import 'failure.dart';

/// Translates Supabase / transport errors into [Failure]s.
Failure mapError(Object error) {
  if (error is Failure) return error;

  if (error is AuthRetryableFetchException) {
    return Failure(FailureKind.network, error);
  }
  if (error is AuthException) {
    final status = error.statusCode;
    final code = error.code ?? '';
    if (status == '429' ||
        code == 'over_sms_send_rate_limit' ||
        code == 'over_request_rate_limit') {
      return Failure(FailureKind.rateLimited, error);
    }
    if (code == 'otp_expired' || code == 'invalid_credentials' || status == '403') {
      return Failure(FailureKind.invalidOtp, error);
    }
    if (code == 'validation_failed' || code == 'sms_send_failed') {
      return Failure(FailureKind.invalidPhone, error);
    }
    if (code == 'session_not_found' || code == 'refresh_token_not_found' || status == '401') {
      return Failure(FailureKind.sessionExpired, error);
    }
    return Failure(FailureKind.unknown, error);
  }
  if (error is PostgrestException) {
    switch (error.code) {
      case '42501':
        return Failure(FailureKind.forbidden, error);
      case 'PGRST301' || 'PGRST303':
        return Failure(FailureKind.sessionExpired, error);
    }
    return Failure(FailureKind.unknown, error);
  }
  // http's ClientException / dart:io's SocketException are not exported by
  // supabase_flutter and dart:io is unavailable on web, so match by name.
  final type = error.runtimeType.toString();
  if (type == 'ClientException' || type == 'SocketException' || type == 'TimeoutException') {
    return Failure(FailureKind.network, error);
  }
  return Failure(FailureKind.unknown, error);
}

/// Runs [body] and rethrows any error as a [Failure].
Future<T> guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } catch (e, st) {
    Error.throwWithStackTrace(mapError(e), st);
  }
}
