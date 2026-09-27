/// Where a home sits within its neighborhood. Water reaches low-lying homes
/// first and homes on hills last, so status and alerts are per band.
enum ElevationBand {
  low,
  middle,
  high;

  static ElevationBand? tryParse(String? name) {
    for (final b in values) {
      if (b.name == name) return b;
    }
    return null;
  }

  /// Homes whose owners chose "not sure" are treated as middle (as on the server).
  static ElevationBand effective(ElevationBand? band) => band ?? middle;
}

/// Suggests a band from GPS altitude using the neighborhood's thresholds.
/// Returns null when there is not enough information to suggest anything.
ElevationBand? suggestElevationBand({
  required double? altitudeM,
  required double? altitudeAccuracyM,
  required double? lowMaxM,
  required double? highMinM,
  double maxAccuracyM = 30,
}) {
  if (altitudeM == null || lowMaxM == null || highMinM == null) return null;
  // Browsers and some devices report 0 when altitude is unknown.
  if (altitudeM == 0 && (altitudeAccuracyM == null || altitudeAccuracyM == 0)) return null;
  if (altitudeAccuracyM != null && altitudeAccuracyM > maxAccuracyM) return null;
  if (altitudeM <= lowMaxM) return ElevationBand.low;
  if (altitudeM >= highMinM) return ElevationBand.high;
  return ElevationBand.middle;
}
