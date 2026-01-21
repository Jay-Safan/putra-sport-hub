# PutraSportHub - System Logic Questions & Edge Cases

## ✅ CONFIRMED LOGIC

1. **Merit Points:**
   - ✅ Normal bookings do NOT award merit points
   - ✅ Tournament participants get merit when tournament completes (captain + all team members)
   - ✅ Tournament organizer gets merit when tournament completes
   - ✅ Referee gets merit when job is completed

2. **Payment Atomicity:**
   - ✅ All payment operations use Firestore transactions (wallet + transaction + booking status)
   - ✅ Split bill payments are atomic

3. **Escrow Release:**
   - ✅ Escrow auto-releases when tournament/booking time passes (after endTime)
   - ✅ Escrow releases to referees when job is manually completed

---

## ❓ QUESTIONS TO CLARIFY

### 1. Tournament Cancellation

**Scenario:** Tournament is cancelled after teams have registered and paid entry fees.

**Questions:**
- Should registered teams/participants get their entry fees refunded?
- Should organizer get refund for facility booking?
- Should participants still get merit points if tournament was cancelled after it started?

**Recommendation:** 
- ✅ Refund entry fees to all participants who paid
- ✅ Refund facility booking (if booking is separate from tournament)
- ❌ No merit points if tournament was cancelled

### 2. Booking Cancellation with Referee Job

**Scenario:** User cancels booking that has an active referee job with escrow held.

**Questions:**
- What happens to escrow? Should it be:
  - Automatically refunded to organizer?
  - Released to referees anyway?
  - Held until manually resolved?
- What happens to the referee job? Should it be:
  - Automatically cancelled?
  - Left open for referees to withdraw?

**Recommendation:**
- Escrow automatically refunded to organizer
- Referee job status set to cancelled
- Notify assigned referees

### 3. Split Bill Participant Leaves Before Payment

**Scenario:** Split bill participant joins but never pays their share.

**Questions:**
- What happens to the booking if some participants never pay?
- Should there be a deadline after which unpaid participants are removed?
- Should organizer be able to remove non-paying participants?
- If booking time passes before all paid, what happens?

**Recommendation:**
- Booking stays pending until all pay OR organizer cancels
- Organizer can remove non-paying participants
- After booking time passes, booking auto-completes (those who paid get to use facility)

### 4. Tournament Completion vs Cancellation

**Scenario:** Tournament is cancelled mid-way (during inProgress status).

**Questions:**
- Is there a difference between "completed" and "cancelled" for merit points?
- Should participants get merit if tournament was cancelled after starting?
- When exactly should tournament status change to completed?

**Recommendation:**
- Completed = finished normally → merit awarded
- Cancelled = didn't finish → no merit
- Tournament auto-completes 24 hours after startDate (or when endDate passes)

### 5. Escrow Release Edge Cases

**Scenario:** Referee never checks in but tournament time passes.

**Questions:**
- Should escrow still be released if referee didn't check in?
- What if referee checks in but then withdraws?
- Should there be a grace period after endTime before auto-release?

**Recommendation:**
- ✅ Auto-release escrow after endTime passes (even if no check-in)
- ✅ Log warning if referee didn't check in
- ✅ No grace period needed - time has passed, release escrow

### 6. Booking Time Conflicts

**Scenario:** Two users try to book the same facility slot at the exact same time.

**Questions:**
- Is there race condition protection?
- How is booking order determined?
- Should there be a "reservation hold" during booking creation?

**Recommendation:**
- ✅ Firestore transactions prevent conflicts
- ✅ First successful payment wins
- ✅ Booking creation should check availability atomically

### 7. Split Bill Organizer Cancellation

**Scenario:** Organizer cancels split bill booking before all participants pay.

**Questions:**
- Should participants who already paid get refunded?
- Should booking be cancelled immediately or wait for organizer confirmation?
- What notification should participants receive?

**Recommendation:**
- ✅ All participants get refunded (organizer's share also refunded)
- ✅ Booking cancelled immediately
- ✅ Notify all participants about cancellation

### 8. Tournament Registration Deadline

**Scenario:** Tournament reaches max teams, but then someone withdraws before start.

**Questions:**
- Can tournament accept new registrations if team withdraws?
- What if tournament has minimum teams (e.g., 4) and someone withdraws making it 3?
- Should tournament auto-cancel if below minimum teams?

**Recommendation:**
- ✅ Tournament reopens for registration if below max teams
- ✅ Auto-cancel if below minimum teams (e.g., < 4)
- ✅ Refund all entry fees if auto-cancelled

### 9. Referee Job Application Limits

**Scenario:** Multiple referees apply to same job simultaneously.

**Questions:**
- How are referees selected if more apply than needed?
- Is it first-come-first-served or organizer chooses?
- What happens if referee applies but doesn't check in?

**Recommendation:**
- ✅ First-come-first-served (up to required number)
- ✅ Organizer can replace referees before check-in
- ✅ If referee doesn't check in, job stays open for other applicants

### 10. Wallet Balance Edge Cases

**Scenario:** User's wallet balance is negative (shouldn't happen but what if?).

**Questions:**
- Should wallet balance ever go negative?
- What if refund makes balance negative due to a bug?
- Should there be minimum balance enforcement?

**Recommendation:**
- ❌ Wallet should never go negative (prevented by balance checks)
- ✅ Add validation to ensure balance >= 0
- ✅ Alert admin if negative balance detected

### 11. Merit Points Semester Cap

**Scenario:** User reaches semester cap (15 points) but tournament completes.

**Questions:**
- Should merit award fail if cap is reached?
- Should we show warning before tournament completes?
- Can user see how many points they'll have after tournament?

**Recommendation:**
- ✅ Merit award fails with clear message if cap reached
- ✅ Show warning in tournament detail if user would exceed cap
- ✅ Merit screen shows "points until cap" counter

### 12. Booking Completion vs Tournament Completion

**Scenario:** Normal booking completes (user finishes playing).

**Questions:**
- Should booking auto-complete when endTime passes?
- Should there be manual "complete booking" button?
- What about split bill - does organizer complete or auto-complete?

**Recommendation:**
- ✅ Booking auto-completes when endTime passes
- ✅ Manual completion button also available (for early finish)
- ✅ All participants see booking as completed

### 13. Referee Job Status Transitions

**Scenario:** Referee checks in but tournament is cancelled.

**Questions:**
- What happens to checked-in referee's escrow?
- Should referee get partial payment?
- Should job status be "cancelled" or "completed"?

**Recommendation:**
- ✅ Escrow refunded to organizer
- ❌ No partial payment
- ✅ Job status = cancelled

### 14. Tournament Bracket Generation

**Scenario:** Tournament has odd number of teams (e.g., 5 teams for bracket).

**Questions:**
- How is bracket generated for odd numbers?
- Should there be byes?
- What if tournament format requires even number?

**Recommendation:**
- ✅ Round-robin for odd numbers
- ✅ Bye system for elimination brackets
- ✅ Enforce min/max teams at creation

### 15. Split Bill Team Code Sharing

**Scenario:** Participant shares team code publicly or with wrong people.

**Questions:**
- Can team code be used unlimited times?
- Should there be a participant limit check?
- What if code is shared after booking is confirmed?

**Recommendation:**
- ✅ Team code valid until max participants reached
- ✅ Code invalid after booking confirmed
- ✅ Organizer can regenerate code

---

## 🔍 ADDITIONAL EDGE CASES TO CONSIDER

1. **Network failures during payment:** Handled with retry mechanisms ✅
2. **Concurrent split bill payments:** Handled with transactions ✅
3. **Merit points duplicate prevention:** Already checked ✅
4. **Booking status race conditions:** Protected with transactions ✅
5. **Escrow double-release prevention:** Status check prevents this ✅

---

## 📋 ACTION ITEMS

Please review questions above and confirm:
- [ ] Tournament cancellation refunds
- [ ] Booking cancellation with referee job
- [ ] Split bill non-payment handling
- [ ] Escrow auto-release timing
- [ ] Tournament minimum teams enforcement
- [ ] Merit points cap warnings

---

## 💡 SUGGESTIONS FOR IMPROVEMENT

1. **Add booking completion automation:** Auto-complete bookings when endTime passes
2. **Add tournament minimum teams check:** Auto-cancel if below minimum
3. **Add wallet balance validation:** Ensure balance never goes negative
4. **Add merit points preview:** Show "points after tournament" before completion
5. **Add split bill deadline:** Set deadline for participant payments
