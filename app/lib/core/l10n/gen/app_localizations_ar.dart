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
  String get errorInvalidPhone =>
      'أدخل رقم هاتف أردنيًا صحيحًا (077 أو 078 أو 079).';

  @override
  String get errorInvalidOtp => 'الرمز غير صحيح أو منتهي الصلاحية.';

  @override
  String get errorNetwork => 'لا يوجد اتصال. تحقق من الإنترنت وحاول مرة أخرى.';

  @override
  String get errorRateLimited =>
      'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.';

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
  String get locationServiceDisabled =>
      'خدمة الموقع متوقفة. شغّلها أو اختر حيّك من القائمة أدناه.';

  @override
  String get locationPermissionDenied =>
      'لم يتم منح إذن الموقع. يمكنك اختيار حيّك من القائمة أدناه.';

  @override
  String get locationPermissionDeniedForever =>
      'الوصول إلى الموقع محظور لتطبيق دور. اسمح به من الإعدادات أو اختر حيّك أدناه.';

  @override
  String get locationUnavailable =>
      'تعذّر تحديد موقعك. حاول مرة أخرى أو اختر حيّك أدناه.';

  @override
  String get locationOutsideCoverage =>
      'دور لا يغطي موقعك الحالي بعد. اختر حيّك من القائمة أدناه.';

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
  String get scheduleDisclaimer =>
      'المواعيد صادرة عن شركة المياه وقد يختلف موعد الضخ الفعلي.';

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
}
