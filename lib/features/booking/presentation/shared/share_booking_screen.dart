import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../../../core/widgets/sport_icon.dart';
import '../../../../../../../../../core/widgets/split_bill_status_chip.dart';
import '../../data/models/booking_model.dart';
import '../../../../../../../../../providers/providers.dart';

/// Share Booking Screen
/// Allows organizers to share split bill booking details via WhatsApp, Email, and QR code
class ShareBookingScreen extends ConsumerWidget {
  final String bookingId;

  const ShareBookingScreen({required this.bookingId, super.key});

  String _buildShareText(BookingModel booking) {
    final dateFormatter = DateFormat('MMM d, yyyy').format(booking.bookingDate);
    final timeFormatter = DateFormat('h:mm a').format(booking.startTime);
    final endTimeFormatter = DateFormat('h:mm a').format(booking.endTime);
    
    final paidCount = booking.splitBillParticipants.where((p) => p.hasPaid).length;
    final totalCount = booking.splitBillParticipants.length;

    return '''${booking.isStudentBooking ? '🎓' : '🏢'} ${booking.facilityName} Booking

📅 $dateFormatter | ⏰ $timeFormatter - $endTimeFormatter
📍 ${booking.facilityName}
🎯 ${booking.sport.displayName}
${booking.subUnit != null ? '🏟️ ${booking.subUnit}\n' : ''}
💰 Total: RM ${booking.totalAmount.toStringAsFixed(2)}
👥 Split among $totalCount ${totalCount == 1 ? 'person' : 'people'} (RM ${(booking.totalAmount / totalCount).toStringAsFixed(2)} per person)
✅ $paidCount/$totalCount ${paidCount == 1 ? 'has' : 'have'} paid

🔗 Team Code: ${booking.teamCode ?? 'N/A'}

Join this booking via PutraSportHub!
Scan the QR code or enter the team code to join and pay your share.''';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));

    return Scaffold(
      backgroundColor: const Color(0xFF0A1F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Share Booking',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: bookingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading booking: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (booking) {
          if (booking == null) {
            return const Center(
              child: Text(
                'Booking not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (!booking.isSplitBill) {
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
                  const Text(
                    'This booking does not support split bill',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Hero QR Code Section
                  _buildEnhancedQrSection(context, booking),
                  const SizedBox(height: 32),

                  // Booking Preview Card
                  _buildEnhancedBookingCard(booking),
                  const SizedBox(height: 24),

                  // Team Code Section
                  _buildEnhancedShareCodeSection(context, booking),
                  const SizedBox(height: 24),

                  // Participant Status
                  if (booking.splitBillParticipants.isNotEmpty) ...[
                    SplitBillStatusChip(
                      booking: booking,
                      showProgress: true,
                      compact: false,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Quick Share Actions
                  _buildEnhancedShareButtons(context, booking),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedQrSection(
    BuildContext context,
    BookingModel booking,
  ) {
    final sportColor = AppTheme.getSportColorFromType(booking.sport);
    final teamCode = booking.teamCode ?? '';

    return Column(
      children: [
        // QR Code Container with Glassmorphism
        GestureDetector(
          onTap: () => _showFullscreenQR(context, teamCode),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      sportColor.withValues(alpha: 0.2),
                      sportColor.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: sportColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: sportColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // QR Code
                    Container(
                      width: 280,
                      height: 280,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        size: const Size(248, 248),
                        painter: QrPainter(
                          data: teamCode,
                          version: QrVersions.auto,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: sportColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tap to enlarge',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Scan QR code to join and pay your share',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showFullscreenQR(BuildContext context, String teamCode) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: CustomPaint(
                size: const Size(300, 300),
                painter: QrPainter(
                  data: teamCode,
                  version: QrVersions.auto,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBookingCard(BookingModel booking) {
    final sportColor = AppTheme.getSportColorFromType(booking.sport);
    final paidCount = booking.splitBillParticipants.where((p) => p.hasPaid).length;
    final totalCount = booking.splitBillParticipants.length;
    final perPerson = totalCount > 0 ? booking.totalAmount / totalCount : booking.totalAmount;

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          sportColor,
                          sportColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SportIcon(
                      sport: booking.sport,
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
                          booking.facilityName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.sport.displayName,
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
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildInfoChip(
                    icon: Icons.calendar_today,
                    label: DateFormat('MMM d, yyyy').format(booking.bookingDate),
                    color: AppTheme.accentGold,
                  ),
                  _buildInfoChip(
                    icon: Icons.access_time,
                    label: '${DateFormat('h:mm a').format(booking.startTime)} - ${DateFormat('h:mm a').format(booking.endTime)}',
                    color: AppTheme.successGreen,
                  ),
                  if (booking.subUnit != null)
                    _buildInfoChip(
                      icon: Icons.place,
                      label: booking.subUnit!,
                      color: AppTheme.futsalBlue,
                    ),
                  _buildInfoChip(
                    icon: Icons.payment,
                    label: 'RM ${perPerson.toStringAsFixed(2)}/person',
                    color: AppTheme.badmintonPurple,
                  ),
                  _buildInfoChip(
                    icon: Icons.group,
                    label: '$paidCount/$totalCount paid',
                    color: paidCount == totalCount ? AppTheme.successGreen : AppTheme.warningAmber,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedShareCodeSection(
    BuildContext context,
    BookingModel booking,
  ) {
    final teamCode = booking.teamCode ?? 'N/A';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.futsalBlue.withValues(alpha: 0.15),
                AppTheme.futsalBlue.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.futsalBlue.withValues(alpha: 0.3),
              width: 1.5,
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
                      color: AppTheme.futsalBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tag,
                      color: AppTheme.futsalBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team Code',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Share this code with friends',
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
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: teamCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Team code copied to clipboard!'),
                        ],
                      ),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.futsalBlue.withValues(alpha: 0.3),
                        AppTheme.futsalBlue.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.futsalBlue.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        teamCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.content_copy,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tap to copy',
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
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/booking/join?code=$teamCode');
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Join via Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.futsalBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildEnhancedShareButtons(
    BuildContext context,
    BookingModel booking,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Share via',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            _buildEnhancedShareButton(
              icon: Icons.message,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              onPressed: () => _shareViaWhatsApp(booking),
            ),
            _buildEnhancedShareButton(
              icon: Icons.email,
              label: 'Email',
              color: AppTheme.futsalBlue,
              onPressed: () => _shareViaEmail(booking),
            ),
            _buildEnhancedShareButton(
              icon: Icons.content_copy,
              label: 'Copy',
              color: AppTheme.accentGold,
              onPressed: () => _copyShareText(booking),
            ),
            _buildEnhancedShareButton(
              icon: Icons.share,
              label: 'More',
              color: AppTheme.primaryGreen,
              onPressed: () => Share.share(_buildShareText(booking)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareViaWhatsApp(BookingModel booking) {
    final text = _buildShareText(booking);
    Share.share(text, subject: '${booking.facilityName} Booking Invitation');
  }

  void _shareViaEmail(BookingModel booking) {
    final text = _buildShareText(booking);
    Share.share(text, subject: '${booking.facilityName} Booking Invitation');
  }

  void _copyShareText(BookingModel booking) {
    final text = _buildShareText(booking);
    Clipboard.setData(ClipboardData(text: text));
  }
}

