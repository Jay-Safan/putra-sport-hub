import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/sport_icon.dart';
import '../../../../core/utils/date_time_utils.dart' hide TimeSlot;
import '../../../../core/utils/date_time_utils.dart' as dt;
import '../../../../core/utils/validators.dart';
import '../../../../providers/providers.dart';
import '../../../booking/data/models/facility_model.dart';

/// Enum to represent time slot states for better UI handling
enum SlotState {
  available, // Available for booking
  booked, // Already booked by someone
  past, // Time has passed
}

/// Create Tournament Screen - Step-by-step tournament creation wizard
/// Clear separation from simple bookings: Organize Tournament flow
/// Flow: Sport → Facility → Format → Date & Time → Details
class CreateTournamentScreen extends ConsumerStatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  ConsumerState<CreateTournamentScreen> createState() =>
      _CreateTournamentScreenState();
}

class _CreateTournamentScreenState
    extends ConsumerState<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _prizeController = TextEditingController();
  final _organizerFeeController = TextEditingController();

  int _currentStep = 0;
  SportType _selectedSport = SportType.football;
  TournamentFormat _selectedFormat = TournamentFormat.eightTeamKnockout;
  DateTime _selectedStartDate = DateTime.now().add(const Duration(days: 7));
  dt.TimeSlot? _selectedTimeSlot; // Selected start time slot
  int _selectedDurationHours =
      4; // Tournament duration in hours (default 4 hours)
  DateTime? _timelineStartTime; // Start time selected from timeline
  DateTime? _timelineEndTime; // End time selected from timeline
  DateTime _selectedRegistrationDeadline = DateTime.now().add(
    const Duration(days: 5),
  );
  double? _entryFee;
  double? _firstPlacePrize;
  double? _organizerFee;
  final bool _isStudentOnly = true;
  String? _selectedFacilityId;
  String?
  _selectedCourt; // For facilities with subUnits (e.g., badminton courts)

  bool _isLoading = false;

  final List<String> _stepTitles = [
    'Select Sport',
    'Choose Facility',
    'Tournament Format',
    'Date & Time',
    'Tournament Details',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _entryFeeController.dispose();
    _prizeController.dispose();
    _organizerFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Organize Tournament',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1F1A), Color(0xFF132E25), Color(0xFF1A3D32)],
            ),
          ),
          child: const Center(
            child: Text(
              'Please login to create a tournament',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // If not on first step, go back to previous step
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              // If on first step, go back to home
              context.pop();
            }
          },
        ),
        title: const Text(
          'Organize Tournament',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Step Indicator
              _buildStepIndicator(),

              // Step Content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final viewInsets = MediaQuery.of(context).viewInsets;
                      return SingleChildScrollView(
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 20,
                          bottom: viewInsets.bottom + 20,
                        ),
                        child: _buildStepContent(),
                      );
                    },
                  ),
                ),
              ),

              // Navigation Buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(_stepTitles.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isCompleted || isActive
                              ? AppTheme.accentGold
                              : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < _stepTitles.length - 1) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildSportSelection();
      case 1:
        return _buildFacilitySelection();
      case 2:
        return _buildFormatSelection();
      case 3:
        return _buildDateTimeSelection();
      case 4:
        return _buildDetailsForm();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSportSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _stepTitles[_currentStep],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the sport for your tournament',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),

        // Sport Cards
        _buildSportCard(SportType.football, AppTheme.footballOrange),
        const SizedBox(height: 16),
        _buildSportCard(SportType.futsal, AppTheme.futsalBlue),
        const SizedBox(height: 16),
        _buildSportCard(SportType.badminton, AppTheme.badmintonPurple),
        const SizedBox(height: 16),
        _buildSportCard(SportType.tennis, AppTheme.tennisGreen),
      ],
    );
  }

  Widget _buildSportCard(SportType sport, Color color) {
    final isSelected = _selectedSport == sport;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSport = sport;
          _selectedFacilityId = null; // Reset facility when sport changes
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                  )
                  : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SportIcon(sport: sport, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sport.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSportDescription(sport),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  String _getSportDescription(SportType sport) {
    switch (sport) {
      case SportType.football:
        return 'Full field, 11v11 format';
      case SportType.futsal:
        return 'Indoor court, 5v5 format';
      case SportType.badminton:
        return 'Court-based, singles/doubles';
      case SportType.tennis:
        return 'Outdoor court, singles/doubles';
    }
  }

  Widget _buildFacilitySelection() {
    final facilitiesAsync = ref.watch(
      facilitiesBySportProvider(_selectedSport),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _stepTitles[_currentStep],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select a facility for ${_selectedSport.displayName}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),

        facilitiesAsync.when(
          data: (facilities) {
            if (facilities.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No facilities available for ${_selectedSport.displayName}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children:
                  facilities.map((facility) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildFacilityCard(facility),
                    );
                  }).toList(),
            );
          },
          loading:
              () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
          error:
              (error, stack) => Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Error loading facilities: $error',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildFacilityCard(FacilityModel facility) {
    final isSelected = _selectedFacilityId == facility.id;
    final hasSubUnits = facility.hasSubUnits;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              // Reset selections if facility changes
              if (_selectedFacilityId != facility.id) {
                _selectedCourt = null;
                _selectedTimeSlot = null;
              }
              _selectedFacilityId = facility.id;
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient:
                      isSelected
                          ? const LinearGradient(
                            colors: [
                              AppTheme.primaryGreen,
                              AppTheme.primaryGreenLight,
                            ],
                          )
                          : null,
                  color:
                      isSelected ? null : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.15),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                facility.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (hasSubUnits) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${facility.subUnits.length} courts',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (facility.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              facility.description,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'RM ${facility.getPrice(true).toStringAsFixed(0)}/hr (Student)',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _stepTitles[_currentStep],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the tournament format',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),

        _buildFormatCard(
          TournamentFormat.eightTeamKnockout,
          '8-Team Knockout',
          'Single elimination bracket\nPerfect for competitive tournaments',
          Icons.tour,
        ),
        const SizedBox(height: 16),
        _buildFormatCard(
          TournamentFormat.fourTeamGroup,
          '4-Team Knockout',
          'Semifinal matches + Final\nFast elimination format',
          Icons.military_tech,
        ),
      ],
    );
  }

  Widget _buildFormatCard(
    TournamentFormat format,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedFormat == format;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFormat = format);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [
                      AppTheme.upmRed,
                      AppTheme.upmRed.withValues(alpha: 0.8),
                    ],
                  )
                  : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppTheme.upmRed.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${format.teamCount} teams',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    // Get facility to check its type and subUnits
    final facilityAsync =
        _selectedFacilityId != null
            ? ref.watch(facilityProvider(_selectedFacilityId!))
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _stepTitles[_currentStep],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'When will your tournament take place?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),

        // Registration Deadline
        _buildDatePickerCard(
          title: 'Registration Deadline',
          date: _selectedRegistrationDeadline,
          icon: Icons.event_available,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedRegistrationDeadline,
              firstDate: DateTime.now(),
              lastDate: _selectedStartDate.subtract(const Duration(days: 1)),
            );
            if (date != null && mounted) {
              setState(() {
                _selectedRegistrationDeadline = date;
                // Clear selected slot when deadline changes
                _selectedTimeSlot = null;
              });
            }
          },
        ),
        const SizedBox(height: 16),

        // Tournament Start Date
        _buildDatePickerCard(
          title: 'Tournament Start Date',
          date: _selectedStartDate,
          icon: Icons.calendar_today,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedStartDate,
              firstDate: _selectedRegistrationDeadline.add(
                const Duration(days: 1),
              ),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null && mounted) {
              setState(() {
                _selectedStartDate = date;
                // Clear selected slot when date changes
                _selectedTimeSlot = null;
              });
            }
          },
        ),
        const SizedBox(height: 24),

        // Time Slot Selection (enhanced with availability)
        if (facilityAsync != null)
          facilityAsync.when(
            data: (facility) {
              if (facility == null) {
                return const SizedBox.shrink();
              }
              return _buildTimeSlotSelection(facility);
            },
            loading:
                () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
            error: (_, __) => const SizedBox.shrink(),
          )
        else
          _buildFacilityNotSelectedMessage(),
      ],
    );
  }

  Widget _buildFacilityNotSelectedMessage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.warningAmber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.warningAmber.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.warningAmber,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please select a facility first to see available time slots',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
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

  Widget _buildTimeSlotSelection(FacilityModel facility) {
    // For facilities with subUnits, if no court is selected yet, show court selection UI with default slots
    // Once a court is selected, fetch actual availability for that court
    final slotKey =
        '${_selectedFacilityId!}|${_selectedStartDate.toIso8601String()}|${facility.hasSubUnits ? (_selectedCourt ?? '') : ''}';

    // If facility has subUnits but no court selected, use default slots for now
    // The court selection UI will appear and once selected, it will rebuild with real availability
    if (facility.hasSubUnits &&
        (_selectedCourt == null || _selectedCourt!.isEmpty)) {
      // Generate default slots to show in the UI
      final defaultSlots =
          facility.type == FacilityType.session
              ? DateTimeUtils.generateSessionSlots(_selectedStartDate)
              : DateTimeUtils.generateHourlySlots(_selectedStartDate);
      return _buildTimeSlotsContent(facility, defaultSlots);
    }

    // Fetch slots with availability for the selected court (or facility without courts)
    final slotsAsync = ref.watch(availableSlotsProvider(slotKey));

    return slotsAsync.when(
      data: (slots) => _buildTimeSlotsContent(facility, slots),
      loading:
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Court Selection UI (shown while loading if facility has courts)
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
                              _timelineStartTime = null;
                              _timelineEndTime = null;
                              _selectedTimeSlot = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
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
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.transparent
                                        : Colors.white.withValues(alpha: 0.15),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: AppTheme.badmintonPurple
                                              .withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sports_tennis,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.8),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  court,
                                  style: TextStyle(
                                    color: Colors.white.withValues(
                                      alpha: isSelected ? 1 : 0.8,
                                    ),
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 32),
              ],
              const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            ],
          ),
      error: (error, _) {
        // Fallback to generated slots without availability check on error
        final fallbackSlots =
            facility.type == FacilityType.session
                ? DateTimeUtils.generateSessionSlots(_selectedStartDate)
                : DateTimeUtils.generateHourlySlots(_selectedStartDate);
        return _buildTimeSlotsContent(facility, fallbackSlots);
      },
    );
  }

  Widget _buildTimeSlotsContent(
    FacilityModel facility,
    List<dt.TimeSlot> slots,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Court Selection (for facilities with courts like Badminton)
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
                        // Clear timeline selection when court changes to refresh availability
                        _timelineStartTime = null;
                        _timelineEndTime = null;
                        _selectedTimeSlot = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
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
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.15),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: AppTheme.badmintonPurple.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sports_tennis,
                            color:
                                isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.8),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            court,
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: isSelected ? 1 : 0.8,
                              ),
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Only show timeline if court is selected (for facilities with courts)
        if (facility.hasSubUnits &&
            (_selectedCourt == null || _selectedCourt!.isEmpty)) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.infoBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.infoBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.infoBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please select a court first to see available time slots',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          // Selected Range Summary (shown first for better hierarchy)
          if (_timelineStartTime != null && _timelineEndTime != null) ...[
            _buildRangeSummary(),
            const SizedBox(height: 32),
            // Visual separator for better hierarchy
            Divider(
              color: Colors.white.withValues(alpha: 0.1),
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 32),
          ],

          // Visual Timeline Selection
          Text(
            'Select Tournament Time',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap on the timeline to select your time range',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // Visual Timeline Bar
          _buildVisualTimeline(facility, slots),
          const SizedBox(height: 24),

          // Duration Quick Select
          _buildDurationQuickSelect(),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  bool _checkTimeRangeAvailability(
    List<dt.TimeSlot> slots,
    DateTime startTime,
    DateTime endTime,
  ) {
    // Get slot duration (assuming all slots have same duration)
    if (slots.isEmpty) return false;
    final slotDuration = slots.first.endTime.difference(slots.first.startTime);

    // Generate all slots that should exist in the range
    final requiredSlots = <DateTime>[];
    DateTime currentTime = startTime;

    while (currentTime.isBefore(endTime)) {
      // Find the slot that starts at or before currentTime
      final matchingSlot = slots.firstWhere(
        (slot) => slot.startTime == currentTime,
        orElse:
            () => dt.TimeSlot(
              startTime: currentTime,
              endTime: currentTime.add(slotDuration),
              label: DateTimeUtils.formatTime(currentTime),
              isAvailable: false,
            ),
      );

      // If this slot is not available, the range is not available
      if (!matchingSlot.isAvailable) {
        return false;
      }

      requiredSlots.add(currentTime);
      currentTime = currentTime.add(slotDuration);
    }

    // All required slots must be available
    return requiredSlots.isNotEmpty &&
        requiredSlots.every((slotTime) {
          final slot = slots.firstWhere(
            (s) => s.startTime == slotTime,
            orElse:
                () => dt.TimeSlot(
                  startTime: slotTime,
                  endTime: slotTime.add(slotDuration),
                  label: DateTimeUtils.formatTime(slotTime),
                  isAvailable: false,
                ),
          );
          return slot.isAvailable;
        });
  }

  /// Find the nearest available time slot that can accommodate the selected duration
  /// Searches within a reasonable range (3 hours before/after tapped time)
  DateTime? _findNearestAvailableTime(
    List<dt.TimeSlot> slots,
    DateTime tappedTime,
    int durationHours,
  ) {
    if (slots.isEmpty) return null;

    // Get slot duration (assuming all slots have same duration)
    final slotDuration = slots.first.endTime.difference(slots.first.startTime);

    // Round tapped time to nearest slot boundary (hour)
    final roundedTime = DateTime(
      tappedTime.year,
      tappedTime.month,
      tappedTime.day,
      tappedTime.hour,
    );

    // Get all available slots
    final availableSlots =
        slots
            .where(
              (slot) =>
                  slot.isAvailable && !DateTimeUtils.hasPassed(slot.startTime),
            )
            .toList();

    if (availableSlots.isEmpty) return null;

    // Check if rounded time itself is available
    final matchingSlot = availableSlots.firstWhere(
      (slot) => slot.startTime == roundedTime,
      orElse:
          () => dt.TimeSlot(
            startTime: roundedTime,
            endTime: roundedTime.add(slotDuration),
            label: DateTimeUtils.formatTime(roundedTime),
            isAvailable: false,
          ),
    );

    if (matchingSlot.isAvailable) {
      final endTime = roundedTime.add(Duration(hours: durationHours));
      if (_checkTimeRangeAvailability(slots, roundedTime, endTime)) {
        return roundedTime;
      }
    }

    // Search within 3 hours before/after the tapped time
    const searchRange = Duration(hours: 3);
    final searchStart = roundedTime.subtract(searchRange);
    final searchEnd = roundedTime.add(searchRange);

    // Filter available slots within search range
    final nearbySlots =
        availableSlots
            .where(
              (slot) =>
                  slot.startTime.isAfter(
                    searchStart.subtract(const Duration(minutes: 1)),
                  ) &&
                  slot.startTime.isBefore(
                    searchEnd.add(const Duration(minutes: 1)),
                  ),
            )
            .toList();

    if (nearbySlots.isEmpty) return null;

    // Find the slot closest to tapped time that can accommodate the duration
    DateTime? bestMatch;
    int minDistance = double.maxFinite.toInt();

    for (final slot in nearbySlots) {
      final endTime = slot.startTime.add(Duration(hours: durationHours));

      // Check if this slot can accommodate the full duration
      if (_checkTimeRangeAvailability(slots, slot.startTime, endTime)) {
        final distance =
            (slot.startTime.difference(roundedTime).abs().inMinutes);
        if (distance < minDistance) {
          minDistance = distance;
          bestMatch = slot.startTime;
        }
      }
    }

    return bestMatch;
  }

  /// Build Visual Timeline - Shows entire day with bookings and allows range selection
  Widget _buildVisualTimeline(FacilityModel facility, List<dt.TimeSlot> slots) {
    // Define day hours (8 AM to 10 PM = 14 hours)
    final dayStart = DateTime(
      _selectedStartDate.year,
      _selectedStartDate.month,
      _selectedStartDate.day,
      8,
    );
    final dayEnd = DateTime(
      _selectedStartDate.year,
      _selectedStartDate.month,
      _selectedStartDate.day,
      22,
    );
    final totalMinutes = dayEnd.difference(dayStart).inMinutes;

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
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline Bar - Using LayoutBuilder for proper width calculation
              LayoutBuilder(
                builder: (context, constraints) {
                  final timelineWidth = constraints.maxWidth;

                  return SizedBox(
                    height: 70,
                    child: Stack(
                      children: [
                        // Background timeline
                        Container(
                          height: 50,
                          width: timelineWidth,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),

                        // Booked/unavailable slots (red blocks) - shows ALL unavailable slots
                        // This includes bookings from simple bookings AND tournaments
                        ...slots
                            .where(
                              (slot) =>
                                  !slot.isAvailable ||
                                  DateTimeUtils.hasPassed(slot.startTime),
                            )
                            .map((slot) {
                              final startPercent = _getTimePercent(
                                slot.startTime,
                                dayStart,
                                dayEnd,
                              );
                              final endPercent = _getTimePercent(
                                slot.endTime,
                                dayStart,
                                dayEnd,
                              );
                              final widthPercent = (endPercent - startPercent)
                                  .clamp(0.0, 1.0);

                              if (widthPercent <= 0) {
                                return const SizedBox.shrink();
                              }

                              final isPast = DateTimeUtils.hasPassed(
                                slot.startTime,
                              );
                              final isBooked = !slot.isAvailable && !isPast;

                              return Positioned(
                                left: timelineWidth * startPercent,
                                width: timelineWidth * widthPercent,
                                top: 0,
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    // Past slots: gray, Booked slots (simple bookings + tournaments): bright red
                                    color:
                                        isPast
                                            ? Colors.grey[700]!.withValues(
                                              alpha: 0.6,
                                            )
                                            : AppTheme.errorRed.withValues(
                                              alpha: 0.7,
                                            ), // Increased opacity for better visibility
                                    borderRadius: BorderRadius.circular(25),
                                    border:
                                        isBooked
                                            ? Border.all(
                                              color: AppTheme.errorRed
                                                  .withValues(alpha: 0.9),
                                              width: 1.5,
                                            )
                                            : null,
                                  ),
                                ),
                              );
                            }),

                        // Selected range (green highlight)
                        if (_timelineStartTime != null &&
                            _timelineEndTime != null)
                          Positioned(
                            left:
                                timelineWidth *
                                _getTimePercent(
                                  _timelineStartTime!,
                                  dayStart,
                                  dayEnd,
                                ),
                            width:
                                timelineWidth *
                                (_getTimePercent(
                                          _timelineEndTime!,
                                          dayStart,
                                          dayEnd,
                                        ) -
                                        _getTimePercent(
                                          _timelineStartTime!,
                                          dayStart,
                                          dayEnd,
                                        ))
                                    .clamp(0.0, 1.0),
                            top: 0,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryGreen.withValues(
                                      alpha: 0.7,
                                    ),
                                    AppTheme.primaryGreenLight.withValues(
                                      alpha: 0.7,
                                    ),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: AppTheme.primaryGreen,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Interactive touch area
                        GestureDetector(
                          onTapDown: (details) {
                            final localPosition = details.localPosition;
                            final percent = (localPosition.dx / timelineWidth)
                                .clamp(0.0, 1.0);
                            final tappedTime = dayStart.add(
                              Duration(
                                minutes: (percent * totalMinutes).round(),
                              ),
                            );

                            setState(() {
                              // Round tapped time to nearest hour for comparison
                              final roundedHour = tappedTime.hour;
                              final tappedTimeRounded = DateTime(
                                tappedTime.year,
                                tappedTime.month,
                                tappedTime.day,
                                roundedHour,
                              );

                              if (_timelineStartTime == null ||
                                  _timelineEndTime != null ||
                                  tappedTimeRounded.isBefore(
                                    _timelineStartTime!,
                                  )) {
                                // Setting new start time - find nearest available slot
                                final nearestAvailable =
                                    _findNearestAvailableTime(
                                      slots,
                                      tappedTime,
                                      _selectedDurationHours,
                                    );

                                if (nearestAvailable != null) {
                                  _timelineStartTime = nearestAvailable;
                                  _timelineEndTime = nearestAvailable.add(
                                    Duration(hours: _selectedDurationHours),
                                  );

                                  // Update selected time slot
                                  _selectedTimeSlot = dt.TimeSlot(
                                    startTime: _timelineStartTime!,
                                    endTime: _timelineEndTime!,
                                    label: DateTimeUtils.formatTime(
                                      _timelineStartTime!,
                                    ),
                                    isAvailable: true,
                                  );

                                  // Show subtle feedback if time was adjusted
                                  if ((nearestAvailable
                                          .difference(tappedTime)
                                          .abs()
                                          .inMinutes) >
                                      30) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Selected nearest available time: ${DateTimeUtils.formatTime(nearestAvailable)}',
                                        ),
                                        backgroundColor: AppTheme.primaryGreen,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } else {
                                  // No available slots found nearby
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No available time slots found nearby. Please try a different area.',
                                      ),
                                      backgroundColor: AppTheme.errorRed,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } else {
                                // Setting end time - round to nearest hour and check if range is available
                                final roundedHour = tappedTime.hour;
                                final tappedTimeRounded = DateTime(
                                  tappedTime.year,
                                  tappedTime.month,
                                  tappedTime.day,
                                  roundedHour,
                                );

                                if (tappedTimeRounded.isAfter(
                                  _timelineStartTime!,
                                )) {
                                  // Try to use the tapped time as end time
                                  if (_checkTimeRangeAvailability(
                                    slots,
                                    _timelineStartTime!,
                                    tappedTimeRounded,
                                  )) {
                                    _timelineEndTime = tappedTimeRounded;
                                    _selectedDurationHours =
                                        _timelineEndTime!
                                            .difference(_timelineStartTime!)
                                            .inHours;

                                    // Update selected time slot
                                    _selectedTimeSlot = dt.TimeSlot(
                                      startTime: _timelineStartTime!,
                                      endTime: _timelineEndTime!,
                                      label: DateTimeUtils.formatTime(
                                        _timelineStartTime!,
                                      ),
                                      isAvailable: true,
                                    );
                                  } else {
                                    // Try to find nearest valid end time
                                    final maxEndTime = dayEnd;

                                    DateTime? bestEndTime;
                                    for (
                                      int hours = _selectedDurationHours;
                                      hours <= 12;
                                      hours++
                                    ) {
                                      final testEndTime = _timelineStartTime!
                                          .add(Duration(hours: hours));
                                      if (testEndTime.isAfter(maxEndTime)) {
                                        break;
                                      }

                                      if (_checkTimeRangeAvailability(
                                        slots,
                                        _timelineStartTime!,
                                        testEndTime,
                                      )) {
                                        // Check if this is closer to the tapped time
                                        if (bestEndTime == null ||
                                            (testEndTime
                                                    .difference(
                                                      tappedTimeRounded,
                                                    )
                                                    .abs() <
                                                bestEndTime
                                                    .difference(
                                                      tappedTimeRounded,
                                                    )
                                                    .abs())) {
                                          bestEndTime = testEndTime;
                                        }
                                      }
                                    }

                                    if (bestEndTime != null) {
                                      _timelineEndTime = bestEndTime;
                                      _selectedDurationHours =
                                          _timelineEndTime!
                                              .difference(_timelineStartTime!)
                                              .inHours;

                                      // Update selected time slot
                                      _selectedTimeSlot = dt.TimeSlot(
                                        startTime: _timelineStartTime!,
                                        endTime: _timelineEndTime!,
                                        label: DateTimeUtils.formatTime(
                                          _timelineStartTime!,
                                        ),
                                        isAvailable: true,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Unable to extend to selected time. Please choose a different range.',
                                          ),
                                          backgroundColor: AppTheme.errorRed,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                }
                              }
                            });
                          },
                          child: Container(
                            height: 50,
                            width: timelineWidth,
                            color: Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Time Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '8 AM',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '12 PM',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '4 PM',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '10 PM',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(
                    color: AppTheme.primaryGreen,
                    label: 'Your Selection',
                  ),
                  const SizedBox(width: 20),
                  _buildLegendItem(
                    color: AppTheme.errorRed,
                    label: 'Booked (All Types)',
                  ),
                  const SizedBox(width: 20),
                  _buildLegendItem(color: Colors.grey[700]!, label: 'Past'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  double _getTimePercent(DateTime time, DateTime dayStart, DateTime dayEnd) {
    if (time.isBefore(dayStart)) return 0.0;
    if (time.isAfter(dayEnd)) return 1.0;
    final total = dayEnd.difference(dayStart).inMinutes;
    final position = time.difference(dayStart).inMinutes;
    return (position / total).clamp(0.0, 1.0);
  }

  /// Duration Quick Select - Compact buttons for common durations
  Widget _buildDurationQuickSelect() {
    final durations = [2, 4, 6, 8];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Duration',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children:
              durations.map((hours) {
                final isSelected = _selectedDurationHours == hours;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: hours != durations.last ? 8 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDurationHours = hours;
                          // Update end time if start time is already selected on timeline
                          if (_timelineStartTime != null) {
                            final newEndTime = _timelineStartTime!.add(
                              Duration(hours: hours),
                            );
                            // Check if range is available before updating
                            // Note: We'll validate this when user taps on timeline, so just update for now
                            _timelineEndTime = newEndTime;
                            _selectedTimeSlot = dt.TimeSlot(
                              startTime: _timelineStartTime!,
                              endTime: _timelineEndTime!,
                              label: DateTimeUtils.formatTime(
                                _timelineStartTime!,
                              ),
                              isAvailable: true,
                            );
                          } else {
                            // Clear selection if no start time selected
                            _timelineEndTime = null;
                            _selectedTimeSlot = null;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient:
                              isSelected
                                  ? const LinearGradient(
                                    colors: [
                                      AppTheme.primaryGreen,
                                      AppTheme.primaryGreenLight,
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
                                      color: AppTheme.primaryGreen.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Text(
                          '$hours${hours == 1 ? 'h' : 'h'}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  /// Range Summary Display
  Widget _buildRangeSummary() {
    if (_timelineStartTime == null || _timelineEndTime == null) {
      return const SizedBox.shrink();
    }

    final duration = _timelineEndTime!.difference(_timelineStartTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen.withValues(alpha: 0.25),
                AppTheme.primaryGreenLight.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.primaryGreenLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tournament Time Range',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateTimeUtils.formatDate(_timelineStartTime!),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.primaryGreenLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      minutes > 0
                          ? '$hours h ${minutes}m'
                          : '$hours hour${hours > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Start Time to End Time Display
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Time',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.play_circle_outline,
                                color: AppTheme.primaryGreenLight,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateTimeUtils.formatTime(_timelineStartTime!),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.arrow_forward,
                      color: AppTheme.primaryGreenLight,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Time',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.stop_circle_outlined,
                                color: AppTheme.accentGold,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateTimeUtils.formatTime(_timelineEndTime!),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerCard({
    required String title,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, dd MMM yyyy').format(date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsForm() {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _stepTitles[_currentStep],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Fill in the tournament details',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),

        // Referee Information Card
        _buildRefereeInfoCard(),
        const SizedBox(height: 20),

        // Tournament Title
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextFormField(
              controller: _titleController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Tournament Title',
                helperText: 'Give your tournament a catchy name',
                helperMaxLines: 2,
                prefixIcon: Icon(
                  Icons.title,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                helperStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryGreen,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.errorRed,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.errorRed,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                final result = Validators.validateTournamentTitle(value);
                return result.isValid ? null : result.errorMessage;
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Description
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextFormField(
              controller: _descriptionController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Description',
                helperText: 'Optional: Describe your tournament',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Icon(
                    Icons.description_outlined,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                alignLabelWithHint: true,
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                helperStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryGreen,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Entry Fee
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextFormField(
              controller: _entryFeeController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Entry Fee',
                helperText: 'Leave empty for a free tournament',
                prefixIcon: Icon(
                  Icons.attach_money_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                prefixText: 'RM ',
                prefixStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                helperStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryGreen,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _entryFee = value.isEmpty ? null : double.tryParse(value);
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Prize Money (if entry fee is set)
        if (_entryFee != null && _entryFee! > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextFormField(
                controller: _prizeController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'First Place Prize (Optional)',
                  helperText: 'Prize amount for the winner',
                  prefixIcon: Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  prefixText: 'RM ',
                  prefixStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  helperStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _firstPlacePrize =
                        value.isEmpty ? null : double.tryParse(value);
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Organizer Fee
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextFormField(
                controller: _organizerFeeController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Organizer Fee (Optional)',
                  helperText: 'Your commission for organizing',
                  prefixIcon: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  prefixText: 'RM ',
                  prefixStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  helperStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _organizerFee =
                        value.isEmpty ? null : double.tryParse(value);
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Financial Summary
          _buildFinancialSummary(),
          const SizedBox(height: 20),
        ],

        // Students Only Info Card (if user is student)
        if (user?.isStudent ?? false)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGreenLight.withValues(alpha: 0.15),
                      AppTheme.primaryGreenLight.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryGreenLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreenLight.withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppTheme.primaryGreenLight,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Students Only',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This tournament is exclusively for UPM students',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRefereeInfoCard() {
    // Get referees required for selected sport
    int getRefereesRequired(SportType sport) {
      switch (sport) {
        case SportType.football:
          return 3; // 1 main + 2 linesmen
        case SportType.futsal:
          return 1; // Solo referee
        case SportType.badminton:
          return 1; // Umpire
        case SportType.tennis:
          return 1; // Chair umpire
      }
    }

    final refereesRequired = getRefereesRequired(_selectedSport);
    const refereeFeePerMatch = AppConstants.refereeEarningsTournament;
    final totalRefereeCost = refereesRequired * refereeFeePerMatch;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGreenLight.withValues(alpha: 0.15),
                AppTheme.primaryGreenLight.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryGreenLight.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreenLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tournament Referees Required',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$refereesRequired referee(s) × RM ${refereeFeePerMatch.toStringAsFixed(0)}/match = RM ${totalRefereeCost.toStringAsFixed(0)} total',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This cost will be deducted from entry fees',
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

  Widget _buildFinancialSummary() {
    // Calculate financial breakdown
    final entryFee = _entryFee ?? 0;
    final maxTeams = _selectedFormat.teamCount;
    final totalRevenue = entryFee * maxTeams;

    // Get referees required based on sport
    int getRefereesRequired(SportType sport) {
      switch (sport) {
        case SportType.football:
          return 3;
        case SportType.futsal:
          return 1;
        case SportType.badminton:
          return 1;
        case SportType.tennis:
          return 1;
      }
    }

    final refereesRequired = getRefereesRequired(_selectedSport);
    final refereeFeeTotal =
        refereesRequired * AppConstants.refereeEarningsTournament;

    final prize = _firstPlacePrize ?? 0;
    final organizerFee = _organizerFee ?? 0;
    final totalDistribution = prize + organizerFee;
    final remainingAfterReferees = totalRevenue - refereeFeeTotal;
    final balance = remainingAfterReferees - totalDistribution;
    final isValid = balance >= 0 && totalRevenue > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (isValid ? AppTheme.primaryGreenLight : AppTheme.errorRed)
                    .withValues(alpha: 0.15),
                (isValid ? AppTheme.primaryGreenLight : AppTheme.errorRed)
                    .withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isValid ? AppTheme.primaryGreenLight : AppTheme.errorRed)
                  .withValues(alpha: 0.3),
              width: isValid ? 1 : 1.5,
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
                      color: (isValid
                              ? AppTheme.primaryGreenLight
                              : AppTheme.errorRed)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isValid
                          ? Icons.account_balance_rounded
                          : Icons.warning_rounded,
                      color:
                          isValid
                              ? AppTheme.primaryGreenLight
                              : AppTheme.errorRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial Summary',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isValid
                              ? 'Breakdown of tournament finances'
                              : 'Prize + Organizer Fee exceeds available funds',
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
              const SizedBox(height: 20),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              _buildFinancialRow(
                'Total Revenue',
                'RM ${totalRevenue.toStringAsFixed(2)}',
                'Entry Fee × $maxTeams teams',
                Colors.white,
              ),
              const SizedBox(height: 12),
              _buildFinancialRow(
                'Referee Costs',
                '-RM ${refereeFeeTotal.toStringAsFixed(2)}',
                '$refereesRequired referee(s) × RM ${AppConstants.refereeEarningsTournament.toStringAsFixed(0)}',
                AppTheme.errorRed,
              ),
              const SizedBox(height: 12),
              _buildFinancialRow(
                'Available Funds',
                'RM ${remainingAfterReferees.toStringAsFixed(2)}',
                'After referee costs',
                AppTheme.primaryGreenLight,
                isBold: true,
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              if (prize > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildFinancialRow(
                    'First Place Prize',
                    'RM ${prize.toStringAsFixed(2)}',
                    null,
                    AppTheme.accentGold,
                  ),
                ),
              if (organizerFee > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildFinancialRow(
                    'Organizer Fee',
                    'RM ${organizerFee.toStringAsFixed(2)}',
                    null,
                    AppTheme.primaryGreenLight,
                  ),
                ),
              if (totalDistribution > 0) ...[
                const SizedBox(height: 12),
                _buildFinancialRow(
                  'Total Distribution',
                  'RM ${totalDistribution.toStringAsFixed(2)}',
                  null,
                  Colors.white,
                  isBold: true,
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                _buildFinancialRow(
                  'Balance',
                  'RM ${balance.toStringAsFixed(2)}',
                  balance >= 0 ? 'Remaining funds' : 'Deficit',
                  balance >= 0 ? AppTheme.primaryGreenLight : AppTheme.errorRed,
                  isBold: true,
                ),
              ],
              if (!isValid && totalRevenue > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.errorRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.errorRed,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reduce prize or organizer fee to match available funds',
                          style: TextStyle(
                            color: AppTheme.errorRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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

  Widget _buildFinancialRow(
    String label,
    String value,
    String? subtitle,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep--);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Text(
                        _currentStep == _stepTitles.length - 1
                            ? 'Create Tournament'
                            : 'Next',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNext() async {
    // Validate current step
    if (_currentStep == 0) {
      // Sport selection - always valid
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      // Facility selection
      if (_selectedFacilityId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a facility'),
            backgroundColor: AppTheme.errorRed,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Court selection happens during time selection (step 3), not here
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      // Format selection - always valid
      setState(() => _currentStep++);
    } else if (_currentStep == 3) {
      // Date & Time validation
      if (_selectedRegistrationDeadline.isAfter(
        _selectedStartDate.subtract(const Duration(days: 1)),
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration deadline must be at least 1 day before tournament start',
            ),
            backgroundColor: AppTheme.errorRed,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Check if court is selected (for facilities with subUnits)
      if (_selectedFacilityId != null) {
        final bookingService = ref.read(bookingServiceProvider);
        final facility = await bookingService.getFacilityById(
          _selectedFacilityId!,
        );
        if (!mounted || !context.mounted) return;
        if (facility != null && facility.hasSubUnits) {
          if (_selectedCourt == null || _selectedCourt!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please select a court first to see available time slots',
                ),
                backgroundColor: AppTheme.errorRed,
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
        }
      }

      // Check if time range is selected (from timeline or time slot)
      if (_timelineStartTime == null || _timelineEndTime == null) {
        if (_selectedTimeSlot == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a time range on the timeline'),
              backgroundColor: AppTheme.errorRed,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }

      setState(() => _currentStep++);
    } else if (_currentStep == 4) {
      // Final step - create tournament
      if (_formKey.currentState!.validate()) {
        _handleCreateTournament();
      }
    }
  }

  Future<void> _handleCreateTournament() async {
    if (_selectedFacilityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a facility'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Get facility
      final bookingService = ref.read(bookingServiceProvider);
      final facility = await bookingService.getFacilityById(
        _selectedFacilityId!,
      );

      if (facility == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Facility not found'),
              backgroundColor: AppTheme.errorRed,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Validate court selection for facilities with subUnits
      if (facility.hasSubUnits &&
          (_selectedCourt == null || _selectedCourt!.isEmpty)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a court for this facility'),
              backgroundColor: AppTheme.errorRed,
              duration: Duration(seconds: 2),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Use timeline selection or fallback to time slot
      DateTime facilityStartTime;
      DateTime facilityEndTime;

      if (_timelineStartTime != null && _timelineEndTime != null) {
        // Use timeline selection
        facilityStartTime = _timelineStartTime!;
        facilityEndTime = _timelineEndTime!;
      } else if (_selectedTimeSlot != null) {
        // Fallback to time slot selection
        facilityStartTime = _selectedTimeSlot!.startTime;
        facilityEndTime = facilityStartTime.add(
          Duration(hours: _selectedDurationHours),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a time range on the timeline'),
              backgroundColor: AppTheme.errorRed,
              duration: Duration(seconds: 2),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Validate that the entire range is still available by checking all slots in range
      final rangeSlots = await bookingService.getAvailableSlots(
        facilityId: _selectedFacilityId!,
        date: _selectedStartDate,
        subUnit: _selectedCourt,
      );

      // Check if all slots in the range are available
      final slotDuration = facility.type == FacilityType.session ? 2 : 1;
      final rangeSlotTimes = <DateTime>[];
      DateTime currentTime = facilityStartTime;
      while (currentTime.isBefore(facilityEndTime)) {
        rangeSlotTimes.add(currentTime);
        currentTime = currentTime.add(Duration(hours: slotDuration));
      }

      final isRangeAvailable = rangeSlotTimes.every((slotTime) {
        final slot = rangeSlots.firstWhere(
          (s) => s.startTime == slotTime,
          orElse:
              () => dt.TimeSlot(
                startTime: slotTime,
                endTime: slotTime.add(Duration(hours: slotDuration)),
                label: DateTimeUtils.formatTime(slotTime),
                isAvailable: false,
              ),
        );
        return slot.isAvailable;
      });

      if (!isRangeAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Selected time range is no longer available. Please choose another time.',
              ),
              backgroundColor: AppTheme.errorRed,
              duration: Duration(seconds: 2),
            ),
          );
        }
        setState(() {
          _isLoading = false;
          _selectedTimeSlot = null;
        });
        return;
      }

      // Create tournament - service will handle booking creation automatically
      final tournamentService = ref.read(tournamentServiceProvider);
      final result = await tournamentService.createTournament(
        title: _titleController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        sport: _selectedSport,
        organizer: user,
        format: _selectedFormat,
        maxTeams: _selectedFormat.teamCount,
        entryFee: _entryFee,
        firstPlacePrize: _firstPlacePrize,
        organizerFee: _organizerFee,
        isStudentOnly: _isStudentOnly,
        registrationDeadline: _selectedRegistrationDeadline,
        startDate: _selectedStartDate,
        matchDuration: const Duration(hours: 2), // Default 2 hours per match
        facility: facility,
        facilityStartTime: facilityStartTime,
        facilityEndTime: facilityEndTime,
        subUnit:
            _selectedCourt, // Pass court selection for facilities with subUnits (e.g., badminton)
        autoCreateBooking: true, // Service will create booking with subUnit
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result.success && result.tournament != null) {
        // Invalidate providers to refresh tournament lists
        ref.invalidate(publicTournamentsProvider);
        ref.invalidate(userTournamentsProvider);

        _showTournamentCreatedToast(context, result.tournament!.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to create tournament'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showTournamentCreatedToast(BuildContext context, String tournamentId) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 24 * (1 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tournament Created!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Share the code so others can join',
                              style: TextStyle(
                                color: Colors.white70,
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
            ),
          ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Auto-dismiss after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      overlayEntry?.remove();
      overlayEntry = null;
    });

    // Navigate after short delay so toast is visible on the next screen too
    Future.delayed(const Duration(milliseconds: 600), () {
      if (context.mounted) {
        context.push('/tournament/$tournamentId');
      }
    });
  }
}
