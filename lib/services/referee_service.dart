import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/retry_utils.dart';
import '../features/referee/data/models/referee_job_model.dart';
import '../features/auth/data/models/user_model.dart';
import '../services/merit_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

/// Referee service for SukanGig marketplace
class RefereeService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  RefereeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // JOB LISTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all available referee jobs
  /// Queries by status only, then filters by startTime in code to avoid index issues
  Future<List<RefereeJobModel>> getAvailableJobs({int limit = 50}) async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection(AppConstants.jobsCollection)
        .where('status', isEqualTo: JobStatus.open.code)
        .limit(limit * 2) // Fetch more to account for filtering
        .get();

    return snapshot.docs
        .map((doc) => RefereeJobModel.fromFirestore(doc))
        .where((job) => job.needsReferees && job.startTime.isAfter(now))
        .take(limit) // Apply limit after filtering
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get available jobs for a specific sport
  Future<List<RefereeJobModel>> getAvailableJobsBySport(SportType sport) async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection(AppConstants.jobsCollection)
        .where('sport', isEqualTo: sport.code)
        .where('status', isEqualTo: JobStatus.open.code)
        .get();

    return snapshot.docs
        .map((doc) => RefereeJobModel.fromFirestore(doc))
        .where((job) => job.needsReferees && job.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get jobs assigned to a referee
  Future<List<RefereeJobModel>> getRefereeJobs(String userId, {int limit = 100}) async {
    // Get all jobs and filter by assigned referee
    final snapshot = await _firestore
        .collection(AppConstants.jobsCollection)
        .orderBy('matchDate', descending: true)
        .limit(limit * 2) // Fetch more to account for filtering
        .get();

    return snapshot.docs
        .map((doc) => RefereeJobModel.fromFirestore(doc))
        .where((job) => job.isUserAssigned(userId))
        .take(limit) // Apply limit after filtering
        .toList();
  }

  /// Get upcoming jobs for a referee
  Future<List<RefereeJobModel>> getUpcomingRefereeJobs(String userId) async {
    final now = DateTime.now();
    final jobs = await getRefereeJobs(userId);

    return jobs
        .where((job) =>
            job.startTime.isAfter(now) &&
            (job.status == JobStatus.open || job.status == JobStatus.assigned))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // JOB APPLICATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Apply for a referee job
  Future<RefereeJobResult> applyForJob({
    required String jobId,
    required UserModel referee,
    RefereeRole? preferredRole,
  }) async {
    try {
      // Get the job
      final doc = await _firestore
          .collection(AppConstants.jobsCollection)
          .doc(jobId)
          .get();

      if (!doc.exists) {
        return RefereeJobResult.failure('Job not found');
      }

      final job = RefereeJobModel.fromFirestore(doc);

      // Validate referee is certified for this sport
      if (!referee.isCertifiedFor(job.sport)) {
        return RefereeJobResult.failure(
          'You are not certified to referee ${job.sport.displayName}',
        );
      }

      // Check if already assigned
      if (job.isUserAssigned(referee.uid)) {
        return RefereeJobResult.failure('You are already assigned to this job');
      }

      // Check if job still needs referees
      if (!job.needsReferees) {
        return RefereeJobResult.failure('This job is fully staffed');
      }

      // Determine role based on sport and current assignments
      RefereeRole role;
      if (job.sport == SportType.football) {
        // Football requires 1 main + 2 linesmen
        final hasMainRef = job.assignedReferees
            .any((r) => r.role == RefereeRole.mainReferee);
        
        if (!hasMainRef && (preferredRole == RefereeRole.mainReferee || preferredRole == null)) {
          role = RefereeRole.mainReferee;
        } else {
          role = RefereeRole.linesman;
        }
      } else {
        role = RefereeRole.solo;
      }

      // Create assigned referee entry
      final assignedReferee = AssignedReferee(
        oderId: _uuid.v4(),
        userId: referee.uid,
        name: referee.displayName,
        email: referee.email,
        role: role,
        assignedAt: DateTime.now(),
      );

      // Update job with new referee
      final updatedReferees = [...job.assignedReferees, assignedReferee];
      final isFullyStaffed = updatedReferees.length >= job.refereesRequired;

      await _firestore.collection(AppConstants.jobsCollection).doc(jobId).update({
        'assignedReferees': updatedReferees.map((r) => r.toMap()).toList(),
        'status': isFullyStaffed ? JobStatus.assigned.code : JobStatus.open.code,
        'updatedAt': Timestamp.now(),
      });

      return RefereeJobResult.success(job.copyWith(
        assignedReferees: updatedReferees,
        status: isFullyStaffed ? JobStatus.assigned : JobStatus.open,
      ));
    } catch (e) {
      return RefereeJobResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'referee', defaultMessage: 'Unable to apply for job. Please try again.'),
      );
    }
  }

  /// Withdraw from a job
  Future<RefereeJobResult> withdrawFromJob({
    required String jobId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.jobsCollection)
          .doc(jobId)
          .get();

      if (!doc.exists) {
        return RefereeJobResult.failure('Job not found');
      }

      final job = RefereeJobModel.fromFirestore(doc);

      if (!job.isUserAssigned(userId)) {
        return RefereeJobResult.failure('You are not assigned to this job');
      }

      // Validate job status - prevent withdrawing from completed/cancelled jobs
      if (job.status == JobStatus.completed) {
        return RefereeJobResult.failure('Cannot withdraw from a completed job');
      }

      if (job.status == JobStatus.cancelled) {
        return RefereeJobResult.failure('Cannot withdraw from a cancelled job');
      }

      // Check if withdrawal is allowed (24 hours before match)
      final hoursUntilMatch = job.startTime.difference(DateTime.now()).inHours;
      if (hoursUntilMatch < 24) {
        return RefereeJobResult.failure(
          'Cannot withdraw less than 24 hours before the match',
        );
      }

      // Remove referee from job
      final updatedReferees = job.assignedReferees
          .where((r) => r.userId != userId)
          .toList();

      await _firestore.collection(AppConstants.jobsCollection).doc(jobId).update({
        'assignedReferees': updatedReferees.map((r) => r.toMap()).toList(),
        'status': JobStatus.open.code, // Reopen for applications
        'updatedAt': Timestamp.now(),
      });

      return RefereeJobResult.success(job.copyWith(
        assignedReferees: updatedReferees,
        status: JobStatus.open,
      ));
    } catch (e) {
      return RefereeJobResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'referee', defaultMessage: 'Unable to withdraw from job. Please try again.'),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHECK-IN & COMPLETION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Referee check-in at venue (QR scan)
  Future<RefereeJobResult> checkIn({
    required String jobId,
    required String userId,
    required String scannedQrCode,
  }) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.jobsCollection)
          .doc(jobId)
          .get();

      if (!doc.exists) {
        return RefereeJobResult.failure('Job not found');
      }

      final job = RefereeJobModel.fromFirestore(doc);

      // Validate QR code (would match booking QR in real implementation)
      // For now, just verify the referee is assigned

      if (!job.isUserAssigned(userId)) {
        return RefereeJobResult.failure('You are not assigned to this job');
      }

      final referee = job.getAssignedReferee(userId);
      if (referee == null) {
        return RefereeJobResult.failure('Referee assignment not found');
      }

      if (referee.hasCheckedIn) {
        return RefereeJobResult.failure('Already checked in');
      }

      // Update check-in status - with retry
      final updatedReferees = job.assignedReferees.map((r) {
        if (r.userId == userId) {
          return r.copyWith(hasCheckedIn: true, checkedInAt: DateTime.now());
        }
        return r;
      }).toList();

      await RetryUtils.retry(
        operation: () async {
          await _firestore.collection(AppConstants.jobsCollection).doc(jobId).update({
            'assignedReferees': updatedReferees.map((r) => r.toMap()).toList(),
            'updatedAt': Timestamp.now(),
          });
        },
        config: RetryConfig.network,
      );

      return RefereeJobResult.success(job.copyWith(
        assignedReferees: updatedReferees,
      ));
    } catch (e) {
      return RefereeJobResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'referee', defaultMessage: 'Check-in failed. Please try again.'),
      );
    }
  }

  /// Complete job and trigger payment release
  /// Auto-completion allowed when job endTime has passed (for automatic escrow release)
  Future<RefereeJobResult> completeJob({
    required String jobId,
    required String organizerUserId,
    bool allowAutoComplete = false, // Set to true for automatic completion when time passes
  }) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.jobsCollection)
          .doc(jobId)
          .get();

      if (!doc.exists) {
        return RefereeJobResult.failure('Job not found');
      }

      final job = RefereeJobModel.fromFirestore(doc);

      // Allow auto-completion if job time has passed (for automatic escrow release)
      final now = DateTime.now();
      final jobTimePassed = now.isAfter(job.endTime);
      
      if (!allowAutoComplete || !jobTimePassed) {
        // Normal completion requires organizer verification
        if (job.organizerUserId != organizerUserId) {
          return RefereeJobResult.failure('Only the organizer can complete the job');
        }
      } else {
        // Auto-completion: log that we're auto-completing due to time passing
        debugPrint('⏰ Auto-completing job $jobId - endTime has passed (${job.endTime})');
      }

      if (job.status == JobStatus.completed) {
        return RefereeJobResult.failure('Job is already completed');
      }

      // Verify all referees have checked in (unless auto-completing after time passed)
      // For auto-completion when time passes, allow completion even if check-in missed
      if (!allowAutoComplete || !jobTimePassed) {
        final allCheckedIn = job.assignedReferees.every((r) => r.hasCheckedIn);
        if (!allCheckedIn) {
          return RefereeJobResult.failure('Not all referees have checked in');
        }
      } else {
        // Auto-completion: Log if check-ins are missing
        final allCheckedIn = job.assignedReferees.every((r) => r.hasCheckedIn);
        if (!allCheckedIn) {
          debugPrint('⚠️ Auto-completing job with incomplete check-ins (time has passed)');
        }
      }

      // Update job status to completed - with retry
      await RetryUtils.retry(
        operation: () async {
          await _firestore.collection(AppConstants.jobsCollection).doc(jobId).update({
            'status': JobStatus.completed.code,
            'updatedAt': Timestamp.now(),
          });
        },
        config: RetryConfig.network,
      );

      // Release escrow to each assigned referee
      // For multi-referee jobs (e.g., Football), escrow is split equally
      if (job.assignedReferees.isNotEmpty) {
        // Find escrow for this job (only if still held - prevent duplicate release)
        final escrowQuery = await _firestore
            .collection(AppConstants.escrowCollection)
            .where('jobId', isEqualTo: jobId)
            .where('status', isEqualTo: 'HELD') // EscrowStatus.held.code
            .get();

        if (escrowQuery.docs.isEmpty) {
          // Escrow already released or doesn't exist - this is fine, just log
          debugPrint('⚠️ No held escrow found for job $jobId (may already be released)');
        } else {
          final escrowDoc = escrowQuery.docs.first;
          final escrowData = escrowDoc.data();
          final totalEscrowAmount = (escrowData['amount'] ?? 0).toDouble();
          final escrowId = escrowDoc.id;
          
          // Calculate each referee's share (equal split)
          final refereeShare = totalEscrowAmount / job.assignedReferees.length;
          
          // Release to each referee and award merit points
          for (final referee in job.assignedReferees) {
            // Credit referee's wallet - with retry
            await RetryUtils.retry(
              operation: () async {
                await _firestore
                    .collection(AppConstants.walletsCollection)
                    .doc(referee.userId)
                    .update({
                  'balance': FieldValue.increment(refereeShare),
                  'updatedAt': Timestamp.now(),
                });
              },
              config: RetryConfig.payment,
            );
            
            // Create release transaction for this referee - with retry
            final txId = _uuid.v4();
            await RetryUtils.retry(
              operation: () async {
                await _firestore
                    .collection(AppConstants.transactionsCollection)
                    .doc(txId)
                    .set({
                  'id': txId,
                  'oderId': _uuid.v4(),
                  'userId': referee.userId,
                  'userEmail': referee.email,
                  'type': 'ESCROW_RELEASE',
                  'amount': refereeShare,
                  'status': 'COMPLETED',
                  'referenceId': escrowId,
                  'description': 'Referee payment for job $jobId (${referee.role.code})',
                  'createdAt': Timestamp.now(),
                  'completedAt': Timestamp.now(),
                });
              },
              config: RetryConfig.payment,
            );

            // Award merit points to referee
            try {
              final authService = AuthService();
              final userModel = await authService.getUserModel(referee.userId);

              if (userModel != null) {
                final meritService = MeritService();
                final meritResult = await meritService.awardRefereeMerit(
                  user: userModel,
                  job: job,
                );

                if (meritResult.success) {
                  debugPrint('✅ Merit points awarded to referee: +${AppConstants.meritPointsReferee} (B2)');
                  
                  // Send notification
                  final notificationService = NotificationService();
                  await notificationService.createNotification(
                    userId: referee.userId,
                    type: NotificationType.meritPointsAwarded,
                    title: 'Merit Points Earned! 🎉',
                    body: 'You earned +${AppConstants.meritPointsReferee} merit points (GP08 Code: B2) for refereeing ${job.sport.displayName} at ${job.facilityName}',
                    relatedId: jobId,
                    route: '/merit',
                    data: {'points': AppConstants.meritPointsReferee, 'code': 'B2'},
                  );
                } else {
                  debugPrint('⚠️ Merit award failed for referee: ${meritResult.errorMessage}');
                }
              }
            } catch (meritError) {
              // Don't fail job completion if merit award fails
              debugPrint('⚠️ Failed to award merit points to referee: $meritError');
            }
          }
          
          // Mark escrow as released (all referees paid)
          await _firestore
              .collection(AppConstants.escrowCollection)
              .doc(escrowId)
              .update({
            'status': 'RELEASED', // EscrowStatus.released.code
            'releasedAt': Timestamp.now(),
            'releaseReason': 'Job completed - split among ${job.assignedReferees.length} referee(s)',
          });
        }
      }

      return RefereeJobResult.success(job.copyWith(
        status: JobStatus.completed,
      ));
    } catch (e) {
      return RefereeJobResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'referee', defaultMessage: 'Unable to complete job. Please try again.'),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RATINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Rate a referee after job completion
  Future<bool> rateReferee({
    required String jobId,
    required String refereeUserId,
    required String raterUserId,
    required double rating,
    String? comment,
  }) async {
    try {
      // Save rating
      await _firestore.collection(AppConstants.ratingsCollection).add({
        'jobId': jobId,
        'refereeUserId': refereeUserId,
        'raterUserId': raterUserId,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.now(),
      });

      // Update referee's hasBeenRated flag in the job
      final doc = await _firestore
          .collection(AppConstants.jobsCollection)
          .doc(jobId)
          .get();

      if (doc.exists) {
        final job = RefereeJobModel.fromFirestore(doc);
        final updatedReferees = job.assignedReferees.map((r) {
          if (r.userId == refereeUserId) {
            return r.copyWith(hasBeenRated: true, rating: rating);
          }
          return r;
        }).toList();

        await _firestore.collection(AppConstants.jobsCollection).doc(jobId).update({
          'assignedReferees': updatedReferees.map((r) => r.toMap()).toList(),
        });
      }

      // Note: Escrow is released when the job is completed (in completeJob method),
      // not when ratings are submitted. Ratings happen after escrow release.

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get referee's average rating
  Future<double?> getRefereeRating(String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.ratingsCollection)
        .where('refereeUserId', isEqualTo: userId)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final totalRating = snapshot.docs.fold<double>(
      0,
      (total, doc) => total + (doc.data()['rating'] ?? 0).toDouble(),
    );

    return totalRating / snapshot.docs.length;
  }
}

/// Referee job operation result
class RefereeJobResult {
  final bool success;
  final RefereeJobModel? job;
  final String? errorMessage;

  const RefereeJobResult._({
    required this.success,
    this.job,
    this.errorMessage,
  });

  factory RefereeJobResult.success(RefereeJobModel job) {
    return RefereeJobResult._(success: true, job: job);
  }

  factory RefereeJobResult.failure(String message) {
    return RefereeJobResult._(success: false, errorMessage: message);
  }
}

