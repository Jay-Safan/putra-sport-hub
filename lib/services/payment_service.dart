import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart' hide TransactionStatus, EscrowStatus;
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
  final NotificationService? _notificationService;

  PaymentService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService;

  // ═══════════════════════════════════════════════════════════════════════════
  // PRICING LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate price based on user type (Student vs Public)
  double calculatePrice({
    required double studentPrice,
    required double publicPrice,
    required String userEmail,
  }) {
    final isStudent =
        userEmail.toLowerCase().endsWith(AppConstants.studentEmailDomain);
    return isStudent ? studentPrice : publicPrice;
  }

  /// Get price tier label
  String getPriceTier(String userEmail) {
    final isStudent =
        userEmail.toLowerCase().endsWith(AppConstants.studentEmailDomain);
    return isStudent ? 'Student Rate' : 'Public Rate';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WALLET MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get user's wallet
  Future<WalletModel?> getWallet(String userId) async {
    final doc = await _firestore
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
      final transactionId = _uuid.v4();

      // Fetch user email from users collection
      String userEmail = '';
      try {
        final userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .get();
        if (userDoc.exists) {
          userEmail = userDoc.data()?['email'] ?? '';
        }
      } catch (e) {
        // Continue even if email fetch fails
        debugPrint('Warning: Could not fetch user email: $e');
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
          final updatedBalance = (updatedWalletDoc.data()?['balance'] ?? 0).toDouble();
          if (updatedBalance < 0) {
            // Critical error: balance went negative - log and alert
            debugPrint('🚨 CRITICAL: Wallet balance is negative for user $userId: RM $updatedBalance');
            // Reset to 0 and log for admin review
            await walletRef.update({'balance': 0.0});
            // In production, you'd want to alert admin here
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
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'payment', defaultMessage: 'Top-up failed. Please check your connection and try again.'),
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
      // UNIFIED LOGIC: Handle split bill vs normal booking
      if (booking.isSplitBill) {
        // Split bill: Organizer pays only their share
        return await _processSplitBillOrganizerPayment(booking, user, useWallet);
      } else {
        // Normal booking: User pays full amount
        return await _processNormalBookingPayment(booking, user, useWallet);
      }
    } catch (e) {
      return PaymentResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'payment', defaultMessage: 'Payment failed. Please check your wallet balance and try again.'),
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
            throw Exception('Invalid balance calculation: balance would be negative');
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
      // Log but don't fail payment - revenue tracking failure shouldn't break payment
      debugPrint('⚠️ Failed to record admin revenue: $e');
    }

    // Create referee job if requested (only after payment confirmation)
    if (booking.refereeFee != null && booking.refereeFee! > 0 && user.isStudent) {
      try {
        final bookingService = BookingService();
        final updatedBooking = booking.copyWith(status: BookingStatus.confirmed);
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
              .update({
            'refereeJobId': refereeJobId,
            'qrCode': updatedQrCode,
          });

          // Create escrow hold for referee fee
          await _createEscrowHold(
            booking: booking.copyWith(refereeJobId: refereeJobId),
            user: user,
            amount: booking.refereeFee!,
          );
        }
      } catch (e) {
        debugPrint('⚠️ Failed to create referee job after payment: $e');
        // Don't fail payment - referee job is optional
      }
    }

    return PaymentResult.success(facilityTx);
  }

  /// Process split bill organizer payment (only their share, stay pending until all paid)
  Future<PaymentResult> _processSplitBillOrganizerPayment(
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

    // Find organizer in participants list
    final organizerParticipant = booking.splitBillParticipants.firstWhere(
      (p) => p.email == user.email,
      orElse: () => SplitBillParticipant(
        oderId: user.uid,
        email: user.email,
        name: user.displayName,
        amount: 0,
        hasPaid: false,
      ),
    );

    // Check if organizer already paid
    if (organizerParticipant.hasPaid) {
      return PaymentResult.failure('You have already paid your share');
    }

    final organizerShare = organizerParticipant.amount;

    if (organizerShare <= 0) {
      return PaymentResult.failure('Invalid payment amount. Please refresh and try again.');
    }

    if (useWallet) {
      // Check wallet balance BEFORE transaction
      final wallet = await getWallet(user.uid);
      if (wallet == null || !wallet.hasSufficientBalance(organizerShare)) {
        return PaymentResult.failure(
          'Insufficient wallet balance. You need RM ${organizerShare.toStringAsFixed(2)} to pay your share.',
        );
      }
    }

    // Create payment transaction for organizer's share
    final facilityTxId = _uuid.v4();
    final facilityTx = TransactionModel(
      id: facilityTxId,
      oderId: _uuid.v4(),
      userId: user.uid,
      userEmail: user.email,
      type: TransactionType.bookingPayment,
      amount: organizerShare,
      status: TransactionStatus.completed,
      referenceId: booking.id,
      description: 'Split bill payment (your share) for ${booking.facilityName}',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );

    // Prepare updated participants list
    final updatedParticipants = List<SplitBillParticipant>.from(
      booking.splitBillParticipants,
    );
    final organizerIndex = updatedParticipants.indexWhere(
      (p) => p.email == user.email,
    );

    if (organizerIndex != -1) {
      // Update organizer's payment status
      updatedParticipants[organizerIndex] = updatedParticipants[organizerIndex].copyWith(
        hasPaid: true,
        paidAt: DateTime.now(),
      );
    }

    // Check if all participants will have paid after this payment
    final allPaid = updatedParticipants.every((p) => p.hasPaid);

    // Use Firestore transaction for atomic operations:
    // 1. Deduct wallet (if useWallet)
    // 2. Save transaction record
    // 3. Update booking with participant payment status
    // 4. Update booking status to confirmed (if all paid)
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

        // Re-verify organizer hasn't already paid (within transaction)
        final currentParticipants = currentBooking.splitBillParticipants;
        final currentOrganizerIndex = currentParticipants.indexWhere(
          (p) => p.email == user.email,
        );
        if (currentOrganizerIndex != -1 && currentParticipants[currentOrganizerIndex].hasPaid) {
          throw Exception('You have already paid your share');
        }

        // If using wallet, deduct balance atomically
        if (useWallet) {
          final walletDoc = await transaction.get(walletRef);
          if (!walletDoc.exists) {
            throw Exception('Wallet not found');
          }
          final walletData = walletDoc.data()!;
          final currentBalance = (walletData['balance'] ?? 0).toDouble();
          if (currentBalance < organizerShare) {
            throw Exception('Insufficient wallet balance');
          }
          
          // Deduct from wallet
          transaction.update(walletRef, {
            'balance': FieldValue.increment(-organizerShare),
            'updatedAt': Timestamp.now(),
          });
        }

        // Save transaction record
        transaction.set(transactionRef, facilityTx.toFirestore());

        // Update booking with organizer's payment status
        final updateData = <String, dynamic>{
          'splitBillParticipants': updatedParticipants.map((p) => p.toMap()).toList(),
          'updatedAt': Timestamp.now(),
        };

        // If all participants paid, also update status to confirmed
        if (allPaid) {
          updateData['status'] = BookingStatus.confirmed.code;
        }

        transaction.update(bookingRef, updateData);
      });
    } catch (e) {
      // Transaction failed - return failure result
      return PaymentResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(
          e,
          context: 'payment',
          defaultMessage: 'Payment processing failed. Please try again.',
        ),
      );
    }

    // Non-critical operations (can happen after transaction succeeds)
    // Record organizer's share to admin revenue
    try {
      await _recordAdminRevenue(
        amount: organizerShare,
        source: 'booking',
        referenceId: booking.id,
        description: 'Split bill organizer payment: ${booking.facilityName}',
      );
    } catch (e) {
      // Log but don't fail payment - revenue tracking failure shouldn't break payment
      debugPrint('⚠️ Failed to record admin revenue: $e');
    }

    // Note: Escrow for referee fee is created AFTER referee job is created
    // (when all participants have paid and booking is confirmed)
    // Booking status update is already handled in the transaction above

    // Create referee job if requested (only after all payments confirmed)
    // Note: allPaid is already checked in transaction, booking status is already updated
    if (allPaid && booking.refereeFee != null && booking.refereeFee! > 0 && user.isStudent) {
      try {
        final bookingService = BookingService();
        final updatedBooking = booking.copyWith(
          status: BookingStatus.confirmed,
          splitBillParticipants: updatedParticipants,
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
              .update({
            'refereeJobId': refereeJobId,
            'qrCode': updatedQrCode,
          });

          // Create escrow hold for referee fee (organizer pays this in full)
          await _createEscrowHold(
            booking: booking.copyWith(refereeJobId: refereeJobId),
            user: user,
            amount: booking.refereeFee!,
          );
        }
      } catch (e) {
        debugPrint('⚠️ Failed to create referee job after split bill payment: $e');
        // Don't fail payment - referee job is optional
      }
    }

    return PaymentResult.success(facilityTx);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN REVENUE TRACKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Record revenue to admin account
  /// This tracks all money that goes to the platform (admin)
  Future<void> _recordAdminRevenue({
    required double amount,
    required String source, // 'booking', 'tournament_entry', etc.
    String? referenceId, // bookingId, tournamentId, etc.
    String? description,
  }) async {
    try {
      const adminRevenueDocId = 'total_revenue'; // Single document for admin revenue
      
      final adminRevenueRef = _firestore
          .collection(AppConstants.adminRevenueCollection)
          .doc(adminRevenueDocId);
      
      final now = DateTime.now();
      
      // Use Firestore transaction for atomic update
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(adminRevenueRef);
        
        if (!doc.exists) {
          // Create initial admin revenue document
          transaction.set(adminRevenueRef, {
            'totalRevenue': amount,
            'facilityRevenue': source == 'booking' ? amount : 0.0,
            'tournamentRevenue': source == 'tournament_entry' ? amount : 0.0,
            'transactionCount': 1,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
            'lastTransaction': {
              'amount': amount,
              'source': source,
              'referenceId': referenceId,
              'description': description,
              'timestamp': Timestamp.fromDate(now),
            },
          });
        } else {
          // Update existing document
          final currentData = doc.data()!;
          final currentTotal = (currentData['totalRevenue'] as num?)?.toDouble() ?? 0.0;
          final currentFacility = (currentData['facilityRevenue'] as num?)?.toDouble() ?? 0.0;
          final currentTournament = (currentData['tournamentRevenue'] as num?)?.toDouble() ?? 0.0;
          final currentCount = (currentData['transactionCount'] as int?) ?? 0;
          
          transaction.update(adminRevenueRef, {
            'totalRevenue': currentTotal + amount,
            'facilityRevenue': source == 'booking' 
                ? currentFacility + amount 
                : currentFacility,
            'tournamentRevenue': source == 'tournament_entry' 
                ? currentTournament + amount 
                : currentTournament,
            'transactionCount': currentCount + 1,
            'updatedAt': Timestamp.fromDate(now),
            'lastTransaction': {
              'amount': amount,
              'source': source,
              'referenceId': referenceId,
              'description': description,
              'timestamp': Timestamp.fromDate(now),
            },
          });
        }
      });
      
      debugPrint('✅ Admin revenue recorded: RM${amount.toStringAsFixed(2)} from $source');
    } catch (e) {
      debugPrint('❌ Failed to record admin revenue: $e');
      // Don't throw - revenue recording failure shouldn't break payment flow
    }
  }

  /// Deduct from admin revenue (for refunds)
  Future<void> _deductAdminRevenue({
    required double amount,
    required String source,
    String? referenceId,
    String? description,
  }) async {
    try {
      const adminRevenueDocId = 'total_revenue';
      final adminRevenueRef = _firestore
          .collection(AppConstants.adminRevenueCollection)
          .doc(adminRevenueDocId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(adminRevenueRef);
        
        if (doc.exists) {
          final currentData = doc.data()!;
          final currentTotal = (currentData['totalRevenue'] as num?)?.toDouble() ?? 0.0;
          final currentFacility = (currentData['facilityRevenue'] as num?)?.toDouble() ?? 0.0;
          final currentTournament = (currentData['tournamentRevenue'] as num?)?.toDouble() ?? 0.0;
          
          transaction.update(adminRevenueRef, {
            'totalRevenue': (currentTotal - amount).clamp(0.0, double.infinity),
            'facilityRevenue': source == 'booking_refund'
                ? (currentFacility - amount).clamp(0.0, double.infinity)
                : currentFacility,
            'tournamentRevenue': source == 'tournament_refund'
                ? (currentTournament - amount).clamp(0.0, double.infinity)
                : currentTournament,
            'updatedAt': Timestamp.now(),
          });
        }
      });
      
      debugPrint('✅ Admin revenue deducted: RM${amount.toStringAsFixed(2)} for $source');
    } catch (e) {
      debugPrint('❌ Failed to deduct admin revenue: $e');
    }
  }

  /// Create escrow hold for referee fee
  Future<void> _createEscrowHold({
    required BookingModel booking,
    required UserModel user,
    required double amount,
  }) async {
    final escrowId = _uuid.v4();

    final escrow = EscrowModel(
      id: escrowId,
      bookingId: booking.id,
      jobId: booking.refereeJobId ?? '',
      payerUserId: user.uid,
      refereeUserId: '', // Will be assigned when referee accepts
      amount: amount,
      status: EscrowStatus.held,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.escrowCollection)
        .doc(escrowId)
        .set(escrow.toFirestore());

    // Create escrow transaction
    final txId = _uuid.v4();
    final transaction = TransactionModel(
      id: txId,
      oderId: _uuid.v4(),
      userId: user.uid,
      userEmail: user.email,
      type: TransactionType.refereePayment,
      amount: amount,
      status: TransactionStatus.completed,
      referenceId: escrowId,
      description: 'Referee fee escrow for booking ${booking.id}',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.transactionsCollection)
        .doc(txId)
        .set(transaction.toFirestore());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SPLIT BILL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Process split bill payment from participant
  Future<PaymentResult> processSplitBillPayment({
    required String bookingId,
    required String oderId,
    required String participantEmail,
    required double amount,
  }) async {
    try {
      final bookingDoc = await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        return PaymentResult.failure('Booking not found');
      }

      final booking = BookingModel.fromFirestore(bookingDoc);

      if (!booking.isSplitBill) {
        return PaymentResult.failure('This booking does not use split bill');
      }

      // Validate booking status - prevent payment on cancelled/completed bookings
      if (booking.status != BookingStatus.pendingPayment) {
        return PaymentResult.failure(
          'This booking is no longer accepting payments (${booking.status.displayName})',
        );
      }

      // Find and update participant
      final participantIndex = booking.splitBillParticipants
          .indexWhere((p) => p.oderId == oderId);

      if (participantIndex == -1) {
        return PaymentResult.failure('Participant not found');
      }

      final participant = booking.splitBillParticipants[participantIndex];
      if (participant.hasPaid) {
        return PaymentResult.failure('Already paid');
      }

      // Check participant's wallet balance BEFORE transaction
      final participantWallet = await getWallet(oderId);
      if (participantWallet == null || !participantWallet.hasSufficientBalance(amount)) {
        return PaymentResult.failure('Insufficient wallet balance. Please top up your wallet.');
      }

      // Prepare updated participants list
      final updatedParticipants = List<SplitBillParticipant>.from(
          booking.splitBillParticipants);
      updatedParticipants[participantIndex] = participant.copyWith(
        hasPaid: true,
        paidAt: DateTime.now(),
      );

      // Check if all participants will have paid after this payment
      final allPaid = updatedParticipants.every((p) => p.hasPaid);

      // Create payment transaction
      final participantTxId = _uuid.v4();
      final participantTx = TransactionModel(
        id: participantTxId,
        oderId: _uuid.v4(),
        userId: oderId,
        userEmail: participantEmail,
        type: TransactionType.bookingPayment,
        amount: amount,
        status: TransactionStatus.completed,
        referenceId: bookingId,
        description: 'Split bill payment (participant share) for ${booking.facilityName}',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      // Use Firestore transaction for atomic operations:
      // 1. Deduct wallet
      // 2. Save transaction record
      // 3. Update booking with participant payment status
      // 4. Update booking status to confirmed (if all paid)
      try {
        await _firestore.runTransaction((transaction) async {
          // Get references
          final walletRef = _firestore
              .collection(AppConstants.walletsCollection)
              .doc(oderId);
          final transactionRef = _firestore
              .collection(AppConstants.transactionsCollection)
              .doc(participantTxId);
          final bookingRef = _firestore
              .collection(AppConstants.bookingsCollection)
              .doc(bookingId);

          // Re-verify booking status within transaction (prevent race conditions)
          final bookingDoc = await transaction.get(bookingRef);
          if (!bookingDoc.exists) {
            throw Exception('Booking not found');
          }
          final currentBooking = BookingModel.fromFirestore(bookingDoc);
          if (currentBooking.status != BookingStatus.pendingPayment) {
            throw Exception('Booking status changed during payment processing');
          }

          // Re-verify participant hasn't already paid (within transaction)
          final currentParticipants = currentBooking.splitBillParticipants;
          final currentParticipantIndex = currentParticipants.indexWhere(
            (p) => p.oderId == oderId,
          );
          if (currentParticipantIndex == -1) {
            throw Exception('Participant not found');
          }
          if (currentParticipants[currentParticipantIndex].hasPaid) {
            throw Exception('Already paid');
          }

          // Deduct from participant's wallet atomically
          final walletDoc = await transaction.get(walletRef);
          if (!walletDoc.exists) {
            throw Exception('Wallet not found');
          }
          final walletData = walletDoc.data()!;
          final currentBalance = (walletData['balance'] ?? 0).toDouble();
          if (currentBalance < amount) {
            throw Exception('Insufficient wallet balance');
          }
          
          transaction.update(walletRef, {
            'balance': FieldValue.increment(-amount),
            'updatedAt': Timestamp.now(),
          });

          // Save transaction record
          transaction.set(transactionRef, participantTx.toFirestore());

          // Update booking with participant's payment status
          final updateData = <String, dynamic>{
            'splitBillParticipants': updatedParticipants.map((p) => p.toMap()).toList(),
            'updatedAt': Timestamp.now(),
          };

          // If all participants paid, also update status to confirmed
          if (allPaid) {
            updateData['status'] = BookingStatus.confirmed.code;
          }

          transaction.update(bookingRef, updateData);
        });
      } catch (e) {
        // Transaction failed - return failure result
        return PaymentResult.failure(
          ErrorHandler.getUserFriendlyErrorMessage(
            e,
            context: 'payment',
            defaultMessage: 'Payment processing failed. Please try again.',
          ),
        );
      }

      // Non-critical operations (can happen after transaction succeeds)
      // Record participant's share to admin revenue
      try {
        await _recordAdminRevenue(
          amount: amount,
          source: 'booking',
          referenceId: bookingId,
          description: 'Split bill participant payment: ${booking.facilityName}',
        );
      } catch (e) {
        // Log but don't fail payment - revenue tracking failure shouldn't break payment
        debugPrint('⚠️ Failed to record admin revenue: $e');
      }

      // AUTO-CONFIRMATION: If all participants paid, create referee job (already handled in transaction above)
      if (allPaid) {

        // Create referee job if requested (only after all payments confirmed)
        if (booking.refereeFee != null && booking.refereeFee! > 0) {
          try {
            // Fetch organizer's user model
            final organizerDoc = await _firestore
                .collection(AppConstants.usersCollection)
                .doc(booking.userId)
                .get();
            
            if (organizerDoc.exists) {
              final organizer = UserModel.fromFirestore(organizerDoc);
              
              if (organizer.isStudent) {
                final bookingService = BookingService();
                final updatedBooking = booking.copyWith(
                  status: BookingStatus.confirmed,
                  splitBillParticipants: updatedParticipants,
                );
                final refereeJobId = await bookingService.createRefereeJobForBooking(
                  booking: updatedBooking,
                  user: organizer,
                );

                // Update booking with referee job ID and QR code if job was created
                if (refereeJobId != null) {
                  final updatedQrCode = QRUtils.generateBookingQR(
                    bookingId: bookingId,
                    refereeJobId: refereeJobId,
                    facilityName: booking.facilityName,
                    dateTime: booking.startTime,
                  );

                  await _firestore
                      .collection(AppConstants.bookingsCollection)
                      .doc(bookingId)
                      .update({
                    'refereeJobId': refereeJobId,
                    'qrCode': updatedQrCode,
                  });

                  // Create escrow hold for referee fee (organizer pays this in full)
                  // Note: We need to get the updated booking to have refereeJobId
                  final updatedBookingForEscrow = booking.copyWith(
                    refereeJobId: refereeJobId,
                    status: BookingStatus.confirmed,
                    splitBillParticipants: updatedParticipants,
                  );
                  await _createEscrowHold(
                    booking: updatedBookingForEscrow,
                    user: organizer,
                    amount: booking.refereeFee!,
                  );
                }
              }
            }
          } catch (e) {
            debugPrint('⚠️ Failed to create referee job after split bill payment: $e');
            // Don't fail payment - referee job is optional
          }
        }

        // Notify organizer that participant paid
        if (_notificationService != null) {
          final paidCount = updatedParticipants.where((p) => p.hasPaid).length;
          await _notificationService.notifyParticipantPaid(
            organizerUserId: booking.userId,
            bookingId: bookingId,
            participantName: participantEmail.split('@').first,
            amount: amount,
            paidCount: paidCount,
            totalCount: updatedParticipants.length,
          );

          // If all paid, notify all participants that booking is confirmed
          if (allPaid) {
            final participantUserIds = updatedParticipants
                .map((p) => p.oderId)
                .where((id) => id.isNotEmpty)
                .toList();
            
            // Also include organizer
            participantUserIds.add(booking.userId);

            await _notificationService.notifySplitBillConfirmed(
              participantUserIds: participantUserIds,
              bookingId: bookingId,
              facilityName: booking.facilityName,
              startTime: booking.startTime,
            );
          }
        }
      } else {
        // Notify organizer that participant paid (but not all paid yet)
        if (_notificationService != null) {
          final paidCount = updatedParticipants.where((p) => p.hasPaid).length;
          await _notificationService.notifyParticipantPaid(
            organizerUserId: booking.userId,
            bookingId: bookingId,
            participantName: participantEmail.split('@').first,
            amount: amount,
            paidCount: paidCount,
            totalCount: updatedParticipants.length,
          );
        }
      }

      // Create transaction record for participant payment
      final txId = _uuid.v4();
      final transaction = TransactionModel(
        id: txId,
        oderId: _uuid.v4(),
        userId: oderId,
        userEmail: participantEmail,
        type: TransactionType.bookingPayment,
        amount: amount,
        status: TransactionStatus.completed,
        referenceId: bookingId,
        description: 'Split bill payment for ${booking.facilityName}',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.transactionsCollection)
          .doc(txId)
          .set(transaction.toFirestore());

      // Record participant's share to admin revenue
      await _recordAdminRevenue(
        amount: amount,
        source: 'booking',
        referenceId: bookingId,
        description: 'Split bill participant payment: ${booking.facilityName}',
      );

      return PaymentResult.success(transaction);
    } catch (e) {
      return PaymentResult.failure('Payment failed: ${e.toString()}');
    }
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

    try {
      // Check wallet balance
      final wallet = await getWallet(userId);
      if (wallet == null) {
        return PaymentResult.failure('Wallet not found. Please contact support.');
      }

      if (!wallet.hasSufficientBalance(amount)) {
        return PaymentResult.failure(
          'Insufficient wallet balance. You have RM ${wallet.balance.toStringAsFixed(2)}, but need RM ${amount.toStringAsFixed(2)}.',
        );
      }

      // Deduct from wallet
      await _firestore
          .collection(AppConstants.walletsCollection)
          .doc(userId)
          .update({
        'balance': FieldValue.increment(-amount),
        'updatedAt': Timestamp.now(),
      });

      // Create transaction record
      final transactionId = _uuid.v4();
      final transaction = TransactionModel(
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
        metadata: {
          'tournamentId': tournamentId,
          'teamName': teamName,
        },
      );

      // Save transaction
      await _firestore
          .collection(AppConstants.transactionsCollection)
          .doc(transactionId)
          .set(transaction.toFirestore());

      // Record tournament entry fee to admin revenue
      await _recordAdminRevenue(
        amount: amount,
        source: 'tournament_entry',
        referenceId: tournamentId,
        description: 'Tournament entry fee: $teamName',
      );

      return PaymentResult.success(transaction);
    } catch (e) {
      return PaymentResult.failure('Entry fee payment failed: ${e.toString()}');
    }
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
      // Find escrow for this job
      final escrowQuery = await _firestore
          .collection(AppConstants.escrowCollection)
          .where('jobId', isEqualTo: jobId)
          .where('status', isEqualTo: EscrowStatus.held.code)
          .get();

      if (escrowQuery.docs.isEmpty) {
        return PaymentResult.failure('No escrow found for this job');
      }

      final escrowDoc = escrowQuery.docs.first;
      final escrow = EscrowModel.fromFirestore(escrowDoc);

      // Update escrow status
      await _firestore
          .collection(AppConstants.escrowCollection)
          .doc(escrow.id)
          .update({
        'status': EscrowStatus.released.code,
        'refereeUserId': refereeUserId,
        'releasedAt': Timestamp.now(),
        'releaseReason': 'Job completed and rated',
      });

      // Credit referee's wallet
      await _firestore
          .collection(AppConstants.walletsCollection)
          .doc(refereeUserId)
          .update({
        'balance': FieldValue.increment(escrow.amount),
        'updatedAt': Timestamp.now(),
      });

      // Create release transaction
      final txId = _uuid.v4();
      final transaction = TransactionModel(
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

      await _firestore
          .collection(AppConstants.transactionsCollection)
          .doc(txId)
          .set(transaction.toFirestore());

      return PaymentResult.success(transaction);
    } catch (e) {
      return PaymentResult.failure('Escrow release failed: ${e.toString()}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REFUNDS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Process refund for cancelled booking
  /// Handles both normal bookings and split bill bookings
  Future<PaymentResult> processRefund({
    required BookingModel booking,
    required String reason,
  }) async {
    try {
      // SPLIT BILL REFUND: Refund all participants who paid
      if (booking.isSplitBill && booking.splitBillParticipants.isNotEmpty) {
        return await _processSplitBillRefund(booking, reason);
      }

      // NORMAL BOOKING REFUND: Refund organizer only
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
      return PaymentResult.failure('Refund failed: ${e.toString()}');
    }
  }

  /// Process refund for split bill booking - refund all participants who paid
  Future<PaymentResult> _processSplitBillRefund(
    BookingModel booking,
    String reason,
  ) async {
    final refundedParticipants = <String>[]; // Track who got refunded
    double totalRefunded = 0.0;

    // Refund each participant who has paid
    for (final participant in booking.splitBillParticipants) {
      if (participant.hasPaid && participant.amount > 0) {
        try {
          // Get participant's wallet
          final wallet = await getWallet(participant.oderId);
          if (wallet != null) {
            // Refund participant's share
            await _firestore
                .collection(AppConstants.walletsCollection)
                .doc(participant.oderId)
                .update({
              'balance': FieldValue.increment(participant.amount),
              'updatedAt': Timestamp.now(),
            });

            // Deduct participant's refund from admin revenue
            await _deductAdminRevenue(
              amount: participant.amount,
              source: 'booking_refund',
              referenceId: booking.id,
              description: 'Split bill refund for ${participant.name}',
            );

            // Create refund transaction for participant
            final participantTxId = _uuid.v4();
            final participantTx = TransactionModel(
              id: participantTxId,
              oderId: _uuid.v4(),
              userId: participant.oderId,
              userEmail: participant.email,
              type: TransactionType.refund,
              amount: participant.amount,
              status: TransactionStatus.completed,
              referenceId: booking.id,
              description: 'Split bill refund for ${booking.facilityName}: $reason',
              createdAt: DateTime.now(),
              completedAt: DateTime.now(),
            );

            await _firestore
                .collection(AppConstants.transactionsCollection)
                .doc(participantTxId)
                .set(participantTx.toFirestore());

            refundedParticipants.add(participant.email);
            totalRefunded += participant.amount;
          }
        } catch (e) {
          debugPrint('Error refunding participant ${participant.email}: $e');
          // Continue with other participants even if one fails
        }
      }
    }

    // Refund escrow if any (organizer pays referee fee)
    if (booking.refereeFee != null && booking.refereeFee! > 0) {
      await refundEscrow(booking.id, booking.userId);
    }

    // Update booking status to REFUNDED
    await _firestore
        .collection(AppConstants.bookingsCollection)
        .doc(booking.id)
        .update({
      'status': BookingStatus.refunded.code,
      'updatedAt': Timestamp.now(),
    });

    // Create a summary transaction record (for organizer/admin tracking)
    final summaryTxId = _uuid.v4();
    final summaryTx = TransactionModel(
      id: summaryTxId,
      oderId: _uuid.v4(),
      userId: booking.userId,
      userEmail: booking.userEmail,
      type: TransactionType.refund,
      amount: totalRefunded,
      status: TransactionStatus.completed,
      referenceId: booking.id,
      description: 'Split bill refund summary: ${refundedParticipants.length} participants refunded for ${booking.facilityName}: $reason',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.transactionsCollection)
        .doc(summaryTxId)
        .set(summaryTx.toFirestore());

    return PaymentResult.success(summaryTx);
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
        return PaymentResult.failure('Wallet not found. Please contact support.');
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
      return PaymentResult.failure('Entry fee refund failed: ${e.toString()}');
    }
  }

  /// Refund escrow to payer (public method for booking cancellation)
  Future<void> refundEscrow(String bookingId, String userId) async {
    final escrowQuery = await _firestore
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
  // TRANSACTION HISTORY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get user's transaction history
  Future<List<TransactionModel>> getTransactionHistory(String userId) async {
    final snapshot = await _firestore
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
    final snapshot = await _firestore
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
      final snapshot = await _firestore
          .collection(AppConstants.transactionsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get all transactions: $e');
      return [];
    }
  }

  /// Stream of all transactions (admin only)
  Stream<List<TransactionModel>> getAllTransactionsStream() {
    return _firestore
        .collection(AppConstants.transactionsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList());
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

