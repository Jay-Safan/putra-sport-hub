import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart' hide TransactionStatus;
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../data/models/transaction_model.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with TickerProviderStateMixin {
  // Track which transaction card is currently expanded (only one at a time)
  String? _expandedTransactionId;

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final transactionsAsync = ref.watch(transactionHistoryProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'SukanPay Wallet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => context.push('/wallet/topup'),
            tooltip: 'Top Up',
          ),
        ],
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Wallet Balance Card
                walletAsync.when(
                  data: (wallet) {
                    final user = ref.watch(currentUserProvider).valueOrNull;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.2),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              AppTheme.accentGold,
                                              Color(0xFFFFE082),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.accentGold
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_wallet,
                                          color: Color(0xFF5D4037),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'SukanPay',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          Text(
                                            user?.isStudent == true
                                                ? 'Student Wallet'
                                                : 'Sports Wallet',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.6,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Available Balance',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'RM',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (wallet?.balance ?? 0.0).toStringAsFixed(2),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                ],
                              ),
                              if (wallet != null &&
                                  wallet.escrowBalance > 0) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.lock_outline,
                                        color: Colors.white70,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'RM ${wallet.escrowBalance.toStringAsFixed(2)} in escrow',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  loading:
                      () => ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.12),
                                  Colors.white.withValues(alpha: 0.04),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  error: (_, __) {
                    final user = ref.watch(currentUserProvider).valueOrNull;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.12),
                                Colors.white.withValues(alpha: 0.04),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppTheme.accentGold,
                                          Color(0xFFFFD54F),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Color(0xFF5D4037),
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'SukanPay',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user?.isStudent == true
                                            ? 'Student Wallet'
                                            : 'Sports Wallet',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'RM',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '0.00',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 44,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -2,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Transaction History Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Transaction History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  color: Colors.white.withValues(alpha: 0.4),
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your transaction history will appear here',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children:
                          transactions
                              .map((tx) => _buildExpandableTransactionCard(tx))
                              .toList(),
                    );
                  },
                  loading:
                      () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                  error:
                      (error, stack) => Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Error loading transactions: $error',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Enhanced transaction card with expandable details
  Widget _buildExpandableTransactionCard(TransactionModel tx) {
    // Determine if transaction is a credit (incoming) or debit (outgoing)
    final isCredit = _isCreditTransaction(tx.type);
    final displayAmount = isCredit ? tx.amount : -tx.amount;
    final icon =
        isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final color = isCredit ? AppTheme.successGreen : AppTheme.errorRed;

    final isExpanded = _expandedTransactionId == tx.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            // Toggle expansion (collapse if already expanded, expand if collapsed)
            _expandedTransactionId = isExpanded ? null : tx.id;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: isExpanded ? 0.12 : 0.08),
                      Colors.white.withValues(alpha: isExpanded ? 0.08 : 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: isExpanded ? 0.18 : 0.12,
                    ),
                    width: isExpanded ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Main transaction info (always visible)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Transaction icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withValues(alpha: 0.25),
                                  color.withValues(alpha: 0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          const SizedBox(width: 16),

                          // Transaction details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.description.isNotEmpty
                                      ? tx.description
                                      : tx.type.displayName,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.98),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.4,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      _formatTransactionDate(tx.createdAt),
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    if (tx.status !=
                                        TransactionStatus.completed) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            tx.status,
                                          ).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: _getStatusColor(
                                              tx.status,
                                            ).withValues(alpha: 0.4),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          tx.status.displayName.toUpperCase(),
                                          style: TextStyle(
                                            color: _getStatusColor(tx.status),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Amount and chevron
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${displayAmount >= 0 ? '+' : '-'}RM ${displayAmount.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Animated chevron
                              AnimatedRotation(
                                duration: const Duration(milliseconds: 250),
                                turns: isExpanded ? 0.5 : 0,
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Expandable details section
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState:
                          isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: _buildTransactionDetails(tx),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build expanded transaction details section
  Widget _buildTransactionDetails(TransactionModel tx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Transaction details grid
          Column(
            children: [
              _buildDetailRow('Transaction ID', _formatTransactionId(tx.id)),
              _buildDetailRow('Status', tx.status.displayName),
              _buildDetailRow('Full Date', _formatFullDate(tx.createdAt)),
              if (tx.referenceId != null)
                _buildDetailRow('Reference', _formatReference(tx)),
              if (tx.metadata != null && tx.metadata!.isNotEmpty)
                ..._buildMetadataRows(tx.metadata!),
            ],
          ),
        ],
      ),
    );
  }

  /// Build detail row for expanded section
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build metadata rows from transaction metadata
  List<Widget> _buildMetadataRows(Map<String, dynamic> metadata) {
    final List<Widget> rows = [];

    // Handle specific metadata keys with friendly names
    metadata.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        final String friendlyKey = _getFriendlyMetadataKey(key);
        rows.add(_buildDetailRow(friendlyKey, value.toString()));
      }
    });

    return rows;
  }

  /// Convert metadata keys to friendly display names
  String _getFriendlyMetadataKey(String key) {
    switch (key.toLowerCase()) {
      case 'paymentmethod':
        return 'Payment Method';
      case 'facilityname':
        return 'Facility';
      case 'bookingdate':
        return 'Booking Date';
      case 'courtname':
        return 'Court';
      case 'tournamentname':
        return 'Tournament';
      case 'matchtype':
        return 'Match Type';
      default:
        // Convert camelCase to Title Case
        return key
            .replaceAllMapped(
              RegExp(r'^[a-z]|[A-Z]'),
              (match) => match.group(0)!.toUpperCase(),
            )
            .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
            .trim();
    }
  }

  /// Format transaction ID for display (shortened)
  String _formatTransactionId(String id) {
    if (id.length > 8) {
      return 'TX-${id.substring(0, 8).toUpperCase()}';
    }
    return 'TX-${id.toUpperCase()}';
  }

  /// Format full date and time
  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Format reference information based on transaction type
  String _formatReference(TransactionModel tx) {
    if (tx.referenceId == null) return '-';

    switch (tx.type) {
      case TransactionType.bookingPayment:
        return 'Booking ${tx.referenceId!.substring(0, 8).toUpperCase()}';
      case TransactionType.tournamentEntryFee:
        return 'Tournament ${tx.referenceId!.substring(0, 8).toUpperCase()}';
      case TransactionType.refereePayment:
        return 'Job ${tx.referenceId!.substring(0, 8).toUpperCase()}';
      default:
        return tx.referenceId!.substring(0, 8).toUpperCase();
    }
  }

  /// Helper method to determine if transaction is credit (incoming money)
  bool _isCreditTransaction(TransactionType type) {
    switch (type) {
      case TransactionType.topUp:
      case TransactionType.refund:
      case TransactionType.refereePayment:
      case TransactionType.escrowRelease:
        return true; // Incoming money
      case TransactionType.bookingPayment:
      case TransactionType.tournamentEntryFee:
        return false; // Outgoing money
    }
  }

  /// Get status color for transaction status badge
  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return Colors.orange;
      case TransactionStatus.completed:
        return AppTheme.successGreen;
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return AppTheme.errorRed;
      case TransactionStatus.refunded:
        return Colors.blue;
    }
  }

  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
