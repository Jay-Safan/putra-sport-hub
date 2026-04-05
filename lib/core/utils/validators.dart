import '../constants/app_constants.dart';

/// Input validation utilities for PutraSportHub
class Validators {
  Validators._();

  /// Validates email format and checks if it's a UPM student email
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return ValidationResult.invalid('Email is required');
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return ValidationResult.invalid('Please enter a valid email address');
    }

    return ValidationResult.valid();
  }

  /// Check if email belongs to UPM student
  static bool isStudentEmail(String email) {
    return email.toLowerCase().endsWith(AppConstants.studentEmailDomain);
  }

  /// Validates password strength
  static ValidationResult validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationResult.invalid('Password is required');
    }

    if (password.length < 8) {
      return ValidationResult.invalid('Password must be at least 8 characters');
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return ValidationResult.invalid(
        'Password must contain at least one uppercase letter',
      );
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return ValidationResult.invalid(
        'Password must contain at least one lowercase letter',
      );
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return ValidationResult.invalid(
        'Password must contain at least one number',
      );
    }

    return ValidationResult.valid();
  }

  /// Validates password confirmation
  static ValidationResult validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return ValidationResult.invalid('Please confirm your password');
    }

    if (password != confirmPassword) {
      return ValidationResult.invalid('Passwords do not match');
    }

    return ValidationResult.valid();
  }

  /// Validates UPM course code format
  static ValidationResult validateCourseCode(String? code) {
    if (code == null || code.isEmpty) {
      return ValidationResult.invalid('Course code is required');
    }

    // UPM course codes typically follow format: XXX0000 (3 letters + 4 digits)
    final codeRegex = RegExp(r'^[A-Z]{3}[0-9]{4}$');
    if (!codeRegex.hasMatch(code.toUpperCase())) {
      return ValidationResult.invalid(
        'Invalid course code format (e.g., QKS2101)',
      );
    }

    return ValidationResult.valid();
  }

  /// Validates referee certification course code for specific sport
  static bool isValidRefereeCourse(String courseCode, SportType sport) {
    final normalizedCode = courseCode.toUpperCase().trim();
    switch (sport) {
      case SportType.football:
        return normalizedCode == AppConstants.footballCourseCode;
      case SportType.futsal:
        return normalizedCode == AppConstants.futsalCourseCode;
      case SportType.badminton:
        return normalizedCode == AppConstants.badmintonCourseCode;
      case SportType.tennis:
        return normalizedCode == AppConstants.tennisCourseCode;
    }
  }

  /// Validates phone number (Malaysian format)
  static ValidationResult validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return ValidationResult.invalid('Phone number is required');
    }

    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    // Malaysian mobile: 01X-XXXXXXX or 01X-XXXXXXXX
    if (digitsOnly.length < 10 || digitsOnly.length > 12) {
      return ValidationResult.invalid('Please enter a valid phone number');
    }

    if (!digitsOnly.startsWith('01') && !digitsOnly.startsWith('601')) {
      return ValidationResult.invalid(
        'Please enter a valid Malaysian mobile number',
      );
    }

    return ValidationResult.valid();
  }

  /// Validates student/staff ID
  static ValidationResult validateMatricNo(String? matricNo) {
    if (matricNo == null || matricNo.isEmpty) {
      return ValidationResult.invalid('Matric number is required');
    }

    // UPM matric numbers are typically 6-10 characters
    if (matricNo.length < 6 || matricNo.length > 10) {
      return ValidationResult.invalid('Please enter a valid matric number');
    }

    return ValidationResult.valid();
  }

  /// Validates name
  static ValidationResult validateName(String? name) {
    if (name == null || name.isEmpty) {
      return ValidationResult.invalid('Name is required');
    }

    if (name.length < 2) {
      return ValidationResult.invalid('Name must be at least 2 characters');
    }

    if (name.length > 100) {
      return ValidationResult.invalid('Name is too long');
    }

    return ValidationResult.valid();
  }

  /// Validates booking date
  static ValidationResult validateBookingDate(DateTime? date) {
    if (date == null) {
      return ValidationResult.invalid('Please select a date');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate.isBefore(today)) {
      return ValidationResult.invalid('Cannot book for past dates');
    }

    // Max 30 days in advance
    final maxDate = today.add(const Duration(days: 30));
    if (selectedDate.isAfter(maxDate)) {
      return ValidationResult.invalid(
        'Cannot book more than 30 days in advance',
      );
    }

    return ValidationResult.valid();
  }

  /// Validates time slot is within operating hours
  static ValidationResult validateTimeSlot(int hour) {
    if (hour < AppConstants.operatingStartHour) {
      return ValidationResult.invalid(
        'Facility opens at ${AppConstants.operatingStartHour}:00 AM',
      );
    }

    if (hour >= AppConstants.operatingEndHour) {
      return ValidationResult.invalid(
        'Facility closes at ${AppConstants.operatingEndHour}:00 PM',
      );
    }

    return ValidationResult.valid();
  }

  /// Check if time falls within Friday prayer block
  static bool isFridayPrayerTime(DateTime dateTime) {
    if (dateTime.weekday != DateTime.friday) return false;

    final timeInMinutes = dateTime.hour * 60 + dateTime.minute;
    const blockStart =
        AppConstants.fridayBlockStartHour * 60 +
        AppConstants.fridayBlockStartMinute;
    const blockEnd =
        AppConstants.fridayBlockEndHour * 60 +
        AppConstants.fridayBlockEndMinute;

    return timeInMinutes >= blockStart && timeInMinutes < blockEnd;
  }

  /// Validates tournament title
  static ValidationResult validateTournamentTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return ValidationResult.invalid('Tournament title is required');
    }

    if (title.trim().length < 3) {
      return ValidationResult.invalid('Title must be at least 3 characters');
    }

    if (title.length > 100) {
      return ValidationResult.invalid('Title is too long (max 100 characters)');
    }

    return ValidationResult.valid();
  }

  /// Validates tournament description
  static ValidationResult validateTournamentDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return ValidationResult.invalid('Description is required');
    }

    if (description.trim().length < 10) {
      return ValidationResult.invalid(
        'Description must be at least 10 characters',
      );
    }

    if (description.length > 500) {
      return ValidationResult.invalid(
        'Description is too long (max 500 characters)',
      );
    }

    return ValidationResult.valid();
  }

  /// Validates entry fee amount
  static ValidationResult validateEntryFee(String? fee) {
    if (fee == null || fee.isEmpty) {
      return ValidationResult.invalid('Entry fee is required');
    }

    final amount = double.tryParse(fee);
    if (amount == null || amount < 0) {
      return ValidationResult.invalid('Please enter a valid amount');
    }

    if (amount > 1000) {
      return ValidationResult.invalid('Entry fee cannot exceed RM 1000');
    }

    return ValidationResult.valid();
  }

  /// Validates wallet top-up amount
  static ValidationResult validateTopUpAmount(String? amount) {
    if (amount == null || amount.isEmpty) {
      return ValidationResult.invalid('Please enter an amount');
    }

    final parsedAmount = double.tryParse(amount);
    if (parsedAmount == null || parsedAmount <= 0) {
      return ValidationResult.invalid('Please enter a valid amount');
    }

    if (parsedAmount < 10) {
      return ValidationResult.invalid('Minimum top-up is RM 10.00');
    }

    if (parsedAmount > 10000) {
      return ValidationResult.invalid('Maximum top-up is RM 10,000.00');
    }

    return ValidationResult.valid();
  }
}

/// Result class for validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._({required this.isValid, this.errorMessage});

  factory ValidationResult.valid() => const ValidationResult._(isValid: true);

  factory ValidationResult.invalid(String message) =>
      ValidationResult._(isValid: false, errorMessage: message);
}
