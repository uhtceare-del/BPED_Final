import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../widgets/dashboard_module.dart';
import '../widgets/dashboard_report_views.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReportsScreenShell(
      title: 'Admin Reports',
      subtitle:
          'System-wide enrollment, submissions, and activity metrics for the BPED e-learning platform.',
      child: AdminReportsView(),
    );
  }
}

class InstructorReportsScreen extends StatelessWidget {
  const InstructorReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReportsScreenShell(
      title: 'Instructor Reports',
      subtitle:
          'Class performance, task completion, and student progress insights for your sections.',
      child: InstructorReportsView(),
    );
  }
}

class StudentReportsScreen extends StatelessWidget {
  const StudentReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReportsScreenShell(
      title: 'Student Reports',
      subtitle:
          'Personal progress, task status, scores, and curriculum coverage across your enrolled classes.',
      child: StudentReportsView(),
    );
  }
}

class _ReportsScreenShell extends StatelessWidget {
  const _ReportsScreenShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F9FC), Color(0xFFF0F4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
            child: DashboardModulePage(
              title: title,
              subtitle: subtitle,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
