import '../../locations/domain/elevation_band.dart';

enum WaterStatus {
  flowing('flowing'),
  noWater('no_water'),
  unknown('unknown');

  const WaterStatus(this.dbName);

  final String dbName;

  static WaterStatus fromDb(String value) =>
      values.firstWhere((s) => s.dbName == value, orElse: () => unknown);
}

class BandStatus {
  const BandStatus({
    required this.band,
    this.status = WaterStatus.unknown,
    this.flowingSince,
    this.arrivedCount = 0,
    this.noWaterCount = 0,
    this.lastReportAt,
  });

  final ElevationBand band;
  final WaterStatus status;
  final DateTime? flowingSince;
  final int arrivedCount;
  final int noWaterCount;
  final DateTime? lastReportAt;
}

/// What to tell a household about the water right now, from their level's view.
sealed class LiveHeadline {
  const LiveHeadline();
}

/// Confirmed flowing at the household's level.
class FlowingHere extends LiveHeadline {
  const FlowingHere({required this.since, required this.confirmations});
  final DateTime since;
  final int confirmations;
}

/// Confirmed flowing lower down, not (yet) at the household's level.
class FlowingBelow extends LiveHeadline {
  const FlowingBelow({required this.since, required this.lowestBand});
  final DateTime since;
  final ElevationBand lowestBand;
}

/// Neighbors at this level (or below) confirm there is no water.
class NoWaterHere extends LiveHeadline {
  const NoWaterHere({required this.reports});
  final int reports;
}

/// Not enough reports to say.
class NoConfirmations extends LiveHeadline {
  const NoConfirmations({required this.reports});
  final int reports;
}

/// Live status of a neighborhood, one entry per elevation band.
class NeighborhoodLiveStatus {
  NeighborhoodLiveStatus(Iterable<BandStatus> bands) : _bands = {for (final b in bands) b.band: b};

  final Map<ElevationBand, BandStatus> _bands;

  BandStatus statusFor(ElevationBand band) => _bands[band] ?? BandStatus(band: band);

  /// Bands from the hilltop down, as shown in the UI.
  List<BandStatus> get topDown => [for (final b in ElevationBand.values.reversed) statusFor(b)];

  LiveHeadline headlineFor(ElevationBand? homeBand) {
    final mine = statusFor(ElevationBand.effective(homeBand));
    switch (mine.status) {
      case WaterStatus.flowing:
        return FlowingHere(since: mine.flowingSince!, confirmations: mine.arrivedCount);
      case WaterStatus.noWater:
        // Water may still be flowing lower down; that is the more useful news.
        break;
      case WaterStatus.unknown:
        break;
    }
    for (final band in ElevationBand.values) {
      if (band.index >= mine.band.index) break;
      final s = statusFor(band);
      if (s.status == WaterStatus.flowing) {
        return FlowingBelow(since: s.flowingSince!, lowestBand: band);
      }
    }
    if (mine.status == WaterStatus.noWater) return NoWaterHere(reports: mine.noWaterCount);
    return NoConfirmations(reports: mine.arrivedCount + mine.noWaterCount);
  }
}
