import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../crowd_reports/presentation/elevation_labels.dart';
import '../../locations/presentation/locations_providers.dart';
import '../../notifications/presentation/notification_prefs_controller.dart';
import '../../notifications/presentation/push_controller.dart';
import 'locale_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = ref.watch(localeControllerProvider);
    final profile = ref.watch(myProfileProvider).value;
    final neighborhoodId = profile?.neighborhoodId;
    final neighborhoodName = neighborhoodId == null
        ? null
        : ref
              .watch(neighborhoodDetailsProvider(neighborhoodId))
              .value
              ?.neighborhood
              .name
              .resolve(locale.languageCode);
    final homeSummary = neighborhoodName == null
        ? null
        : '$neighborhoodName · ${l10n.elevationLabel(profile?.elevationBand)}';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(l10n.settingsHome),
            subtitle: homeSummary == null ? null : Text(homeSummary),
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
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: Text(l10n.settingsNotifications, style: Theme.of(context).textTheme.titleSmall),
          ),
          SwitchListTile(
            key: const Key('notifyArrivalSwitch'),
            secondary: const Icon(Icons.water_drop_outlined),
            title: Text(l10n.settingsNotifyArrival),
            subtitle: Text(l10n.settingsNotifyArrivalSubtitle),
            value: profile?.notifyWaterArrival ?? true,
            onChanged: profile == null
                ? null
                : ref.read(notificationPrefsControllerProvider.notifier).setWaterArrival,
          ),
          SwitchListTile(
            key: const Key('notifyReminderSwitch'),
            secondary: const Icon(Icons.event_outlined),
            title: Text(l10n.settingsNotifyReminder),
            subtitle: Text(l10n.settingsNotifyReminderSubtitle),
            value: profile?.notifyScheduleReminder ?? true,
            onChanged: profile == null
                ? null
                : ref.read(notificationPrefsControllerProvider.notifier).setScheduleReminder,
          ),
          SwitchListTile(
            key: const Key('notifyStartSwitch'),
            secondary: const Icon(Icons.schedule_outlined),
            title: Text(l10n.settingsNotifyStart),
            subtitle: Text(l10n.settingsNotifyStartSubtitle),
            value: profile?.notifyScheduleStart ?? true,
            onChanged: profile == null
                ? null
                : ref.read(notificationPrefsControllerProvider.notifier).setScheduleStart,
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
          await ref.read(pushControllerProvider.notifier).signOut();
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
