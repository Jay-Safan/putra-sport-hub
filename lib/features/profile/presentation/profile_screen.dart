import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../providers/providers.dart';
import '../../../features/auth/data/models/user_model.dart';
import '../../../core/utils/error_handler.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingPhoto = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
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
          child: userAsync.when(
            data:
                (user) =>
                    user != null
                        ? _buildProfileContent(context, ref, user)
                        : _buildNotLoggedIn(context),
            loading: () => const ShimmerProfileLoading(),
            error:
                (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    int animIndex = 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile header - Hero entrance
          _buildProfileHeader(context, ref, user)
              .animate()
              .fadeIn(duration: 600.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 24),

          // Become a Referee CTA - Prominent placement for students without badges
          if (user.isStudent && !user.isVerifiedReferee) ...[
            _buildBecomeRefereeCard(
              context,
            ).cascadeIn(index: animIndex++, baseDelay: 200.ms),
            const SizedBox(height: 20),
          ],

          // Mode Switch (only for students with referee badges)
          if (user.isVerifiedReferee && user.isStudent)
            _buildModeSwitchCard(
              context,
              ref,
              user,
            ).cascadeIn(index: animIndex++, baseDelay: 200.ms),
          if (user.isVerifiedReferee && user.isStudent)
            const SizedBox(height: 20),

          _buildWalletCard(
            context,
            ref,
            user,
          ).cascadeIn(index: animIndex++, baseDelay: 200.ms),
          const SizedBox(height: 20),

          if (user.isStudent)
            _buildMeritCard(
              context,
              user,
            ).cascadeIn(index: animIndex++, baseDelay: 200.ms),
          if (user.isStudent) const SizedBox(height: 20),

          _buildBadgesSection(
            context,
            user,
          ).cascadeIn(index: animIndex++, baseDelay: 200.ms),
          const SizedBox(height: 20),

          _buildMenuSection(
            context,
            ref,
            user,
          ).cascadeIn(index: animIndex, baseDelay: 200.ms),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    return ClipRRect(
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
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap:
                    _isUploadingPhoto
                        ? null
                        : () => _showImagePickerOptions(context, ref, user),
                child: Stack(
                  children: [
                    AvatarWidget.fromUser(
                      user: user,
                      radius: 45,
                      showGlow: true,
                      onTap:
                          _isUploadingPhoto
                              ? null
                              : () =>
                                  _showImagePickerOptions(context, ref, user),
                    ),
                    // Loading overlay on avatar - only shows when uploading
                    if (_isUploadingPhoto)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                    // Camera icon overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getRoleColor(user.role).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getRoleColor(user.role).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getRoleIcon(user.role),
                      color: _getRoleColor(user.role),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user.role.displayName,
                      style: TextStyle(
                        color: _getRoleColor(user.role),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (user.matricNo != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Matric: ${user.matricNo}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, WidgetRef ref, UserModel user) {
    final walletAsync = ref.watch(walletProvider);

    return GestureDetector(
      onTap: () => context.push('/wallet'),
      child: ClipRRect(
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
                  AppTheme.accentGold.withValues(alpha: 0.2),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: AppTheme.accentGold,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'SukanPay Wallet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/wallet/topup'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Top Up',
                          style: TextStyle(
                            color: AppTheme.accentGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                walletAsync.when(
                  data:
                      (wallet) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RM ${(wallet?.balance ?? 0.0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Available Balance',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                  loading:
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 36,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.accentGold,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Loading balance...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                  error:
                      (e, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RM ${user.walletBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Available Balance',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
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
    );
  }

  Widget _buildMeritCard(BuildContext context, UserModel user) {
    final progress = (user.totalMeritPoints /
            AppConstants.meritPointsMaxPerSemester)
        .clamp(0.0, 1.0);

    return InkWell(
      onTap: () => context.go('/merit'),
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
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
                  AppTheme.successGreen.withValues(alpha: 0.15),
                  AppTheme.successGreen.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.successGreen.withValues(alpha: 0.3),
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
                        color: AppTheme.successGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: AppTheme.successGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MyMerit Points',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'GP08 Housing Merit',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${user.totalMeritPoints}',
                      style: const TextStyle(
                        color: AppTheme.successGreen,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Semester Progress',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${user.totalMeritPoints}/${AppConstants.meritPointsMaxPerSemester} pts',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.successGreen,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tap indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: AppTheme.successGreen.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppTheme.successGreen.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, UserModel user) {
    if (user.badges.isEmpty) {
      return _buildEmptyBadges(context, user);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified,
                    color: AppTheme.accentGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Verified Badges',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${user.badges.length} Badge${user.badges.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    user.badges.map((badge) {
                      final badgeInfo = _getBadgeInfo(badge);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              badgeInfo.color.withValues(alpha: 0.3),
                              badgeInfo.color.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: badgeInfo.color.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              badgeInfo.icon,
                              color: badgeInfo.color,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              badgeInfo.label,
                              style: TextStyle(
                                color: badgeInfo.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyBadges(BuildContext context, UserModel user) {
    // Only show informational message for students who aren't verified referees
    // (The prominent "Become a Referee" card above already handles the CTA)
    final isStudentNotReferee = user.isStudent && !user.isVerifiedReferee;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isStudentNotReferee
                          ? Icons.workspace_premium_outlined
                          : Icons.info_outline,
                      color:
                          isStudentNotReferee
                              ? Colors.white.withValues(alpha: 0.4)
                              : AppTheme.infoBlue.withValues(alpha: 0.7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isStudentNotReferee
                              ? 'No Badges Yet'
                              : 'Student Features',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isStudentNotReferee
                              ? 'Complete referee certification to earn your first badge'
                              : 'Badges, merit points, and referee features are available when you sign in with an @student.upm.edu.my email.',
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
              // Public user notice only (students see the prominent card above)
              if (!user.isStudent) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.infoBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        color: AppTheme.infoBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Use your UPM student email to unlock all features',
                          style: TextStyle(
                            color: AppTheme.infoBlue.withValues(alpha: 0.9),
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

  /// Build mode switch card (Student Mode / Referee Mode)
  Widget _buildModeSwitchCard(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    final currentMode = ref.watch(activeUserModeProvider);
    final canSwitch = ref.watch(canSwitchToRefereeModeProvider);

    if (!canSwitch) return const SizedBox.shrink();

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
                AppTheme.upmRed.withValues(alpha: 0.2),
                AppTheme.upmRed.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.upmRed.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.swap_horiz, color: AppTheme.upmRed, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'App Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Switch between Student and Referee experiences',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              // Mode Toggle
              Row(
                children: [
                  // Student Mode Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final authService = ref.read(authServiceProvider);
                        ref.read(activeUserModeProvider.notifier).state =
                            UserMode.student;
                        // Save preference to Firebase (non-blocking)
                        await authService.savePreferredMode(
                          uid: user.uid,
                          mode: UserMode.student,
                        );
                        // Navigate to home when switching modes
                        if (context.mounted) {
                          context.go('/home');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color:
                              currentMode == UserMode.student
                                  ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                currentMode == UserMode.student
                                    ? AppTheme.primaryGreen
                                    : Colors.white.withValues(alpha: 0.2),
                            width: currentMode == UserMode.student ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.school,
                              color:
                                  currentMode == UserMode.student
                                      ? AppTheme.primaryGreenLight
                                      : Colors.white.withValues(alpha: 0.6),
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Student',
                              style: TextStyle(
                                color:
                                    currentMode == UserMode.student
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                                fontWeight:
                                    currentMode == UserMode.student
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            Text(
                              'Mode',
                              style: TextStyle(
                                color:
                                    currentMode == UserMode.student
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Referee Mode Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final authService = ref.read(authServiceProvider);
                        ref.read(activeUserModeProvider.notifier).state =
                            UserMode.referee;
                        // Save preference to Firebase (non-blocking)
                        await authService.savePreferredMode(
                          uid: user.uid,
                          mode: UserMode.referee,
                        );
                        // Navigate to referee dashboard when switching to referee mode
                        if (context.mounted) {
                          context.go('/referee');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color:
                              currentMode == UserMode.referee
                                  ? AppTheme.upmRed.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                currentMode == UserMode.referee
                                    ? AppTheme.upmRed
                                    : Colors.white.withValues(alpha: 0.2),
                            width: currentMode == UserMode.referee ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.sports_soccer,
                              color:
                                  currentMode == UserMode.referee
                                      ? AppTheme.upmRed
                                      : Colors.white.withValues(alpha: 0.6),
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Referee',
                              style: TextStyle(
                                color:
                                    currentMode == UserMode.referee
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                                fontWeight:
                                    currentMode == UserMode.referee
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            Text(
                              'Mode',
                              style: TextStyle(
                                color:
                                    currentMode == UserMode.referee
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
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

  /// CTA card for students to become referees (Enhanced - More Prominent)
  Widget _buildBecomeRefereeCard(BuildContext context) {
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
                AppTheme.upmRed.withValues(alpha: 0.25),
                AppTheme.upmRed.withValues(alpha: 0.15),
                AppTheme.primaryGreen.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.upmRed.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.upmRed.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => context.push('/referee/apply'),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.upmRed.withValues(alpha: 0.4),
                            AppTheme.upmRed.withValues(alpha: 0.2),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.upmRed.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.gavel_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Become a Referee 🏆',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money_rounded,
                                color: AppTheme.accentGold,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'RM30/match',
                                style: TextStyle(
                                  color: AppTheme.accentGold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(
                                Icons.stars_rounded,
                                color: AppTheme.accentGold,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '3 Merit Points',
                                style: TextStyle(
                                  color: AppTheme.accentGold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Requirements
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Requirements:',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRequirementRow('QKS2101', 'Football Referee'),
                      const SizedBox(height: 4),
                      _buildRequirementRow('QKS2104', 'Futsal Referee'),
                      const SizedBox(height: 4),
                      _buildRequirementRow('QKS2102', 'Badminton Referee'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/referee/apply');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.upmRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.upload_file, size: 20),
                    label: const Text(
                      'Apply Now',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
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
  }

  Widget _buildRequirementRow(String code, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            code,
            style: const TextStyle(
              color: AppTheme.accentGold,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              // Admin Dashboard (only for admins)
              if (user.role == UserRole.admin) ...[
                _buildMenuItem(
                  icon: Icons.admin_panel_settings,
                  label: 'Admin Dashboard',
                  onTap: () => context.go('/admin'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.upmRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                _buildDivider(),
              ],
              _buildMenuItem(
                icon: Icons.history,
                label: 'Transaction History',
                onTap: () => context.push('/wallet'),
              ),
              _buildDivider(),
              _buildNotificationMenuItem(),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.help_outline,
                label: 'Help & Support',
                onTap: () => context.push('/help-support'),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.info_outline,
                label: 'About PutraSportHub',
                onTap: () => context.push('/about'),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.logout,
                label: 'Sign Out',
                isDestructive: true,
                onTap: () => _showLogoutDialog(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationMenuItem() {
    return Builder(
      builder: (context) {
        final user = ref.watch(currentUserProvider).valueOrNull;
        final userId = user?.uid ?? '';

        if (userId.isEmpty) {
          return _buildMenuItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => context.push('/notifications'),
          );
        }

        final unreadCountAsync = ref.watch(
          unreadNotificationsCountProvider(userId),
        );

        return unreadCountAsync.when(
          data:
              (count) => _buildMenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () => context.push('/notifications'),
                trailing:
                    count > 0
                        ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        : null,
              ),
          loading:
              () => _buildMenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () => context.push('/notifications'),
              ),
          error:
              (_, __) => _buildMenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () => context.push('/notifications'),
              ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    Widget? trailing,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final color = isDestructive ? AppTheme.errorRed : Colors.white;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: color.withValues(alpha: isDestructive ? 1 : 0.7),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: isDestructive ? 1 : 0.9),
                  fontSize: 15,
                  fontWeight:
                      isDestructive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withValues(alpha: 0.08),
      indent: 56,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A3D32).withValues(alpha: 0.95),
                        const Color(0xFF0A1F1A).withValues(alpha: 0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: AppTheme.errorRed,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Title
                        const Text(
                          'Sign Out?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Message
                        Text(
                          'Are you sure you want to sign out?\nYou\'ll need to sign in again to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await ref.read(authServiceProvider).signOut();
                                  if (context.mounted) {
                                    context.go('/login');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.errorRed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Sign Out',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
          ),
    );
  }

  Future<void> _showImagePickerOptions(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    // Bottom navigation bar height - adjust if needed
    const bottomNavBarHeight = 90.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Enable for better control
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom:
                  MediaQuery.of(context).viewInsets.bottom + bottomNavBarHeight,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false, // Manual padding handling
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(top: 12, bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Title
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Change Profile Picture',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Options
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              // Gallery option
                              _buildImagePickerOption(
                                context: context,
                                icon: Icons.photo_library_rounded,
                                title: 'Choose from Gallery',
                                subtitle: 'Select an existing photo',
                                onTap: () async {
                                  // Don't close bottom sheet yet - will close after upload completes
                                  await _pickAndUploadImage(
                                    context,
                                    ref,
                                    user,
                                    ImageSource.gallery,
                                  );
                                  if (context.mounted &&
                                      Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),

                              // Camera option
                              _buildImagePickerOption(
                                context: context,
                                icon: Icons.camera_alt_rounded,
                                title: 'Take Photo',
                                subtitle: 'Capture a new photo',
                                onTap: () async {
                                  // Don't close bottom sheet yet - will close after upload completes
                                  await _pickAndUploadImage(
                                    context,
                                    ref,
                                    user,
                                    ImageSource.camera,
                                  );
                                  if (context.mounted &&
                                      Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),

                              // Remove option (if photo exists)
                              if (user.photoUrl != null &&
                                  user.photoUrl!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(
                                  color: Colors.white24,
                                  height: 1,
                                  thickness: 1,
                                ),
                                const SizedBox(height: 12),
                                _buildImagePickerOption(
                                  context: context,
                                  icon: Icons.delete_outline_rounded,
                                  title: 'Remove Photo',
                                  subtitle: 'Remove current profile picture',
                                  isDestructive: true,
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await _removeProfilePicture(
                                      context,
                                      ref,
                                      user,
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Cancel button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildImagePickerOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppTheme.errorRed : AppTheme.primaryGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDestructive ? 0.1 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: isDestructive ? 0.3 : 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    ImageSource source,
  ) async {
    try {
      // Store platform check before async operations
      final isAndroid = Theme.of(context).platform == TargetPlatform.android;

      // Check and request permissions
      PermissionStatus permissionStatus;

      if (source == ImageSource.camera) {
        permissionStatus = await Permission.camera.request();
        if (!permissionStatus.isGranted) {
          if (!mounted) return;
          _showPermissionDeniedDialog(
            this.context,
            'Camera Permission',
            'Please enable camera access in Settings to take photos.',
          );
          return;
        }
      } else {
        // For gallery access
        if (isAndroid) {
          // Android 13+ uses photos permission, older versions use storage
          if (await Permission.photos.isRestricted) {
            permissionStatus = await Permission.storage.request();
          } else {
            permissionStatus = await Permission.photos.request();
            if (!permissionStatus.isGranted) {
              permissionStatus = await Permission.storage.request();
            }
          }
        } else {
          permissionStatus = await Permission.photos.request();
        }

        if (!permissionStatus.isGranted) {
          if (!mounted) return;
          _showPermissionDeniedDialog(
            this.context,
            'Photo Library Permission',
            'Please enable photo library access in Settings to select photos.',
          );
          return;
        }
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        await _uploadProfilePicture(this.context, ref, user, pickedFile);
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ErrorHandler.getUserFriendlyErrorMessage(
        e,
        context: 'image picker',
        defaultMessage: 'Failed to pick image. Please try again.',
      );
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showPermissionDeniedDialog(
    BuildContext dialogContext,
    String title,
    String message,
  ) {
    showDialog(
      context: dialogContext,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A3D32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text(
                  'Open Settings',
                  style: TextStyle(color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
    );
  }

  void _showSuccessAnimation(BuildContext dialogContext) {
    if (!mounted) return;

    showDialog(
      context: dialogContext,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      barrierDismissible: true, // Allow tapping outside to dismiss
      useRootNavigator: true, // Use root navigator for consistency
      builder: (dialogBuildContext) {
        // Auto-close after animation
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (dialogBuildContext.mounted) {
            Navigator.of(dialogBuildContext, rootNavigator: true).pop();
          }
        });

        return PopScope(
          canPop: true, // Allow back button to dismiss
          child: GestureDetector(
            onTap: () {
              // Allow tapping dialog to dismiss
              Navigator.of(dialogBuildContext, rootNavigator: true).pop();
            },
            child: const _SuccessAnimationDialog(),
          ),
        );
      },
    );
  }

  Future<void> _uploadProfilePicture(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    XFile imageFile,
  ) async {
    if (!mounted) return;

    // Set flag to prevent router redirects during profile update
    ref.read(isUpdatingProfileProvider.notifier).state = true;

    // Show loading overlay - stays on same page
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // Upload to Cloudinary
      final storageService = ref.read(storageServiceProvider);
      final photoUrl = await storageService.uploadProfileImage(
        userId: user.uid,
        imageBytes: imageBytes,
      );

      if (photoUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Update user profile
      final authService = ref.read(authServiceProvider);
      final success = await authService.updateProfile(
        uid: user.uid,
        photoUrl: photoUrl,
      );

      if (!success) {
        throw Exception('Failed to update profile');
      }

      if (!mounted) return;

      // Hide loading overlay
      setState(() {
        _isUploadingPhoto = false;
      });

      // Clear flag - allow router redirects again (after delay to ensure Firestore update completes)
      // Use longer delay to ensure all provider updates have settled
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          ref.read(isUpdatingProfileProvider.notifier).state = false;
          debugPrint(
            '✅ Profile update flag cleared (upload) - router redirects enabled again',
          );
        }
      });

      // Capture context-dependent objects right after mounted check
      // ignore: use_build_context_synchronously
      final currentContext = context;
      // ignore: use_build_context_synchronously
      final scaffoldMessenger = ScaffoldMessenger.of(currentContext);

      // Show success animation
      // ignore: use_build_context_synchronously
      _showSuccessAnimation(currentContext);

      // Show success snackbar
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Profile picture updated successfully!'),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // No need to invalidate provider - userModelStream uses Firestore snapshots()
      // which automatically updates when the document changes in Firestore
      // This prevents router redirects that happen during provider invalidation
    } catch (e) {
      if (!mounted) return;

      // Hide loading overlay
      setState(() {
        _isUploadingPhoto = false;
      });

      // Clear flag on error too (with delay to prevent immediate router rebuild)
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          ref.read(isUpdatingProfileProvider.notifier).state = false;
          debugPrint(
            '✅ Profile update flag cleared (upload error) - router redirects enabled again',
          );
        }
      });

      // ignore: use_build_context_synchronously
      final errorMessage = ErrorHandler.getUserFriendlyErrorMessage(
        e,
        context: 'profile picture upload',
        defaultMessage: 'Failed to update profile picture. Please try again.',
      );
      // ignore: use_build_context_synchronously
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
        // Ensure flag is cleared even if there's an unexpected error
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            ref.read(isUpdatingProfileProvider.notifier).state = false;
            debugPrint(
              '✅ Profile update flag cleared (finally) - router redirects enabled again',
            );
          }
        });
      }
    }
  }

  Future<void> _removeProfilePicture(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    if (!mounted) return;

    // Set flag to prevent router redirects during profile update
    ref.read(isUpdatingProfileProvider.notifier).state = true;

    // Show loading overlay - stays on same page
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      // Update user profile to remove photoUrl
      final authService = ref.read(authServiceProvider);
      final success = await authService.updateProfile(
        uid: user.uid,
        removePhotoUrl: true,
      );

      if (!success) {
        throw Exception('Failed to remove profile picture');
      }

      if (!mounted) return;

      // Hide loading overlay
      setState(() {
        _isUploadingPhoto = false;
      });

      // Clear flag - allow router redirects again (after delay to ensure Firestore update completes)
      // Use longer delay to ensure all provider updates have settled
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          ref.read(isUpdatingProfileProvider.notifier).state = false;
          debugPrint(
            '✅ Profile update flag cleared (removal) - router redirects enabled again',
          );
        }
      });

      // ignore: use_build_context_synchronously
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Profile picture removed successfully!'),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // No need to invalidate provider - userModelStream uses Firestore snapshots()
      // which automatically updates when the document changes in Firestore
      // This prevents router redirects that happen during provider invalidation
    } catch (e) {
      if (!mounted) return;

      // Hide loading overlay
      setState(() {
        _isUploadingPhoto = false;
      });

      // Clear flag on error too (with delay to prevent immediate router rebuild)
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          ref.read(isUpdatingProfileProvider.notifier).state = false;
          debugPrint(
            '✅ Profile update flag cleared (removal error) - router redirects enabled again',
          );
        }
      });

      // ignore: use_build_context_synchronously
      final errorMessage = ErrorHandler.getUserFriendlyErrorMessage(
        e,
        context: 'profile picture removal',
        defaultMessage: 'Failed to remove profile picture. Please try again.',
      );
      // ignore: use_build_context_synchronously
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            color: Colors.white.withValues(alpha: 0.4),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Not Logged In',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.student:
        return AppTheme.successGreen;
      case UserRole.public:
        return AppTheme.futsalBlue;
      case UserRole.admin:
        return AppTheme.upmRed;
      case UserRole.referee:
        return AppTheme.accentGold;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Icons.school;
      case UserRole.public:
        return Icons.person;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.referee:
        return Icons.sports;
    }
  }

  _BadgeInfo _getBadgeInfo(String badge) {
    if (badge.contains('FOOTBALL')) {
      return _BadgeInfo(
        label: 'Football Referee',
        icon: Icons.sports_soccer,
        color: AppTheme.primaryGreen,
      );
    }
    if (badge.contains('FUTSAL')) {
      return _BadgeInfo(
        label: 'Futsal Referee',
        icon: Icons.sports_soccer,
        color: AppTheme.futsalBlue,
      );
    }
    if (badge.contains('BADMINTON')) {
      return _BadgeInfo(
        label: 'Badminton Referee',
        icon: Icons.sports_tennis,
        color: AppTheme.badmintonPurple,
      );
    }
    return _BadgeInfo(
      label: badge,
      icon: Icons.verified,
      color: AppTheme.accentGold,
    );
  }
}

class _SuccessAnimationDialog extends StatefulWidget {
  const _SuccessAnimationDialog();

  @override
  State<_SuccessAnimationDialog> createState() =>
      _SuccessAnimationDialogState();
}

class _SuccessAnimationDialogState extends State<_SuccessAnimationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 60,
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeInfo {
  final String label;
  final IconData icon;
  final Color color;

  _BadgeInfo({required this.label, required this.icon, required this.color});
}
