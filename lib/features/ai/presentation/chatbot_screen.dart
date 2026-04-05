import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/api_keys.dart';
import '../../../features/auth/data/models/user_model.dart';
import '../../../providers/providers.dart';
import '../../../services/chatbot_service.dart';

/// Modern Chatbot Screen - Clean & Minimalist AI Assistant
class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  // Removed: final List<ChatMessage> _messages = []; - now using provider
  final Uuid _uuid = const Uuid();

  bool _isLoading = false;
  bool _showQuickActions = true;
  BookingIntent? _currentBookingIntent;
  String? _suggestedFacilityId;
  late ChatbotService _chatbotService;

  // Typing indicator animation
  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();

    // Initialize chatbot service with safe API key access
    try {
      final geminiKey = ApiKeys.gemini;
      _chatbotService = ChatbotService(
        apiKey: geminiKey.isEmpty ? null : geminiKey,
      );
    } catch (e) {
      // If dotenv not loaded (web), create service without API key (uses fallback)
      _chatbotService = ChatbotService(apiKey: null);
    }

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Only add welcome message if history is empty (first time opening)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      final messages = ref
          .read(chatHistoryProvider.notifier)
          .getMessagesForUser(user?.uid);

      if (messages.isEmpty) {
        _addWelcomeMessage();
      } else {
        // History exists - check if welcome message is already there
        final hasWelcome = ref
            .read(chatHistoryProvider.notifier)
            .hasWelcomeMessage(user?.uid);
        if (!hasWelcome) {
          _addWelcomeMessage();
        }
        // Show quick actions only if last message is welcome or very old
        setState(() {
          _showQuickActions = messages.length <= 2;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final user = ref.read(currentUserProvider).valueOrNull;
    final welcomeMessage = _chatbotService.getWelcomeMessage(user);

    final welcomeMsg = ChatMessage(
      id: _uuid.v4(),
      content: welcomeMessage,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.welcome,
      userId: user?.uid,
    );

    ref.read(chatHistoryProvider.notifier).addMessage(welcomeMsg);
  }

  Future<void> _sendMessage([String? quickMessage]) async {
    final messageText = (quickMessage ?? _messageController.text).trim();
    if (messageText.isEmpty || _isLoading) return;

    setState(() {
      _showQuickActions = false;
    });

    final user = ref.read(currentUserProvider).valueOrNull;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: messageText,
      isUser: true,
      timestamp: DateTime.now(),
      userId: user?.uid,
    );

    // Add to provider instead of local state
    ref.read(chatHistoryProvider.notifier).addMessage(userMessage);
    setState(() {
      _isLoading = true;
      _messageController.clear();
    });

    _scrollToBottom();

    final messages = ref
        .read(chatHistoryProvider.notifier)
        .getMessagesForUser(user?.uid);
    final bookingIntent = _chatbotService.parseBookingIntent(
      messageText,
      messages,
    );

    if (bookingIntent != null) {
      await _handleBookingIntent(bookingIntent, user);
      return;
    }

    try {
      final conversationHistory = ref
          .read(chatHistoryProvider.notifier)
          .getConversationHistory(user?.uid);
      final response = await _chatbotService.getResponse(
        userMessage: messageText,
        conversationHistory: conversationHistory,
        user: user,
      );

      if (mounted) {
        ref
            .read(chatHistoryProvider.notifier)
            .addMessage(
              ChatMessage(
                id: _uuid.v4(),
                content: response,
                isUser: false,
                timestamp: DateTime.now(),
                userId: user?.uid,
              ),
            );
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ref
            .read(chatHistoryProvider.notifier)
            .addMessage(
              ChatMessage(
                id: _uuid.v4(),
                content: 'Oops! Something went wrong. Please try again.',
                isUser: false,
                timestamp: DateTime.now(),
                userId: user?.uid,
              ),
            );
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _handleBookingIntent(
    BookingIntent intent,
    UserModel? user,
  ) async {
    setState(() {
      _currentBookingIntent = intent;
    });

    if (intent.sport != null) {
      try {
        final facilities = await ref.read(
          facilitiesBySportProvider(intent.sport!).future,
        );

        if (facilities.isNotEmpty) {
          _suggestedFacilityId = facilities.first.id;
          final response = _chatbotService.getBookingAssistantResponse(
            intent,
            facilities,
            user,
          );

          if (mounted) {
            ref
                .read(chatHistoryProvider.notifier)
                .addMessage(
                  ChatMessage(
                    id: _uuid.v4(),
                    content: response,
                    isUser: false,
                    timestamp: DateTime.now(),
                    type: MessageType.booking,
                  ),
                );
            setState(() {
              _isLoading = false;
            });
            _scrollToBottom();
          }
        } else {
          _addBotMessage(
            'No facilities found for ${intent.sport!.displayName}. Try browsing from Home!',
          );
        }
      } catch (e) {
        _addBotMessage('Error finding facilities. Please try again.');
      }
    } else {
      final response = _chatbotService.getBookingAssistantResponse(
        intent,
        null,
        user,
      );
      _addBotMessage(response);
    }
  }

  void _addBotMessage(String content, {MessageType type = MessageType.text}) {
    if (mounted) {
      ref
          .read(chatHistoryProvider.notifier)
          .addMessage(
            ChatMessage(
              id: _uuid.v4(),
              content: content,
              isUser: false,
              timestamp: DateTime.now(),
              type: type,
            ),
          );
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleBookNow() {
    if (_suggestedFacilityId != null) {
      context.push('/booking/facility/$_suggestedFacilityId');
    } else if (_currentBookingIntent?.sport != null) {
      context.push('/booking/sport/${_currentBookingIntent!.sport!.code}');
    } else {
      context.go('/home');
    }
  }

  String _formatTimestamp(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    // Watch provider for current user's messages
    final messages = ref.watch(currentUserMessagesProvider);
    final quickActions = _chatbotService.getQuickActions('', user: user);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0A1F1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D2920), Color(0xFF0A1F1A), Color(0xFF081915)],
          ),
        ),
        child: SafeArea(
          bottom: true,
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount:
                      messages.length +
                      (_isLoading ? 1 : 0) +
                      (_showQuickActions ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Quick actions at the end
                    if (_showQuickActions &&
                        index == messages.length + (_isLoading ? 1 : 0)) {
                      return _buildQuickActions(quickActions);
                    }
                    // Loading indicator
                    if (_isLoading && index == messages.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(messages[index], index);
                  },
                ),
              ),

              // Input area
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white70,
                size: 16,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Bot avatar with status
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen,
                      AppTheme.primaryGreen.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0A1F1A),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PutraBot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'AI Assistant • Online',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Menu button
          IconButton(
            onPressed: () {
              // Could add menu options here
            },
            icon: Icon(
              Icons.more_vert,
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(List<String> actions) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                actions.map((action) {
                  return GestureDetector(
                    onTap: () => _sendMessage(action),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        action,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final messages = ref.read(currentUserMessagesProvider);
    final isUser = message.isUser;
    final showTimestamp =
        index == messages.length - 1 ||
        (index < messages.length - 1 &&
            messages[index + 1].isUser != message.isUser);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bot avatar
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, bottom: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryGreen.withValues(alpha: 0.8),
                        AppTheme.primaryGreen.withValues(alpha: 0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],

              // Message bubble
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient:
                        isUser
                            ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryGreen,
                                Color(0xFF1B5E4A),
                              ],
                            )
                            : null,
                    color: isUser ? null : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border:
                        isUser
                            ? null
                            : Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                              width: 1,
                            ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message text with markdown-like formatting
                      _buildFormattedText(message.content, isUser),

                      // Booking action button
                      if (!isUser &&
                          message.type == MessageType.booking &&
                          _suggestedFacilityId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _handleBookNow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryGreen,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Book Now',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // User avatar
              if (isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(left: 8, bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 14,
                  ),
                ),
              ],
            ],
          ),

          // Timestamp
          if (showTimestamp)
            Padding(
              padding: EdgeInsets.only(
                top: 6,
                left: isUser ? 0 : 36,
                right: isUser ? 36 : 0,
                bottom: 8,
              ),
              child: Text(
                _formatTimestamp(message.timestamp),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildFormattedText(String text, bool isUser) {
    // Simple markdown-like formatting
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          lines.map((line) {
            // Headers (##)
            if (line.startsWith('## ')) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line.substring(3),
                  style: TextStyle(
                    color:
                        isUser
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.95),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              );
            }

            // Bold (**text**)
            if (line.contains('**')) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _buildBoldText(line, isUser),
              );
            }

            // Bullet points
            if (line.startsWith('• ') ||
                line.startsWith('- ') ||
                line.startsWith('✅ ') ||
                line.startsWith('❌ ')) {
              return Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  line,
                  style: TextStyle(
                    color:
                        isUser
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              );
            }

            // Regular text
            return Text(
              line,
              style: TextStyle(
                color:
                    isUser
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                height: 1.5,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildBoldText(String text, bool isUser) {
    final parts = text.split('**');
    return RichText(
      text: TextSpan(
        children:
            parts.asMap().entries.map((entry) {
              final isBold = entry.key % 2 == 1;
              return TextSpan(
                text: entry.value,
                style: TextStyle(
                  color:
                      isUser
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                  height: 1.5,
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot avatar
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withValues(alpha: 0.8),
                  AppTheme.primaryGreen.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 14,
            ),
          ),

          // Typing dots
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _typingController,
                  builder: (context, child) {
                    final progress =
                        (_typingController.value + index * 0.2) % 1.0;
                    final bounce =
                        (progress < 0.5) ? progress * 2 : 2 - progress * 2;
                    return Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.3 + bounce * 0.4,
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    // Bottom nav bar is positioned at bottom: 16 with SafeArea
    // Nav bar height: ~80px (icon + padding + text + spacing)
    // Total needed: nav bar height + position offset + extra spacing for visual separation
    const bottomNavBarHeight =
        120.0; // Increased to ensure input area sits above nav bar

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + bottomNavBarHeight,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF081915).withValues(alpha: 0),
            const Color(0xFF081915),
          ],
        ),
      ),
      child: Row(
        children: [
          // Input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Ask anything about PutraSportHub...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Send button
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient:
                    _isLoading
                        ? null
                        : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.primaryGreen, Color(0xFF1B5E4A)],
                        ),
                color: _isLoading ? Colors.white.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color:
                    _isLoading
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
