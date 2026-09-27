import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/push_strings.dart';

void main() {
  test('Edge Function push strings are in sync with the ARB files', () {
    final generated = File(outputPath).readAsStringSync();
    expect(
      generated,
      renderPushStrings(),
      reason: 'Run `dart run tool/push_strings.dart` in app/ after editing push* ARB strings.',
    );
  });
}
