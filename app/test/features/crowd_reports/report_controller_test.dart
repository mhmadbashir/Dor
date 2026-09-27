import 'package:dor/core/errors/failure.dart';
import 'package:dor/features/crowd_reports/domain/crowd_report.dart';
import 'package:dor/features/crowd_reports/presentation/crowd_reports_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  final now = DateTime.utc(2026, 9, 27, 6);
  late FakeCrowdReportsRepository repo;
  late ProviderContainer container;
  final provider = reportControllerProvider('nb-khalda');

  setUp(() {
    repo = FakeCrowdReportsRepository()..now = () => now;
    container = ProviderContainer.test(
      overrides: [crowdReportsRepositoryProvider.overrideWithValue(repo)],
      retry: (_, _) => null,
    );
    container.listen(provider, (_, _) {});
  });

  test('submitting records the report and starts the 6-hour wait', () async {
    await container.read(provider.future);
    await container.read(provider.notifier).submit(ReportKind.arrived);

    final state = container.read(provider).value!;
    expect(repo.submitted, [ReportKind.arrived]);
    expect(state.justReported, isTrue);
    expect(state.reporting.lastReport!.kind, ReportKind.arrived);
    expect(state.canReport(now.add(const Duration(hours: 1))), isFalse);
    expect(state.reporting.nextAllowedAt, now.add(const Duration(hours: 6)));
  });

  test('a server-side rate limit disables reporting until the given time', () async {
    final until = now.add(const Duration(hours: 3));
    repo.submitError = ReportRateLimited(until);
    await container.read(provider.future);

    await container.read(provider.notifier).submit(ReportKind.noWater);

    final state = container.read(provider).value!;
    expect(state.reporting.nextAllowedAt, until);
    expect(state.canReport(now), isFalse);
    expect(state.error, isNull);
  });

  test('other failures are shown and reporting stays possible', () async {
    repo.submitError = const Failure(FailureKind.network);
    await container.read(provider.future);

    await container.read(provider.notifier).submit(ReportKind.arrived);

    final state = container.read(provider).value!;
    expect((state.error! as Failure).kind, FailureKind.network);
    expect(state.canReport(now), isTrue);
  });

  test('loads the last report so the wait survives restarts', () async {
    repo.latest = CrowdReport(id: 'x', kind: ReportKind.noWater, createdAt: now);
    container.invalidate(provider);
    final state = await container.read(provider.future);
    expect(state.canReport(now.add(const Duration(hours: 2))), isFalse);
  });
}
