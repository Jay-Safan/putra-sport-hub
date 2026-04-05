import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final isStudent = userAsync.valueOrNull?.isStudent ?? false;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryGreen.withValues(alpha: 0.2),
                            AppTheme.primaryGreenLight.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.help_outline_rounded,
                              color: AppTheme.primaryGreenLight,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need Help?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'We\'re here to assist you',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
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
                const SizedBox(height: 24),

                // FAQ Section
                _buildSectionHeader('Frequently Asked Questions'),
                const SizedBox(height: 16),

                // Common FAQs for all users
                _buildFAQItem(
                  icon: Icons.account_balance_wallet,
                  title: 'How do I top up my wallet?',
                  content:
                      'Go to Profile → Wallet → Top Up. You can add funds to your SukanPay wallet using various payment methods.',
                ),
                const SizedBox(height: 12),
                _buildFAQItem(
                  icon: Icons.book_online,
                  title: 'How do I book a facility?',
                  content:
                      'Navigate to Home → Select a Sport → Choose Facility → Select Date & Time → Complete Payment. Your booking will be confirmed instantly!',
                ),
                const SizedBox(height: 12),
                _buildFAQItem(
                  icon: Icons.cancel_outlined,
                  title: 'Can I cancel a booking?',
                  content:
                      'Yes! You can cancel bookings up to 24 hours before the scheduled time. Refunds will be credited back to your wallet.',
                ),

                // Student-specific FAQs
                if (isStudent) ...[
                  const SizedBox(height: 12),
                  _buildFAQItem(
                    icon: Icons.stars,
                    title: 'How do I earn merit points?',
                    content:
                        'As a UPM student, you can earn merit points by participating in tournaments, being a referee, or organizing events. Points are automatically credited to your account and count towards GP08 housing merit.',
                  ),
                  const SizedBox(height: 12),
                  _buildFAQItem(
                    icon: Icons.workspace_premium,
                    title: 'How do I become a referee?',
                    content:
                        'Go to Profile → View "Become a Referee" → Upload your transcript showing QKS2101/QKS2102/QKS2104. Once verified, you can start earning RM30/match + 3 merit points!',
                  ),
                  const SizedBox(height: 12),
                  _buildFAQItem(
                    icon: Icons.emoji_events,
                    title: 'Can I create tournaments?',
                    content:
                        'Yes! As a student, you can create and organize tournaments. Navigate to Tournaments → Create Tournament. Tournament organizers earn merit points for organizing events.',
                  ),
                ] else ...[
                  // Public user FAQs
                  const SizedBox(height: 12),
                  _buildFAQItem(
                    icon: Icons.person_outline,
                    title: 'What features are available for public users?',
                    content:
                        'As a public user, you can book facilities, make payments, view transaction history, and access basic features. Student-exclusive features like tournaments, merit points, and referee services require a UPM student email.',
                  ),
                  const SizedBox(height: 12),
                  _buildFAQItem(
                    icon: Icons.school,
                    title: 'How do I access student features?',
                    content:
                        'To unlock all features (tournaments, merit points, referee services), sign in with your UPM student email (@student.upm.edu.my). Public users can still book facilities and use the wallet system.',
                  ),
                ],

                const SizedBox(height: 32),

                // Contact Section
                _buildSectionHeader('Contact Us'),
                const SizedBox(height: 16),
                _buildContactCard(
                  icon: Icons.email_outlined,
                  title: 'Email Support',
                  subtitle: 'support@putrasporthub.upm.edu.my',
                  onTap: () => _launchEmail(),
                  color: AppTheme.infoBlue,
                ),
                const SizedBox(height: 12),
                _buildContactCard(
                  icon: Icons.phone_outlined,
                  title: 'Phone Support',
                  subtitle: '+60 3-9769 XXXX',
                  onTap: () => _launchPhone(),
                  color: AppTheme.successGreen,
                ),
                const SizedBox(height: 12),
                _buildContactCard(
                  icon: Icons.location_on_outlined,
                  title: 'Visit Us',
                  subtitle: 'Akademi Sukan UPM, Serdang, Selangor',
                  onTap: () => _openMaps(),
                  color: AppTheme.accentGold,
                ),

                const SizedBox(height: 32),

                // Quick Links
                _buildSectionHeader('Quick Links'),
                const SizedBox(height: 16),
                _buildLinkCard(
                  icon: Icons.book_outlined,
                  title: 'Terms & Conditions',
                  onTap: () => context.push('/terms-conditions'),
                ),
                const SizedBox(height: 12),
                _buildLinkCard(
                  icon: Icons.lock_outline,
                  title: 'Privacy Policy',
                  onTap: () => context.push('/privacy-policy'),
                ),
                const SizedBox(height: 12),
                _buildLinkCard(
                  icon: Icons.feedback_outlined,
                  title: 'Send Feedback',
                  onTap: () => context.push('/send-feedback'),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFAQItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryGreenLight, size: 20),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.5,
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

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final uri = Uri.parse('mailto:support@putrasporthub.upm.edu.my');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone() async {
    final uri = Uri.parse('tel:+60397691234');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=2.999,101.707',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
