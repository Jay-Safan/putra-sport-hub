// ═══════════════════════════════════════════════════════════════════════════
// CENTRAL PROVIDERS FILE
// ═══════════════════════════════════════════════════════════════════════════
// This file re-exports all feature-based providers to ensure existing imports
// continue to work unchanged. Providers are now organized by feature in
// separate files for better maintainability.
// ═══════════════════════════════════════════════════════════════════════════

// Service providers (core services)
export 'service_providers.dart';

// Auth providers (authentication & user state)
export 'auth_providers.dart';

// Booking providers (facilities, bookings, weather)
export 'booking_providers.dart';

// Referee providers (jobs, ratings, certifications)
export 'referee_providers.dart';

// Merit providers (merit records & points)
export 'merit_providers.dart';

// Payment providers (wallet & transactions)
export 'payment_providers.dart';

// Tournament providers (tournament management)
export 'tournament_providers.dart';

// Admin providers (stats & management)
export 'admin_providers.dart';

// Notification providers (notifications & unread counts)
export 'notification_providers.dart';

// Chatbot providers (AI chat history)
export 'chatbot_providers.dart';

// UI providers (UI state, theme, network)
export 'ui_providers.dart';
