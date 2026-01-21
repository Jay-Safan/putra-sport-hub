# PUTRASPORTHUB - PROJECT PLANNING DOCUMENT
**Last Updated:** 2024
**Status:** Planning Phase
**Purpose:** Central planning document for app restructuring and feature development

---

## 📋 TABLE OF CONTENTS

1. [Student User System Overview](#1-student-user-system-overview)
2. [App Flow Restructure Recommendations](#2-app-flow-restructure-recommendations)
3. [Tournament Hub Integration Strategy](#3-tournament-hub-integration-strategy)
4. [AI Poster Generation for Tournaments](#4-ai-poster-generation-for-tournaments)
5. [Unified Student System Architecture (Future)](#5-unified-student-system-architecture-future)
6. [Implementation Roadmap](#6-implementation-roadmap)

---

## 1. STUDENT USER SYSTEM OVERVIEW

### 1.1 Current State

**Student Detection:**
- Email domain: `@student.upm.edu.my` → auto-assigned `STUDENT` role
- UserModel fields: `isStudent: bool` + `role: UserRole.student`

**Student Privileges:**
| Feature | Student | Public User |
|---------|---------|-------------|
| Subsidized Pricing | ✅ RM 15-200 | ❌ RM 20-250 |
| Split Bill | ✅ Up to 10-way | ❌ Not available |
| Hire Referee | ✅ Available | ❌ Not available |
| Merit Points | ✅ Earn (GP08) | ❌ None |
| Referee Certification | ✅ Can apply | ❌ Not available |
| Tournament Creation | ✅ Available | ❌ Limited |
| Student-Only Tournaments | ✅ Can join | ❌ Cannot join |

### 1.2 Dual Mode System (Student vs Referee Mode)

**Student Mode (Default):**
- Navigation: Home → Bookings → Merit → Profile
- Focus: Booking facilities, earning merit, managing bookings

**Referee Mode (If verified referee):**
- Navigation: Home → SukanGig → Profile
- Focus: Accepting referee jobs, earning gig income

**Mode Switching:**
- Location: Profile Screen
- Persistence: `user.preferredMode` field in Firestore
- Provider: `activeUserModeProvider` (Riverpod)
- Issue: Mode resets on app restart (not loading from Firestore)

### 1.3 Current Issues Identified

1. **Dual Checking System**
   - Some places check `user.isStudent`
   - Others check `user.role == UserRole.student`
   - Others check `user.hasStudentPrivileges`
   - **Need:** Standardize on single source of truth

2. **Mode Persistence**
   - `preferredMode` exists in UserModel but not loaded on app start
   - Mode resets to Student on app restart
   - **Need:** Load mode from Firestore on app initialization

3. **Navigation Logic Duplication**
   - Mode switching logic in `main.dart`
   - Home screen mode adaptation
   - Profile screen mode switch UI
   - **Need:** Centralize in service/provider

4. **Feature Gating Inconsistency**
   - Split Bill: Checked via `isStudent`
   - Referee Hiring: Checked via `isStudent` + facility requirement
   - Merit: Checked via `user.canEarnMerit`
   - **Need:** Consistent helper methods

---

## 2. APP FLOW RESTRUCTURE RECOMMENDATIONS

### 2.1 Current Issues

1. **Tournaments are hidden** - `/tournaments` route exists but not in bottom nav
2. **Home screen is facility-focused** - No tournament discovery
3. **Features are disconnected** - Bookings, Tournaments, Referee jobs are separate
4. **Navigation inconsistent** - Different tabs for Student vs Referee mode

### 2.2 Recommended Approach: "Hub-Based Architecture"

**Goal:** Make Home a true discovery hub that surfaces tournaments prominently while maintaining clear access paths to all core features.

### 2.3 Proposed Structure: "Smart Home with Tournament Spotlight" (RECOMMENDED)

#### Home Screen Enhancement:
```
┌─────────────────────────────────────┐
│ Header + Weather + Wallet            │
├─────────────────────────────────────┤
│ 🔥 TOURNAMENT HUB (New Section)      │
│   - "Live Now" badge if any active  │
│   - Featured tournament card         │
│   - "View All Tournaments" button    │
│   → Taps go to full Tournament Hub  │
├─────────────────────────────────────┤
│ Quick Actions                        │
│   [My Bookings] [Join Tournament]   │
│   [My Merit] [Referee Mode]         │
├─────────────────────────────────────┤
│ Book Facility                        │
│   - Sport cards (current design)    │
└─────────────────────────────────────┘
```

#### Bottom Navigation Update:
```
Student Mode:
Home → Tournaments → Bookings → Merit → Profile

Referee Mode:
Home → SukanGig → Profile
```

### 2.4 Tournament Hub Screen (Full Screen)

The `/tournaments` route becomes the full hub with:
- **Tabs:** Live Now | Registration Open | My Tournaments | Past
- **Filter:** By Sport | By Status
- **Search bar**
- **Create Tournament** button (prominent, top-right)

### 2.5 Visual Flow

```
User Opens App
    ↓
Home Screen (Discovery Hub)
    ├─→ Tournament Spotlight (Featured live/upcoming)
    │       └─→ Tap → Tournament Detail → Join
    │
    ├─→ Quick Actions
    │       ├─→ Join Tournament → Tournament Hub
    │       ├─→ Book Facility → Facility List
    │       └─→ My Bookings → Bookings Screen
    │
    └─→ Sport Cards → Facility Booking Flow
    
Bottom Nav:
    ├─→ Tournaments Tab → Full Tournament Hub
    │       ├─→ Browse all tournaments
    │       ├─→ Filter by sport/status
    │       ├─→ Create Tournament
    │       └─→ My Tournament registrations
    │
    ├─→ Bookings Tab → All bookings
    │
    └─→ Merit Tab → Merit points (students only)
```

### 2.6 Implementation Priority

**Phase 1: Quick Win (2 hours)**
- Add Tournament Spotlight section to Home screen
- Add Tournaments to bottom nav
- Test basic flow

**Phase 2: Enhancement (3 hours)**
- Enhance Tournament Hub screen with tabs/filters
- Add search functionality
- Improve tournament list UI

**Phase 3: Polish (2 hours)**
- Tournament cards in Home spotlight
- Empty states
- Loading states

---

## 3. TOURNAMENT HUB INTEGRATION STRATEGY

### 3.1 Tournament Hub Screen Structure

**Screen Layout:**
```
Tournament Hub Screen
├── Header
│   ├── Title: "Tournament Hub"
│   ├── Search Bar
│   └── Filter Chips (All | Football | Futsal | Badminton)
├── Create Tournament Button (Floating/Sticky)
└── Tab Bar
    ├── Live Now Tab
    │   └── Active tournaments in progress
    ├── Registration Open Tab
    │   └── Tournaments accepting teams
    ├── My Tournaments Tab
    │   └── User's registered tournaments
    └── Past Tab
        └── Completed tournaments
```

### 3.2 Tournament Cards Display

**Card Components:**
- Tournament poster/thumbnail (primary visual)
- Tournament title
- Sport icon/color
- Status badge ("LIVE NOW", "REGISTRATION OPEN", "FULL")
- Date/time
- Teams registered ("8/16 teams")
- Entry fee (if applicable)
- Quick action button ("Join" / "View Details")

### 3.3 Quick Actions Update

**Home Screen Quick Actions:**
- **My Bookings** (existing)
- **Join Tournament** (NEW - links to Tournament Hub)
- **MyMerit** (students only)
- **Referee Mode** (if verified referee)

---

## 4. AI POSTER GENERATION FOR TOURNAMENTS

### 4.1 Current State

**Existing System:**
- Works with Bookings (Match-type only)
- Uses `GeminiService.generatePoster()`
- Inputs: eventName, dateTime, venue, sport, teamCode, organizerName
- Stored in: `booking.posterImageUrl`
- Route: `/booking/:bookingId/poster`

**Tournament Model:**
- Already has `posterImageUrl` field
- Rich context available for poster generation

### 4.2 Unified Poster System Strategy

**Concept:** One poster service handling both bookings and tournaments

**Service Structure:**
```
GeminiService (enhanced)
├── generateBookingPoster(BookingModel) → Uint8List
├── generateTournamentPoster(TournamentModel) → Uint8List
└── generatePoster() [Generic method with rich context]
```

### 4.3 Tournament Poster Generation Flow

**Option A: Auto-Generate on Creation (RECOMMENDED)**
- When organizer creates tournament → auto-generate poster
- Store in `tournament.posterImageUrl`
- Show in Tournament Hub immediately

**Option B: On-Demand Generation**
- "Generate Poster" button in Tournament Detail screen
- Organizer can regenerate anytime

**Recommended: Hybrid Approach**
- Auto-generate on creation (default)
- Allow regeneration if organizer wants to update

### 4.4 Tournament Poster Content

**Essential Elements:**
- Tournament title
- Sport type (with icon/visual)
- Date/time (start date, registration deadline)
- Venue name
- Format ("8-Team Knockout", "4-Team Group")
- Share code (e.g., "TOURNAMENT-EAGLE-123")
- UPM branding/colors

**Dynamic Elements:**
- Registration status badge ("Registration Open", "Full", "Live Now")
- Team count ("12/16 Teams Registered")
- Entry fee ("RM 20/team" or "Free Entry")
- Organizer name
- Countdown to registration deadline

**Visual Enhancements:**
- Sport-specific imagery
- Format visualization (bracket silhouette, group stage)
- QR code for quick join via share code

### 4.5 Enhanced AI Prompt for Tournament Posters

```
Create an attractive tournament poster with:
- Tournament Title: [title]
- Sport: [sport] with [sport] icon/imagery
- Format: [8-Team Knockout / 4-Team Group Stage]
- Date: [startDate] - [endDate if multi-day]
- Registration Deadline: [deadline]
- Venue: [venue]
- Team Status: [currentTeams]/[maxTeams] teams registered
- Entry Fee: [RM X / Free Entry]
- Share Code: [TOURNAMENT-EAGLE-123]
- Organizer: [organizerName]
- Status Badge: [Registration Open / Full / Live]

Design Requirements:
- Tournament-style design (more elaborate than match poster)
- Show bracket/competition visual elements
- Include QR code for quick join via share code
- UPM branding (Red #B22222, Green #2E8B57)
- Social media optimized (1080x1080 or 1080x1350)
- Emphasize competitiveness and excitement
- Registration deadline countdown visual
```

### 4.6 Integration Points

**Point 1: Tournament Creation**
```
User creates tournament
    ↓
Tournament saved to Firestore
    ↓
Auto-trigger poster generation (background)
    ↓
GeminiService.generateTournamentPoster(tournament)
    ↓
Poster uploaded to Firebase Storage
    ↓
tournament.posterImageUrl updated
    ↓
Poster visible in Tournament Hub immediately
```

**Point 2: Tournament Detail Screen**
- Show generated poster (if exists)
- "Generate/Regenerate Poster" button (organizer only)
- "Share Poster" button (download/share)

**Point 3: Tournament Hub/Discovery**
- Use posters as cards in list view
- Poster previews increase engagement

**Point 4: Share Functionality**
- Share tournament via poster
- Include share code in poster (QR code or text)
- Deep link: `putrasporthub://tournament/:tournamentId`

### 4.7 Technical Implementation Considerations

**Storage Strategy:**
- Store posters in Firebase Storage
- Path: `tournaments/{tournamentId}/poster_{timestamp}.png`
- Keep latest poster URL in `tournament.posterImageUrl`
- Archive old posters if regenerated

**Generation Timing:**
- Start with synchronous (blocking) - simpler
- Move to asynchronous (Firebase Function) if needed - better UX

**Poster Refresh/Caching:**
- Cache generated posters
- Allow regeneration if tournament details change
- Version posters with timestamps

**Fallback Strategy:**
- If Gemini fails → show placeholder with tournament info
- Allow manual poster upload (organizer can upload custom)

**Sharing Mechanics:**
- Deep link: `putrasporthub://tournament/:tournamentId?code=TOURNAMENT-EAGLE-123`
- QR code in poster for quick join
- Share code prominently displayed

### 4.8 Implementation Plan

**Phase 1: Core Connection (2-3 hours)**
1. Enhance `GeminiService` with `generateTournamentPoster()`
2. Add poster generation trigger in tournament creation
3. Update Tournament Detail screen to display poster
4. Test with sample tournament

**Phase 2: UI Integration (2 hours)**
1. Add poster section to Tournament Detail screen
2. Add "Generate/Regenerate Poster" button
3. Add "Share Poster" functionality
4. Show posters in Tournament Hub cards

**Phase 3: Enhancement (1-2 hours)**
1. Add poster preview in Tournament Hub list
2. Improve prompt for tournament-specific visuals
3. Add QR code to poster
4. Add deep link support

**Phase 4: Polish (1 hour)**
1. Loading states during generation
2. Error handling and fallbacks
3. Manual upload option
4. Poster versioning

---

## 5. UNIFIED STUDENT SYSTEM ARCHITECTURE (FUTURE)

### 5.1 Core Principle: Single Source of Truth

**Make student identity and privileges come from ONE place.**
- `UserModel.isStudent` becomes the single source of truth
- Set it once when user loads, use it everywhere

### 5.2 Three-Layer Architecture

**Layer 1: Data Layer (What We Store)**
- Student identity: Email domain check at registration
- Store `isStudent: true` in Firestore once
- Read it back - don't re-check email repeatedly
- Mode preference: Persist `preferredMode` in user document

**Layer 2: Business Logic Layer (The Rules)**
- Centralize all student checks in a service
- UI asks: "Can this user split the bill?" → Service checks `isStudent`
- Feature flags: One place that says "Split bill allowed? Check the feature flag, which checks student status"

**Layer 3: UI Layer (What Users See)**
- UI doesn't decide logic, it asks the service layer
- Navigation: Generated from user + mode context
- Consistent messaging throughout app

### 5.3 Proposed Service Layer

**StudentPrivilegeService:**
- `canSplitBill()` → Yes if student
- `canHireReferee()` → Yes if student + facility requires it
- `canEarnMerit()` → Yes if student
- `shouldShowStudentPricing()` → Yes if student
- `canCreateStudentOnlyTournament()` → Yes if student
- `canSwitchToRefereeMode()` → Yes if student + verified referee badge

**UserModeService:**
- `switchMode(UserMode mode)`
- `getActiveMode()`
- `canSwitchToReferee(UserModel user)`
- Loads mode from Firestore on app start

**NavigationService:**
- `getNavigationItems(UserModel user, UserMode mode)`
- Returns appropriate nav items based on context

### 5.4 Migration Strategy (Future Work)

**Phase 1: Create Service Layer**
- Build `StudentPrivilegeService`
- Build `UserModeService`
- Build `NavigationService`

**Phase 2: Replace Scattered Checks**
- Update UI components to use service
- Remove duplicate conditionals
- Update providers to use service

**Phase 3: Fix Persistence**
- Ensure mode loads on app start
- Save mode on switch

**Phase 4: Testing & Refinement**
- Verify consistency across app
- Clean up unused code

---

## 6. IMPLEMENTATION ROADMAP

### 6.0 USER TYPE PRIORITY ORDER

**Implementation Focus (Strategic Decision):**
1. **Student/Public Users FIRST** - Primary users, most features, 90% of user base
2. **Referee Users SECOND** - Secondary features, polish only (already ~90% complete)
3. **Admin Users LAST** - Tertiary, basic features sufficient for MVP

**Rationale:**
- Student/Public are the main users (booking, tournaments, merit points)
- Referee system is already ~90% complete, needs minimal polish
- Admin features are operational, less critical for demo
- Better to perfect main user experience first
- More efficient use of development time

---

### 6.1 Priority Order (By User Type)

#### 🔴 PHASE 1: STUDENT/PUBLIC USER FEATURES (HIGH PRIORITY)

**Goal:** Complete all student and public user journeys
**Time:** ~20-25 hours (3 weeks)
**Impact:** 90% of user base

**1. Tournament Hub Integration**
- **Goal:** Make tournaments discoverable and accessible
- **Time:** 4-5 hours
- **User Impact:** Student/Public (primary tournament users)
- **Tasks:**
  - Add Tournament Spotlight to Home screen
  - Add Tournaments to bottom nav
  - Enhance Tournament Hub screen with tabs
  - Update Quick Actions

**2. AI Poster Generation for Tournaments**
- **Goal:** Connect poster generation to tournaments
- **Time:** 3-4 hours
- **User Impact:** Student/Public (tournament organizers)
- **Tasks:**
  - Enhance GeminiService for tournaments
  - Add auto-generation on tournament creation
  - Update Tournament Detail screen
  - Add sharing functionality

**3. AI Chatbot (App-Focused Help)**
- **Goal:** Conversational AI assistant for app help
- **Time:** 3-4 hours
- **User Impact:** All users (primary: Student/Public)
- **Tasks:**
  - Create ChatbotService using Gemini API
  - Design floating chat button UI
  - Build chat interface screen
  - Create prompt templates for app topics
  - Implement context-aware responses
  - Add quick action buttons

**4. AI Booking Assistant**
- **Goal:** Conversational booking flow
- **Time:** 4-5 hours
- **User Impact:** Student/Public (primary booking users)
- **Tasks:**
  - Extend ChatbotService for booking logic
  - Integrate with BookingService
  - Create natural language booking flow
  - Add facility search and availability
  - Implement booking confirmation via chat
  - Add quick action buttons (Book, Add Referee, Split Bill)

**5. Navigation Consistency & Mode Persistence**
- **Goal:** Fix navigation and mode persistence
- **Time:** 4-6 hours (combined)
- **User Impact:** All users (primary: Student)
- **Tasks:**
  - Fix mode persistence (load on app start)
  - Standardize navigation logic
  - Ensure consistent user experience
  - Test mode switching

#### 🟡 PHASE 2: REFEREE USER FEATURES (MEDIUM PRIORITY - OPTIONAL)

**Goal:** Polish referee experience (already ~90% complete)
**Time:** ~2-3 hours (only if polish needed)
**Status:** Referee system is already functional

**Note:** Referee system is already ~90% complete. Focus here is on polish only if time permits.

- [ ] Referee dashboard enhancements (if needed)
- [ ] Job acceptance flow polish (if needed)
- [ ] QR code check-in improvements (if needed)

**Current Referee Features (Already Complete):**
- ✅ Referee application flow
- ✅ Job marketplace
- ✅ Job acceptance
- ✅ QR check-in
- ✅ Escrow payment
- ✅ Merit points

#### 🟢 PHASE 3: ADMIN USER FEATURES (LOW PRIORITY - OPTIONAL)

**Goal:** Basic admin functionality (already sufficient for MVP)
**Time:** ~1-2 hours (only if time permits)
**Status:** Admin features are already sufficient

**Note:** Admin features are already implemented. Only enhance if time permits after completing Phase 1.

- [ ] Admin dashboard polish (optional)
- [ ] Additional admin controls (optional)

**Current Admin Features (Already Complete):**
- ✅ Admin dashboard
- ✅ Admin authentication
- ✅ Basic admin controls

#### ⚠️ MEDIUM PRIORITY (Cross-User Features - Optional)

**AI Poster Customization** (Optional Enhancement)
- **Goal:** Customize posters via chat commands
- **Time:** 3-4 hours
- **User Impact:** Student/Public (tournament organizers)
- **Tasks:**
  - Extend GeminiService for style modifications
  - Add poster editing UI
  - Implement natural language style commands
  - Create live preview functionality
  - Test customization commands
- **Priority:** Can be done after core features if time permits

#### 🟢 FUTURE ENHANCEMENTS (Low Priority)

**Unified Student System Architecture**
- **Goal:** Consolidate student privilege checking
- **Time:** 8-10 hours
- **Tasks:**
  - Create service layer
  - Refactor UI components
  - Update all checks
  - Testing and cleanup

### 6.2 Quick Wins (Student/Public Focus - Can Do Now)

**Priority:** All quick wins focus on Student/Public users

1. **Add Tournaments to Bottom Nav** (30 min)
   - Update navigation in `main.dart`
   - Add route to ShellRoute
   - **User Impact:** Student/Public

2. **Tournament Spotlight on Home** (1 hour)
   - Add section to Home screen
   - Fetch featured tournaments
   - Link to Tournament Hub
   - **User Impact:** Student/Public

3. **Poster Display in Tournament Detail** (1 hour)
   - Show poster if exists
   - Add regenerate button
   - **User Impact:** Student/Public (tournament organizers)

### 6.3 Estimated Timeline (By User Priority)

**PHASE 1: Student/Public Users (Weeks 1-3) - CORE MVP**

**Week 1: Tournament Hub + Navigation**
- Day 1-2: Tournament Hub Integration (Home screen + bottom nav)
- Day 3-4: Tournament Hub enhancement (tabs, filters)
- Day 5: Navigation fixes + mode persistence

**Week 2: AI Features for Students**
- Day 1-2: AI Chatbot (ChatbotService + UI)
- Day 3-4: AI Booking Assistant (conversational booking)
- Day 5: Testing and integration

**Week 3: Tournament Posters + Polish**
- Day 1-2: Tournament poster generation
- Day 3-4: UI integration and polish
- Day 5: Testing and refinement

**PHASE 2: Referee Users (Week 4 - Optional)**

**Week 4: Referee Polish (if needed)**
- Day 1-2: Referee dashboard enhancements (if any needed)
- Day 3-4: Job flow polish
- Day 5: Testing

**Note:** Referee system is already ~90% complete. This phase only if polish needed.

**PHASE 3: Admin Users (Week 5 - Optional)**

**Week 5: Admin Polish (if time permits)**
- Day 1-2: Admin dashboard polish
- Day 3-4: Additional admin controls (if needed)
- Day 5: Testing

**Note:** Admin features are already sufficient for MVP. This is optional.

**Total Core Timeline (Phase 1):** 3 weeks → **Complete MVP**
**With Polish (Phase 2-3):** 4-5 weeks (optional)

**Future: Unified Student System**
- TBD: Full refactoring when ready

---

## 7. KEY DECISIONS & RATIONALE

### 7.1 AI Features Selection

**Decision:** Implement 3 user-facing AI features:
1. **AI Chatbot** - App-focused help assistant
2. **AI Booking Assistant** - Conversational booking flow
3. **AI Poster Customization** - Edit posters via chat commands

**Rationale:**
- All features are **visible and interactive** (not hidden/backend)
- Easy to demonstrate in final year project presentation
- Tournaments stay **manual** (too complex for conversational flow)
- Focus on practical, user-facing AI applications
- All use existing Gemini API (no new dependencies)

**Tournaments Decision:**
- Tournament creation: Manual forms (better for detailed setup)
- Tournament browsing: Manual hub (users can explore)
- Tournament joining: Manual selection (more control)
- No AI recommendations for tournaments (keep it simple)

### 7.2 Tournament Hub Placement

**Decision:** Add to bottom nav AND spotlight on Home
**Rationale:** 
- Bottom nav = always accessible
- Home spotlight = discovery and engagement
- Best of both worlds

### 7.3 Poster Generation Timing

**Decision:** Auto-generate on creation + allow regeneration
**Rationale:**
- Default experience is smooth (auto-generated)
- Flexibility for organizers who want custom
- Reduces friction for most users

### 7.4 Mode System

**Decision:** Keep dual-mode system, fix persistence
**Rationale:**
- System works well conceptually
- Just needs persistence fix
- Full refactoring can wait

---

## 8. NOTES & CONSIDERATIONS

### 8.1 Technical Notes

- **Firebase Storage:** Use for poster storage
- **Deep Links:** Implement for tournament sharing
- **QR Codes:** Include in tournament posters
- **State Management:** Continue using Riverpod

### 8.2 UX Considerations

- **Loading States:** Show during poster generation
- **Empty States:** Handle no tournaments gracefully
- **Error Handling:** Fallbacks if AI generation fails
- **Offline:** Consider cached tournament data

### 8.3 Future Enhancements

- **Tournament Notifications:** Push notifications for registration opening
- **Recommendations:** AI-recommended tournaments based on user preferences
- **Tournament Analytics:** Stats for organizers
- **Live Updates:** Real-time tournament status updates

---

## 9. QUESTIONS TO RESOLVE

1. **Poster Generation:** Synchronous or asynchronous?
   - Start with synchronous, move to async if needed

2. **Tournament Hub Tabs:** How many tabs? What order?
   - Suggested: Live Now | Registration Open | My Tournaments | Past

3. **Poster Refresh Policy:** When to allow regeneration?
   - Suggested: Always allow, but warn if tournament details changed

4. **Home Screen Tournament Count:** How many to show?
   - Suggested: 1-2 featured, with "View All" button

---

## 10. REFERENCES

- `project_context.md` - Full project context
- `UX_FLOWS.md` - User experience flows
- `DOMAIN_CONTEXT.md` - Domain knowledge
- `README.md` - Project overview

---

**END OF PLANNING DOCUMENT**

*This is a living document - update as implementation progresses*

