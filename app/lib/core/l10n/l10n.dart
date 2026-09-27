import 'package:flutter/widgets.dart';

import '../errors/failure.dart';
import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension FailureMessage on AppLocalizations {
  /// Localized, user-facing message for any error surfaced to the UI.
  String errorMessage(Object error) {
    final kind = error is Failure ? error.kind : FailureKind.unknown;
    return switch (kind) {
      FailureKind.invalidPhone => errorInvalidPhone,
      FailureKind.invalidOtp => errorInvalidOtp,
      FailureKind.network => errorNetwork,
      FailureKind.rateLimited => errorRateLimited,
      FailureKind.forbidden => errorForbidden,
      FailureKind.sessionExpired => errorSessionExpired,
      FailureKind.unknown => errorUnknown,
    };
  }
}
