import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../locations/presentation/locations_providers.dart';
import 'locale_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = ref.watch(localeControllerProvider);
    final neighborhoodId = ref.watch(myProfileProvider).value?.neighborhoodId;
    final neighborhoodName = neighborhoodId == null
        ? null
        : ref
              .watch(neighborhoodDetailsProvider(neighborhoodId))
              .value
              ?.neighborhood
              .name
              .resolve(locale.languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(l10n.settingsNeighborhood),
            subtitle: neighborhoodName == null ? null : Text(neighborhoodName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.settingsNeighborhood),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            trailing: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'ar', label: Text(l10n.languageArabic)),
                ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
              ],
              selected: {locale.languageCode},
              onSelectionChanged: (s) =>
                  ref.read(localeControllerProvider.notifier).setLanguage(s.single),
            ),
          ),
          const Divider(),
          const SignOutTile(),
        ],
      ),
    );
  }
}

class SignOutTile extends ConsumerWidget {
  const SignOutTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final color = Theme.of(context).colorScheme.error;
    return ListTile(
      key: const Key('signOutTile'),
      leading: Icon(Icons.logout, color: color),
      title: Text(l10n.signOut, style: TextStyle(color: color)),
      // The router redirects to sign-in once the session ends.
      onTap: () async {
        try {
          await ref.read(authRepositoryProvider).signOut();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.errorMessage(e))));
          }
        }
      },
    );
  }
}
