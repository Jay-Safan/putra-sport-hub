import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';
import 'auth_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PAYMENT & WALLET PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// User's wallet provider
final walletProvider = StreamProvider((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(paymentServiceProvider).walletStream(user.uid);
});

/// Transaction history provider
final transactionHistoryProvider = FutureProvider((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  return ref.watch(paymentServiceProvider).getTransactionHistory(user.uid);
});
