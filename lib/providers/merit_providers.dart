import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/merit/data/models/merit_record_model.dart';
import 'service_providers.dart';
import 'auth_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MERIT PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// User's merit records provider
final meritRecordsProvider = FutureProvider<List<MeritRecordModel>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  return ref.watch(meritServiceProvider).getUserMeritRecords(user.uid);
});

/// Alias for merit records (used in UI)
final userMeritRecordsProvider = meritRecordsProvider;

/// Merit summary by category provider
final meritSummaryProvider = FutureProvider<Map<MeritCategory, int>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return {};
  return ref.watch(meritServiceProvider).getMeritSummary(user.uid);
});

/// Total merit points provider
final totalMeritPointsProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return 0;
  return ref.watch(meritServiceProvider).getTotalMeritPoints(user.uid);
});
