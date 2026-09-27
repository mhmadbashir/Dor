import 'package:dor/core/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpApp on WidgetTester {
  /// Pumps [screen] inside a localized MaterialApp.
  Future<void> pumpScreen(
    Widget screen, {
    String locale = 'ar',
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(ProviderScope(
      overrides: overrides,
      retry: (_, _) => null,
      child: MaterialApp(
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: screen,
      ),
    ));
    await pumpAndSettle();
  }
}
