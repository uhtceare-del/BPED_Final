import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'constants/app_colors.dart';
import 'firebase_options.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/instructor_dashboard.dart';
import 'screens/admin_dashboard.dart';

// Providers
import 'providers/auth_provider.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase with platform-specific options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize();
  }

  // 3. Initialize Hive for Offline capabilities (Reviewers/Downloads)
  await Hive.initFlutter();
  await Hive.openBox('downloadsBox');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PhysEdLearn',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: kNavy,
        scaffoldBackgroundColor: kBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kNavy,
          primary: kNavy,
          secondary: kMaroon,
          surface: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: kNavyBorder),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: kNavy,
          elevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: kNavyTint,
          surfaceTintColor: Colors.transparent,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: kMaroon);
            }
            return const IconThemeData(color: kGrey38);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(
              color: states.contains(WidgetState.selected) ? kNavy : kGrey38,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
            );
          }),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Colors.transparent,
          indicatorColor: kNavyTint,
          selectedIconTheme: IconThemeData(color: kMaroon),
          unselectedIconTheme: IconThemeData(color: kGrey38),
          selectedLabelTextStyle: TextStyle(
            color: kNavy,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: kGrey38,
            fontWeight: FontWeight.w600,
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: kNavy,
          unselectedLabelColor: kGrey38,
          indicatorColor: kMaroon,
          labelStyle: TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kNavyBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kNavyBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kNavy, width: 1.3),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kNavy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kNavy,
            side: const BorderSide(color: kNavyBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: kNavy,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      // The AuthWrapper determines the starting screen dynamically
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSigningOut = ref.watch(signOutInProgressProvider);
    if (isSigningOut) {
      return const LoadingScaffold();
    }

    final bootstrapState = ref.watch(authBootstrapProvider);

    return bootstrapState.when(
      data: (state) {
        switch (state.status) {
          case AuthBootstrapStatus.signedOut:
            return const HomeScreen();
          case AuthBootstrapStatus.loadingProfile:
            return const LoadingScaffold();
          case AuthBootstrapStatus.onboardingRequired:
            return const OnboardingScreen();
          case AuthBootstrapStatus.ready:
            final appUser = state.appUser;
            if (appUser == null) {
              return const LoadingScaffold();
            }

            switch (appUser.role.trim().toLowerCase()) {
              case 'admin':
                return const AdminDashboard();
              case 'instructor':
                return const InstructorDashboard();
              case 'student':
                return const StudentDashboard();
              default:
                return const OnboardingScreen();
            }
        }
      },
      loading: () => const LoadingScaffold(),
      error: (e, _) =>
          e is FirebaseException &&
              e.plugin == 'cloud_firestore' &&
              e.code == 'permission-denied' &&
              (ref.read(signOutInProgressProvider) ||
                  ref.read(firebaseAuthProvider).currentUser == null)
          ? const LoadingScaffold()
          : ErrorScaffold(message: "Auth Error: $e"),
    );
  }
}

// Simple helper for the loading state
class LoadingScaffold extends StatelessWidget {
  const LoadingScaffold({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: kNavy)),
    );
  }
}

// Simple helper for error state
class ErrorScaffold extends StatelessWidget {
  final String message;
  const ErrorScaffold({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(message)));
  }
}
