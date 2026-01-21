import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'services/seed_service.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔥 DATA CLEAR & SEED OPTIONS 🔥
  // ═══════════════════════════════════════════════════════════════════════════
  // OPTION 1: Clear all data EXCEPT users (preserves user accounts):
  //   - Uncomment lines 54-58 below
  //   - Uses: clearAllExceptUsers()
  //
  // OPTION 2: Clear ALL data INCLUDING users (COMPLETE RESET):
  //   - Uncomment lines 61-67 below
  //   - Uses: clearAllCollections()
  //   - ⚠️ WARNING: This deletes ALL user accounts - users must sign up again!
  //
  // OPTION 3: Seed demo accounts (Public, Student, Student(Referee), Admin):
  //   - Uncomment lines 70-72 below
  //   - Creates demo accounts with proper roles and permissions
  //   - ⚠️ IMPORTANT: Must run while NOT logged in (will sign out if logged in)
  //
  // After clearing/seeding:
  //   1. Do a FULL RESTART (not hot reload) - Stop app completely and run again
  //   2. Check browser console (F12 -> Console) for success messages
  //   3. After it runs, COMMENT THEM BACK (add //) to prevent running again
  // ═══════════════════════════════════════════════════════════════════════════
  
  // OPTION 1: Clear all EXCEPT users (uncomment to use):
  // final clearService = SeedService();
  // await clearService.clearAllExceptUsers();
  // await clearService.seedAll();
  // debugPrint('✅ Data reset complete! Users preserved. Restart app normally now.');
  // // Don't return - let app start normally
  
  // OPTION 2: Clear ALL including users (uncomment to use):
  // final clearService = SeedService();
  // await clearService.clearAllCollections(); // ⚠️ Deletes EVERYTHING including users
  // // Don't seed test users after clearing - they should sign up through the app
  // await clearService.seedFacilities();
  // await clearService.seedBlackoutDates();
  // await clearService.seedRefereeJobs();
  // debugPrint('✅ Complete reset done! All data deleted. Facilities seeded. Restart app normally now.');
  // // Don't return - let app start normally
  
  // OPTION 3: Seed demo accounts (uncomment to use):
  // final demoSeedService = SeedService();
  // await demoSeedService.seedDemoAccounts(); // Creates Public, Student, Student(Referee), Admin accounts
  // debugPrint('✅ Demo accounts created! You can now login with these accounts.');
  // Don't return - let app start normally
  
  // Start app immediately - don't block on seeding check
  // Seed check will happen in background after app starts
  runApp(
    const ProviderScope(
      child: PutraSportHubApp(),
    ),
  );

  // Check and seed in background (non-blocking)
  // This prevents delay on app startup
  Future.microtask(() async {
    final seedService = SeedService();
    final isSeeded = await seedService.isSeeded();
    if (!isSeeded) {
      debugPrint('🔄 Database not seeded, seeding in background...');
      await seedService.seedAll();
      debugPrint('✅ Seeding complete!');
    }
  });
}

class PutraSportHubApp extends ConsumerWidget {
  const PutraSportHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A1F1A), // Match splash background
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryGreen,
          brightness: Brightness.dark, // Dark theme to prevent light flash
        ).copyWith(
          surface: const Color(0xFF0A1F1A), // Match splash
        ),
      ),
      routerConfig: router,
    );
  }
}
