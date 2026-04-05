import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chatbot_service.dart';
import 'auth_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CHATBOT PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Chat history provider (session-based, cleared on app restart)
/// Stores conversation history per user during app session
/// Messages persist when navigating away and coming back to chatbot
/// Each user's chat is preserved when switching accounts (session-based)
final chatHistoryProvider =
    StateNotifierProvider<ChatHistoryNotifier, Map<String, List<ChatMessage>>>((
      ref,
    ) {
      return ChatHistoryNotifier();
    });

/// Provider that exposes only the current user's messages
final currentUserMessagesProvider = Provider<List<ChatMessage>>((ref) {
  final chatHistory = ref.watch(chatHistoryProvider);
  final currentUser = ref.watch(currentUserProvider).valueOrNull;

  if (currentUser == null) return [];

  return chatHistory[currentUser.uid] ?? [];
});

/// Chat history notifier - stores messages per user
class ChatHistoryNotifier
    extends StateNotifier<Map<String, List<ChatMessage>>> {
  ChatHistoryNotifier() : super({});

  /// Add a single message to chat history for a specific user
  void addMessage(ChatMessage message) {
    if (message.userId == null) return;

    final userMessages = state[message.userId] ?? [];
    state = {
      ...state,
      message.userId!: [...userMessages, message],
    };
  }

  /// Add multiple messages to chat history for a specific user
  void addMessages(List<ChatMessage> messages, String userId) {
    final userMessages = state[userId] ?? [];
    state = {
      ...state,
      userId: [...userMessages, ...messages],
    };
  }

  /// Clear all chat history (all users)
  void clearHistory() {
    state = {};
  }

  /// Clear chat history for a specific user
  void clearUserHistory(String userId) {
    final newState = Map<String, List<ChatMessage>>.from(state);
    newState.remove(userId);
    state = newState;
  }

  /// Remove a specific message by ID
  void removeMessage(String messageId, String userId) {
    final userMessages = state[userId] ?? [];
    state = {
      ...state,
      userId: userMessages.where((m) => m.id != messageId).toList(),
    };
  }

  /// Get conversation history excluding welcome messages for a specific user
  /// Used for sending context to AI API
  List<ChatMessage> getConversationHistory(String? userId) {
    if (userId == null) return [];
    final userMessages = state[userId] ?? [];
    return userMessages.where((m) => m.type != MessageType.welcome).toList();
  }

  /// Check if welcome message exists for a specific user
  bool hasWelcomeMessage(String? userId) {
    if (userId == null) return false;
    final userMessages = state[userId] ?? [];
    return userMessages.any((m) => m.type == MessageType.welcome);
  }

  /// Get messages for a specific user
  List<ChatMessage> getMessagesForUser(String? userId) {
    if (userId == null) return [];
    return state[userId] ?? [];
  }
}
