/// A name stored in both Arabic and English.
class LocalizedName {
  const LocalizedName({required this.ar, required this.en});

  final String ar;
  final String en;

  /// Picks the name for [languageCode], falling back to Arabic.
  String resolve(String languageCode) => languageCode == 'en' ? en : ar;

  @override
  bool operator ==(Object other) => other is LocalizedName && other.ar == ar && other.en == en;

  @override
  int get hashCode => Object.hash(ar, en);
}
