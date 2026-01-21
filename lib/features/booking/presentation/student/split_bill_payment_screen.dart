import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/booking_model.dart';

class SplitBillPaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String? participantOderId; // Optional, will find from email if not provided

  const SplitBillPaymentScreen({
    super.key,
    required this.bookingId,
    this.participantOderId,
  });

  @override
  ConsumerState<SplitBillPaymentScreen> createState() => _SplitBillPaymentScreenState();
}

class _SplitBillPaymentScreenState extends ConsumerState<SplitBillPaymentScreen> {
  bool _isPaying = false;

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingByIdProvider(widget.bookingId));
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Pay Your Share',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1F1A),
              Color(0xFF132E25),
              Color(0xFF1A3D32),
              Color(0xFF0D1F1A),
            ],
          ),
        ),
        child: SafeArea(
          child: bookingAsync.when(
            data: (booking) {
              if (booking == null) {
                return const Center(
                  child: Text('Booking not found', style: TextStyle(color: Colors.white)),
                );
              }

              if (!booking.isSplitBill) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 48),
                      const SizedBox(height: 16),
                      const Text('This booking does not support split bill', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                );
              }

              // Find participant
              final participant = booking.splitBillParticipants.firstWhere(
                (p) => (widget.participantOderId != null 
                        ? p.oderId == widget.participantOderId 
                        : p.email == user?.email),
                orElse: () => const SplitBillParticipant(
                  oderId: '',
                  email: '',
                  name: '',
                  amount: 0,
                ),
              );

              if (participant.email.isEmpty) {
                return const Center(
                  child: Text('Participant not found', style: TextStyle(color: Colors.white)),
                );
              }

              if (participant.hasPaid) {
                return _buildAlreadyPaidView(booking, participant);
              }

              return _buildPaymentView(booking, participant, user);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            ),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: $error', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentView(BookingModel booking, SplitBillParticipant participant, UserModel? user) {
    final participantId = participant.oderId.isEmpty 
        ? (user?.uid ?? '') 
        : participant.oderId;
    
    // Use current user's wallet if they match the participant
    final walletAsync = (participantId == user?.uid) ? ref.watch(walletProvider) : null;
    
    // Extract balance from wallet
    double balance = 0.0;
    bool isLoadingBalance = false;
    if (walletAsync != null) {
      balance = walletAsync.when(
        data: (w) => w?.balance ?? 0.0,
        loading: () {
          isLoadingBalance = true;
          return 0.0;
        },
        error: (_, __) => 0.0,
      );
    }
    
    final hasEnough = balance >= participant.amount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          
          // Booking Info Card
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.payment,
                        color: AppTheme.primaryGreen,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      booking.facilityName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${booking.sport.displayName} • ${booking.startTime.day}/${booking.startTime.month}/${booking.startTime.year}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Amount Card
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [
                      AppTheme.successGreen.withValues(alpha: 0.2),
                      AppTheme.successGreen.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.successGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Share',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RM ${participant.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    isLoadingBalance
                        ? const SizedBox(
                            height: 44,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (hasEnough 
                                  ? AppTheme.successGreen 
                                  : AppTheme.errorRed).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  hasEnough ? Icons.check_circle : Icons.warning,
                                  color: hasEnough 
                                      ? AppTheme.successGreen 
                                      : AppTheme.errorRed,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Wallet Balance: RM ${balance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: hasEnough 
                                        ? AppTheme.successGreen 
                                        : AppTheme.errorRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Payment Info
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.infoBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Once you pay, the organizer will receive a refund for your share',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Pay Button
          ElevatedButton(
            onPressed: (_isPaying || !hasEnough) ? null : () => _processPayment(participant),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
            ),
            child: _isPaying
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Pay Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          // Top Up Button (if insufficient balance)
          if (!hasEnough)
            OutlinedButton.icon(
              onPressed: () => context.push('/wallet/top-up'),
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Top Up Wallet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlreadyPaidView(BookingModel booking, SplitBillParticipant participant) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppTheme.successGreen,
              size: 64,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Payment Complete! ✅',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You have paid RM ${participant.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/booking/${widget.bookingId}');
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('View Booking Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(SplitBillParticipant participant) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isPaying = true);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final result = await paymentService.processSplitBillPayment(
        bookingId: widget.bookingId,
        oderId: participant.oderId.isEmpty ? user.uid : participant.oderId,
        participantEmail: participant.email,
        amount: participant.amount,
      );

      if (!mounted) return;

      setState(() => _isPaying = false);

      if (result.success) {
        // Show success and navigate
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        
        // Refresh booking to show updated status
        ref.invalidate(bookingByIdProvider(widget.bookingId));
        
        // Wait a bit then navigate
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.push('/booking/${widget.bookingId}');
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Payment failed'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}

