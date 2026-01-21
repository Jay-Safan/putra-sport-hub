# PutraSportHub - Complete Project Documentation
**Version:** 1.3.0  
**Last Updated:** January 10, 2026  
**Status:** Core Features Complete (100%) | Production Ready (~95%)

---

## 🎯 Latest Updates

### Phase 2: Split Bill & UI Enhancements ✅
**Date:** January 7, 2025  
**Completion:** Split bill for normal bookings, Tournament Hub improvements, Premium UI/UX

### What Changed:
- ✅ **Split bill for normal bookings** (students only, sport-based participant limits)
- ✅ **Unified time slot availability** (normal bookings + tournaments shown together)
- ✅ **Tournament Hub restructured** (Discover, My Active, History tabs)
- ✅ **Role filtering** in My Active tab (Organizing/Participating)
- ✅ **Premium minimalist UI** improvements (sticky filters, icon-first chips)
- ✅ **Split bill booking sharing** (QR codes, deep links)
- ✅ **In-app notifications** for split bill events
- ✅ **Split bill status indicators** across all screens
- ✅ **Auto-confirmation** when all participants paid
- ✅ **Proportional refunds** on split bill cancellation
- ✅ **Participant management** (join/leave with share recalculation)

### Phase 1: Tournament Sharing ✅
**Date:** January 6, 2025  
- ❌ **Removed:** Complex poster generation system
- ✅ **Added:** Share tournament feature with QR codes and multi-platform sharing

---

## 📋 Executive Summary

**PutraSportHub** is a Flutter mobile application that digitizes the sports facility management ecosystem for Universiti Putra Malaysia (UPM). It integrates facility booking, a gig economy for student referees, tournament management, and academic merit point tracking into a unified platform.

### Current Status
- **Core Features:** 95% Complete ✅
- **Integration & Polish:** 90% Complete ✅
- **Production Readiness:** 90% Complete ✅

### Key Achievements
✅ **Complete booking system** with split bill functionality for normal bookings  
✅ **Unified availability system** (normal bookings + tournaments)  
✅ **Split bill for normal bookings** (students only, sport-based limits)  
✅ **Referee marketplace** (SukanGig) with escrow payments  
✅ **Tournament creation, management, and discovery** (Fully Integrated)  
✅ **Tournament Hub** with smart tabs (Discover, My Active, History)  
✅ **Tournament sharing** with QR codes and multi-platform support  
✅ **Split bill booking sharing** with QR codes and deep links  
✅ **In-app notifications** system for all events  
✅ **AI chatbot** with role-specific context  
✅ **Merit points system** (GP08 integration)  
✅ **Admin dashboard** with data management  
✅ **Premium minimalist UI/UX** with smooth animations and loading states  

---

## 🏗️ System Architecture

### Technology Stack
- **Frontend:** Flutter 3.7+ (Dart)
- **Backend:** Firebase (Firestore, Auth)
- **Image Storage:** Cloudinary (25 GB free tier, for profile images only)
- **State Management:** Riverpod 2.6+
- **Routing:** GoRouter 14.8+
- **External APIs:**
  - Google Gemini API (AI chatbot)
  - OpenWeatherMap API (weather-based booking - optional)
  - Google Maps Static API (facility location maps)

### Project Structure
```
lib/
├── core/
│   ├── config/          # API keys, Firebase options
│   ├── constants/       # AppConstants, Enums (UserRole, SportType, etc.)
│   ├── navigation/      # GoRouter config, MainScaffold (bottom nav)
│   ├── theme/           # AppTheme (colors, typography)
│   ├── utils/           # Date/time helpers, validators, QR utils
│   └── widgets/         # Reusable UI components (loaders, cards, etc.)
│
├── features/            # Feature-based organization
│   ├── auth/           # Authentication (Login, Register)
│   ├── home/           # Home dashboard
│   ├── booking/        # Booking flow, facility selection, split bill
│   ├── payment/        # Wallet, top-up, transaction history
│   ├── referee/        # SukanGig (referee marketplace)
│   ├── tournament/     # Tournament creation, joining, management, sharing
│   ├── merit/          # Merit points tracking, PDF export
│   ├── profile/        # User profile management
│   ├── admin/          # Admin dashboard
│   ├── ai/             # AI chatbot screen
│   └── notifications/  # In-app notifications
│
├── services/           # Business logic layer
│   ├── auth_service.dart
│   ├── booking_service.dart
│   ├── payment_service.dart
│   ├── referee_service.dart
│   ├── tournament_service.dart
│   ├── merit_service.dart
│   ├── weather_service.dart
│   ├── chatbot_service.dart
│   ├── storage_service.dart (Cloudinary integration)
│   ├── notification_service.dart
│   └── seed_service.dart
│
└── providers/          # Riverpod providers
    └── providers.dart
```

---

## 👥 User Roles & Access

### 1. **Student Users** (`@student.upm.edu.my`)
**Default Role:** `UserRole.student`

**Features:**
- ✅ Student pricing (booking fees: RM 3-10) vs Public (full rates: RM 20-600)
- ✅ **Split bill functionality** for normal bookings (students only)
  - Sport-based participant limits:
    - Football: max 22 participants
    - Futsal: max 12 participants
    - Badminton: max 8 participants
    - Tennis: max 4 participants
  - Share booking via QR code or team code
  - Auto-confirmation when all participants paid
- ✅ **Tournament creation and joining** (Fully Integrated)
- ✅ **Tournament sharing with QR codes** (WhatsApp, Twitter, Email)
- ✅ **Join tournaments** via QR scanner or share code
- ✅ Merit points earning (GP08)
- ✅ Referee certification application (for tournaments)
- ✅ AI chatbot access (full context)

**Navigation:**
- Home → Bookings → **Tournaments** → AI Help → Profile

**Tournament Features:**
- Create tournaments with custom details
- **Tournament Hub** with smart tabs:
  - **Discover:** Browse open tournaments (excludes your own)
  - **My Active:** Your organizing/participating tournaments with role filters
  - **History:** Past tournaments you organized or participated in
- Sport filtering (All Sports, Football, Futsal, Badminton, Tennis)
- Role filtering (Organizing/Participating) in My Active tab
- Share tournaments with QR codes
- Multi-platform sharing (WhatsApp, Twitter, Email, Generic)
- Join tournaments via QR scanner or share code
- View tournament details and brackets

---

### 2. **Public Users** (Non-student emails)
**Default Role:** `UserRole.publicUser`

**Features:**
- ✅ Public pricing (RM 20-250)
- ❌ No split bill
- ❌ No tournaments
- ❌ No merit points
- ❌ No referee features
- ✅ AI chatbot access (public-only context)

**Navigation:**
- Home → Bookings → AI Help → Profile

**AI Context:**
- Bot responses exclude tournament/merit/referee features
- Only mentions booking and wallet features

---

### 3. **Referees** (Students with certification)
**Status:** Not a separate role - Students with verified badges

**Important:** Referees are only assigned to **tournament matches**. Normal facility bookings do not require referees.

**Certification:**
- Students apply via `/referee/apply`
- Upload transcript with QKS codes:
  - `QKS2101` → `VERIFIED_REF_FOOTBALL`
  - `QKS2102` → `VERIFIED_REF_BADMINTON`
  - `QKS2103` → `VERIFIED_REF_TENNIS` (verify with UPM)
  - `QKS2104` → `VERIFIED_REF_FUTSAL`
- Badges stored in `user.badges[]` array

**Features:**
- ✅ Browse referee jobs (SukanGig) — tournament matches only
- ✅ Accept jobs matching their badges
- ✅ QR code venue check-in
- ✅ Escrow-based payments (RM50/match)
- ✅ Merit points (+3 per match, GP08 Code B2)
- ✅ Switch between Student/Referee modes

**Navigation (Referee Mode):**
- Home → SukanGig → AI Help → Profile

---

### 4. **Admin Users**
**Role:** `UserRole.admin`
**Detection:** Set in Firestore `users` collection (`role: 'ADMIN'`)

**Features:**
- ✅ Admin dashboard
- ✅ Data reset tool (demo/testing)
- ✅ System management capabilities
- ✅ AI chatbot access

**Navigation:**
- Admin → AI Help → Profile

**Access Control:**
- Automatically redirected to `/admin` if accessing `/home`
- Cannot access regular booking/tournament flows
- Has separate dashboard interface

---

## 🎯 Core Features Status

### ✅ Fully Implemented Features

#### 1. **Smart Facility Booking System** (100% Complete)
**Location:** `lib/features/booking/`, `lib/services/booking_service.dart`

**Features:**
- ✅ **Simplified 3-step booking flow** (Date → Time → Confirm)
- ✅ Two booking patterns across four sports:
  - **Session-based (SESSION):** Football, Futsal (2-hour fixed sessions)
  - **Inventory (INVENTORY):** Badminton (Courts 1-8), Tennis (Courts 1-14)
- ✅ **All bookings are "Practice" type** (simple bookings)
- ✅ **Split bill functionality** (students only):
  - Sport-based participant limits (Football: max 22, Futsal: max 12, Badminton: max 8, Tennis: max 4)
  - Organizer pays only their share initially
  - Auto-confirmation when all participants paid
  - Share booking via QR code or team code
  - Proportional refunds on cancellation
  - Participant join/leave with share recalculation
- ✅ **Unified time slot availability** (normal bookings + tournaments):
  - Visual indication of booked slots
  - Prevents double-booking across booking types
- ✅ Student/Public pricing (automatic detection)
- ✅ Weather-based recommendations (OpenWeatherMap)
- ✅ Friday prayer blocking (12:15 PM - 2:45 PM)
- ✅ Booking cancellation with 24-hour policy
- ✅ QR code generation for check-in
- ✅ **Sub-unit support** (independent court availability)

**Status Notes:**
- ✅ All booking types working
- ✅ Cancellation and refunds working
- ✅ Public and student flows unified
- ✅ Court selection integrated into time selection

---

#### 2. **Tournament System** (100% Complete) ✅
**Location:** `lib/features/tournament/`, `lib/services/tournament_service.dart`

**Features:**
- ✅ **Tournament creation wizard** (`/tournament/create`)
  - Sport selection
  - Facility selection with court selection (for badminton)
  - Tournament format selection (8-team knockout, 4-team group)
  - Date and time selection with duration (2h, 4h, 6h, 8h, 10h, 12h)
  - Tournament details (title, description, entry fee, student-only toggle)
- ✅ **Tournament Hub** with smart tabs:
  - **Discover:** Browse open tournaments (excludes your own)
  - **My Active:** Your organizing/participating tournaments
    - Role filters: All, Organizing, Participating
    - Icon-first segmented filter chips
  - **History:** Past tournaments you organized or participated in
- ✅ **Sticky sport filter bar** across all tabs (All Sports, Football, Futsal, Badminton, Tennis)
- ✅ Tournament detail view with:
  - Tournament information grid
  - Team cards with status
  - Action buttons (Share, Manage, Cancel)
- ✅ Tournament joining flow with payment
- ✅ Team registration system
- ✅ Fixed bracket formats (8-team knockout, 4-team group)
- ✅ Tournament status management
- ✅ **Tournament sharing with QR codes** (NEW - Phase 1)
- ✅ **Multi-platform sharing** (WhatsApp, Twitter, Email, Generic) (NEW - Phase 1)
- ✅ Tournament cancellation (organizer only)

**Status:**
- ✅ Fully integrated into navigation
- ✅ Tournament Hub restructured with smart tabs (Discover, My Active, History)
- ✅ Sticky sport filter bar with icon-first chips
- ✅ Role filtering in My Active tab
- ✅ Sharing functionality working
- ✅ Firestore transactions prevent race conditions
- ✅ Automatic status updates working
- ✅ All tournament flows functional

---

#### 3. **Split Bill System** (100% Complete)
**Location:** `lib/features/booking/presentation/split_bill_*.dart`, `lib/services/payment_service.dart`, `lib/features/booking/presentation/share_booking_screen.dart`

**Note:** Split bill is **available for normal bookings** (students only), not tournaments.

**Features:**
- ✅ **Sport-based participant limits:**
  - Football: max 22 participants (recommended: 12)
  - Futsal: max 12 participants (recommended: 10)
  - Badminton: max 8 participants (recommended: 4)
  - Tennis: max 4 participants (recommended: 2)
- ✅ **Organizer pays only their share initially** (booking stays `PENDING_PAYMENT`)
- ✅ **Team code generation** (`ANIMAL-XXX` format, e.g., `TIGER-882`)
- ✅ **Share booking** via QR code or deep link (`putrasport://join/`)
- ✅ **Participant join flow** via team code or QR scanner
- ✅ **Auto-confirmation** when all participants have paid
- ✅ **Individual participant payment screens**
- ✅ **Proportional refunds** on cancellation (all participants refunded their share)
- ✅ **Participant leave** functionality (before paying, with share recalculation)
- ✅ **Payment status tracking** per participant
- ✅ **Status indicators** across all screens (X/Y paid, color-coded)
- ✅ **In-app notifications** for all split bill events (join, paid, confirmed, left)

**Status:**
- ✅ Fully implemented for normal bookings (students only)
- ✅ Payment processing working
- ✅ Refund logic correct (proportional)
- ✅ Auto-confirmation working
- ✅ Notifications integrated

---

#### 4. **Payment & Wallet System (SukanPay)** (100% Complete)
**Location:** `lib/features/payment/`, `lib/services/payment_service.dart`

**Features:**
- ✅ Wallet creation on user registration
- ✅ Top-up functionality
- ✅ Transaction history
- ✅ Escrow vault for referee payments
- ✅ Refund processing (to wallet, never external)
- ✅ Split bill payment handling (for tournaments)
- ✅ Tournament entry fee payment
- ✅ Balance checking and validation

**Transaction Types:**
- Booking payment
- Top-up
- Refund
- Split bill payment
- Tournament entry fee
- Referee payout (from escrow)

**Status:**
- ✅ Complete and operational
- ✅ All transaction types working
- ✅ Escrow system functional

---

#### 5. **Referee Marketplace (SukanGig)** (95% Complete)
**Location:** `lib/features/referee/`, `lib/services/referee_service.dart`

**Features:**
- ✅ Referee application flow (Profile → Apply)
- ✅ QKS code-based certification
- ✅ Badge system (`VERIFIED_REF_*`)
- ✅ Job marketplace (filtered by user badges)
- ✅ Job acceptance flow
- ✅ QR code check-in system
- ✅ Escrow payment release
- ✅ Merit points awarding (+3 points, Code B2)

**Job Lifecycle:**
```
OPEN → ASSIGNED → COMPLETED → PAID
```

**Status:**
- ✅ Fully functional
- ✅ Escrow payments working
- ✅ QR check-in implemented

---

#### 6. **Merit Points System (MyMerit)** (95% Complete)
**Location:** `lib/features/merit/`, `lib/services/merit_service.dart`

**Features:**
- ✅ GP08 integration
- ✅ Point types:
  - Player participation: +2 points (Code B1)
  - Referee service: +3 points (Code B2)
  - Tournament organizer: +5 points (Code B3)
- ✅ Semester-based tracking
- ✅ 15-point cap per semester
- ✅ Merit record logging
- ✅ PDF transcript generation
- ✅ Merit screen with history

**PDF Export:**
- UPM branding
- Student information
- Activity summary table
- GP08 code references
- Verification section

**Status:**
- ✅ Fully functional
- ✅ PDF generation working
- ✅ All point types implemented

---

#### 7. **In-App Notifications** (100% Complete)
**Location:** `lib/services/notification_service.dart`, `lib/features/notifications/`

**Features:**
- ✅ Notification creation and storage in Firestore
- ✅ Split bill notifications (join, paid, confirmed, left, refund)
- ✅ Tournament notifications (join, status updates)
- ✅ Booking notifications (confirmed, cancelled, reminder)
- ✅ Payment notifications (received, refund)
- ✅ Notification screen with read/unread states
- ✅ Deep linking to related screens

**Status:**
- ✅ Fully functional
- ✅ All event types covered

---

#### 8. **AI Features** (95% Complete)

##### A. **AI Chatbot** ✅ (95% Complete)
**Location:** `lib/services/chatbot_service.dart`, `lib/features/ai/presentation/chatbot_screen.dart`

**Features:**
- ✅ Role-specific system prompts
- ✅ Public user context (no tournaments/merit)
- ✅ Student/Referee context (full features)
- ✅ Conversational interface
- ✅ Welcome message customization
- ✅ Fallback responses
- ✅ Integration in bottom navigation

**Status:**
- ✅ Fully functional
- ✅ Context-aware responses working

---

#### 9. **Admin Dashboard** (85% Complete)
**Location:** `lib/features/admin/presentation/admin_dashboard_screen.dart`

**Features:**
- ✅ Admin authentication detection (from Firestore)
- ✅ Data reset tool (clears all data except users)
- ✅ Demo/testing utilities
- ✅ Simplified UI focused on data management

**Status:**
- ✅ Functional for demo purposes

---

## 🗄️ Database Schema (Firestore)

### Collections Overview

| Collection | Purpose | Key Fields |
|------------|---------|------------|
| `users` | User accounts | `uid`, `email`, `role`, `isStudent`, `badges[]`, `wallet_balance`, `merit_points_total` |
| `facilities` | Sports facilities | `id`, `name`, `type`, `sport`, `price_student`, `price_public`, `is_indoor`, `subUnits[]` |
| `bookings` | Facility bookings | `id`, `facilityId`, `userId`, `status`, `startTime`, `endTime`, `totalAmount`, `subUnit`, `bookingType` |
| `tournaments` | Tournament data | `id`, `title`, `sport`, `organizerId`, `startDate`, `endDate`, `status`, `shareCode`, `teams[]`, `format` |
| `referee_jobs` | SukanGig jobs | `id`, `bookingId`, `sportType`, `status`, `assignedRefereeId`, `payoutAmount` |
| `merit_logs` | Merit records | `id`, `userId`, `activityName`, `points`, `gp08Code`, `timestamp` |
| `transactions` | Payment history | `id`, `userId`, `type`, `amount`, `status`, `referenceId` |
| `wallets` | SukanPay wallets | `id`, `userId`, `balance`, `updatedAt` |
| `escrow_vault` | Escrow storage | `id`, `jobId`, `amount`, `status` |
| `notifications` | In-app notifications | `id`, `userId`, `title`, `message`, `type`, `read`, `timestamp` |

### Key Relationships
- `bookings.userId` → `users.uid`
- `bookings.facilityId` → `facilities.id`
- `bookings.subUnit` → `facilities.subUnits[].name`
- `referee_jobs.bookingId` → `bookings.id`
- `referee_jobs.assignedRefereeId` → `users.uid`
- `tournaments.organizerId` → `users.uid`

---

## 🔄 User Flows

### Student Booking Flow (Simple Practice Booking with Split Bill)
```
1. Login (ali@student.upm.edu.my)
2. Home → Select Sport (Futsal)
3. Select Facility (Futsal KMR Indoor)
4. Select Date (Friday, 5 PM)
5. Select Time Slot (shows unified availability - normal bookings + tournaments)
6. Review booking details
7. [Optional] Enable Split Bill (students only):
   - Toggle split bill option
   - Shows estimated per-person cost
   - Shows sport-based participant limits
8. Confirm & Pay (Student rate: RM 40, or RM 20 if split bill with 2 participants)
9. If split bill:
   - Booking status: PENDING_PAYMENT
   - Team code generated (e.g., TIGER-882)
   - Share booking via QR code or team code
   - Participants join and pay their share
   - Booking auto-confirms when all paid
10. If normal booking:
    - Booking confirmed immediately
    - QR code generated for check-in
```

### Student Tournament Creation Flow
```
1. Student login
2. Home → "Create Tournament" button
3. Tournament creation wizard:
   - Select Sport (Football/Futsal/Badminton)
   - Select Facility (with court selection for badminton)
   - Select Format (8-team knockout / 4-team group)
   - Select Date, Duration (2h-12h), and Time
   - Enter Details (title, description, entry fee, student-only toggle)
4. Create Tournament
5. Navigate to Tournament Detail
6. Click "Share Tournament" button
7. Generate QR code and share via WhatsApp/Twitter/Email
8. Teams join via:
   - QR code scanner (Tournament Hub → Join button)
   - Share code entry (Tournament Hub → Join button)
9. Tournament appears in:
   - Discover tab (for other students)
   - My Active tab → Organizing filter (for organizer)
   - History tab (after tournament ends)
```

### Public User Booking Flow (Simplified)
```
1. Login (public@example.com)
2. Home → Select Sport
3. Select Facility
4. Select Date & Time
5. Confirm & Pay (Public rate: RM 50)
6. Booking confirmed (no split bill, no tournaments)
```

### Referee Flow
```
1. Profile → "Become a Referee"
2. Select Course (QKS2101 for Football)
3. Upload Transcript (optional)
4. Submit → Badge assigned: VERIFIED_REF_FOOTBALL
5. Switch to Referee Mode (if desired)
6. SukanGig → Browse Jobs
7. Accept Job → Job status: ASSIGNED
8. Match Day → Show QR Code → Organizer scans
9. Match Complete → Escrow released → RM30 to wallet
10. Merit points awarded (+3, Code B2)
```

---

## 🎨 Design System

### Color Palette
- **Primary Green:** `#1B5E20` (UPM Forest Green)
- **Primary Red:** `#B22222` (UPM Red)
- **Accent Gold:** `#FFD700` (Championship Gold)
- **Success Green:** `#4CAF50`
- **Info Blue:** `#2196F3`
- **Warning Amber:** `#FFC107`
- **Error Red:** `#F44336`
- **Dark Background:** `#0A1F1A` (Deep dark green)

### UI Style
- **Premium Minimalist Design:** Clean, modern interface inspired by Wise mobile app
- **Glassmorphism:** Backdrop blur effects with semi-transparent backgrounds
- **Dark Theme:** Primary design (gradient backgrounds)
- **Material 3:** Using latest Material Design
- **Typography:** Google Fonts (dynamic loading)
- **Modern Loaders:** Shimmer skeletons, progressive loading, minimal dot loaders
- **Sticky Headers:** Sport filter bars remain visible while scrolling
- **Icon-First Chips:** Role filters with icons (star for organizing, person for participating)
- **Smooth Animations:** Staggered animations, fade transitions, micro-interactions

### Navigation Style
- **Bottom Navigation:** Glassmorphic bar with backdrop filter
- **Tab Transitions:** Smooth fade-in animations
- **Flow Transitions:** Slide-in from right for flows
- **Role-Based:** Different nav items per user type

---

## 🔒 Security & Access Control

### Authentication
- Firebase Auth (Email/Password)
- Role detection:
  - Email domain (`@student.upm.edu.my`) → Student
  - Firestore `role` field → Admin/Referee
  - Default → Public User
- **Strict login:** Only allows sign-in for existing accounts

### Route Guards
- Unauthenticated users → Redirect to `/login`
- Admin users → Redirect to `/admin` (not `/home`)
- Public users → Block tournament routes
- Role-based navigation items

### Firestore Security Rules
- User documents: Read/write own document
- Bookings: Create own, read own + admin
- Referee jobs: Read filtered by badges
- Facilities: Read-only (admin write)
- Tournaments: Read public tournaments, write own tournaments

---

## 📊 Current Implementation Status

### Feature Completion Matrix

| Feature Category | Status | Completion | Notes |
|-----------------|--------|------------|-------|
| **Authentication** | ✅ | 100% | Email/password, role detection, strict login |
| **Booking System** | ✅ | 100% | All patterns, simplified flow, sub-unit support, unified availability |
| **Split Bill System** | ✅ | 100% | Normal bookings (students only), sport-based limits, auto-confirmation |
| **Payment/Wallet** | ✅ | 100% | Complete payment flow, escrow, refunds, split bill payments |
| **Referee System** | ✅ | 95% | Full functionality |
| **Tournament System** | ✅ | 100% | Fully integrated, smart tabs, sharing, QR codes |
| **Notifications** | ✅ | 100% | All event types, in-app notifications |
| **Merit System** | ✅ | 95% | Points, PDF export, tracking complete |
| **AI Chatbot** | ✅ | 95% | Role-specific context working |
| **Admin Dashboard** | ✅ | 85% | Functional, demo tools included |
| **Navigation** | ✅ | 100% | Role-based, consistent, smooth transitions |
| **Public User Flow** | ✅ | 100% | Simplified booking, no tournaments, no split bill |
| **Image Storage** | ✅ | 100% | Cloudinary integration (profile images only) |
| **UI/UX** | ✅ | 100% | Premium minimalist design, shimmer loaders, sticky filters |

### Overall Project Completion: **~95%**

**Breakdown:**
- Core Features: **100%** ✅ (All critical features implemented)
- Integration & Polish: **95%** ✅ (UI/UX refined, notifications complete)
- Production Readiness: **95%** ✅ (Only security rules need tightening)

---

## 🚀 Deployment & Configuration

### Environment Setup
1. **Firebase Project:** Configured with Firestore, Auth
2. **Cloudinary Account:** Configured for profile image storage (25 GB free tier, optional)
3. **API Keys Required:**
   - Gemini API key (for AI chatbot) - in `lib/core/config/api_keys.dart`
   - OpenWeatherMap API key (for weather) - optional
   - Google Maps Static API key (for facility maps) - in `api_keys.dart`
4. **Firestore Rules:** Configured in `firestore.rules`
5. **Data Seeding:** Automatic on first launch via `SeedService`

### Build Configuration
- **Platforms:** iOS, Android, Web (configured)
- **Flutter Version:** 3.7+
- **Dependencies:** See `pubspec.yaml`

### Testing Accounts
- Student: `ali@student.upm.edu.my` / `Password123`
- Student (Referee): `haziq@student.upm.edu.my` / `Password123` (with badges)
- Public: `public@example.com` / `Password123`
- Admin: `admin@upm.edu.my` / `AdminPass123` (role set in Firestore)

**Note:** Demo accounts can be auto-filled on the sign-up page for easy testing.

---

## 📈 Project Metrics

### Code Statistics
- **Features:** 11 major feature modules
- **Services:** 11 business logic services
- **Screens:** 30+ UI screens
- **Models:** 10+ data models
- **Collections:** 10+ Firestore collections

### Feature Coverage
- **Booking Patterns:** 3 (Session, Hourly, Inventory)
- **Sports:** 3 (Football, Futsal, Badminton)
- **User Roles:** 4 (Student, Public, Referee, Admin)
- **Payment Types:** 6+ (Booking, Top-up, Refund, Split Bill, Tournament Entry, Escrow)
- **AI Features:** 1 fully implemented (Chatbot)
- **Tournament Formats:** 2 (8-team knockout, 4-team group)

---

## ✅ Production Readiness Checklist

### Core Functionality
- [x] All user flows working end-to-end
- [x] Payment processing secure
- [x] Data persistence reliable
- [x] Error handling in place
- [x] Role-based access control
- [x] Tournament system fully integrated
- [x] Tournament sharing working
- [x] Split bill for normal bookings working
- [x] Unified availability system working
- [x] Auto-confirmation for split bill working
- [x] In-app notifications working
- [x] Firestore transactions preventing race conditions

### User Experience
- [x] Consistent navigation
- [x] Premium minimalist design
- [x] Shimmer loading skeletons
- [x] Progressive loading transitions
- [x] Error messages
- [x] Empty states
- [x] Role-specific UI
- [x] Smooth animations (staggered, fade, micro-interactions)
- [x] Scrollable screens
- [x] Sticky filter bars
- [x] Icon-first filter chips
- [x] Status indicators (color-coded, X/Y paid format)

### Technical
- [x] Firebase integration
- [x] Cloudinary integration (for profile images)
- [x] API integrations working
- [x] State management consistent
- [x] Code organization clean
- [x] Image storage configured
- [ ] Unit tests (partial)
- [ ] Integration tests (partial)

### Documentation
- [x] Code comments
- [x] Documentation files
- [x] Architecture documented
- [x] User flows documented
- [x] Setup guides

---

## 🎓 For Final Year Project Submission

### Strengths to Emphasize
1. **Complete System:** All major features implemented and working
2. **Real-World Application:** Solves actual UPM problems
3. **AI Integration:** Demonstrates practical AI usage (chatbot)
4. **Multi-Faceted:** Booking, Payments, Referees, Tournaments, Merit
5. **Professional Quality:** Clean code, good architecture, documentation
6. **Modern UI/UX:** Glassmorphic design, smooth animations
7. **Tournament Management:** Complete lifecycle with QR code sharing
8. **Easy Sharing:** Multi-platform tournament sharing with QR codes

### Demo Highlights
1. **Full Booking Flow:** Show simple practice booking
2. **Tournament Creation:** Show tournament wizard with all options
3. **Tournament Sharing:** Generate QR codes and share via multiple platforms
4. **AI Chatbot:** Show role-specific responses
5. **Referee Flow:** Complete job acceptance and payment
6. **Merit System:** Show PDF export
7. **Split Bill (Tournaments):** Show team code and participant joining

### Potential Questions & Answers
**Q: Why QR codes for tournament sharing?**  
A: Makes tournament promotion simple and accessible. Users can easily share tournaments via WhatsApp, Twitter, or Email. QR codes provide instant access without requiring app installation.

**Q: How does tournament split bill work?**  
A: Tournament organizer pays upfront, participants pay their share later, organizer gets refunded proportionally - solves coordination issues for team tournaments.

**Q: Why different user types?**  
A: Students have academic integration needs (merit points), public users just want to book facilities - different feature sets make sense.

**Q: How scalable is this?**  
A: Firebase scales automatically, Cloudinary handles image storage, modular architecture allows easy feature additions, could expand to other universities.

**Q: Why Cloudinary over Firebase Storage?**  
A: Free tier (25 GB), no billing setup required, automatic CORS handling, image optimization included, simpler configuration.

---

## 🔄 Recent Updates (Latest Session - January 2025)

### Latest Changes
1. ✅ **Tournament System Fully Integrated:** Tournament Hub with tabs, creation wizard, joining flow
2. ✅ **Tournament Sharing Implemented:** QR code generation and multi-platform sharing (Phase 1)
3. ✅ **Cloudinary Integration:** For profile image storage (25 GB free tier)
4. ✅ **Simplified Booking Flow:** Removed organizer mode from simple bookings (now only for tournaments)
5. ✅ **Sub-unit Support:** Independent court availability for badminton
6. ✅ **Enhanced UI/UX:** Modern loaders, smooth animations, scrollable screens
7. ✅ **Strict Authentication:** Only allows sign-in for existing accounts
8. ✅ **Better Error Handling:** User-friendly error messages, proper navigation
9. ✅ **Code Cleanup:** Removed unused code, organized API keys
10. ✅ **Poster Generation Removed:** Simplified system, replaced with QR code sharing

### Known Issues Fixed
- ✅ Nested Expanded widget errors fixed
- ✅ Navigation issues fixed
- ✅ All compilation errors resolved
- ✅ Tournament Hub tabs working correctly

---

## 📞 Support & Maintenance

### Code Organization
- Feature-based structure (easy to maintain)
- Service layer separation (business logic isolated)
- Provider pattern (clean state management)
- Clear naming conventions
- Centralized API keys (`lib/core/config/api_keys.dart`)

### Extension Points
- New sports: Add to `SportType` enum, create facilities
- New booking patterns: Extend `FacilityType` enum
- New user roles: Add to `UserRole` enum, update navigation
- New AI features: Extend `ChatbotService`
- New storage: Update `StorageService` (currently Cloudinary)

---

## 🎯 Current System Capabilities

### What the System Can Do Now

1. **Facility Booking:**
   - Book facilities for 3 sports (Football, Futsal, Badminton)
   - Support for different booking patterns (Session, Hourly, Inventory)
   - Student and public pricing
   - Weather-based recommendations
   - Friday prayer blocking
   - Court selection for badminton

2. **Tournament Management:**
   - Create tournaments with custom details
   - Share tournaments with QR codes
   - Multi-platform sharing (WhatsApp, Twitter, Email, Generic)
   - Join tournaments with payment
   - View tournament details and brackets
   - Cancel tournaments (organizer only)

3. **AI Features:**
   - AI chatbot with role-specific context
   - Natural language help and assistance

4. **Payment System:**
   - Wallet-based payments
   - Top-up functionality
   - Transaction history
   - Escrow for referees
   - Refunds to wallet
   - Tournament entry fees

5. **Referee Marketplace:**
   - Referee certification
   - Job marketplace
   - QR code check-in
   - Escrow payments
   - Merit points

6. **Merit System:**
   - Point tracking
   - PDF transcript generation
   - GP08 integration

---

**END OF PROJECT DOCUMENTATION**

*This document provides a comprehensive, accurate snapshot of the PutraSportHub project as of January 6, 2025. For setup instructions, see [SETUP.md](SETUP.md). For domain knowledge and user flows, see [REFERENCE.md](REFERENCE.md).*

