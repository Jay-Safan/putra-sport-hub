import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/sport_icon.dart';
import '../../features/booking/data/models/booking_model.dart';

/// A beautiful 3D ticket card for displaying booking details
/// Features: Perforated edge, QR code with glow, glassmorphism
class BookingTicketCard extends StatefulWidget {
  final BookingModel booking;
  final VoidCallback? onAddToCalendar;
  final VoidCallback? onShare;
  final VoidCallback? onCancel;
  final bool isExpanded;

  const BookingTicketCard({
    super.key,
    required this.booking,
    this.onAddToCalendar,
    this.onShare,
    this.onCancel,
    this.isExpanded = false,
  });

  @override
  State<BookingTicketCard> createState() => _BookingTicketCardState();
}

class _BookingTicketCardState extends State<BookingTicketCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Always start with QR code collapsed for better UX
    _isExpanded = false;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        setState(() => _isExpanded = !_isExpanded);
        HapticFeedback.lightImpact();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: Stack(
            children: [
              // Main ticket body
              _buildTicketBody(),
              // Perforated line - positioned based on content height
              Positioned(
                left: 0,
                right: 0,
                top: _calculatePerforatedLinePosition(),
                child: _buildPerforatedLine(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketBody() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _getSportColor().withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top section - Booking info
              _buildTopSection(),
              // Bottom section - QR code (expandable)
              AnimatedCrossFade(
                firstChild: _buildCollapsedBottom(),
                secondChild: _buildExpandedBottom(),
                crossFadeState:
                    _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with sport badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: _getSportGradient(),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _getSportColor().withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SportIcon(
                  sport: widget.booking.sport,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.booking.sport.displayName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.booking.facilityName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 20),

          // Booking ID and Reference
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  'Booking ID: ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.booking.id.length > 8
                        ? '${widget.booking.id.substring(0, 8).toUpperCase()}...'
                        : widget.booking.id.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Date and Duration row
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'DATE',
                  value: _formatDate(widget.booking.startTime),
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.access_time_rounded,
                  label: 'DURATION',
                  value: _formatDuration(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Start and End time chips
          Row(
            children: [
              Expanded(
                child: _buildDetailChip(
                  icon: Icons.schedule_outlined,
                  label: 'Start Time',
                  value: _formatTime(widget.booking.startTime),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailChip(
                  icon: Icons.schedule_outlined,
                  label: 'End Time',
                  value: _formatTime(widget.booking.endTime),
                ),
              ),
            ],
          ),

          // Price information
          if (widget.booking.totalAmount > 0) ...[
            const SizedBox(height: 14),
            _buildDetailChip(
              icon: Icons.payments_outlined,
              label: 'Total Amount',
              value: 'RM ${widget.booking.totalAmount.toStringAsFixed(2)}',
              isHighlighted: true,
            ),
          ],

          // Court/Sub-unit information
          if (widget.booking.subUnit != null) ...[
            const SizedBox(height: 14),
            _buildInfoChip(
              icon: Icons.location_on_outlined,
              text: widget.booking.subUnit!,
            ),
          ],

          // Booking type and additional info
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSmallChip(
                icon: Icons.sports_outlined,
                text: widget.booking.bookingType?.displayName ?? 'Practice',
              ),
              if (widget.booking.refereeJobId != null)
                _buildSmallChip(
                  icon: Icons.sports_soccer_outlined,
                  text: 'Referee Assigned',
                  color: AppTheme.successGreen,
                ),
              if (widget.booking.tournamentFormat != null)
                _buildSmallChip(
                  icon: Icons.emoji_events_outlined,
                  text: widget.booking.tournamentFormat!.displayName,
                  color: AppTheme.upmRed,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedBottom() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
      decoration: BoxDecoration(
        // Add subtle gradient to match glassmorphic theme
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.white.withValues(alpha: 0.03)],
        ),
      ),
      child: Row(
        children: [
          // Mini QR preview - styled to match dark theme
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getSportColor().withValues(alpha: 0.2),
                  _getSportColor().withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _getSportColor().withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle QR icon
                Icon(
                  Icons.qr_code_2_outlined,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 28,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap to show QR code',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan at venue to check-in',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white.withValues(alpha: 0.6),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedBottom() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: [
          // QR Code with glow
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _getSportColor().withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: QrImageView(
              data: widget.booking.qrCode ?? widget.booking.id,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: _getSportColor(),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF1A3D32),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Scan this code at the venue',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.calendar_month_outlined,
                  label: 'Add to Calendar',
                  onTap: widget.onAddToCalendar,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: widget.onShare,
                ),
              ),
            ],
          ),
          if (widget.booking.status == BookingStatus.confirmed &&
              widget.onCancel != null) ...[
            const SizedBox(height: 14),
            _buildCancelButton(),
          ],
          const SizedBox(height: 12),
          Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Colors.white.withValues(alpha: 0.6),
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildPerforatedLine() {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color:
                  index.isEven
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    IconData icon;

    switch (widget.booking.status) {
      case BookingStatus.confirmed:
        color = AppTheme.successGreen;
        text = 'CONFIRMED';
        icon = Icons.check_circle;
        break;
      case BookingStatus.pendingPayment:
        color = AppTheme.warningAmber;
        text = 'PENDING';
        icon = Icons.pending;
        break;
      case BookingStatus.completed:
        color = AppTheme.primaryGreen;
        text = 'COMPLETED';
        icon = Icons.done_all;
        break;
      case BookingStatus.cancelled:
        color = AppTheme.errorRed;
        text = 'CANCELLED';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = 'UNKNOWN';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onCancel?.call();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.35)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, color: AppTheme.errorRed, size: 20),
            SizedBox(width: 10),
            Text(
              'Cancel Booking',
              style: TextStyle(
                color: AppTheme.errorRed,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSportColor() {
    return AppTheme.getSportColorFromType(widget.booking.sport);
  }

  LinearGradient _getSportGradient() {
    switch (widget.booking.sport) {
      case SportType.football:
        return AppTheme.footballGradient;
      case SportType.futsal:
        return AppTheme.futsalGradient;
      case SportType.badminton:
        return AppTheme.badmintonGradient;
      case SportType.tennis:
        return AppTheme.tennisGradient;
    }
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            isHighlighted
                ? _getSportColor().withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isHighlighted
                  ? _getSportColor().withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isHighlighted
                        ? _getSportColor()
                        : Colors.white.withValues(alpha: 0.7),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: isHighlighted ? _getSportColor() : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallChip({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    final chipColor = color ?? Colors.white.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: chipColor, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: chipColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration() {
    final duration = widget.booking.endTime.difference(
      widget.booking.startTime,
    );
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
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
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  double _calculatePerforatedLinePosition() {
    // Calculate position to place line between the tags and QR code section
    // Top section padding: 24 (top)
    // Header row height: ~66px (icon + text with improved spacing)
    // Spacing after header: 20
    // Booking ID section: ~40px
    // Spacing: 16
    // Date/Duration row height: ~50px
    // Spacing: 16
    // Start/End time chips: ~40px
    // Price section (if present): 14 + ~40px
    // SubUnit section (if present): 14 + ~40px
    // Context tags section: 14 + ~30px
    // Bottom padding of top section: 24

    final hasSubUnit = widget.booking.subUnit != null;
    final hasPrice = widget.booking.totalAmount > 0;

    // Base height: top padding + header + spacing + booking ID + spacing
    double baseHeight = 24.0 + 66.0 + 20.0 + 40.0 + 16.0;

    // Add date/duration row + spacing
    baseHeight += 50.0 + 16.0;

    // Add time chips row
    baseHeight += 40.0;

    // Add price section if present
    if (hasPrice) {
      baseHeight += 14.0 + 40.0; // spacing + chip height
    }

    // Add subUnit height if it exists
    if (hasSubUnit) {
      baseHeight += 14.0 + 40.0; // spacing + chip height
    }

    // Add context tags section
    baseHeight += 14.0 + 30.0; // spacing + tags height

    // Add extra spacing to position line with equal spacing above and below
    baseHeight += 65.0; // increased spacing after tags for equal visual balance

    // Position line right between tags and QR section
    return baseHeight;
  }
}
