import 'package:dor/features/crowd_reports/domain/crowd_report.dart';
import 'package:dor/features/crowd_reports/domain/live_status.dart';
import 'package:dor/features/locations/domain/elevation_band.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  group('suggestElevationBand', () {
    ElevationBand? suggest(double? altitude, {double? accuracy = 10}) => suggestElevationBand(
      altitudeM: altitude,
      altitudeAccuracyM: accuracy,
      lowMaxM: 960,
      highMinM: 1020,
    );

    test('maps altitude to a band using the thresholds', () {
      expect(suggest(940), ElevationBand.low);
      expect(suggest(960), ElevationBand.low);
      expect(suggest(990), ElevationBand.middle);
      expect(suggest(1020), ElevationBand.high);
      expect(suggest(1050), ElevationBand.high);
    });

    test('does not guess from missing or poor altitude data', () {
      expect(suggest(null), isNull);
      expect(suggest(0, accuracy: 0), isNull, reason: 'browsers report 0 when unknown');
      expect(suggest(1050, accuracy: 60), isNull, reason: 'too inaccurate');
      expect(
        suggestElevationBand(altitudeM: 1000, altitudeAccuracyM: 5, lowMaxM: null, highMinM: 1020),
        isNull,
        reason: 'neighborhood has no thresholds',
      );
    });

    test('"not sure" counts as middle', () {
      expect(ElevationBand.effective(null), ElevationBand.middle);
      expect(ElevationBand.effective(ElevationBand.high), ElevationBand.high);
    });
  });

  group('NeighborhoodLiveStatus.headlineFor', () {
    final six = DateTime.utc(2026, 9, 27, 3); // 6:00 Amman

    test('flowing at my level', () {
      final live = NeighborhoodLiveStatus([flowing(ElevationBand.low, six, 12)]);
      final h = live.headlineFor(ElevationBand.low);
      expect(h, isA<FlowingHere>());
      expect((h as FlowingHere).confirmations, 12);
      expect(h.since, six);
    });

    test('hilltop home sees that water reached lower homes', () {
      final live = NeighborhoodLiveStatus([flowing(ElevationBand.low, six, 5)]);
      final h = live.headlineFor(ElevationBand.high);
      expect(h, isA<FlowingBelow>());
      expect((h as FlowingBelow).lowestBand, ElevationBand.low);
    });

    test('flowing lower down is more useful than "no water" at my level', () {
      final live = NeighborhoodLiveStatus([
        flowing(ElevationBand.low, six, 5),
        const BandStatus(band: ElevationBand.high, status: WaterStatus.noWater, noWaterCount: 4),
      ]);
      expect(live.headlineFor(ElevationBand.high), isA<FlowingBelow>());
    });

    test('no water at my level', () {
      final live = NeighborhoodLiveStatus([
        const BandStatus(band: ElevationBand.middle, status: WaterStatus.noWater, noWaterCount: 4),
      ]);
      final h = live.headlineFor(null); // not sure -> middle
      expect(h, isA<NoWaterHere>());
      expect((h as NoWaterHere).reports, 4);
    });

    test('water higher up does not count as "below" for low homes', () {
      final live = NeighborhoodLiveStatus([
        const BandStatus(band: ElevationBand.low, arrivedCount: 1),
      ]);
      final h = live.headlineFor(ElevationBand.low);
      expect(h, isA<NoConfirmations>());
      expect((h as NoConfirmations).reports, 1);
    });

    test('missing rows read as unknown and topDown lists the hilltop first', () {
      final live = NeighborhoodLiveStatus(const []);
      expect(live.topDown.map((b) => b.band), [
        ElevationBand.high,
        ElevationBand.middle,
        ElevationBand.low,
      ]);
      expect(live.topDown.every((b) => b.status == WaterStatus.unknown), isTrue);
    });
  });

  group('ReportingState', () {
    final at9 = DateTime.utc(2026, 9, 27, 6);

    test('can report when nothing was reported', () {
      expect(const ReportingState(rateLimit: Duration(hours: 6)).canReport(at9), isTrue);
    });

    test('waits 6 hours after the last report', () {
      final s = ReportingState(
        lastReport: CrowdReport(id: 'r', kind: ReportKind.arrived, createdAt: at9),
        rateLimit: const Duration(hours: 6),
      );
      expect(s.nextAllowedAt, at9.add(const Duration(hours: 6)));
      expect(s.canReport(at9.add(const Duration(hours: 5, minutes: 59))), isFalse);
      expect(s.canReport(at9.add(const Duration(hours: 6))), isTrue);
    });

    test('honors a later limit reported by the server', () {
      final later = at9.add(const Duration(hours: 8));
      final s = ReportingState(
        lastReport: CrowdReport(id: 'r', kind: ReportKind.arrived, createdAt: at9),
        rateLimit: const Duration(hours: 6),
        serverNextAllowedAt: later,
      );
      expect(s.nextAllowedAt, later);
    });
  });
}
