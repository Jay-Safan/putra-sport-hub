import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/minimalist_loaders.dart';
import '../../../providers/providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isStudentEmail = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkStudentEmail(String email) {
    setState(() {
      _isStudentEmail = Validators.isStudentEmail(email);
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ref.read(authServiceProvider).registerWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      if (mounted) {
        context.go('/home');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(result.errorMessage ?? 'Registration failed')),
              ],
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background orbs - ignore pointer events
            IgnorePointer(
              child: _buildBackgroundOrbs(),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button - Immediate entrance
                    _buildBackButton()
                        .animate()
                        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                        .slideX(begin: -0.2, end: 0, duration: 400.ms),
                    
                    const SizedBox(height: 20),

                    // Header - Hero entrance
                    _buildHeader()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 100.ms, curve: Curves.easeOut)
                        .slideY(begin: 0.1, end: 0, duration: 600.ms),
                    
                    const SizedBox(height: 24),

                    // Demo Account Buttons
                    _buildDemoAccounts()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 200.ms, curve: Curves.easeOut)
                        .slideY(begin: 0.1, end: 0, duration: 500.ms),
                    
                    const SizedBox(height: 24),

                    // Registration Form Card - Main content
                    _buildRegistrationCard()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 300.ms, curve: Curves.easeOut)
                        .slideY(begin: 0.15, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),
                    
                    const SizedBox(height: 24),

                    // Sign In Link
                    _buildSignInLink()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 500.ms, curve: Curves.easeOut),
                    
                    const SizedBox(height: 20),
                  ],
                ),
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
          bottom: 200,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.upmRed.withValues(alpha: 0.15),
                  AppTheme.upmRed.withValues(alpha: 0.0),
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
        Positioned(
          top: 300,
          right: 20,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentGold.withValues(alpha: 0.2),
                  AppTheme.accentGold.withValues(alpha: 0.0),
                ],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 3500.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(duration: 1000.ms, delay: 400.ms),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return AnimatedPressableButton(
      onTap: () => context.pop(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join the UPM sports community',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Field - Staggered index 0
                _buildGlassTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                  validator: (value) {
                    final result = Validators.validateName(value);
                    return result.isValid ? null : result.errorMessage;
                  },
                ).cascadeIn(index: 0, baseDelay: 400.ms),
                
                const SizedBox(height: 20),

                // Email Field - Staggered index 1
                _buildGlassTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'your.email@student.upm.edu.my',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _checkStudentEmail,
                  validator: (value) {
                    final result = Validators.validateEmail(value);
                    return result.isValid ? null : result.errorMessage;
                  },
                ).cascadeIn(index: 1, baseDelay: 400.ms),
                
                const SizedBox(height: 8),

                // Student Email Badge - Animated appearance
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  height: _isStudentEmail ? 44 : 0,
                  child: _isStudentEmail 
                      ? _buildStudentBadge()
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 300.ms)
                      : null,
                ),
                
                const SizedBox(height: 12),

                // Password Field - Staggered index 2
                _buildGlassTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleObscure: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  validator: (value) {
                    final result = Validators.validatePassword(value);
                    return result.isValid ? null : result.errorMessage;
                  },
                ).cascadeIn(index: 2, baseDelay: 400.ms),
                
                const SizedBox(height: 20),

                // Confirm Password Field - Staggered index 3
                _buildGlassTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onToggleObscure: () {
                    setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                  validator: (value) {
                    final result = Validators.validateConfirmPassword(
                      _passwordController.text,
                      value,
                    );
                    return result.isValid ? null : result.errorMessage;
                  },
                ).cascadeIn(index: 3, baseDelay: 400.ms),
                
                const SizedBox(height: 28),

                // Register Button - Staggered index 4
                _buildRegisterButton().cascadeIn(index: 4, baseDelay: 400.ms),
                
                const SizedBox(height: 24),

                // Benefits Section - Staggered index 5
                _buildBenefitsSection().cascadeIn(index: 5, baseDelay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: AppTheme.primaryGreen,
            validator: validator,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: AppTheme.primaryGreen,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: onToggleObscure,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              errorStyle: const TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.successGreen.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified,
              color: AppTheme.successGreen,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Student privileges unlocked!',
            style: TextStyle(
              color: AppTheme.successGreen,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return AnimatedPressableButton(
      onTap: _isLoading ? null : _handleRegister,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const InlineLoader(
                  size: 22,
                  strokeWidth: 2.5,
                )
              : const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.2),
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
                      color: AppTheme.accentGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stars,
                      color: AppTheme.accentGold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Student Benefits',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBenefitItem(Icons.price_change_outlined,
                  'Subsidized booking prices', 0),
              _buildBenefitItem(Icons.stars_outlined, 'Earn merit points (GP08)', 1),
              _buildBenefitItem(Icons.sports_outlined, 'Apply to be a referee', 2),
              _buildBenefitItem(Icons.group_outlined, 'Organize SUKOL matches', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.accentGold),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          AnimatedPressableButton(
            onTap: () => context.pop(),
            child: const Text(
              'Sign In',
              style: TextStyle(
                color: AppTheme.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoAccounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.science_outlined,
              color: AppTheme.accentGold.withValues(alpha: 0.8),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Quick Fill (Demo Accounts)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // First row: Public and Student
        Row(
          children: [
            Expanded(
              child: _buildDemoAccountChip(
                label: 'Public',
                name: 'Public User',
                email: 'public@example.com',
                password: 'Password123',
                color: AppTheme.badmintonPurple,
                icon: Icons.person,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDemoAccountChip(
                label: 'Student',
                name: 'Ali Ahmad',
                email: 'ali@student.upm.edu.my',
                password: 'Password123',
                color: AppTheme.successGreen,
                icon: Icons.school,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Second row: Student (Referee) and Admin
        Row(
          children: [
            Expanded(
              child: _buildDemoAccountChip(
                label: 'Student (Referee)',
                name: 'Haziq Rahman',
                email: 'haziq@student.upm.edu.my',
                password: 'Password123',
                color: AppTheme.futsalBlue,
                icon: Icons.sports,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDemoAccountChip(
                label: 'Admin',
                name: 'System Admin',
                email: 'admin@upm.edu.my',
                password: 'AdminPass123',
                color: AppTheme.upmRed,
                icon: Icons.admin_panel_settings,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoAccountChip({
    required String label,
    required String name,
    required String email,
    required String password,
    required Color color,
    required IconData icon,
  }) {
    return AnimatedPressableButton(
      onTap: () {
        ScaffoldMessenger.of(context).clearSnackBars();
        
        setState(() {
          _nameController.text = name;
          _emailController.text = email;
          _passwordController.text = password;
          _confirmPasswordController.text = password;
          _checkStudentEmail(email);
        });
        
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$label form filled! Tap "Sign Up" button to create account.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                backgroundColor: color,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    email.split('@')[0],
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
