import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phys_ed/providers/auth_provider.dart';
import 'auth_gate.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../constants/app_colors.dart';
import '../widgets/public_portal_shell.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);
    try {
      final authController = ref.read(authControllerProvider);

      final result = await authController.signInWithGoogleAndCheck();

      if (result == GoogleSignInResult.existingUser ||
          result == GoogleSignInResult.newUser) {
        // ✅ SUCCESS: Replace entire stack with AuthGate — it will route
        // to onboarding (new user) or dashboard (existing user) automatically.
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-Up was cancelled or failed'),
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Google Sign-Up failed: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleEmailSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(authControllerProvider)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            role: 'student',
            section: '',
            yearLevel: '',
          );

      // ✅ SUCCESS: Replace entire stack with AuthGate — it will detect the
      // incomplete profile (no fullName) and route to OnboardingScreen.
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _openLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
        PublicPortalHeaderButton(
          label: 'Login',
          filled: false,
          onPressed: _openLogin,
        ),
        PublicPortalHeaderButton(
          label: 'Sign Up',
          filled: true,
          onPressed: null,
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
                'Sign Up',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a student account with the same visual treatment used on the landing and login screens.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.84),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              _buildGoogleButton(),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'OR USE EMAIL',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildTextField(
                _emailController,
                'Gmail Address',
                Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _passwordController,
                'Password',
                Icons.lock_outline,
                obscure: true,
              ),
              const SizedBox(height: 24),
              _buildPrimaryButton('CREATE WITH EMAIL', _handleEmailSignUp),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: _openLogin,
                  child: const Text(
                    'Already have an account? Sign in',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() => OutlinedButton.icon(
    onPressed: _isLoading ? null : _handleGoogleSignUp,
    label: const Text(
      'Sign Up with Google',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      padding: const EdgeInsets.symmetric(vertical: 14),
      foregroundColor: Colors.white,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
  }) => TextFormField(
    controller: controller,
    obscureText: obscure,
    style: const TextStyle(color: Colors.white),
    decoration: publicPortalInputDecoration(label: label, icon: icon),
  );

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) => SizedBox(
    height: 55,
    child: FilledButton(
      onPressed: _isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: kMaroon,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          : Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
    ),
  );
}
