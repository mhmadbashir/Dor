import 'package:dor/features/auth/presentation/auth_providers.dart';
import 'package:dor/features/auth/presentation/phone_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

void main() {
  setUpAll(registerFallbacks);

  testWidgets('renders right-to-left in Arabic with the phone field kept LTR', (tester) async {
    await tester.pumpScreen(
      const PhoneScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(signedInAuth(null))],
    );

    expect(find.text('أدخل رقم هاتفك المحمول'), findsOneWidget);
    final scaffoldContext = tester.element(find.byType(Scaffold));
    expect(Directionality.of(scaffoldContext), TextDirection.rtl);
    final fieldContext = tester.element(find.byKey(const Key('phoneField')));
    expect(Directionality.of(fieldContext), TextDirection.ltr);
  });

  testWidgets('shows a localized error for an invalid number', (tester) async {
    final auth = signedInAuth(null);
    await tester.pumpScreen(
      const PhoneScreen(),
      locale: 'en',
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );

    await tester.enterText(find.byKey(const Key('phoneField')), '0612');
    await tester.tap(find.byKey(const Key('sendCodeButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('valid Jordanian mobile number'), findsOneWidget);
    verifyNever(() => auth.sendOtp(any()));
  });
}
