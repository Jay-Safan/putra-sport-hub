# Putra Sport Hub - Implementation Planning
**Version:** 2.0.0  
**Last Updated:** January 11, 2026

---

## 📋 Summary of Identified Information

### 1. Pricing Model Clarification

#### Understanding UPM Rate Categories
| Category | Meaning | Target Users |
|----------|---------|--------------|
| **Kerajaan** | Government | Government agencies, other public universities, civil service organizations |
| **Swasta** | Private/Commercial | Private companies, commercial events, external individuals |
| **Warga Kampus** | Campus Citizens | UPM Students & Staff - **NOT in price list (internal access)** |

#### Key Finding
- The official UPM price list shows **EXTERNAL RENTAL RATES** only
- **UPM Students are "Warga Kampus"** - they get FREE facility access as part of their student fees
- Students don't pay "Kerajaan" rates - that's for external government bodies

#### Final Pricing Model for App
| User Type | Facility Cost | Platform Fee | Total |
|-----------|---------------|--------------|-------|
| **UPM Students** | FREE | RM3-10 (digital booking fee) | RM3-10 |
| **Public Users** | Full Swasta Rate | Included | RM15-600 |

**Rationale:**
- Students: Facility is free (covered by student fees), small platform fee for booking system service
- Public: Pay actual UPM rental rates as external parties

---

### 2. Verified Official UPM Rates (Swasta/Public)

From official UPM Akademi Sukan price list:

| Sport/Facility | Public Rate | Booking Model | Max Duration |
|----------------|-------------|---------------|--------------|
| **Badminton** | RM20/hour | HOURLY | 2 hours |
| **Tennis** | RM20/hour | HOURLY | 2 hours |
| **Futsal** | RM100/session | SESSION | 2 hours |
| **Football (Padang A-E)** | RM250/session | SESSION | 2 hours |
| **Football (Stadium)** | RM600/session | SESSION | 2 hours |

*Source: UPM Akademi Sukan Official Price List*

---

### 3. Football Field Locations (Verified)

| Facility ID | Name | Location | Rate (Public) | Category |
|-------------|------|----------|---------------|----------|
| `fac_football_stadium` | Stadium UPM | Main Stadium Complex | RM600/session | **Premium** |
| `fac_football_padang_a` | Padang Bola A | Near KMR | RM250/session | Standard |
| `fac_football_padang_b` | Padang Bola B | Near KMR | RM250/session | Standard |
| `fac_football_padang_c` | Padang Bola C | Near KMR | RM250/session | Standard |
| `fac_football_padang_d` | Padang Bola D | Kolej Serumpun | RM250/session | Standard |
| `fac_football_padang_e` | Padang Bola E | K10 | RM250/session | Standard |

---

### 4. Student Booking Fees (Digital Platform Fee)

Since facilities are FREE for students, we charge a small platform fee:

| Sport | Student Booking Fee | Justification |
|-------|---------------------|---------------|
| **Football** | RM10 | Larger facility, more coordination needed |
| **Futsal** | RM5 | Medium facility |
| **Badminton** | RM3 | Per court per hour |
| **Tennis** | RM5 | Per court per hour |

---

### 5. Current Sports Supported

| Sport | Icon | Facilities | Booking Type |
|-------|------|------------|--------------|
| Football | ⚽ | Stadium + 5 Padangs | SESSION |
| Futsal | 🎯 | 4 Courts (A-D) | SESSION |
| Badminton | 🏸 | 10 Courts | INVENTORY (hourly) |
| Tennis | 🎾 | 14 Courts | INVENTORY (hourly) |

---

## 🎯 Recommended Action Plan

### Phase 1: Data & Pricing Update (Priority: HIGH)
**Estimated Time:** 30-45 minutes

#### Tasks:
1. **Update `facility_model.dart` seed data:**
   - [ ] Update football field locations (KMR, Serumpun, K10)
   - [ ] Add Stadium as premium facility with RM600 public rate
   - [ ] Update all public rates to match official price list
   - [ ] Verify student booking fees are reasonable (RM3-10)

2. **Update `app_constants.dart`:**
   - [ ] Verify pricing constants match new rates
   - [ ] Add stadium-specific pricing constant

3. **Update documentation:**
   - [ ] Update `docs/REFERENCE.md` with verified pricing
   - [ ] Update `docs/PROJECT.md` with facility details

4. **Re-seed database:**
   - [ ] Use admin dashboard "Re-seed Facilities" button
   - [ ] Verify data in Firebase console

---

### Phase 2: Booking Flow Enhancement (Priority: HIGH)
**Estimated Time:** 2-3 hours

#### Tasks:
1. **Multi-Hour Booking for Hourly Sports (Tennis/Badminton):**
   - [ ] Allow selecting multiple consecutive time slots
   - [ ] Validate slots must be adjacent (no gaps)
   - [ ] Enforce max 2-hour limit per UPM rules
   - [ ] Price = base rate × hours selected
   - [ ] UI: Show "+1 hour" / "-1 hour" buttons

2. **Combined Date & Time Picker:**
   - [ ] Merge date and time selection into single page
   - [ ] Calendar at top
   - [ ] Available time slots below (updates based on date)
   - [ ] Better UX flow consistency

3. **Slot Validation Rules:**
   ```
   Rules:
   - Slots must be consecutive (e.g., 2pm + 3pm ✓, 2pm + 5pm ✗)
   - Maximum 2 hours per booking (UPM policy)
   - Cannot book past slots
   - Cannot book conflicting slots (already booked)
   ```

---

### Phase 3: UI Polish (Priority: MEDIUM)
**Estimated Time:** 1-2 hours

#### Tasks:
1. **Referee Button Sizing:**
   - [ ] Ensure "Become Referee" card matches other quick action cards
   - [ ] Remove badge height affecting card size, or standardize all cards

2. **Facility Selection Improvements:**
   - [ ] Add "Premium" section header for Stadium
   - [ ] Add "Training Fields" section header for Padang A-E
   - [ ] Gold accent styling for premium facilities
   - [ ] Consider facility images (see below)

3. **Facility Images (Optional Enhancement):**
   - **Option A (Recommended for FYP):** Local assets in `assets/images/facilities/`
     - `stadium.jpg`, `padang_a.jpg`, `futsal_a.jpg`, etc.
     - Fast loading, works offline
     - Increases app size slightly
   - **Option B:** Placeholder icons with sport-specific colors
     - Simpler, no additional assets needed
     - Less visually engaging

---

### Phase 4: Testing & Verification (Priority: HIGH)
**Estimated Time:** 30-45 minutes

#### Core Functionality Tests:
- [ ] Student login → Book badminton (hourly) → Pay RM3 → Confirm
- [ ] Student login → Book football → Pay RM10 → Confirm
- [ ] Public login → Book tennis → Pay RM20 → Confirm
- [ ] Wallet top-up (fixed: now creates wallet if missing)
- [ ] Multi-hour booking validation (after Phase 2)
- [ ] Admin re-seed facilities

---

## 📊 Facility Data Structure

### Football Facilities (Updated)

```dart
// Stadium - Premium
FacilityModel(
  id: 'fac_football_stadium',
  name: 'Stadium UPM',
  sportType: SportType.football,
  location: 'UPM Main Stadium Complex',
  description: 'Main football stadium with full facilities, floodlights, and spectator seating',
  pricePerSession: 600.0,  // Public rate
  studentPrice: 10.0,      // Booking fee only
  type: FacilityType.session,
  totalUnits: 1,
  isPremium: true,  // NEW: Premium flag
)

// Padang A-E - Standard
FacilityModel(
  id: 'fac_football_padang_a',
  name: 'Padang Bola A',
  sportType: SportType.football,
  location: 'Near KMR (Kolej Mohamad Rashid)',
  pricePerSession: 250.0,  // Public rate
  studentPrice: 10.0,      // Booking fee only
  type: FacilityType.session,
  totalUnits: 1,
  isPremium: false,
)
```

### Tennis Facilities

```dart
FacilityModel(
  id: 'fac_tennis_main',
  name: 'Gelanggang Tenis UPM',
  sportType: SportType.tennis,
  location: 'UPM Sports Academy Tennis Complex',
  description: '14 outdoor hard courts',
  pricePerHour: 20.0,      // Public rate (hourly)
  studentPrice: 5.0,       // Booking fee per hour
  type: FacilityType.inventory,
  totalUnits: 14,
  maxBookingHours: 2,      // UPM max rule
)
```

---

## 🔄 Migration Notes

### When Re-seeding Facilities:
1. Old facilities will be deleted (handled by `clearFacilities()`)
2. New facilities with correct pricing/locations will be created
3. Existing bookings remain (linked by facility ID)
4. If facility ID changes, old bookings may show "Unknown Facility"

### Recommended Approach:
- Keep facility IDs consistent where possible
- Update in-place for minor changes
- For major restructuring, clear and re-seed

---

## 📝 Files to Update

| File | Changes |
|------|---------|
| `lib/features/booking/data/models/facility_model.dart` | Update seed data with locations, pricing |
| `lib/core/constants/app_constants.dart` | Verify/update pricing constants |
| `lib/features/booking/presentation/booking_flow_screen.dart` | Multi-hour selection, combined date/time |
| `lib/features/home/presentation/home_screen.dart` | Referee button sizing |
| `docs/REFERENCE.md` | Update pricing tables |
| `docs/PROJECT.md` | Update facility information |

---

## ✅ Completion Checklist

### Data Updates
- [ ] Facility seed data updated with correct locations
- [ ] Pricing matches official UPM rates
- [ ] Stadium marked as premium
- [ ] Documentation updated

### Booking Flow
- [ ] Multi-hour booking for hourly sports
- [ ] Consecutive slot validation
- [ ] Max 2-hour enforcement
- [ ] Combined date/time picker

### UI/UX
- [ ] Referee button balanced with others
- [ ] Facility selection shows premium/standard sections
- [ ] (Optional) Facility images added

### Testing
- [ ] All booking flows work
- [ ] Wallet top-up works (new users)
- [ ] Admin functions work
- [ ] Re-seed facilities works

---

## 🚀 Next Steps

1. **Start with Phase 1** - Update facility data and pricing
2. **Test core flows** - Ensure booking and payment work
3. **Implement Phase 2** - Multi-hour booking enhancement
4. **Polish UI** - Phase 3 improvements
5. **Final testing** - Complete functionality verification

---

*Document created based on research and user requirements gathering session.*
