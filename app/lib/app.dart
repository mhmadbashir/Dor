import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/l10n.dart';
import 'core/router/app_router.dart';
import 'core/router/routes.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/presentation/push_controller.dart';
import 'features/settings/presentation/locale_controller.dart';

class DorApp extends ConsumerWidget {
  const DorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps this device registered for push while someone is signed in.
    ref.watch(pushControllerProvider);
    // Tapping a water alert opens the live status on the home screen.
    ref.listen(pushOpenedProvider, (_, next) {
      if (next.hasValue) ref.read(routerProvider).go(Routes.home);
    });

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      locale: ref.watch(localeControllerProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
    );
  }
}
