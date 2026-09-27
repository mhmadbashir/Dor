import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';

/// App language. Arabic by default; follows the signed-in profile, and a
/// choice made before sign-in is saved to the profile once it loads.
class LocaleController extends Notifier<Locale> {
  static const supported = ['ar', 'en'];

  String? _chosenWhileSignedOut;

  @override
  Locale build() {
    ref.listen(myProfileProvider, (_, next) {
      final profile = next.value;
      if (profile == null) return;
      final pending = _chosenWhileSignedOut;
      if (pending != null) {
        _chosenWhileSignedOut = null;
        if (pending != profile.locale) _persist(profile.id, pending);
      } else if (profile.locale != state.languageCode) {
        state = Locale(profile.locale);
      }
    });
    return const Locale('ar');
  }

  Future<void> setLanguage(String languageCode) async {
    if (!supported.contains(languageCode) || languageCode == state.languageCode) return;
    state = Locale(languageCode);
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) {
      _chosenWhileSignedOut = languageCode;
    } else {
      await _persist(userId, languageCode);
    }
  }

  Future<void> _persist(String userId, String languageCode) async {
    try {
      await ref.read(profileRepositoryProvider).updateLocale(userId, languageCode);
    } catch (_) {
      // Not critical: the UI already switched; it is re-synced next save.
    }
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);
