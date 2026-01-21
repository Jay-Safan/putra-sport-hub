import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';

/// Transaction model for SukanPay financial system
class TransactionModel {
  final String id;
  final String oderId;
  final String userId;
  final String userEmail;
  final TransactionType type;
  final double amount;
  final String currency;
  final TransactionStatus status;
  final String? referenceId; // Booking ID, Job ID, etc.
  final String description;
  final String? fromWalletId;
  final String? toWalletId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  const TransactionModel({
    required this.id,
    required this.oderId,
    required this.userId,
    required this.userEmail,
    required this.type,
    required this.amount,
    this.currency = 'MYR',
    required this.status,
    this.referenceId,
    required this.description,
    this.fromWalletId,
    this.toWalletId,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  /// Check if transaction is successful
  bool get isSuccessful => status == TransactionStatus.completed;

  /// Check if transaction is pending
  bool get isPending =>
      status == TransactionStatus.pending ||
      status == TransactionStatus.processing;

  /// Get formatted amount with currency
  String get formattedAmount => 'RM ${amount.toStringAsFixed(2)}';

  /// Factory constructor from Firestore
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      oderId: data['oderId'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      type: TransactionType.fromCode(data['type'] ?? 'BOOKING'),
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'MYR',
      status: TransactionStatus.fromCode(data['status'] ?? 'PENDING'),
      referenceId: data['referenceId'],
      description: data['description'] ?? '',
      fromWalletId: data['fromWalletId'],
      toWalletId: data['toWalletId'],
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'oderId': oderId,
      'userId': userId,
      'userEmail': userEmail,
      'type': type.code,
      'amount': amount,
      'currency': currency,
      'status': status.code,
      'referenceId': referenceId,
      'description': description,
      'fromWalletId': fromWalletId,
      'toWalletId': toWalletId,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'metadata': metadata,
    };
  }

  TransactionModel copyWith({
    TransactionStatus? status,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      id: id,
      oderId: oderId,
      userId: userId,
      userEmail: userEmail,
      type: type,
      amount: amount,
      currency: currency,
      status: status ?? this.status,
      referenceId: referenceId,
      description: description,
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: ${type.displayName}, amount: $formattedAmount)';
  }
}

/// Transaction status
enum TransactionStatus {
  pending('PENDING', 'Pending'),
  processing('PROCESSING', 'Processing'),
  completed('COMPLETED', 'Completed'),
  failed('FAILED', 'Failed'),
  refunded('REFUNDED', 'Refunded'),
  cancelled('CANCELLED', 'Cancelled');

  final String code;
  final String displayName;
  const TransactionStatus(this.code, this.displayName);

  static TransactionStatus fromCode(String code) {
    return TransactionStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => TransactionStatus.pending,
    );
  }
}

/// Wallet model for user balance management
class WalletModel {
  final String id;
  final String userId;
  final double balance;
  final double escrowBalance;
  final double pendingBalance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletModel({
    required this.id,
    required this.userId,
    this.balance = 0.0,
    this.escrowBalance = 0.0,
    this.pendingBalance = 0.0,
    this.currency = 'MYR',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get total available balance
  double get availableBalance => balance;

  /// Get total frozen balance (escrow + pending)
  double get frozenBalance => escrowBalance + pendingBalance;

  /// Get formatted balance
  String get formattedBalance => 'RM ${balance.toStringAsFixed(2)}';

  /// Check if wallet has sufficient balance
  bool hasSufficientBalance(double amount) => balance >= amount;

  /// Factory constructor from Firestore
  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      balance: (data['balance'] ?? 0).toDouble(),
      escrowBalance: (data['escrowBalance'] ?? 0).toDouble(),
      pendingBalance: (data['pendingBalance'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'MYR',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'balance': balance,
      'escrowBalance': escrowBalance,
      'pendingBalance': pendingBalance,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  WalletModel copyWith({
    double? balance,
    double? escrowBalance,
    double? pendingBalance,
  }) {
    return WalletModel(
      id: id,
      userId: userId,
      balance: balance ?? this.balance,
      escrowBalance: escrowBalance ?? this.escrowBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      currency: currency,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'WalletModel(userId: $userId, balance: $formattedBalance)';
  }
}

/// Escrow model for referee fee holding
class EscrowModel {
  final String id;
  final String bookingId;
  final String jobId;
  final String payerUserId;
  final String refereeUserId;
  final double amount;
  final EscrowStatus status;
  final DateTime createdAt;
  final DateTime? releasedAt;
  final String? releaseReason;

  const EscrowModel({
    required this.id,
    required this.bookingId,
    required this.jobId,
    required this.payerUserId,
    required this.refereeUserId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.releasedAt,
    this.releaseReason,
  });

  /// Check if escrow is still held
  bool get isHeld => status == EscrowStatus.held;

  /// Factory constructor from Firestore
  factory EscrowModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EscrowModel(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      jobId: data['jobId'] ?? '',
      payerUserId: data['payerUserId'] ?? '',
      refereeUserId: data['refereeUserId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      status: EscrowStatus.fromCode(data['status'] ?? 'HELD'),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      releasedAt: (data['releasedAt'] as Timestamp?)?.toDate(),
      releaseReason: data['releaseReason'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'jobId': jobId,
      'payerUserId': payerUserId,
      'refereeUserId': refereeUserId,
      'amount': amount,
      'status': status.code,
      'createdAt': Timestamp.fromDate(createdAt),
      'releasedAt':
          releasedAt != null ? Timestamp.fromDate(releasedAt!) : null,
      'releaseReason': releaseReason,
    };
  }

  EscrowModel copyWith({
    EscrowStatus? status,
    DateTime? releasedAt,
    String? releaseReason,
  }) {
    return EscrowModel(
      id: id,
      bookingId: bookingId,
      jobId: jobId,
      payerUserId: payerUserId,
      refereeUserId: refereeUserId,
      amount: amount,
      status: status ?? this.status,
      createdAt: createdAt,
      releasedAt: releasedAt ?? this.releasedAt,
      releaseReason: releaseReason ?? this.releaseReason,
    );
  }

  @override
  String toString() {
    return 'EscrowModel(id: $id, amount: RM ${amount.toStringAsFixed(2)}, status: ${status.displayName})';
  }
}

/// Escrow status
enum EscrowStatus {
  held('HELD', 'Held'),
  released('RELEASED', 'Released to Referee'),
  refunded('REFUNDED', 'Refunded to Payer'),
  disputed('DISPUTED', 'Under Dispute');

  final String code;
  final String displayName;
  const EscrowStatus(this.code, this.displayName);

  static EscrowStatus fromCode(String code) {
    return EscrowStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => EscrowStatus.held,
    );
  }
}

