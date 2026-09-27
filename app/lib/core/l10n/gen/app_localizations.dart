import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Dor'**
  String get appTitle;

  /// No description provided for @authPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get authPhoneTitle;

  /// No description provided for @authPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a verification code by SMS.'**
  String get authPhoneSubtitle;

  /// No description provided for @authPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'07X XXX XXXX'**
  String get authPhoneHint;

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendCode;

  /// No description provided for @authOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get authOtpTitle;

  /// No description provided for @authOtpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {phone}'**
  String authOtpSubtitle(String phone);

  /// No description provided for @authOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authOtpLabel;

  /// No description provided for @authVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authVerify;

  /// No description provided for @authResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResendCode;

  /// No description provided for @authCodeResent.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way.'**
  String get authCodeResent;

  /// No description provided for @authChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get authChangeNumber;

  /// No description provided for @errorInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Jordanian mobile number (077, 078 or 079).'**
  String get errorInvalidPhone;

  /// No description provided for @errorInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'The code is incorrect or has expired.'**
  String get errorInvalidOtp;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get errorNetwork;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errorRateLimited;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get errorForbidden;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you live?'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll show you your neighborhood\'s water schedule.'**
  String get onboardingSubtitle;

  /// No description provided for @governorateLabel.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get governorateLabel;

  /// No description provided for @areaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get areaLabel;

  /// No description provided for @neighborhoodLabel.
  ///
  /// In en, this message translates to:
  /// **'Neighborhood'**
  String get neighborhoodLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @noOptions.
  ///
  /// In en, this message translates to:
  /// **'Nothing to choose from yet'**
  String get noOptions;

  /// No description provided for @locationUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get locationUseCurrent;

  /// No description provided for @locationLocating.
  ///
  /// In en, this message translates to:
  /// **'Finding your neighborhood…'**
  String get locationLocating;

  /// No description provided for @locationDetected.
  ///
  /// In en, this message translates to:
  /// **'We found {neighborhood} from your location. Check it\'s right, then continue.'**
  String locationDetected(String neighborhood);

  /// No description provided for @locationOrChooseManually.
  ///
  /// In en, this message translates to:
  /// **'Or choose manually'**
  String get locationOrChooseManually;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off. Turn it on, or choose your neighborhood below.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission wasn\'t granted. You can choose your neighborhood below.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked for Dor. Allow it in settings, or choose your neighborhood below.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t get your location. Try again, or choose your neighborhood below.'**
  String get locationUnavailable;

  /// No description provided for @locationOutsideCoverage.
  ///
  /// In en, this message translates to:
  /// **'Dor doesn\'t cover your current location yet. Choose your neighborhood below.'**
  String get locationOutsideCoverage;

  /// No description provided for @locationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get locationOpenSettings;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Water schedule'**
  String get scheduleTitle;

  /// No description provided for @scheduleWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly schedule'**
  String get scheduleWeekTitle;

  /// No description provided for @scheduleNoWater.
  ///
  /// In en, this message translates to:
  /// **'No water'**
  String get scheduleNoWater;

  /// No description provided for @scheduleWindow.
  ///
  /// In en, this message translates to:
  /// **'{time} · {hours, plural, =1{1 hour} other{{hours} hours}}'**
  String scheduleWindow(String time, int hours);

  /// No description provided for @scheduleNowTitle.
  ///
  /// In en, this message translates to:
  /// **'It\'s your water day'**
  String get scheduleNowTitle;

  /// No description provided for @scheduleNowBody.
  ///
  /// In en, this message translates to:
  /// **'Scheduled supply until {end}'**
  String scheduleNowBody(String end);

  /// No description provided for @scheduleNextTitle.
  ///
  /// In en, this message translates to:
  /// **'Next water day'**
  String get scheduleNextTitle;

  /// No description provided for @scheduleNextIn.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Today} =1{Tomorrow} other{In {days} days}}'**
  String scheduleNextIn(int days);

  /// No description provided for @scheduleNextAt.
  ///
  /// In en, this message translates to:
  /// **'{day}, {time}'**
  String scheduleNextAt(String day, String time);

  /// No description provided for @scheduleNone.
  ///
  /// In en, this message translates to:
  /// **'No water schedule has been published for your neighborhood yet.'**
  String get scheduleNone;

  /// No description provided for @scheduleDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Times are published by the water utility and actual supply may vary.'**
  String get scheduleDisclaimer;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsNeighborhood.
  ///
  /// In en, this message translates to:
  /// **'My neighborhood'**
  String get settingsNeighborhood;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @driverHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver mode'**
  String get driverHomeTitle;

  /// No description provided for @driverHomeBody.
  ///
  /// In en, this message translates to:
  /// **'Driver tools will appear here once your account is approved.'**
  String get driverHomeBody;

  /// No description provided for @pushWaterArrivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Water arrived in {neighborhood}'**
  String pushWaterArrivedTitle(String neighborhood);

  /// No description provided for @pushWaterArrivedBody.
  ///
  /// In en, this message translates to:
  /// **'Neighbors at your level confirmed water is flowing. Time to fill your tanks.'**
  String get pushWaterArrivedBody;

  /// No description provided for @pushReachedLowerTitle.
  ///
  /// In en, this message translates to:
  /// **'Water reached {neighborhood}'**
  String pushReachedLowerTitle(String neighborhood);

  /// No description provided for @pushReachedLowerBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s flowing in the lower parts of the neighborhood. Homes on higher ground usually get it later.'**
  String get pushReachedLowerBody;

  /// No description provided for @pushReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Water day tomorrow in {neighborhood}'**
  String pushReminderTitle(String neighborhood);

  /// No description provided for @pushReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Supply is scheduled to start at {time}. Get your tanks ready.'**
  String pushReminderBody(String time);

  /// No description provided for @elevationTitle.
  ///
  /// In en, this message translates to:
  /// **'Where is your home in the neighborhood?'**
  String get elevationTitle;

  /// No description provided for @elevationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Water reaches low-lying homes first and homes on hills last, so we match you with neighbors at your level.'**
  String get elevationSubtitle;

  /// No description provided for @elevationLow.
  ///
  /// In en, this message translates to:
  /// **'Low ground'**
  String get elevationLow;

  /// No description provided for @elevationMiddle.
  ///
  /// In en, this message translates to:
  /// **'Middle'**
  String get elevationMiddle;

  /// No description provided for @elevationHigh.
  ///
  /// In en, this message translates to:
  /// **'On a hill'**
  String get elevationHigh;

  /// No description provided for @elevationNotSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get elevationNotSure;

  /// No description provided for @elevationSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested from your location\'s altitude. Change it if it\'s not right.'**
  String get elevationSuggested;

  /// No description provided for @settingsHome.
  ///
  /// In en, this message translates to:
  /// **'My home'**
  String get settingsHome;

  /// No description provided for @liveTitle.
  ///
  /// In en, this message translates to:
  /// **'Water right now'**
  String get liveTitle;

  /// No description provided for @liveFlowing.
  ///
  /// In en, this message translates to:
  /// **'Water is flowing'**
  String get liveFlowing;

  /// No description provided for @liveFlowingDetail.
  ///
  /// In en, this message translates to:
  /// **'Since {time} · {count, plural, =1{1 confirmation} other{{count} confirmations}}'**
  String liveFlowingDetail(String time, int count);

  /// No description provided for @liveFlowingBelow.
  ///
  /// In en, this message translates to:
  /// **'Water reached lower homes'**
  String get liveFlowingBelow;

  /// No description provided for @liveFlowingBelowDetail.
  ///
  /// In en, this message translates to:
  /// **'Flowing lower down since {time}. Homes on higher ground usually get it later.'**
  String liveFlowingBelowDetail(String time);

  /// No description provided for @liveNoWater.
  ///
  /// In en, this message translates to:
  /// **'No water yet'**
  String get liveNoWater;

  /// No description provided for @liveNoWaterDetail.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 neighbor at your level reported no water} other{{count} neighbors at your level reported no water}}'**
  String liveNoWaterDetail(int count);

  /// No description provided for @liveUnknown.
  ///
  /// In en, this message translates to:
  /// **'No confirmations yet'**
  String get liveUnknown;

  /// No description provided for @liveUnknownDetail.
  ///
  /// In en, this message translates to:
  /// **'Let your neighbors know when water arrives.'**
  String get liveUnknownDetail;

  /// No description provided for @liveYourLevel.
  ///
  /// In en, this message translates to:
  /// **'Your home'**
  String get liveYourLevel;

  /// No description provided for @bandFlowing.
  ///
  /// In en, this message translates to:
  /// **'Flowing'**
  String get bandFlowing;

  /// No description provided for @bandNoWater.
  ///
  /// In en, this message translates to:
  /// **'No water'**
  String get bandNoWater;

  /// No description provided for @bandUnknown.
  ///
  /// In en, this message translates to:
  /// **'No reports'**
  String get bandUnknown;

  /// No description provided for @reportArrived.
  ///
  /// In en, this message translates to:
  /// **'Water arrived'**
  String get reportArrived;

  /// No description provided for @reportNoWater.
  ///
  /// In en, this message translates to:
  /// **'No water'**
  String get reportNoWater;

  /// No description provided for @reportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for letting your neighbors know!'**
  String get reportThanks;

  /// No description provided for @reportedArrivedAt.
  ///
  /// In en, this message translates to:
  /// **'You reported water arrived at {time}.'**
  String reportedArrivedAt(String time);

  /// No description provided for @reportedNoWaterAt.
  ///
  /// In en, this message translates to:
  /// **'You reported no water at {time}.'**
  String reportedNoWaterAt(String time);

  /// No description provided for @reportNextAllowed.
  ///
  /// In en, this message translates to:
  /// **'You can report again at {time}.'**
  String reportNextAllowed(String time);

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Water alerts'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'When water arrives in your neighborhood and reminders before your water day.'**
  String get notificationChannelDescription;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotifyArrival.
  ///
  /// In en, this message translates to:
  /// **'Water arrival alerts'**
  String get settingsNotifyArrival;

  /// No description provided for @settingsNotifyArrivalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When neighbors at your level confirm water is flowing.'**
  String get settingsNotifyArrivalSubtitle;

  /// No description provided for @settingsNotifyReminder.
  ///
  /// In en, this message translates to:
  /// **'Water day reminder'**
  String get settingsNotifyReminder;

  /// No description provided for @settingsNotifyReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The evening before your scheduled water day.'**
  String get settingsNotifyReminderSubtitle;

  /// No description provided for @bandReports.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 report} other{{count} reports}}'**
  String bandReports(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
