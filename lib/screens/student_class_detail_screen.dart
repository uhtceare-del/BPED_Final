import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../models/class_model.dart';
import '../widgets/dashboard_module.dart';

class StudentClassDetailScreen extends ConsumerWidget {
  final ClassModel classModel;

  const StudentClassDetailScreen({super.key, required this.classModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DashboardModuleHeader(
                  title: classModel.className,
                  subtitle: '${classModel.subject} • ${classModel.schedule}',
                  leading: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: kNavy),
                  ),
                  trailing: DashboardTag(
                    label: classModel.classCode,
                    color: kMaroon,
                    icon: Icons.vpn_key_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kNavyBorder),
                  ),
                  child: const TabBar(
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(icon: Icon(Icons.menu_book), text: 'Lessons'),
                      Tab(icon: Icon(Icons.task_alt), text: 'Tasks'),
                      Tab(icon: Icon(Icons.assignment), text: 'Grades'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildLessonsTab(),
                      _buildTasksTab(),
                      _buildGradesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLessonsTab() {
    return const DashboardEmptyState(
      icon: Icons.menu_book_outlined,
      title: 'Lessons',
      message:
          'Lesson details for this class will appear here in a later pass.',
    );
  }

  Widget _buildTasksTab() {
    return const DashboardEmptyState(
      icon: Icons.task_alt_outlined,
      title: 'Tasks',
      message:
          'Assigned activities and quizzes for this class will appear here in a later pass.',
    );
  }

  Widget _buildGradesTab() {
    return const DashboardEmptyState(
      icon: Icons.assignment_outlined,
      title: 'Grades',
      message:
          'Submission results and grades for this class will appear here in a later pass.',
    );
  }
}
