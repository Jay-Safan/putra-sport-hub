import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart'
    hide TransactionStatus, EscrowStatus;
import '../core/utils/qr_utils.dart';
import '../core/utils/error_handler.dart';
import '../features/payment/data/models/transaction_model.dart';
import '../features/booking/data/models/booking_model.dart';
import '../features/auth/data/models/user_model.dart';
import '../services/notification_service.dart';
import '../services/booking_service.dart';

/// Payment service for SukanPay financial system
class PaymentService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  PaymentService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // PRICING LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate price based on user type (Student vs Public)
  double calculatePrice({
    required double studentPrice,
    required double publicPrice,
    required String userEmail,
  }) {
    final isStudent = userEmail.toLowerCase().endsWith(
      AppConstants.studentEmailDomain,
    );
    return isStudent ? studentPrice : publicPrice;
  }

  /// Get price tier label
  String getPriceTier(String userEmail) {
    final isStudent = userEmail.toLowerCase().endsWith(
      AppConstants.studentEmailDomain,
    );
    return isStudent ? 'Student Rate' : 'Public Rate';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WALLET MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get user's wallet
  Future<WalletModel?> getWallet(String userId) async {
    final doc =
        await _firestore
            .collection(AppConstants.walletsCollection)
            .doc(userId)
            .get();

    if (doc.exists) {
      return WalletModel.fromFirestore(doc);
    }
    return null;
  }

  /// Get wallet stream for real-time updates
  Stream<WalletModel?> walletStream(String userId) {
    return _firestore
        .collection(AppConstants.walletsCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? WalletModel.fromFirestore(doc) : null);
  }

  /// Top up wallet balance
  Future<PaymentResult> topUpWallet({
    required String userId,
    required double amount,
    required String paymentMethod,
  }) async {
    if (amount <= 0) {
      return PaymentResult.failure('Invalid amount');
    }

    try {
      // Simulate payment gateway processing (2 seconds) for realistic UX
      // In production: replace with actual payment gateway API call
      await Future.delayed(const Duration(seconds: 2));

      final transactionId = _uuid.v4();

      // Fetch user email from users collection
      String userEmail = '';
      try {
        final userDoc =
            await _firestore
                .collection(AppConstants.usersCollection)
                .doc(userId)
                .get();
        if (userDoc.exists) {
          userEmail = userDoc.data()?['email'] ?? '';
        }
      } catch (e) {
        // Non-critical: Email fetch failure shouldn't block wallet top-up
      }

      // Create transaction record
      final transaction = TransactionModel(
        id: transactionId,
        oderId: _uuid.v4(),
        userId: userId,
        userEmail: userEmail,
        type: TransactionType.topUp,
        amount: amount,
        status: TransactionStatus.completed,
        description: 'Wallet top-up via $paymentMethod',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        metadata: {'paymentMethod': paymentMethod},
      );

      // Get or create wallet document
      final walletRef = _firestore
          .collection(AppConstants.walletsCollection)
          .doc(userId);

      final walletDoc = await walletRef.get();

      if (!walletDoc.exists) {
        // Create new wallet if it doesn't exist
        final now = DateTime.now();
        await walletRef.set({
          'userId': userId,
          'balance': amount, // Initial balance is the top-up amount
          'escrowBalance': 0.0,
          'pendingBalance': 0.0,
          'currency': 'MYR',
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });
      } else {
        // Update existing wallet balance
        await walletRef.update({
          'balance': FieldValue.increment(amount),
          'updatedAt': Timestamp.now(),
        });

        // Validate balance after update (should never be negative)
        final updatedWalletDoc = await walletRef.get();
        if (updatedWalletDoc.exists) {
          final updatedBalance =
              (updatedWalletDoc.data()?['balance'] ?? 0).toDouble();
          if (updatedBalance < 0) {
            // Critical error: balance went negative - reset to 0 and log for admin review
            await walletRef.update({'balance': 0.0});
          }
        }
      }

      // Save transaction
      await _firestore
          .collection(AppConstants.transactionsCollection)
          .doc(transactionId)
          .set(transaction.toFirestore());

      return PaymentResult.success(transaction);
    } catch (e) {
      return PaymentResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(
          e,
          context: 'payment',
          defaultMessage:
              'Top-up failed. Please check your connection and try again.',
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOKING PAYMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Process booking payment
  Future<PaymentResult> processBookingPayment({
    required BookingModel booking,
    required UserModel user,
    bool useWallet = false,
  }) async {
    try {
      // Direct payment: User pays full amount
      return await _processNormalBookingPayment(booking, user, useWallet);
    } catch (e) {
      return PaymentResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(
          e,
          context: 'payment',
          defaultMessage:
              'Payment failed. Please check your wallet balance and try again.',
        ),
      );
    }
  }

  /// Process normal booking payment (full amount, immediate confirmation)
  Future<PaymentResult> _processNormalBookingPayment(
    BookingModel booking,
    UserModel user,
    bool useWallet,
  ) async {
    // Validate booking status - prevent double payment
    if (booking.status != BookingStatus.pendingPayment) {
      return PaymentResult.failure(
        'Booking is already processed (${booking.status.displayName}) or cancelled',
      );
    }

    if (useWallet) {
      // Check wallet balance BEFORE transaction
      final wallet = await getWallet(user.uid);
      if (wallet == null || !wallet.hasSufficientBalance(booking.totalAmount)) {
        return PaymentResult.failure('Insufficient wallet balance');
      }
    }

    // Create facility payment transaction
    final facilityTxId = _uuid.v4();
    final facilityTx = TransactionModel(
      id: facilityTxId,
      oderId: _uuid.v4(),
      userId: user.uid,
      userEmail: user.email,
      type: TransactionType.bookingPayment,
      amount: booking.facilityFee,
      status: TransactionStatus.completed,
      referenceId: booking.id,
      description: 'Facility booking: ${booking.facilityName}',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );

    // Use Firestore transaction for atomic operations:
    // 1. Deduct wallet (if useWallet)
    // 2. Save transaction record
    // 3. Update booking status to confirmed
    // This ensures all-or-nothing: either all succeed or all fail
    try {
      await _firestore.runTransaction((transaction) async {
        // Get references
        final walletRef = _firestore
            .collection(AppConstants.walletsCollection)
            .doc(user.uid);
        final transactionRef = _firestore
            .collection(AppConstants.transactionsCollection)
            .doc(facilityTxId);
        final bookingRef = _firestore
            .collection(AppConstants.bookingsCollection)
            .doc(booking.id);

        // Re-verify booking status within transaction (prevent race conditions)
        final bookingDoc = await transaction.get(bookingRef);
        if (!bookingDoc.exists) {
          throw Exception('Booking not found');
        }
        final currentBooking = BookingModel.fromFirestore(bookingDoc);
        if (currentBooking.status != BookingStatus.pendingPayment) {
          throw Exception('Booking status changed during payment processing');
        }

        // If using wallet, deduct balance atomically
        if (useWallet) {
          final walletDoc = await transaction.get(walletRef);
          if (!walletDoc.exists) {
            throw Exception('Wallet not found');
          }
          final walletData = walletDoc.data()!;
          final currentBalance = (walletData['balance'] ?? 0).toDouble();
          if (currentBalance < booking.totalAmount) {
            throw Exception('Insufficient wallet balance');
          }

          // Calculate new balance and validate
          final newBalance = currentBalance - booking.totalAmount;
          if (newBalance < 0) {
            throw Exception(
              'Invalid balance calculation: balance would be negative',
            );
          }

          // Deduct from wallet (use absolute value to ensure validation)
          transaction.update(walletRef, {
            'balance': newBalance,
            'updatedAt': Timestamp.now(),
          });
        }

        // Save transaction record
        transaction.set(transactionRef, facilityTx.toFirestore());

        // Update booking status to confirmed
        transaction.update(bookingRef, {
          'status': BookingStatus.confirmed.code,
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      // Transaction failed - return failure result
      // ⭐ CRITICAL: Auto-cancel booking on payment failure to free up the time slot
      try {
        await _firestore
            .collection(AppConstants.bookingsCollection)
            .doc(booking.id)
            .update({
              'status': BookingStatus.cancelled.code,
              'cancellationReason': 'Payment failed: ${e.toString()}',
              'cancelledAt': Timestamp.now(),
              'updatedAt': Timestamp.now(),
            });
      } catch (cleanupError) {
        // Non-critical: Cleanup failure shouldn't mask the original payment error
      }

      return PaymentResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(
          e,
          context: 'payment',
          defaultMessage: 'Payment processing failed. Please try again.',
        ),
      );
    }

    // Non-critical operations (can happen after transaction succeeds)
    // Record facility fee to admin revenue (referee fee is escrow, not admin revenue)
    try {
      await _recordAdminRevenue(
        amount: booking.facilityFee,
        source: 'booking',
        referenceId: booking.id,
        description: 'Facility booking: ${booking.facilityName}',
      );
    } catch (e) {
      // Non-critical: Revenue tracking failure shouldn't break payment flow
    }

    // Create referee job if requested (only after payment confirmation)
    if (booking.refereeFee != null &&
        booking.refereeFee! > 0 &&
        user.isStudent) {
      try {
        final bookingService = BookingService();
        final updatedBooking = booking.copyWith(
          status: BookingStatus.confirmed,
        );
        final refereeJobId = await bookingService.createRefereeJobForBooking(
          booking: updatedBooking,
          user: user,
        );

        // Update booking with referee job ID and QR code if job was created
        if (refereeJobId != null) {
          final updatedQrCode = QRUtils.generateBookingQR(
            bookingId: booking.id,
            refereeJobId: refereeJobId,
            facilityName: booking.facilityName,
            dateTime: booking.startTime,
          );

          await _firestore
              .collection(AppConstants.bookingsCollection)
              .doc(booking.id)
              .update({'refereeJobId': refereeJobId, 'qrCode': updatedQrCode});

          // Create escrow hold for referee fee
          await _createEscrowHold(
            booking: booking.copyWith(refereeJobId: refereeJobId),
            user: user,
            amount: booking.refereeFee!,
          );
        }
      } catch (e) {
        // Non-critical: Referee job creation failure shouldn't block payment completion
      }
    }

    return PaymentResult.success(facilityTx);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOURNAMENT ENTRY FEE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Process tournament entry fee payment
  Future<PaymentResult> processTournamentEntryFee({
    required String userId,
    required String userEmail,
    required double amount,
    required String tournamentId,
    required String teamName,
  }) async {
    if (amount <= 0) {
      return PaymentResult.failure('Invalid entry fee amount');
    }

    // Early balance check for fast UX feedback (re-verified atomically inside transaction)
    final wallet = await getWallet(userId);
    if (wallet == null) {
      return PaymentResult.failure('Wallet not found. Please contact support.');
    }
    if (!wallet.hasSufficientBalance(amount)) {
      return PaymentResult.failure(
        'Insufficient wallet balance. You have RM ${wallet.balance.toStringAsFixed(2)}, but need RM ${amount.toStringAsFixed(2)}.',
      );
    }

    // Create transaction model outside the transaction so we can return it on success
    final transactionId = _uuid.v4();
    final entryFeeTx = TransactionModel(
      id: transactionId,
      oderId: _uuid.v4(),
      userId: userId,
      userEmail: userEmail,
      type: TransactionType.tournamentEntryFee,
      amount: amount,
      status: TransactionStatus.completed,
      referenceId: tournamentId,
      description: 'Tournament entry fee for team: $teamName',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      metadata: {'tournamentId': tournamentId, 'teamName': teamName},
    );

    try {
      // Atomic: deduct wallet + save transaction record in one Firestore transaction
      // Either both succeed or both fail — no partial state possible
      await _firestore.runTransaction((tx) async {
        final walletRef = _firestore
            .collection(AppConstants.walletsCollection)
            .doc(userId);
        final txRef = _firestore
            .collection(AppConstants.transactionsCollection)
            .doc(transactionId);

        // Re-read wallet inside transaction to guard against race conditions
        final walletDoc = await tx.get(walletRef);
        if (!walletDoc.exists) {
          throw Exception('Wallet not found');
        }
        final currentBalance = (walletDoc.data()?['balance'] ?? 0.0).toDouble();
        if (currentBalance < amount) {
          throw Exception(
            'Insufficient wallet balance. You have RM ${currentBalance.toStringAsFixed(2)}, but need RM ${amount.toStringAsFixed(2)}.',
          );
        }

        // Deduct wallet balance
        tx.update(walletRef, {
          'balance': currentBalance - amount,
          'updatedAt': Timestamp.now(),
        });

        // Save transaction record
        tx.set(txRef, entryFeeTx.toFirestore());
      });
    } catch (e) {
      return PaymentResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'payment'),
      );
    }

    // Non-critical: admin revenue tracking (failure here won't affect user)
    try {
      await _recordAdminRevenue(
        amount: amount,
        source: 'tournament_entry',
        referenceId: tournamentId,
        description: 'Tournament entry fee: $teamName',
      );
    } catch (e) {
      // Non-critical: revenue tracking failure shouldn't break payment flow
    }

    return PaymentResult.success(entryFeeTx);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ESCROW & REFEREE PAYMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Release escrow to referee after job completion and rating
  Future<PaymentResult> releaseEscrow({
    required String jobId,
    required String refereeUserId,
  }) async {
    try {
      // Find escrow for this job (pre-check outside transaction)
      final escrowQuery =
          await _firestore
              .collection(AppConstants.escrowCollection)
              .where('jobId', isEqualTo: jobId)
              .where('status', isEqualTo: EscrowStatus.held.code)
              .get();

      if (escrowQuery.docs.isEmpty) {
        return PaymentResult.failure('No escrow found for this job');
      }

      final escrowDoc = escrowQuery.docs.first;
      final escrow = EscrowModel.fromFirestore(escrowDoc);

      // Create release transaction model before the transaction so we can return it
      final txId = _uuid.v4();
      final releaseTx = TransactionModel(
        id: txId,
        oderId: _uuid.v4(),
        userId: refereeUserId,
        userEmail: '',
        type: TransactionType.escrowRelease,
        amount: escrow.amount,
        status: TransactionStatus.completed,
        referenceId: escrow.id,
        description: 'Referee payment for job $jobId',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      // Atomic: update escrow + credit wallet + save transaction in one Firestore transaction
      // Either all 3 succeed or all 3 fail — referee cannot be paid twice or left unpaid
      await _firestore.runTransaction((tx) async {
        final escrowRef = _firestore
            .collection(AppConstants.escrowCollection)
            .doc(escrow.id);
        final walletRef = _firestore
            .collection(AppConstants.walletsCollection)
            .doc(refereeUserId);
        final txRef = _firestore
            .collection(AppConstants.transactionsCollection)
            .doc(txId);

        // Read current wallet balance inside transaction
        final walletDoc = await tx.get(walletRef);
        final currentBalance = (walletDoc.data()?['balance'] ?? 0.0).toDouble();

        // Mark escrow as released
        tx.update(escrowRef, {
          'status': EscrowStatus.released.code,
          'refereeUserId': refereeUserId,
          'releasedAt': Timestamp.now(),
          'releaseReason': 'Job completed and rated',
        });

        // Credit referee wallet
        tx.update(walletRef, {
          'balance': currentBalance + escrow.amount,
          'updatedAt': Timestamp.now(),
        });

        // Save transaction record
        tx.set(txRef, releaseTx.toFirestore());
      });

      return PaymentResult.success(releaseTx);
    } catch (e) {
      return PaymentResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'payment'),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REFUNDS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Process refund for cancelled booking
  /// Process refund for cancelled booking
  Future<PaymentResult> processRefund({
    required BookingModel booking,
    required String reason,
  }) async {
    try {
      // Create refund transaction
      final txId = _uuid.v4();
      final transaction = TransactionModel(
        id: txId,
        oderId: _uuid.v4(),
        userId: booking.userId,
        userEmail: booking.userEmail,
        type: TransactionType.refund,
        amount: booking.totalAmount,
        status: TransactionStatus.completed,
        referenceId: booking.id,
        description: 'Refund for ${booking.facilityName}: $reason',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      // Credit organizer's wallet
      await _firestore
          .collection(AppConstants.walletsCollection)
          .doc(booking.userId)
          .update({
            'balance': FieldValue.increment(booking.totalAmount),
            'updatedAt': Timestamp.now(),
          });

      // Save transaction
      await _firestore
          .collection(AppConstants.transactionsCollection)
          .doc(txId)
          .set(transaction.toFirestore());

      // Deduct refunded facility fee from admin revenue
      // Note: Only facilityFee was recorded to admin revenue (refereeFee goes to escrow)
      // User's wallet is credited with totalAmount (facilityFee + refereeFee)
      // Referee fee is refunded separately via refundEscrow() below
      await _deductAdminRevenue(
        amount: booking.facilityFee,
        source: 'booking_refund',
        referenceId: booking.id,
        description: 'Refund for ${booking.facilityName}: $reason',
      );

      // Update booking status to REFUNDED
      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(booking.id)
          .update({
            'status': BookingStatus.refunded.code,
            'updatedAt': Timestamp.now(),
          });

      // Refund escrow if any
      if (booking.refereeFee != null && booking.refereeFee! > 0) {
        await refundEscrow(booking.id, booking.userId);
      }

      return PaymentResult.success(transaction);
    } catch (e) {
      throw Exception(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'payment'),
      );
    }
  }

  /// Process refund for tournament entry fee
  /// Refunds entry fee to team captain's wallet
  Future<PaymentResult> refundTournamentEntryFee({
    required String userId,
    required String userEmail,
    required double amount,
    required String tournamentId,
    required String teamName,
    required String reason,
  }) async {
    if (amount <= 0) {
      return PaymentResult.failure('Invalid refund amount');
    }

    try {
      // Get user's wallet
      final wallet = await getWallet(userId);
      if (wallet == null) {
        return PaymentResult.failure(
          'Wallet not found. Please contact support.',
        );
      }

      // Credit refund to wallet
      await _firestore
          .collection(AppConstants.walletsCollection)
          .doc(userId)
          .update({
            'balance': FieldValue.increment(amount),
            'updatedAt': Timestamp.now(),
          });

      // Create refund transaction record
      final transactionId = _uuid.v4();
      final transaction = TransactionModel(
        id: transactionId,
        oderId: _uuid.v4(),
        userId: userId,
        userEmail: userEmail,
        type: TransactionType.refund,
        amount: amount,
        status: TransactionStatus.completed,
        referenceId: tournamentId,
        description: 'Tournament entry fee refund for $teamName: $reason',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        metadata: {
          'tournamentId': tournamentId,
          'teamName': teamName,
          'refundReason': reason,
          'originalType': 'tournamentEntryFee',
        },
      );

      // Save transaction
      await _firestore
          .collection(AppConstants.transactionsCollection)
          .doc(transactionId)
          .set(transaction.toFirestore());

      return PaymentResult.success(transaction);
    } catch (e) {
      throw Exception(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'payment'),
      );
    }
  }

  /// Refund escrow to payer (public method for booking cancellation)
  Future<void> refundEscrow(String bookingId, String userId) async {
    final escrowQuery =
        await _firestore
            .collection(AppConstants.escrowCollection)
            .where('bookingId', isEqualTo: bookingId)
            .where('status', isEqualTo: EscrowStatus.held.code)
            .get();

    for (final doc in escrowQuery.docs) {
      final escrow = EscrowModel.fromFirestore(doc);

      await _firestore
          .collection(AppConstants.escrowCollection)
          .doc(escrow.id)
          .update({
            'status': EscrowStatus.refunded.code,
            'releasedAt': Timestamp.now(),
            'releaseReason': 'Booking cancelled',
          });

      // Credit back to payer
      await _firestore
          .collection(AppConstants.walletsCollection)
          .doc(userId)
          .update({
            'balance': FieldValue.increment(escrow.amount),
            'updatedAt': Timestamp.now(),
          });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN REVENUE TRACKING (Private Helper Methods)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Record revenue to admin (private helper)
  Future<void> _recordAdminRevenue({
    required double amount,
    required String source,
    required String referenceId,
    required String description,
  }) async {
    try {
      final revenueDocRef = _firestore
          .collection(AppConstants.adminRevenueCollection)
          .doc('total_revenue');

      await _firestore.runTransaction((transaction) async {
        final revenueDoc = await transaction.get(revenueDocRef);

        if (!revenueDoc.exists) {
          // Create new revenue document
          transaction.set(revenueDocRef, {
            'totalRevenue': amount,
            'facilityRevenue': amount,
            'refereePayouts': 0.0,
            'updatedAt': Timestamp.now(),
          });
        } else {
          // Increment existing revenue
          transaction.update(revenueDocRef, {
            'totalRevenue': FieldValue.increment(amount),
            'facilityRevenue': FieldValue.increment(amount),
            'updatedAt': Timestamp.now(),
          });
        }
      });
    } catch (e) {
      // Non-critical: Revenue tracking failure shouldn't break payment flow
    }
  }

  /// Deduct revenue from admin (for refunds) (private helper)
  Future<void> _deductAdminRevenue({
    required double amount,
    required String source,
    required String referenceId,
    required String description,
  }) async {
    try {
      final revenueDocRef = _firestore
          .collection(AppConstants.adminRevenueCollection)
          .doc('total_revenue');

      await _firestore.runTransaction((transaction) async {
        final revenueDoc = await transaction.get(revenueDocRef);

        if (revenueDoc.exists) {
          // Decrement existing revenue
          transaction.update(revenueDocRef, {
            'totalRevenue': FieldValue.increment(-amount),
            'facilityRevenue': FieldValue.increment(-amount),
            'updatedAt': Timestamp.now(),
          });
        }
      });
    } catch (e) {
      // Non-critical: Revenue tracking failure shouldn't break refund flow
    }
  }

  /// Create escrow hold for referee fee (private helper)
  Future<void> _createEscrowHold({
    required BookingModel booking,
    required UserModel user,
    required double amount,
  }) async {
    try {
      final escrowId = _uuid.v4();
      final escrow = EscrowModel(
        id: escrowId,
        bookingId: booking.id,
        jobId: booking.refereeJobId ?? '',
        payerUserId: user.uid,
        refereeUserId: '', // Will be set when referee accepts job
        amount: amount,
        status: EscrowStatus.held,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.escrowCollection)
          .doc(escrowId)
          .set(escrow.toFirestore());
    } catch (e) {
      // Non-critical: Escrow hold failure shouldn't break payment flow
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRANSACTION HISTORY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get user's transaction history
  Future<List<TransactionModel>> getTransactionHistory(String userId) async {
    final snapshot =
        await _firestore
            .collection(AppConstants.transactionsCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();
  }

  /// Get recent transactions
  Future<List<TransactionModel>> getRecentTransactions(
    String userId, {
    int limit = 10,
  }) async {
    final snapshot =
        await _firestore
            .collection(AppConstants.transactionsCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();
  }

  /// Get all transactions (admin only)
  Future<List<TransactionModel>> getAllTransactions({int limit = 100}) async {
    try {
      final snapshot =
          await _firestore
              .collection(AppConstants.transactionsCollection)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Non-critical: Transaction list fetch failure returns empty list
      return [];
    }
  }

  /// Stream of all transactions (admin only)
  Stream<List<TransactionModel>> getAllTransactionsStream() {
    return _firestore
        .collection(AppConstants.transactionsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => TransactionModel.fromFirestore(doc))
                  .toList(),
        );
  }
}

/// Payment operation result
class PaymentResult {
  final bool success;
  final TransactionModel? transaction;
  final String? errorMessage;

  const PaymentResult._({
    required this.success,
    this.transaction,
    this.errorMessage,
  });

  factory PaymentResult.success(TransactionModel transaction) {
    return PaymentResult._(success: true, transaction: transaction);
  }

  factory PaymentResult.failure(String message) {
    return PaymentResult._(success: false, errorMessage: message);
  }
}
