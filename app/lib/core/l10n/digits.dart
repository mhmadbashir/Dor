import 'package:intl/intl.dart';

/// Dor shows Western digits (0-9) in every language, including Arabic dates
/// and times ("8:00 ص" rather than "٨:٠٠ ص"). Call once at startup.
void useWesternDigits() {
  for (final locale in const ['ar', 'ar_JO']) {
    DateFormat.useNativeDigitsByDefaultFor(locale, false);
  }
}
