import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_providers.dart';
import '../data/supabase_auth_repository.dart';
import '../data/supabase_profile_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.watch(supabaseClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(ref.watch(supabaseClientProvider)),
);

/// The signed-in user id, or null when signed out.
final authUserIdProvider = StreamProvider<String?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  yield repo.currentUserId;
  yield* repo.watchUserId();
});

/// The signed-in user's profile, or null when signed out.
final myProfileProvider = FutureProvider<Profile?>((ref) async {
  final userId = await ref.watch(authUserIdProvider.future);
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).fetchProfile(userId);
});
