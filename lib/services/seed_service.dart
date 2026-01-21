import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/booking/data/models/facility_model.dart';
import '../features/auth/data/models/user_model.dart';
import '../core/constants/app_constants.dart';

/// Service for seeding initial data to Firestore (v5.0 spec)
class SeedService {
  final FirebaseFirestore _firestore;

  SeedService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Seed all initial data (Facilities, Blackout Dates, Referee Jobs)
  /// Note: Users are NOT seeded automatically - use seedDemoAccounts() to create demo accounts
  Future<void> seedAll() async {
    await seedFacilities();
    await seedBlackoutDates();
    await seedRefereeJobs();
    debugPrint('✅ All data seeded successfully!');
    debugPrint('   Note: Use seedDemoAccounts() to create demo user accounts.');
  }

  /// Clear facilities collection (removes old facilities)
  Future<void> clearFacilities() async {
    debugPrint('🗑️  Clearing old facilities...');
    
    try {
      final snapshot = await _firestore
          .collection(AppConstants.facilitiesCollection)
          .get();
      
      if (snapshot.docs.isEmpty) {
        debugPrint('  ⊘ Facilities collection is already empty');
        return;
      }

      // Delete in batches (Firestore limit is 500 per batch)
      for (int i = 0; i < snapshot.docs.length; i += 500) {
        final batch = _firestore.batch();
        final batchDocs = snapshot.docs.skip(i).take(500);
        
        for (final doc in batchDocs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
      }
      
      debugPrint('  ✅ Cleared ${snapshot.docs.length} old facilities');
    } catch (e) {
      debugPrint('  ⚠️ Error clearing facilities: $e');
      rethrow;
    }
  }

  /// Seed facilities collection
  /// Set clearFirst to true to remove old facilities before seeding
  Future<void> seedFacilities({bool clearFirst = false}) async {
    debugPrint('📦 Seeding facilities...');

    // Clear old facilities if requested
    if (clearFirst) {
      await clearFacilities();
    }

    for (final facilityData in facilitiesSeedData) {
      final facility = FacilityModel.fromSeedJson(facilityData);
      await _firestore
          .collection(AppConstants.facilitiesCollection)
          .doc(facility.id)
          .set(facility.toFirestore()); // Use set() without merge to replace entirely
      debugPrint('  ✓ ${facility.name}');
      if (facility.location != null) {
        debugPrint('    📍 Location: ${facility.location!.latitude}, ${facility.location!.longitude}');
      }
    }

    debugPrint('✅ Facilities seeded (${facilitiesSeedData.length} items)');
  }

  /// Update existing facilities with location data (for facilities already in Firestore)
  /// Note: This is a utility method for updating location data on existing facilities
  /// Locations are now hardcoded in AppConstants.getFacilityLocation()
  Future<void> updateFacilityLocations() async {
    debugPrint('📍 Updating facility locations...');

    for (final facilityData in facilitiesSeedData) {
      if (facilityData['location'] != null) {
        final location = facilityData['location'] as Map<String, dynamic>;
        final geoPoint = GeoPoint(
          location['latitude'] as double,
          location['longitude'] as double,
        );
        
        await _firestore
            .collection(AppConstants.facilitiesCollection)
            .doc(facilityData['id'] as String)
            .update({'location': geoPoint});
        debugPrint('  ✓ Updated location for ${facilityData['name']}');
      }
    }

    debugPrint('✅ Facility locations updated');
  }

  /// Check if data is already seeded
  Future<bool> isSeeded() async {
    final snapshot = await _firestore
        .collection(AppConstants.facilitiesCollection)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }


  /// Clear all collections except users (preserves user accounts and their data)
  /// Safe for development/testing - does not affect user authentication
  Future<void> clearAllExceptUsers() async {
    debugPrint('⚠️ Clearing all data except users...');
    debugPrint('📋 Users collection will be preserved');

    // All collections to clear - EXCEPT users
    final collectionsToClear = [
      AppConstants.facilitiesCollection,
      AppConstants.bookingsCollection,
      AppConstants.jobsCollection,
      AppConstants.meritRecordsCollection,
      AppConstants.transactionsCollection,
      AppConstants.walletsCollection, // Wallets will be reset (users keep accounts)
      AppConstants.escrowCollection,
      AppConstants.blackoutDatesCollection,
      AppConstants.ratingsCollection,
      AppConstants.tournamentsCollection,
      AppConstants.notificationsCollection, // Clear notifications too
    ];

    int totalDeleted = 0;

    for (final collection in collectionsToClear) {
      try {
        final snapshot = await _firestore.collection(collection).get();
        final docCount = snapshot.docs.length;
        
        if (docCount == 0) {
          debugPrint('  ⊘ $collection (already empty)');
          continue;
        }

        // Delete in batches (Firestore limit is 500 per batch)
        for (int i = 0; i < snapshot.docs.length; i += 500) {
          final batch = _firestore.batch();
          final batchDocs = snapshot.docs.skip(i).take(500);
          
          for (final doc in batchDocs) {
            batch.delete(doc.reference);
          }
          
          await batch.commit();
        }
        
        totalDeleted += docCount;
        debugPrint('  ✓ Cleared $collection ($docCount documents)');
      } catch (e) {
        debugPrint('  ⚠️ Error clearing $collection: $e');
        // Continue with other collections even if one fails
      }
    }

    debugPrint('✅ Data cleared successfully!');
    debugPrint('   - Total documents deleted: $totalDeleted');
    debugPrint('   - Users preserved: ${AppConstants.usersCollection}');
    debugPrint('   - You can now run seedAll() to re-seed facilities, blackout dates, etc.');
  }

  /// Clear ALL collections including users (COMPLETE RESET)
  /// ⚠️ WARNING: This will delete EVERYTHING including all user accounts
  Future<void> clearAllCollections() async {
    // Use debugPrint for visibility in web console and Flutter debug console
    const message = '⚠️⚠️⚠️ CLEARING ALL DATA - COMPLETE RESET ⚠️⚠️⚠️';
    debugPrint(message);
    const message2 = '📋 ALL collections will be deleted including users!';
    debugPrint(message2);

    // All collections to clear - INCLUDING users
    final allCollections = [
      AppConstants.usersCollection, // ⚠️ This will delete all user accounts
      AppConstants.facilitiesCollection,
      AppConstants.bookingsCollection,
      AppConstants.jobsCollection,
      AppConstants.meritRecordsCollection,
      AppConstants.transactionsCollection,
      AppConstants.walletsCollection,
      AppConstants.escrowCollection,
      AppConstants.blackoutDatesCollection,
      AppConstants.ratingsCollection,
      AppConstants.tournamentsCollection,
      AppConstants.notificationsCollection,
    ];

    int totalDeleted = 0;

    for (final collection in allCollections) {
      try {
        final readMsg = '  🔍 Reading $collection...';
        debugPrint(readMsg);
        
        final snapshot = await _firestore.collection(collection).get();
        final docCount = snapshot.docs.length;
        
        if (docCount == 0) {
          final emptyMsg = '  ⊘ $collection (already empty)';
          debugPrint(emptyMsg);
          continue;
        }

        final deleteMsg = '  🗑️  Deleting $docCount documents from $collection...';
        debugPrint(deleteMsg);
        
        // Delete in batches (Firestore limit is 500 per batch)
        int deletedInCollection = 0;
        for (int i = 0; i < snapshot.docs.length; i += 500) {
          final batch = _firestore.batch();
          final batchDocs = snapshot.docs.skip(i).take(500);
          
          for (final doc in batchDocs) {
            batch.delete(doc.reference);
          }
          
          await batch.commit();
          deletedInCollection += batchDocs.length;
          final batchMsg = '    ✓ Deleted batch: $deletedInCollection/$docCount';
          debugPrint(batchMsg);
        }
        
        totalDeleted += docCount;
        final clearedMsg = '  ✅ Cleared $collection ($docCount documents)';
        debugPrint(clearedMsg);
      } catch (e) {
        final errorMsg = '  ❌ Error clearing $collection: $e';
        debugPrint(errorMsg);
        // Continue with other collections even if one fails
      }
    }

    final summary = '''
    
✅ ALL data cleared successfully!
   - Total documents deleted: $totalDeleted
   - ALL collections including users have been deleted
   - Test users will NOT be re-seeded (users must sign up through the app)
''';
    debugPrint(summary);
  }

  /// Create sample blackout dates
  Future<void> seedBlackoutDates() async {
    debugPrint('📦 Seeding blackout dates...');

    final sampleBlackouts = [
      {
        'id': 'blackout_convocation_2026',
        'date': Timestamp.fromDate(DateTime(2026, 10, 15)),
        'reason': 'UPM Convocation Ceremony',
        'affectedFacilities': ['fac_football_stadium', 'fac_football_padang_a'],
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'id': 'blackout_varsity_2026',
        'date': Timestamp.fromDate(DateTime(2026, 11, 1)),
        'reason': 'Varsity Team Training',
        'affectedFacilities': [
          'fac_football_stadium',
          'fac_football_padang_a',
          'fac_futsal_complex_a',
          'fac_futsal_complex_b',
        ],
        'isActive': false, // Example of inactive blackout
        'createdAt': Timestamp.now(),
      },
    ];

    for (final blackout in sampleBlackouts) {
      await _firestore
          .collection(AppConstants.blackoutDatesCollection)
          .doc(blackout['id'] as String)
          .set(blackout);
      debugPrint('  ✓ ${blackout['reason']}');
    }

    debugPrint('✅ Blackout dates seeded');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTE: seedTestUsers() has been removed
  // Users must sign up through Firebase Auth - no hardcoded test users
  // Demo account buttons in login screen are for UI convenience only
  // ═══════════════════════════════════════════════════════════════════════════

  /// Seed sample referee jobs for testing
  Future<void> seedRefereeJobs() async {
    debugPrint('📦 Seeding referee jobs...');

    final now = DateTime.now();
    // Note: Referee jobs are now only created for tournaments
    // These are sample tournament referee jobs for testing
    final sampleJobs = [
      {
        'job_id': 'job_football_001',
        'booking_id': 'tournament_001',
        'sport_type': SportType.football.code,
        'date_time': Timestamp.fromDate(now.add(const Duration(days: 3))),
        'payout_amount': AppConstants.refereeEarningsTournament,
        'status': JobStatus.open.code,
        'assigned_referee_id': null,
        'facility_name': 'Stadium UPM',
        'location': 'UPM Sports Complex',
        'notes': 'Tournament: SUKOL 2026 - Quarter Final',
        'createdAt': Timestamp.now(),
      },
      {
        'job_id': 'job_futsal_001',
        'booking_id': 'tournament_002',
        'sport_type': SportType.futsal.code,
        'date_time': Timestamp.fromDate(now.add(const Duration(days: 2))),
        'payout_amount': AppConstants.refereeEarningsTournament,
        'status': JobStatus.open.code,
        'assigned_referee_id': null,
        'facility_name': 'Gelanggang Futsal A',
        'location': 'UPM Sports Complex',
        'notes': 'Tournament: Futsal League - Match 1',
        'createdAt': Timestamp.now(),
      },
      {
        'job_id': 'job_tennis_001',
        'booking_id': 'tournament_003',
        'sport_type': SportType.tennis.code,
        'date_time': Timestamp.fromDate(now.add(const Duration(days: 4))),
        'payout_amount': AppConstants.refereeEarningsTournament,
        'status': JobStatus.open.code,
        'assigned_referee_id': null,
        'facility_name': 'Gelanggang Tenis UPM',
        'location': 'UPM Tennis Complex',
        'notes': 'Tournament: UPM Open - Semi Final',
        'createdAt': Timestamp.now(),
      },
    ];

    for (final job in sampleJobs) {
      await _firestore
          .collection(AppConstants.jobsCollection)
          .doc(job['job_id'] as String)
          .set(job);
      debugPrint('  ✓ ${job['facility_name']} - ${job['sport_type']}');
    }

    debugPrint('✅ Referee jobs seeded (${sampleJobs.length} jobs)');
  }

  /// Seed demo accounts with proper roles and permissions
  /// Creates Firebase Auth users and Firestore documents with full configuration
  /// ⚠️ IMPORTANT: Must be run while NOT logged in (or user will be signed out)
  Future<void> seedDemoAccounts() async {
    debugPrint('👤 Seeding demo accounts...');
    final auth = FirebaseAuth.instance;
    
    // Ensure no user is logged in before seeding
    if (auth.currentUser != null) {
      await auth.signOut();
      debugPrint('  ℹ️ Signed out current user to seed accounts');
    }

    final demoAccounts = [
      {
        'email': AppConstants.demoPublicEmail,
        'password': 'Password123', // At least one capital letter
        'displayName': 'Public User',
        'matricNo': null,
        'role': UserRole.public,
        'isStudent': false,
        'badges': <String>[], // Explicit type
        'walletBalance': 100.0, // Starting balance for testing
      },
      {
        'email': AppConstants.demoStudentEmail,
        'password': 'Password123',
        'displayName': 'Ali Ahmad',
        'matricNo': 'A123456',
        'role': UserRole.student,
        'isStudent': true,
        'badges': <String>[], // Explicit type
        'walletBalance': 200.0,
      },
      {
        'email': AppConstants.demoRefereeEmail,
        'password': 'Password123',
        'displayName': 'Haziq Rahman',
        'matricNo': 'H789012',
        'role': UserRole.student, // Student who is also a referee
        'isStudent': true,
        'badges': <String>[AppConstants.badgeRefFootball], // Verified referee badge - explicit type
        'walletBalance': 150.0,
      },
      {
        'email': AppConstants.demoAdminEmail,
        'password': 'AdminPass123', // At least one capital letter
        'displayName': 'System Admin',
        'matricNo': null,
        'role': UserRole.admin,
        'isStudent': false, // Admin doesn't need to be a student
        'badges': <String>[], // Explicit type
        'walletBalance': 500.0,
      },
    ];

    int created = 0;
    int skipped = 0;
    int errors = 0;

    for (final account in demoAccounts) {
      try {
        final email = account['email'] as String;
        final password = account['password'] as String;
        final displayName = account['displayName'] as String;
        final matricNo = account['matricNo'] as String?;
        final role = account['role'] as UserRole;
        final isStudent = account['isStudent'] as bool;
        // Ensure badges is List<String> (convert from dynamic if needed)
        final badges = List<String>.from(account['badges'] as List);
        final walletBalance = account['walletBalance'] as double;

        // Check if Firebase Auth user already exists
        try {
          // Try to sign in to check if user exists
          await auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          // If successful, user exists - get the UID
          final uid = auth.currentUser!.uid;
          await auth.signOut();
          
          debugPrint('  ✓ Auth user exists: $email');
          
          // Check if Firestore document exists
          final userDoc = await _firestore
              .collection(AppConstants.usersCollection)
              .doc(uid)
              .get();
          
          if (userDoc.exists) {
            // Update existing document with correct role/badges
            // Convert badges to ensure proper type
            await _firestore
                .collection(AppConstants.usersCollection)
                .doc(uid)
                .update({
              'role': role.code,
              'isStudent': isStudent,
              'badges': List<String>.from(badges), // Ensure proper type
              'matric_no': matricNo,
              'full_name': displayName,
            });
            
            // Update wallet if needed
            await _updateWallet(uid, walletBalance);
            
            debugPrint('    ✓ Updated Firestore document: $email (${role.displayName})');
            skipped++;
          } else {
            // Auth exists but no Firestore doc - create it
            await _createUserDocument(
              uid: uid,
              email: email,
              displayName: displayName,
              matricNo: matricNo,
              role: role,
              isStudent: isStudent,
              badges: badges,
              walletBalance: walletBalance,
            );
            debugPrint('    ✓ Created Firestore document: $email (${role.displayName})');
            created++;
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found' || e.code == 'wrong-password') {
            // User doesn't exist in Auth or password is wrong - try to create new account
            try {
              debugPrint('  📝 Creating new account: $email');
              
              final credential = await auth.createUserWithEmailAndPassword(
                email: email,
                password: password,
              );
              
              final uid = credential.user!.uid;
              
              // Update display name in Auth
              await credential.user!.updateDisplayName(displayName);
              
              // Create Firestore document
              await _createUserDocument(
                uid: uid,
                email: email,
                displayName: displayName,
                matricNo: matricNo,
                role: role,
                isStudent: isStudent,
                badges: badges,
                walletBalance: walletBalance,
              );
              
              debugPrint('    ✓ Created: $email (${role.displayName})');
              created++;
              
              // Sign out after creating
              await auth.signOut();
            } on FirebaseAuthException catch (createError) {
              if (createError.code == 'email-already-in-use') {
                // Account exists but we couldn't sign in - skip it
                debugPrint('    ⚠️  Account exists but password may be different - skipping: $email');
                skipped++;
              } else {
                rethrow;
              }
            }
          } else {
            rethrow;
          }
        } catch (e) {
          // Other errors
          rethrow;
        }
      } catch (e) {
        debugPrint('    ❌ Error creating ${account['email']}: $e');
        errors++;
      }
    }

    debugPrint('✅ Demo accounts seeding complete!');
    debugPrint('   - Created: $created');
    debugPrint('   - Updated: $skipped');
    debugPrint('   - Errors: $errors');
    debugPrint('');
    debugPrint('📋 Account Details:');
    debugPrint('   Public: ${AppConstants.demoPublicEmail} / Password123');
    debugPrint('   Student: ${AppConstants.demoStudentEmail} / Password123');
    debugPrint('   Student(Referee): ${AppConstants.demoRefereeEmail} / Password123');
    debugPrint('   Admin: ${AppConstants.demoAdminEmail} / AdminPass123');
  }

  /// Create user document in Firestore with proper configuration
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String displayName,
    String? matricNo,
    required UserRole role,
    required bool isStudent,
    required List<String> badges,
    required double walletBalance,
  }) async {
    final now = DateTime.now();
    
    // Create user document
    final userModel = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      matricNo: matricNo,
      role: role,
      isStudent: isStudent,
      badges: badges,
      walletBalance: walletBalance,
      totalMeritPoints: 0,
      createdAt: now,
      isActive: true,
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(userModel.toFirestore());

    // Create wallet
    await _firestore.collection(AppConstants.walletsCollection).doc(uid).set({
      'userId': uid,
      'balance': walletBalance,
      'escrowBalance': 0.0,
      'pendingBalance': 0.0,
      'currency': 'MYR',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  /// Update wallet balance
  Future<void> _updateWallet(String uid, double balance) async {
    final walletDoc = await _firestore
        .collection(AppConstants.walletsCollection)
        .doc(uid)
        .get();
    
    if (walletDoc.exists) {
      await _firestore
          .collection(AppConstants.walletsCollection)
          .doc(uid)
          .update({
        'balance': balance,
        'updatedAt': Timestamp.now(),
      });
    } else {
      await _firestore.collection(AppConstants.walletsCollection).doc(uid).set({
        'userId': uid,
        'balance': balance,
        'escrowBalance': 0.0,
        'pendingBalance': 0.0,
        'currency': 'MYR',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    }
  }
}

