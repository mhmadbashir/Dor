import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/crowd_report.dart';
import '../domain/crowd_reports_repository.dart';
import '../domain/live_status.dart';
import 'crowd_reports_dtos.dart';

class SupabaseCrowdReportsRepository implements CrowdReportsRepository {
  SupabaseCrowdReportsRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<NeighborhoodLiveStatus> watchStatus(String neighborhoodId) => _client
      .from('neighborhood_status')
      .stream(primaryKey: ['neighborhood_id', 'elevation_band'])
      .eq('neighborhood_id', neighborhoodId)
      .map((rows) => NeighborhoodLiveStatus(rows.map(CrowdReportsDtos.bandStatus).nonNulls))
      .handleError((Object e, StackTrace st) => Error.throwWithStackTrace(mapError(e), st));

  @override
  Future<CrowdReport?> myLatestReport(String neighborhoodId) => guard(() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from('crowd_reports')
        .select('id, kind, created_at')
        .eq('user_id', userId)
        .eq('neighborhood_id', neighborhoodId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : CrowdReportsDtos.report(row);
  });

  @override
  Future<Duration> rateLimit() => guard(() async {
    final row = await _client
        .from('app_settings')
        .select('value')
        .eq('key', 'crowd_reports')
        .maybeSingle();
    final hours = ((row?['value'] as Map<String, dynamic>?)?['rate_limit_hours'] as num?)?.toInt();
    return Duration(hours: hours ?? 6);
  });

  @override
  Future<CrowdReport> submit(String neighborhoodId, ReportKind kind) async {
    try {
      final row = await _client.rpc<Map<String, dynamic>>(
        'submit_crowd_report',
        params: {'p_neighborhood_id': neighborhoodId, 'p_kind': kind.dbName},
      );
      return CrowdReportsDtos.report(row);
    } on PostgrestException catch (e, st) {
      if (e.code == 'P0001' && e.message == 'rate_limited') {
        final next = DateTime.tryParse(e.hint ?? '');
        if (next != null) throw ReportRateLimited(next);
      }
      Error.throwWithStackTrace(mapError(e), st);
    } catch (e, st) {
      Error.throwWithStackTrace(mapError(e), st);
    }
  }
}
