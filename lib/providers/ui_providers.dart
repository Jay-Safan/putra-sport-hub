import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/utils/network_utils.dart';

// ═══════════════════════════════════════════════════════════════════════════
// UI STATE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Current bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// Splash screen start time provider (tracks when splash was first shown)
final splashStartTimeProvider = StateProvider<DateTime?>((ref) => null);

/// Theme mode provider
final themeModeProvider = StateProvider<bool>((ref) => false); // false = light

/// Loading state provider
final isLoadingProvider = StateProvider<bool>((ref) => false);

// ═══════════════════════════════════════════════════════════════════════════
// NETWORK PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Network connectivity status stream provider
/// Returns `List<ConnectivityResult>` - may contain multiple connection types
final connectivityStatusProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) {
  return NetworkUtils.connectivityStream;
});

/// Is connected to internet provider (simplified boolean)
final isConnectedProvider = StreamProvider<bool>((ref) async* {
  await for (final connectivityResults in NetworkUtils.connectivityStream) {
    // If no connectivity or only 'none', return false
    yield connectivityResults.isNotEmpty &&
        !connectivityResults.contains(ConnectivityResult.none);
  }
});
