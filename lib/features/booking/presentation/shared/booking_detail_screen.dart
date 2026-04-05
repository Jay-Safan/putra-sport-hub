import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../../../core/constants/app_constants.dart';
import '../../../../../../../../../core/widgets/sport_icon.dart';
import '../../../../../../../../../core/config/api_keys.dart';
import '../../../../../../../../../core/widgets/booking_ticket_card.dart';
import '../../../../../../../../../core/widgets/avatar_widget.dart';
import '../../../../../../../../../providers/providers.dart';
import '../../data/models/booking_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../referee/data/models/referee_job_model.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  /// Check if booking is past (historical record)
  static bool _isPastBooking(BookingModel booking) {
    final now = DateTime.now();
    return booking.startTime.isBefore(now) ||
        booking.status == BookingStatus.completed ||
        booking.status == BookingStatus.cancelled;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: bookingAsync.maybeWhen(
          data:
              (booking) => Text(
                booking?.facilityName ?? 'Booking Details',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          orElse:
              () => const Text(
                'Booking Details',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
        centerTitle: true,
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
          child: bookingAsync.when(
            data: (booking) {
              if (booking == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Booking not found',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Back to Home'),
                      ),
                    ],
                  ),
                );
              }

              final isPast = _isPastBooking(booking);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  children: [
                    // Booking Ticket Card
                    BookingTicketCard(booking: booking, isExpanded: true),
                    const SizedBox(height: 28),

                    // Referee Status Section (for normal bookings with referee job)
                    if (booking.refereeJobId != null)
                      _buildRefereeStatusSection(
                        context,
                        ref,
                        booking.refereeJobId!,
                      ),

                    // Past Booking Summary (only for past bookings)
                    if (isPast) ...[
                      _buildPastBookingSummary(context, booking),
                      const SizedBox(height: 24),
                    ],

                    // Tournament Info for Match bookings
                    if (booking.bookingType == BookingType.match &&
                        booking.tournamentFormat != null) ...[
                      const SizedBox(height: 28),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.upmRed.withValues(alpha: 0.2),
                                  AppTheme.upmRed.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.upmRed.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.emoji_events,
                                      color: AppTheme.upmRed,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        'Tournament: ${booking.tournamentFormat!.displayName}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Teams: ${booking.tournamentTeams ?? 0}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Location Map Section
                    _buildLocationMapSection(context, ref, booking),
                  ],
                ),
              );
            },
            loading:
                () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            error:
                (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading booking',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Back to Home'),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildPastBookingSummary(BuildContext context, BookingModel booking) {
    final statusText =
        booking.status == BookingStatus.completed
            ? 'Completed'
            : booking.status == BookingStatus.cancelled
            ? 'Cancelled'
            : 'Past Booking';

    final statusColor =
        booking.status == BookingStatus.completed
            ? AppTheme.successGreen
            : booking.status == BookingStatus.cancelled
            ? AppTheme.errorRed
            : Colors.grey;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                statusColor.withValues(alpha: 0.15),
                statusColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      booking.status == BookingStatus.completed
                          ? Icons.check_circle_outline
                          : booking.status == BookingStatus.cancelled
                          ? Icons.cancel_outlined
                          : Icons.history,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This booking has ended',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Booking Summary Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Total Amount',
                      'RM ${booking.totalAmount.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Date', _formatDate(booking.startTime)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildRefereeStatusSection(
    BuildContext context,
    WidgetRef ref,
    String refereeJobId,
  ) {
    final refereeJobAsync = ref.watch(refereeJobByIdProvider(refereeJobId));

    return refereeJobAsync.when(
      data: (refereeJob) {
        if (refereeJob == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentGold.withValues(alpha: 0.15),
                      AppTheme.accentGold.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
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
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Referee Status',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    refereeJob.assignmentStatusText,
                                    style: TextStyle(
                                      color: _getRefereeStatusColor(
                                        refereeJob.status,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (refereeJob.refereesRequired > 1) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Assignment: ${refereeJob.assignmentProgress}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Show assigned referee profile whenever there are assigned referees
                    // Displays immediately when referee(s) accept, even for partial assignments
                    if (refereeJob.assignedReferees.isNotEmpty)
                      _buildAssignedRefereeProfile(context, ref, refereeJob),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildRefereeInfoRow(
                            'Referee Assignment',
                            refereeJob.assignmentProgress,
                          ),
                          if (refereeJob.isPartiallyAssigned) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.warningAmber.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.warningAmber.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppTheme.warningAmber,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Partial referee coverage - session can proceed',
                                    style: TextStyle(
                                      color: AppTheme.warningAmber,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildRefereeInfoRow(
                            'Earnings per Referee',
                            'RM ${refereeJob.earnings.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAssignedRefereeProfile(
    BuildContext context,
    WidgetRef ref,
    RefereeJobModel refereeJob,
  ) {
    // For normal bookings, assume one referee (first assigned referee)
    final assignedReferee = refereeJob.assignedReferees.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FutureBuilder<UserModel?>(
        future: ref
            .read(authServiceProvider)
            .getUserModel(assignedReferee.userId),
        builder: (context, snapshot) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.successGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Referee Avatar - real profile photo or fallback
                AvatarWidget.fromUser(
                  user: snapshot.data,
                  radius: 20,
                  backgroundColor: AppTheme.successGreen.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 12),
                // Referee Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned Referee',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        assignedReferee.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (assignedReferee.role != RefereeRole.solo)
                        Text(
                          assignedReferee.role.displayName,
                          style: TextStyle(
                            color: AppTheme.successGreen.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status indicator
                if (assignedReferee.hasCheckedIn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Checked In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRefereeInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getRefereeStatusText(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return 'Looking for referees';
      case JobStatus.assigned:
        return 'Referees assigned';
      case JobStatus.completed:
        return 'Match completed';
      case JobStatus.paid:
        return 'Payment completed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getRefereeStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return Colors.orange;
      case JobStatus.assigned:
        return AppTheme.successGreen;
      case JobStatus.completed:
        return AppTheme.accentGold;
      case JobStatus.paid:
        return AppTheme.successGreen;
      case JobStatus.cancelled:
        return AppTheme.errorRed;
    }
  }

  Widget _buildLocationMapSection(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
  ) {
    final facilityAsync = ref.watch(facilityProvider(booking.facilityId));

    return facilityAsync.when(
      data: (facility) {
        if (facility == null) {
          return const SizedBox.shrink();
        }

        // Get location from facility data or use hardcoded coordinates
        final locationData =
            facility.location != null
                ? {
                  'latitude': facility.location!.latitude,
                  'longitude': facility.location!.longitude,
                }
                : AppConstants.getFacilityLocation(booking.facilityId);

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryGreen.withValues(alpha: 0.3),
                                  AppTheme.primaryGreenLight.withValues(
                                    alpha: 0.2,
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppTheme.primaryGreenLight,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Facility Location',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  facility.name,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Sport and Court info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getSportColor(
                                facility.sport,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getSportColor(
                                  facility.sport,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SportIcon(
                                  sport: facility.sport,
                                  size: 14,
                                  color: _getSportColor(facility.sport),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  facility.sport.displayName,
                                  style: TextStyle(
                                    color: _getSportColor(facility.sport),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (booking.subUnit != null) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.place,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    booking.subUnit!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Map Preview with Google Maps Static
                    Container(
                      height: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildGoogleStaticMap(
                          context,
                          GeoPoint(
                            locationData['latitude']!,
                            locationData['longitude']!,
                          ),
                          facility.sport,
                          hasLocation: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Get Directions Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              () => _openMaps(
                                context,
                                GeoPoint(
                                  locationData['latitude']!,
                                  locationData['longitude']!,
                                ),
                              ),
                          icon: const Icon(Icons.directions_rounded, size: 20),
                          label: const Text('Get Directions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
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
      },
      loading:
          () => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      error:
          (error, _) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Unable to load location',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Future<void> _openMaps(BuildContext context, GeoPoint location) async {
    final lat = location.latitude;
    final lng = location.longitude;

    // Try multiple URL schemes for better compatibility
    // 1. Android intent URL (works on Android, opens app or browser)
    final androidIntentUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng');

    // 2. Google Maps web URL (fallback that always works)
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    try {
      // First, try Android intent URL (works better on Android devices/emulators)
      if (await canLaunchUrl(androidIntentUrl)) {
        await launchUrl(androidIntentUrl, mode: LaunchMode.externalApplication);
      }
      // Fallback to Google Maps web URL (works in browser)
      else if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.platformDefault, // Opens in browser on emulator
        );
      }
      // Last resort: try web URL directly
      else {
        await launchUrl(googleMapsUrl, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      // If all methods fail, show helpful error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open maps. Try copying coordinates: $lat, $lng',
            ),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('❌ Error opening maps: $e');
    }
  }

  Color _getSportColor(SportType sport) {
    return AppTheme.getSportColorFromType(sport);
  }

  Widget _buildGoogleStaticMap(
    BuildContext context,
    GeoPoint location,
    SportType sport, {
    bool hasLocation = true,
  }) {
    final lat = location.latitude;
    final lng = location.longitude;

    // Safe API key access with fallback
    String apiKey;
    try {
      apiKey = ApiKeys.googleMapsStatic;
      if (apiKey.isEmpty) {
        // No API key - show placeholder instead
        return _buildMapPlaceholder(sport);
      }
    } catch (e) {
      // Error accessing API key - show placeholder
      return _buildMapPlaceholder(sport);
    }

    // Generate Google Maps Static API URL
    // URL encoding for marker color (0xFF2E8B57 = green)
    const markerColor = '0x2E8B57'; // Removed the FF prefix for URL
    final mapUrl =
        'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng'
        '&zoom=${hasLocation ? 17 : 15}' // Slightly wider zoom if using fallback location
        '&size=400x200'
        '&scale=2' // For retina displays
        '&markers=color:$markerColor%7C$lat,$lng' // Green marker
        '&style=feature:poi|visibility:off' // Hide points of interest
        '&style=feature:transit|visibility:off' // Hide transit
        '&key=$apiKey';

    return Stack(
      children: [
        // Google Maps Static Image
        CachedNetworkImage(
          imageUrl: mapUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildMapPlaceholder(sport),
          errorWidget: (context, url, error) {
            // Log error for debugging
            debugPrint('❌ Google Maps Static API Error: $error');
            debugPrint('URL: $url');
            return _buildMapPlaceholder(sport);
          },
          fadeInDuration: const Duration(milliseconds: 300),
        ),
        // Show indicator if using fallback location
        if (!hasLocation)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'UPM Area',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        // Subtle overlay gradient at bottom for better text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder(SportType sport) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getSportColor(sport).withValues(alpha: 0.2),
            _getSportColor(sport).withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_rounded,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Location Available',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Location marker overlay
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Countdown timer widget for booking expiration
