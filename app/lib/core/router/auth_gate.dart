import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/profile.dart';
import '../../features/auth/domain/user_role.dart';
import 'routes.dart';

/// What routing needs to know about the session.
sealed class AuthGate {
  const AuthGate();

  static AuthGate from(AsyncValue<String?> userId, AsyncValue<Profile?> profile) {
    if (!userId.hasValue) return userId.hasError ? const GateError() : const GateLoading();
    if (userId.value == null) return const GateSignedOut();
    // A stale profile of the same user is fine while it refreshes.
    final p = profile.value;
    if (p != null && p.id == userId.value) return GateSignedIn(p);
    if (profile.hasError && !profile.isLoading) return const GateError();
    return const GateLoading();
  }
}

class GateLoading extends AuthGate {
  const GateLoading();
  @override
  bool operator ==(Object other) => other is GateLoading;
  @override
  int get hashCode => 0;
}

class GateError extends AuthGate {
  const GateError();
  @override
  bool operator ==(Object other) => other is GateError;
  @override
  int get hashCode => 1;
}

class GateSignedOut extends AuthGate {
  const GateSignedOut();
  @override
  bool operator ==(Object other) => other is GateSignedOut;
  @override
  int get hashCode => 2;
}

class GateSignedIn extends AuthGate {
  const GateSignedIn(this.profile);
  final Profile profile;
  @override
  bool operator ==(Object other) => other is GateSignedIn && other.profile == profile;
  @override
  int get hashCode => profile.hashCode;
}

/// Pure routing policy: where should [location] go, given [gate]?
/// Returns null to stay.
String? resolveRedirect(AuthGate gate, String location) {
  bool at(String route) => location == route || location.startsWith('$route/');
  final inAuth = at('/auth');

  switch (gate) {
    case GateLoading() || GateError():
      return location == Routes.splash ? null : Routes.splash;
    case GateSignedOut():
      return inAuth ? null : Routes.phone;
    case GateSignedIn(:final profile):
      if (profile.role == UserRole.driver) {
        return at(Routes.driverHome) ? null : Routes.driverHome;
      }
      // Households (and admins, who manage data from the web dashboard).
      if (!profile.hasNeighborhood) {
        return location == Routes.onboarding ? null : Routes.onboarding;
      }
      if (location == Routes.splash ||
          location == Routes.onboarding ||
          inAuth ||
          at(Routes.driverHome)) {
        return Routes.home;
      }
      return null;
  }
}
