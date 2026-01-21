import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_time_utils.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/retry_utils.dart';
import '../features/tournament/data/models/tournament_model.dart';
import '../features/tournament/data/models/tournament_team_model.dart';
import '../features/booking/data/models/booking_model.dart';
import '../features/booking/data/models/facility_model.dart';
import '../features/auth/data/models/user_model.dart';
import '../features/referee/data/models/referee_job_model.dart';
import '../services/booking_service.dart';
import '../services/payment_service.dart';
import '../services/merit_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/referee_service.dart';

/// Professional tournament service with complete business logic
/// Handles tournament lifecycle: creation, team registration, bracket management, referee assignment
class TournamentService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  TournamentService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // TOURNAMENT CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create a new tournament
  /// This is the main entry point for tournament creation
  /// Automatically handles: facility booking, referee job creation, bracket initialization
  Future<TournamentResult> createTournament({
    required String title,
    String? description,
    required SportType sport,
    required UserModel organizer,
    required TournamentFormat format,
    required int maxTeams,
    double? entryFee,
    double? firstPlacePrize,
    double? organizerFee,
    required bool isStudentOnly,
    required DateTime registrationDeadline,
    required DateTime startDate,
    DateTime? endDate,
    required Duration matchDuration,
    required FacilityModel facility,
    required DateTime facilityStartTime,
    required DateTime facilityEndTime,
    String? subUnit, // For facilities with subUnits (e.g., badminton courts)
    bool autoCreateBooking = true, // Auto-book facility for tournament
  }) async {
    try {
      // Business Logic Validation
      final validation = _validateTournamentCreation(
        title: title,
        maxTeams: maxTeams,
        format: format,
        registrationDeadline: registrationDeadline,
        startDate: startDate,
        organizer: organizer,
        isStudentOnly: isStudentOnly,
      );

      if (!validation.isValid) {
        return TournamentResult.failure(validation.errorMessage!);
      }

      // Generate tournament ID and share code
      final tournamentId = _uuid.v4();
      final shareCode = _generateTournamentShareCode();

      // Calculate referee requirements based on sport (tournament rate)
      final refereesRequired = _getRefereesRequired(sport);
      final refereeFeeTotal =
          refereesRequired * AppConstants.refereeEarningsTournament;

      // Create facility booking if requested
      // Note: Referee jobs are created separately in _createRefereeJobsForTournament
      // when tournament registration closes (when all teams have joined)
      String? bookingId;
      if (autoCreateBooking) {
        final bookingService = BookingService();
        final bookingResult = await bookingService.createBooking(
          facility: facility,
          user: organizer,
          date: DateTimeUtils.startOfDay(startDate),
          startTime: facilityStartTime,
          endTime: facilityEndTime,
          subUnit: subUnit, // Pass court selection for facilities with subUnits
          bookingType: BookingType.match,
          tournamentFormat: format,
          isSplitBill: isStudentOnly, // Auto-enable split bill for students
        );

        if (!bookingResult.success) {
          return TournamentResult.failure(
            'Failed to create facility booking: ${bookingResult.errorMessage}',
          );
        }

        bookingId = bookingResult.booking?.id;
      }

      // Create tournament document
      final tournament = TournamentModel(
        id: tournamentId,
        title: title,
        description: description,
        sport: sport,
        organizerId: organizer.uid,
        organizerName: organizer.displayName,
        organizerEmail: organizer.email,
        format: format,
        maxTeams: maxTeams,
        currentTeams: 0,
        entryFee: entryFee,
        firstPlacePrize: firstPlacePrize,
        organizerFee: organizerFee,
        isStudentOnly: isStudentOnly,
        registrationDeadline: registrationDeadline,
        startDate: startDate,
        endDate: endDate,
        matchDuration: matchDuration,
        facilityId: facility.id,
        facilityName: facility.name,
        venue: facility.name, // Can be enhanced later
        bookingId: bookingId,
        refereesRequired: refereesRequired,
        refereeFeeTotal: refereeFeeTotal,
        refereeJobIds: [], // Will be populated after referee jobs created
        teams: [],
        bracketData: null, // Will be generated when first team joins
        shareCode: shareCode,
        isPublic: true,
        status: TournamentStatus.registrationOpen,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save tournament to Firestore with retry
      await RetryUtils.retry(
        operation: () async {
          await _firestore
              .collection(AppConstants.tournamentsCollection)
              .doc(tournamentId)
              .set(tournament.toFirestore());
        },
        config: RetryConfig.network,
      );

      // Referee jobs will be created automatically when tournament registration closes
      // (when max teams are reached). This is handled in joinTournament() method.

      return TournamentResult.success(tournament);
    } catch (e) {
      return TournamentResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(
          e,
          context: 'tournament',
          defaultMessage: 'Unable to create tournament. Please try again.',
        ),
      );
    }
  }

  /// Get tournament by ID
  /// Automatically updates status if needed (e.g., registration deadline passed)
  Future<TournamentModel?> getTournamentById(String tournamentId) async {
    try {
      final doc =
          await _firestore
              .collection(AppConstants.tournamentsCollection)
              .doc(tournamentId)
              .get();

      if (!doc.exists) return null;

      var tournament = TournamentModel.fromFirestore(doc);

      // Auto-update status if needed
      tournament = await _autoUpdateTournamentStatus(tournament);

      return tournament;
    } catch (e) {
      debugPrint('Error getting tournament by ID: $e');
      return null;
    }
  }

  /// Get tournament by ID as a stream for real-time updates
  /// Useful for tournament detail screens where bracket updates need to be reflected immediately
  Stream<TournamentModel?> getTournamentByIdStream(String tournamentId) {
    return _firestore
        .collection(AppConstants.tournamentsCollection)
        .doc(tournamentId)
        .snapshots()
        .asyncMap((doc) async {
          if (!doc.exists) return null;

          final tournament = TournamentModel.fromFirestore(doc);

          // Auto-update status if needed (non-blocking)
          // Note: Status updates happen in background, current data is still returned
          _autoUpdateTournamentStatus(tournament).catchError((e) {
            debugPrint('Error auto-updating tournament status in stream: $e');
            return tournament; // Return original tournament on error
          });

          return tournament;
        });
  }

  /// Automatically update tournament status based on current state and time
  /// Called when tournament is fetched to ensure status is up-to-date
  Future<TournamentModel> _autoUpdateTournamentStatus(
    TournamentModel tournament,
  ) async {
    final now = DateTime.now();
    TournamentStatus? newStatus;

    // 0. Check if tournament is below minimum teams - auto-cancel if so
    // Only check if tournament hasn't started yet and is below minimum
    if (tournament.status != TournamentStatus.cancelled &&
        tournament.status != TournamentStatus.completed &&
        tournament.status != TournamentStatus.inProgress &&
        tournament.currentTeams < AppConstants.minTournamentTeams) {
      // Auto-cancel tournament if below minimum teams
      try {
        final cancelResult = await cancelTournament(
          tournamentId: tournament.id,
          reason:
              'Tournament cancelled: Below minimum teams (${tournament.currentTeams} < ${AppConstants.minTournamentTeams})',
        );
        if (cancelResult.success && cancelResult.tournament != null) {
          debugPrint(
            '⚠️ Auto-cancelled tournament ${tournament.id} - below minimum teams',
          );
          return cancelResult.tournament!; // Return cancelled tournament
        }
      } catch (e) {
        debugPrint('⚠️ Failed to auto-cancel tournament: $e');
        // Continue with normal status update even if auto-cancel fails
      }
    }

    // 1. Check if registration deadline has passed
    if (tournament.status == TournamentStatus.registrationOpen) {
      if (now.isAfter(tournament.registrationDeadline) || tournament.isFull) {
        newStatus = TournamentStatus.registrationClosed;
      }
    }

    // 2. Check if tournament has started (startDate passed)
    if (tournament.status == TournamentStatus.registrationClosed) {
      if (now.isAfter(tournament.startDate) ||
          now.isAtSameMomentAs(tournament.startDate)) {
        newStatus = TournamentStatus.inProgress;
      }
    }

    // 3. Check if tournament has ended (endDate passed, or startDate + reasonable duration)
    if (tournament.status == TournamentStatus.inProgress) {
      if (tournament.endDate != null) {
        if (now.isAfter(tournament.endDate!)) {
          newStatus = TournamentStatus.completed;
        }
      } else {
        // No endDate - consider tournament complete 24 hours after startDate
        final hoursSinceStart = now.difference(tournament.startDate).inHours;
        if (hoursSinceStart > 24) {
          newStatus = TournamentStatus.completed;
        }
      }
    }

    // Update status in Firestore if changed
    if (newStatus != null && newStatus != tournament.status) {
      try {
        final updated = tournament.copyWith(status: newStatus);
        await _firestore
            .collection(AppConstants.tournamentsCollection)
            .doc(tournament.id)
            .update({'status': newStatus.code, 'updatedAt': Timestamp.now()});

        // Create referee jobs when registration closes (if not already created)
        if (newStatus == TournamentStatus.registrationClosed &&
            tournament.bookingId != null &&
            tournament.refereeJobIds.isEmpty) {
          debugPrint(
            '📋 Registration closed - creating referee jobs for tournament: ${tournament.id}',
          );
          await _createRefereeJobsForTournament(updated, tournament.bookingId!);
        }

        // Award merit points when tournament is completed
        if (newStatus == TournamentStatus.completed) {
          try {
            final authService = AuthService();
            final meritService = MeritService();
            final notificationService = NotificationService();

            // Award merit to organizer
            final organizerModel = await authService.getUserModel(
              tournament.organizerId,
            );
            if (organizerModel != null) {
              final organizerMeritResult = await meritService
                  .awardOrganizerMerit(
                    user: organizerModel,
                    tournamentId: tournament.id,
                    sport: tournament.sport,
                    facilityName: tournament.facilityName,
                    tournamentDate: tournament.startDate,
                  );

              if (organizerMeritResult.success) {
                debugPrint(
                  '✅ Merit points awarded to organizer: +${AppConstants.meritPointsOrganizer} (B3)',
                );

                await notificationService.createNotification(
                  userId: tournament.organizerId,
                  type: NotificationType.meritPointsAwarded,
                  title: 'Merit Points Earned! 🎉',
                  body:
                      'You earned +${AppConstants.meritPointsOrganizer} merit points (GP08 Code: B3) for organizing ${tournament.sport.displayName} tournament',
                  relatedId: tournament.id,
                  route: '/merit',
                  data: {
                    'points': AppConstants.meritPointsOrganizer,
                    'code': 'B3',
                  },
                );
              } else {
                debugPrint(
                  '⚠️ Merit award failed for organizer: ${organizerMeritResult.errorMessage}',
                );
              }
            }

            // Award merit to all registered tournament participants (captains + team members)
            for (final team in tournament.teams) {
              // Award to captain
              try {
                final captainModel = await authService.getUserModel(
                  team.captainId,
                );
                if (captainModel != null) {
                  final participantMeritResult = await meritService
                      .awardParticipantMerit(
                        user: captainModel,
                        tournamentId: tournament.id,
                        sport: tournament.sport,
                        facilityName: tournament.facilityName,
                        tournamentDate: tournament.startDate,
                      );

                  if (participantMeritResult.success) {
                    debugPrint(
                      '✅ Merit points awarded to participant (captain): ${team.captainName} (+${AppConstants.meritPointsPlayer} B1)',
                    );

                    await notificationService.createNotification(
                      userId: team.captainId,
                      type: NotificationType.meritPointsAwarded,
                      title: 'Merit Points Earned! 🎉',
                      body:
                          'You earned +${AppConstants.meritPointsPlayer} merit points (GP08 Code: B1) for participating in ${tournament.sport.displayName} tournament',
                      relatedId: tournament.id,
                      route: '/merit',
                      data: {
                        'points': AppConstants.meritPointsPlayer,
                        'code': 'B1',
                      },
                    );
                  }
                }
              } catch (e) {
                debugPrint(
                  '⚠️ Failed to award merit to captain ${team.captainName}: $e',
                );
              }

              // Award to all team members
              for (int i = 0; i < team.memberIds.length; i++) {
                try {
                  final memberId = team.memberIds[i];
                  final memberModel = await authService.getUserModel(memberId);
                  if (memberModel != null) {
                    final participantMeritResult = await meritService
                        .awardParticipantMerit(
                          user: memberModel,
                          tournamentId: tournament.id,
                          sport: tournament.sport,
                          facilityName: tournament.facilityName,
                          tournamentDate: tournament.startDate,
                        );

                    if (participantMeritResult.success) {
                      debugPrint(
                        '✅ Merit points awarded to participant (member): ${team.memberNames[i]} (+${AppConstants.meritPointsPlayer} B1)',
                      );

                      await notificationService.createNotification(
                        userId: memberId,
                        type: NotificationType.meritPointsAwarded,
                        title: 'Merit Points Earned! 🎉',
                        body:
                            'You earned +${AppConstants.meritPointsPlayer} merit points (GP08 Code: B1) for participating in ${tournament.sport.displayName} tournament',
                        relatedId: tournament.id,
                        route: '/merit',
                        data: {
                          'points': AppConstants.meritPointsPlayer,
                          'code': 'B1',
                        },
                      );
                    }
                  }
                } catch (e) {
                  debugPrint(
                    '⚠️ Failed to award merit to member ${team.memberNames[i]}: $e',
                  );
                }
              }
            }
          } catch (meritError) {
            // Don't fail tournament status update if merit award fails
            debugPrint('⚠️ Failed to award merit points: $meritError');
          }

          // Auto-release escrow for referee jobs when tournament time passes
          // Escrow should be released after tournament/booking time ends
          if (tournament.refereeJobIds.isNotEmpty) {
            try {
              final refereeService = RefereeService();
              final now = DateTime.now();
              final tournamentEndTime =
                  tournament.endDate ??
                  tournament.startDate.add(const Duration(hours: 24));

              // If tournament time has passed, auto-release escrow for all referee jobs
              if (now.isAfter(tournamentEndTime)) {
                debugPrint(
                  '⏰ Tournament time has passed - auto-releasing escrow for referee jobs',
                );

                for (final jobId in tournament.refereeJobIds) {
                  try {
                    // Get job to check if escrow needs to be released
                    final jobDoc =
                        await _firestore
                            .collection(AppConstants.jobsCollection)
                            .doc(jobId)
                            .get();

                    if (jobDoc.exists) {
                      final job = RefereeJobModel.fromFirestore(jobDoc);
                      // Only release if job is assigned and escrow is still held
                      // Check if job time has passed (endTime)
                      if (job.assignedReferees.isNotEmpty &&
                          job.status != JobStatus.completed &&
                          now.isAfter(job.endTime)) {
                        // Auto-complete job to release escrow (this releases escrow)
                        // Allow auto-completion since tournament time has passed
                        final result = await refereeService.completeJob(
                          jobId: jobId,
                          organizerUserId: tournament.organizerId,
                          allowAutoComplete:
                              true, // Allow auto-completion when time has passed
                        );

                        if (result.success) {
                          debugPrint(
                            '✅ Auto-released escrow for referee job: $jobId',
                          );
                        } else {
                          debugPrint(
                            '⚠️ Failed to auto-release escrow for job $jobId: ${result.errorMessage}',
                          );
                        }
                      }
                    }
                  } catch (jobError) {
                    debugPrint(
                      '⚠️ Error auto-releasing escrow for job $jobId: $jobError',
                    );
                    // Continue with other jobs
                  }
                }
              }
            } catch (escrowError) {
              // Don't fail tournament completion if escrow release fails
              debugPrint('⚠️ Failed to auto-release escrow: $escrowError');
            }
          }
        }

        debugPrint(
          '✅ Auto-updated tournament ${tournament.id} status: ${tournament.status.code} → ${newStatus.code}',
        );
        return updated;
      } catch (e) {
        debugPrint('⚠️ Failed to auto-update tournament status: $e');
        // Return original tournament if update fails
        return tournament;
      }
    }

    return tournament;
  }

  /// Get tournament by share code
  Future<TournamentModel?> getTournamentByShareCode(String shareCode) async {
    try {
      final snapshot =
          await _firestore
              .collection(AppConstants.tournamentsCollection)
              .where('shareCode', isEqualTo: shareCode)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) return null;

      return TournamentModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('Error getting tournament by share code: $e');
      return null;
    }
  }

  /// Get all public tournaments (for discovery) - returns a stream for real-time updates
  /// Filters applied in code to avoid Firestore composite index requirements
  Stream<List<TournamentModel>> getPublicTournamentsStream({
    SportType? sportFilter,
    TournamentStatus? statusFilter,
    int limit = 50,
  }) {
    try {
      // Query without filters to avoid composite index requirements
      // All filtering is done in code after fetching
      return _firestore
          .collection(AppConstants.tournamentsCollection)
          .orderBy('startDate', descending: false)
          .limit(limit * 2) // Fetch more to account for filtering
          .snapshots()
          .map((snapshot) {
            var tournaments =
                snapshot.docs
                    .map((doc) => TournamentModel.fromFirestore(doc))
                    .toList();

            // Filter in code to avoid Firestore index requirements
            tournaments = tournaments.where((t) => t.isPublic).toList();

            if (sportFilter != null) {
              tournaments =
                  tournaments.where((t) => t.sport == sportFilter).toList();
            }

            if (statusFilter != null) {
              tournaments =
                  tournaments.where((t) => t.status == statusFilter).toList();
            }

            // Apply limit after filtering
            return tournaments.take(limit).toList();
          });
    } catch (e) {
      debugPrint('Error in getPublicTournamentsStream: $e');
      return Stream.value([]);
    }
  }

  /// Get all public tournaments (for discovery) - legacy method for backwards compatibility
  /// Filters applied in code to avoid Firestore composite index requirements
  Future<List<TournamentModel>> getPublicTournaments({
    SportType? sportFilter,
    TournamentStatus? statusFilter,
    int limit = 50,
  }) async {
    try {
      // Query without filters to avoid composite index requirements
      // All filtering is done in code after fetching
      final snapshot =
          await _firestore
              .collection(AppConstants.tournamentsCollection)
              .orderBy('startDate', descending: false)
              .limit(limit * 2) // Fetch more to account for filtering
              .get();

      var tournaments =
          snapshot.docs
              .map((doc) => TournamentModel.fromFirestore(doc))
              .toList();

      // Filter in code to avoid Firestore index requirements
      tournaments = tournaments.where((t) => t.isPublic).toList();

      if (sportFilter != null) {
        tournaments = tournaments.where((t) => t.sport == sportFilter).toList();
      }

      if (statusFilter != null) {
        tournaments =
            tournaments.where((t) => t.status == statusFilter).toList();
      }

      // Apply limit after filtering
      return tournaments.take(limit).toList();
    } catch (e) {
      debugPrint('Error in getPublicTournaments: $e');
      return [];
    }
  }

  /// Get user's tournaments (as organizer or participant)
  /// Filtering done in code to avoid Firestore composite index requirements
  Future<List<TournamentModel>> getUserTournaments(String userId) async {
    try {
      // Query all tournaments ordered by startDate (no where clause to avoid index)
      // Filter in code to avoid composite index requirements
      final snapshot =
          await _firestore
              .collection(AppConstants.tournamentsCollection)
              .orderBy('startDate', descending: true)
              .limit(100) // Reasonable limit for user tournaments
              .get();

      final allTournaments =
          snapshot.docs
              .map((doc) => TournamentModel.fromFirestore(doc))
              .toList();

      // Filter organizer tournaments in code
      final organizerTournaments =
          allTournaments.where((t) => t.isOrganizer(userId)).toList();

      // Filter participant tournaments in code
      final participantTournaments =
          allTournaments
              .where(
                (t) => t.isUserParticipating(userId) && !t.isOrganizer(userId),
              )
              .toList();

      // Combine and sort by startDate descending
      final combined = [...organizerTournaments, ...participantTournaments];
      combined.sort((a, b) => b.startDate.compareTo(a.startDate));

      return combined;
    } catch (e) {
      debugPrint('Error in getUserTournaments: $e');
      return [];
    }
  }

  /// Update tournament
  Future<TournamentResult> updateTournament({
    required String tournamentId,
    String? title,
    String? description,
    TournamentStatus? status,
    Map<String, dynamic>? bracketData,
    List<String>? refereeJobIds,
  }) async {
    try {
      final tournament = await getTournamentById(tournamentId);
      if (tournament == null) {
        return TournamentResult.failure('Tournament not found');
      }

      final updated = tournament.copyWith(
        title: title,
        description: description,
        status: status,
        bracketData: bracketData,
        refereeJobIds: refereeJobIds,
      );

      await _firestore
          .collection(AppConstants.tournamentsCollection)
          .doc(tournamentId)
          .update(updated.toFirestore());

      return TournamentResult.success(updated);
    } catch (e) {
      return TournamentResult.failure(
        'Failed to update tournament: ${e.toString()}',
      );
    }
  }

  /// Cancel tournament
  Future<TournamentResult> cancelTournament({
    required String tournamentId,
    required String reason,
  }) async {
    try {
      final tournament = await getTournamentById(tournamentId);
      if (tournament == null) {
        return TournamentResult.failure('Tournament not found');
      }

      if (tournament.status == TournamentStatus.cancelled) {
        return TournamentResult.failure('Tournament is already cancelled');
      }

      // Update status
      final updated = tournament.copyWith(status: TournamentStatus.cancelled);

      await _firestore
          .collection(AppConstants.tournamentsCollection)
          .doc(tournamentId)
          .update(updated.toFirestore());

      // ═══════════════════════════════════════════════════════════════════════════
      // CLEANUP: Cancel associated booking, referee jobs, and process refunds
      // ═══════════════════════════════════════════════════════════════════════════

      // 1. Cancel associated booking if exists
      if (tournament.bookingId != null) {
        try {
          final bookingService = BookingService();
          await bookingService.cancelBooking(
            bookingId: tournament.bookingId!,
            reason: 'Tournament cancelled: $reason',
            forceRefund: true,
          );
        } catch (e) {
          debugPrint('⚠️ Failed to cancel booking ${tournament.bookingId}: $e');
          // Continue with other cleanup even if booking cancellation fails
        }
      }

      // 2. Cancel referee jobs
      if (tournament.refereeJobIds.isNotEmpty) {
        try {
          for (final jobId in tournament.refereeJobIds) {
            try {
              // Get job to check if it's still active
              final jobDoc =
                  await _firestore
                      .collection(AppConstants.jobsCollection)
                      .doc(jobId)
                      .get();

              if (jobDoc.exists) {
                final job = RefereeJobModel.fromFirestore(jobDoc);
                // Only cancel if job is not already completed/cancelled
                if (job.status == JobStatus.open ||
                    job.status == JobStatus.assigned) {
                  await _firestore
                      .collection(AppConstants.jobsCollection)
                      .doc(jobId)
                      .update({
                        'status': JobStatus.cancelled.code,
                        'updatedAt': Timestamp.now(),
                      });
                }
              }
            } catch (e) {
              debugPrint('⚠️ Failed to cancel referee job $jobId: $e');
              // Continue with other jobs
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error cancelling referee jobs: $e');
        }
      }

      // 3. Process refunds for entry fees
      if (tournament.entryFee != null && tournament.entryFee! > 0) {
        try {
          final paymentService = PaymentService();
          final refundedTeams = <String>[];

          for (final team in tournament.teams) {
            // Only refund teams that have paid
            if (team.paidEntryFee && tournament.entryFee != null) {
              try {
                final refundResult = await paymentService
                    .refundTournamentEntryFee(
                      userId: team.captainId,
                      userEmail: team.captainEmail,
                      amount: tournament.entryFee!,
                      tournamentId: tournamentId,
                      teamName: team.teamName,
                      reason: 'Tournament cancelled: $reason',
                    );

                if (refundResult.success) {
                  refundedTeams.add(team.teamName);
                } else {
                  debugPrint(
                    '⚠️ Failed to refund entry fee for team ${team.teamName}: ${refundResult.errorMessage}',
                  );
                }
              } catch (e) {
                debugPrint(
                  '⚠️ Error refunding entry fee for team ${team.teamName}: $e',
                );
                // Continue with other teams
              }
            }
          }

          if (refundedTeams.isNotEmpty) {
            debugPrint(
              '✅ Refunded entry fees for ${refundedTeams.length} teams: ${refundedTeams.join(", ")}',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error processing entry fee refunds: $e');
        }
      }

      return TournamentResult.success(updated);
    } catch (e) {
      return TournamentResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(
          e,
          context: 'tournament',
          defaultMessage: 'Unable to cancel tournament. Please try again.',
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEAM REGISTRATION & MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Join tournament as a team (captain registers team)
  /// Uses Firestore transaction to prevent race conditions when multiple users join simultaneously
  Future<TournamentResult> joinTournament({
    required String tournamentId,
    required UserModel user,
    required String teamName,
    double? entryFeePaid,
    String? entryFeeTransactionId,
  }) async {
    try {
      // Use Firestore transaction to prevent race conditions
      return await _firestore.runTransaction((transaction) async {
        // Get tournament document within transaction
        final tournamentDoc = await transaction.get(
          _firestore
              .collection(AppConstants.tournamentsCollection)
              .doc(tournamentId),
        );

        if (!tournamentDoc.exists) {
          throw Exception('Tournament not found');
        }

        final tournament = TournamentModel.fromFirestore(tournamentDoc);

        // Business Logic Validation (within transaction for consistency)
        if (!tournament.isRegistrationOpen) {
          throw Exception('Registration is closed or tournament is full');
        }

        if (tournament.isFull) {
          throw Exception('Tournament is full');
        }

        if (tournament.isStudentOnly && !user.isStudent) {
          throw Exception('This tournament is only open to UPM students');
        }

        if (tournament.isUserParticipating(user.uid)) {
          throw Exception('You are already registered in this tournament');
        }

        // Validate entry fee payment
        if (tournament.entryFee != null && tournament.entryFee! > 0) {
          if (entryFeePaid == null || entryFeePaid < tournament.entryFee!) {
            throw Exception(
              'Entry fee of RM ${tournament.entryFee!.toStringAsFixed(2)} is required',
            );
          }
        }

        // Create team
        final teamId = _uuid.v4();
        final seed = tournament.teams.length + 1; // Simple seeding

        final team = TournamentTeamModel(
          teamId: teamId,
          teamName: teamName,
          captainId: user.uid,
          captainName: user.displayName,
          captainEmail: user.email,
          memberIds: [],
          memberNames: [],
          registeredAt: DateTime.now(),
          paidEntryFee: entryFeePaid != null,
          entryFeeTransactionId: entryFeeTransactionId,
          seed: seed,
        );

        // Add team to tournament
        final updatedTeams = [...tournament.teams, team];

        // Generate or update bracket
        final bracketData = await _generateOrUpdateBracket(
          tournament: tournament,
          teams: updatedTeams,
        );

        // Update tournament
        final updatedTournament = tournament.copyWith(
          currentTeams: updatedTeams.length,
          teams: updatedTeams,
          bracketData: bracketData,
          status:
              updatedTeams.length >= tournament.maxTeams
                  ? TournamentStatus.registrationClosed
                  : TournamentStatus.registrationOpen,
        );

        // Update within transaction (atomic operation)
        transaction.update(
          tournamentDoc.reference,
          updatedTournament.toFirestore(),
        );

        // After transaction commits, create referee jobs if registration is closed
        // Do this outside transaction to avoid long-running transactions
        if (updatedTeams.length >= tournament.maxTeams &&
            tournament.bookingId != null &&
            (tournament.refereeJobIds.isEmpty)) {
          // Use Future.microtask to ensure this runs after transaction commits
          Future.microtask(() async {
            debugPrint(
              '📋 Tournament full - creating referee jobs for: ${tournament.id}',
            );
            // Re-fetch tournament to get updated bracket data
            final refreshedTournament = await getTournamentById(tournament.id);
            if (refreshedTournament != null &&
                refreshedTournament.bracketData != null) {
              await _createRefereeJobsForTournament(
                refreshedTournament,
                tournament.bookingId!,
              );
            } else {
              debugPrint(
                '⚠️ Bracket not ready yet, referee jobs will be created on status update',
              );
            }
          });
        }

        // Return success after transaction commits
        return TournamentResult.success(updatedTournament);
      });
    } catch (e) {
      return TournamentResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(
          e,
          context: 'tournament',
          defaultMessage: 'Unable to join tournament. Please try again.',
        ),
      );
    }
  }

  /// Add member to team (when team captain invites others)
  Future<TournamentResult> addTeamMember({
    required String tournamentId,
    required String teamId,
    required UserModel member,
  }) async {
    try {
      final tournament = await getTournamentById(tournamentId);
      if (tournament == null) {
        return TournamentResult.failure('Tournament not found');
      }

      final teamIndex = tournament.teams.indexWhere((t) => t.teamId == teamId);
      if (teamIndex == -1) {
        return TournamentResult.failure('Team not found');
      }

      final team = tournament.teams[teamIndex];

      // Validate user is not already in another team
      if (tournament.isUserParticipating(member.uid)) {
        return TournamentResult.failure(
          'User is already registered in another team',
        );
      }

      // Add member to team
      final updatedTeam = team.copyWith(
        memberIds: [...team.memberIds, member.uid],
        memberNames: [...team.memberNames, member.displayName],
      );

      final updatedTeams = List<TournamentTeamModel>.from(tournament.teams);
      updatedTeams[teamIndex] = updatedTeam;

      final updatedTournament = tournament.copyWith(teams: updatedTeams);

      await _firestore
          .collection(AppConstants.tournamentsCollection)
          .doc(tournamentId)
          .update(updatedTournament.toFirestore());

      return TournamentResult.success(updatedTournament);
    } catch (e) {
      return TournamentResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(
          e,
          context: 'tournament',
          defaultMessage: 'Unable to add team member. Please try again.',
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BRACKET MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate or update bracket based on current teams
  Future<Map<String, dynamic>> _generateOrUpdateBracket({
    required TournamentModel tournament,
    required List<TournamentTeamModel> teams,
  }) async {
    final teamIds = teams.map((t) => t.teamId).toList();

    if (tournament.format == TournamentFormat.eightTeamKnockout) {
      return _generateEightTeamKnockout(teamIds);
    } else if (tournament.format == TournamentFormat.fourTeamGroup) {
      return _generateFourTeamGroup(teamIds);
    }

    return {};
  }

  /// Generate 8-team knockout bracket
  Map<String, dynamic> _generateEightTeamKnockout(List<String> teamIds) {
    final matches = <Map<String, dynamic>>[];

    // Quarter-finals (4 matches)
    for (int i = 0; i < 4; i++) {
      matches.add({
        'round': 'QUARTER_FINAL',
        'matchNumber': i + 1,
        'team1Id': i < teamIds.length ? teamIds[i] : null,
        'team2Id': i + 4 < teamIds.length ? teamIds[i + 4] : null,
        'winnerId': null,
        'status': 'PENDING',
      });
    }

    // Semi-finals (2 matches)
    for (int i = 0; i < 2; i++) {
      matches.add({
        'round': 'SEMI_FINAL',
        'matchNumber': i + 1,
        'team1Id': null, // Will be set when QF completes
        'team2Id': null,
        'winnerId': null,
        'status': 'PENDING',
      });
    }

    // Final (1 match)
    matches.add({
      'round': 'FINAL',
      'matchNumber': 1,
      'team1Id': null,
      'team2Id': null,
      'winnerId': null,
      'status': 'PENDING',
    });

    return {
      'format': TournamentFormat.eightTeamKnockout.code,
      'teamCount': teamIds.length,
      'matches': matches,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Generate 4-team group stage bracket (round-robin)
  Map<String, dynamic> _generateFourTeamGroup(List<String> teamIds) {
    final matches = <Map<String, dynamic>>[];

    // Round-robin: each team plays every other team once (6 matches total)
    int matchNum = 1;
    for (int i = 0; i < teamIds.length; i++) {
      for (int j = i + 1; j < teamIds.length; j++) {
        matches.add({
          'round': 'GROUP_STAGE',
          'matchNumber': matchNum++,
          'team1Id': teamIds[i],
          'team2Id': teamIds[j],
          'team1Score': null,
          'team2Score': null,
          'winnerId': null,
          'status': 'PENDING',
        });
      }
    }

    return {
      'format': TournamentFormat.fourTeamGroup.code,
      'teamCount': teamIds.length,
      'matches': matches,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Update match result in bracket
  Future<TournamentResult> updateMatchResult({
    required String tournamentId,
    required int matchNumber,
    String? winnerTeamId,
    int? team1Score,
    int? team2Score,
  }) async {
    try {
      final tournament = await getTournamentById(tournamentId);
      if (tournament == null) {
        return TournamentResult.failure('Tournament not found');
      }

      if (tournament.bracketData == null) {
        return TournamentResult.failure('Bracket not initialized');
      }

      final bracketData = Map<String, dynamic>.from(tournament.bracketData!);
      final matches = List<Map<String, dynamic>>.from(
        bracketData['matches'] ?? [],
      );

      final matchIndex = matches.indexWhere(
        (m) => m['matchNumber'] == matchNumber,
      );
      if (matchIndex == -1) {
        return TournamentResult.failure('Match not found');
      }

      // Update match
      matches[matchIndex] = {
        ...matches[matchIndex],
        'winnerId': winnerTeamId,
        'team1Score': team1Score,
        'team2Score': team2Score,
        'status': winnerTeamId != null ? 'COMPLETED' : 'PENDING',
        'completedAt':
            winnerTeamId != null ? FieldValue.serverTimestamp() : null,
      };

      bracketData['matches'] = matches;
      bracketData['updatedAt'] = FieldValue.serverTimestamp();

      // Update tournament bracket
      final updatedTournament = tournament.copyWith(bracketData: bracketData);

      await _firestore
          .collection(AppConstants.tournamentsCollection)
          .doc(tournamentId)
          .update(updatedTournament.toFirestore());

      return TournamentResult.success(updatedTournament);
    } catch (e) {
      return TournamentResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(
          e,
          context: 'tournament',
          defaultMessage: 'Unable to update match result. Please try again.',
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validate tournament creation input
  _ValidationResult _validateTournamentCreation({
    required String title,
    required int maxTeams,
    required TournamentFormat format,
    required DateTime registrationDeadline,
    required DateTime startDate,
    required UserModel organizer,
    required bool isStudentOnly,
  }) {
    if (title.trim().isEmpty) {
      return _ValidationResult(false, 'Tournament title is required');
    }

    if (maxTeams < 2) {
      return _ValidationResult(false, 'Tournament must have at least 2 teams');
    }

    if (maxTeams != format.teamCount) {
      return _ValidationResult(
        false,
        'Max teams must match format (${format.teamCount} teams for ${format.displayName})',
      );
    }

    if (registrationDeadline.isBefore(DateTime.now())) {
      return _ValidationResult(
        false,
        'Registration deadline must be in the future',
      );
    }

    if (startDate.isBefore(DateTime.now())) {
      return _ValidationResult(false, 'Start date must be in the future');
    }

    if (startDate.isBefore(registrationDeadline)) {
      return _ValidationResult(
        false,
        'Tournament start date must be after registration deadline',
      );
    }

    if (isStudentOnly && !organizer.isStudent) {
      return _ValidationResult(
        false,
        'Only students can create student-only tournaments',
      );
    }

    return _ValidationResult(true, null);
  }

  /// Get referees required based on sport
  int _getRefereesRequired(SportType sport) {
    switch (sport) {
      case SportType.football:
        return 3; // 1 main + 2 linesmen
      case SportType.futsal:
        return 1; // Solo referee
      case SportType.badminton:
        return 1; // Umpire
      case SportType.tennis:
        return 1; // Chair umpire
    }
  }

  /// Generate unique tournament share code
  String _generateTournamentShareCode() {
    // Format: TOURNAMENT-ANIMAL-NUMBER
    final animals = ['EAGLE', 'TIGER', 'LION', 'BEAR', 'WOLF', 'FALCON'];
    final random = DateTime.now().millisecondsSinceEpoch;
    final animalIndex = random % animals.length;
    final animal = animals[animalIndex];
    final number = (random % 900) + 100; // 100-999
    return 'TOURNAMENT-$animal-$number';
  }

  /// Create referee jobs for tournament matches
  /// Creates one referee job per match in the bracket when bracket is finalized
  Future<void> _createRefereeJobsForTournament(
    TournamentModel tournament,
    String bookingId,
  ) async {
    try {
      // Get booking to get facility details and time slot
      final bookingDoc =
          await _firestore
              .collection(AppConstants.bookingsCollection)
              .doc(bookingId)
              .get();

      if (!bookingDoc.exists) {
        debugPrint('⚠️ Booking not found for tournament: $bookingId');
        return;
      }

      final booking = BookingModel.fromFirestore(bookingDoc);

      // Check if bracket is already generated and has matches
      if (tournament.bracketData == null) {
        debugPrint(
          '⚠️ Bracket not yet generated for tournament: ${tournament.id}',
        );
        return;
      }

      final bracketData = tournament.bracketData!;
      final matches = List<Map<String, dynamic>>.from(
        bracketData['matches'] ?? [],
      );

      if (matches.isEmpty) {
        debugPrint('⚠️ No matches in bracket for tournament: ${tournament.id}');
        return;
      }

      // Get referee requirements based on sport (tournament rate)
      final refereesRequired = _getRefereesRequired(tournament.sport);
      const earningsPerMatch = AppConstants.refereeEarningsTournament;

      // Calculate match times
      // Matches are scheduled sequentially with matchDuration between them
      var currentMatchTime = booking.startTime;
      final matchDuration = tournament.matchDuration;

      final createdJobIds = <String>[];
      final updatedMatches = <Map<String, dynamic>>[];

      for (final match in matches) {
        final matchNumber = match['matchNumber'] as int;
        final round = match['round'] as String? ?? 'MATCH';

        // Only create jobs for matches that have teams assigned (not future knockout rounds)
        // For group stage or initial rounds, create jobs immediately
        final hasTeams = match['team1Id'] != null || match['team2Id'] != null;

        // Skip if match doesn't have teams yet (future knockout rounds)
        // These will be created when teams advance
        if (!hasTeams && round != 'GROUP_STAGE') {
          debugPrint('⏭️ Skipping match $matchNumber (no teams assigned yet)');
          updatedMatches.add(match);
          continue;
        }

        // Create referee job for this match
        final jobId = _uuid.v4();
        final matchEndTime = currentMatchTime.add(matchDuration);

        final job = RefereeJobModel(
          id: jobId,
          bookingId: bookingId,
          facilityId: tournament.facilityId,
          facilityName: tournament.facilityName,
          sport: tournament.sport,
          matchDate: DateTimeUtils.startOfDay(currentMatchTime),
          startTime: currentMatchTime,
          endTime: matchEndTime,
          location: tournament.facilityName,
          earnings: earningsPerMatch,
          refereesRequired: refereesRequired,
          status: JobStatus.open,
          organizerUserId: tournament.organizerId,
          organizerName: tournament.organizerName,
          notes:
              'Tournament: ${tournament.title} - Match $matchNumber ($round)',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save referee job to Firestore
        await _firestore
            .collection(AppConstants.jobsCollection)
            .doc(jobId)
            .set(job.toFirestore());

        createdJobIds.add(jobId);

        // Update match with referee job ID
        updatedMatches.add({...match, 'refereeJobId': jobId});

        // Move to next match time (add buffer between matches if needed)
        currentMatchTime = matchEndTime.add(
          const Duration(minutes: 5),
        ); // 5 min buffer

        debugPrint('✅ Created referee job $jobId for match $matchNumber');
      }

      // Update bracket with referee job IDs
      final updatedBracketData = {
        ...bracketData,
        'matches': updatedMatches,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update tournament with bracket data and referee job IDs
      await _firestore
          .collection(AppConstants.tournamentsCollection)
          .doc(tournament.id)
          .update({
            'bracketData': updatedBracketData,
            'refereeJobIds': FieldValue.arrayUnion(createdJobIds),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      debugPrint(
        '✅ Created ${createdJobIds.length} referee jobs for tournament ${tournament.id}',
      );
    } catch (e) {
      debugPrint('❌ Error creating referee jobs for tournament: $e');
    }
  }

  // Legacy methods for backward compatibility with existing booking flow
  Future<Map<String, dynamic>> generateBracket({
    required TournamentFormat format,
    required String bookingId,
    required List<String> teamIds,
  }) async {
    if (format == TournamentFormat.eightTeamKnockout) {
      return _generateEightTeamKnockout(teamIds);
    } else if (format == TournamentFormat.fourTeamGroup) {
      return _generateFourTeamGroup(teamIds);
    }
    return {};
  }

  Future<Map<String, dynamic>?> getTournamentBracket(String bookingId) async {
    try {
      final doc =
          await _firestore
              .collection(AppConstants.tournamentsCollection)
              .doc(bookingId)
              .get();

      if (!doc.exists) return null;
      return doc.data()?['bracketData'];
    } catch (e) {
      return null;
    }
  }

  /// Legacy method: Add team to tournament bracket (for booking-based tournaments)
  /// Used when split bill booking creates tournament bracket
  /// This maintains backward compatibility with existing booking flow
  Future<void> addTeamToTournament({
    required String bookingId,
    required String teamId,
    required String teamName,
  }) async {
    try {
      // For booking-based tournaments, the bracket is stored directly in tournaments collection
      // with bookingId as document ID
      final bracketDoc = _firestore
          .collection(AppConstants.tournamentsCollection)
          .doc(bookingId);
      final bracket = await bracketDoc.get();

      if (!bracket.exists) {
        // If bracket doesn't exist, we need to get the booking to create it
        final bookingDoc =
            await _firestore
                .collection(AppConstants.bookingsCollection)
                .doc(bookingId)
                .get();

        if (!bookingDoc.exists) return;

        final booking = BookingModel.fromFirestore(bookingDoc);
        if (booking.tournamentFormat == null) return;

        // Generate initial bracket
        final newBracket = await generateBracket(
          format: booking.tournamentFormat!,
          bookingId: bookingId,
          teamIds: [teamId],
        );
        await bracketDoc.set(newBracket);
      } else {
        // Add team to existing bracket
        final data = bracket.data()!;
        final teams = List<Map<String, dynamic>>.from(data['teams'] ?? []);

        // Check if team already exists
        if (teams.any((t) => t['id'] == teamId)) return;

        teams.add({'id': teamId, 'name': teamName});

        await bracketDoc.update({'teams': teams, 'teamCount': teams.length});
      }
    } catch (e) {
      // Handle error silently for backward compatibility
      debugPrint('Warning: Failed to add team to tournament bracket: $e');
    }
  }

  /// Get tournament statistics for admin dashboard
  Future<AdminTournamentStats> getTournamentStats() async {
    try {
      final snapshot =
          await _firestore.collection(AppConstants.tournamentsCollection).get();

      int upcoming = 0;
      int active = 0;
      int completed = 0;
      int cancelled = 0;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      int todayCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final statusCode = data['status'] as String?;
        final status = TournamentStatus.fromCode(
          statusCode ?? 'REGISTRATION_OPEN',
        );

        // Count by status
        switch (status) {
          case TournamentStatus.registrationOpen:
          case TournamentStatus.registrationClosed:
            upcoming++;
            break;
          case TournamentStatus.inProgress:
            active++;
            break;
          case TournamentStatus.completed:
            completed++;
            break;
          case TournamentStatus.cancelled:
            cancelled++;
            break;
        }

        // Count tournaments created today
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null &&
            createdAt.isAfter(todayStart) &&
            createdAt.isBefore(todayEnd)) {
          todayCount++;
        }
      }

      return AdminTournamentStats(
        totalTournaments: snapshot.docs.length,
        upcoming: upcoming,
        active: active,
        completed: completed,
        cancelled: cancelled,
        todayCount: todayCount,
      );
    } catch (e) {
      debugPrint('❌ Failed to get tournament stats: $e');
      return const AdminTournamentStats();
    }
  }

  /// Get all tournaments (admin only)
  Future<List<TournamentModel>> getAllTournaments({int limit = 100}) async {
    try {
      final snapshot =
          await _firestore
              .collection(AppConstants.tournamentsCollection)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs
          .map((doc) => TournamentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get all tournaments: $e');
      return [];
    }
  }

  /// Stream of all tournaments (admin only)
  Stream<List<TournamentModel>> getAllTournamentsStream({int limit = 100}) {
    return _firestore
        .collection(AppConstants.tournamentsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => TournamentModel.fromFirestore(doc))
                  .toList(),
        );
  }
}

/// Validation result helper
class _ValidationResult {
  final bool isValid;
  final String? errorMessage;

  _ValidationResult(this.isValid, this.errorMessage);
}

/// Tournament operation result wrapper
class TournamentResult {
  final bool success;
  final TournamentModel? tournament;
  final String? errorMessage;

  const TournamentResult._({
    required this.success,
    this.tournament,
    this.errorMessage,
  });

  factory TournamentResult.success(TournamentModel tournament) {
    return TournamentResult._(success: true, tournament: tournament);
  }

  factory TournamentResult.failure(String message) {
    return TournamentResult._(success: false, errorMessage: message);
  }
}

/// Admin tournament statistics model
class AdminTournamentStats {
  final int totalTournaments;
  final int upcoming;
  final int active;
  final int completed;
  final int cancelled;
  final int todayCount;

  const AdminTournamentStats({
    this.totalTournaments = 0,
    this.upcoming = 0,
    this.active = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.todayCount = 0,
  });
}
