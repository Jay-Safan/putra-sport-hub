/// Core application constants for PutraSportHub
///
/// Official UPM References:
/// - Merit Guidelines: UPM/KK/TAD/GP08 (Garis Panduan Pengiraan Merit)
/// - Housing Policy: MERIT_KOLEJ (Students need points for college accommodation)
/// - Akademi Sukan Rental Rates 2024
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'PutraSportHub';
  static const String appVersion = '1.0.0';
  static const String universityName = 'Universiti Putra Malaysia';

  // Official UPM Document References
  static const String meritGuideline = 'UPM/KK/TAD/GP08';
  static const String housingPolicy = 'MERIT_KOLEJ';

  // Operating Hours
  static const int operatingStartHour = 8; // 08:00 AM
  static const int operatingEndHour = 22; // 10:00 PM

  // Friday Prayer Block (Hard Constraint) - "The Jumaat Gap"
  // Strictly CLOSED on Fridays from 12:15 PM – 2:45 PM (Muslim Prayer)
  static const int fridayBlockStartHour = 12;
  static const int fridayBlockStartMinute = 15; // 12:15 PM
  static const int fridayBlockEndHour = 14;
  static const int fridayBlockEndMinute = 45; // 2:45 PM

  // Weather Threshold - Rain > 5mm triggers auto-cancellation for outdoor
  static const double rainThresholdMm = 5.0; // 5mm rainfall
  static const double rainProbabilityThreshold =
      60.0; // 60% probability fallback

  // UPM Location for OpenWeatherMap
  static const double upmLatitude = 2.999;
  static const double upmLongitude = 101.707;

  // ═══════════════════════════════════════════════════════════════════════════
  // FACILITY LOCATIONS (UPM Campus - Serdang, Selangor)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get facility location coordinates by facility ID
  /// Returns UPM default location if facility not found
  static Map<String, double> getFacilityLocation(String facilityId) {
    switch (facilityId) {
      // Football Stadium & Padang
      case 'fac_football_stadium':
        return {'latitude': 2.986372108422893, 'longitude': 101.72579628891536};
      case 'fac_football_padang_a':
        return {'latitude': 2.997660204655413, 'longitude': 101.70600927089941};
      case 'fac_football_padang_b':
        return {'latitude': 2.9960699996249094, 'longitude': 101.7069976276016};
      case 'fac_football_padang_c':
        return {'latitude': 2.995181678690454, 'longitude': 101.70770111887524};
      case 'fac_football_padang_d':
        return {
          'latitude': 2.9918733483331974,
          'longitude': 101.71658472158012,
        }; // Kolej Serumpun
      case 'fac_football_padang_e':
        return {
          'latitude': 3.0078650418969475,
          'longitude': 101.71792061303512,
        }; // Kolej 10

      // Futsal Courts (Sports Complex)
      case 'fac_futsal_kmr':
        return {'latitude': 2.9868095178480107, 'longitude': 101.7245986302808};

      // Badminton (Dewan Serbaguna)
      case 'fac_badminton_main':
        return {'latitude': 2.9868095178480107, 'longitude': 101.7245986302808};

      // Tennis Courts (Gelanggang Tenis UPM)
      case 'fac_tennis_main':
        return {'latitude': 2.9974331685643287, 'longitude': 101.7043194912751};

      default:
        // Default to UPM main location
        return {'latitude': upmLatitude, 'longitude': upmLongitude};
    }
  }

  /// Get facility location by facility name (fallback method)
  static Map<String, double> getFacilityLocationByName(String facilityName) {
    final name = facilityName.toLowerCase();

    if (name.contains('stadium')) {
      return {'latitude': 2.986372108422893, 'longitude': 101.72579628891536};
    } else if (name.contains('padang') &&
        (name.contains('padang a') || name.contains('kmr'))) {
      return {'latitude': 2.997660204655413, 'longitude': 101.70600927089941};
    } else if (name.contains('padang') && name.contains('kolej serumpun')) {
      return {'latitude': 2.9918733483331974, 'longitude': 101.71658472158012};
    } else if (name.contains('padang') && name.contains('kolej 10')) {
      return {'latitude': 3.0078650418969475, 'longitude': 101.71792061303512};
    } else if (name.contains('gelanggang futsal') || name.contains('futsal')) {
      return {'latitude': 2.9868095178480107, 'longitude': 101.7245986302808};
    } else if (name.contains('dewan serbaguna') || name.contains('badminton')) {
      return {'latitude': 2.9868095178480107, 'longitude': 101.7245986302808};
    } else if (name.contains('tenis') || name.contains('tennis')) {
      return {'latitude': 2.9974331685643287, 'longitude': 101.7043194912751};
    } else {
      return {'latitude': upmLatitude, 'longitude': upmLongitude};
    }
  }

  // Pricing (in RM) - Referee Earnings
  static const double refereeEarningsPractice =
      20.0; // Per session (practice/bookings)
  static const double refereeEarningsTournament =
      40.0; // Per match (tournaments)

  // Legacy constant - deprecated, use refereeEarningsTournament instead
  @Deprecated('Use refereeEarningsTournament instead')
  static const double refereeEarningsPerMatch = refereeEarningsTournament;

  // ═══════════════════════════════════════════════════════════════════════════
  // FACILITY PRICING
  // Student rates = small booking fees (facility access free per UPM policy)
  // Public rates = full rental rates
  // ═══════════════════════════════════════════════════════════════════════════

  // Facility Pricing - Student Booking Fees (Digital Platform Fee)
  static const double footballPriceStudent =
      10.0; // Booking fee per 2-hour session
  static const double futsalPriceStudent =
      5.0; // Booking fee per 2-hour session
  static const double badmintonPriceStudent = 3.0; // Booking fee per hour
  static const double tennisPriceStudent = 5.0; // Booking fee per hour

  // Facility Pricing - Public Rates (Full Rental) - Official UPM Akademi Sukan Rates
  static const double footballPricePublic =
      250.0; // Per 2-hour session (Padang A-E)
  static const double footballStadiumPricePublic =
      600.0; // Stadium premium rate
  static const double futsalPricePublic = 100.0; // Per 2-hour session
  static const double badmintonPricePublic = 20.0; // Per hour (max 2 hours)
  static const double tennisPricePublic =
      20.0; // Per hour (max 2 hours) - Official UPM rate

  // Maximum booking duration (UPM Policy: MAKSIMUM 2 JAM)
  static const int maxBookingHours = 2;

  // Cancellation Policy
  static const int cancellationHoursThreshold =
      24; // Must cancel 24 hours before booking

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String facilitiesCollection = 'facilities';
  static const String bookingsCollection = 'bookings';
  static const String jobsCollection = 'referee_jobs';
  static const String walletsCollection = 'wallets';
  static const String transactionsCollection = 'transactions';
  static const String escrowCollection = 'escrow';
  static const String tournamentsCollection = 'tournaments';
  static const String meritRecordsCollection = 'merit_records';
  static const String notificationsCollection = 'notifications';
  static const String blackoutDatesCollection = 'blackout_dates';
  static const String ratingsCollection = 'ratings';
  static const String emailVerificationCodesCollection =
      'email_verification_codes';
  static const String adminRevenueCollection = 'admin_revenue';

  // Storage Paths
  static const String storageProfilePictures = 'profile_pictures';
  static const String storageMeritCertificates = 'merit_certificates';

  // Tournament Configuration
  static const int minTournamentTeams = 4;
  static const int maxTournamentTeams = 8;

  // Referee Badge Codes (Pusat Kokurikulum QKS Codes)
  static const String badgeRefFootball = 'VERIFIED_REF_FOOTBALL';
  static const String badgeRefBadminton = 'VERIFIED_REF_BADMINTON';
  static const String badgeRefTennis =
      'VERIFIED_REF_TENNIS'; // QKS2103 - verify with UPM
  static const String badgeRefFutsal = 'VERIFIED_REF_FUTSAL';
  static const String badgeRefTableTennis = 'VERIFIED_REF_TABLE_TENNIS';

  // Demo Account Emails (for login screen demo buttons only - NOT for seeding)
  // These are just UI helpers - users must sign up through Firebase Auth
  static const String demoStudentEmail = 'ali@student.upm.edu.my';
  static const String demoRefereeEmail = 'haziq@student.upm.edu.my';
  static const String demoPublicEmail = 'public@example.com';
  static const String demoAdminEmail = 'admin@upm.edu.my';

  // Legacy constants for backward compatibility (deprecated - use demo* constants above)
  @Deprecated('Use demoStudentEmail instead')
  static const String testStudentEmail = demoStudentEmail;
  @Deprecated('Use demoRefereeEmail instead')
  static const String testRefereeEmail = demoRefereeEmail;
  @Deprecated('Use demoAdminEmail instead')
  static const String testAdminEmail = demoAdminEmail;

  // Email Domain
  static const String studentEmailDomain = '@student.upm.edu.my';

  // Referee Course Codes (Pusat Kokurikulum)
  static const String footballCourseCode = 'QKS2101';
  static const String badmintonCourseCode = 'QKS2102';
  static const String tennisCourseCode = 'QKS2103'; // Verify with UPM
  static const String futsalCourseCode = 'QKS2104';

  // Merit Points (GP08)
  static const int meritPointsPlayer = 2; // B1: Player participation
  static const int meritPointsReferee = 3; // B2: Referee service
  static const int meritPointsOrganizer = 5; // B3: Tournament organizer
  static const int meritPointsMaxPerSemester =
      15; // Maximum points per semester (GP08 Policy)

  // Merit Codes (GP08)
  static const String meritCodePlayer = 'B1';
  static const String meritCodeReferee = 'B2';
  static const String meritCodeOrganizer = 'B3';
}

/// User roles in the system
enum UserRole {
  student('STUDENT', 'Student'),
  public('PUBLIC', 'Public User'),
  referee('REFEREE', 'Referee'),
  admin('ADMIN', 'Administrator');

  final String code;
  final String displayName;
  const UserRole(this.code, this.displayName);

  static UserRole fromCode(String code) {
    return UserRole.values.firstWhere(
      (e) => e.code == code,
      orElse: () => UserRole.public,
    );
  }
}

/// Sport types available in the system
enum SportType {
  football('FOOTBALL', 'Football'),
  futsal('FUTSAL', 'Futsal'),
  badminton('BADMINTON', 'Badminton'),
  tennis('TENNIS', 'Tennis');

  final String code;
  final String displayName;
  const SportType(this.code, this.displayName);

  static SportType fromCode(String code) {
    return SportType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => SportType.futsal,
    );
  }
}

/// Facility types
enum FacilityType {
  inventory(
    'INVENTORY',
    'Inventory',
  ), // Multiple bookable units (e.g., Badminton Court 1, 2, 3)
  session(
    'SESSION',
    'Session',
  ); // Single unit, session-based booking (e.g., Football Field)

  final String code;
  final String displayName;
  const FacilityType(this.code, this.displayName);

  static FacilityType fromCode(String code) {
    return FacilityType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => FacilityType.session,
    );
  }
}

enum BookingStatus {
  pendingPayment('PENDING_PAYMENT', 'Pending Payment'),
  confirmed('CONFIRMED', 'Confirmed'),
  inProgress('IN_PROGRESS', 'In Progress'),
  completed('COMPLETED', 'Completed'),
  cancelled('CANCELLED', 'Cancelled'),
  refunded('REFUNDED', 'Refunded');

  final String code;
  final String displayName;
  const BookingStatus(this.code, this.displayName);

  static BookingStatus fromCode(String code) {
    return BookingStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => BookingStatus.pendingPayment,
    );
  }
}

/// Referee job status (v5.0 spec)
enum JobStatus {
  open('OPEN', 'Open'),
  assigned('ASSIGNED', 'Assigned'),
  completed('COMPLETED', 'Completed'),
  paid('PAID', 'Paid'),
  cancelled('CANCELLED', 'Cancelled');

  final String code;
  final String displayName;
  const JobStatus(this.code, this.displayName);

  static JobStatus fromCode(String code) {
    return JobStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => JobStatus.open,
    );
  }
}

/// Weather status for bookings
enum WeatherStatus {
  clear('CLEAR', 'Clear'),
  rainWarning('RAIN_WARNING', 'Rain Warning'),
  washedOut('WASHED_OUT', 'Washed Out');

  final String code;
  final String displayName;
  const WeatherStatus(this.code, this.displayName);

  static WeatherStatus fromCode(String code) {
    return WeatherStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => WeatherStatus.clear,
    );
  }
}

/// Booking type (Practice or Match)
enum BookingType {
  practice('PRACTICE', 'Practice'),
  match('MATCH', 'Match');

  final String code;
  final String displayName;
  const BookingType(this.code, this.displayName);

  static BookingType fromCode(String code) {
    return BookingType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => BookingType.practice,
    );
  }
}

/// Tournament format (for Match bookings)
enum TournamentFormat {
  eightTeamKnockout('8_TEAM_KNOCKOUT', '8-Team Knockout', 8),
  fourTeamGroup('4_TEAM_GROUP', '4-Team Knockout', 4);

  final String code;
  final String displayName;
  final int teamCount;
  const TournamentFormat(this.code, this.displayName, this.teamCount);

  static TournamentFormat? fromCode(String? code) {
    if (code == null) return null;
    return TournamentFormat.values.firstWhere(
      (e) => e.code == code,
      orElse: () => TournamentFormat.eightTeamKnockout,
    );
  }
}

/// Tournament status lifecycle
enum TournamentStatus {
  registrationOpen('REGISTRATION_OPEN', 'Registration Open'),
  registrationClosed('REGISTRATION_CLOSED', 'Registration Closed'),
  inProgress('IN_PROGRESS', 'In Progress'),
  completed('COMPLETED', 'Completed'),
  cancelled('CANCELLED', 'Cancelled');

  final String code;
  final String displayName;

  const TournamentStatus(this.code, this.displayName);

  static TournamentStatus fromCode(String code) {
    return TournamentStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => TournamentStatus.registrationOpen,
    );
  }
}

/// Tournament role for a user within a specific tournament
/// Enforces mutual exclusivity: user can only have ONE role per tournament
enum TournamentRole {
  none('NONE', 'No Role'),
  organizer('ORGANIZER', 'Organizer'),
  player('PLAYER', 'Player'),
  referee('REFEREE', 'Referee');

  final String code;
  final String displayName;

  const TournamentRole(this.code, this.displayName);

  static TournamentRole fromCode(String code) {
    return TournamentRole.values.firstWhere(
      (e) => e.code == code,
      orElse: () => TournamentRole.none,
    );
  }
}

/// Notification types for in-app notifications
enum NotificationType {
  bookingConfirmed('BOOKING_CONFIRMED', 'Booking Confirmed'),
  bookingCancelled('BOOKING_CANCELLED', 'Booking Cancelled'),
  bookingReminder24h('BOOKING_REMINDER_24H', 'Booking Reminder'),
  bookingReminder1h('BOOKING_REMINDER_1H', 'Booking Reminder'),
  paymentReceived('PAYMENT_RECEIVED', 'Payment Received'),
  paymentFailed('PAYMENT_FAILED', 'Payment Failed'),
  refundProcessed('REFUND_PROCESSED', 'Refund Processed'),
  refereeJobAssigned('REFEREE_JOB_ASSIGNED', 'Referee Job Assigned'),
  refereeJobCancelled('REFEREE_JOB_CANCELLED', 'Referee Job Cancelled'),
  refereePaymentReleased('REFEREE_PAYMENT_RELEASED', 'Payment Released'),
  tournamentCreated('TOURNAMENT_CREATED', 'Tournament Created'),
  tournamentRegistrationOpen(
    'TOURNAMENT_REGISTRATION_OPEN',
    'Tournament Registration',
  ),
  tournamentRegistrationClosed(
    'TOURNAMENT_REGISTRATION_CLOSED',
    'Tournament Registration',
  ),
  weatherWarning('WEATHER_WARNING', 'Weather Warning'),
  meritPointsAwarded('MERIT_POINTS_AWARDED', 'Merit Points Awarded'),
  general('GENERAL', 'General');

  final String code;
  final String displayName;
  const NotificationType(this.code, this.displayName);

  static NotificationType fromCode(String code) {
    return NotificationType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => NotificationType.general,
    );
  }
}

/// User mode for context switching (Student vs Referee)
/// Allows users with multiple roles to switch between different app experiences
enum UserMode {
  student('STUDENT', 'Student Mode'),
  referee('REFEREE', 'Referee Mode');

  final String code;
  final String displayName;
  const UserMode(this.code, this.displayName);

  static UserMode fromCode(String code) {
    return UserMode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => UserMode.student,
    );
  }
}

/// Transaction types
enum TransactionType {
  topUp('TOP_UP', 'Top Up'),
  bookingPayment('BOOKING_PAYMENT', 'Booking Payment'),
  refund('REFUND', 'Refund'),
  refereePayment('REFEREE_PAYMENT', 'Referee Payment'),
  escrowRelease('ESCROW_RELEASE', 'Escrow Release'),
  tournamentEntryFee('TOURNAMENT_ENTRY_FEE', 'Tournament Entry Fee');

  final String code;
  final String displayName;
  const TransactionType(this.code, this.displayName);

  static TransactionType fromCode(String code) {
    return TransactionType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => TransactionType.topUp,
    );
  }
}

/// Transaction status
enum TransactionStatus {
  pending('PENDING', 'Pending'),
  completed('COMPLETED', 'Completed'),
  failed('FAILED', 'Failed');

  final String code;
  final String displayName;
  const TransactionStatus(this.code, this.displayName);

  static TransactionStatus fromCode(String code) {
    return TransactionStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => TransactionStatus.pending,
    );
  }
}

/// Escrow status for referee payments
enum EscrowStatus {
  held('HELD', 'Held'),
  released('RELEASED', 'Released'),
  refunded('REFUNDED', 'Refunded');

  final String code;
  final String displayName;
  const EscrowStatus(this.code, this.displayName);

  static EscrowStatus fromCode(String code) {
    return EscrowStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => EscrowStatus.held,
    );
  }
}
