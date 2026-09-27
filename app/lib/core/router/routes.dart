import '../../features/auth/domain/phone_number.dart';

abstract final class Routes {
  static const splash = '/';
  static const phone = '/auth/phone';
  static const otp = '/auth/otp';
  static const onboarding = '/onboarding/neighborhood';
  static const home = '/home';
  static const settings = '/settings';
  static const settingsNeighborhood = '/settings/neighborhood';
  static const driverHome = '/driver';

  static String otpFor(PhoneNumber phone) =>
      Uri(path: otp, queryParameters: {'phone': phone.e164}).toString();
}
