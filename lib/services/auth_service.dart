import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/retry_utils.dart';
import '../features/auth/data/models/user_model.dart';

/// Authentication service for PutraSportHub
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Check if current user is a student
  bool get isStudent {
    final email = currentUser?.email;
    return email != null &&
        email.toLowerCase().endsWith(AppConstants.studentEmailDomain);
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await RetryUtils.retry(
        operation:
            () => _auth.signInWithEmailAndPassword(
              email: email.trim(),
              password: password,
            ),
        config: RetryConfig.network,
      );

      if (credential.user != null) {
        final firebaseUid = credential.user!.uid;

        // Check if user document exists in Firestore
        final userModel = await getUserModel(firebaseUid);

        if (userModel == null) {
          // User must sign up first - reject login if user document doesn't exist
          // Sign out the Firebase Auth user since we're rejecting the login
          // Delay signOut to prevent immediate router redirect that clears error message
          Future.delayed(const Duration(milliseconds: 100), () async {
            await _auth.signOut();
          });
          return AuthResult.failure(
            'Account not found. Please sign up first to create your account, then try logging in again.',
          );
        }

        // Update last login
        await _updateLastLogin(firebaseUid);

        return AuthResult.success(credential.user!, userModel);
      }

      return AuthResult.failure(
        'Unable to sign in. Please check your credentials and try again.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(
          e,
          defaultMessage: 'Something went wrong. Please try again later.',
        ),
      );
    }
  }

  /// Register with email and password
  /// Handles existing Auth accounts by completing their Firestore setup
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await RetryUtils.retry(
        operation:
            () => _auth.createUserWithEmailAndPassword(
              email: email.trim(),
              password: password,
            ),
        config: RetryConfig.network,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(displayName);

        // Create user document in Firestore (but mark as unverified)
        final userModel = UserModel.create(
          uid: credential.user!.uid,
          email: email.trim(),
          displayName: displayName,
        );

        // Save user document with retry
        await RetryUtils.retry(
          operation: () async {
            await _firestore
                .collection(AppConstants.usersCollection)
                .doc(credential.user!.uid)
                .set(userModel.toFirestore());
          },
          config: RetryConfig.network,
        );

        // Create wallet for user with retry
        await RetryUtils.retry(
          operation: () => _createWallet(credential.user!.uid),
          config: RetryConfig.network,
        );

        return AuthResult.success(credential.user!, userModel);
      }

      return AuthResult.failure(
        'Unable to create your account. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      // Handle email-already-in-use: Account exists in Auth but might not have Firestore doc
      if (e.code == 'email-already-in-use') {
        return await _handleExistingAuthAccount(
          email: email.trim(),
          password: password,
          displayName: displayName,
        );
      }
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(
        'Something went wrong during registration. Please try again.',
      );
    }
  }

  /// Handle existing Firebase Auth account during registration
  /// Attempts to complete the account setup if Firestore document is missing
  Future<AuthResult> _handleExistingAuthAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    debugPrint('🔍 Handling existing Auth account: $email');

    try {
      // Try to sign in to verify password and get UID
      debugPrint('  → Attempting sign in to verify password...');
      final signInCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (signInCredential.user == null) {
        debugPrint('  ❌ Sign in succeeded but user is null');
        return AuthResult.failure(
          'An account already exists with this email. The password you entered is incorrect. Please use "Forgot Password" to reset it or try signing in with the correct password.',
        );
      }

      final uid = signInCredential.user!.uid;
      debugPrint('  ✅ Sign in successful. UID: $uid');

      // Check if Firestore document exists
      debugPrint('  → Checking for Firestore document...');
      final existingUserDoc = await getUserModel(uid);

      if (existingUserDoc != null) {
        // Firestore document exists - account is already complete
        debugPrint('  ℹ️ Firestore document exists - account is complete');
        await _auth.signOut(); // Sign out since we were just checking
        return AuthResult.failure(
          'An account already exists with this email. Please sign in instead.',
        );
      }

      debugPrint(
        '  ℹ️ No Firestore document found - completing account setup...',
      );

      // Firestore document doesn't exist - complete the account setup
      // Update display name if different
      if (signInCredential.user!.displayName != displayName) {
        debugPrint('  → Updating display name to: $displayName');
        await signInCredential.user!.updateDisplayName(displayName);
      }

      // Create user document in Firestore
      debugPrint('  → Creating Firestore user document...');
      final userModel = UserModel.create(
        uid: uid,
        email: email,
        displayName: displayName,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(userModel.toFirestore());

      debugPrint('  ✅ Firestore document created');

      // Create wallet for user if it doesn't exist
      debugPrint('  → Ensuring wallet exists...');
      await _ensureWalletExists(uid);

      debugPrint('  ✅ Account setup complete! User signed in.');
      // Return success - user is now signed in and has Firestore document
      return AuthResult.success(signInCredential.user!, userModel);
    } on FirebaseAuthException catch (e) {
      // Check if Firestore document exists even if password is wrong
      // This helps determine if account is complete or needs setup
      bool firestoreDocExists = false;
      try {
        // Try to get UID by attempting to fetch sign-in methods
        // If that doesn't work, we'll check Firestore by email query
        // ignore: deprecated_member_use
        final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
        if (signInMethods.isNotEmpty) {
          // Email exists in Auth - now check Firestore
          // We can't get UID without signing in, so we'll check by email
          final userQuery =
              await _firestore
                  .collection(AppConstants.usersCollection)
                  .where('email', isEqualTo: email)
                  .limit(1)
                  .get();
          firestoreDocExists = userQuery.docs.isNotEmpty;
          if (firestoreDocExists) {
            debugPrint('  ℹ️ Firestore document exists - account is complete');
          } else {
            debugPrint('  ℹ️ No Firestore document - account needs completion');
          }
        }
      } catch (checkError) {
        debugPrint('  ⚠️ Could not check Firestore status: $checkError');
      }

      // Wrong password or invalid credential
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        if (firestoreDocExists) {
          // Account is complete - just wrong password
          return AuthResult.failure(
            'An account already exists with this email, but the password is incorrect. Please use "Forgot Password" on the login page to reset your password, or sign in with the correct password.',
          );
        } else {
          // Account exists in Auth but not in Firestore - automatically send password reset
          try {
            debugPrint(
              '  → Sending password reset email to complete account setup...',
            );
            await _auth.sendPasswordResetEmail(email: email);
            debugPrint('  ✅ Password reset email sent');
            return AuthResult.failure(
              'An account exists with this email, but the password doesn\'t match. A password reset email has been sent to $email. Please check your email, reset your password, then come back and try signing in to complete your account setup.',
            );
          } catch (resetError) {
            // Failed to send password reset - guide user to manual reset
            return AuthResult.failure(
              'An account exists with this email, but the password is incorrect. Please go to the login page and use "Forgot Password" to reset it. After resetting, you can sign in to complete your account setup.',
            );
          }
        }
      } else if (e.code == 'user-disabled') {
        return AuthResult.failure(
          'This account has been disabled. Please contact support for assistance.',
        );
      } else if (e.code == 'too-many-requests') {
        return AuthResult.failure(
          'Too many attempts. Please wait a few minutes and try again.',
        );
      }
      return AuthResult.failure(
        'An account already exists with this email. Error: ${e.code}. Please sign in instead, or use "Forgot Password" to reset your password.',
      );
    } catch (e) {
      return AuthResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(
          e,
          defaultMessage:
              'An account already exists with this email. Please sign in instead.',
        ),
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(null, null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(
        'Unable to send password reset email. Please try again.',
      );
    }
  }

  /// Get user model from Firestore
  Future<UserModel?> getUserModel(String uid) async {
    try {
      final doc =
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(uid)
              .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Stream of current user model
  Stream<UserModel?> userModelStream(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  /// Save user's preferred mode to Firebase
  /// This persists the mode preference across app sessions
  Future<bool> savePreferredMode({
    required String uid,
    required UserMode mode,
  }) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {'preferredMode': mode.code, 'updatedAt': FieldValue.serverTimestamp()},
      );
      return true;
    } catch (e) {
      // Failed to save preferred mode - non-critical
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String uid,
    String? displayName,
    String? phoneNumber,
    String? matricNo,
    String? photoUrl,
    bool removePhotoUrl = false,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (matricNo != null) updates['matricNo'] = matricNo;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (removePhotoUrl) updates['photoUrl'] = FieldValue.delete();

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(updates);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Apply for referee certification (v5.0 badge system)
  /// Maps QKS course codes to VERIFIED_REF_* badges
  Future<bool> applyForRefereeCert({
    required String uid,
    required String courseCode,
  }) async {
    try {
      // Map course code to badge
      String? badge;
      switch (courseCode.toUpperCase()) {
        case 'QKS2101':
          badge = AppConstants.badgeRefFootball;
          break;
        case 'QKS2102':
          badge = AppConstants.badgeRefBadminton;
          break;
        case 'QKS2103':
          badge = AppConstants.badgeRefTennis;
          break;
        case 'QKS2104':
          badge = AppConstants.badgeRefFutsal;
          break;
        default:
          return false; // Invalid course code
      }

      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {
          'badges': FieldValue.arrayUnion([badge]),
        },
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Grant all referee badges to a user (Admin function)
  /// Adds all four referee certifications: Football, Badminton, Tennis, Futsal
  Future<bool> grantAllRefereeBadges({required String uid}) async {
    try {
      final allBadges = [
        AppConstants.badgeRefFootball,
        AppConstants.badgeRefBadminton,
        AppConstants.badgeRefTennis,
        AppConstants.badgeRefFutsal,
      ];

      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {'badges': FieldValue.arrayUnion(allBadges)},
      );

      return true;
    } catch (e) {
      // Failed to grant referee badges - non-critical
      return false;
    }
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {'lastLoginAt': Timestamp.now()},
      );
    } catch (_) {}
  }

  /// Ensure wallet exists (doesn't overwrite if already exists)
  /// This preserves seeded balances for test accounts
  Future<void> _ensureWalletExists(String uid) async {
    try {
      final doc =
          await _firestore
              .collection(AppConstants.walletsCollection)
              .doc(uid)
              .get();

      if (!doc.exists) {
        await _createWalletWithBalance(uid, 0.0);
      }
    } catch (e) {
      // Failed to ensure wallet exists - non-critical, will be created on first transaction
    }
  }

  /// Create wallet for new user
  Future<void> _createWallet(String uid) async {
    await _createWalletWithBalance(uid, 0.0);
  }

  /// Create wallet with initial balance (used by seed service)
  Future<void> _createWalletWithBalance(
    String uid,
    double initialBalance,
  ) async {
    try {
      await _firestore.collection(AppConstants.walletsCollection).doc(uid).set({
        'userId': uid,
        'balance': initialBalance,
        'escrowBalance': 0.0,
        'pendingBalance': 0.0,
        'currency': 'MYR',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (_) {}
  }

  /// Create UserModel for new users (when no Firestore document exists)
  /// Role is determined by email domain only - no hardcoded logic
  /// Admin/Referee roles must be set in Firestore via seeding or admin panel
  // Removed unused method _createUserModelForEmail
  // ignore: unused_element

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL VERIFICATION (Code-based)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a random 6-digit verification code
  String _generateVerificationCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 900000 + 100000;
    return random.toString().padLeft(6, '0');
  }

  /// Send email verification code to user
  /// Note: This stores the code in Firestore. You'll need to integrate with
  /// an email service (Firebase Cloud Functions, SendGrid, AWS SES, etc.) to actually send the email.
  Future<AuthResult> sendEmailVerificationCode(String email) async {
    try {
      final code = _generateVerificationCode();
      final expirationTime = DateTime.now().add(const Duration(minutes: 10));

      // Store verification code in Firestore
      await _firestore
          .collection(AppConstants.emailVerificationCodesCollection)
          .doc(email.toLowerCase())
          .set({
            'code': code,
            'email': email.toLowerCase(),
            'createdAt': Timestamp.now(),
            'expiresAt': Timestamp.fromDate(expirationTime),
            'verified': false,
          });

      // TODO: Integrate email service (Firebase Cloud Functions with SendGrid, AWS SES, etc.)
      // await emailService.sendVerificationCode(email: email, code: code);

      return AuthResult.success(null, null);
    } catch (e) {
      return AuthResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(
          e,
          defaultMessage: 'Failed to send verification code. Please try again.',
        ),
      );
    }
  }

  /// Resend email verification code
  Future<AuthResult> resendVerificationCode(String email) async {
    return sendEmailVerificationCode(email);
  }

  /// Verify email with code
  Future<AuthResult> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      final emailLower = email.toLowerCase().trim();
      final codeTrimmed = code.trim();

      // Get verification code from Firestore
      final doc =
          await _firestore
              .collection(AppConstants.emailVerificationCodesCollection)
              .doc(emailLower)
              .get();

      if (!doc.exists) {
        return AuthResult.failure(
          'Verification code not found. Please request a new code.',
        );
      }

      final data = doc.data()!;
      final storedCode = data['code'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final verified = data['verified'] as bool? ?? false;

      // Check if already verified
      if (verified) {
        return AuthResult.failure('This email has already been verified.');
      }

      // Check if expired
      if (DateTime.now().isAfter(expiresAt)) {
        return AuthResult.failure(
          'Verification code has expired. Please request a new code.',
        );
      }

      // Verify code
      if (storedCode != codeTrimmed) {
        return AuthResult.failure(
          'Invalid verification code. Please check and try again.',
        );
      }

      // Mark as verified
      await doc.reference.update({
        'verified': true,
        'verifiedAt': Timestamp.now(),
      });

      // Get user by email and mark email as verified in their profile
      final userQuery =
          await _firestore
              .collection(AppConstants.usersCollection)
              .where('email', isEqualTo: emailLower)
              .limit(1)
              .get();

      if (userQuery.docs.isNotEmpty) {
        await userQuery.docs.first.reference.update({
          'emailVerified': true,
          'emailVerifiedAt': Timestamp.now(),
        });
      }

      return AuthResult.success(null, null);
    } catch (e) {
      return AuthResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(
          e,
          defaultMessage: 'Failed to verify code. Please try again.',
        ),
      );
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified(String email) async {
    try {
      final emailLower = email.toLowerCase().trim();

      final userQuery =
          await _firestore
              .collection(AppConstants.usersCollection)
              .where('email', isEqualTo: emailLower)
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) return false;

      final data = userQuery.docs.first.data();
      return data['emailVerified'] as bool? ?? false;
    } catch (e) {
      // Failed to check email verification - return false as safe default
      return false;
    }
  }

  /// Get readable auth error message
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Account not found. Please sign up first to create your account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or use "Forgot Password" to reset it.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please sign in instead.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 8 characters with uppercase, lowercase, and numbers.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      case 'too-many-requests':
        return 'Too many login attempts. Please wait a few minutes and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not available. Please contact support.';
      case 'network-request-failed':
        return 'Connection error. Please check your internet and try again.';
      default:
        return 'Unable to sign in. Please check your credentials and try again.';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN STATS (Firebase-driven)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get user counts by role from Firebase
  Future<AdminUserCounts> getUserCounts() async {
    try {
      final snapshot =
          await _firestore.collection(AppConstants.usersCollection).get();

      int students = 0;
      int publicUsers = 0;
      int referees = 0;
      int admins = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final role = data['role'] as String?;
        final badges = List<String>.from(data['badges'] ?? []);
        final hasRefereeBadge = badges.any(
          (b) => b.startsWith('VERIFIED_REF_'),
        );

        switch (role) {
          case 'STUDENT':
            students++;
            if (hasRefereeBadge) referees++;
            break;
          case 'PUBLIC':
            publicUsers++;
            break;
          case 'ADMIN':
            admins++;
            break;
        }
      }

      return AdminUserCounts(
        totalUsers: snapshot.docs.length,
        students: students,
        publicUsers: publicUsers,
        referees: referees,
        admins: admins,
      );
    } catch (e) {
      // Failed to get user counts - return empty counts
      return const AdminUserCounts();
    }
  }

  /// Get all users (admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot =
          await _firestore
              .collection(AppConstants.usersCollection)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      // Failed to get all users - return empty list
      return [];
    }
  }

  /// Stream of all users (admin only)
  Stream<List<UserModel>> getAllUsersStream() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }
}

/// Admin user counts model
class AdminUserCounts {
  final int totalUsers;
  final int students;
  final int publicUsers;
  final int referees;
  final int admins;

  const AdminUserCounts({
    this.totalUsers = 0,
    this.students = 0,
    this.publicUsers = 0,
    this.referees = 0,
    this.admins = 0,
  });
}

/// Auth result wrapper
class AuthResult {
  final bool success;
  final User? user;
  final UserModel? userModel;
  final String? errorMessage;

  const AuthResult._({
    required this.success,
    this.user,
    this.userModel,
    this.errorMessage,
  });

  factory AuthResult.success(User? user, UserModel? userModel) {
    return AuthResult._(success: true, user: user, userModel: userModel);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(success: false, errorMessage: message);
  }
}
