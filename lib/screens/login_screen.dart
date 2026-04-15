import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_gate.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import '../providers/auth_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/public_portal_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // LOGIC PRESERVED: Google Sign-In handler
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(authControllerProvider)
          .signInWithGoogleAndCheck();

      if (result != GoogleSignInResult.existingUser &&
          result != GoogleSignInResult.newUser &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In failed or was cancelled'),
          ),
        );
        return;
      }

      // ✅ SUCCESS: Replace entire stack with AuthGate so it reacts to auth state
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      await ref.read(authControllerProvider).signIn(email, password);

      // ✅ SUCCESS: Replace entire stack with AuthGate — it will route
      // to the correct dashboard (or onboarding) based on the user profile.
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e'), backgroundColor: kMaroon),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _openSignUp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  void _openHome() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PublicPortalScaffold(
      onBrandTap: _openHome,
      actions: [
        PublicPortalHeaderButton(label: 'Login', filled: true, onPressed: null),
        PublicPortalHeaderButton(
          label: 'Sign Up',
          filled: false,
          onPressed: _openSignUp,
        ),
      ],
      contentAlignment: Alignment.centerRight,
      maxContentWidth: 440,
      child: PublicPortalPanel(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Access your BPED portal account with the same interface and color language used across the public entry screens.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.84),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: publicPortalInputDecoration(
                  label: 'Gmail Address',
                  icon: Icons.email_outlined,
                ),
                validator: (v) {
                  if (kDebugMode &&
                      kDevAdminEnabled &&
                      v?.toLowerCase().trim() == 'admin') {
                    return null;
                  }

                  return !RegExp(
                        r'^[a-zA-Z0-9._%+-]+@gmail\.com$',
                      ).hasMatch(v ?? '')
                      ? 'Must be a valid @gmail.com'
                      : null;
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: publicPortalInputDecoration(
                  label: 'Password',
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Password required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _isLoading ? null : login,
                  style: FilledButton.styleFrom(
                    backgroundColor: kMaroon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'SIGN IN',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    GestureDetector(
                      onTap: _openSignUp,
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
