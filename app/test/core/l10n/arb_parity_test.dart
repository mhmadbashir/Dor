import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String locale) =>
    jsonDecode(File('lib/core/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  test('Arabic and English ARB files define the same messages', () {
    final ar = _messageKeys(_load('ar'));
    final en = _messageKeys(_load('en'));
    expect(ar.difference(en), isEmpty, reason: 'only in ar');
    expect(en.difference(ar), isEmpty, reason: 'only in en');
  });

  test('Arabic messages use every placeholder declared in English', () {
    final ar = _load('ar');
    final en = _load('en');
    for (final key in _messageKeys(en)) {
      final meta = en['@$key'] as Map<String, dynamic>?;
      final placeholders =
          (meta?['placeholders'] as Map<String, dynamic>?)?.keys ?? const <String>[];
      for (final name in placeholders) {
        expect(ar[key] as String, contains('{$name'), reason: '$key is missing {$name}');
      }
    }
  });
}
