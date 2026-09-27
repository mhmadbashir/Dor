import 'package:dor/core/errors/failure.dart';
import 'package:dor/features/auth/domain/phone_number.dart';
import 'package:dor/features/auth/presentation/auth_providers.dart';
import 'package:dor/features/auth/presentation/sign_in_controllers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

void main() {
  setUpAll(registerFallbacks);

  late MockAuthRepository auth;
  late ProviderContainer container;

  setUp(() {
    auth = signedInAuth(null);
    container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      retry: (_, _) => null,
    );
  });

  group('SendCodeController', () {
    test('rejects an invalid number without calling the backend', () async {
      final sub = container.listen(sendCodeControllerProvider, (_, _) {});
      final result = await container.read(sendCodeControllerProvider.notifier).sendCode('12345');

      expect(result, isNull);
      expect((sub.read().error! as Failure).kind, FailureKind.invalidPhone);
      verifyNever(() => auth.sendOtp(any()));
    });

    test('normalizes the number and sends the code', () async {
      when(() => auth.sendOtp(any())).thenAnswer((_) async {});
      container.listen(sendCodeControllerProvider, (_, _) {});

      final result = await container
          .read(sendCodeControllerProvider.notifier)
          .sendCode('٠٧٩ ١٢٣ ٤٥٦٧');

      expect(result?.e164, '+962791234567');
      verify(() => auth.sendOtp(PhoneNumber.tryParse('0791234567')!)).called(1);
    });

    test('exposes backend failures', () async {
      when(() => auth.sendOtp(any())).thenThrow(const Failure(FailureKind.rateLimited));
      final sub = container.listen(sendCodeControllerProvider, (_, _) {});

      final result = await container
          .read(sendCodeControllerProvider.notifier)
          .sendCode('0791234567');

      expect(result, isNull);
      expect((sub.read().error! as Failure).kind, FailureKind.rateLimited);
    });
  });

  group('VerifyCodeController', () {
    final phone = PhoneNumber.tryParse('0791234567')!;

    test('requires six digits', () async {
      final sub = container.listen(verifyCodeControllerProvider, (_, _) {});
      final ok = await container.read(verifyCodeControllerProvider.notifier).verify(phone, '123');

      expect(ok, isFalse);
      expect((sub.read().error! as Failure).kind, FailureKind.invalidOtp);
      verifyNever(() => auth.verifyOtp(any(), any()));
    });

    test('verifies Arabic-digit codes', () async {
      when(() => auth.verifyOtp(any(), any())).thenAnswer((_) async {});
      container.listen(verifyCodeControllerProvider, (_, _) {});

      final ok = await container
          .read(verifyCodeControllerProvider.notifier)
          .verify(phone, '١٢٣٤٥٦');

      expect(ok, isTrue);
      verify(() => auth.verifyOtp(phone, '123456')).called(1);
    });
  });
}
