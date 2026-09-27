import 'dart:async';

import 'package:dor/core/l10n/digits.dart';

/// Applies app-wide startup configuration to every test.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  useWesternDigits();
  await testMain();
}
