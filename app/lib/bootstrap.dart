import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';

/// Initializes services, then runs [app] inside a [ProviderScope].
Future<void> bootstrap(Widget app) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }

  await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabasePublishableKey);

  runApp(
    ProviderScope(
      // Screens offer explicit retry buttons; don't retry failures silently.
      retry: (_, _) => null,
      child: app,
    ),
  );
}

/// Developer-facing only: shown when --dart-define values are missing.
class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Missing SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY.\n'
            'Run with --dart-define-from-file=env/local.json',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
