import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'student_dashboard.dart';
import 'instructor_dashboard.dart';
import 'admin_dashboard.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // Not signed in → show login
          return const LoginScreen();
        }

        // User signed in → check full user profile
        final userAsync = ref.watch(currentUserProvider);

        return userAsync.when(
          data: (appUser) {
            // If profile doc doesn't exist yet or onboarding not completed
            // route to onboarding instead of dashboard
            if (appUser == null ||
                appUser.fullName == null ||
                appUser.fullName!.trim().isEmpty) {
              return const OnboardingScreen();
            }

            switch (appUser.role.toLowerCase()) {
              case 'student':
                return const StudentDashboard();
              case 'instructor':
                return const InstructorDashboard();
              case 'admin':
                return const AdminDashboard();
              default:
                return const Scaffold(
                  body: Center(child: Text('Role not assigned')),
                );
            }
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            body: Center(child: Text('Error loading profile: $e')),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Auth error: $e')),
      ),
    );
  }
}
