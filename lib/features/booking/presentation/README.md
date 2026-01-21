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
└── student/             # Students only
    ├── split_bill_join_screen.dart
    └── split_bill_payment_screen.dart
```

## 👥 Access Control

### Shared Features (All Authenticated Users)
- **Public Users**: Can book facilities, view bookings, share bookings
- **Students**: Same as public + split bill feature
- **Student-Referees**: Same as students (can switch between student/referee mode)
- **Admins**: View-only access via admin management screens

### Student-Only Features
- **Split Bill**: Students can split booking costs with friends
- **Join Split Bill**: Students can join split bill bookings via QR code

## 🔄 User Flows

1. **Standard Booking Flow** (Public + Students):
   - Home → Select Sport → Facility List → Booking Flow → Payment → Success

2. **Split Bill Flow** (Students only):
   - Booking Flow → Enable Split Bill → Share QR Code → Friends Join → Payment

## 💡 Design Decisions

- **Shared folder**: Contains screens accessible to all user types
- **Student folder**: Contains student-exclusive features (split bill)
- **Access control**: Handled via route guards in `app_router.dart`
- **Pricing**: Differentiated by `isStudent` flag (booking fees vs full rates)
