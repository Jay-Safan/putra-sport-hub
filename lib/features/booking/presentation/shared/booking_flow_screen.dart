import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../../../core/constants/app_constants.dart';
import '../../../../../../../../../core/widgets/sport_icon.dart';
import '../../../../../../../../../core/utils/date_time_utils.dart'
    hide TimeSlot;
import '../../../../../../../../../core/utils/date_time_utils.dart' as dt;
import '../../../../../../../../../providers/providers.dart';
import '../../data/models/facility_model.dart';
import '../../data/models/booking_model.dart';

/// Enum to represent time slot states for better UI handling
enum SlotState {
  available, // Available for booking
  booked, // Already booked by someone
  past, // Time has passed
}

class BookingFlowScreen extends ConsumerStatefulWidget {
  final String facilityId;

  const BookingFlowScreen({super.key, required this.facilityId});

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  int _currentStep = 0;
  DateTime _selectedDate = DateTime.now();
  dt.TimeSlot? _selectedSlot; // Single slot for session-based booking
  final List<dt.TimeSlot> _selectedSlots =
      []; // Multiple slots for hourly booking
  String? _selectedCourt;
  bool _isLoading = false;
  bool _enableSplitBill = false; // Split bill toggle for students
  bool _requestReferee =
      false; // Optional referee for practice sessions (students only)

  @override
  void initState() {
    super.initState();
  }

  /// Check if facility uses hourly booking (can book multiple consecutive hours)
  bool _isHourlyBooking(FacilityModel facility) {
    return facility.type == FacilityType.inventory;
  }

  /// Get total selected hours for hourly facilities
  int get _selectedHours => _selectedSlots.length;

  /// Check if a slot can be added to current selection (must be consecutive)
  bool _canAddSlot(dt.TimeSlot slot, List<dt.TimeSlot> currentSlots) {
    if (currentSlots.isEmpty) return true;
    if (currentSlots.length >= AppConstants.maxBookingHours) return false;

    // Check if slot is consecutive with any existing slot
    for (final existingSlot in currentSlots) {
      // Slot is consecutive if it starts when existing ends OR ends when existing starts
      if (slot.startTime == existingSlot.endTime ||
          slot.endTime == existingSlot.startTime) {
        return true;
      }
    }
    return false;
  }

  /// Check if removing a slot would break consecutiveness
  bool _canRemoveSlot(dt.TimeSlot slot, List<dt.TimeSlot> currentSlots) {
    if (currentSlots.length <= 1) return true;

    // Sort slots by start time
    final sorted = List<dt.TimeSlot>.from(currentSlots)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Check if slot is at the edge (first or last)
    return sorted.first.startTime == slot.startTime ||
        sorted.last.startTime == slot.startTime;
  }

  /// Get the combined start and end time from selected slots
  (DateTime start, DateTime end)? get _selectedTimeRange {
    if (_selectedSlots.isEmpty) return null;

    final sorted = List<dt.TimeSlot>.from(_selectedSlots)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return (sorted.first.startTime, sorted.last.endTime);
  }

  /// Get combined label for selected time range
  String get _selectedTimeLabel {
    final range = _selectedTimeRange;
    if (range == null) return '-';

    final startHour = range.$1.hour;
    final endHour = range.$2.hour;
    final startPeriod = startHour >= 12 ? 'PM' : 'AM';
    final endPeriod = endHour >= 12 ? 'PM' : 'AM';
    final displayStartHour =
        startHour > 12 ? startHour - 12 : (startHour == 0 ? 12 : startHour);
    final displayEndHour =
        endHour > 12 ? endHour - 12 : (endHour == 0 ? 12 : endHour);

    return '$displayStartHour$startPeriod - $displayEndHour$endPeriod (${_selectedHours}h)';
  }

  /// Calculate total amount including referee fee if requested
  double _calculateTotalWithReferee(FacilityModel facility, bool isStudent) {
    // Calculate duration
    int durationHours;
    if (_isHourlyBooking(facility)) {
      durationHours = _selectedHours;
    } else {
      durationHours =
          _selectedSlot?.endTime.difference(_selectedSlot!.startTime).inHours ??
          2;
    }

    // Calculate facility fee
    final basePrice = facility.getPrice(isStudent);
    final facilityFee =
        facility.type == FacilityType.session
            ? basePrice // Session-based: flat rate per session
            : basePrice * durationHours; // Hourly: price × hours

    // Add referee fee if requested (practice sessions use lower rate)
    double refereeFee = 0;
    if (_requestReferee) {
      final refereesRequired = _getRefereesRequired(facility.sport);
      refereeFee = refereesRequired * AppConstants.refereeEarningsPractice;
    }

    return facilityFee + refereeFee;
  }

  void _handleBack(BuildContext context) {
    // If on first step, go back to facility list or show cancel dialog
    if (_currentStep == 0) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } else {
      // Go back one step within the flow
      setState(() {
        _currentStep--;
      });
    }
  }

  void _cancelBooking(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A3D32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Cancel Booking?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to cancel? Your progress will be lost.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Continue',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/home');
                },
                child: const Text(
                  'Cancel Booking',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final facilityAsync = ref.watch(facilityProvider(widget.facilityId));
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isStudent = user?.isStudent ?? false;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _buildBackButton(context),
        title: const Text(
          'Book Facility',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () => _cancelBooking(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1F1A),
              Color(0xFF132E25),
              Color(0xFF1A3D32),
              Color(0xFF0D1F1A),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background orbs - ignore pointer events
            IgnorePointer(child: _buildBackgroundOrbs()),
            facilityAsync.when(
              data: (facility) {
                if (facility == null) {
                  return const Center(
                    child: Text(
                      'Facility not found',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return Column(
                  children: [
                    // Progress Indicator
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildProgressIndicator(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _buildStepContent(facility, isStudent),
                      ),
                    ),

                    // Bottom Action Bar
                    _buildBottomBar(facility, isStudent),
                  ],
                );
              },
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  ),
              error:
                  (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: const TextStyle(color: AppTheme.errorRed),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => _handleBack(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryGreen.withValues(alpha: 0.25),
                  AppTheme.primaryGreen.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 150,
          left: -100,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentGold.withValues(alpha: 0.15),
                  AppTheme.accentGold.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Builder(
            builder: (context) {
              // Simplified flow: Date → Time → Confirm (3 steps for everyone)
              // Organizer mode (Practice/Match) has been moved to tournament creation
              return Row(
                children: [
                  _buildStepDot(0, 'Date'),
                  _buildStepLine(0),
                  _buildStepDot(1, 'Time'),
                  _buildStepLine(1),
                  _buildStepDot(2, 'Confirm'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStepDot(int step, String label, {bool isPublicUser = false}) {
    // For public users: Map steps (0=Date, 1=Time, 2=Confirm)
    // Visual step 2 for public = internal step 3 (confirmation)
    // For students: Steps (0=Date, 1=Time, 2=Type, 3=Confirm)
    final actualStep = isPublicUser && step == 2 ? 3 : step;
    final isActive = _currentStep >= actualStep;
    final isCompleted = _currentStep > actualStep;

    // For display number: always show step + 1 (1-2-3 for public, 1-2-3-4 for students)
    final displayStepNumber = step + 1;

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient:
                isActive
                    ? const LinearGradient(
                      colors: [
                        AppTheme.primaryGreen,
                        AppTheme.primaryGreenLight,
                      ],
                    )
                    : null,
            color: isActive ? null : Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                        blurRadius: 12,
                      ),
                    ]
                    : null,
          ),
          child: Center(
            child:
                isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text(
                      displayStepNumber.toString(),
                      style: TextStyle(
                        color:
                            isActive
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color:
                isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    // For public users: Map steps differently
    // Step 0->1 line: active when currentStep > 1
    // Step 1->2 line: active when currentStep >= 3 (confirmation)
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isStudent = user?.isStudent ?? false;

    if (!isStudent && afterStep == 1) {
      // Line after Time step for public users goes to Confirm (step 3)
      final isActive = _currentStep >= 3;
      return Expanded(
        child: Container(
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color:
                isActive
                    ? AppTheme.primaryGreen
                    : Colors.white.withValues(alpha: 0.15),
          ),
        ),
      );
    }

    final isActive = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color:
              isActive
                  ? AppTheme.primaryGreen
                  : Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  Widget _buildStepContent(FacilityModel facility, bool isStudent) {
    // Simplified flow: Date → Time → Confirm (removed organizer mode - now in tournaments)
    switch (_currentStep) {
      case 0:
        return _buildDateSelection(facility);
      case 1:
        return _buildTimeSelection(facility, isStudent);
      case 2:
        return _buildConfirmation(facility, isStudent);
      default:
        return const SizedBox();
    }
  }

  Widget _buildDateSelection(FacilityModel facility) {
    final nextDays = DateTimeUtils.getNextDays(14);
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Facility Info
        _buildFacilityCard(facility),
        const SizedBox(height: 24),

        // Weather Warning for outdoor facilities
        if (!facility.isIndoor) ...[
          _buildWeatherWarning(),
          const SizedBox(height: 24),
        ],

        // Date Selection Header with current month
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Date',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateTimeUtils.formatMonthYear(today),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            // Date legend
            _buildDateLegend(),
          ],
        ),
        const SizedBox(height: 20),

        // Date Scroll with enhanced visuals
        SizedBox(
          height: 115,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: nextDays.length,
            itemBuilder: (context, index) {
              final date = nextDays[index];
              final isSelected =
                  _selectedDate.day == date.day &&
                  _selectedDate.month == date.month &&
                  _selectedDate.year == date.year;
              final isToday = DateTimeUtils.isToday(date);
              final isPast = date.isBefore(
                DateTime(today.year, today.month, today.day),
              );

              // Show month divider if month changes
              final showMonthDivider =
                  index > 0 && nextDays[index - 1].month != date.month;

              return Row(
                children: [
                  if (showMonthDivider)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        DateTimeUtils.formatMonthYear(date),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  _buildDateChip(
                    date: date,
                    isSelected: isSelected,
                    isToday: isToday,
                    isPast: isPast,
                  ),
                ],
              );
            },
          ),
        ),

        // Selected date info box
        const SizedBox(height: 20),
        _buildSelectedDateInfo(),

        // Friday Prayer Warning
        if (_selectedDate.weekday == DateTime.friday) ...[
          const SizedBox(height: 20),
          _buildFridayWarning(),
        ],
      ],
    );
  }

  /// Build individual date chip with enhanced styling
  Widget _buildDateChip({
    required DateTime date,
    required bool isSelected,
    required bool isToday,
    required bool isPast,
  }) {
    final canSelect = !isPast;

    return GestureDetector(
      onTap:
          canSelect
              ? () {
                setState(() {
                  _selectedDate = date;
                });
              }
              : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 78,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient:
              isSelected && canSelect
                  ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
                  )
                  : null,
          color:
              isSelected && canSelect
                  ? null
                  : isPast
                  ? Colors.grey[900]!.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected && canSelect
                    ? Colors.transparent
                    : isPast
                    ? Colors.white.withValues(alpha: 0.08)
                    : isToday
                    ? AppTheme.accentGold.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.15),
            width: isSelected || isToday ? 2 : 1.5,
          ),
          boxShadow:
              isSelected && canSelect
                  ? [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                      spreadRadius: 2,
                    ),
                  ]
                  : isToday
                  ? [
                    BoxShadow(
                      color: AppTheme.accentGold.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Opacity(
          opacity: isPast ? 0.4 : 1.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Day name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isPast) ...[
                    Icon(
                      Icons.access_time,
                      size: 10,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    _getDayName(date),
                    style: TextStyle(
                      color:
                          isSelected && canSelect
                              ? Colors.white.withValues(alpha: 0.9)
                              : isPast
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Date number
              Text(
                date.day.toString(),
                style: TextStyle(
                  color:
                      isSelected && canSelect
                          ? Colors.white
                          : isPast
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.95),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              // Badge for today or past
              if (isToday && !isPast)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : AppTheme.accentGold.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.accentGold,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              else if (isPast)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Past',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }

  /// Build selected date info display
  Widget _buildSelectedDateInfo() {
    final isToday = DateTimeUtils.isToday(_selectedDate);
    final weekdayName = _getFullWeekdayName(_selectedDate);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen.withValues(alpha: 0.2),
                AppTheme.primaryGreenLight.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryGreenLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weekdayName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateTimeUtils.formatDate(_selectedDate),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      color: AppTheme.accentGold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build date legend
  Widget _buildDateLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendDot(color: AppTheme.primaryGreen, label: 'Selected'),
        const SizedBox(width: 12),
        _buildLegendDot(color: AppTheme.accentGold, label: 'Today'),
        const SizedBox(width: 12),
        _buildLegendDot(color: Colors.grey[600]!, label: 'Past'),
      ],
    );
  }

  Widget _buildLegendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getFullWeekdayName(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }

  Widget _buildTimeSelection(FacilityModel facility, bool isStudent) {
    // Fetch slots with availability from BookingService
    final slotKey =
        '${widget.facilityId}|${_selectedDate.toIso8601String()}|${facility.hasSubUnits ? (_selectedCourt ?? '') : ''}';
    final slotsAsync = ref.watch(availableSlotsProvider(slotKey));

    return slotsAsync.when(
      data: (slots) => _buildTimeSlotsContent(facility, isStudent, slots),
      loading:
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGlassInfoBox(
                icon: Icons.calendar_today,
                iconColor: AppTheme.primaryGreen,
                title: DateTimeUtils.formatDate(_selectedDate),
                trailing: GestureDetector(
                  onTap: () => setState(() => _currentStep = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        color: AppTheme.primaryGreenLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            ],
          ),
      error: (error, _) {
        // Fallback to generated slots without availability check on error
        final fallbackSlots =
            facility.type == FacilityType.session
                ? DateTimeUtils.generateSessionSlots(_selectedDate)
                : DateTimeUtils.generateHourlySlots(_selectedDate);
        return _buildTimeSlotsContent(facility, isStudent, fallbackSlots);
      },
    );
  }

  Widget _buildTimeSlotsContent(
    FacilityModel facility,
    bool isStudent,
    List<dt.TimeSlot> slots,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected Date Display
        _buildGlassInfoBox(
          icon: Icons.calendar_today,
          iconColor: AppTheme.primaryGreen,
          title: DateTimeUtils.formatDate(_selectedDate),
          trailing: GestureDetector(
            onTap: () => setState(() => _currentStep = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Change',
                style: TextStyle(
                  color: AppTheme.primaryGreenLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Court Selection (for Badminton) - Moved to top
        if (facility.hasSubUnits) ...[
          Text(
            'Select Court',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose your preferred court first',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                facility.subUnits.map((court) {
                  final isSelected = _selectedCourt == court;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCourt = isSelected ? null : court;
                        // Clear selected slots when court changes to refresh availability
                        _selectedSlot = null;
                        _selectedSlots.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient:
                            isSelected
                                ? const LinearGradient(
                                  colors: [
                                    AppTheme.badmintonPurple,
                                    Color(0xFFAB47BC),
                                  ],
                                )
                                : null,
                        color:
                            isSelected
                                ? null
                                : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.15),
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: AppTheme.badmintonPurple.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 10,
                                  ),
                                ]
                                : null,
                      ),
                      child: Text(
                        court,
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: isSelected ? 1 : 0.8,
                          ),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 28),
        ],

        // Time Slots Header
        Text(
          'Select Time Slot',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          facility.type == FacilityType.session
              ? '2-hour sessions'
              : 'Hourly slots (max ${AppConstants.maxBookingHours} hours)',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),

        // Multi-hour selection info for hourly facilities
        if (_isHourlyBooking(facility)) ...[
          const SizedBox(height: 12),
          _buildMultiHourInfo(facility),
        ],

        const SizedBox(height: 16),

        // Legend for time slot states
        _buildSlotLegend(),
        const SizedBox(height: 16),

        // Time Slots Grid
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              slots.map((slot) {
                final isHourly = _isHourlyBooking(facility);
                final isSelected =
                    isHourly
                        ? _selectedSlots.any(
                          (s) => s.startTime == slot.startTime,
                        )
                        : _selectedSlot?.startTime == slot.startTime;
                final isAvailable = slot.isAvailable;
                final isPast = DateTimeUtils.hasPassed(slot.startTime);
                final isBooked = !isAvailable && !isPast;

                // For hourly booking, check if slot can be added/removed
                final canAdd =
                    isHourly ? _canAddSlot(slot, _selectedSlots) : true;
                final canRemove =
                    isHourly && isSelected
                        ? _canRemoveSlot(slot, _selectedSlots)
                        : true;

                // Determine slot state for better UI
                SlotState slotState;
                if (isPast) {
                  slotState = SlotState.past;
                } else if (isBooked) {
                  slotState = SlotState.booked;
                } else {
                  slotState = SlotState.available;
                }

                final canSelect =
                    isAvailable && !isPast && (isSelected ? canRemove : canAdd);

                return GestureDetector(
                  onTap:
                      canSelect
                          ? () => setState(() {
                            if (isHourly) {
                              // Multi-slot selection for hourly facilities
                              final newSlot = dt.TimeSlot(
                                startTime: slot.startTime,
                                endTime: slot.endTime,
                                label: slot.label,
                                isAvailable: slot.isAvailable,
                              );
                              if (isSelected) {
                                // Remove slot if already selected
                                _selectedSlots.removeWhere(
                                  (s) => s.startTime == slot.startTime,
                                );
                              } else {
                                // Add slot if within limit and consecutive
                                if (_selectedSlots.length <
                                    AppConstants.maxBookingHours) {
                                  _selectedSlots.add(newSlot);
                                }
                              }
                            } else {
                              // Single slot for session-based facilities
                              _selectedSlot = dt.TimeSlot(
                                startTime: slot.startTime,
                                endTime: slot.endTime,
                                label: slot.label,
                                isAvailable: slot.isAvailable,
                              );
                            }
                          })
                          : (isBooked || (!canAdd && !isSelected))
                          ? () {
                            // Show appropriate feedback
                            String message;
                            if (isBooked) {
                              message = 'This time slot is already booked';
                            } else if (_selectedSlots.length >=
                                AppConstants.maxBookingHours) {
                              message =
                                  'Maximum ${AppConstants.maxBookingHours} hours allowed per booking';
                            } else {
                              message = 'Select consecutive time slots only';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.block,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        message,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppTheme.errorRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                          : null,
                  child: _buildTimeSlotChip(
                    slot: slot,
                    isSelected: isSelected,
                    slotState: slotState,
                    isAddable:
                        !isSelected &&
                        canAdd &&
                        slotState == SlotState.available,
                    isRemovable: isSelected && canRemove,
                  ),
                );
              }).toList(),
        ),

        // Public User Notice - Show for non-student users
        if (!isStudent) ...[
          const SizedBox(height: 28),
          _buildPublicUserNotice(),
        ],
      ],
    );
  }

  /// Build info card for multi-hour booking
  Widget _buildMultiHourInfo(FacilityModel facility) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isStudent = user?.isStudent ?? false;
    final pricePerHour = facility.getPrice(isStudent);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGreen.withValues(alpha: 0.15),
                AppTheme.primaryGreen.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedSlots.isEmpty
                          ? 'Tap to select time slots'
                          : 'Selected: $_selectedTimeLabel',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedSlots.isEmpty
                          ? 'Select up to ${AppConstants.maxBookingHours} consecutive hours'
                          : 'Total: RM ${(pricePerHour * _selectedHours).toStringAsFixed(2)} (${_selectedHours}h × RM ${pricePerHour.toStringAsFixed(0)})',
                      style: TextStyle(
                        color:
                            _selectedSlots.isEmpty
                                ? Colors.white.withValues(alpha: 0.5)
                                : AppTheme.primaryGreenLight,
                        fontSize: 12,
                        fontWeight:
                            _selectedSlots.isEmpty
                                ? FontWeight.normal
                                : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedSlots.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_selectedHours}h',
                    style: const TextStyle(
                      color: AppTheme.primaryGreenLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build individual time slot chip with appropriate styling based on state
  Widget _buildTimeSlotChip({
    required dt.TimeSlot slot,
    required bool isSelected,
    required SlotState slotState,
    bool isAddable = true,
    bool isRemovable = true,
  }) {
    // Define colors and styles based on slot state
    Color borderColor;
    Color backgroundColor;
    Color textColor;
    IconData? icon;
    Color iconColor = Colors.white; // Default value
    double opacity;
    bool showStrikethrough;

    switch (slotState) {
      case SlotState.available:
        if (isSelected) {
          // Selected available slot - green gradient
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Text(
                  slot.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
        // Available but not selected
        borderColor = Colors.white.withValues(alpha: 0.2);
        backgroundColor = Colors.white.withValues(alpha: 0.1);
        textColor = Colors.white.withValues(alpha: 0.9);
        icon = null;
        opacity = 1.0;
        showStrikethrough = false;
        break;

      case SlotState.booked:
        // Booked by someone else - clear red/error styling with label
        borderColor = AppTheme.errorRed.withValues(alpha: 0.6);
        backgroundColor = AppTheme.errorRed.withValues(alpha: 0.2);
        textColor = Colors.white.withValues(alpha: 0.7);
        icon = Icons.event_busy;
        iconColor = AppTheme.errorRed;
        opacity = 0.9;
        showStrikethrough = true;
        break;

      case SlotState.past:
        // Time has passed - grayed out
        borderColor = Colors.white.withValues(alpha: 0.1);
        backgroundColor = Colors.grey[900]!.withValues(alpha: 0.4);
        textColor = Colors.white.withValues(alpha: 0.3);
        icon = Icons.access_time;
        iconColor = Colors.white.withValues(alpha: 0.4);
        opacity = 0.5;
        showStrikethrough = false;
        break;
    }

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: slotState == SlotState.booked ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
            ],
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration:
                        showStrikethrough ? TextDecoration.lineThrough : null,
                    decorationThickness: 2,
                  ),
                ),
                if (slotState == SlotState.booked) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Booked',
                    style: TextStyle(
                      color: AppTheme.errorRed.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build legend explaining slot states
  Widget _buildSlotLegend() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                icon: Icons.circle,
                iconColor: AppTheme.primaryGreen,
                label: 'Available',
                color: Colors.white.withValues(alpha: 0.9),
              ),
              _buildLegendItem(
                icon: Icons.event_busy,
                iconColor: AppTheme.errorRed,
                label: 'Booked',
                color: Colors.white.withValues(alpha: 0.7),
              ),
              _buildLegendItem(
                icon: Icons.access_time,
                iconColor: Colors.white.withValues(alpha: 0.4),
                label: 'Past',
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPublicUserNotice() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppTheme.warningAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Public User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Split bill and student pricing are only available for UPM students.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Removed: _buildBookingTypeSelection - organizer mode moved to tournament creation

  // Removed: _buildBookingTypeCard - organizer mode moved to tournament creation

  Widget _buildConfirmation(FacilityModel facility, bool isStudent) {
    // Calculate duration based on facility type
    final int durationHours;
    final String timeLabel;

    if (_isHourlyBooking(facility)) {
      // Multi-hour selection for hourly facilities
      durationHours = _selectedHours;
      timeLabel = _selectedTimeLabel;
    } else {
      // Single slot for session-based facilities
      durationHours =
          _selectedSlot?.endTime.difference(_selectedSlot!.startTime).inHours ??
          2;
      timeLabel = _selectedSlot?.label ?? '-';
    }

    // Calculate facility fee correctly based on facility type
    final basePrice = facility.getPrice(isStudent);
    final facilityFee =
        facility.type == FacilityType.session
            ? basePrice // Session-based: flat rate per session
            : basePrice * durationHours; // Hourly: price × hours

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking Summary',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Summary Card
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Facility', facility.name),
                  if (_selectedCourt != null)
                    _buildSummaryRow('Court', _selectedCourt!),
                  _buildSummaryRow(
                    'Date',
                    DateTimeUtils.formatDate(_selectedDate),
                  ),
                  _buildSummaryRow('Time', timeLabel),
                  if (_isHourlyBooking(facility))
                    _buildSummaryRow(
                      'Duration',
                      '$durationHours hour${durationHours > 1 ? 's' : ''}',
                    ),
                  _buildSummaryRow(
                    'Price Tier',
                    isStudent ? 'Student Rate ✓' : 'Public Rate',
                    valueColor: isStudent ? AppTheme.successGreen : null,
                  ),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.1),
                    height: 32,
                  ),
                  // Price label based on user type
                  _buildSummaryRow(
                    isStudent ? 'Booking Fee' : 'Facility Rental',
                    'RM ${facilityFee.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                  // Price breakdown for hourly facilities
                  if (facility.type == FacilityType.inventory) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 0),
                      child: Text(
                        'RM ${basePrice.toStringAsFixed(2)}/hour × $durationHours hour${durationHours > 1 ? 's' : ''} = RM ${facilityFee.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ] else if (facility.type == FacilityType.session) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 0),
                      child: Text(
                        'RM ${basePrice.toStringAsFixed(2)}/session ($durationHours hours)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  Divider(
                    color: Colors.white.withValues(alpha: 0.1),
                    height: 32,
                  ),
                  // Referee fee (if requested)
                  if (_requestReferee && isStudent) ...[
                    _buildSummaryRow(
                      'Referee Fee',
                      '+RM ${(_getRefereesRequired(facility.sport) * AppConstants.refereeEarningsPractice).toStringAsFixed(2)}',
                      valueColor: AppTheme.accentGold,
                    ),
                  ],
                  if (_enableSplitBill && isStudent) ...[
                    Divider(
                      color: Colors.white.withValues(alpha: 0.1),
                      height: 24,
                    ),
                    _buildSummaryRow(
                      'Split Bill',
                      'Enabled',
                      valueColor: AppTheme.primaryGreen,
                      isBold: true,
                    ),
                    _buildSummaryRow(
                      'Per Person (est.)',
                      'RM ${(_calculateTotalWithReferee(facility, isStudent) / AppConstants.getRecommendedSplitBillParticipants(facility.sport)).toStringAsFixed(2)}',
                      valueColor: AppTheme.primaryGreenLight,
                    ),
                  ],
                  Divider(
                    color: Colors.white.withValues(alpha: 0.1),
                    height: 32,
                  ),
                  if (_enableSplitBill && isStudent) ...[
                    // For split bill, show "Your Share" instead of "Total"
                    _buildSummaryRow(
                      'Your Share',
                      'RM ${(_calculateTotalWithReferee(facility, isStudent) / 2).toStringAsFixed(2)}',
                      isBold: true,
                      isHighlighted: true,
                      valueColor: AppTheme.primaryGreenLight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: RM ${_calculateTotalWithReferee(facility, isStudent).toStringAsFixed(2)} (split among participants)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ] else ...[
                    // For normal booking, show full total
                    _buildSummaryRow(
                      'Total',
                      'RM ${_calculateTotalWithReferee(facility, isStudent).toStringAsFixed(2)}',
                      isBold: true,
                      isHighlighted: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Split Bill Option (Students Only)
        if (isStudent) ...[
          _buildSplitBillToggle(facility, isStudent),
          const SizedBox(height: 16),
        ],

        // Request Referee Option (Students Only - for practice sessions)
        if (isStudent) ...[
          _buildRefereeOption(facility),
          const SizedBox(height: 24),
        ],

        // Booking Fee Info (Students Only)
        if (isStudent)
          _buildGlassInfoBox(
            icon: Icons.info_outline,
            iconColor: AppTheme.primaryGreenLight,
            title: 'Booking Fee Information',
            subtitle:
                'Facility access is free for UPM students. This is a digital booking fee for the platform service.',
          ),
        if (isStudent) const SizedBox(height: 16),

        // Cancellation Policy
        _buildGlassInfoBox(
          icon: Icons.info_outline,
          iconColor: AppTheme.warningAmber,
          title: 'Cancellation Policy',
          subtitle:
              'Free cancellation up to 24 hours before. Refund goes to SukanPay Wallet.',
        ),
      ],
    );
  }

  /// Build split bill toggle option (Students only)
  Widget _buildSplitBillToggle(FacilityModel facility, bool isStudent) {
    // Calculate fee based on booking type
    final int durationHours;
    if (_isHourlyBooking(facility)) {
      durationHours = _selectedHours;
    } else {
      durationHours =
          _selectedSlot?.endTime.difference(_selectedSlot!.startTime).inHours ??
          2;
    }
    // Calculate facility fee correctly based on facility type
    final basePrice = facility.getPrice(isStudent);
    final facilityFee =
        facility.type == FacilityType.session
            ? basePrice // Session-based: flat rate per session
            : basePrice * durationHours; // Hourly: price × hours

    // Calculate price per person (assuming 2 people initially, will be recalculated as more join)
    final pricePerPerson = facilityFee / 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen.withValues(alpha: 0.15),
                AppTheme.primaryGreenLight.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  _enableSplitBill
                      ? AppTheme.primaryGreen.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.15),
              width: _enableSplitBill ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Split Bill',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share costs with friends',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _enableSplitBill,
                    onChanged: (value) {
                      setState(() {
                        _enableSplitBill = value;
                      });
                    },
                    activeThumbColor: AppTheme.primaryGreen,
                    activeTrackColor: AppTheme.primaryGreenLight,
                  ),
                ],
              ),
              if (_enableSplitBill) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Share the booking cost with friends. Each person pays their share (up to ${AppConstants.getMaxSplitBillParticipants(facility.sport)} for ${facility.sport.displayName}).',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated per person',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RM ${pricePerPerson.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.primaryGreenLight,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Up to 10 people',
                          style: TextStyle(
                            color: AppTheme.primaryGreenLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityCard(FacilityModel facility) {
    final sportColor = AppTheme.getSportColor(facility.sport.code);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                sportColor.withValues(alpha: 0.3),
                sportColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: sportColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: SportIconFromCode(
                  sportCode: facility.sport.code,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            facility.isIndoor ? 'Indoor' : 'Outdoor',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            facility.type.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassInfoBox({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: iconColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherWarning() {
    return _buildGlassInfoBox(
      icon: Icons.cloud_outlined,
      iconColor: AppTheme.infoBlue,
      title: 'Outdoor Facility',
      subtitle:
          'Weather conditions will be checked. Rain > 5mm triggers auto-refund to your SukanPay wallet.',
    );
  }

  Widget _buildFridayWarning() {
    return _buildGlassInfoBox(
      icon: Icons.mosque_outlined,
      iconColor: AppTheme.warningAmber,
      title: 'Friday Prayer Time',
      subtitle:
          'Slots between 12:15 PM - 2:45 PM are blocked for Jumaat prayers.',
    );
  }

  /// Build optional referee toggle for practice sessions (Students only)
  /// This allows students to request a referee for practice/training sessions
  Widget _buildRefereeOption(FacilityModel facility) {
    // Get referee requirements for this sport
    final refereesRequired = _getRefereesRequired(facility.sport);
    final refereeFee = refereesRequired * AppConstants.refereeEarningsPractice;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.accentGold.withValues(alpha: 0.12),
                AppTheme.accentGold.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  _requestReferee
                      ? AppTheme.accentGold.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.15),
              width: _requestReferee ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sports,
                      color: AppTheme.accentGold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Referee',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Optional for practice sessions',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _requestReferee,
                    onChanged: (value) {
                      setState(() {
                        _requestReferee = value;
                      });
                    },
                    activeThumbColor: AppTheme.accentGold,
                    activeTrackColor: AppTheme.accentGold.withValues(
                      alpha: 0.3,
                    ),
                    inactiveThumbColor: Colors.white.withValues(alpha: 0.5),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ],
              ),
              if (_requestReferee) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: AppTheme.accentGold,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Referee${refereesRequired > 1 ? 's' : ''} Required',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$refereesRequired',
                            style: const TextStyle(
                              color: AppTheme.accentGold,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.attach_money,
                                color: AppTheme.accentGold,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Referee Fee',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '+RM ${refereeFee.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.accentGold,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A referee job will be posted in SukanGig marketplace for certified referees to apply.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Get referees required based on sport
  int _getRefereesRequired(SportType sport) {
    switch (sport) {
      case SportType.football:
        return 3; // 1 main + 2 linesmen
      case SportType.futsal:
        return 1; // Solo referee
      case SportType.badminton:
        return 1; // Umpire
      case SportType.tennis:
        return 1; // Chair umpire (optional)
    }
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    bool isHighlighted = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  isHighlighted
                      ? AppTheme.primaryGreenLight
                      : Colors.white.withValues(alpha: 0.6),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color:
                  valueColor ??
                  (isHighlighted
                      ? AppTheme.primaryGreenLight
                      : Colors.white.withValues(alpha: 0.9)),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isHighlighted ? 20 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(FacilityModel facility, bool isStudent) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final user = ref.read(currentUserProvider).valueOrNull;
                        final isStudent = user?.isStudent ?? false;

                        // For public users: If on step 3 (confirmation), go back to step 1 (time)
                        if (!isStudent && _currentStep == 3) {
                          setState(() {
                            _currentStep = 1;
                          });
                        } else {
                          setState(() {
                            _currentStep--;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _canProceed() && !_isLoading ? _handleNext : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient:
                            _canProceed()
                                ? const LinearGradient(
                                  colors: [
                                    AppTheme.primaryGreen,
                                    AppTheme.primaryGreenLight,
                                  ],
                                )
                                : null,
                        color:
                            _canProceed()
                                ? null
                                : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow:
                            _canProceed()
                                ? [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ]
                                : null,
                      ),
                      child: Center(
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Builder(
                                  builder: (context) {
                                    final facilityAsync = ref.read(
                                      facilityProvider(widget.facilityId),
                                    );
                                    final facility = facilityAsync.valueOrNull;

                                    // Calculate fee based on booking type
                                    double facilityFee = 0.0;
                                    if (facility != null) {
                                      final basePrice = facility.getPrice(
                                        isStudent,
                                      );
                                      if (_isHourlyBooking(facility) &&
                                          _selectedSlots.isNotEmpty) {
                                        facilityFee =
                                            basePrice * _selectedHours;
                                      } else if (_selectedSlot != null) {
                                        final durationHours =
                                            _selectedSlot!.endTime
                                                .difference(
                                                  _selectedSlot!.startTime,
                                                )
                                                .inHours;
                                        facilityFee =
                                            facility.type ==
                                                    FacilityType.session
                                                ? basePrice // Session-based: flat rate
                                                : basePrice *
                                                    durationHours; // Hourly: price × hours
                                      }
                                    }

                                    final recommendedParticipants =
                                        facility != null
                                            ? AppConstants.getRecommendedSplitBillParticipants(
                                              facility.sport,
                                            )
                                            : 2; // Default fallback
                                    final shareAmount =
                                        recommendedParticipants > 0
                                            ? facilityFee /
                                                recommendedParticipants
                                            : facilityFee;

                                    return _currentStep == 2
                                        ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _enableSplitBill && isStudent
                                                  ? 'Pay Your Share'
                                                  : 'Confirm Booking',
                                              style: TextStyle(
                                                color:
                                                    _canProceed()
                                                        ? Colors.white
                                                        : Colors.white
                                                            .withValues(
                                                              alpha: 0.4,
                                                            ),
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (_enableSplitBill &&
                                                isStudent &&
                                                shareAmount > 0) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'RM ${shareAmount.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.8),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        )
                                        : Text(
                                          'Continue',
                                          style: TextStyle(
                                            color:
                                                _canProceed()
                                                    ? Colors.white
                                                    : Colors.white.withValues(
                                                      alpha: 0.4,
                                                    ),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                  },
                                ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canProceed() {
    final facilityAsync = ref.read(facilityProvider(widget.facilityId));
    final facility = facilityAsync.valueOrNull;

    switch (_currentStep) {
      case 0:
        return true;
      case 1:
        // For facilities with subUnits (like Badminton/Tennis), court must be selected first
        if (facility?.hasSubUnits == true && _selectedCourt == null) {
          return false;
        }
        // Check slot selection based on facility type
        if (facility != null && _isHourlyBooking(facility)) {
          return _selectedSlots.isNotEmpty;
        }
        return _selectedSlot != null;
      case 2:
        return true; // Confirmation step - always can proceed
      default:
        return false;
    }
  }

  Future<void> _handleNext() async {
    if (_currentStep < 2) {
      // Move to next step
      setState(() => _currentStep++);
    } else {
      // On confirmation step, create booking
      await _createBooking();
    }
  }

  Future<void> _createBooking() async {
    final facility = ref.read(facilityProvider(widget.facilityId)).valueOrNull;
    final user = ref.read(currentUserProvider).valueOrNull;

    // Validate based on facility type
    final isHourly = facility != null && _isHourlyBooking(facility);
    if (facility == null || user == null) return;
    if (isHourly && _selectedSlots.isEmpty) return;
    if (!isHourly && _selectedSlot == null) return;

    setState(() => _isLoading = true);

    // Get user type
    final isStudent = user.isStudent;

    // Get start and end time based on booking type
    final DateTime startTime;
    final DateTime endTime;

    if (isHourly) {
      final range = _selectedTimeRange!;
      startTime = range.$1;
      endTime = range.$2;
    } else {
      startTime = _selectedSlot!.startTime;
      endTime = _selectedSlot!.endTime;
    }

    // Calculate facility fee
    final durationHours = endTime.difference(startTime).inHours;
    final facilityFee = facility.getPrice(isStudent) * durationHours;

    // Simple booking - split bill available for students
    // All bookings are treated as Practice bookings

    // Create simple practice booking
    // Note: Referees are only for tournaments - normal bookings are self-officiated
    final result = await ref
        .read(bookingServiceProvider)
        .createBooking(
          facility: facility,
          user: user,
          date: _selectedDate,
          startTime: startTime,
          endTime: endTime,
          subUnit: _selectedCourt,
          isSplitBill:
              isStudent ? _enableSplitBill : false, // Split bill for students
          requestReferee:
              isStudent
                  ? _requestReferee
                  : false, // Optional referee for practice
          splitParticipants:
              _enableSplitBill && isStudent
                  ? [
                    // Add organizer as first participant when split bill is enabled
                    // Initial share calculated based on sport's recommended participant count
                    // Amount will be recalculated automatically as more participants join
                    SplitBillParticipant(
                      oderId: user.uid, // Set organizer's user ID
                      email: user.email,
                      name: user.displayName,
                      amount:
                          facilityFee /
                          AppConstants.getRecommendedSplitBillParticipants(
                            facility.sport,
                          ),
                      hasPaid:
                          false, // Will be set to true after organizer pays
                    ),
                  ]
                  : null,
          bookingType: BookingType.practice, // All simple bookings are practice
          tournamentFormat: null, // No tournament format for simple bookings
        );

    if (!result.success) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(result.errorMessage ?? 'Booking failed')),
              ],
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    // Process payment via SukanPay wallet
    // UNIFIED LOGIC: For split bill, organizer pays only their share
    // Booking stays PENDING_PAYMENT until all participants paid (auto-confirmed)
    final paymentService = ref.read(paymentServiceProvider);
    final paymentResult = await paymentService.processBookingPayment(
      booking: result.booking!,
      user: user,
      useWallet: true,
    );

    setState(() => _isLoading = false);

    // CRITICAL: Check payment result FIRST - NEVER navigate to success page if payment failed
    if (!paymentResult.success) {
      // Payment failed - show error and stay on current page (don't navigate to success)
      if (!mounted) return;

      // Detect if error is "insufficient balance"
      final errorMessage = (paymentResult.errorMessage ?? '').toLowerCase();
      final isInsufficientBalance =
          errorMessage.contains('insufficient') ||
          errorMessage.contains('not enough') ||
          errorMessage.contains('low balance') ||
          errorMessage.contains('wallet');

      // Refresh providers to show updated booking status
      ref.invalidate(userBookingsProvider);
      ref.invalidate(upcomingBookingsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isInsufficientBalance
                      ? 'Insufficient wallet balance. Please top up and try again.'
                      : (paymentResult.errorMessage ??
                          'Payment failed. Please try again.'),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.warningAmber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      // CRITICAL: If insufficient balance, return WITHOUT navigating
      // User stays on confirmation screen to adjust wallet and retry
      if (isInsufficientBalance) {
        return;
      }

      // For other payment failures, navigate to booking detail page for retry
      if (mounted) {
        context.go('/booking/${result.booking!.id}');
      }
      return; // CRITICAL: Exit early - do NOT proceed to success page navigation
    }

    // Payment succeeded - proceed with success flow
    if (!mounted) return;

    // For split bill bookings, status will be auto-confirmed when all participants paid
    // For normal bookings, status is already confirmed by processBookingPayment
    // So we don't need to manually update status here - it's handled in the payment service

    // Refresh bookings list to ensure new booking appears in "My Bookings"
    ref.invalidate(userBookingsProvider);
    ref.invalidate(upcomingBookingsProvider);

    // Get updated booking to check for split bill team code
    final updatedBooking = await ref
        .read(bookingServiceProvider)
        .getBookingById(result.booking!.id);
    final hasSplitBill = updatedBooking?.isSplitBill ?? false;
    final teamCode = updatedBooking?.teamCode;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Booking confirmed! Payment processed.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (hasSplitBill && teamCode != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Team Code: $teamCode',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Share this code with friends to split the cost',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () {
                        // Copy team code to clipboard
                        Clipboard.setData(ClipboardData(text: teamCode));
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Team code copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // Only navigate to success page if widget is still mounted
    // (Payment already confirmed successful by early return above)
    if (mounted) {
      context.go('/booking/success/${result.booking!.id}');
    }
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}
