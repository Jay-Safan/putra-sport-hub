import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Split Bill share screen shown after booking creation
class SplitBillShareScreen extends StatefulWidget {
  final String teamCode;
  final double totalAmount;
  final int totalParticipants;
  final int paidParticipants;
  final VoidCallback? onCopyCode;
  final VoidCallback? onShareWhatsApp;
  final VoidCallback? onDone;

  const SplitBillShareScreen({
    super.key,
    required this.teamCode,
    required this.totalAmount,
    required this.totalParticipants,
    this.paidParticipants = 1,
    this.onCopyCode,
    this.onShareWhatsApp,
    this.onDone,
  });

  @override
  State<SplitBillShareScreen> createState() => _SplitBillShareScreenState();
}

class _SplitBillShareScreenState extends State<SplitBillShareScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _sharePerPerson => widget.totalAmount / widget.totalParticipants;
  double get _progress => widget.paidParticipants / widget.totalParticipants;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Success icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.successGreen.withValues(alpha: 0.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successGreen.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.group_add_rounded,
                    size: 60,
                    color: AppTheme.successGreen,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Title
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Share with Your Team! 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Friends can join by entering this code',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              // Team Code Card
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildCodeCard(),
              ),
              const SizedBox(height: 24),
              // Progress section
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildProgressSection(),
              ),
              const Spacer(),
              // Action buttons
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildActionButtons(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
            ),
          ),
          child: Column(
            children: [
              Text(
                'TEAM CODE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              // Code display
              GestureDetector(
                onTap: _copyCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1F1A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.accentGold.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentGold.withValues(alpha: 0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.teamCode,
                        style: const TextStyle(
                          color: AppTheme.accentGold,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _isCopied ? Icons.check : Icons.copy,
                          key: ValueKey(_isCopied),
                          color: _isCopied
                              ? AppTheme.successGreen
                              : AppTheme.accentGold,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isCopied ? 'Copied!' : 'Tap to copy',
                style: TextStyle(
                  color: _isCopied
                      ? AppTheme.successGreen
                      : Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Each person pays',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RM ${_sharePerPerson.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people,
                          color: AppTheme.primaryGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.paidParticipants}/${widget.totalParticipants}',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress bar
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.successGreen,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.totalParticipants - widget.paidParticipants} spots remaining',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Share WhatsApp button
        _buildPrimaryButton(
          icon: Icons.share,
          label: 'Share to WhatsApp',
          onTap: widget.onShareWhatsApp,
          gradient: const LinearGradient(
            colors: [Color(0xFF25D366), Color(0xFF128C7E)],
          ),
        ),
        const SizedBox(height: 12),
        // Done button
        _buildSecondaryButton(
          label: 'Done',
          onTap: widget.onDone,
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    LinearGradient? gradient,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap?.call();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient ??
              const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
              ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (gradient?.colors.first ?? AppTheme.primaryGreen)
                  .withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.teamCode));
    HapticFeedback.mediumImpact();
    setState(() => _isCopied = true);
    widget.onCopyCode?.call();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }
}

/// Team code generator utility
class TeamCodeGenerator {
  static const _adjectives = [
    'TIGER', 'EAGLE', 'SHARK', 'WOLF', 'LION',
    'HAWK', 'COBRA', 'PUMA', 'BEAR', 'STORM',
  ];

  static String generate() {
    final adjective = _adjectives[DateTime.now().millisecond % _adjectives.length];
    final number = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
    return '$adjective-${number.substring(0, 4)}';
  }
}

