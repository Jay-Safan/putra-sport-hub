# Booking Feature - Access Control & Organization

## 📁 Directory Structure

```
presentation/
├── shared/              # Public + Students + Student-Referees
│   ├── booking_detail_screen.dart
│   ├── booking_flow_screen.dart
│   ├── bookings_screen.dart
│   ├── facility_list_screen.dart
│   ├── booking_success_screen.dart
│   └── share_booking_screen.dart
```

## 👥 Access Control

### Shared Features (All Authenticated Users)
- **Public Users**: Can book facilities, view bookings, share bookings
- **Students**: Same as public users (student pricing)
- **Student-Referees**: Same as students (can switch between student/referee mode)
- **Admins**: View-only access via admin management screens

## 🔄 User Flows

1. **Standard Booking Flow** (All Users):
   - Home → Select Sport → Facility List → Booking Flow → Payment → Success

## 💡 Design Decisions

- **Shared folder**: Contains screens accessible to all user types
- **Direct payment**: Simplified booking system with immediate payment
- **Access control**: Handled via route guards in `app_router.dart`
- **Pricing**: Differentiated by `isStudent` flag (booking fees vs full rates)
