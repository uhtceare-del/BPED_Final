import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import '../providers/submission_provider.dart';
import '../providers/task_provider.dart';
import '../models/class_model.dart';
import '../models/submission_model.dart';
import '../models/task_model.dart';
import '../widgets/dashboard_analytics.dart';
import '../widgets/dashboard_shell.dart';
import 'task_screen.dart';
import 'lesson_screen.dart';
import 'class_screen.dart';
import 'reviewer_screen.dart';
import 'submission_screen.dart';
import 'trash_screen.dart';

final selectedModuleProvider = StateProvider<int>((ref) => 0);

class InstructorDashboard extends ConsumerWidget {
  const InstructorDashboard({super.key});

  // Semester removed from nav — assigned per-class in class creation
  static const _labels = [
    'Tasks',
    'Curriculum',
    'Classes',
    'Reviewers',
    'Submissions',
  ];
  static const _icons = [
    Icons.task_outlined,
    Icons.menu_book_outlined,
    Icons.groups_outlined,
    Icons.upload_file_outlined,
    Icons.assignment_outlined,
  ];
  static const _activeIcons = [
    Icons.task,
    Icons.menu_book,
    Icons.groups,
    Icons.upload_file,
    Icons.assignment_turned_in,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedModuleProvider);
    final userAsync = ref.watch(currentUserProvider);
    final screens = [
      const TaskScreen(),
      const LessonScreen(),
      const ClassScreen(),
      const ReviewerScreen(),
      const SubmissionScreen(),
    ];
    final navItems = List.generate(
      _labels.length,
      (i) => DashboardNavItem(
        label: _labels[i],
        icon: _icons[i],
        selectedIcon: _activeIcons[i],
      ),
    );

    return DashboardScaffold(
      header: userAsync.when(
        data: (user) => _buildHeader(context, ref, user),
        loading: () => const DashboardTopBar(
          title: 'INSTRUCTOR',
          subtitle: 'Instructor · LNU BPED Department',
          fallbackIcon: Icons.person,
        ),
        error: (error, stackTrace) => const DashboardTopBar(
          title: 'INSTRUCTOR',
          subtitle: 'Instructor · LNU BPED Department',
          fallbackIcon: Icons.person,
        ),
      ),
      navigationItems: navItems,
      selectedIndex: selectedIndex,
      onDestinationSelected: (i) =>
          ref.read(selectedModuleProvider.notifier).state = i,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final shouldConstrainOverview = constraints.maxHeight < 720;
          final overviewHeight = constraints.maxHeight < 520 ? 180.0 : 260.0;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                child: shouldConstrainOverview
                    ? SizedBox(
                        height: overviewHeight,
                        child: const SingleChildScrollView(
                          child: _InstructorOverview(),
                        ),
                      )
                    : const _InstructorOverview(),
              ),
              Expanded(child: screens[selectedIndex]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, appUser) {
    return DashboardTopBar(
      title: ((appUser?.fullName as String?)?.toUpperCase()) ?? 'INSTRUCTOR',
      subtitle: 'Instructor · LNU BPED Department',
      fallbackIcon: Icons.person,
      avatarUrl: appUser?.avatarUrl as String?,
      onProfileTap: () => _showProfileModal(context, appUser),
      actions: [
        DashboardActionButton(
          icon: Icons.restore_from_trash_outlined,
          tooltip: 'Trash',
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const TabBar(
                      tabs: [
                        Tab(text: 'Tasks'),
                        Tab(text: 'Lessons'),
                        Tab(text: 'Reviewers'),
                      ],
                    ),
                    const Expanded(
                      child: TabBarView(
                        children: [
                          TrashScreen(collection: 'tasks'),
                          TrashScreen(collection: 'lessons'),
                          TrashScreen(collection: 'reviewers'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        DashboardActionButton(
          icon: Icons.logout_rounded,
          tooltip: 'Logout',
          onPressed: () => _showLogoutDialog(context, ref),
        ),
      ],
    );
  }

  void _showProfileModal(BuildContext context, appUser) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'INSTRUCTOR PROFILE',
                style: TextStyle(
                  color: kNavy,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Divider(height: 30),
              CircleAvatar(
                radius: 45,
                backgroundColor: kBackground,
                backgroundImage:
                    ((appUser?.avatarUrl as String?)?.isNotEmpty ?? false)
                    ? NetworkImage(appUser!.avatarUrl as String)
                    : null,
                child: ((appUser?.avatarUrl as String?)?.isEmpty ?? true)
                    ? const Icon(Icons.person, size: 40, color: kNavy)
                    : null,
              ),
              const SizedBox(height: 20),
              _profileRow(
                Icons.person_outline,
                'Name',
                (appUser?.fullName as String?) ?? 'N/A',
              ),
              _profileRow(
                Icons.email_outlined,
                'Email',
                (appUser?.email as String?) ?? 'N/A',
              ),
              _profileRow(Icons.badge_outlined, 'Role', 'Instructor'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(color: kNavy, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kNavy.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: kNavy,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(color: kNavy, fontWeight: FontWeight.bold),
        ),
        content: const Text('Ready to leave the instructor portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kNavy),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authControllerProvider).signOut();
              // AuthWrapper will react to auth state change and route to LoginScreen
            },
            child: const Text(
              'YES, LOGOUT',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructorOverview extends ConsumerWidget {
  const _InstructorOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final classesAsync = ref.watch(instructorClassesProvider);
    final tasksAsync = ref.watch(instructorTasksProvider);
    final submissionsAsync = ref.watch(securedSubmissionsProvider);

    if (user == null ||
        classesAsync.isLoading ||
        tasksAsync.isLoading ||
        submissionsAsync.isLoading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(color: kNavy)),
      );
    }

    if (classesAsync.hasError) {
      return Text('Error: ${classesAsync.error}');
    }
    if (tasksAsync.hasError) {
      return Text('Error: ${tasksAsync.error}');
    }
    if (submissionsAsync.hasError) {
      return Text('Error: ${submissionsAsync.error}');
    }

    final classes = classesAsync.value ?? const <ClassModel>[];
    final classIds = classes.map((cls) => cls.id).toSet();
    final tasks = (tasksAsync.value ?? const <TaskModel>[])
        .where((task) => classIds.contains(task.classId))
        .toList();
    final submissions = submissionsAsync.value ?? const <SubmissionModel>[];
    final classesById = {for (final cls in classes) cls.id: cls};
    final progressItems = buildTaskProgressData(
      tasks: tasks,
      submissions: submissions,
      classesById: classesById,
    );

    final totalStudents = classes.fold<int>(
      0,
      (sum, cls) => sum + cls.enrolledStudentIds.length,
    );
    final totalOnTime = progressItems.fold<int>(
      0,
      (sum, item) => sum + item.onTimeCount,
    );
    final totalLate = progressItems.fold<int>(
      0,
      (sum, item) => sum + item.lateCount,
    );
    final totalPending = progressItems.fold<int>(
      0,
      (sum, item) => sum + item.pendingCount,
    );

    return InsightShell(
      title: 'Instruction command center',
      subtitle:
          'Monitor task completion, timing, and class workload at a glance.',
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                StatBadge(
                  label: 'Classes',
                  value: '${classes.length}',
                  tone: kNavy,
                ),
                const SizedBox(width: 10),
                StatBadge(
                  label: 'Students',
                  value: '$totalStudents',
                  tone: Colors.teal.shade700,
                ),
                const SizedBox(width: 10),
                StatBadge(
                  label: 'Tasks',
                  value: '${tasks.length}',
                  tone: kGold,
                ),
                const SizedBox(width: 10),
                StatBadge(label: 'Late', value: '$totalLate', tone: kMaroon),
              ],
            ),
          ),
          const SizedBox(height: 18),
          InteractiveBarChart(
            title: 'Submission status by task portfolio',
            data: [
              DashboardBarDatum(
                label: 'On time',
                value: totalOnTime,
                color: Colors.green.shade700,
              ),
              DashboardBarDatum(
                label: 'Late',
                value: totalLate,
                color: Colors.orange.shade800,
              ),
              DashboardBarDatum(
                label: 'Pending',
                value: totalPending,
                color: kMaroon,
              ),
              DashboardBarDatum(
                label: 'Tasks',
                value: tasks.length,
                color: kNavy,
              ),
            ],
          ),
          const SizedBox(height: 18),
          TaskProgressBoard(
            items: progressItems,
            emptyText: 'Create a task to start tracking class progress.',
          ),
        ],
      ),
    );
  }
}
