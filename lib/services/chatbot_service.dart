import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../features/auth/data/models/user_model.dart';
import '../features/booking/data/models/facility_model.dart';

/// Chat message model
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
  });
}

/// Message types for different UI rendering
enum MessageType {
  text,
  booking,
  quickActions,
  welcome,
}

/// ChatbotService - AI assistant with complete PutraSportHub knowledge
/// Uses Gemini 1.5 Flash for fast, natural responses
class ChatbotService {
  final String? apiKey;
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  ChatbotService({this.apiKey});

  /// Get response from AI chatbot
  Future<String> getResponse({
    required String userMessage,
    required List<ChatMessage> conversationHistory,
    UserModel? user,
  }) async {
    if (apiKey == null || apiKey!.isEmpty) {
      developer.log('PutraBot: No API key, using fallback');
      return _getSmartResponse(userMessage, user: user, history: conversationHistory);
    }

    try {
      final systemPrompt = _buildComprehensivePrompt(user);
      final conversationContext = _buildConversationContext(conversationHistory);

      final fullPrompt = '''
$systemPrompt

$conversationContext

User: $userMessage
Assistant:''';

      developer.log('PutraBot: Calling Gemini API...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/models/gemini-2.5-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': fullPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.9,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 800,
          },
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
          ],
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          developer.log('PutraBot: API timeout');
          throw Exception('API timeout');
        },
      );

      developer.log('PutraBot: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String;
            developer.log('PutraBot: Got response from Gemini');
            return text.trim();
          }
        }
        
        // Check for blocked content
        if (data['promptFeedback']?['blockReason'] != null) {
          developer.log('PutraBot: Content blocked - ${data['promptFeedback']['blockReason']}');
        }
      } else {
        developer.log('PutraBot: API error ${response.statusCode} - ${response.body}');
      }

      return _getSmartResponse(userMessage, user: user, history: conversationHistory);
    } catch (e) {
      developer.log('PutraBot: Exception - $e');
      return _getSmartResponse(userMessage, user: user, history: conversationHistory);
    }
  }

  /// Build comprehensive system prompt with few-shot examples
  String _buildComprehensivePrompt(UserModel? user) {
    final userName = user?.displayName.split(' ').first ?? '';
    final userRole = _getUserRole(user);
    
    return '''
You are PutraBot, a friendly AI assistant for PutraSportHub - UPM's campus sports booking app.

=== PERSONALITY ===
- Talk like a helpful friend, not a robot
- Keep answers SHORT (2-3 sentences max)
- One emoji max per message (optional)
- Match the user's casual tone
- NEVER use bullet lists unless asked

=== USER INFO ===
Name: ${userName.isNotEmpty ? userName : 'User'}
Role: $userRole

=== EXAMPLE CONVERSATIONS (Follow this style) ===

User: "hi how do i book"
Bot: "Hey! Just tap any sport card on the Home screen, pick a facility and time, then pay with SukanPay. You'll get a QR code to check in at the venue!"

User: "where wallet"
Bot: "Your wallet is in Profile tab - tap Profile at the bottom, then Wallet. You can see your balance and top up there!"

User: "tournament?"
Bot: "Tournaments are in the Tournaments tab! Browse open ones, join with entry fee, or create your own. What would you like to do?"

User: "book futsal tomorrow"
Bot: "Nice! Tap the Futsal card on Home, pick a court, and select tomorrow's date. Student rate is just RM5!"

User: "how much badminton"
Bot: "Badminton is RM3/hour for students, RM20/hour for public. 8 courts available at the Sports Complex!"

User: "merit points"
Bot: "You earn merit points by playing in tournaments (+2), refereeing (+3), or organizing (+5). Note: Normal bookings don't give merit points - only tournaments do! Check your total in the Merit tab."

=== APP KNOWLEDGE ===

BOOKING: Home screen → tap sport card → select facility → pick date & time → pay with SukanPay → get QR code

SPORTS & PRICES (Student/Public):
- Football: RM10/RM250 (Padang A-E), RM600 (Stadium) - 6 fields total
- Futsal: RM5/RM100 - Indoor & outdoor courts
- Badminton: RM3/RM20 per hour - 8 courts
- Tennis: RM5/RM20 per hour - 14 courts

HOURS: 8AM-10PM daily, closed Friday 12:15-2:45PM for prayers

WALLET: Profile → Wallet → Top Up (min RM10)

SPLIT BILL: Toggle on when booking, share team code with friends, everyone pays their share. Max participants: Football 22, Futsal 12, Badminton 8, Tennis 4

TOURNAMENTS: Tournaments tab → browse/create/join with code (Students only). Formats: 8-Team Knockout or 4-Team Group Stage

SUKANGIG: Profile → Become Referee → get certified → SukanGig tab → accept jobs → earn RM20-40/match + 3 merit points

MERIT: Playing in tournaments +2, Refereeing +3, Organizing +5. Max 15/semester. NOTE: Normal bookings do NOT award player merit points - only tournament participation does. Export PDF in Merit tab.

CANCEL: Bookings tab → select → Cancel (24hr before). Refund to wallet.

${_getRoleSpecificInstructions(user)}

=== RESPONSE RULES ===
1. Answer naturally and directly
2. If they ask WHERE, give the navigation path
3. If they ask HOW, explain simply
4. Keep it SHORT - no essays!
5. Sound human, not robotic
''';
  }

  String _getUserRole(UserModel? user) {
    if (user == null) return 'Guest';
    if (user.role == UserRole.admin) return 'Admin';
    if (user.isVerifiedReferee) return 'Student Referee';
    if (user.isStudent) return 'UPM Student';
    if (user.role == UserRole.public) return 'Public User';
    return 'User';
  }

  String _getRoleSpecificInstructions(UserModel? user) {
    final isAdmin = user?.role == UserRole.admin;
    final isPublic = user?.role == UserRole.public;
    final isStudentReferee = user?.isStudent == true && (user?.isVerifiedReferee ?? false);
    final isStudent = user?.isStudent == true && !isStudentReferee;
    
    if (isAdmin) {
      return '''
=== ADMIN ROLE ===
You are helping an ADMIN user. Focus ONLY on admin functionality:
- Admin Dashboard: Overview stats (Users, Revenue, Bookings, Tournaments)
- User Management: View all users, manage accounts (/admin/users)
- Booking Management: View all bookings, check details (/admin/bookings)
- Tournament Management: View all tournaments, check details (/admin/tournaments)
- Referee Management: View all referees, certifications (/admin/referees)
- Facilities Management: View/manage facilities (/admin/facilities)
- Transactions: View all transactions, payment history (/admin/transactions)
- Analytics: View system analytics and reports (/admin/analytics)

IMPORTANT: 
- DO NOT discuss user-facing features (booking facilities, tournaments, split bill, etc.)
- Focus on admin tools, system management, and data oversight
- Redirect questions about user features: "That's for users - use the admin screens to view their data"
''';
    }
    
    if (isPublic) {
      return '''
=== PUBLIC USER ===
Access: Book facilities, use SukanPay wallet
Cannot access: Tournaments, Split Bill, SukanGig, Merit points (student-only features)
When asked about student features, say: "That's a student feature! You can still book facilities and use SukanPay."
''';
    }
    
    if (isStudentReferee) {
      return '''
=== STUDENT REFEREE ROLE ===
Full student access PLUS referee features:
- Book facilities (student rates), Split Bill, Tournaments (join/create), Merit points
- SukanGig: Accept referee jobs, earn RM20-40/match + 3 merit points
- Profile → Become Referee: Already certified (can access SukanGig tab)
- Can switch between Student mode and Referee mode
- Can earn merit from: Playing tournaments (+2), Refereeing (+3), Organizing (+5)
''';
    }
    
    if (isStudent) {
      return '''
=== STUDENT ROLE ===
Full student access:
- Book facilities (student rates), Split Bill, Tournaments (join/create), Merit points
- Cannot access SukanGig (need to become a verified referee first)
- Profile → Become Referee: Get certified to access referee jobs
- Can earn merit from: Playing tournaments (+2), Organizing (+5)
- NOTE: Normal bookings do NOT award merit points - only tournament participation does
''';
    }
    
    return '';
  }

  /// Build conversation context
  String _buildConversationContext(List<ChatMessage> history) {
    if (history.isEmpty) return '';

    final recent = history.length > 6 ? history.sublist(history.length - 6) : history;
    final context = recent.map((msg) {
      return msg.isUser ? 'User: ${msg.content}' : 'Bot: ${msg.content}';
    }).join('\n');

    return 'Recent chat:\n$context\n';
  }

  /// Smart fallback with improved matching
  String _getSmartResponse(String userMessage, {UserModel? user, List<ChatMessage>? history}) {
    final msg = _cleanMessage(userMessage);
    final isAdmin = user?.role == UserRole.admin;
    final isPublic = user?.role == UserRole.public;
    final isReferee = user?.isVerifiedReferee ?? false;
    final userName = user?.displayName.split(' ').first ?? '';

    // === ADMIN-SPECIFIC RESPONSES (Check first for admins) ===
    if (isAdmin) {
      if (_matchesIntent(msg, ['book', 'booking', 'reserve', 'tempah']) && !_matchesIntent(msg, ['view', 'see', 'check', 'manage', 'list'])) {
        return 'To manage bookings, go to Admin Dashboard → Bookings or navigate to /admin/bookings to view all bookings.';
      }
      if (_matchesIntent(msg, ['user', 'users', 'account', 'accounts'])) {
        if (_matchesIntent(msg, ['view', 'see', 'check', 'manage', 'list', 'all'])) {
          return 'Go to Admin Dashboard → Users or navigate to /admin/users to view and manage all user accounts.';
        }
        return 'User management is in Admin Dashboard → Users. View all users, check details, and manage accounts there.';
      }
      if (_matchesIntent(msg, ['tournament', 'tournaments', 'competition'])) {
        if (_matchesIntent(msg, ['view', 'see', 'check', 'manage', 'list', 'all'])) {
          return 'Go to Admin Dashboard → Tournaments or navigate to /admin/tournaments to view all tournaments and check details.';
        }
        return 'Tournament management is in Admin Dashboard → Tournaments. View all tournaments and check details there.';
      }
      if (_matchesIntent(msg, ['revenue', 'money', 'income', 'payment', 'transaction'])) {
        return 'View revenue and transactions in Admin Dashboard → Analytics or /admin/transactions. Check stats in the Overview section.';
      }
      if (_matchesIntent(msg, ['dashboard', 'admin', 'overview', 'stats', 'statistics'])) {
        return 'Admin Dashboard shows overview stats: Total Users, Revenue, Active Bookings, and Active Tournaments. Quick access to all management screens!';
      }
      if (_matchesIntent(msg, ['facility', 'facilities', 'court', 'field'])) {
        return 'Manage facilities in Admin Dashboard → Facilities or /admin/facilities. View all facilities and their details.';
      }
      if (_matchesIntent(msg, ['referee', 'referees', 'wasit', 'officiate'])) {
        return 'View all referees and certifications in Admin Dashboard → Referees or /admin/referees.';
      }
      if (_matchesIntent(msg, ['analytics', 'report', 'reports', 'data'])) {
        return 'View system analytics and reports in Admin Dashboard → Analytics or /admin/analytics.';
      }
      if (_matchesIntent(msg, ['how', 'where', 'what can', 'help'])) {
        return 'Admin Dashboard has everything: Overview stats, User/Booking/Tournament management, Facilities, Referees, Transactions, and Analytics. What do you need to manage?';
      }
      // Default admin response
      return 'Use the Admin Dashboard to manage users, bookings, tournaments, facilities, referees, transactions, and view analytics. What do you need help with?';
    }

    // === BOOKING QUESTIONS (Check first - most common) ===
    if (_matchesIntent(msg, ['book', 'booking', 'reserve', 'tempah'])) {
      if (_matchesIntent(msg, ['how', 'where', 'cara', 'macam mana', 'nak'])) {
        return 'Tap any sport card on the Home screen, pick a facility and time slot, then pay with SukanPay. You\'ll get a QR code to check in! 🎯';
      }
      if (_matchesIntent(msg, ['cancel', 'refund', 'batal'])) {
        return 'Go to Bookings tab, tap your booking, and hit Cancel. Need to cancel 24 hours before - refund goes to your wallet!';
      }
      if (_matchesIntent(msg, ['price', 'cost', 'harga', 'berapa'])) {
        return _getPriceResponse(user);
      }
      return 'Tap any sport card on Home to start booking - Football, Futsal, Badminton, or Tennis. Pick time and pay with SukanPay!';
    }

    // === GREETINGS (only if pure greeting, no question) ===
    if (_isPureGreeting(msg)) {
      return userName.isNotEmpty 
        ? 'Hey $userName! 👋 What can I help you with?' 
        : 'Hey! 👋 Ask me anything about PutraSportHub!';
    }

    // === WALLET ===
    if (_matchesIntent(msg, ['wallet', 'sukanpay', 'duit', 'balance', 'baki'])) {
      if (_matchesIntent(msg, ['top up', 'topup', 'add', 'tambah'])) {
        return 'Go to Profile → Wallet → Top Up button. Min RM10, balance updates instantly!';
      }
      if (_matchesIntent(msg, ['where', 'mana', 'find'])) {
        return 'Wallet is in the Profile tab - tap Profile at the bottom, then Wallet!';
      }
      return 'SukanPay is your in-app wallet. Check balance on Home or in Profile → Wallet. Top up anytime!';
    }

    // === SPORTS / FACILITIES ===
    if (_matchesIntent(msg, ['sport', 'sukan', 'facility', 'what can', 'available'])) {
      return 'We have Football (6 fields), Futsal (indoor/outdoor), Badminton (8 courts), and Tennis (14 courts). All on the Home screen!';
    }

    // === PRICES ===
    if (_matchesIntent(msg, ['price', 'cost', 'harga', 'berapa', 'how much'])) {
      return _getPriceResponse(user);
    }

    // === SPLIT BILL ===
    if (_matchesIntent(msg, ['split', 'share', 'kongsi', 'friend', 'kawan'])) {
      if (isPublic) return 'Split bill is for students only! You can still book normally.';
      return 'When booking, toggle Split Bill on - you\'ll get a team code to share. Everyone pays their part, then booking confirms! Max participants: Football 22, Futsal 12, Badminton 8, Tennis 4.';
    }

    // === TOURNAMENT ===
    if (_matchesIntent(msg, ['tournament', 'pertandingan', 'competition'])) {
      if (isPublic) return 'Tournaments are for UPM students only. You can still book facilities for your own games!';
      if (_matchesIntent(msg, ['create', 'buat', 'organize'])) {
        return 'Go to Tournaments tab → Create Tournament. Pick sport, format, dates, entry fee, then share the code!';
      }
      if (_matchesIntent(msg, ['join', 'sertai', 'masuk'])) {
        return 'Tournaments tab → browse and tap Join, or enter a tournament code. Pay entry fee to register!';
      }
      return 'Check the Tournaments tab to browse, join, or create tournaments!';
    }

    // === REFEREE / SUKANGIG ===
    if (_matchesIntent(msg, ['referee', 'wasit', 'sukangig', 'gig', 'officiate'])) {
      if (isPublic) return 'SukanGig is for UPM student referees. You can still book facilities with referees included!';
      if (_matchesIntent(msg, ['become', 'jadi', 'apply', 'how to be'])) {
        return 'Profile → Become Referee → select your sport cert. Once verified, SukanGig tab appears with job listings!';
      }
      if (_matchesIntent(msg, ['earn', 'money', 'gaji', 'bayar'])) {
        return 'Referees earn RM20-40 per match plus 3 merit points! Payment held in escrow, released after the game.';
      }
      if (isReferee) return 'Check SukanGig tab for available jobs. Accept, show up, QR check-in, and get paid!';
      return 'Want to earn as a referee? Go to Profile → Become Referee to get started!';
    }

    // === MERIT POINTS ===
    if (_matchesIntent(msg, ['merit', 'point', 'gp08', 'housing', 'kolej'])) {
      if (isPublic) return 'Merit points are for UPM students - part of the housing system. Anything else I can help with?';
      if (_matchesIntent(msg, ['earn', 'dapat', 'how'])) {
        return 'Playing in tournaments +2 points (NOT normal bookings!), refereeing +3, organizing +5. Max 15 per semester!';
      }
      if (_matchesIntent(msg, ['export', 'pdf', 'download'])) {
        return 'Merit tab → Export PDF button. Gets you an official transcript for housing applications!';
      }
      return 'Your merit points are in the Merit tab. You can see history and export PDF transcripts there!';
    }

    // === TIME / HOURS ===
    if (_matchesIntent(msg, ['time', 'hour', 'when', 'bila', 'open', 'buka'])) {
      return 'Open 8AM to 10PM daily. Closed during Friday prayers (12:15-2:45PM). Max 2 hours per booking!';
    }

    // === WEATHER ===
    if (_matchesIntent(msg, ['weather', 'rain', 'hujan', 'cuaca'])) {
      return 'Weather shows on Home screen! If rain\'s expected, the app warns you before booking outdoor facilities.';
    }

    // === LOCATION / WHERE ===
    if (_matchesIntent(msg, ['where', 'mana', 'find', 'cari', 'location'])) {
      if (_matchesIntent(msg, ['book'])) return 'Book from the Home screen - tap any sport card!';
      if (_matchesIntent(msg, ['wallet'])) return 'Wallet is in Profile tab → Wallet!';
      if (_matchesIntent(msg, ['tournament'])) return isPublic ? 'Tournaments are student-only!' : 'Tournaments tab at the bottom!';
      if (_matchesIntent(msg, ['merit'])) return isPublic ? 'Merit is for students only!' : 'Merit tab in the navigation!';
      if (_matchesIntent(msg, ['profile', 'setting'])) return 'Profile is the last tab at the bottom!';
    }

    // === HELP ===
    if (_matchesIntent(msg, ['help', 'tolong', 'what can you'])) {
      if (isAdmin) return 'I can help with admin tools: User/Booking/Tournament management, Facilities, Referees, Transactions, and Analytics. What do you need?';
      if (isPublic) return 'I can help with booking facilities, wallet stuff, or navigating the app. What do you need?';
      if (isReferee) return 'I can help with booking facilities, tournaments, SukanGig referee jobs, merit points, and more! What do you need?';
      return 'I know everything about PutraSportHub! Booking, tournaments, split bill, merit points - just ask!';
    }

    // === THANKS ===
    if (_matchesIntent(msg, ['thank', 'thanks', 'terima kasih', 'tq'])) {
      return 'No problem! 😊 Let me know if you need anything else!';
    }

    // === BYE ===
    if (_matchesIntent(msg, ['bye', 'goodbye', 'later', 'jumpa'])) {
      return isAdmin ? 'See you! 👋' : 'See you! 👋 Enjoy your sports activities!';
    }

    // === DEFAULT ===
    if (isAdmin) return 'Use the Admin Dashboard to manage users, bookings, tournaments, facilities, referees, transactions, and view analytics. What do you need help with?';
    if (isPublic) return 'I can help with booking facilities or wallet stuff. What do you want to know?';
    if (isReferee) return 'Ask me about booking, tournaments, SukanGig referee jobs, merit points, or anything about the app!';
    return 'Ask me about booking, tournaments, split bill, merit points, or anything about the app!';
  }

  /// Clean message for better matching
  String _cleanMessage(String msg) {
    return msg.toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  }

  /// Check if message matches intent (more flexible than containsAny)
  bool _matchesIntent(String msg, List<String> keywords) {
    return keywords.any((k) => msg.contains(k));
  }

  /// Check if it's a pure greeting (no question attached)
  bool _isPureGreeting(String msg) {
    final greetings = ['hello', 'hi', 'hey', 'hai', 'helo', 'yo', 'sup', 'salam', 'assalamualaikum'];
    final hasGreeting = greetings.any((g) => msg.contains(g));
    final hasQuestion = _matchesIntent(msg, ['how', 'where', 'what', 'when', 'why', 'can', 'do', 'is', '?']);
    return hasGreeting && !hasQuestion && msg.split(' ').length < 5;
  }

  /// Get price response based on user type
  String _getPriceResponse(UserModel? user) {
    if (user?.isStudent == true) {
      return 'Student rates: Football RM10, Futsal RM5, Badminton RM3/hr, Tennis RM5/hr. Pretty cheap! 🎉';
    }
    return 'Public rates: Football RM250 (Padang A-E), RM600 (Stadium), Futsal RM100, Badminton RM20/hr, Tennis RM20/hr. Students get way cheaper!';
  }

  /// Get contextual quick actions
  List<String> getQuickActions(String userMessage, {UserModel? user}) {
    final isPublic = user?.role == UserRole.public;
    final isReferee = user?.isVerifiedReferee ?? false;
    final isAdmin = user?.role == UserRole.admin;

    if (isAdmin) return ['View Analytics', 'Manage Users', 'Check Bookings'];
    if (isReferee) return ['Find Gigs', 'Book Court', 'Check Wallet'];
    if (isPublic) return ['How to book?', 'Check prices', 'Where\'s wallet?'];
    return ['How to book?', 'Tournaments', 'Merit points'];
  }

  /// Welcome message
  String getWelcomeMessage(UserModel? user) {
    final name = user?.displayName.split(' ').first ?? '';
    final isReferee = user?.isVerifiedReferee ?? false;
    final isPublic = user?.role == UserRole.public;
    final isAdmin = user?.role == UserRole.admin;

    if (isAdmin) return 'Hey${name.isNotEmpty ? ' $name' : ''}! 👋 Need help with admin stuff?';
    if (isReferee) return 'Hey $name! 👋 Looking for gigs or need help with something?';
    if (isPublic) return 'Welcome${name.isNotEmpty ? ' $name' : ''}! 👋 I can help you book facilities or manage your wallet.';
    return 'Hey${name.isNotEmpty ? ' $name' : ''}! 👋 Ask me anything about booking, tournaments, or the app!';
  }

  /// Parse booking intent - only for clear requests
  BookingIntent? parseBookingIntent(String userMessage, List<ChatMessage> history) {
    final msg = userMessage.toLowerCase();
    
    // Don't trigger for questions
    if (_matchesIntent(msg, ['how', 'where', 'what', '?', 'explain', 'tell'])) return null;
    
    // Only trigger for clear booking requests
    final hasIntent = _matchesIntent(msg, [
      'i want to book', 'i wanna book', 'book me', 'book a', 
      'reserve a', 'nak book', 'want book', 'need to book',
      'lets book', 'tolong book'
    ]);
    
    if (!hasIntent) return null;

    SportType? sport;
    if (_matchesIntent(msg, ['football', 'soccer', 'padang', 'bola sepak'])) {
      sport = SportType.football;
    } else if (_matchesIntent(msg, ['futsal'])) {
      sport = SportType.futsal;
    } else if (_matchesIntent(msg, ['badminton', 'shuttle'])) {
      sport = SportType.badminton;
    } else if (_matchesIntent(msg, ['tennis', 'tenis'])) {
      sport = SportType.tennis;
    }

    DateTime? preferredDate;
    if (msg.contains('today') || msg.contains('hari ini')) {
      preferredDate = DateTime.now();
    } else if (msg.contains('tomorrow') || msg.contains('esok')) {
      preferredDate = DateTime.now().add(const Duration(days: 1));
    }

    return BookingIntent(
      sport: sport,
      preferredDate: preferredDate,
      preferredTime: null,
      message: userMessage,
    );
  }

  /// Booking response
  String getBookingAssistantResponse(BookingIntent intent, List<FacilityModel>? facilities, UserModel? user) {
    if (intent.sport == null) {
      return 'Which sport - football, futsal, badminton, or tennis?';
    }

    if (facilities == null || facilities.isEmpty) {
      return 'Can\'t find that right now. Try tapping the sport card on Home!';
    }

    final facility = facilities.first;
    final isStudent = user?.isStudent ?? false;
    final price = isStudent ? facility.priceStudent : facility.pricePublic;

    var response = '${facility.name} for ${intent.sport!.displayName} - RM${price.toStringAsFixed(0)}${isStudent ? ' (student rate)' : ''}.';
    
    if (intent.preferredDate != null) {
      final day = intent.preferredDate!.day == DateTime.now().day ? 'today' : 'tomorrow';
      response += ' For $day?';
    }
    
    response += ' Tap below to continue!';
    return response;
  }
}

/// Booking intent
class BookingIntent {
  final SportType? sport;
  final DateTime? preferredDate;
  final DateTime? preferredTime;
  final String message;

  BookingIntent({
    this.sport,
    this.preferredDate,
    this.preferredTime,
    required this.message,
  });
}
