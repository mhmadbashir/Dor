import 'package:dor/core/errors/error_mapper.dart';
import 'package:dor/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  FailureKind kindOf(Object e) => mapError(e).kind;

  test('auth errors', () {
    expect(kindOf(const AuthApiException('x', statusCode: '429')), FailureKind.rateLimited);
    expect(kindOf(const AuthApiException('x', statusCode: '403', code: 'otp_expired')), FailureKind.invalidOtp);
    expect(kindOf(AuthRetryableFetchException()), FailureKind.network);
  });

  test('postgrest errors', () {
    expect(kindOf(const PostgrestException(message: 'x', code: '42501')), FailureKind.forbidden);
    expect(kindOf(const PostgrestException(message: 'x', code: 'PGRST303')), FailureKind.sessionExpired);
  });

  test('failures pass through and unknown errors map to unknown', () {
    const f = Failure(FailureKind.invalidPhone);
    expect(identical(mapError(f), f), isTrue);
    expect(kindOf(StateError('x')), FailureKind.unknown);
  });

  test('guard rethrows as Failure', () async {
    await expectLater(
      guard<void>(() async => throw const PostgrestException(message: 'x', code: '42501')),
      throwsA(isA<Failure>().having((f) => f.kind, 'kind', FailureKind.forbidden)),
    );
  });
}
