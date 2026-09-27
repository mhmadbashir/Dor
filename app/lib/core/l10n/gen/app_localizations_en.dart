// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dor';

  @override
  String get authPhoneTitle => 'Enter your mobile number';

  @override
  String get authPhoneSubtitle => 'We\'ll send you a verification code by SMS.';

  @override
  String get authPhoneLabel => 'Mobile number';

  @override
  String get authPhoneHint => '07X XXX XXXX';

  @override
  String get authSendCode => 'Send code';

  @override
  String get authOtpTitle => 'Enter the code';

  @override
  String authOtpSubtitle(String phone) {
    return 'We sent a 6-digit code to $phone';
  }

  @override
  String get authOtpLabel => 'Verification code';

  @override
  String get authVerify => 'Verify';

  @override
  String get authResendCode => 'Resend code';

  @override
  String get authCodeResent => 'A new code is on its way.';

  @override
  String get authChangeNumber => 'Change number';

  @override
  String get errorInvalidPhone =>
      'Enter a valid Jordanian mobile number (077, 078 or 079).';

  @override
  String get errorInvalidOtp => 'The code is incorrect or has expired.';

  @override
  String get errorNetwork =>
      'No connection. Check your internet and try again.';

  @override
  String get errorRateLimited =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errorForbidden => 'You don\'t have permission to do that.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get retry => 'Try again';

  @override
  String get onboardingTitle => 'Where do you live?';

  @override
  String get onboardingSubtitle =>
      'We\'ll show you your neighborhood\'s water schedule.';

  @override
  String get governorateLabel => 'Governorate';

  @override
  String get areaLabel => 'Area';

  @override
  String get neighborhoodLabel => 'Neighborhood';

  @override
  String get save => 'Save';

  @override
  String get continueButton => 'Continue';

  @override
  String get noOptions => 'Nothing to choose from yet';

  @override
  String get scheduleTitle => 'Water schedule';

  @override
  String get scheduleWeekTitle => 'Weekly schedule';

  @override
  String get scheduleNoWater => 'No water';

  @override
  String scheduleWindow(String time, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$time · $_temp0';
  }

  @override
  String get scheduleNowTitle => 'It\'s your water day';

  @override
  String scheduleNowBody(String end) {
    return 'Scheduled supply until $end';
  }

  @override
  String get scheduleNextTitle => 'Next water day';

  @override
  String scheduleNextIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $days days',
      one: 'Tomorrow',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String scheduleNextAt(String day, String time) {
    return '$day, $time';
  }

  @override
  String get scheduleNone =>
      'No water schedule has been published for your neighborhood yet.';

  @override
  String get scheduleDisclaimer =>
      'Times are published by the water utility and actual supply may vary.';

  @override
  String get today => 'Today';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsNeighborhood => 'My neighborhood';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get signOut => 'Sign out';

  @override
  String get driverHomeTitle => 'Driver mode';

  @override
  String get driverHomeBody =>
      'Driver tools will appear here once your account is approved.';
}
