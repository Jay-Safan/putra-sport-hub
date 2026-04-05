# PutraSportHub - Domain Knowledge & Reference
**Version:** 1.4.0  
**Last Updated:** January 26, 2026  
**Purpose:** Domain knowledge, business rules, and user flows for developers

---

## 📋 Table of Contents
1. [Project Identity & Core Mission](#1-project-identity--core-mission)
2. [Technical Architecture](#2-technical-architecture)
3. [Verified Domain Data](#3-verified-domain-data-source-of-truth)
4. [Database Schema](#4-detailed-database-schema-firestore)
5. [Critical Business Logic](#5-critical-business-logic)
6. [UI/UX Design System](#6-uiux-design-system-glassmorphism)
7. [User Experience Flows](#7-user-experience-flows)
8. [Domain Context & UX Strategy](#8-domain-context--ux-strategy)

---

## 1. Project Identity & Core Mission

**PutraSportHub** is a "Smart Campus" mobile ecosystem designed to digitize the sports lifecycle at UPM. It replaces manual paper forms with an automated app that integrates Venue Booking, the Gig Economy, and Academic Merit.

* **The Problem:** Current booking requires physical forms ("Borang"), cash payments, and manual verification for merit points.
* **The Solution:** An app that automates bookings, instant refunds via wallet, and verifies referee work for merit.
* **The "Grade A" Factor:** It solves the "Housing Merit" crisis for students by automating GP08 point collection.

---

## 2. Technical Architecture

* **Frontend:** Flutter (Latest Stable).
* **Backend:** Firebase (Firestore, Auth, Storage, Cloud Functions).
* **State Management:** Riverpod (Use `autoDispose` providers).
* **Routing:** GoRouter.
* **External APIs:**
    * **OpenWeatherMap:** Lat/Long `2.999, 101.707` (UPM Serdang).
    * **Gemini API:** For AI chatbot (role-specific context).

---

## 3. Verified Domain Data (Source of Truth)

*Strictly use these values. They are based on official UPM policies.*

### **A. Facility Pricing & Logic (Akademi Sukan)**

*Note: Student pricing represents small booking fees (facility access free per UPM policy). Public pricing is full rental rate.*

| Sport | Facility Name | Location | Booking Type | Student Price | Public Price | Logic Pattern |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Football** | Stadium UPM (Premium) | Main Stadium Complex | Session (2 Hours) | **RM 10.00** (fee) | RM 600.00 | 3 Referees (1 main + 2 linesmen) |
| **Football** | Padang A | Near KMR | Session (2 Hours) | **RM 10.00** (fee) | RM 250.00 | 3 Referees (1 main + 2 linesmen) |
| **Football** | Padang B | Near KMR | Session (2 Hours) | **RM 10.00** (fee) | RM 250.00 | 3 Referees (1 main + 2 linesmen) |
| **Football** | Padang C | Near KMR | Session (2 Hours) | **RM 10.00** (fee) | RM 250.00 | 3 Referees (1 main + 2 linesmen) |
| **Football** | Padang D | Kolej Serumpun | Session (2 Hours) | **RM 10.00** (fee) | RM 250.00 | 3 Referees (1 main + 2 linesmen) |
| **Football** | Padang E | Kolej 10 (K10) | Session (2 Hours) | **RM 10.00** (fee) | RM 250.00 | 3 Referees (1 main + 2 linesmen) |
| **Futsal** | Gelanggang Futsal A-D | Sports Complex | Session (2 Hours) | **RM 5.00** (fee) | RM 100.00 | 1 Referee (solo) |
| **Badminton** | Dewan Serbaguna | Main Campus | Hourly (max 2h) | **RM 3.00** (fee) | RM 20.00 | 1 Umpire. Courts 1-8. Multi-hour. |
| **Tennis** | Gelanggang Tenis UPM | Tennis Complex | Hourly (max 2h) | **RM 5.00** (fee) | RM 20.00 | 1 Chair Umpire (opt). Courts 1-14. Multi-hour. |

### **A.1. Facility GPS Coordinates (Verified)**

*All coordinates verified via Google Maps. Used for Google Static Maps API in booking details.*

| Facility | Latitude | Longitude |
| :--- | :--- | :--- |
| **Stadium UPM** | 2.986372108422893 | 101.72579628891536 |
| **Padang A (Near KMR)** | 2.997660204655413 | 101.70600927089941 |
| **Padang B (Near KMR)** | 2.9960699996249094 | 101.7069976276016 |
| **Padang C (Near KMR)** | 2.995181678690454 | 101.70770111887524 |
| **Padang D (Kolej Serumpun)** | 2.9918733483331974 | 101.71658472158012 |
| **Padang E (Kolej 10)** | 3.0078650418969475 | 101.71792061303512 |
| **Gelanggang Futsal A-D** | 2.9868095178480107 | 101.7245986302808 |
| **Dewan Serbaguna (Badminton)** | 2.9868095178480107 | 101.7245986302808 |
| **Gelanggang Tenis UPM** | 2.9974331685643287 | 101.7043194912751 |

**Important Notes:**
- **Referee Requirements by Sport:**
  - **Football:** 3 referees (1 main referee + 2 linesmen)
    - Tournament: RM 120 total (3 × RM 40)
    - Practice: RM 60 total (3 × RM 20)
  - **Futsal:** 1 referee (solo)
    - Tournament: RM 40
    - Practice: RM 20
  - **Badminton:** 1 umpire
    - Tournament: RM 40
    - Practice: RM 20
  - **Tennis:** 1 chair umpire (optional)
    - Tournament: RM 40
    - Practice: RM 20

- **Referee System (Two Types):**
  1. **Tournament Referees:** Mandatory for all tournament matches (automatically assigned)
  2. **Normal Booking Referees:** Optional add-on for practice sessions/friendly matches

- **Multi-Referee Logic:**
  - Partial assignment allowed (e.g., football can have 1/3, 2/3, or 3/3 referees)
  - **Proportional Payment:** Only assigned referees are paid
  - **Auto-Refund:** Unused referee fees refunded to organizer
  - Example: Football job with 3 referee slots:
    - If 2 referees accept: RM 40 paid (2 × RM 20), RM 20 refunded
    - If 0 referees accept by endTime: RM 60 refunded (auto-cancelled)

- **Referee Job Lifecycle:**
  ```
  Normal Bookings:
  Payment → OPEN (visible until endTime) → ASSIGNED (referee accepts)
  → endTime reached → COMPLETED (auto) → PAID (escrow release)
  
  If no referee by endTime: OPEN → CANCELLED (full refund)
  
  Tournaments:
  Tournament Start → OPEN → ASSIGNED → Match Complete
  → COMPLETED (admin confirms) → PAID (escrow release)
  ```

- **Conflict Prevention:**
  - Referees cannot accept overlapping jobs
  - Backend validates time conflicts before acceptance
  - UI shows conflicting jobs with warnings (accept button disabled)

- Referee fee: **RM 40 per referee per tournament match**, **RM 20 per referee per practice session**
- **Multi-hour booking** is available for hourly facilities (Badminton, Tennis) - users can select up to 2 consecutive hours.
- Maximum booking duration is **2 hours** per UPM Akademi Sukan policy ("MAKSIMUM 2 JAM").
- Student prices are **digital booking fees** - facility access is free for UPM students (covered by student fees).
- Public prices are **full rental rates** from official UPM Akademi Sukan price list.

### **B. Referee Verification Codes & Badge System**

*Students can only accept referee jobs if their profile has the specific badge, which corresponds to completing referee certification courses offered by UPM Akademi Sukan.*

#### **Course Codes & Badges (4 Sports):**
| Sport | Course Code | Badge Constant | Display Name |
|---|---|---|---|
| Football | `QKS2101` | `VERIFIED_REF_FOOTBALL` | Football |
| Futsal | `QKS2104` | `VERIFIED_REF_FUTSAL` | Futsal |
| Badminton | `QKS2102` | `VERIFIED_REF_BADMINTON` | Badminton |
| Tennis | `QKS2103` | `VERIFIED_REF_TENNIS` | Tennis |

#### **Badge System Architecture:**

**Data Storage:**
- Location: `users.badges` (Firestore array field)
- Type: `List<String>` containing badge constants
- Example: `['VERIFIED_REF_FOOTBALL', 'VERIFIED_REF_FUTSAL']`

**Single Source of Truth:**
- **Class:** `BadgeService` (`lib/services/badge_service.dart`)
- **Purpose:** Centralized badge validation and management
- **Methods:**
  - `availableBadges` - List of all valid badges (4 sports)
  - `badgeNames` - Display names mapping
  - `badgeIcons` - Icon mapping (⚽🎸🎾)
  - `badgeDescriptions` - Badge descriptions
  - `isCertifiedFor(user, sport)` - Validation method

**Strict 1:1 Mapping Rule:**
- Every badge must correspond to exactly one `SportType` enum value
- Every `SportType` must have exactly one corresponding badge
- This ensures:
  - Referee jobs can be filtered correctly
  - Backend access control works properly
  - No "orphaned" badges or missing certifications

**Badge Validation Flow:**
```dart
// 1. User applies for referee certification
AuthService.applyForReferee(userId, selectedBadges)

// 2. Admin reviews and approves
BadgeService.setBadgesForUser(userId, approvedBadges)

// 3. System validates before showing jobs
final sportBadge = BadgeService._getSportBadge(job.sport);
if (user.badges.contains(sportBadge)) {
  // Show job to referee
}

// 4. Backend validates before acceptance
RefereeService.acceptJob(jobId) {
  if (!referee.isCertifiedFor(job.sport)) {
    throw 'Not certified for this sport';
  }
}
```

**Admin Badge Management:**
- Location: Admin Dashboard → Referees List
- Features:
  - View all referees with their certifications
  - Click referee row to open badge management dialog
  - Add/remove badges via checkboxes
  - Changes saved to Firestore immediately
  - Real-time job filtering updates
- UI: Fixed overflow issues, displays 4 sports in 2×2 grid

**Referee Job Filtering:**
- **Available Jobs Tab:**
  - Shows jobs matching referee's badges
  - Example: Referee with `VERIFIED_REF_FOOTBALL` sees only football jobs
  - Empty state: "Get certified for more sports to see more jobs"
- **Conflict Detection:**
  - Jobs overlapping with accepted jobs shown but disabled
  - Warning icon and disabled accept button
  - Hover tooltip explains conflict

**Course Names (UPM Akademi Sukan):**
* **QKS2101:** Kursus Pengadil Bola Sepak (Football Referee Course)
* **QKS2104:** Kursus Pengadil Futsal (Futsal Referee Course)
* **QKS2102:** Kursus Pengadil Badminton (Badminton Umpire Course)
* **QKS2103:** Kursus Pengadil Tenis (Tennis Umpire Course)

**Note:** Badge constants use `VERIFIED_REF_*` prefix to distinguish from other badge types (e.g., achievement badges, rank badges).

#### **Certification Process:**
1. **Course Completion:** Students complete referee certification courses through UPM Akademi Sukan (Akademi Sukan provides professional training and certification courses)
2. **Application:** Students apply for referee certification in the app by:
   - Selecting the relevant course code (QKS2101-QKS2104)
   - Optionally uploading proof of course completion (certificate/transcript from Akademi Sukan)
3. **Badge Assignment:** System grants the corresponding referee badge upon application
4. **Job Access:** Badge enables students to accept referee jobs in the SukanGig marketplace

**Note:** 
- Referees are automatically assigned to **tournament matches**. For **normal bookings**, referees are an **optional add-on** (useful for practice/training sessions).
- This system aligns with Akademi Sukan's educational services - they provide the courses, PutraSportHub handles certification verification and job matching.

### **C. Operational Constraints**

* **Standard Hours:** 08:00 AM – 10:00 PM Daily.
* **The "Jumaat" Gap:** strictly **CLOSED** on Fridays from **12:15 PM – 2:45 PM** (Muslim Prayer).
    * *Dev Note:* The Booking UI must disable these time slots on Fridays.

---

### **D. Referee System Business Logic (SukanGig)**

#### **D.1. Two Referee Types**

**1. Tournament Referees (Mandatory)**
- **Trigger:** Automatically created when tournament starts
- **Status:** Required for all tournament matches
- **Rate:** RM 40 per match per referee
- **Payment:** Organizer pays from tournament pool when registration closes
- **Lifecycle:** Tournament Start → OPEN → ASSIGNED → Match Complete → COMPLETED → PAID

**2. Normal Booking Referees (Optional)**
- **Trigger:** Student selects "Request Referee" during booking flow
- **Status:** Optional add-on for practice/friendly matches
- **Rate:** RM 20 per session per referee
- **Payment:** Student pays referee fee during booking (held in escrow)
- **Visibility:** Jobs remain visible until booking `endTime` (not `startTime`)
  - Allows referees to accept jobs even for ongoing sessions
  - Provides flexibility for last-minute coverage
- **Lifecycle:** Payment → OPEN → ASSIGNED → endTime → COMPLETED → PAID
- **Auto-Cleanup:** System runs cleanup at booking `endTime`:
  - If referees assigned → job auto-completes, escrow released
  - If no referees assigned → job cancelled, full referee fee refunded
- **Key Point:** Booking proceeds regardless of referee availability

#### **D.2. Multi-Referee Logic**

**Referee Requirements by Sport:**
```dart
football: 3 referees    // 1 main + 2 linesmen
futsal: 1 referee       // solo
badminton: 1 umpire     // solo
tennis: 1 umpire        // solo (optional)
```

**Partial Assignment System:**
- Jobs can be partially fulfilled
- Example: Football job (3 referees required)
  - 0/3 referees: Job remains OPEN
  - 1/3 referees: Job remains OPEN (partially assigned)
  - 2/3 referees: Job remains OPEN (partially assigned)
  - 3/3 referees: Job fully assigned (still OPEN until match starts)

**Proportional Payment Algorithm:**
```dart
// Calculate referee fee per slot
feePerReferee = totalRefereeFee / refereesRequired

// On job completion:
assignedCount = assignedReferees.length
paymentAmount = assignedCount * feePerReferee
refundAmount = (refereesRequired - assignedCount) * feePerReferee

// Example: Football (RM 60 total, 3 referees required)
// Scenario 1: 2 referees assigned
//   Payment: 2 × RM 20 = RM 40 (to referees)
//   Refund: 1 × RM 20 = RM 20 (to organizer)

// Scenario 2: 0 referees assigned (auto-cancelled)
//   Payment: RM 0
//   Refund: RM 60 (full refund to organizer)
```

**UI Progress Indicators:**
- Single referee jobs: "Referee assigned" or "Looking for referee"
- Multi-referee jobs:
  - "1/3 referees assigned (2 more needed)"
  - "2/3 referees assigned (1 more needed)"
  - "3/3 referees assigned (fully covered)"
  - In "My Jobs" tab: "You + 2 others" or "You + 1 other (1 more needed)"

#### **D.3. Referee Conflict Prevention**

**Problem:** Referees could accidentally accept overlapping jobs, causing double-booking.

**Solution:** Time overlap detection and validation.

**Overlap Detection Algorithm:**
```dart
bool hasTimeConflict(Job newJob, List<Job> existingJobs) {
  for (final existingJob in existingJobs) {
    if (newJob.startTime.isBefore(existingJob.endTime) &&
        newJob.endTime.isAfter(existingJob.startTime)) {
      return true; // Jobs overlap
    }
  }
  return false;
}

// Example conflicts:
// Existing: 2:00 PM - 4:00 PM
// New: 3:00 PM - 5:00 PM → CONFLICT (overlaps 3-4 PM)
// New: 1:00 PM - 2:30 PM → CONFLICT (overlaps 2-2:30 PM)
// New: 4:00 PM - 6:00 PM → NO CONFLICT (starts when existing ends)
```

**Backend Validation:**
- Location: `RefereeService.acceptJob()`
- Checks: All referee's assigned jobs (status: ASSIGNED, COMPLETED)
- Action: Throws error if conflict detected
- Error Message: "You have a conflicting job from [time] to [time]"

**Frontend Indicators:**
- Conflicting jobs shown in "Available Jobs" tab
- Visual styling: Warning border/background
- Accept button: Disabled
- Warning icon: ⚠️ with tooltip explaining conflict
- Status badge: "Time Conflict" in orange

**Edge Cases Handled:**
- Jobs starting exactly when another ends: NO CONFLICT
- Jobs with same start time: CONFLICT
- Back-to-back jobs with 0-minute gap: NO CONFLICT
- Overlapping by even 1 minute: CONFLICT

#### **D.4. Enhanced Referee Dashboard (3-Tab Interface)**

**Tab 1: Available Jobs**
- **Purpose:** Browse open job opportunities
- **Filtering:**
  - Shows only OPEN jobs
  - Filters by referee's badges (sport certifications)
  - Hides jobs already accepted by this referee
  - Shows future jobs and next-day jobs
  - Marks conflicting jobs (shown but disabled)
- **Display:**
  - Job cards with sport, time, location, pay
  - Multi-referee progress ("2/3 referees needed")
  - Conflict warning for overlapping jobs
  - Accept button (disabled for conflicts/uncertified sports)
- **Empty States:**
  - No jobs available: "Check back later for new opportunities"
  - No certifications: "Get certified for sports to see job listings"
  - All jobs taken: "All available jobs are assigned"

**Tab 2: My Jobs**
- **Purpose:** Track accepted jobs
- **Filtering:**
  - Shows jobs where referee is in `assignedReferees` array
  - Statuses: ASSIGNED, COMPLETED
  - Excludes PAID and CANCELLED (moved to History)
- **Status Classification:**
  - 🟢 **Upcoming:** Job startTime is in the future
    - Shows countdown: "Starts in 2 hours" or "Starts tomorrow at 3:00 PM"
  - 🟡 **In Progress:** Current time is between startTime and endTime
    - Shows time remaining: "45 minutes remaining"
  - 🔵 **Recently Ended:** Job completed < 24 hours ago
    - Shows completion status: "Completed 3 hours ago"
- **Multi-Referee Display:**
  - "You + 2 others" (3/3 referees)
  - "You + 1 other (1 more needed)" (2/3 referees)
  - "You (2 more needed)" (1/3 referees)
- **Actions:**
  - View booking details
  - QR check-in (when job is active)
  - Navigate to facility location

**Tab 3: History**
- **Purpose:** View past job records
- **Filtering:**
  - Shows jobs with status: COMPLETED, PAID, CANCELLED
  - Sorted by completion date (newest first)
- **Display:**
  - Job summary with final status
  - Payment received (for PAID jobs)
  - Cancellation reason (for CANCELLED jobs)
  - Merit points earned (+3 per completed job)
- **Empty State:** "No job history yet. Accept jobs to build your record."

#### **D.5. Badge System Integration**

**Job Visibility Rules:**
```dart
// Referee sees job only if:
1. Job status is OPEN
2. Referee has required badge for job's sport
3. Job is not in referee's assignedJobs list
4. Job startTime is not in the past

// Example:
Job: Football match (sport: 'FOOTBALL')
Referee badges: ['VERIFIED_REF_FOOTBALL', 'VERIFIED_REF_FUTSAL']
Result: Job is visible (✅ has VERIFIED_REF_FOOTBALL)

Job: Tennis match (sport: 'TENNIS')
Referee badges: ['VERIFIED_REF_FOOTBALL']
Result: Job is hidden (❌ missing VERIFIED_REF_TENNIS)
```

**Badge Validation on Job Acceptance:**
```dart
// Backend validation in RefereeService.acceptJob()
final requiredBadge = BadgeService.getSportBadge(job.sport);
if (!referee.badges.contains(requiredBadge)) {
  throw 'You are not certified to referee ${job.sport}';
}
```

#### **D.6. Escrow Payment Flow**

**For Tournament Matches:**
```
1. Tournament created → Organizer pays facility fee
2. Teams join → Entry fees collected in tournament pool
3. Registration closes → Referee fee deducted from pool to escrow_vault
4. Match completed → Admin confirms completion
5. Escrow released → Referee payment distributed proportionally
```

**For Normal Bookings:**
```
1. Booking created with referee request → Student pays (facility + referee fee)
2. Referee fee held in escrow_vault
3. Referee accepts job → Job status: ASSIGNED
4. Booking endTime reached → Auto-complete job
5. Escrow released → Assigned referees paid proportionally, unused refunded
```

**Payment Distribution Example (Football, 3 referees, RM 60 total):**
- 3 referees assigned: 3 × RM 20 = RM 60 paid, RM 0 refunded
- 2 referees assigned: 2 × RM 20 = RM 40 paid, RM 20 refunded
- 1 referee assigned: 1 × RM 20 = RM 20 paid, RM 40 refunded
- 0 referees assigned: RM 0 paid, RM 60 refunded (job auto-cancelled)

**Firestore Transactions:**
- All escrow operations use Firestore transactions
- Ensures atomic updates (no partial payments/refunds)
- Prevents race conditions and double-payments

---

## 4. Detailed Database Schema (Firestore)

### **Collection: `users`**
* `uid` (string): Firebase Auth ID.
* `email` (string): Ends in `@student.upm.edu.my` triggers STUDENT role.
* `full_name` (string)
* `matric_no` (string, optional): Required for Students.
* `role` (string): 'STUDENT', 'PUBLIC', 'ADMIN'.
* `wallet_balance` (double): SukanPay credits (Refunds go here).
* `badges` (array): e.g., `['VERIFIED_REF_FOOTBALL']`.
* `merit_points_total` (int): Cached total.

### **Collection: `facilities`**
* `id` (string): e.g., `fac_football_padang_a`
* `name` (string)
* `description` (string): Detailed facility information aligned with real UPM data
* `type` (enum): 'SESSION', 'INVENTORY'
* `sport` (string): 'FOOTBALL', 'FUTSAL', 'BADMINTON', 'TENNIS'
* `price_student` (double)
* `price_public` (double)
* `is_indoor` (bool): Critical for Weather Logic (Futsal is outdoor)
* `imageUrl` (string): Asset path to facility image (maps to imageAssetPath in model)
* `sub_units` (array): e.g., `['Court 1', 'Court 2']` (Only for Inventory type - Badminton, Tennis).
* `location` (GeoPoint): GPS coordinates for UPM campus facilities

### **Collection: `bookings`**
* `booking_id` (string)
* `user_id` (ref)
* `facility_id` (ref)
* `start_time` (timestamp)
* `end_time` (timestamp)
* `status` (enum): 'PENDING_PAYMENT', 'CONFIRMED', 'CANCELLED', 'COMPLETED', 'REFUNDED'
* `weather_status` (enum): 'CLEAR', 'RAIN_WARNING', 'WASHED_OUT'
* `total_amount` (double)
* `selected_sub_unit` (string, optional): e.g., "Court 3".
* `cancellation_reason` (string, optional): Reason provided when cancelled.
* `cancelled_at` (timestamp, optional): When cancellation occurred.

### **Collection: `referee_jobs` (The SukanGig Marketplace)**

*Note: Referee jobs are created for **tournament matches** (mandatory) and **normal bookings** (when requested by students).*

* `job_id` (string)
* `booking_id` (ref): Tournament booking ID
* `sport_type` (string): 'FOOTBALL', 'FUTSAL', 'BADMINTON', 'TENNIS'
* `date_time` (timestamp)
* `payout_amount` (double): e.g., 50.00 (Held in Escrow).
* `status` (enum): 'OPEN', 'ASSIGNED', 'COMPLETED', 'PAID', 'CANCELLED'
* `assigned_referee_id` (string, nullable)
* `notes` (string, optional): Tournament match reference (e.g., "Tournament: SUKOL 2026 - Match 3 (SEMIFINAL)")

### **Collection: `merit_logs`**
* `log_id` (string)
* `user_id` (ref)
* `activity_name` (string): e.g., "Refereed Match #4421"
* `points` (int): +2 or +3.
* `gp08_code` (string): 'B1' (Player) or 'B2' (Official).
* `timestamp` (timestamp)

---

## 5. Critical Business Logic

### **A. Weather & Cancellation (The "SukanPay" Loophole)**

* **Logic:** If OpenWeatherMap API shows Rain > 5mm AND `is_indoor == false`:
    1.  Block new bookings.
    2.  If a booking exists, trigger **Auto-Cancellation**.
* **Refund:** Money is refunded strictly to `wallet_balance` (SukanPay), **NEVER** to the bank account. This solves the "UPM Bursar 3-Month Delay" issue.

### **B. Booking Cancellation & Refund Policy**

* **24-Hour Rule:** Bookings can only be cancelled if more than 24 hours before the start time.
* **Cancellation Flow:**
  1. User initiates cancellation via `BookingsScreen` → Shows confirmation dialog with refund amount.
  2. `BookingService.cancelBooking()` → Sets booking status to `CANCELLED`, cancels associated referee job (if any).
  3. If eligible (24+ hours before), `PaymentService.processRefund()` → Credits full amount to user's wallet, creates refund transaction, refunds escrow (if referee fee was paid).
  4. Booking status updated to `REFUNDED` after refund is processed.
* **Refund Destination:** All refunds go to `wallet_balance` (SukanPay credits), **NEVER** to external bank accounts.
* **Referee Job Handling:** If booking has an associated referee job, it's automatically cancelled and status set to `CANCELLED`.
* **Booking Cancellation:** When booking is cancelled, payment is refunded according to cancellation policy.
* **Status Flow:** `CONFIRMED/PENDING_PAYMENT` → `CANCELLED` → `REFUNDED` (if eligible)

### **C. The Escrow Payment Flow**

**Note:** Escrow is used for ALL referee payments (tournaments and normal bookings). See section **D.6** above for comprehensive escrow payment documentation including multi-referee proportional payments and auto-cleanup logic.

**Quick Summary:**
* **Tournaments:** Entry fees → tournament pool → referee fee to escrow → match complete → payment distributed
* **Normal Bookings:** Booking payment → referee fee to escrow → job complete/cancelled → payment distributed/refunded

### **C.1. Tournament Financial Model (Prize & Organizer Fee)**

* **Organizer sets:**
  * **Entry Fee:** Amount each team pays to join (optional, can be free)
  * **First Place Prize:** Prize money for the winner (optional)
  * **Organizer Fee:** Organizer's commission for organizing (optional)

* **Financial Breakdown:**
  ```
  Total Revenue = Entry Fee × Number of Teams
  Referee Costs = Referees Required × RM 40 (tournament rate)
  Available Funds = Total Revenue - Referee Costs
  Distribution = First Place Prize + Organizer Fee
  Balance = Available Funds - Distribution
  ```

* **Validation Rules:**
  * Prize + Organizer Fee must be ≤ Available Funds
  * If entry fee is 0 (free tournament), prize and organizer fee should be 0
  * Financial summary card shows real-time calculation and validation

* **Payment Flow:**
  1. **Tournament Creation:** Organizer pays facility fee upfront
  2. **Teams Join:** Participants pay entry fee (held in tournament pool)
  3. **Registration Closes:** Organizer pays referee fee (from tournament pool)
  4. **Tournament Completion:** Winner receives prize, organizer receives fee (manual distribution)

* **Example (8-team Football Tournament):**
  * Entry Fee: RM 30 per team
  * Total Revenue: RM 240 (8 teams × RM 30)
  * Referee Costs: RM 120 (3 referees × RM 40)
  * Available Funds: RM 110 (RM 240 - RM 120)
  * First Place Prize: RM 80 (organizer sets)
  * Organizer Fee: RM 30 (organizer sets)
  * Balance: RM 0 ✓

### **D. Merit Calculation (GP08 Policy)**

* **Player:** +2 Points per match (Code B1).
* **Referee:** +3 Points per match (Code B2 - Leadership).
* **Organizer:** +5 Points per Tournament (Code B3).
* **Cap:** Maximum 15 Points per Semester.

---

## 6. UI/UX Design System (Glassmorphism)

* **Theme:** Dark Mode iOS Glass.
* **Primary Color:** UPM Red `Color(0xFFB22222)`.
* **Secondary Color:** UPM Green `Color(0xFF2E8B57)`.
* **Glass Widget Specs:**
    * **Blur:** `BackdropFilter` with `sigmaX: 10, sigmaY: 10`.
    * **Fill:** `Colors.white.withOpacity(0.08)`.
    * **Border:** `Colors.white.withOpacity(0.2)` (Thin 1px).
    * **Shadow:** Low opacity black shadow for depth.

---

## 7. User Experience Flows

### **1. THE STUDENT PLAYER FLOW (The "Super User")**
*Persona: Ali, a 2nd Year Engineering Student wanting to play Futsal.*

#### **Phase 1: Discovery & Context**
1. **Login:** Ali logs in with `ali@student.upm.edu.my`.
   - *System Check:* App detects `@student.upm.edu.my` domain → Assigns **STUDENT Role**
   - *Code Reference:* `AuthService.registerWithEmail()` checks `AppConstants.studentEmailDomain`

2. **Home Dashboard:**
   - Ali sees the **Weather Widget** (Sunny, 32°C) - fetched from OpenWeatherMap
   - He sees his **SukanPay Wallet** (RM 50.00) - from `user.wallet_balance`
   - He taps the **Futsal Card** (Glassy 3D Card) → navigates to `/booking/sport/FUTSAL`

#### **Phase 2: The Booking (Smart Logic)**
1. **Facility Selection:** He selects "Futsal Outdoor A".
   - *Edge Case:* If Weather API shows Rain > 5mm (v5.0) or probability > 60%:
     - App **blocks** outdoor bookings
     - Highlights "Futsal KMR (Indoor)" as alternative
   - *Code Reference:* `WeatherService.shouldBlockOutdoorBooking()`

2. **Time Slot:** He picks **Friday, 5:00 PM**.
   - *System Rule:* Slots between **12:15 PM - 2:45 PM** are greyed out (Jumaat Prayer)
   - *Code Reference:* `DateTimeUtils._isFridayPrayerSlot()`

3. **Customization Options:**
   - Ali pays the full booking amount directly
   - *Note:* Referees are mandatory for tournaments and optional for normal bookings when requested
   - *Code Reference:* `BookingFlowScreen._enableSplitBill` toggle

#### **Phase 3: Payment & Confirmation**
1. **Checkout:** Total is RM5 (Futsal booking fee for student)


2. **State Changes:**
   ```
   BookingStatus.PENDING_PAYMENT → PENDING_PARTICIPANTS → CONFIRMED
   ```

**
   - App generates shareable link/Team Code (e.g., `TIGER-882`)
   - Ali sends to WhatsApp group
   - Friends click link → Pay their share → Auto-join booking

4. **Confirmation:** Once all participants have paid, status → `CONFIRMED`

#### **Phase 4: Post-Game (Rewards)**
1. **Match End:** Ali scans Referee's QR Code to verify game completion
2. **Merit Alert:** "Congratulations! +2 Merit Points (GP08 Code: B1)"
   - *Code Reference:* `MeritService.awardPlayerMerit()`

#### **Phase 5: Booking Cancellation (If Needed)**
1. **Cancellation Request:** Ali taps "Cancel" button on booking card in `/bookings` screen
2. **Confirmation Dialog:** 
   - Shows refund amount (RM X.XX)
   - Optional cancellation reason text field
   - Button disabled if less than 24 hours before booking start
3. **Cancellation Process:**
   - `BookingService.cancelBooking()` → Sets status to `CANCELLED`, cancels referee job
   - If eligible (24+ hours), `PaymentService.processRefund()` → Credits wallet, creates transaction, refunds escrow
   - Status updated to `REFUNDED`
4. **Success Feedback:** "Booking cancelled. RM X.XX refunded to wallet!"
   - *Code Reference:* `BookingsScreen._handleCancelBooking()`

---

### **2. THE PUBLIC USER FLOW (The "Guest")**
*Persona: Mr. Tan, a resident of Serdang wanting to play Badminton.*

#### **Key Differences from Student:**
| Feature | Student | Public |
|---------|---------|--------|
| Badminton Price | RM 15.00 | RM 20.00 |
| Payment | Direct payment | Direct payment |
| Hire Referee | ✅ Available | ❌ Disabled |
| Merit Points | ✅ Earned | ❌ None |

#### **Flow:**
1. **Login:** `tan@gmail.com` → System assigns **PUBLIC Role**
2. **Booking:** Sees public pricing (RM 20 vs RM 15)
3. **Payment:** Must pay full amount directly
4. **No Rewards:** No Merit Points awarded

---

### **3. THE REFEREE FLOW (The "Gig Worker")**
*Persona: Haziq, a Verified Football Referee (Badge: `VERIFIED_REF_FOOTBALL`).*

#### **Phase 1: Verification (One Time)**
1. **Application:** Haziq navigates to Profile → "Become a Referee" button
   - *Route:* `/referee/apply`
   - *Code Reference:* `RefereeApplicationScreen`

2. **Course Selection:** Haziq selects "Football Referee" (QKS2101)
   - UI shows all four referee course options (aligned with Akademi Sukan courses):
     - Football Referee (QKS2101)
     - Futsal Referee (QKS2104)
     - Badminton Referee (QKS2102)
     - Tennis Referee (QKS2103)
   - Each option shows course code and sport icon
   - These courses correspond to referee certification courses offered by UPM Akademi Sukan

3. **Proof of Completion Upload (Optional):** Haziq can upload certificate or transcript
   - Uses `image_picker` to select from gallery
   - Shows proof of completing the Akademi Sukan referee course
   - Image stored for future admin verification
   - Not required for MVP (immediate badge assignment)

4. **Submission:** Haziq clicks "Submit Application"
   - `AuthService.applyForRefereeCert()` called
   - Badge immediately added to `user.badges[]`
   - Success message: "You are now certified for Football!"

5. **Badge Mapping:**
   ```
   QKS2101 → VERIFIED_REF_FOOTBALL (Football)
   QKS2104 → VERIFIED_REF_FUTSAL (Futsal)
   QKS2102 → VERIFIED_REF_BADMINTON (Badminton)
   QKS2103 → VERIFIED_REF_TENNIS (Tennis)
   ```
   - *Code Reference:* `AuthService.applyForRefereeCert()`
   - *Result:* SukanGig tab appears in bottom navigation
   - *Alignment:* Course codes correspond to Akademi Sukan referee certification courses

#### **Phase 2: The Job Hunt (SukanGig)**
1. **Dashboard:** Haziq navigates to `/referee` (SukanGig Tab)
2. **Job Feed:** Shows jobs filtered by his badges
   - Sees: "Football Match @ Padang A, Tomorrow 5PM. Earnings: **RM30**"
   - Does NOT see Badminton/Futsal jobs (wrong badge)
   - *Code Reference:* `filteredAvailableJobsProvider` in `providers.dart`

3. **Acceptance:** Clicks "Accept Job"
   - Job Status: `OPEN` → `ASSIGNED`
   - Ali (Organizer) notified: "Haziq is your Referee"
   - *Code Reference:* `RefereeService.applyForJob()`

#### **Phase 3: Execution & Payday**
1. **Match Day:** Haziq arrives, shows Job QR Code
2. **The Handshake:** Ali scans QR → Confirms referee attendance
3. **Escrow Release:**
   ```
   escrow_vault (RM30) → Haziq's wallet_balance
   ```
   - *Code Reference:* `RefereeService.completeJob()`

4. **Merit:** Haziq earns **+3 Merit Points** (GP08 Code: B2 - Leadership)
   - *Code Reference:* `MeritService.awardRefereeMerit()`

---

### **4. THE ADMIN FLOW (The "God Mode")**
*Persona: Puan Sarah, UPM Sports Officer.*

#### **Phase 1: Operational Control**

##### **Blackout Dates:**
- **Scenario:** "Convocation is next week"
- **Action:** Select `Padang A` → Date Range → "Block for University Event"
- **Result:** Users see "Venue Unavailable (University Use)"
- **Events:** Pesta Konvokesyen, SUKOL (Inter-College Games)

##### **Weather Override:**
- **Scenario:** Heavy storm hits Serdang
- **Action:** Admin triggers "Emergency Rain Protocol"
- **Result:** 
  - All outdoor bookings for next 2 hours → `CANCELLED`
  - Auto-refund to user's `wallet_balance` (never to bank!)
- *Code Reference:* `WeatherService.shouldTriggerAutoCancel`

#### **Phase 2: Analytics**
1. **Revenue View:** Split between:
   - "Field Revenue" (University money)
   - "Referee Payouts" (Student money via escrow)

2. **Merit Export:** Download monthly PDF of Student Activities
   - Sent to Housing Department for merit verification
   - *Code Reference:* `MeritService.generateMeritTranscript()`

---

### **State Machines**

#### **Booking Lifecycle**
```
                    ┌─────────────────┐
                    │ PENDING_PAYMENT │
                    └────────┬────────┘
                             │ (Payment received)
                             ▼
            ┌────────────────────────────────┐
            │                                │
            ▼                                ▼
┌───────────────────┐            ┌───────────────────┐
│PENDING_PARTICIPANTS│            │    CONFIRMED      │
│ (Split Bill ON)    │            │ (Full payment)    │
└─────────┬─────────┘            └─────────┬─────────┘
          │ (All paid)                     │
          └────────────┬───────────────────┘
                       │
                       ▼
              ┌───────────────┐
              │  IN_PROGRESS  │ (Match started)
              └───────┬───────┘
                      │
          ┌───────────┴───────────┐
          │                       │
          ▼                       ▼
   ┌────────────┐          ┌────────────┐
   │ COMPLETED  │          │ CANCELLED  │
   │ (+Merit)   │          │ (+Refund)  │
   └────────────┘          └────────────┘
```

#### **Referee Job Lifecycle**
```
┌────────┐
│  OPEN  │ (Job created when booking requests referee)
└───┬────┘
    │ (Referee accepts)
    ▼
┌──────────┐
│ ASSIGNED │ (Referee confirmed, organizer notified)
└────┬─────┘
     │ (QR Check-in scanned)
     ▼
┌───────────┐
│ COMPLETED │ (Escrow released to referee wallet)
└─────┬─────┘
      │
      ▼
┌──────┐
│ PAID │ (Referee confirms receipt, merit awarded)
└──────┘

CANCELLATION PATH:
- OPEN → CANCELLED (No referee accepted, organizer cancels)
- ASSIGNED → CANCELLED (Referee withdraws, reopens to OPEN)
```

---

## 8. Domain Context & UX Strategy

### **1. The "Grade A" Strategy (Why we built it this way)**

* **The Sport Selection:** We selected **Football, Futsal, Badminton, and Tennis** to demonstrate distinct booking patterns:
  * *Football* proves we can handle **Complex Resources** (3-man referee crews + large session blocks).
  * *Futsal* proves we can handle **Session-Based Booking** (2-hour fixed sessions).
  * *Badminton* proves we can handle **Inventory Management** (avoiding conflict between Court 1-8).
  * *Tennis* proves **Scalable Inventory** (14 courts, similar pattern to Badminton).
  * *Note to Developer:* There are two primary booking patterns: **SESSION** (Football, Futsal) and **INVENTORY** (Badminton, Tennis).

### **2. The "Smart Upgrade" UX Flow**

* **Concept:** Do not build separate "Booking" and "Tournament" apps.
* **The Flow:**
  1. Every interaction starts as a **Simple Booking** (e.g., "Book Futsal 8PM").
  2. For tournaments, users create them separately via the Tournament Hub.
  3. *Why:* This keeps the UI clean for 90% of users while offering power tools for the 10%.

### **3. The Tournament "Cheat Code" (Implementation Detail)**

* **Constraint:** We are **NOT** building a custom drag-and-drop bracket builder (too complex).
* **The Solution:** Use **"Fixed Logic"**:
  * **Format:** Hard-code "8-Team Knockout" or "4-Team Group".
  * **Join Mechanism:** The Organizer gets a **Team Code** (e.g., `TIGER-882`). Players enter this code to auto-join the roster.
  * *Developer Instruction:* Focus on the "Team Code" logic rather than complex bracket UI.

### **4. Official UPM Research Data (The "Source of Truth")**

*Use these codes in comments and variable names to prove authenticity.*

#### **The Merit Document**
- **Code:** `UPM/KK/TAD/GP08` (Garis Panduan Pengiraan Merit)
- **Rule:** Grants merit for "Activity Involvement" (Component B)

#### **The Referee Verification Codes**
| Sport | Course Code | Badge | Description |
|-------|-------------|-------|-------------|
| Football | `QKS2101` | `VERIFIED_REF_FOOTBALL` | Football Officiating |
| Badminton | `QKS2102` | `VERIFIED_REF_BADMINTON` | Badminton Officiating |
| Tennis | `QKS2103` | `VERIFIED_REF_TENNIS` | Tennis Umpiring (verify with UPM) |
| Futsal | `QKS2104` | `VERIFIED_REF_FUTSAL` | Futsal Officiating |

*Usage:* A user cannot become a referee unless they upload a transcript containing these specific string codes.

**Important:** Referees are mandatory for **tournament matches** and optionally available for **normal facility bookings** when students request referee assistance for practice or friendly matches.

#### **The Housing Policy**
- **Code:** `MERIT_KOLEJ`
- **Context:** Students need these points to live in college next semester. This is the "User Motivation" for using the app.

### **5. Operational Realism (The "Assessor Defense")**

#### **The Refund Loophole**
- **Context:** Getting cash back from the University Bursar takes 3 months.
- **Solution:** We use **"SukanPay Credits"** for instant refunds.
- **Dev Note:** All refunds must go to `wallet_balance`, never `external_bank`.

#### **The "Blackout" Context**
- Specific events to test: "Pesta Konvokesyen" (Convocation) and "SUKOL" (Inter-College Games).
- **Logic:** Admin overrides > Student Bookings.

### **6. Visual Identity & Branding**

| Element | Value |
|---------|-------|
| **App Name** | PutraSportHub |
| **Primary Red** | `#B22222` (UPM Red) |
| **Primary Green** | `#2E8B57` (UPM Green) |
| **Accent Gold** | `#FFD700` (Championship Gold) |
| **Vibe** | Official, Academic, yet Modern. Not "Startup-y", but "University-Official" |

### **7. Key Constants Reference**

```dart
// UPM Official References
const String MERIT_GUIDELINE = 'UPM/KK/TAD/GP08';
const String HOUSING_POLICY = 'MERIT_KOLEJ';

// Referee Course Codes (Pusat Kokurikulum)
const String FOOTBALL_CERT = 'QKS2101';
const String BADMINTON_CERT = 'QKS2102';
const String TENNIS_CERT = 'QKS2103'; // Verify with UPM
const String FUTSAL_CERT = 'QKS2104';

// Sport Types
const List<String> SPORTS = ['FOOTBALL', 'FUTSAL', 'BADMINTON', 'TENNIS'];

// Student Email Domain
const String STUDENT_DOMAIN = '@student.upm.edu.my';
```

---

**END OF REFERENCE DOCUMENTATION**

*This document provides domain knowledge, business rules, and user flows for developers. For setup instructions, see [SETUP.md](SETUP.md). For comprehensive project overview, see [PROJECT.md](PROJECT.md).*

