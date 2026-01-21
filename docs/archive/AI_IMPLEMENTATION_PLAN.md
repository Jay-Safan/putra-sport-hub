# AI FEATURES IMPLEMENTATION PLAN
**Project:** PutraSportHub
**Last Updated:** 2024
**Status:** Planning Phase

---

## 📋 OVERVIEW

This document outlines the detailed implementation plan for the three confirmed AI features:
1. **AI Chatbot** (App-focused help)
2. **AI Booking Assistant** (Conversational booking)
3. **AI Poster Customization** (Edit via chat commands)

**Decision:** Tournaments remain manual (no AI recommendations)

---

## 1. AI CHATBOT (HIGH PRIORITY)

### 1.1 Overview
Floating chat button providing app-focused help using Gemini API.

### 1.2 Features
- Floating chat button (always accessible)
- Answers app-related questions
- Context-aware responses (uses user data when available)
- Quick action buttons for common questions
- App topics: Booking, Tournaments, Merit Points, Referee System, Payment

### 1.3 Implementation

**Service Layer:**
```dart
// lib/services/chatbot_service.dart
class ChatbotService {
  Future<String> respondToQuery(String userQuery, UserModel? user);
  List<String> getSuggestedQuestions();
  bool isBookingQuery(String query); // Detect if user wants to book
}
```

**UI Components:**
- `lib/core/widgets/floating_chat_button.dart` - Floating button
- `lib/features/chatbot/presentation/chatbot_screen.dart` - Chat interface

**Prompt Template:**
```
You are a helpful assistant for PutraSportHub app.
User asks: "{userQuery}"

Context:
- User type: {userRole}
- Current bookings: {upcomingBookings}
- Wallet balance: {walletBalance}

Provide helpful, concise answer about:
- How to book facilities
- How tournaments work
- Merit point system
- Referee jobs
- Payment/wallet

Keep answers under 3 sentences when possible.
```

### 1.4 Tasks
- [ ] Create ChatbotService with Gemini integration
- [ ] Design floating button widget
- [ ] Build chat UI screen
- [ ] Create prompt templates for app topics
- [ ] Add quick action buttons
- [ ] Implement context-aware responses
- [ ] Add suggested questions
- [ ] Test with various queries

**Estimated Time:** 3-4 hours

---

## 2. AI BOOKING ASSISTANT (HIGH PRIORITY)

### 2.1 Overview
Conversational booking flow using natural language.

### 2.2 Features
- Natural language understanding ("I want futsal Friday evening")
- Facility search and availability checking
- Time slot suggestions
- Options: Add referee, split bill
- Complete booking via chat

### 2.3 Implementation

**Service Extension:**
```dart
// Extend ChatbotService
class BookingAssistantService extends ChatbotService {
  Future<BookingIntent> parseBookingIntent(String query);
  Future<List<FacilityModel>> searchFacilities(BookingIntent intent);
  Future<List<TimeSlot>> getAvailableSlots(String facilityId, DateTime date);
  Future<BookingResult> completeBookingViaChat(BookingIntent intent);
}
```

**Data Models:**
```dart
class BookingIntent {
  SportType? sport;
  DateTime? preferredDate;
  TimeOfDay? preferredTime;
  bool wantsReferee;
  bool wantsSplitBill;
  String? facilityPreference;
}
```

**UI Flow:**
1. User: "I want futsal this Friday evening"
2. AI: Shows available facilities with times
3. User: Selects option or confirms
4. AI: Asks about referee/split bill
5. User: Confirms options
6. AI: Completes booking

### 2.4 Tasks
- [ ] Extend ChatbotService for booking logic
- [ ] Create BookingIntent model
- [ ] Implement intent parsing
- [ ] Integrate with FacilityService
- [ ] Integrate with BookingService
- [ ] Create conversational booking UI
- [ ] Add quick action buttons
- [ ] Handle edge cases (no availability, etc.)
- [ ] Test end-to-end booking flow

**Estimated Time:** 4-5 hours

---

## 3. AI POSTER CUSTOMIZATION (MEDIUM PRIORITY)

### 3.1 Overview
Customize generated posters via chat commands.

### 3.2 Features
- Edit posters with natural language commands
- Live preview of changes
- Style modifications
- Save updated poster

### 3.3 Commands Supported
- "Make it more colorful/vibrant"
- "Add team emojis"
- "Change to modern/minimalist style"
- "Bigger text"
- "Different color scheme"
- "Add QR code"
- "Make it sportier"

### 3.4 Implementation

**Service Extension:**
```dart
// Extend GeminiService
Future<Uint8List> customizePoster({
  required Uint8List originalPoster,
  required String customizationRequest,
  required TournamentModel tournament, // or BookingModel
}) async {
  // Use Gemini to understand customization request
  // Generate modified poster
  // Return updated poster bytes
}
```

**UI Flow:**
1. User views generated poster
2. User: "Make it more colorful"
3. System shows loading state
4. Poster updates with new design
5. User can accept, reject, or request more changes
6. Save final version

### 3.5 Tasks
- [ ] Extend GeminiService for customization
- [ ] Create customization prompt templates
- [ ] Add poster editing UI
- [ ] Implement live preview
- [ ] Handle various style commands
- [ ] Add save/regenerate options
- [ ] Test with different commands
- [ ] Optimize generation speed

**Estimated Time:** 3-4 hours

---

## 4. INTEGRATION POINTS

### 4.1 Chatbot Integration
- Floating button appears on all main screens
- Can be triggered from anywhere
- Context-aware (knows current screen/user state)

### 4.2 Booking Assistant Integration
- "Book with AI" button on Home screen
- Can be accessed from chatbot ("Book a facility")
- Integrates with existing BookingService

### 4.3 Poster Customization Integration
- Available after poster generation
- Edit button on poster preview
- Works for both booking and tournament posters

---

## 5. TECHNICAL CONSIDERATIONS

### 5.1 API Usage
- All features use existing Gemini API
- No new API dependencies needed
- Consider rate limiting and costs

### 5.2 Error Handling
- Fallback responses if API fails
- Loading states for async operations
- Clear error messages

### 5.3 Performance
- Cache common responses
- Optimize prompt sizes
- Lazy load chatbot service

### 5.4 User Experience
- Quick, concise responses
- Visual feedback (typing indicators)
- Smooth animations
- Clear action buttons

---

## 6. TESTING STRATEGY

### 6.1 Unit Tests
- ChatbotService response generation
- BookingIntent parsing
- Poster customization prompts

### 6.2 Integration Tests
- End-to-end booking via chat
- Poster generation and customization
- Error handling scenarios

### 6.3 User Testing
- Test with real users
- Collect feedback on responses
- Measure success rate of bookings via AI

---

## 7. IMPLEMENTATION ORDER

**Week 1: AI Chatbot**
- Day 1-2: Service + UI
- Day 3: Testing and refinement

**Week 2: AI Booking Assistant**
- Day 1-2: Extend chatbot + booking logic
- Day 3: Integration and testing

**Week 3: AI Poster Customization**
- Day 1-2: Extend GeminiService + UI
- Day 3: Testing and polish

**Total Estimated Time:** 10-13 hours

---

## 8. SUCCESS METRICS

### 8.1 Chatbot
- Response accuracy (user satisfaction)
- Common questions answered correctly
- Time to response

### 8.2 Booking Assistant
- Successful bookings via chat
- User preference for AI vs manual booking
- Average booking time

### 8.3 Poster Customization
- Commands understood correctly
- User satisfaction with results
- Time to customize

---

**END OF IMPLEMENTATION PLAN**

*This plan will be updated as implementation progresses*

