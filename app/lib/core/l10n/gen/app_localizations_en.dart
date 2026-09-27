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
  String get locationUseCurrent => 'Use my current location';

  @override
  String get locationLocating => 'Finding your neighborhood…';

  @override
  String locationDetected(String neighborhood) {
    return 'We found $neighborhood from your location. Check it\'s right, then continue.';
  }

  @override
  String get locationOrChooseManually => 'Or choose manually';

  @override
  String get locationServiceDisabled =>
      'Location is turned off. Turn it on, or choose your neighborhood below.';

  @override
  String get locationPermissionDenied =>
      'Location permission wasn\'t granted. You can choose your neighborhood below.';

  @override
  String get locationPermissionDeniedForever =>
      'Location access is blocked for Dor. Allow it in settings, or choose your neighborhood below.';

  @override
  String get locationUnavailable =>
      'We couldn\'t get your location. Try again, or choose your neighborhood below.';

  @override
  String get locationOutsideCoverage =>
      'Dor doesn\'t cover your current location yet. Choose your neighborhood below.';

  @override
  String get locationOpenSettings => 'Open settings';

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

  @override
  String pushWaterArrivedTitle(String neighborhood) {
    return 'Water arrived in $neighborhood';
  }

  @override
  String get pushWaterArrivedBody =>
      'Neighbors at your level confirmed water is flowing. Time to fill your tanks.';

  @override
  String pushReachedLowerTitle(String neighborhood) {
    return 'Water reached $neighborhood';
  }

  @override
  String get pushReachedLowerBody =>
      'It\'s flowing in the lower parts of the neighborhood. Homes on higher ground usually get it later.';

  @override
  String pushReminderTitle(String neighborhood) {
    return 'Water day tomorrow in $neighborhood';
  }

  @override
  String pushReminderBody(String time) {
    return 'Supply is scheduled to start at $time. Get your tanks ready.';
  }

  @override
  String pushScheduleStartTitle(String neighborhood) {
    return 'Your water day in $neighborhood starts now';
  }

  @override
  String pushScheduleStartBody(String time) {
    return 'Supply is scheduled from $time. We\'ll let you know when neighbors confirm water has arrived.';
  }

  @override
  String get elevationTitle => 'Where is your home in the neighborhood?';

  @override
  String get elevationSubtitle =>
      'Water reaches low-lying homes first and homes on hills last, so we match you with neighbors at your level.';

  @override
  String get elevationLow => 'Low ground';

  @override
  String get elevationMiddle => 'Middle';

  @override
  String get elevationHigh => 'On a hill';

  @override
  String get elevationNotSure => 'Not sure';

  @override
  String get elevationSuggested =>
      'Suggested from your location\'s altitude. Change it if it\'s not right.';

  @override
  String get settingsHome => 'My home';

  @override
  String get liveTitle => 'Water right now';

  @override
  String get liveFlowing => 'Water is flowing';

  @override
  String liveFlowingDetail(String time, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirmations',
      one: '1 confirmation',
    );
    return 'Since $time · $_temp0';
  }

  @override
  String get liveFlowingBelow => 'Water reached lower homes';

  @override
  String liveFlowingBelowDetail(String time) {
    return 'Flowing lower down since $time. Homes on higher ground usually get it later.';
  }

  @override
  String get liveNoWater => 'No water yet';

  @override
  String liveNoWaterDetail(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neighbors at your level reported no water',
      one: '1 neighbor at your level reported no water',
    );
    return '$_temp0';
  }

  @override
  String get liveUnknown => 'No confirmations yet';

  @override
  String get liveUnknownDetail => 'Let your neighbors know when water arrives.';

  @override
  String get liveYourLevel => 'Your home';

  @override
  String get bandFlowing => 'Flowing';

  @override
  String get bandNoWater => 'No water';

  @override
  String get bandUnknown => 'No reports';

  @override
  String get reportArrived => 'Water arrived';

  @override
  String get reportNoWater => 'No water';

  @override
  String get reportThanks => 'Thanks for letting your neighbors know!';

  @override
  String reportedArrivedAt(String time) {
    return 'You reported water arrived at $time.';
  }

  @override
  String reportedNoWaterAt(String time) {
    return 'You reported no water at $time.';
  }

  @override
  String reportNextAllowed(String time) {
    return 'You can report again at $time.';
  }

  @override
  String get notificationChannelName => 'Water alerts';

  @override
  String get notificationChannelDescription =>
      'When water arrives in your neighborhood and reminders before your water day.';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotifyArrival => 'Water arrival alerts';

  @override
  String get settingsNotifyArrivalSubtitle =>
      'When neighbors at your level confirm water is flowing.';

  @override
  String get settingsNotifyReminder => 'Water day reminder';

  @override
  String get settingsNotifyReminderSubtitle =>
      'The evening before your scheduled water day.';

  @override
  String get settingsNotifyStart => 'Water day starts';

  @override
  String get settingsNotifyStartSubtitle =>
      'At the scheduled start time on your water day.';

  @override
  String bandReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports',
      one: '1 report',
    );
    return '$_temp0';
  }
}
