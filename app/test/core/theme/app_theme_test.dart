import 'package:dor/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every text style, including button labels, uses the bundled Cairo font', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      expect(theme.textTheme.bodyMedium!.fontFamily, AppTheme.fontFamily);
      expect(theme.textTheme.labelLarge!.fontFamily, AppTheme.fontFamily);
      final buttonText = theme.filledButtonTheme.style!.textStyle!.resolve(<WidgetState>{});
      expect(buttonText!.fontFamily, AppTheme.fontFamily);
    }
  });
}
