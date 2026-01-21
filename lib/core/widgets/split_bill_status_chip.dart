import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../features/booking/data/models/booking_model.dart';

/// Unified Split Bill Status Chip Component
/// Premium minimalist design with smooth animations
class SplitBillStatusChip extends StatefulWidget {
  final BookingModel booking;
  final bool showProgress;
  final bool compact;
  final bool showShareButton;
  final bool isExpanded;

  const SplitBillStatusChip({
    super.key,
    required this.booking,
    this.showProgress = true,
    this.compact = false,
    this.showShareButton = false,
    this.isExpanded = false,
  });

  @override
  State<SplitBillStatusChip> createState() => _SplitBillStatusChipState();
}

class _SplitBillStatusChipState extends State<SplitBillStatusChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.booking.isSplitBill) {
      return const SizedBox.shrink();
    }

    final paidCount =
        widget.booking.splitBillParticipants.where((p) => p.hasPaid).length;
    final totalCount = widget.booking.splitBillParticipants.length;
    final allPaid = paidCount == totalCount && totalCount > 0;
    final status = widget.booking.splitBillStatus;

    final color = allPaid ? AppTheme.successGreen : AppTheme.warningAmber;
    final icon = allPaid ? Icons.check_circle_rounded : Icons.pending_actions_rounded;
    final label = _getStatusLabel(status, paidCount, totalCount, allPaid);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.isExpanded
            ? _buildExpandedChip(context, color, icon, label, paidCount, totalCount, allPaid)
            : widget.compact
                ? _buildCompactChip(color, icon, label)
                : _buildFullChip(color, icon, label, paidCount, totalCount, allPaid),
      ),
    );
  }

  Widget _buildCompactChip(Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullChip(
    Color color,
    IconData icon,
    String label,
    int paidCount,
    int totalCount,
    bool allPaid,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.2),
                color.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.showProgress && totalCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$paidCount/$totalCount paid',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedChip(
    BuildContext context,
    Color color,
    IconData icon,
    String label,
    int paidCount,
    int totalCount,
    bool allPaid,
  ) {
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
                color.withValues(alpha: 0.2),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Status',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: totalCount > 0 ? paidCount / totalCount : 0,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$paidCount of $totalCount participants paid',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              if (!allPaid && widget.booking.teamCode != null) ...[
                const SizedBox(height: 16),
                _buildParticipantList(),
              ],
              if (widget.showShareButton && !allPaid && widget.booking.teamCode != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to share screen - handled by parent
                    },
                    icon: const Icon(Icons.share, size: 20),
                    label: const Text('Share Invite Link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participants',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.booking.splitBillParticipants.map((p) {
          final paid = p.hasPaid;
          final color = paid ? AppTheme.successGreen : Colors.white.withValues(alpha: 0.6);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (paid ? AppTheme.successGreen : Colors.white).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    paid ? Icons.check_rounded : Icons.schedule_rounded,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          color: paid ? Colors.white : Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: paid ? null : TextDecoration.lineThrough,
                          decorationColor: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'RM ${p.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (paid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Paid',
                      style: TextStyle(
                        color: AppTheme.successGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _getStatusLabel(
    SplitBillStatus status,
    int paidCount,
    int totalCount,
    bool allPaid,
  ) {
    if (allPaid) {
      return 'All payments received';
    }

    switch (status) {
      case SplitBillStatus.pending:
        return 'Awaiting all payments';
      case SplitBillStatus.partial:
        final remaining = totalCount - paidCount;
        return 'Waiting for $remaining more payment${remaining == 1 ? '' : 's'}';
      case SplitBillStatus.complete:
        return 'All payments received';
      case SplitBillStatus.notApplicable:
        return 'Not Available';
    }
  }
}

