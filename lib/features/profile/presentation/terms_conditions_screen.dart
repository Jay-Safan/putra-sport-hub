import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Terms & Conditions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
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
                      child: const Row(
                        children: [
                          Icon(
                            Icons.book_outlined,
                            color: AppTheme.primaryGreenLight,
                            size: 32,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Terms & Conditions',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Last updated: January 2024',
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

                // Content Sections
                _buildSection(
                  title: '1. Acceptance of Terms',
                  content:
                      'By accessing and using PutraSportHub, you accept and agree to be bound by these Terms & Conditions. If you do not agree to these terms, please do not use our services.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '2. User Accounts',
                  content:
                      'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized access to your account. Users must be at least 18 years old or have parental consent to use this platform.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '3. Facility Bookings',
                  content:
                      'All bookings are subject to availability. Bookings must be made in advance according to facility-specific rules. Cancellations must be made at least 24 hours before the scheduled time to receive a full refund. Refunds will be credited to your SukanPay wallet.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '4. Payment Terms',
                  content:
                      'All payments are processed through the SukanPay wallet system. Prices are displayed in Malaysian Ringgit (MYR). Payments are non-refundable except as specified in our cancellation policy. We reserve the right to modify pricing with advance notice.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '5. User Conduct',
                  content:
                      'Users must use facilities responsibly and in accordance with UPM guidelines. Damage to facilities will result in charges to your account. Users are prohibited from using the platform for any illegal activities or unauthorized purposes.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '6. Referee Services',
                  content:
                      'Referees are independent contractors, not employees of PutraSportHub. Referee fees are set by the platform and are non-negotiable. Referees must maintain valid certifications and comply with UPM referee standards.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '7. Merit Points (Students Only)',
                  content:
                      'Merit points are awarded for eligible activities and count towards UPM GP08 housing merit calculations. Points are awarded automatically based on verified participation. PutraSportHub is not responsible for final merit point calculations by UPM administration.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '8. Limitation of Liability',
                  content:
                      'PutraSportHub shall not be liable for any indirect, incidental, or consequential damages arising from the use of our services. We are not responsible for injuries or accidents that occur during facility use.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '9. Modifications to Terms',
                  content:
                      'We reserve the right to modify these Terms & Conditions at any time. Users will be notified of significant changes via email or in-app notifications. Continued use of the platform after changes constitutes acceptance of the updated terms.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '10. Contact Information',
                  content:
                      'For questions regarding these Terms & Conditions, please contact us at support@putrasporthub.upm.edu.my or visit Akademi Sukan UPM, Serdang, Selangor.',
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

