# PUTRASPORT HUB - COMPLETE PROJECT CONTEXT DOCUMENT
## *For Academic Thesis/Proposal Writing with AI Assistance*

**Last Updated:** January 22, 2026  
**Purpose:** Copy-paste this document into ChatGPT when writing your thesis/proposal

---

## PART 1: PROJECT IDENTITY

### App Name
**PutraSportHub**

### Tagline
"Where Campus Sports Meet Technology"

### Institution
Universiti Putra Malaysia (UPM) - Serdang, Selangor, Malaysia

### Project Type
Final Year Project (FYP) - Mobile Application Development  
Department: Computer Science / Software Engineering

### Platform
Cross-platform Mobile App (iOS & Android) built with Flutter 3.7+

### Development Status
**95% Complete - Production Ready** ✅  
**All Research Objectives Met** ✅  
**Ready for Thesis Defense/Demo** ✅  
**Last Major Fix:** January 22, 2026 (Critical login navigation bug resolved)

---

## PART 2: PROBLEM STATEMENT

### The Core Problems

**Problem 1: Manual Paper-Based Booking System ("Borang")**
- Current UPM sports facility booking requires students to physically visit the Pusat Sukan office
- Students must fill out paper forms ("Borang Tempahan")
- Wait 1-3 days for manual confirmation
- No real-time availability checking leads to double-bookings
- Cash-only payments with no refund mechanism (UPM Bursar takes 3 months for refunds)

**Problem 2: No Gig Economy for Student Referees**
- UPM offers referee certification courses (QKS2101-QKS2104) through Akademi Sukan
- After certification, students have NO platform to monetize their skills
- Tournament organizers struggle to find certified referees
- No payment protection for either party

**Problem 3: Fragmented Merit Point Tracking**
- UPM Housing Policy (MERIT_KOLEJ) requires students to accumulate merit points for residential college accommodation
- GP08 Guidelines (UPM/KK/TAD/GP08) define merit point categories
- Currently, students manually track points across multiple systems
- Risk of losing documentation, delayed verification

### Why This Matters
- **Housing Crisis**: Students NEED merit points to stay in residential colleges
- **Financial Opportunity**: Certified referee students have no income platform
- **Administrative Burden**: Manual processes waste time for staff and students

---

## PART 3: PROJECT OBJECTIVES

### Research Objectives (RO)

**RO1**: To develop a mobile application that digitizes UPM sports facility booking with real-time availability, automated confirmation, and digital payment processing.

**RO2**: To implement a gig economy marketplace (SukanGig) that connects certified student referees with tournament organizers, featuring escrow-based payment protection.

**RO3**: To integrate the UPM GP08 merit point system for automatic tracking and verification of student sports participation activities.

### Additional Objectives
- Implement AI-powered chatbot for user assistance
- Support multiple user roles (Student, Public, Referee, Admin)
- Enable split bill functionality for group bookings
- Provide tournament creation and management system

---

## PART 4: SCOPE & LIMITATIONS

### In Scope
- **Sports Supported**: Football, Futsal, Badminton, Tennis
- **User Types**: UPM Students, Public Users, Certified Referees, Administrators
- **Core Features**: Booking, Payment (Wallet), Referee Marketplace, Tournaments, Merit Tracking
- **Platform**: Mobile (iOS/Android via Flutter)
- **Backend**: Firebase (Firestore, Authentication)

### Out of Scope
- Web application version
- Push notifications (in-app only)
- Complex tournament bracket builder (uses fixed formats)
- Integration with UPM's actual administrative systems
- Payment gateway integration (simulated wallet system)

### Limitations
- Requires internet connectivity
- Limited to 4 sports (expandable)
- Referee certification is self-declared (no actual UPM verification integration)

---

## PART 5: USER ROLES & ACCESS CONTROL

### Role 1: Public User
- **Detection**: Email NOT ending with `@student.upm.edu.my`
- **Firestore Fields**: `role: 'PUBLIC'`, `isStudent: false`
- **Can Do**:
  - Book facilities at public rates (RM20-600)
  - Top-up and manage wallet
  - Use AI chatbot (public context)
- **Cannot Do**:
  - Access tournaments
  - Use split bill
  - Earn merit points
  - Apply as referee
- **Navigation**: Home → Bookings → AI Help → Profile

### Role 2: Student
- **Detection**: Email ending with `@student.upm.edu.my`
- **Firestore Fields**: `role: 'STUDENT'`, `isStudent: true`
- **Can Do**:
  - Book facilities at student rates (RM3-10)
  - Create and join tournaments
  - Use split bill for bookings
  - Earn merit points (GP08)
  - Apply for referee certification
  - Use AI chatbot (full context)
- **Navigation**: Home → Bookings → Tournaments → AI Help → Profile

### Role 3: Student Referee
- **Detection**: Student with badges array containing `VERIFIED_REF_*`
- **Firestore Fields**: `badges: ['VERIFIED_REF_FOOTBALL']`, `preferredMode: 'REFEREE'`
- **Can Do**:
  - Everything a Student can do
  - Switch between Student Mode and Referee Mode
  - Browse and accept referee jobs (filtered by badges)
  - Check-in at venues via QR code
  - Receive escrow-protected payments
  - Earn referee merit points (B2 category)
- **Referee Mode Navigation**: Home → SukanGig → AI Help → Profile

### Role 4: Administrator
- **Detection**: Firestore `role: 'ADMIN'`
- **Can Do**:
  - Access admin dashboard
  - View all users, bookings, tournaments, transactions
  - Manage facilities
  - View analytics
- **Cannot Do**:
  - Book facilities (redirected to admin)
  - Participate in tournaments
- **Navigation**: Admin → AI Help → Profile

---

## PART 6: TECHNICAL ARCHITECTURE

### Technology Stack

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| Frontend | Flutter | 3.7+ | Cross-platform UI |
| Language | Dart | Latest | Programming language |
| Backend | Firebase Firestore | Latest | NoSQL database |
| Auth | Firebase Auth | Latest | User authentication |
| State | Riverpod | 2.6+ | State management |
| Routing | GoRouter | 14.8+ | Navigation |
| AI | Google Gemini API | Latest | Chatbot |
| Weather | OpenWeatherMap API | Latest | Weather data |
| Maps | Google Maps Static API | Latest | Facility maps |

### Project Structure

```
lib/
├── core/
│   ├── config/           # API keys, Firebase options
│   ├── constants/        # AppConstants, Enums
│   ├── navigation/       # GoRouter config, MainScaffold
│   ├── permissions/      # RoleGuards, AccessControl
│   ├── theme/            # AppTheme (colors, typography)
│   ├── utils/            # DateTimeUtils, QRUtils, Validators
│   └── widgets/          # Reusable UI components
│
├── features/
│   ├── auth/             # Login, Register, ForgotPassword
│   ├── home/             # Home dashboard
│   ├── booking/
│   │   ├── data/models/  # BookingModel, FacilityModel
│   │   └── presentation/
│   │       ├── shared/   # Common booking screens
│   │       └── student/  # Split bill screens
│   ├── payment/          # Wallet, TopUp, Transactions
│   ├── referee/          # SukanGig dashboard, Application
│   ├── tournament/
│   │   ├── data/models/  # TournamentModel
│   │   └── presentation/
│   │       ├── shared/   # List, Detail, Join screens
│   │       └── student/  # Create tournament
│   ├── merit/            # Merit screen, PDF export
│   ├── profile/          # Profile, Settings
│   ├── admin/            # Admin dashboard, Management
│   ├── ai/               # Chatbot screen
│   └── notifications/    # Notifications screen
│
├── services/             # Business logic layer
│   ├── auth_service.dart
│   ├── booking_service.dart
│   ├── payment_service.dart
│   ├── referee_service.dart
│   ├── tournament_service.dart
│   ├── merit_service.dart
│   ├── weather_service.dart
│   ├── chatbot_service.dart
│   ├── notification_service.dart
│   └── storage_service.dart
│
└── providers/
    └── providers.dart    # Riverpod providers
```

### Architecture Pattern
- **Feature-Based Modular Architecture**
- **Clean Architecture Principles**: Separation of Presentation, Business Logic, and Data layers
- **Dependency Injection**: Via Riverpod providers

---

## PART 7: DATABASE SCHEMA (FIRESTORE)

### Collections

#### `users`
```json
{
  "uid": "string (Firebase Auth UID)",
  "email": "string",
  "full_name": "string",
  "matric_no": "string | null",
  "role": "STUDENT | PUBLIC | ADMIN",
  "isStudent": "boolean",
  "badges": ["VERIFIED_REF_FOOTBALL"],
  "wallet_balance": "number",
  "merit_points_total": "number",
  "preferredMode": "STUDENT | REFEREE | null",
  "createdAt": "timestamp",
  "lastLoginAt": "timestamp",
  "isActive": "boolean"
}
```

#### `facilities`
```json
{
  "id": "string",
  "name": "string",
  "sport": "FOOTBALL | FUTSAL | BADMINTON | TENNIS",
  "type": "SESSION | INVENTORY",
  "location": "string",
  "description": "string",
  "price_student": "number",
  "price_public": "number",
  "is_indoor": "boolean",
  "subUnits": ["Court 1", "Court 2"],
  "isActive": "boolean"
}
```

#### `bookings`
```json
{
  "id": "string",
  "facilityId": "string",
  "facilityName": "string",
  "sport": "string",
  "userId": "string",
  "userName": "string",
  "userEmail": "string",
  "isStudentBooking": "boolean",
  "subUnit": "string | null",
  "bookingDate": "timestamp",
  "startTime": "timestamp",
  "endTime": "timestamp",
  "facilityFee": "number",
  "refereeFee": "number | null",
  "totalAmount": "number",
  "status": "PENDING_PAYMENT | CONFIRMED | IN_PROGRESS | COMPLETED | CANCELLED | REFUNDED",
  "isSplitBill": "boolean",
  "splitBillParticipants": [
    {
      "oderId": "string",
      "userId": "string",
      "email": "string",
      "name": "string",
      "shareAmount": "number",
      "hasPaid": "boolean",
      "paidAt": "timestamp | null"
    }
  ],
  "teamCode": "string | null (e.g., TIGER-882)",
  "qrCode": "string",
  "bookingType": "PRACTICE | MATCH",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### `tournaments`
```json
{
  "id": "string",
  "title": "string",
  "description": "string",
  "sport": "FOOTBALL | FUTSAL | BADMINTON | TENNIS",
  "format": "8_TEAM_KNOCKOUT | 4_TEAM_GROUP",
  "organizerId": "string",
  "organizerName": "string",
  "facilityId": "string",
  "facilityName": "string",
  "startDate": "timestamp",
  "endDate": "timestamp",
  "entryFee": "number",
  "maxTeams": "number",
  "registeredTeams": [
    {
      "oderId": "string",
      "teamId": "string",
      "teamName": "string",
      "captainId": "string",
      "captainName": "string",
      "registeredAt": "timestamp",
      "hasPaid": "boolean"
    }
  ],
  "status": "REGISTRATION_OPEN | REGISTRATION_CLOSED | IN_PROGRESS | COMPLETED | CANCELLED",
  "shareCode": "string",
  "isStudentOnly": "boolean",
  "createdAt": "timestamp"
}
```

#### `referee_jobs` (SukanGig)
```json
{
  "id": "string",
  "bookingId": "string | null",
  "tournamentId": "string | null",
  "sport": "string",
  "facilityId": "string",
  "facilityName": "string",
  "matchDate": "timestamp",
  "startTime": "timestamp",
  "endTime": "timestamp",
  "payoutAmount": "number",
  "refereesRequired": "number",
  "assignedReferees": [
    {
      "oderId": "string",
      "userId": "string",
      "name": "string",
      "email": "string",
      "role": "SOLO | MAIN_REFEREE | LINESMAN",
      "assignedAt": "timestamp",
      "checkedIn": "boolean",
      "checkedInAt": "timestamp | null"
    }
  ],
  "status": "OPEN | ASSIGNED | COMPLETED | PAID | CANCELLED",
  "notes": "string",
  "createdAt": "timestamp"
}
```

#### `wallets`
```json
{
  "userId": "string",
  "balance": "number",
  "escrowBalance": "number",
  "pendingBalance": "number",
  "currency": "MYR",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### `transactions`
```json
{
  "id": "string",
  "oderId": "string",
  "userId": "string",
  "userEmail": "string",
  "type": "TOP_UP | BOOKING_PAYMENT | REFUND | REFEREE_PAYMENT | ESCROW_RELEASE | TOURNAMENT_ENTRY_FEE",
  "amount": "number",
  "status": "PENDING | COMPLETED | FAILED",
  "description": "string",
  "referenceId": "string | null",
  "createdAt": "timestamp",
  "completedAt": "timestamp | null",
  "metadata": "object"
}
```

#### `escrow`
```json
{
  "id": "string",
  "jobId": "string",
  "bookingId": "string",
  "refereeId": "string",
  "amount": "number",
  "status": "HELD | RELEASED | REFUNDED",
  "createdAt": "timestamp",
  "releasedAt": "timestamp | null"
}
```

#### `merit_records`
```json
{
  "id": "string",
  "oderId": "string",
  "userId": "string",
  "userEmail": "string",
  "userName": "string",
  "matricNo": "string | null",
  "category": "SPORTS | LEADERSHIP",
  "activityType": "PLAYER_PARTICIPATION | REFEREE_SERVICE | SUKOL_ORGANIZER",
  "sport": "string",
  "activityDescription": "string",
  "points": "number",
  "gp08Code": "B1 | B2 | B3",
  "referenceId": "string",
  "activityDate": "timestamp",
  "semester": "string",
  "academicYear": "string",
  "createdAt": "timestamp"
}
```

#### `notifications`
```json
{
  "id": "string",
  "userId": "string",
  "title": "string",
  "message": "string",
  "type": "NotificationType enum",
  "referenceId": "string | null",
  "read": "boolean",
  "createdAt": "timestamp"
}
```

---

## PART 8: CORE FEATURES DETAILED

### Feature 1: Smart Facility Booking

**What It Does:**
- Real-time slot availability checking
- Two booking patterns: SESSION (Football, Futsal) and INVENTORY (Badminton, Tennis)
- Tiered pricing (Student RM3-10, Public RM20-600)
- Friday prayer time blocking (12:15 PM - 2:45 PM)
- Weather-based recommendations for outdoor facilities
- QR code generation for venue check-in

**Key Services:**
- `BookingService.getAvailableSlots()` - Checks availability
- `BookingService.createBooking()` - Creates booking
- `BookingService.cancelBooking()` - Handles cancellation with refund

**Data Flow:**
```
User selects sport → Facility List → Select Date/Time → Check Availability →
Create Booking (PENDING_PAYMENT) → Process Payment → Status: CONFIRMED →
Generate QR Code
```

### Feature 2: Split Bill System

**What It Does:**
- Students can split booking cost with friends
- Sport-based participant limits (Football: 22, Futsal: 12, Badminton: 8, Tennis: 4)
- Team code generation (e.g., "TIGER-882")
- Share via QR code or deep link
- Auto-confirmation when all participants pay
- Proportional refunds on cancellation

**Key Services:**
- `BookingService.createBooking(isSplitBill: true)` - Creates split bill booking
- `PaymentService.processSplitBillPayment()` - Handles participant payment
- `BookingService.joinSplitBillBooking()` - Participant joins via code

**Data Flow:**
```
Organizer creates split bill booking → Pays their share → Team code generated →
Share with friends → Friends join via code → Each pays their share →
All paid? → Auto-confirm booking
```

### Feature 3: Tournament Management

**What It Does:**
- Create tournaments with custom details
- Two formats: 8-Team Knockout, 4-Team Group
- Team registration with entry fee payment
- Share tournaments via QR codes
- Multi-platform sharing (WhatsApp, Twitter, Email)
- Automatic status lifecycle management

**Key Services:**
- `TournamentService.createTournament()` - Creates tournament
- `TournamentService.joinTournament()` - Team registration (atomic transaction)
- `TournamentService._createRefereeJobsForTournament()` - Auto-creates referee jobs

**Status Lifecycle:**
```
REGISTRATION_OPEN → (Teams fill up) → REGISTRATION_CLOSED →
(Tournament starts) → IN_PROGRESS → (All matches done) → COMPLETED
```

### Feature 4: SukanGig (Referee Marketplace)

**What It Does:**
- Job marketplace for certified student referees
- Jobs filtered by user's certification badges
- Escrow-based payment protection
- QR code venue check-in
- Rating system for referees
- Merit points (B2) on job completion

**Referee Certification Process:**
1. Student navigates to Profile → "Become a Referee"
2. Selects course code (QKS2101-QKS2104)
3. Badge added to `user.badges[]`
4. SukanGig tab appears in navigation

**Badge Mapping:**
```
QKS2101 → VERIFIED_REF_FOOTBALL
QKS2102 → VERIFIED_REF_BADMINTON
QKS2103 → VERIFIED_REF_TENNIS
QKS2104 → VERIFIED_REF_FUTSAL
```

**Key Services:**
- `RefereeService.getAvailableJobs()` - Fetches open jobs
- `RefereeService.applyForJob()` - Referee accepts job
- `RefereeService.checkIn()` - QR code venue check-in
- `RefereeService.completeJob()` - Releases escrow, awards merit

**Job Lifecycle:**
```
OPEN → (Referee accepts) → ASSIGNED → (QR check-in) →
(Match complete) → COMPLETED → (Escrow released) → PAID
```

### Feature 5: Payment System (SukanPay)

**What It Does:**
- Digital wallet for all transactions
- Top-up functionality (simulated)
- Booking payments
- Tournament entry fees
- Escrow holding for referee payments
- Refunds (always to wallet, never external)

**Transaction Types:**
- TOP_UP - Wallet recharge
- BOOKING_PAYMENT - Facility booking
- REFUND - Cancelled booking refund
- REFEREE_PAYMENT - Referee job payment
- ESCROW_RELEASE - Escrow to referee wallet
- TOURNAMENT_ENTRY_FEE - Tournament registration

**Key Services:**
- `PaymentService.topUpWallet()` - Add funds
- `PaymentService.processBookingPayment()` - Deduct for booking
- `PaymentService.processRefund()` - Return funds to wallet
- `PaymentService.releaseEscrow()` - Pay referee

### Feature 6: Merit System (MyMerit)

**What It Does:**
- Automatic merit point tracking
- GP08-compliant categorization
- Semester-based tracking with 15-point cap
- PDF transcript generation
- UPM branding on certificates

**Point Categories (GP08):**
```
B1 (Player Participation): +2 points - ONLY for tournament participation (NOT normal bookings)
B2 (Referee Service): +3 points - For completing referee jobs
B3 (Tournament Organizer): +5 points - For organizing tournaments
Maximum per semester: 15 points
```

**Important Rules:**
- Player merit points (+2) are ONLY awarded when students participate in tournaments
- Normal facility bookings (practice sessions) do NOT award player merit points
- Only tournament participation counts toward player merit points

**Key Services:**
- `MeritService.awardPlayerMerit()` - Awards B1 points
- `MeritService.awardRefereeMerit()` - Awards B2 points
- `MeritService.awardOrganizerMerit()` - Awards B3 points
- `MeritService.generateMeritTranscript()` - PDF export

### Feature 7: AI Chatbot

**What It Does:**
- Context-aware help assistant
- Role-specific responses (students see tournaments, public doesn't)
- Powered by Google Gemini API
- Natural language understanding

**Key Services:**
- `ChatbotService.sendMessage()` - Sends message to Gemini
- System prompts customized per user role

---

## PART 9: BUSINESS RULES & CONSTRAINTS

### Operational Rules

1. **Operating Hours**: 8:00 AM - 10:00 PM daily
2. **Friday Prayer Block**: CLOSED 12:15 PM - 2:45 PM
3. **Max Booking Duration**: 2 hours (UPM policy "MAKSIMUM 2 JAM")
4. **Cancellation Policy**: Must cancel 24+ hours before booking

### Pricing Rules

**Student Rates (Platform Fee Only - Facility Access Free per UPM Policy):**
| Sport | Student Price |
|-------|---------------|
| Football | RM10 |
| Futsal | RM5 |
| Badminton | RM3/hour |
| Tennis | RM5/hour |

**Public Rates (Full Rental - Official UPM Akademi Sukan Rates):**
| Facility | Public Price |
|----------|--------------|
| Football Stadium | RM600 |
| Football Padang A-E | RM250 |
| Futsal | RM100 |
| Badminton | RM20/hour |
| Tennis | RM20/hour |

### Referee Requirements by Sport

| Sport | Referees Required | Rate per Match (Tournament) | Rate per Session (Practice) |
|-------|-------------------|-----------------------------|-----------------------------|
| Football | 3 (1 main + 2 linesmen) | RM120 total | RM60 total |
| Futsal | 1 (solo) | RM40 | RM20 |
| Badminton | 1 (umpire) | RM40 | RM20 |
| Tennis | 1 (chair umpire) | RM40 | RM20 |

### Weather Rules
- Rain threshold: >5mm or >60% probability
- Outdoor facilities blocked during rain
- Auto-refund for cancelled outdoor bookings

---

## PART 10: UI/UX DESIGN

### Design Style
- **Theme**: Dark Mode with Glassmorphism
- **Vibe**: Premium, Minimalist, University-Official

### Color Palette
```
Primary Green: #1B5E20 (UPM Forest Green)
Primary Red: #B22222 (UPM Red)
Accent Gold: #FFD700 (Championship Gold)
Dark Background: #0A1F1A (Deep Dark Green)
Dark Surface: #0D2E26
Dark Card: #122D24
```

### Glass Widget Specs
```
Blur: BackdropFilter (sigmaX: 10, sigmaY: 10)
Fill: Colors.white.withOpacity(0.08)
Border: Colors.white.withOpacity(0.2), 1px
```

### Navigation Pattern
- Bottom navigation with role-based items
- Glassmorphic floating nav bar
- Tab transitions with fade animations
- Flow transitions with slide-in from right

---

## PART 11: DATA FLOW DIAGRAMS

### Booking Flow
```
User → Home Screen → Select Sport → Facility List → Select Facility →
Booking Flow Screen → Select Date → Select Time Slot → Check Availability →
[Split Bill?] → Enable/Disable → Review Details → Confirm & Pay →
Payment Service → Deduct Wallet → Create Booking → Generate QR →
Notification → Success Screen
```

### Tournament Creation Flow
```
Student → Tournaments → Create Tournament → Select Sport → Select Facility →
Select Format (8-team/4-team) → Select Date & Duration → Enter Details →
Set Entry Fee → Create → Tournament Created → Share Code Generated →
Notification
```

### Referee Job Flow
```
Tournament Created → Registration Closes → Auto-Create Referee Jobs →
Jobs appear in SukanGig → Certified Referee browses → Applies for Job →
Validation (badge check) → Assigned → Match Day → QR Check-in →
Match Completed → Escrow Released → Merit Awarded → Notification
```

### Payment Flow
```
User → Wallet → Top-Up → Select Amount → Process Payment (simulated) →
Update Wallet Balance → Create Transaction Record → Show Confirmation
```

---

## PART 12: SECURITY & ACCESS CONTROL

### Authentication
- Firebase Authentication (Email/Password)
- Role detection on login via email domain
- JWT-based session management

### Route Guards
- Unauthenticated → Redirect to `/login`
- Public user accessing tournaments → Redirect to `/home`
- Admin accessing home → Redirect to `/admin`
- Referee mode restrictions on booking routes

### Firestore Security Rules Summary
- Users: Read/write own document only
- Bookings: Create own, read own + admin
- Facilities: Read all, write admin only
- Transactions: Read own, write service-level only

---

## PART 13: TESTING ACCOUNTS

| Role | Email | Password |
|------|-------|----------|
| Student | ali@student.upm.edu.my | Password123 |
| Student Referee | haziq@student.upm.edu.my | Password123 |
| Public | public@example.com | Password123 |
| Admin | admin@upm.edu.my | AdminPass123 |

---

## PART 14: PROJECT METRICS

- **Total Features**: 11 major modules
- **Services**: 11 business logic services
- **Screens**: 30+ UI screens
- **Data Models**: 10+ models
- **Firestore Collections**: 10+
- **Lines of Code**: ~20,000+ (estimated)
- **Sports Supported**: 4
- **User Roles**: 4
- **Tournament Formats**: 2

---

## PART 15: KEYWORDS FOR THESIS

**Technical Keywords:**
Flutter, Firebase, Firestore, NoSQL, Riverpod, State Management, Mobile Application, Cross-Platform, REST API, Gemini AI, Real-time Database

**Domain Keywords:**
Sports Facility Management, Gig Economy, Escrow Payment, Merit System, GP08, University Campus, Booking System, Tournament Management, Referee Marketplace

**Academic Keywords:**
Digital Transformation, Smart Campus, Mobile-First, User Experience, Role-Based Access Control, Automated Workflow

---

## PART 16: OFFICIAL UPM REFERENCES

### Documents & Policies
- **Merit Guideline**: UPM/KK/TAD/GP08 (Garis Panduan Pengiraan Merit)
- **Housing Policy**: MERIT_KOLEJ (Students need points for college accommodation)
- **Pricing Source**: UPM Akademi Sukan Official Price List 2024

### Referee Course Codes (Pusat Kokurikulum)
| Sport | Course Code | Description |
|-------|-------------|-------------|
| Football | QKS2101 | Kursus Pengadil Bola Sepak |
| Badminton | QKS2102 | Kursus Pengadil Badminton |
| Tennis | QKS2103 | Kursus Pengadil Tenis |
| Futsal | QKS2104 | Kursus Pengadil Futsal |

### Facility Locations (GPS Coordinates)
| Facility | Latitude | Longitude |
|----------|----------|-----------|
| Stadium UPM | 2.9864 | 101.7258 |
| Padang A (KMR) | 2.9977 | 101.7060 |
| Padang B (KMR) | 2.9961 | 101.7070 |
| Padang C (KMR) | 2.9952 | 101.7077 |
| Padang D (Serumpun) | 2.9919 | 101.7166 |
| Padang E (K10) | 3.0079 | 101.7179 |
| Futsal Complex | 2.9868 | 101.7246 |
| Badminton Hall | 2.9868 | 101.7246 |
| Tennis Courts | 2.9974 | 101.7043 |

---

## HOW TO USE THIS DOCUMENT WITH CHATGPT

### For Proposal Writing:
Copy-paste the relevant sections when asking ChatGPT to help with:
- Introduction/Background → Parts 1, 2
- Problem Statement → Part 2
- Objectives → Part 3
- Scope → Part 4
- Literature Review gaps → Parts 2, 8 (compare with existing systems)

### For Thesis Writing:
- Methodology → Parts 6, 7, 11
- System Design → Parts 6, 7
- Implementation → Parts 8, 9
- Testing → Part 13
- Results/Discussion → Part 14

### Example Prompts for ChatGPT:

**For Problem Statement:**
```
Based on this project context [paste Part 2], write a formal Problem Statement section for my thesis proposal. Use academic writing style.
```

**For Objectives:**
```
Based on these objectives [paste Part 3], help me write the Research Objectives section with proper RO1, RO2, RO3 format for my thesis.
```

**For System Architecture:**
```
Based on this technical architecture [paste Part 6], help me write the System Architecture chapter for my thesis with appropriate diagrams descriptions.
```

**For Implementation:**
```
Based on these feature details [paste Part 8], help me write the Implementation chapter focusing on the [specific feature] for my thesis.
```

---

## QUICK SUMMARY (1 PARAGRAPH)

PutraSportHub is a Flutter-based cross-platform mobile application developed to digitize the sports facility management ecosystem at Universiti Putra Malaysia (UPM). The system addresses three core problems: (1) the inefficient paper-based booking system ("Borang") that causes delays and double-bookings, (2) the absence of a gig economy platform for certified student referees to monetize their skills, and (3) the fragmented manual tracking of GP08 merit points required for student housing eligibility. The application supports four user roles (Student, Public, Referee, Admin) with role-specific features including real-time facility booking with split bill functionality, a referee marketplace (SukanGig) with escrow-protected payments, tournament creation and management, automated merit point tracking with PDF export, and an AI-powered chatbot. Built using Firebase Firestore for backend services and Riverpod for state management, the system implements a feature-based modular architecture that ensures scalability and maintainability. The application is 95% complete and production-ready, demonstrating practical digital transformation of university sports management.

---

**END OF CONTEXT DOCUMENT**

*Last Updated: January 15, 2026*
*Document Version: 1.1*
