import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'signup_screen.dart';
import '../widgets/public_portal_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicPortalScaffold(
      actions: [
        PublicPortalHeaderButton(
          label: 'Login',
          filled: true,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        PublicPortalHeaderButton(
          label: 'Sign Up',
          filled: false,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignUpScreen()),
            );
          },
        ),
      ],
      contentAlignment: Alignment.centerLeft,
      child: const PublicPortalPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PhysEdLearn',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 18),
            Text(
              'An e-learning platform for BPED students.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.02,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Inspired by the project abstract, PhysEdLearn is built to deliver course-specific content for anatomy, kinesiology, sports psychology, and teaching methodologies in one mobile-friendly portal.',
              style: TextStyle(color: Colors.white, height: 1.6, fontSize: 15),
            ),
            SizedBox(height: 14),
            Text(
              'It brings together video lessons, quizzes, offline study access, and progress tracking to support both theory and practical training for Bachelor of Physical Education learners.',
              style: TextStyle(color: Colors.white, height: 1.6, fontSize: 14),
            ),
            SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                PublicPortalPill(label: 'Video lessons'),
                PublicPortalPill(label: 'Quizzes'),
                PublicPortalPill(label: 'Offline access'),
                PublicPortalPill(label: 'Progress tracking'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
