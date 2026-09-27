// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'دور';

  @override
  String get authPhoneTitle => 'أدخل رقم هاتفك المحمول';

  @override
  String get authPhoneSubtitle => 'سنرسل لك رمز تحقق برسالة نصية.';

  @override
  String get authPhoneLabel => 'رقم الهاتف المحمول';

  @override
  String get authPhoneHint => '07X XXX XXXX';

  @override
  String get authSendCode => 'أرسل الرمز';

  @override
  String get authOtpTitle => 'أدخل الرمز';

  @override
  String authOtpSubtitle(String phone) {
    return 'أرسلنا رمزًا من 6 أرقام إلى $phone';
  }

  @override
  String get authOtpLabel => 'رمز التحقق';

  @override
  String get authVerify => 'تحقق';

  @override
  String get authResendCode => 'إعادة إرسال الرمز';

  @override
  String get authCodeResent => 'تم إرسال رمز جديد.';

  @override
  String get authChangeNumber => 'تغيير الرقم';

  @override
  String get errorInvalidPhone => 'أدخل رقم هاتف أردنيًا صحيحًا (077 أو 078 أو 079).';

  @override
  String get errorInvalidOtp => 'الرمز غير صحيح أو منتهي الصلاحية.';

  @override
  String get errorNetwork => 'لا يوجد اتصال. تحقق من الإنترنت وحاول مرة أخرى.';

  @override
  String get errorRateLimited => 'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.';

  @override
  String get errorForbidden => 'ليس لديك صلاحية للقيام بذلك.';

  @override
  String get errorSessionExpired => 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get errorUnknown => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get retry => 'حاول مرة أخرى';

  @override
  String get onboardingTitle => 'أين تسكن؟';

  @override
  String get onboardingSubtitle => 'سنعرض لك جدول دور المياه في حيّك.';

  @override
  String get governorateLabel => 'المحافظة';

  @override
  String get areaLabel => 'المنطقة';

  @override
  String get neighborhoodLabel => 'الحي';

  @override
  String get save => 'حفظ';

  @override
  String get continueButton => 'متابعة';

  @override
  String get noOptions => 'لا توجد خيارات بعد';

  @override
  String get locationUseCurrent => 'استخدم موقعي الحالي';

  @override
  String get locationLocating => 'جارٍ تحديد حيّك…';

  @override
  String locationDetected(String neighborhood) {
    return 'وجدنا أنك في $neighborhood حسب موقعك. تأكد من صحته ثم تابع.';
  }

  @override
  String get locationOrChooseManually => 'أو اختر يدويًا';

  @override
  String get locationServiceDisabled => 'خدمة الموقع متوقفة. شغّلها أو اختر حيّك من القائمة أدناه.';

  @override
  String get locationPermissionDenied =>
      'لم يتم منح إذن الموقع. يمكنك اختيار حيّك من القائمة أدناه.';

  @override
  String get locationPermissionDeniedForever =>
      'الوصول إلى الموقع محظور لتطبيق دور. اسمح به من الإعدادات أو اختر حيّك أدناه.';

  @override
  String get locationUnavailable => 'تعذّر تحديد موقعك. حاول مرة أخرى أو اختر حيّك أدناه.';

  @override
  String get locationOutsideCoverage => 'دور لا يغطي موقعك الحالي بعد. اختر حيّك من القائمة أدناه.';

  @override
  String get locationOpenSettings => 'فتح الإعدادات';

  @override
  String get scheduleTitle => 'جدول دور المياه';

  @override
  String get scheduleWeekTitle => 'الجدول الأسبوعي';

  @override
  String get scheduleNoWater => 'لا يوجد دور';

  @override
  String scheduleWindow(String time, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ساعة',
      many: '$hours ساعة',
      few: '$hours ساعات',
      two: 'ساعتان',
      one: 'ساعة واحدة',
    );
    return '$time · $_temp0';
  }

  @override
  String get scheduleNowTitle => 'اليوم دورك في المياه';

  @override
  String scheduleNowBody(String end) {
    return 'الضخ المجدول حتى $end';
  }

  @override
  String get scheduleNextTitle => 'الدور القادم';

  @override
  String scheduleNextIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'بعد $days يوم',
      many: 'بعد $days يومًا',
      few: 'بعد $days أيام',
      two: 'بعد يومين',
      one: 'غدًا',
      zero: 'اليوم',
    );
    return '$_temp0';
  }

  @override
  String scheduleNextAt(String day, String time) {
    return '$day، $time';
  }

  @override
  String get scheduleNone => 'لم يُنشر جدول دور المياه لحيّك بعد.';

  @override
  String get scheduleDisclaimer => 'المواعيد صادرة عن شركة المياه وقد يختلف موعد الضخ الفعلي.';

  @override
  String get today => 'اليوم';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsNeighborhood => 'حيّي';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get driverHomeTitle => 'وضع السائق';

  @override
  String get driverHomeBody => 'ستظهر أدوات السائق هنا بعد الموافقة على حسابك.';

  @override
  String pushWaterArrivedTitle(String neighborhood) {
    return 'وصلت المياه إلى $neighborhood';
  }

  @override
  String get pushWaterArrivedBody =>
      'أكّد جيرانك في نفس مستوى منزلك أن المياه تصل الآن. حان وقت ملء الخزانات.';

  @override
  String pushReachedLowerTitle(String neighborhood) {
    return 'وصلت المياه إلى $neighborhood';
  }

  @override
  String get pushReachedLowerBody =>
      'المياه تصل الآن إلى المناطق المنخفضة من الحي، وعادةً تصل إلى المنازل المرتفعة لاحقًا.';

  @override
  String pushReminderTitle(String neighborhood) {
    return 'غدًا دور المياه في $neighborhood';
  }

  @override
  String pushReminderBody(String time) {
    return 'يبدأ الضخ المجدول الساعة $time. جهّز خزاناتك.';
  }

  @override
  String get elevationTitle => 'أين يقع منزلك في الحي؟';

  @override
  String get elevationSubtitle =>
      'تصل المياه أولًا إلى المنازل المنخفضة وأخيرًا إلى المنازل المرتفعة، لذلك نربطك بجيرانك في نفس المستوى.';

  @override
  String get elevationLow => 'منطقة منخفضة';

  @override
  String get elevationMiddle => 'وسط';

  @override
  String get elevationHigh => 'على مرتفع';

  @override
  String get elevationNotSure => 'لست متأكدًا';

  @override
  String get elevationSuggested => 'اقترحناه حسب ارتفاع موقعك. غيّره إن لم يكن صحيحًا.';

  @override
  String get settingsHome => 'منزلي';

  @override
  String get liveTitle => 'المياه الآن';

  @override
  String get liveFlowing => 'المياه واصلة';

  @override
  String liveFlowingDetail(String time, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تأكيد',
      many: '$count تأكيدًا',
      few: '$count تأكيدات',
      two: 'تأكيدان',
      one: 'تأكيد واحد',
    );
    return 'منذ $time · $_temp0';
  }

  @override
  String get liveFlowingBelow => 'وصلت المياه إلى المنازل المنخفضة';

  @override
  String liveFlowingBelowDetail(String time) {
    return 'تصل إلى المناطق المنخفضة منذ $time. عادةً تصل إلى المنازل المرتفعة لاحقًا.';
  }

  @override
  String get liveNoWater => 'لم تصل المياه بعد';

  @override
  String liveNoWaterDetail(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أبلغ $count جار في مستواك عن عدم وصول المياه',
      many: 'أبلغ $count جارًا في مستواك عن عدم وصول المياه',
      few: 'أبلغ $count جيران في مستواك عن عدم وصول المياه',
      two: 'أبلغ جاران في مستواك عن عدم وصول المياه',
      one: 'أبلغ جار واحد في مستواك عن عدم وصول المياه',
    );
    return '$_temp0';
  }

  @override
  String get liveUnknown => 'لا توجد تأكيدات بعد';

  @override
  String get liveUnknownDetail => 'أخبر جيرانك عندما تصل المياه.';

  @override
  String get liveYourLevel => 'منزلك';

  @override
  String get bandFlowing => 'واصلة';

  @override
  String get bandNoWater => 'لا مياه';

  @override
  String get bandUnknown => 'لا بلاغات';

  @override
  String get reportArrived => 'وصلت المياه';

  @override
  String get reportNoWater => 'لا توجد مياه';

  @override
  String get reportThanks => 'شكرًا لإبلاغ جيرانك!';

  @override
  String reportedArrivedAt(String time) {
    return 'أبلغتَ عن وصول المياه الساعة $time.';
  }

  @override
  String reportedNoWaterAt(String time) {
    return 'أبلغتَ عن عدم وجود مياه الساعة $time.';
  }

  @override
  String reportNextAllowed(String time) {
    return 'يمكنك الإبلاغ مجددًا الساعة $time.';
  }

  @override
  String get notificationChannelName => 'تنبيهات المياه';

  @override
  String get notificationChannelDescription => 'عند وصول المياه إلى حيّك وتذكير قبل يوم الدور.';

  @override
  String get settingsNotifications => 'الإشعارات';

  @override
  String get settingsNotifyArrival => 'تنبيهات وصول المياه';

  @override
  String get settingsNotifyArrivalSubtitle => 'عندما يؤكد جيرانك في نفس مستوى منزلك وصول المياه.';

  @override
  String get settingsNotifyReminder => 'تذكير بيوم الدور';

  @override
  String get settingsNotifyReminderSubtitle => 'مساء اليوم الذي يسبق يوم الدور المجدول.';

  @override
  String bandReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بلاغ',
      many: '$count بلاغًا',
      few: '$count بلاغات',
      two: 'بلاغان',
      one: 'بلاغ واحد',
    );
    return '$_temp0';
  }
}
