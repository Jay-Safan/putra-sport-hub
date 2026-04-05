import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../../../core/constants/app_constants.dart';
import '../../../../../../../../../core/widgets/sport_icon.dart';

import '../../../../../../../../../core/widgets/shimmer_loading.dart';
import '../../../../../../../../../core/widgets/animations.dart';
import '../../../../../../../../../core/utils/error_handler.dart';
import '../../../../../../../../../providers/providers.dart';
import '../../data/models/booking_model.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isStudent = user?.isStudent ?? false;

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton:
          isStudent
              ? FloatingActionButton.extended(
                onPressed: () => context.push('/booking/join'),
                backgroundColor: AppTheme.primaryGreen,
                icon: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  'Join Booking',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              )
              : null,
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
        child: Stack(
          children: [
            // Background orbs - ignore pointer events
            IgnorePointer(child: _buildBackgroundOrbs()),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader()
                      .animate()
                      .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                      .slideY(begin: -0.1, end: 0, duration: 500.ms),
                  _buildTabBar()
                      .animate()
                      .fadeIn(
                        duration: 500.ms,
                        delay: 100.ms,
                        curve: Curves.easeOut,
                      )
                      .slideY(begin: 0.05, end: 0, duration: 500.ms),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildUpcomingBookings(),
                        _buildPastBookings(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryGreen.withValues(alpha: 0.25),
                      AppTheme.primaryGreen.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 4000.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(duration: 1000.ms),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.futsalBlue.withValues(alpha: 0.15),
                      AppTheme.futsalBlue.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 5000.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(duration: 1200.ms, delay: 200.ms),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppTheme.primaryGreen,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Bookings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage your reservations',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [Tab(text: 'Upcoming'), Tab(text: 'History')],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingBookings() {
    final bookingsAsync = ref.watch(userBookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        final upcoming =
            bookings
                .where(
                  (b) =>
                      b.startTime.isAfter(DateTime.now()) &&
                      (b.status == BookingStatus.confirmed ||
                          b.status == BookingStatus.pendingPayment),
                )
                .toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));

        if (upcoming.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userBookingsProvider);
            },
            color: AppTheme.primaryGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: _buildEmptyState(
                  icon: Icons.event_available,
                  title: 'No Upcoming Bookings 📅',
                  subtitle:
                      'Ready to play? Book a facility now and start your sports journey!',
                  actionLabel: 'Book Now',
                  onAction: () => context.go('/home'),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userBookingsProvider);
          },
          color: AppTheme.primaryGreen,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: upcoming.length,
            itemBuilder:
                (context, index) =>
                    _buildBookingCard(upcoming[index], isUpcoming: true)
                        .animate()
                        .fadeIn(
                          duration: 400.ms,
                          delay: (index * 50).ms,
                          curve: Curves.easeOut,
                        )
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 400.ms,
                          delay: (index * 50).ms,
                          curve: Curves.easeOut,
                        ),
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error:
          (e, _) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userBookingsProvider);
            },
            color: AppTheme.primaryGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: _buildErrorState(
                  ErrorHandler.getUserFriendlyErrorMessage(
                    e,
                    context: 'booking',
                    defaultMessage:
                        'Unable to load bookings. Please try again.',
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildPastBookings() {
    final bookingsAsync = ref.watch(userBookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        final past =
            bookings
                .where(
                  (b) =>
                      b.startTime.isBefore(DateTime.now()) ||
                      b.status == BookingStatus.completed ||
                      b.status == BookingStatus.cancelled,
                )
                .toList()
              ..sort((a, b) => b.startTime.compareTo(a.startTime));

        if (past.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userBookingsProvider);
            },
            color: AppTheme.primaryGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: _buildEmptyState(
                  icon: Icons.history,
                  title: 'No Past Bookings 📜',
                  subtitle:
                      'Your completed and cancelled bookings will appear here once you start booking facilities.',
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userBookingsProvider);
          },
          color: AppTheme.primaryGreen,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: past.length,
            itemBuilder:
                (context, index) =>
                    _buildBookingCard(past[index], isUpcoming: false)
                        .animate()
                        .fadeIn(
                          duration: 400.ms,
                          delay: (index * 50).ms,
                          curve: Curves.easeOut,
                        )
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 400.ms,
                          delay: (index * 50).ms,
                          curve: Curves.easeOut,
                        ),
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error:
          (e, _) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userBookingsProvider);
            },
            color: AppTheme.primaryGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: _buildErrorState(
                  ErrorHandler.getUserFriendlyErrorMessage(
                    e,
                    context: 'booking',
                    defaultMessage:
                        'Unable to load bookings. Please try again.',
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildBookingCard(BookingModel booking, {required bool isUpcoming}) {
    final sportColor = _getSportColor(booking.facilityId);
    final statusColor = _getStatusColor(booking.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/booking/${booking.id}'),
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
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
                  border: Border.all(
                    color:
                        isUpcoming
                            ? sportColor.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    // Header with sport icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            sportColor.withValues(alpha: 0.2),
                            sportColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: sportColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SportIcon(
                              sport: booking.sport,
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
                                  booking.facilityName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (booking.subUnit != null) ...[
                                  Text(
                                    booking.subUnit!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _buildStatusBadge(booking.status, statusColor),
                        ],
                      ),
                    ),

                    // Details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            Icons.calendar_today_outlined,
                            'Date',
                            DateFormat(
                              'EEEE, d MMM yyyy',
                            ).format(booking.startTime),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.access_time_outlined,
                            'Time',
                            '${DateFormat('h:mm a').format(booking.startTime)} - ${DateFormat('h:mm a').format(booking.endTime)}',
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.payments_outlined,
                            'Amount',
                            'RM ${booking.totalAmount.toStringAsFixed(2)}',
                            valueColor: AppTheme.successGreen,
                          ),
                          // Weather warnings would be shown here if available
                        ],
                      ),
                    ),

                    // Actions for upcoming bookings
                    if (isUpcoming && booking.status == BookingStatus.confirmed)
                      _buildActions(booking),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push('/booking/${booking.id}'),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('View Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 48,
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 20),
          Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms, curve: Curves.easeOut)
              .slideY(begin: 0.1, end: 0, duration: 500.ms),
          const SizedBox(height: 8),
          Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 300.ms, curve: Curves.easeOut)
              .slideY(begin: 0.1, end: 0, duration: 500.ms),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            AnimatedPressableButton(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.primaryGreenLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 400.ms, curve: Curves.easeOut)
                .slideY(begin: 0.1, end: 0, duration: 500.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      physics: const BouncingScrollPhysics(),
      itemCount: 3, // Show 3 shimmer cards
      itemBuilder:
          (context, index) => TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 200)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: const ShimmerBookingTicket(),
          ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load bookings',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSportColor(String facilityId) {
    if (facilityId.contains('football')) {
      return AppTheme.getSportColor('FOOTBALL');
    }
    if (facilityId.contains('futsal')) return AppTheme.getSportColor('FUTSAL');
    if (facilityId.contains('badminton')) {
      return AppTheme.getSportColor('BADMINTON');
    }
    if (facilityId.contains('tennis')) return AppTheme.getSportColor('TENNIS');
    return AppTheme.primaryGreen;
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return AppTheme.successGreen;
      case BookingStatus.pendingPayment:
        return AppTheme.warningAmber;
      case BookingStatus.completed:
        return AppTheme.futsalBlue;
      case BookingStatus.cancelled:
      case BookingStatus.refunded:
        return AppTheme.errorRed;
      case BookingStatus.inProgress:
        return AppTheme.infoBlue;
    }
  }
}
