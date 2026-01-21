import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/minimalist_loaders.dart';
import '../../../core/widgets/animations.dart';
import '../../../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Clear any previous error
    ref.read(lastLoginErrorProvider.notifier).state = null;

    setState(() => _isLoading = true);

    final result = await ref.read(authServiceProvider).signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // Don't navigate manually - let router handle navigation based on auth state
    } else {
      final errorMessage = result.errorMessage ?? 'Unable to sign in. Please check your credentials and try again.';
      ref.read(lastLoginErrorProvider.notifier).state = errorMessage;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for persisted login error and show it
    final lastError = ref.watch(lastLoginErrorProvider);
    
    if (lastError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && lastError == ref.read(lastLoginErrorProvider)) {
          final errorToShow = ref.read(lastLoginErrorProvider);
          ref.read(lastLoginErrorProvider.notifier).state = null;
          
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted || errorToShow == null) return;
            scaffoldMessenger.clearSnackBars();
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorToShow,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.errorRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 5),
                margin: const EdgeInsets.all(16),
                elevation: 6,
              ),
            );
          });
        }
      });
    }
    
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
            // Animated background orbs - ignore pointer events
            IgnorePointer(
              child: _buildBackgroundOrbs(),
            ),

            // Main content
            SafeArea(
              child: Builder(
                builder: (context) {
                  final authState = ref.watch(authStateProvider);
                  final currentUser = ref.watch(currentUserProvider);
                  final isAuthenticating = authState.valueOrNull != null && currentUser.isLoading;
                  
                  if (isAuthenticating) {
                    return const Center(
                      child: InlineLoader(
                        size: 32,
                        strokeWidth: 3,
                      ),
                    );
                  }
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        
                        // Logo & Branding - Hero entrance
                        _buildHeader()
                            .animate()
                            .fadeIn(duration: 700.ms, curve: Curves.easeOut)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1, 1),
                              duration: 700.ms,
                              curve: Curves.easeOutBack,
                            ),
                        
                        const SizedBox(height: 48),

                        // Login Form Card - Slide up with fade
                        _buildLoginCard()
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 300.ms, curve: Curves.easeOut)
                            .slideY(
                              begin: 0.15,
                              end: 0,
                              duration: 600.ms,
                              delay: 300.ms,
                              curve: Curves.easeOutCubic,
                            ),
                        
                        const SizedBox(height: 24),

                        // Sign Up Link - Fade in last
                        _buildSignUpLink()
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 600.ms, curve: Curves.easeOut),
                      ],
                    ),
                  );
                },
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
        // Top-right green orb - Subtle pulse
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryGreen.withValues(alpha: 0.3),
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
        // Bottom-left red orb
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.upmRed.withValues(alpha: 0.2),
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
        // Center gold accent
        Positioned(
          top: 350,
          right: 50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentGold.withValues(alpha: 0.15),
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

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          // Animated Logo with glow
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accentGold, Color(0xFFFFE082)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGold.withValues(alpha: 0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_soccer,
              color: Color(0xFF1A3D32),
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'PutraSportHub',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your Campus Sports Ecosystem',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(28),
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
                // Welcome text - Staggered index 0
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).cascadeIn(index: 0, baseDelay: 500.ms),
                
                const SizedBox(height: 6),
                
                Text(
                  'Sign in to continue your journey',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ).cascadeIn(index: 1, baseDelay: 500.ms),
                
                const SizedBox(height: 32),

                // Email Field - Staggered index 2
                _buildGlassTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'your.email@student.upm.edu.my',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final result = Validators.validateEmail(value);
                    return result.isValid ? null : result.errorMessage;
                  },
                ).cascadeIn(index: 2, baseDelay: 500.ms),
                
                const SizedBox(height: 20),

                // Password Field - Staggered index 3
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
                    // For login, we don't need strict password validation
                    // Just check if it's not empty
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ).cascadeIn(index: 3, baseDelay: 500.ms),
                
                const SizedBox(height: 36),

                // Login Button - Staggered index 4
                _buildLoginButton().cascadeIn(index: 4, baseDelay: 500.ms),
                
                const SizedBox(height: 24),

                // Demo Accounts Section - Staggered index 5
                _buildDemoAccounts().cascadeIn(index: 5, baseDelay: 500.ms),
                
                const SizedBox(height: 16),

                // Student Email Info - Staggered index 6
                _buildStudentInfoBadge().cascadeIn(index: 6, baseDelay: 500.ms),
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
                  ? Semantics(
                      label: obscureText ? 'Show password' : 'Hide password',
                      button: true,
                      child: IconButton(
                        icon: Icon(
                          obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: onToggleObscure,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              errorStyle: const TextStyle(
                color: AppTheme.errorRed,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    final authState = ref.watch(authStateProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAuthenticating = authState.valueOrNull != null && currentUser.isLoading;
    final shouldDisableButton = _isLoading || isAuthenticating;
    
    return AnimatedPressableButton(
      onTap: shouldDisableButton ? null : _handleLogin,
      semanticLabel: 'Sign in to your account',
      semanticHint: shouldDisableButton ? 'Please wait while signing in' : 'Double tap to sign in',
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
          child: shouldDisableButton
              ? const InlineLoader(
                  size: 22,
                  strokeWidth: 2.5,
                )
              : const Text(
                  'Sign In',
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
            Flexible(
              child: Text(
                'Quick Login (Demo)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
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
                email: 'admin@upm.edu.my',
                password: 'AdminPass123',
                color: AppTheme.upmRed,
                icon: Icons.admin_panel_settings,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.infoBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.infoBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.infoBlue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Demo Account Details',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildDemoAccountDetail('Public', 'public@example.com', 'Password123'),
              const SizedBox(height: 4),
              _buildDemoAccountDetail('Student', 'ali@student.upm.edu.my', 'Password123'),
              const SizedBox(height: 4),
              _buildDemoAccountDetail('Student (Referee)', 'haziq@student.upm.edu.my', 'Password123'),
              const SizedBox(height: 4),
              _buildDemoAccountDetail('Admin', 'admin@upm.edu.my', 'AdminPass123'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.warningAmber,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '⚠️ These are demo accounts - you must sign up first, then login.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildDemoAccountChip({
    required String label,
    required String email,
    required String password,
    required Color color,
    required IconData icon,
    bool fullWidth = false,
  }) {
    return AnimatedPressableButton(
      onTap: () {
        ScaffoldMessenger.of(context).clearSnackBars();
        
        setState(() {
          _emailController.text = email;
          _passwordController.text = password;
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
                        '$label credentials filled! Tap "Sign In" button to login.',
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
          mainAxisAlignment: fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
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
                      color: Colors.white.withValues(alpha: 0.5),
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

  Widget _buildStudentInfoBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.infoBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.infoBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.infoBlue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: AppTheme.infoBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Use your @student.upm.edu.my email for student prices & merit points!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAccountDetail(String label, String email, String password) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          email,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 9,
            fontFamily: 'monospace',
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Pass: $password',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              "Don't have an account? ",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AnimatedPressableButton(
            onTap: () => context.push('/register'),
            child: const Text(
              'Sign Up',
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
}
