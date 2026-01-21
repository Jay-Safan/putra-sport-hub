# PUTRASPORT HUB - TESTING DOCUMENTATION

**Last Updated:** January 15, 2026  
**Purpose:** Comprehensive testing documentation for thesis submission  
**App Version:** 1.0.0  
**Platform:** Flutter (iOS & Android)

---

## TABLE OF CONTENTS

1. [Testing Methodology](#testing-methodology)
2. [Test Environment](#test-environment)
3. [User Roles & Test Accounts](#user-roles--test-accounts)
4. [Functional Testing](#functional-testing)
5. [Integration Testing](#integration-testing)
6. [User Acceptance Testing](#user-acceptance-testing)
7. [Performance Testing](#performance-testing)
8. [Security Testing](#security-testing)
9. [Test Results Summary](#test-results-summary)
10. [Known Issues & Limitations](#known-issues--limitations)

---

## TESTING METHODOLOGY

### Testing Approach
- **Manual Testing**: Primary method for functional and user acceptance testing
- **Test-Driven Development**: Critical features validated during development
- **Exploratory Testing**: Ad-hoc testing for edge cases and user experience
- **Role-Based Testing**: Testing across all user roles (Public, Student, Student Referee, Admin)

### Testing Phases
1. **Unit Testing**: Individual components and functions
2. **Integration Testing**: Feature interactions and data flow
3. **System Testing**: End-to-end user flows
4. **User Acceptance Testing**: Real-world usage scenarios
5. **Performance Testing**: Load, response time, and resource usage
6. **Security Testing**: Authentication, authorization, and data protection

---

## TEST ENVIRONMENT

### Development Environment
- **Platform**: Flutter SDK (Latest Stable)
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **Development Devices**: 
  - Android: [Device Model/Emulator]
  - iOS: [Device Model/Simulator]

### Testing Devices
- **Android Devices**: 
  - [ ] Device 1: [Model, OS Version]
  - [ ] Device 2: [Model, OS Version]
- **iOS Devices**: 
  - [ ] Device 1: [Model, iOS Version]
  - [ ] Device 2: [Model, iOS Version]

### Network Conditions
- [ ] Wi-Fi (High-speed)
- [ ] 4G/5G Mobile Data
- [ ] 3G (Slow network simulation)
- [ ] Offline/No Connection

---

## USER ROLES & TEST ACCOUNTS

### User Roles Overview
1. **Public User**: General public, limited booking access
2. **UPM Student**: Full student features, merit points, split bill
3. **Student Referee**: Student + Referee certification, SukanGig access
4. **Admin**: Full system access, analytics, user management

### Test Accounts

| Role | Email | Password | Purpose |
|------|-------|----------|---------|
| Public User | `public@test.com` | `test123` | Public user testing |
| Student | `student@upm.edu.my` | `test123` | Student features testing |
| Student Referee | `referee@upm.edu.my` | `test123` | Referee features testing |
| Admin | `admin@putrasporthub.com` | `admin123` | Admin features testing |

**Note**: Replace with actual test account credentials. Keep secure for thesis documentation.

---

## FUNCTIONAL TESTING

### 1. AUTHENTICATION & USER MANAGEMENT

#### 1.1 User Registration
- [ ] **TC-AUTH-001**: Public user registration with valid email
  - **Steps**: Navigate to Register → Fill form → Submit
  - **Expected**: Account created, redirected to home
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-AUTH-002**: Student registration with UPM email (@upm.edu.my)
  - **Steps**: Register with student email → Verify student privileges
  - **Expected**: Account created with student role, access to student features
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-AUTH-003**: Registration with existing email
  - **Steps**: Attempt to register with existing email
  - **Expected**: Error message "Email already in use"
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-AUTH-004**: Registration with weak password
  - **Steps**: Enter password < 8 characters
  - **Expected**: Validation error, password strength requirement shown
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 1.2 User Login
- [ ] **TC-AUTH-005**: Login with valid credentials
  - **Steps**: Enter email/password → Submit
  - **Expected**: Successful login, redirected to home
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-AUTH-006**: Login with incorrect password
  - **Steps**: Enter correct email, wrong password
  - **Expected**: Error message "Incorrect password"
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-AUTH-007**: Login with non-existent email
  - **Steps**: Enter unregistered email
  - **Expected**: Error message "Account not found"
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 1.3 Profile Management
- [ ] **TC-AUTH-008**: Update profile information
  - **Steps**: Profile → Edit → Update name/phone → Save
  - **Expected**: Profile updated, changes reflected
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-AUTH-009**: Upload profile picture
  - **Steps**: Profile → Change Photo → Select image → Upload
  - **Expected**: Image uploaded, displayed in profile
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

---

### 2. FACILITY BOOKING SYSTEM

#### 2.1 Browse Facilities
- [ ] **TC-BOOK-001**: View available facilities by sport
  - **Steps**: Home → Select sport (Football/Futsal/Badminton/Tennis)
  - **Expected**: Facility list displayed with availability
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-BOOK-002**: Filter facilities by sport type
  - **Steps**: Facility list → Apply sport filter
  - **Expected**: Only selected sport facilities shown
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 2.2 Create Booking (Normal Booking)
- [ ] **TC-BOOK-003**: Create booking as Public User
  - **Steps**: Select facility → Choose date/time → Confirm booking → Pay
  - **Expected**: Booking created, payment processed, booking confirmed
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-BOOK-004**: Create booking as Student (with student rate)
  - **Steps**: Student account → Book facility → Verify student pricing
  - **Expected**: Student rate applied, booking created
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-BOOK-005**: Book unavailable time slot
  - **Steps**: Select already-booked time slot
  - **Expected**: Error "Time slot no longer available"
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-BOOK-006**: Book during Friday prayer time (12:30 PM - 2:30 PM)
  - **Steps**: Select Friday → Choose time between 12:30-2:30 PM
  - **Expected**: Blocked with message about prayer time
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-BOOK-007**: Book past time slot
  - **Steps**: Select date/time in the past
  - **Expected**: Error "Cannot book slots in the past"
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 2.3 Split Bill Booking (Student Only)
- [ ] **TC-BOOK-008**: Create split bill booking
  - **Steps**: Student → Create booking → Enable split bill → Pay share
  - **Expected**: Booking created with team code, organizer pays share only
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-BOOK-009**: Join split bill booking with team code
  - **Steps**: Student → Join booking → Enter team code → Pay share
  - **Expected**: Joined successfully, share amount calculated, payment processed
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-BOOK-010**: Split bill - All participants pay
  - **Steps**: Create split bill → Multiple participants join → All pay
  - **Expected**: Booking auto-confirmed when all participants paid
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-BOOK-011**: Split bill - Participant limit reached
  - **Steps**: Join split bill → Reach sport's max limit (Football: 22, Futsal: 12, Badminton: 8, Tennis: 4)
  - **Expected**: Error "Maximum participants reached"
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-BOOK-012**: Leave split bill booking (before payment)
  - **Steps**: Join split bill → Leave before paying
  - **Expected**: Successfully left, share recalculated for remaining participants
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 2.4 Booking Management
- [ ] **TC-BOOK-013**: View upcoming bookings
  - **Steps**: Bookings tab → Upcoming
  - **Expected**: List of future bookings with details
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-BOOK-014**: View booking history
  - **Steps**: Bookings tab → Past
  - **Expected**: List of past bookings with status
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-BOOK-015**: Cancel booking (within 24 hours)
  - **Steps**: Upcoming booking → Cancel → Provide reason
  - **Expected**: Booking cancelled, refund processed (if within 24h), wallet updated
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-BOOK-016**: Cancel booking (after 24 hours)
  - **Steps**: Book > 24h in future → Cancel
  - **Expected**: Booking cancelled, no refund (policy message shown)
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-BOOK-017**: View booking details/QR code
  - **Steps**: Booking card → View details
  - **Expected**: Booking details shown, QR code displayed
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-BOOK-018**: Check-in using QR code
  - **Steps**: Booking → Show QR code → Scan at facility
  - **Expected**: Check-in successful, booking status updated
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

---

### 3. PAYMENT SYSTEM (SukanPay Wallet)

#### 3.1 Wallet Management
- [ ] **TC-PAY-001**: View wallet balance
  - **Steps**: Profile → Wallet
  - **Expected**: Current balance displayed
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-PAY-002**: Top up wallet
  - **Steps**: Wallet → Top Up → Enter amount → Select method → Confirm
  - **Expected**: Wallet balance increased, transaction recorded
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-PAY-003**: View transaction history
  - **Steps**: Wallet → Transactions
  - **Expected**: List of all transactions (top-ups, payments, refunds)
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 3.2 Payment Processing
- [ ] **TC-PAY-004**: Pay for booking using wallet
  - **Steps**: Create booking → Pay → Use wallet
  - **Expected**: Amount deducted from wallet, booking confirmed
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-PAY-005**: Insufficient wallet balance
  - **Steps**: Create booking → Pay with insufficient balance
  - **Expected**: Error "Insufficient balance. Top up required."
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-PAY-006**: Payment for split bill (organizer)
  - **Steps**: Create split bill → Pay organizer's share
  - **Expected**: Only organizer's share deducted, booking stays pending
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-PAY-007**: Payment for split bill (participant)
  - **Steps**: Join split bill → Pay participant's share
  - **Expected**: Share amount deducted, booking confirmed if all paid
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 3.3 Refunds
- [ ] **TC-PAY-008**: Refund from cancelled booking (within 24h)
  - **Steps**: Cancel booking < 24h before → Verify refund
  - **Expected**: Refund processed, wallet balance updated
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

---

### 4. TOURNAMENT SYSTEM

#### 4.1 Create Tournament (Student Only)
- [ ] **TC-TOUR-001**: Create tournament
  - **Steps**: Student → Tournament → Create → Fill details → Confirm
  - **Expected**: Tournament created, organizer merit points awarded (+5)
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-TOUR-002**: Create tournament with 8-team knockout format
  - **Steps**: Create tournament → Select 8-team knockout
  - **Expected**: Tournament created, bracket initialized
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-TOUR-003**: Create tournament with 4-team group stage
  - **Steps**: Create tournament → Select 4-team group stage
  - **Expected**: Tournament created, group stage bracket initialized
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 4.2 Join Tournament
- [ ] **TC-TOUR-004**: Join tournament (Student)
  - **Steps**: Tournament list → Select → Join → Pay entry fee
  - **Expected**: Joined successfully, entry fee deducted, merit points awarded (+2)
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-TOUR-005**: Join full tournament (8/8 teams)
  - **Steps**: Attempt to join tournament with 8 teams
  - **Expected**: Error "Tournament is full"
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-TOUR-006**: Join tournament with insufficient balance
  - **Steps**: Low balance → Join tournament
  - **Expected**: Error "Insufficient balance for entry fee"
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 4.3 Tournament Management
- [ ] **TC-TOUR-007**: View tournament list (Discover)
  - **Steps**: Tournament → Discover tab
  - **Expected**: All available tournaments displayed
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-TOUR-008**: View my active tournaments
  - **Steps**: Tournament → My Active tab
  - **Expected**: Tournaments user is participating in/organizing
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-TOUR-009**: View tournament details
  - **Steps**: Tournament card → View details
  - **Expected**: Tournament info, bracket, participants shown
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-TOUR-010**: Cancel tournament (Organizer)
  - **Steps**: My Active → Tournament → Cancel
  - **Expected**: Tournament cancelled, entry fees refunded, notifications sent
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

---

### 5. REFEREE MARKETPLACE (SukanGig)

#### 5.1 Referee Certification
- [ ] **TC-REF-001**: Apply for referee certification
  - **Steps**: Profile → Become Referee → Enter QKS code → Submit
  - **Expected**: Badge awarded, referee mode unlocked
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-REF-002**: Apply with invalid QKS code
  - **Steps**: Enter invalid QKS code
  - **Expected**: Error "Invalid certification code"
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 5.2 Job Application
- [ ] **TC-REF-003**: View available jobs
  - **Steps**: SukanGig → Available tab
  - **Expected**: Jobs for certified sports displayed
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-REF-004**: Apply for job (certified sport)
  - **Steps**: Available job → Accept Job
  - **Expected**: Job accepted, moved to "My Jobs", escrow created
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-REF-005**: Apply for job (uncertified sport)
  - **Steps**: Attempt to accept job for uncertified sport
  - **Expected**: Error "Certification required"
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-REF-006**: View my jobs
  - **Steps**: SukanGig → My Jobs tab
  - **Expected**: Accepted jobs displayed with status
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 5.3 Job Completion
- [ ] **TC-REF-007**: Check-in for job
  - **Steps**: My Jobs → Job → Check In
  - **Expected**: Check-in successful, status updated
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-REF-008**: Complete job
  - **Steps**: My Jobs → Job → Complete → Rate organizer
  - **Expected**: Job completed, escrow released, earnings added to wallet, merit points awarded (+3)
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-REF-009**: View job history
  - **Steps**: SukanGig → History tab
  - **Expected**: Past completed jobs with earnings
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 5.4 Earnings
- [ ] **TC-REF-010**: View total earnings
  - **Steps**: SukanGig → View stats
  - **Expected**: Total earnings displayed
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-REF-011**: Verify earnings range (Practice: RM20-40, Tournament: RM20-40 per match)
  - **Steps**: Complete jobs → Verify earnings
  - **Expected**: Earnings match expected range
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

---

### 6. MERIT POINTS SYSTEM (MyMerit)

#### 6.1 Merit Points Earning
- [ ] **TC-MERIT-001**: Earn player merit (+2) from tournament participation
  - **Steps**: Join tournament → Complete tournament
  - **Expected**: +2 points awarded (B1: Player Participation)
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-MERIT-002**: Verify NO merit points for normal booking
  - **Steps**: Create normal booking (not tournament)
  - **Expected**: No merit points awarded
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-MERIT-003**: Earn referee merit (+3) from job completion
  - **Steps**: Complete referee job
  - **Expected**: +3 points awarded (B2: Referee Service)
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-MERIT-004**: Earn organizer merit (+5) from tournament creation
  - **Steps**: Create tournament
  - **Expected**: +5 points awarded (B3: Tournament Organization)
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 6.2 Merit Points Viewing
- [ ] **TC-MERIT-005**: View merit points summary
  - **Steps**: Profile → MyMerit
  - **Expected**: Total points, breakdown by category displayed
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-MERIT-006**: View merit history
  - **Steps**: MyMerit → History
  - **Expected**: List of all merit-earning activities
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-MERIT-007**: Verify semester cap (Max 20 points per semester)
  - **Steps**: Earn points → Verify cap enforcement
  - **Expected**: Points capped at 20 per semester
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 6.3 Merit Points Export
- [ ] **TC-MERIT-008**: Export merit transcript (PDF)
  - **Steps**: MyMerit → Export PDF
  - **Expected**: PDF generated with all merit records, GP08 codes
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

---

### 7. AI CHATBOT

#### 7.1 Chatbot Functionality
- [ ] **TC-AI-001**: Access chatbot
  - **Steps**: Home → Chatbot icon
  - **Expected**: Chatbot interface opens
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-AI-002**: Ask general app questions
  - **Steps**: Chatbot → Ask "How do I book a facility?"
  - **Expected**: Helpful, accurate response about booking process
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-AI-003**: Role-based responses (Student)
  - **Steps**: Student account → Ask student-specific question
  - **Expected**: Response tailored to student role
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-AI-004**: Role-based responses (Public)
  - **Steps**: Public account → Ask about student-only features
  - **Expected**: Polite redirect, explanation of limitations
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-AI-005**: Role-based responses (Referee)
  - **Steps**: Referee account → Ask about SukanGig
  - **Expected**: Detailed referee-specific information
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-AI-006**: Role-based responses (Admin)
  - **Steps**: Admin account → Ask about admin features
  - **Expected**: Admin-focused responses
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

---

### 8. ADMIN DASHBOARD

#### 8.1 Analytics
- [ ] **TC-ADMIN-001**: View user statistics
  - **Steps**: Admin → Dashboard → Users
  - **Expected**: User counts by role displayed
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-ADMIN-002**: View booking statistics
  - **Steps**: Admin → Dashboard → Bookings
  - **Expected**: Booking counts, revenue displayed
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-ADMIN-003**: View revenue statistics
  - **Steps**: Admin → Dashboard → Revenue
  - **Expected**: Total revenue, breakdown by source
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 8.2 User Management
- [ ] **TC-ADMIN-004**: View all users
  - **Steps**: Admin → Users
  - **Expected**: List of all users with details
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-ADMIN-005**: View user details
  - **Steps**: Admin → Users → Select user
  - **Expected**: User profile, bookings, transactions shown
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 8.3 Booking Management
- [ ] **TC-ADMIN-006**: View all bookings
  - **Steps**: Admin → Bookings
  - **Expected**: All bookings listed with status
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-ADMIN-007**: View booking details
  - **Steps**: Admin → Bookings → Select booking
  - **Expected**: Full booking details displayed
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

#### 8.4 Tournament Management
- [ ] **TC-ADMIN-008**: View all tournaments
  - **Steps**: Admin → Tournaments
  - **Expected**: All tournaments listed
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

---

### 9. NOTIFICATIONS

- [ ] **TC-NOTIF-001**: Receive booking confirmation notification
  - **Steps**: Create booking → Complete payment
  - **Expected**: Notification received
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-NOTIF-002**: Receive payment notification
  - **Steps**: Top up wallet
  - **Expected**: Notification received
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-NOTIF-003**: Receive referee job notification
  - **Steps**: Job assigned/available
  - **Expected**: Notification received
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-NOTIF-004**: View notification list
  - **Steps**: Notification icon → View all
  - **Expected**: All notifications displayed
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

---

### 10. WEATHER INTEGRATION

- [ ] **TC-WEATHER-001**: Weather check for outdoor booking
  - **Steps**: Book outdoor facility → Check weather
  - **Expected**: Weather info displayed, rain warnings if applicable
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-WEATHER-002**: Weather blocking outdoor booking
  - **Steps**: Attempt outdoor booking during high rain
  - **Expected**: Booking blocked with weather warning
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

---

## INTEGRATION TESTING

### End-to-End User Flows

- [ ] **TC-INT-001**: Complete Student Booking Flow
  - **Steps**: Register → Book facility → Pay → Receive confirmation → Check-in
  - **Expected**: All steps complete successfully
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-INT-002**: Complete Split Bill Flow
  - **Steps**: Student creates split bill → Participants join → All pay → Booking confirmed
  - **Expected**: All participants pay, booking auto-confirmed
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-INT-003**: Complete Tournament Flow
  - **Steps**: Create tournament → Join → Complete → Merit points awarded
  - **Expected**: Tournament lifecycle complete, points awarded
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-INT-004**: Complete Referee Job Flow
  - **Steps**: Apply for job → Check-in → Complete → Earnings released
  - **Expected**: Job completed, payment processed, merit points awarded
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

- [ ] **TC-INT-005**: Payment and Wallet Integration
  - **Steps**: Top up → Book facility → Pay from wallet → Cancel → Refund
  - **Expected**: All payment operations work correctly
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail
  - **Notes**: 

---

## USER ACCEPTANCE TESTING

### Test Scenarios

- [ ] **TC-UAT-001**: New user onboarding
  - **Scenario**: First-time user registers and makes first booking
  - **User Feedback**: [ ]
  - **Status**: [ ] Pass / [ ] Fail

- [ ] **TC-UAT-002**: Student using all features
  - **Scenario**: Student books facility, creates tournament, joins split bill
  - **User Feedback**: [ ]
  - **Status**: [ ] Pass / [ ] Fail

- [ ] **TC-UAT-003**: Referee earning through SukanGig
  - **Scenario**: Referee applies, completes jobs, earns money
  - **User Feedback**: [ ]
  - **Status**: [ ] Pass / [ ] Fail

- [ ] **TC-UAT-004**: Admin managing system
  - **Scenario**: Admin views analytics, manages users
  - **User Feedback**: [ ]
  - **Status**: [ ] Pass / [ ] Fail

---

## PERFORMANCE TESTING

- [ ] **TC-PERF-001**: App launch time
  - **Target**: < 3 seconds
  - **Actual**: [ ] seconds
  - **Status**: [ ] Pass / [ ] Fail

- [ ] **TC-PERF-002**: List scrolling performance
  - **Target**: Smooth 60 FPS
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail

- [ ] **TC-PERF-003**: Network request response time
  - **Target**: < 2 seconds for API calls
  - **Actual**: [ ] seconds
  - **Status**: [ ] Pass / [ ] Fail

- [ ] **TC-PERF-004**: Image loading performance
  - **Target**: Images load efficiently
  - **Actual**: [ ]
  - **Status**: [ ] Pass / [ ] Fail

---

## SECURITY TESTING

- [ ] **TC-SEC-001**: Authentication security
  - **Test**: Attempt unauthorized access
  - **Expected**: Access denied
  - **Status**: [ ] Pass / [ ] Fail

- [ ] **TC-SEC-002**: Data privacy (users can only see their data)
  - **Test**: User A tries to access User B's bookings
  - **Expected**: Access denied
  - **Status**: [ ] Pass / [ ] Fail

- [ ] **TC-SEC-003**: Payment security
  - **Test**: Attempt to manipulate payment amounts
  - **Expected**: Server-side validation prevents manipulation
  - **Status**: [ ] Pass / [ ] Fail

- [ ] **TC-SEC-004**: Input validation
  - **Test**: Submit malicious input (SQL injection, XSS attempts)
  - **Expected**: Input sanitized/rejected
  - **Status**: [ ] Pass / [ ] Fail

---

## TEST RESULTS SUMMARY

### Overall Test Statistics

| Category | Total Tests | Passed | Failed | Pass Rate |
|----------|-------------|--------|--------|-----------|
| Authentication | [ ] | [ ] | [ ] | [ ]% |
| Booking | [ ] | [ ] | [ ] | [ ]% |
| Payment | [ ] | [ ] | [ ] | [ ]% |
| Tournament | [ ] | [ ] | [ ] | [ ]% |
| Referee | [ ] | [ ] | [ ] | [ ]% |
| Merit Points | [ ] | [ ] | [ ] | [ ]% |
| AI Chatbot | [ ] | [ ] | [ ] | [ ]% |
| Admin | [ ] | [ ] | [ ] | [ ]% |
| Integration | [ ] | [ ] | [ ] | [ ]% |
| Performance | [ ] | [ ] | [ ] | [ ]% |
| Security | [ ] | [ ] | [ ] | [ ]% |
| **TOTAL** | **[ ]** | **[ ]** | **[ ]** | **[ ]%** |

### Critical Bugs Found

| Bug ID | Description | Severity | Status | Notes |
|--------|-------------|----------|--------|-------|
| BUG-001 | [ ] | [ ] | [ ] | [ ] |
| BUG-002 | [ ] | [ ] | [ ] | [ ] |

### Known Issues

| Issue ID | Description | Impact | Workaround | Priority |
|----------|-------------|--------|------------|----------|
| ISSUE-001 | [ ] | [ ] | [ ] | [ ] |

---

## KNOWN ISSUES & LIMITATIONS

### Current Limitations

1. **Firestore Security Rules**: Currently permissive for development (must be tightened for production)
2. **Payment Gateway**: Uses simulated wallet system (no real payment gateway integration)
3. **Push Notifications**: In-app notifications only (no push notifications)
4. **Tournament Brackets**: Fixed formats only (8-team knockout, 4-team group stage)
5. **Offline Mode**: Limited offline functionality

### Future Improvements

- [ ] Implement push notifications
- [ ] Add payment gateway integration
- [ ] Enhance tournament bracket builder
- [ ] Improve offline functionality
- [ ] Add more sports support

---

## TESTING NOTES

### Testing Environment Setup
- Date Started: [ ]
- Date Completed: [ ]
- Testers: [ ]
- Testing Tools: [ ]

### Additional Notes
[Add any additional testing notes, observations, or recommendations here]

---

**Document Version**: 1.0  
**Last Updated**: January 15, 2026  
**Prepared By**: [Your Name]  
**Reviewed By**: [Supervisor Name]
