import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import 'locale_controller.dart';

class LanguageMenuButton extends ConsumerWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      key: const Key('languageMenu'),
      tooltip: l10n.settingsLanguage,
      icon: const Icon(Icons.language),
      onSelected: (code) => ref.read(localeControllerProvider.notifier).setLanguage(code),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'ar', child: Text(l10n.languageArabic)),
        PopupMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
      ],
    );
  }
}
