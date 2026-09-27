/// A validated Jordanian mobile number in E.164 form (e.g. `+962791234567`).
///
/// Accepts the formats people actually type: `0791234567`, `791234567`,
/// `+962 79 123 4567`, `00962791234567`, with spaces or dashes, and in
/// Arabic-Indic or Eastern Arabic-Indic digits.
class PhoneNumber {
  const PhoneNumber._(this.e164);

  final String e164;

  /// Mobile operators use the 77, 78 and 79 prefixes.
  static final _localMobile = RegExp(r'^7[789]\d{7}$');

  static PhoneNumber? tryParse(String input) {
    var digits = _normalizeDigits(input).replaceAll(RegExp(r'[\s\-().]'), '');
    if (digits.startsWith('+')) {
      digits = digits.substring(1);
    } else if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('962')) {
      digits = digits.substring(3);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (!_localMobile.hasMatch(digits)) return null;
    return PhoneNumber._('+962$digits');
  }

  /// Local display form, e.g. `079 123 4567`.
  String get display {
    final local = '0${e164.substring(4)}';
    return '${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
  }

  static String _normalizeDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + rune - 0x0660); // Arabic-Indic ٠-٩
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + rune - 0x06F0); // Eastern Arabic-Indic ۰-۹
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) => other is PhoneNumber && other.e164 == e164;

  @override
  int get hashCode => e164.hashCode;

  @override
  String toString() => e164;
}

/// Normalizes a typed OTP (Arabic digits, stray spaces) to ASCII digits.
String normalizeOtp(String input) =>
    PhoneNumber._normalizeDigits(input).replaceAll(RegExp(r'\D'), '');
