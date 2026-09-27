import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../settings/presentation/language_menu_button.dart';
import '../../settings/presentation/settings_screen.dart';

/// Placeholder until driver mode is built in Phase 3.
class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.driverHomeTitle), actions: const [LanguageMenuButton()]),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          const Icon(Icons.local_shipping_outlined, size: 64),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.driverHomeBody, textAlign: TextAlign.center),
          ),
          const SignOutTile(),
        ],
      ),
    );
  }
}
