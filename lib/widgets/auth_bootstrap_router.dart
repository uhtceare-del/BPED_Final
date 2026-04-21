import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../screens/admin_dashboard.dart';
import '../screens/instructor_dashboard.dart';
import '../screens/onboarding_screen.dart';
import '../screens/student_dashboard.dart';

class AuthBootstrapRouter extends ConsumerWidget {
  const AuthBootstrapRouter({super.key, required this.signedOutScreen});

  final Widget signedOutScreen;

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
            return signedOutScreen;
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
          : ErrorScaffold(message: 'Auth Error: $e'),
    );
  }
}

class LoadingScaffold extends StatelessWidget {
  const LoadingScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class ErrorScaffold extends StatelessWidget {
  const ErrorScaffold({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(message)));
  }
}
