import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/supabase_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../settings/presentation/locale_controller.dart';
import '../data/firebase_push_messaging.dart';
import '../data/supabase_push_token_repository.dart';
import '../domain/push_messaging.dart';

final pushMessagingProvider = Provider<PushMessaging>((ref) => FirebasePushMessaging());

final pushTokenRepositoryProvider = Provider<PushTokenRepository>(
  (ref) => SupabasePushTokenRepository(ref.watch(supabaseClientProvider)),
);

enum PushStatus { unavailable, denied, enabled }

/// Keeps this device's push token registered for the signed-in user.
///
/// Watched from the app root. On sign-in it asks for permission and
/// registers the token; on token refresh it re-registers. [signOut] removes
/// the token before the session ends (the RPC needs the session).
class PushController extends Notifier<PushStatus> {
  String? _registeredToken;
  StreamSubscription<String>? _refreshSub;

  @override
  PushStatus build() {
    ref.onDispose(() => _refreshSub?.cancel());
    ref.listen(authUserIdProvider, (previous, next) {
      final userId = next.value;
      if (userId != null && userId != previous?.value) unawaited(_enable());
    }, fireImmediately: true);
    return PushStatus.unavailable;
  }

  Future<void> _enable() async {
    final push = ref.read(pushMessagingProvider);
    final l10n = lookupAppLocalizations(ref.read(localeControllerProvider));
    try {
      final available = await push.initialize(
        NotificationChannelText(
          name: l10n.notificationChannelName,
          description: l10n.notificationChannelDescription,
        ),
      );
      if (!available || !ref.mounted) return;
      if (!await push.requestPermission()) {
        if (ref.mounted) state = PushStatus.denied;
        return;
      }
      final token = await push.token();
      if (token != null) await _register(token);
      await _refreshSub?.cancel();
      _refreshSub = push.onTokenRefresh.listen((t) => unawaited(_register(t)));
      if (ref.mounted) state = PushStatus.enabled;
    } catch (e) {
      debugPrint('Push setup failed: $e');
    }
  }

  Future<void> _register(String token) async {
    if (ref.read(authRepositoryProvider).currentUserId == null) return;
    await ref
        .read(pushTokenRepositoryProvider)
        .register(token, ref.read(pushMessagingProvider).platform);
    _registeredToken = token;
  }

  /// Signs out, first detaching this device so the old account stops
  /// receiving its alerts.
  Future<void> signOut() async {
    final token = _registeredToken;
    if (token != null) {
      try {
        await ref.read(pushTokenRepositoryProvider).unregister(token);
        await ref.read(pushMessagingProvider).deleteToken();
      } catch (e) {
        debugPrint('Could not unregister push token: $e');
      }
      _registeredToken = null;
    }
    await _refreshSub?.cancel();
    _refreshSub = null;
    state = PushStatus.unavailable;
    await ref.read(authRepositoryProvider).signOut();
  }
}

/// Notifications the user tapped.
final pushOpenedProvider = StreamProvider<PushNotification>(
  (ref) => ref.watch(pushMessagingProvider).onOpened,
);

final pushControllerProvider = NotifierProvider<PushController, PushStatus>(PushController.new);
