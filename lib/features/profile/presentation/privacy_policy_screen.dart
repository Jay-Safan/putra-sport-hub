import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
                            AppTheme.infoBlue.withValues(alpha: 0.2),
                            AppTheme.infoBlue.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.infoBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: AppTheme.infoBlue,
                            size: 32,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Privacy Policy',
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
                  title: '1. Information We Collect',
                  content:
                      'We collect information you provide directly (name, email, student ID), usage data (booking history, preferences), and device information (IP address, device type). For student users, we also collect merit point data and referee certification information.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '2. How We Use Your Information',
                  content:
                      'We use your information to provide services (facility bookings, payments), communicate with you (notifications, support), process transactions, award merit points, and improve our services through analytics. We do not sell your personal information to third parties.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '3. Data Storage & Security',
                  content:
                      'Your data is stored securely using Firebase (Google Cloud Platform) with industry-standard encryption. We implement security measures to protect against unauthorized access. However, no system is 100% secure, and we cannot guarantee absolute security.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '4. Information Sharing',
                  content:
                      'We share information with UPM administration for merit point verification and academic records. We may share aggregated, anonymized data for research purposes. We do not share personal information with third parties except as required by law or with your explicit consent.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '5. User Rights',
                  content:
                      'You have the right to access, update, or delete your personal information through your profile settings. You can request a copy of your data by contacting support. You may opt out of marketing communications at any time.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '6. Cookies & Tracking',
                  content:
                      'We use cookies and similar technologies to enhance your experience, analyze usage patterns, and personalize content. You can control cookies through your device settings, though this may affect app functionality.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '7. Third-Party Services',
                  content:
                      'We use third-party services including Firebase (authentication, database), Google Maps (location services), and payment processors. These services have their own privacy policies, and we encourage you to review them.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '8. Data Retention',
                  content:
                      'We retain your information for as long as your account is active or as needed to provide services. After account deletion, we may retain certain information as required by law or for legitimate business purposes (e.g., transaction records).',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '9. Children\'s Privacy',
                  content:
                      'PutraSportHub is intended for users 18 years and older. Users under 18 require parental consent. We do not knowingly collect information from children without appropriate consent.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '10. Changes to Privacy Policy',
                  content:
                      'We may update this Privacy Policy from time to time. We will notify you of significant changes via email or in-app notifications. Your continued use of the platform after changes constitutes acceptance of the updated policy.',
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: '11. Contact Us',
                  content:
                      'If you have questions or concerns about this Privacy Policy, please contact us at support@putrasporthub.upm.edu.my or visit Akademi Sukan UPM, Serdang, Selangor.',
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

