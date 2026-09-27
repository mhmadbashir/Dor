import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The single Supabase client. Overridden in tests.
final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Wall-clock source, overridable in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
