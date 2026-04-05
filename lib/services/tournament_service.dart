import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
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
        );

        if (!bookingResult.success) {
          return TournamentResult.failure(
            'Failed to create facility booking: ${bookingResult.errorMessage}',
          );
        }

        bookingId = bookingResult.booking?.id;
      }

      // Generate initial bracket structure (empty)
      final initialBracket = _generateEmptyBracket(format);

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
        bracketData: initialBracket, // Generate bracket structure immediately
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

      // Log tournament creation for debugging
      debugPrint('✅ Tournament created successfully');
      debugPrint('   ID: ${tournament.id}');
      debugPrint('   Title: ${tournament.title}');
      debugPrint('   Organizer: ${tournament.organizerId}');
      debugPrint('   isPublic: ${tournament.isPublic}');
      debugPrint('   Status: ${tournament.status.code}');
      debugPrint(
        '   Registration Deadline: ${tournament.registrationDeadline}',
      );
      debugPrint('   Start Date: ${tournament.startDate}');

      // Create referee jobs immediately if booking exists
      // This allows referees to see and apply for jobs right after tournament creation
      if (bookingId != null && initialBracket['matches'] != null) {
        debugPrint(
          '📋 Creating referee jobs immediately for tournament: ${tournament.id}',
        );
        await _createRefereeJobsForTournament(tournament, bookingId);
      }

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

        return updated;
      } catch (e) {
        // Non-critical: Status update failure returns original tournament
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

            debugPrint(
              '🌊 Tournament stream update: ${tournaments.length} tournaments fetched',
            );

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

            debugPrint(
              '   After filters: ${tournaments.length} tournaments (public, sport, status)',
            );

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
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'tournament'),
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

        // ROLE CONFLICT CHECK: Prevent joining as player if already a referee
        // Check denormalized refereeUserIds list (O(1) lookup)
        if (tournament.refereeUserIds.contains(user.uid)) {
          throw Exception(
            'You are already registered as a referee for this tournament. '
            'You cannot participate as both a player and a referee in the same tournament.',
          );
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

  /// Generate empty bracket structure for a given format
  Map<String, dynamic> _generateEmptyBracket(TournamentFormat format) {
    if (format == TournamentFormat.eightTeamKnockout) {
      return _generateEightTeamKnockout([]);
    } else if (format == TournamentFormat.fourTeamGroup) {
      return _generateFourTeamGroup([]);
    }
    return {};
  }

  /// Generate 8-team knockout bracket
  Map<String, dynamic> _generateEightTeamKnockout(List<String> teamIds) {
    final matches = <Map<String, dynamic>>[];

    // Ensure we have 8 slots (fill with nulls if needed)
    final paddedTeamIds = List<String?>.filled(8, null);
    for (int i = 0; i < teamIds.length && i < 8; i++) {
      paddedTeamIds[i] = teamIds[i];
    }

    // Quarter-finals (4 matches) - always create all 4 matches
    for (int i = 0; i < 4; i++) {
      matches.add({
        'round': 'QUARTER_FINAL',
        'matchNumber': i + 1,
        'team1Id': paddedTeamIds[i],
        'team2Id': paddedTeamIds[i + 4],
        'winnerId': null,
        'status': 'PENDING',
      });
    }

    // Semi-finals (2 matches)
    for (int i = 0; i < 2; i++) {
      matches.add({
        'round': 'SEMI_FINAL',
        'matchNumber': i + 5,
        'team1Id': null, // Will be set when QF completes
        'team2Id': null,
        'winnerId': null,
        'status': 'PENDING',
      });
    }

    // Final (1 match)
    matches.add({
      'round': 'FINAL',
      'matchNumber': 7,
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

  /// Generate 4-team knockout bracket (semifinals + final)
  Map<String, dynamic> _generateFourTeamGroup(List<String> teamIds) {
    final matches = <Map<String, dynamic>>[];

    // Ensure we have 4 slots (fill with nulls if needed)
    final paddedTeamIds = List<String?>.filled(4, null);
    for (int i = 0; i < teamIds.length && i < 4; i++) {
      paddedTeamIds[i] = teamIds[i];
    }

    // Knockout format: 2 semifinals + 1 final (3 matches total)
    // Semifinal 1
    matches.add({
      'round': 'SEMIFINAL',
      'matchNumber': 1,
      'team1Id': paddedTeamIds[0],
      'team2Id': paddedTeamIds[1],
      'team1Score': null,
      'team2Score': null,
      'winnerId': null,
      'status': 'PENDING',
    });

    // Semifinal 2
    matches.add({
      'round': 'SEMIFINAL',
      'matchNumber': 2,
      'team1Id': paddedTeamIds[2],
      'team2Id': paddedTeamIds[3],
      'team1Score': null,
      'team2Score': null,
      'winnerId': null,
      'status': 'PENDING',
    });

    // Final (winners advance here)
    matches.add({
      'round': 'FINAL',
      'matchNumber': 3,
      'team1Id': null, // Winner of match 1
      'team2Id': null, // Winner of match 2
      'team1Score': null,
      'team2Score': null,
      'winnerId': null,
      'status': 'PENDING',
    });

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

      // Auto-advance winner to next round in knockout format
      if (winnerTeamId != null) {
        final completedMatch = matches[matchIndex];
        final round = completedMatch['round'] as String?;

        // Handle 8-team knockout advancement
        if (tournament.format == TournamentFormat.eightTeamKnockout) {
          if (round == 'QUARTER_FINAL') {
            // QF matches 1-4 advance to SF matches 5-6
            final qfMatchNum = matchNumber; // 1, 2, 3, or 4
            final sfMatchNum = qfMatchNum <= 2 ? 5 : 6;
            final sfMatchIndex = matches.indexWhere(
              (m) => m['matchNumber'] == sfMatchNum,
            );

            if (sfMatchIndex != -1) {
              if (qfMatchNum % 2 == 1) {
                matches[sfMatchIndex]['team1Id'] = winnerTeamId;
              } else {
                matches[sfMatchIndex]['team2Id'] = winnerTeamId;
              }
            }
          } else if (round == 'SEMI_FINAL') {
            // SF matches 5-6 advance to Final match 7
            final sfMatchNum = matchNumber; // 5 or 6
            final finalMatchIndex = matches.indexWhere(
              (m) => m['matchNumber'] == 7,
            );

            if (finalMatchIndex != -1) {
              if (sfMatchNum == 5) {
                matches[finalMatchIndex]['team1Id'] = winnerTeamId;
              } else {
                matches[finalMatchIndex]['team2Id'] = winnerTeamId;
              }
            }
          }
        }
        // Handle 4-team knockout advancement
        else if (tournament.format == TournamentFormat.fourTeamGroup) {
          if (round == 'SEMIFINAL') {
            // SF matches 1-2 advance to Final match 3
            final sfMatchNum = matchNumber; // 1 or 2
            final finalMatchIndex = matches.indexWhere(
              (m) => m['matchNumber'] == 3,
            );

            if (finalMatchIndex != -1) {
              if (sfMatchNum == 1) {
                matches[finalMatchIndex]['team1Id'] = winnerTeamId;
              } else {
                matches[finalMatchIndex]['team2Id'] = winnerTeamId;
              }
            }
          }
        }

        bracketData['matches'] = matches;
      }

      // Update tournament bracket
      final updatedTournament = tournament.copyWith(bracketData: bracketData);

      await _firestore
          .collection(AppConstants.tournamentsCollection)
          .doc(tournamentId)
          .update(updatedTournament.toFirestore());

      // ═══════════════════════════════════════════════════════════════════════
      // PHASE 2A: Safe Integrity - Match Completion → Referee Job Completion
      // ═══════════════════════════════════════════════════════════════════════
      // When a match result is entered (status → COMPLETED), automatically
      // complete the linked referee job IF check-in requirements are met.
      // This ensures referees are only paid when match results are confirmed.
      // ═══════════════════════════════════════════════════════════════════════
      if (winnerTeamId != null) {
        // Match is now COMPLETED - trigger referee job completion
        final matchData = matches[matchIndex];
        final refereeJobId = matchData['refereeJobId'] as String?;

        if (refereeJobId != null && refereeJobId.isNotEmpty) {
          // Complete the referee job asynchronously (don't block match update)
          _completeRefereeJobForMatch(
                jobId: refereeJobId,
                tournamentId: tournamentId,
                matchNumber: matchNumber,
                organizerUserId: tournament.organizerId,
              )
              .then((result) {
                if (result.success) {
                  debugPrint(
                    '✅ [Phase 2A] Auto-completed referee job $refereeJobId for match $matchNumber',
                  );
                } else {
                  debugPrint(
                    '⚠️ [Phase 2A] Could not auto-complete referee job $refereeJobId: ${result.errorMessage}',
                  );
                }
              })
              .catchError((error) {
                debugPrint(
                  '❌ [Phase 2A] Error completing referee job for match $matchNumber: $error',
                );
              });
        } else {
          debugPrint(
            'ℹ️ [Phase 2A] Match $matchNumber has no referee job linked - skipping job completion',
          );
        }
      }

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

  // ═══════════════════════════════════════════════════════════════════════════
  // ROLE MANAGEMENT (BACKEND CONTRACT IMPLEMENTATION)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get user's role in a specific tournament
  /// Role precedence: Organizer > Player > Referee > None
  ///
  /// Returns:
  /// - TournamentRole.organizer: If user is the tournament organizer
  /// - TournamentRole.player: If user is in any team (captain or member)
  /// - TournamentRole.referee: If user is assigned to any referee job
  /// - TournamentRole.none: If user has no role in this tournament
  Future<TournamentRole> getUserTournamentRole(
    String tournamentId,
    String userId,
  ) async {
    try {
      final tournament = await getTournamentById(tournamentId);
      if (tournament == null) {
        return TournamentRole.none;
      }

      // Check organizer (highest precedence)
      if (tournament.isOrganizer(userId)) {
        return TournamentRole.organizer;
      }

      // Check player (team member or captain)
      if (tournament.isUserParticipating(userId)) {
        return TournamentRole.player;
      }

      // Check referee (denormalized list for O(1) lookup)
      // Backward compatible: treat missing refereeUserIds as empty
      if (tournament.refereeUserIds.contains(userId)) {
        return TournamentRole.referee;
      }

      return TournamentRole.none;
    } catch (e) {
      debugPrint('Error getting user tournament role: $e');
      return TournamentRole.none;
    }
  }

  /// Get all referee jobs for a tournament
  /// Used to check if user has any referee assignments for conflict checking
  Future<List<RefereeJobModel>> getTournamentRefereeJobs(
    String tournamentId,
  ) async {
    try {
      final tournament = await getTournamentById(tournamentId);
      if (tournament == null || tournament.refereeJobIds.isEmpty) {
        return [];
      }

      // Query jobs by IDs
      final jobsSnapshot =
          await _firestore
              .collection(AppConstants.jobsCollection)
              .where(FieldPath.documentId, whereIn: tournament.refereeJobIds)
              .get();

      return jobsSnapshot.docs
          .map((doc) => RefereeJobModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting tournament referee jobs: $e');
      return [];
    }
  }

  /// Ensure refereeUserIds field exists on tournament document (backward compatibility)
  /// Call this when first referee applies to ensure field exists for array operations
  Future<void> _ensureRefereeUserIdsExists(String tournamentId) async {
    try {
      final doc =
          await _firestore
              .collection(AppConstants.tournamentsCollection)
              .doc(tournamentId)
              .get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      // If field doesn't exist, initialize it as empty array
      if (!data.containsKey('refereeUserIds')) {
        await doc.reference.update({'refereeUserIds': []});
        debugPrint(
          '✅ Initialized refereeUserIds for tournament: $tournamentId',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error ensuring refereeUserIds exists: $e');
      // Non-critical error, continue
    }
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

      debugPrint('🔍 [JOB CREATION DEBUG] ═══════════════════════════════');
      debugPrint('🔍 Tournament: ${tournament.title}');
      debugPrint('🔍 Booking startTime: $currentMatchTime');
      debugPrint('🔍 Current time (now): ${DateTime.now()}');
      debugPrint('🔍 Match duration: $matchDuration');
      debugPrint('🔍 Sport: ${tournament.sport.code}');
      debugPrint('🔍 Status that will be set: ${JobStatus.open.code}');
      debugPrint('🔍 ═══════════════════════════════════════════════════');

      final createdJobIds = <String>[];
      final updatedMatches = <Map<String, dynamic>>[];

      for (final match in matches) {
        final matchNumber = match['matchNumber'] as int;
        final round = match['round'] as String? ?? 'MATCH';

        // Only create jobs for matches that have teams assigned (not future knockout rounds)
        // For initial rounds (QF, SF with teams) or group stage, create jobs immediately
        final hasTeams = match['team1Id'] != null || match['team2Id'] != null;
        final isInitialRound =
            round == 'GROUP_STAGE' ||
            round == 'QUARTER_FINAL' ||
            round == 'SEMIFINAL';

        // Skip if match doesn't have teams yet AND it's not an initial round
        // (e.g., finals in knockout where winners haven't advanced yet)
        if (!hasTeams && !isInitialRound) {
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

        debugPrint('✅ [JOB CREATED] ─────────────────────────────────');
        debugPrint('✅ Job ID: $jobId');
        debugPrint('✅ Match #$matchNumber ($round)');
        debugPrint('✅ Status: ${job.status.code}');
        debugPrint('✅ Sport: ${job.sport.code}');
        debugPrint('✅ Start time: ${job.startTime}');
        debugPrint('✅ End time: ${job.endTime}');
        debugPrint('✅ End time > now? ${job.endTime.isAfter(DateTime.now())}');
        debugPrint('✅ Earnings: RM${job.earnings}');
        debugPrint('✅ Collection: ${AppConstants.jobsCollection}');
        debugPrint('✅ ────────────────────────────────────────────────');

        createdJobIds.add(jobId);

        // Update match with referee job ID AND match times
        updatedMatches.add({
          ...match,
          'refereeJobId': jobId,
          'matchStartTime': Timestamp.fromDate(currentMatchTime),
          'matchEndTime': Timestamp.fromDate(matchEndTime),
        });

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

  // ═══════════════════════════════════════════════════════════════════════════
  // REFEREE COVERAGE HELPERS (Phase 1 - Visibility)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get referee coverage status for a specific match
  /// Returns status: 'full', 'partial', 'empty', or 'no-job'
  Future<MatchRefereeCoverage> getMatchRefereeCoverage({
    required String tournamentId,
    required int matchNumber,
  }) async {
    try {
      final tournament = await getTournamentById(tournamentId);
      if (tournament == null) {
        return MatchRefereeCoverage.noJob();
      }

      // Get match from bracket
      final matches = tournament.bracketData?['matches'] as List<dynamic>?;
      if (matches == null) {
        return MatchRefereeCoverage.noJob();
      }

      final match = matches.firstWhere(
        (m) => m['matchNumber'] == matchNumber,
        orElse: () => null,
      );

      if (match == null) {
        return MatchRefereeCoverage.noJob();
      }

      final refereeJobId = match['refereeJobId'] as String?;
      if (refereeJobId == null) {
        return MatchRefereeCoverage.noJob();
      }

      // Get referee job
      final jobDoc =
          await _firestore
              .collection(AppConstants.jobsCollection)
              .doc(refereeJobId)
              .get();

      if (!jobDoc.exists) {
        return MatchRefereeCoverage.noJob();
      }

      final job = RefereeJobModel.fromFirestore(jobDoc);

      // Calculate coverage
      if (job.isFullyAssigned) {
        return MatchRefereeCoverage.full(
          assignedCount: job.assignedReferees.length,
          requiredCount: job.refereesRequired,
          referees: job.assignedReferees,
        );
      } else if (job.assignedReferees.isNotEmpty) {
        return MatchRefereeCoverage.partial(
          assignedCount: job.assignedReferees.length,
          requiredCount: job.refereesRequired,
          referees: job.assignedReferees,
        );
      } else {
        return MatchRefereeCoverage.empty(requiredCount: job.refereesRequired);
      }
    } catch (e) {
      debugPrint('Error getting match referee coverage: $e');
      return MatchRefereeCoverage.noJob();
    }
  }

  /// Get all referee coverage for a tournament
  Future<Map<int, MatchRefereeCoverage>> getTournamentRefereeCoverage(
    String tournamentId,
  ) async {
    try {
      final tournament = await getTournamentById(tournamentId);
      if (tournament == null) {
        return {};
      }

      final matches = tournament.bracketData?['matches'] as List<dynamic>?;
      if (matches == null) {
        return {};
      }

      final coverage = <int, MatchRefereeCoverage>{};

      for (final match in matches) {
        final matchNumber = match['matchNumber'] as int;
        coverage[matchNumber] = await getMatchRefereeCoverage(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
        );
      }

      return coverage;
    } catch (e) {
      debugPrint('Error getting tournament referee coverage: $e');
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 2A: Safe Integrity Helper - Complete Referee Job with Check-In Guard
  // ═══════════════════════════════════════════════════════════════════════════
  /// Completes a referee job for a match with check-in requirement enforcement.
  ///
  /// This method ensures payment integrity by:
  /// 1. Verifying at least one referee checked in (proof of service)
  /// 2. Only completing job if check-in requirement is met
  /// 3. Logging warnings if check-ins are missing (for organizer follow-up)
  ///
  /// Edge Cases Handled:
  /// - Job already completed → Skip (idempotent)
  /// - No assigned referees → Skip (job might still be OPEN)
  /// - No check-ins → Log warning, don't complete (organizer can override later)
  /// - Job not found → Log error
  Future<RefereeJobResult> _completeRefereeJobForMatch({
    required String jobId,
    required String tournamentId,
    required int matchNumber,
    required String organizerUserId,
  }) async {
    try {
      // Fetch referee job
      final jobDoc =
          await _firestore
              .collection(AppConstants.jobsCollection)
              .doc(jobId)
              .get();

      if (!jobDoc.exists) {
        debugPrint(
          '⚠️ [Phase 2A] Referee job $jobId not found for match $matchNumber',
        );
        return RefereeJobResult.failure('Referee job not found');
      }

      final job = RefereeJobModel.fromFirestore(jobDoc);

      // Edge Case 1: Job already completed
      if (job.status == JobStatus.completed) {
        debugPrint(
          'ℹ️ [Phase 2A] Referee job $jobId already completed - skipping',
        );
        return RefereeJobResult.success(job);
      }

      // Edge Case 2: No assigned referees yet (job might still be OPEN)
      if (job.assignedReferees.isEmpty) {
        debugPrint(
          '⚠️ [Phase 2A] No referees assigned to job $jobId yet - skipping completion',
        );
        return RefereeJobResult.failure('No referees assigned yet');
      }

      // CRITICAL: Check-in requirement - at least one referee must have checked in
      final hasAnyCheckedIn = job.assignedReferees.any((r) => r.hasCheckedIn);

      if (!hasAnyCheckedIn) {
        // Edge Case 3: No check-ins - DON'T complete job
        debugPrint(
          '❌ [Phase 2A] Cannot complete job $jobId - NO referees checked in for match $matchNumber',
        );
        debugPrint(
          '   Assigned referees: ${job.assignedReferees.map((r) => '${r.name} (checked in: ${r.hasCheckedIn})').join(', ')}',
        );
        debugPrint(
          '   ⚠️ PAYMENT BLOCKED - Organizer can manually complete if check-in was missed',
        );
        return RefereeJobResult.failure(
          'Cannot complete - no referee checked in. Organizer can override manually.',
        );
      }

      // Check-in requirement MET - proceed with job completion
      debugPrint(
        '✅ [Phase 2A] Check-in verified for job $jobId - proceeding with completion',
      );
      debugPrint(
        '   Checked-in referees: ${job.assignedReferees.where((r) => r.hasCheckedIn).map((r) => r.name).join(', ')}',
      );

      // Use existing RefereeService.completeJob() - this handles escrow release
      final refereeService = RefereeService();
      final result = await refereeService.completeJob(
        jobId: jobId,
        organizerUserId: organizerUserId,
        allowAutoComplete: false, // Don't bypass organizer check
      );

      if (result.success) {
        debugPrint(
          '✅ [Phase 2A] Successfully completed job $jobId and released escrow for match $matchNumber',
        );
      } else {
        debugPrint(
          '⚠️ [Phase 2A] RefereeService.completeJob() failed: ${result.errorMessage}',
        );
      }

      return result;
    } catch (e) {
      debugPrint(
        '❌ [Phase 2A] Error completing referee job $jobId for match $matchNumber: $e',
      );
      return RefereeJobResult.failure('Error completing referee job: $e');
    }
  }
}

/// Match referee coverage status
class MatchRefereeCoverage {
  final String status; // 'full', 'partial', 'empty', 'no-job'
  final int assignedCount;
  final int requiredCount;
  final List<AssignedReferee> referees;

  const MatchRefereeCoverage({
    required this.status,
    this.assignedCount = 0,
    this.requiredCount = 0,
    this.referees = const [],
  });

  factory MatchRefereeCoverage.full({
    required int assignedCount,
    required int requiredCount,
    required List<AssignedReferee> referees,
  }) {
    return MatchRefereeCoverage(
      status: 'full',
      assignedCount: assignedCount,
      requiredCount: requiredCount,
      referees: referees,
    );
  }

  factory MatchRefereeCoverage.partial({
    required int assignedCount,
    required int requiredCount,
    required List<AssignedReferee> referees,
  }) {
    return MatchRefereeCoverage(
      status: 'partial',
      assignedCount: assignedCount,
      requiredCount: requiredCount,
      referees: referees,
    );
  }

  factory MatchRefereeCoverage.empty({required int requiredCount}) {
    return MatchRefereeCoverage(status: 'empty', requiredCount: requiredCount);
  }

  factory MatchRefereeCoverage.noJob() {
    return const MatchRefereeCoverage(status: 'no-job');
  }

  bool get isFull => status == 'full';
  bool get isPartial => status == 'partial';
  bool get isEmpty => status == 'empty';
  bool get hasNoJob => status == 'no-job';

  Color get indicatorColor {
    switch (status) {
      case 'full':
        return AppTheme.successGreen;
      case 'partial':
        return AppTheme.warningAmber;
      case 'empty':
        return AppTheme.errorRed;
      case 'no-job':
      default:
        return Colors.grey;
    }
  }

  String get displayText {
    switch (status) {
      case 'full':
        return 'Fully Staffed ($assignedCount/$requiredCount)';
      case 'partial':
        return 'Partial ($assignedCount/$requiredCount)';
      case 'empty':
        return 'No Referee (0/$requiredCount)';
      case 'no-job':
      default:
        return 'No Job Created';
    }
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
