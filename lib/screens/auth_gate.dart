import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../widgets/auth_bootstrap_router.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthBootstrapRouter(signedOutScreen: LoginScreen());
  }
}
