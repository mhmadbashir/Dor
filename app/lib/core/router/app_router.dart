import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/phone_number.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/phone_screen.dart';
import '../../features/driver/presentation/driver_home_screen.dart';
import '../../features/locations/presentation/neighborhood_picker_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'auth_gate.dart';
import 'routes.dart';
import 'splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  AuthGate currentGate() =>
      AuthGate.from(ref.read(authUserIdProvider), ref.read(myProfileProvider));

  final gate = ValueNotifier<AuthGate>(currentGate());
  ref.listen(authUserIdProvider, (_, _) => gate.value = currentGate());
  ref.listen(myProfileProvider, (_, _) => gate.value = currentGate());

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: gate,
    redirect: (_, state) => resolveRedirect(gate.value, state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.phone, builder: (_, _) => const PhoneScreen()),
      GoRoute(
        path: Routes.otp,
        redirect: (_, state) =>
            PhoneNumber.tryParse(state.uri.queryParameters['phone'] ?? '') == null
            ? Routes.phone
            : null,
        builder: (_, state) =>
            OtpScreen(phone: PhoneNumber.tryParse(state.uri.queryParameters['phone']!)!),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const NeighborhoodPickerScreen(isOnboarding: true),
      ),
      GoRoute(path: Routes.home, builder: (_, _) => const ScheduleScreen()),
      GoRoute(
        path: Routes.settings,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'neighborhood',
            builder: (_, _) => const NeighborhoodPickerScreen(isOnboarding: false),
          ),
        ],
      ),
      GoRoute(path: Routes.driverHome, builder: (_, _) => const DriverHomeScreen()),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    gate.dispose();
  });
  return router;
});
