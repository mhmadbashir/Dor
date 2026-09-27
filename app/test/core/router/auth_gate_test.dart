import 'package:dor/core/router/auth_gate.dart';
import 'package:dor/core/router/routes.dart';
import 'package:dor/features/auth/domain/profile.dart';
import 'package:dor/features/auth/domain/user_role.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const household = Profile(id: 'u', role: UserRole.household, neighborhoodId: 'n');
const newHousehold = Profile(id: 'u', role: UserRole.household);
const driver = Profile(id: 'u', role: UserRole.driver);
const admin = Profile(id: 'u', role: UserRole.admin, neighborhoodId: 'n');

void main() {
  group('resolveRedirect', () {
    test('loading goes to splash', () {
      expect(resolveRedirect(const GateLoading(), Routes.home), Routes.splash);
      expect(resolveRedirect(const GateLoading(), Routes.splash), isNull);
    });

    test('signed out may only visit auth screens', () {
      expect(resolveRedirect(const GateSignedOut(), Routes.home), Routes.phone);
      expect(resolveRedirect(const GateSignedOut(), Routes.splash), Routes.phone);
      expect(resolveRedirect(const GateSignedOut(), Routes.phone), isNull);
      expect(resolveRedirect(const GateSignedOut(), Routes.otp), isNull);
    });

    test('household without a neighborhood must onboard', () {
      const gate = GateSignedIn(newHousehold);
      expect(resolveRedirect(gate, Routes.home), Routes.onboarding);
      expect(resolveRedirect(gate, Routes.settings), Routes.onboarding);
      expect(resolveRedirect(gate, Routes.onboarding), isNull);
    });

    test('onboarded household lands on home and can use settings', () {
      const gate = GateSignedIn(household);
      expect(resolveRedirect(gate, Routes.splash), Routes.home);
      expect(resolveRedirect(gate, Routes.otp), Routes.home);
      expect(resolveRedirect(gate, Routes.onboarding), Routes.home);
      expect(resolveRedirect(gate, Routes.driverHome), Routes.home);
      expect(resolveRedirect(gate, Routes.home), isNull);
      expect(resolveRedirect(gate, Routes.settingsNeighborhood), isNull);
    });

    test('drivers are kept in driver mode', () {
      const gate = GateSignedIn(driver);
      expect(resolveRedirect(gate, Routes.home), Routes.driverHome);
      expect(resolveRedirect(gate, Routes.onboarding), Routes.driverHome);
      expect(resolveRedirect(gate, Routes.driverHome), isNull);
    });

    test('admins use the household experience on mobile', () {
      expect(resolveRedirect(const GateSignedIn(admin), Routes.splash), Routes.home);
    });
  });

  group('AuthGate.from', () {
    test('maps session and profile states', () {
      expect(AuthGate.from(const AsyncLoading(), const AsyncLoading()), const GateLoading());
      expect(AuthGate.from(const AsyncData(null), const AsyncData(null)), const GateSignedOut());
      expect(AuthGate.from(const AsyncData('u'), const AsyncLoading()), const GateLoading());
      expect(AuthGate.from(const AsyncData('u'), const AsyncData(household)), const GateSignedIn(household));
      expect(
        AuthGate.from(const AsyncData('u'), AsyncError(Exception(), StackTrace.empty)),
        const GateError(),
      );
    });

    test("ignores a previous user's profile", () {
      expect(AuthGate.from(const AsyncData('other'), const AsyncData(household)), const GateLoading());
    });
  });
}
