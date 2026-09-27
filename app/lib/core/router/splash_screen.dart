import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../widgets/async_value_view.dart';

/// Shown while the session and profile load; offers retry if loading fails.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    return Scaffold(
      body: profile.hasError && !profile.isLoading
          ? ErrorView(error: profile.error!, onRetry: () => ref.invalidate(myProfileProvider))
          : Center(
              child: Icon(Icons.water_drop, size: 72, color: Theme.of(context).colorScheme.primary),
            ),
    );
  }
}
