import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../domain/phone_number.dart';
import 'auth_providers.dart';

/// Step 1: validate the phone number and request an SMS code.
class SendCodeController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Returns the parsed number when the code was sent, otherwise null
  /// (with the error exposed through [state]).
  Future<PhoneNumber?> sendCode(String input) async {
    final phone = PhoneNumber.tryParse(input);
    if (phone == null) {
      state = AsyncError(const Failure(FailureKind.invalidPhone), StackTrace.current);
      return null;
    }
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => ref.read(authRepositoryProvider).sendOtp(phone));
    if (!ref.mounted) return null;
    state = result;
    return result.hasError ? null : phone;
  }
}

final sendCodeControllerProvider =
    NotifierProvider.autoDispose<SendCodeController, AsyncValue<void>>(SendCodeController.new);

/// Step 2: verify the SMS code (and resend it on request).
class VerifyCodeController extends Notifier<AsyncValue<void>> {
  static const codeLength = 6;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> verify(PhoneNumber phone, String input) async {
    final code = normalizeOtp(input);
    if (code.length != codeLength) {
      state = AsyncError(const Failure(FailureKind.invalidOtp), StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).verifyOtp(phone, code),
    );
    if (!ref.mounted) return false;
    state = result;
    return !result.hasError;
  }

  Future<bool> resend(PhoneNumber phone) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => ref.read(authRepositoryProvider).sendOtp(phone));
    if (!ref.mounted) return false;
    state = result;
    return !result.hasError;
  }
}

final verifyCodeControllerProvider =
    NotifierProvider.autoDispose<VerifyCodeController, AsyncValue<void>>(VerifyCodeController.new);
