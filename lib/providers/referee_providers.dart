import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/referee/data/models/referee_job_model.dart';
import '../core/constants/app_constants.dart';
import 'service_providers.dart';
import 'auth_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// REFEREE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Available referee jobs provider
final availableJobsProvider = FutureProvider<List<RefereeJobModel>>((ref) {
  return ref.watch(refereeServiceProvider).getAvailableJobs();
});

/// Available jobs by sport provider
final availableJobsBySportProvider =
    FutureProvider.family<List<RefereeJobModel>, SportType>((ref, sport) {
      return ref.watch(refereeServiceProvider).getAvailableJobsBySport(sport);
    });

/// User's referee jobs provider
final userRefereeJobsProvider = FutureProvider<List<RefereeJobModel>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  return ref.watch(refereeServiceProvider).getRefereeJobs(user.uid);
});

/// Upcoming referee jobs provider
final upcomingRefereeJobsProvider = FutureProvider<List<RefereeJobModel>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  return ref.watch(refereeServiceProvider).getUpcomingRefereeJobs(user.uid);
});

/// Filtered available jobs based on user badges (v5.0 spec)
/// Shows only jobs the user is certified to officiate
final filteredAvailableJobsProvider = FutureProvider<List<RefereeJobModel>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final jobs = await ref.watch(availableJobsProvider.future);

  if (user == null || user.badges.isEmpty) {
    return jobs; // Return all jobs if no user or no badges
  }

  // Filter jobs based on user's referee badges
  return jobs.where((job) {
    switch (job.sport) {
      case SportType.football:
        return user.badges.contains(AppConstants.badgeRefFootball);
      case SportType.futsal:
        return user.badges.contains(AppConstants.badgeRefFutsal);
      case SportType.badminton:
        return user.badges.contains(AppConstants.badgeRefBadminton);
      case SportType.tennis:
        return user.badges.contains(AppConstants.badgeRefTennis);
    }
  }).toList();
});

/// Referee job by ID provider (for student booking detail view)
/// Uses StreamProvider for real-time updates when job status changes
final refereeJobByIdProvider = StreamProvider.family<RefereeJobModel?, String>((
  ref,
  jobId,
) {
  return ref.watch(refereeServiceProvider).getRefereeJobStream(jobId);
});

/// Referee average rating provider
final refereeRatingProvider = FutureProvider.family<double?, String>((
  ref,
  userId,
) {
  return ref.watch(refereeServiceProvider).getRefereeRating(userId);
});
