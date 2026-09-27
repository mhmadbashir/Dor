import 'package:dor/features/auth/domain/phone_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneNumber.tryParse', () {
    const expected = '+962791234567';

    for (final input in [
      '0791234567',
      '791234567',
      '+962791234567',
      '00962791234567',
      '962791234567',
      '+962 79 123 4567',
      '079-123-4567',
      '(079) 123 4567',
      '٠٧٩١٢٣٤٥٦٧', // Arabic-Indic digits
      '۰۷۹۱۲۳۴۵۶۷', // Eastern Arabic-Indic digits
      '+9620791234567', // trunk zero kept after country code
    ]) {
      test('accepts "$input"', () {
        expect(PhoneNumber.tryParse(input)?.e164, expected);
      });
    }

    test('accepts all three mobile operators', () {
      expect(PhoneNumber.tryParse('0771234567')?.e164, '+962771234567');
      expect(PhoneNumber.tryParse('0781234567')?.e164, '+962781234567');
    });

    for (final input in [
      '',
      '079123456', // too short
      '07912345678', // too long
      '0761234567', // not a mobile prefix
      '064123456', // Amman landline
      '+966501234567', // Saudi number
      'abc',
    ]) {
      test('rejects "$input"', () {
        expect(PhoneNumber.tryParse(input), isNull);
      });
    }
  });

  test('display formats the local number', () {
    expect(PhoneNumber.tryParse('+962791234567')!.display, '079 123 4567');
  });

  test('normalizeOtp converts Arabic digits and strips separators', () {
    expect(normalizeOtp('١٢٣ ٤٥٦'), '123456');
    expect(normalizeOtp(' 12-34-56 '), '123456');
  });
}
