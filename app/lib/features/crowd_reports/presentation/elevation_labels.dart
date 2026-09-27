import '../../../core/l10n/l10n.dart';
import '../../locations/domain/elevation_band.dart';

extension ElevationLabels on AppLocalizations {
  String elevationLabel(ElevationBand? band) => switch (band) {
    ElevationBand.low => elevationLow,
    ElevationBand.middle => elevationMiddle,
    ElevationBand.high => elevationHigh,
    null => elevationNotSure,
  };
}
