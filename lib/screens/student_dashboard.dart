import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Models & Providers
import '../models/submission_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import '../providers/submission_provider.dart';
import '../providers/task_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/dashboard_analytics.dart';
import '../widgets/dashboard_shell.dart';

// Screens
import '../screens/offline_downloads_screen.dart';
import '../screens/student_class_detail_screen.dart';
import '../screens/lesson_screen.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final classesAsync = ref.watch(myClassesProvider);
    final tasksAsync = ref.watch(tasksForMyClassesProvider);
    final submissionsAsync = ref.watch(mySubmissionsProvider);

    return DashboardScaffold(
      header: userAsync.when(
        data: (user) => _buildHeader(context, user, ref),
        loading: () => const DashboardTopBar(
          title: 'STUDENT',
          subtitle: 'Student portal',
          fallbackIcon: Icons.person,
        ),
        error: (error, stackTrace) => const DashboardTopBar(
          title: 'STUDENT',
          subtitle: 'Student portal',
          fallbackIcon: Icons.person,
        ),
      ),
      body: classesAsync.when(
        data: (classes) {
          final tasks = tasksAsync.value ?? const <TaskModel>[];
          final submissions =
              submissionsAsync.value ?? const <SubmissionModel>[];
          final classIds = classes.map((cls) => cls.id).toSet();
          final classMap = {for (final cls in classes) cls.id: cls};
          final studentTasks =
              tasks.where((task) => classIds.contains(task.classId)).toList()
                ..sort((a, b) => a.deadline.compareTo(b.deadline));
          final taskStatuses = buildStudentTaskStatusData(
            tasks: studentTasks,
            submissions: submissions,
            classesById: classMap,
          );
          final onTimeCount = taskStatuses
              .where((task) => task.state == StudentTaskState.onTime)
              .length;
          final lateCount = taskStatuses
              .where((task) => task.state == StudentTaskState.late)
              .length;
          final pendingCount = taskStatuses
              .where((task) => task.state == StudentTaskState.pending)
              .length;
          final overdueCount = taskStatuses
              .where((task) => task.state == StudentTaskState.overdue)
              .length;

          if (classes.isEmpty) {
            return _buildWelcomeState(context, ref);
          }
          return RefreshIndicator(
            color: kNavy,
            onRefresh: () async {
              ref.invalidate(myClassesProvider);
              ref.invalidate(tasksForMyClassesProvider);
              ref.invalidate(mySubmissionsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                InsightShell(
                  title: 'Your academic pulse',
                  subtitle:
                      'Track submission timing, pending work, and overdue tasks before they stack up.',
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
                              label: 'Tasks',
                              value: '${studentTasks.length}',
                              tone: kGold,
                            ),
                            const SizedBox(width: 10),
                            StatBadge(
                              label: 'On time',
                              value: '$onTimeCount',
                              tone: Colors.green.shade700,
                            ),
                            const SizedBox(width: 10),
                            StatBadge(
                              label: 'Overdue',
                              value: '$overdueCount',
                              tone: kMaroon,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      InteractiveBarChart(
                        title: 'Submission status',
                        data: [
                          DashboardBarDatum(
                            label: 'On time',
                            value: onTimeCount,
                            color: Colors.green.shade700,
                          ),
                          DashboardBarDatum(
                            label: 'Late',
                            value: lateCount,
                            color: Colors.orange.shade800,
                          ),
                          DashboardBarDatum(
                            label: 'Pending',
                            value: pendingCount,
                            color: kNavy,
                          ),
                          DashboardBarDatum(
                            label: 'Overdue',
                            value: overdueCount,
                            color: kMaroon,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      StudentTaskStatusBoard(
                        items: taskStatuses,
                        emptyText:
                            'No active tasks across your enrolled classes yet.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kNavy),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LessonScreen()),
                  ),
                  icon: const Icon(Icons.menu_book_outlined, color: kNavy),
                  label: const Text(
                    'Open Curriculum',
                    style: TextStyle(color: kNavy, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 16),
                // Join class button at top
                _buildJoinClassButton(context, ref),
                const SizedBox(height: 16),

                // Section header
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.groups, color: kNavy, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'MY CLASSES (${classes.length})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: kNavy,
                        ),
                      ),
                    ],
                  ),
                ),

                // Class cards
                ...classes.map(
                  (cls) => _ClassCard(
                    classModel: cls,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StudentClassDetailScreen(classModel: cls),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kNavy)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  // ── Welcome / empty state ─────────────────────────────────────────────────

  Widget _buildWelcomeState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: kNavy.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_outlined,
                size: 72,
                color: kNavy.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: kNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re not enrolled in any classes yet.\nAsk your instructor for a class code to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showJoinClassDialog(context, ref),
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'JOIN A CLASS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinClassButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: kNavy),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () => _showJoinClassDialog(context, ref),
      icon: const Icon(Icons.add_circle_outline, color: kNavy, size: 18),
      label: const Text(
        'Join a Class',
        style: TextStyle(color: kNavy, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AppUser? user, WidgetRef ref) {
    return DashboardTopBar(
      title: user?.fullName?.toUpperCase() ?? 'STUDENT',
      subtitle: user?.email ?? 'Student portal',
      fallbackIcon: Icons.person,
      avatarUrl: user?.avatarUrl,
      onProfileTap: () => _showProfileModal(context, user),
      actions: [
        DashboardActionButton(
          icon: Icons.download_for_offline_outlined,
          tooltip: 'Offline Downloads',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OfflineDownloadsScreen()),
          ),
        ),
        DashboardActionButton(
          icon: Icons.logout_rounded,
          tooltip: 'Logout',
          onPressed: () => _showLogoutConfirmation(context, ref),
        ),
      ],
    );
  }

  // ── Join class dialog ─────────────────────────────────────────────────────

  void _showJoinClassDialog(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();
    bool isJoining = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Join a Class',
            style: TextStyle(color: kNavy, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the 6-character class code from your instructor.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  color: kNavy,
                ),
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'XXXXXX',
                  hintStyle: TextStyle(
                    letterSpacing: 6,
                    color: Colors.grey.shade300,
                  ),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kNavy, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isJoining ? null : () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isJoining
                  ? null
                  : () async {
                      final code = codeCtrl.text.trim().toUpperCase();
                      if (code.length != 6) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a 6-character code.'),
                          ),
                        );
                        return;
                      }
                      setDialog(() => isJoining = true);
                      try {
                        final repo = ref.read(classRepositoryProvider);
                        final cls = await repo.getClassByCode(code);
                        if (cls == null) {
                          setDialog(() => isJoining = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Class not found. Check the code and try again.',
                                ),
                              ),
                            );
                          }
                          return;
                        }
                        final user = ref
                            .read(authControllerProvider)
                            .currentUser;
                        if (user == null) return;
                        if (cls.enrolledStudentIds.contains(user.uid)) {
                          setDialog(() => isJoining = false);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'You are already in ${cls.className}.',
                                ),
                              ),
                            );
                          }
                          return;
                        }
                        await repo.enrollStudent(
                          classId: cls.id,
                          studentId: user.uid,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ref.invalidate(myClassesProvider);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Joined ${cls.className}!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialog(() => isJoining = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(
                            ctx,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
              child: isJoining
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'JOIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Modals ────────────────────────────────────────────────────────────────

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(color: kNavy, fontWeight: FontWeight.bold),
        ),
        content: const Text('Ready to leave the student portal?'),
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
              // AuthWrapper will handle navigation to LoginScreen
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

  void _showProfileModal(BuildContext context, AppUser? user) {
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
                'STUDENT PROFILE',
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
                backgroundImage: (user?.avatarUrl.isNotEmpty ?? false)
                    ? NetworkImage(user!.avatarUrl)
                    : null,
                child: (user?.avatarUrl.isEmpty ?? true)
                    ? const Icon(Icons.person, size: 40, color: kNavy)
                    : null,
              ),
              const SizedBox(height: 20),
              _profileRow(
                Icons.person_outline,
                'Name',
                user?.fullName ?? 'N/A',
              ),
              _profileRow(Icons.email_outlined, 'Email', user?.email ?? 'N/A'),
              _profileRow(
                Icons.school_outlined,
                'Year',
                (user?.yearLevel?.isNotEmpty ?? false)
                    ? user!.yearLevel!
                    : 'N/A',
              ),
              _profileRow(
                Icons.class_outlined,
                'Section',
                (user?.section?.isNotEmpty ?? false) ? user!.section! : 'N/A',
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
}

// ── Class Card ────────────────────────────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  final dynamic classModel;
  final VoidCallback onTap;
  const _ClassCard({required this.classModel, required this.onTap});

  // Pick a color based on class name (deterministic)
  Color _accentColor() {
    final colors = [
      Colors.blue.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.deepPurple.shade600,
      Colors.cyan.shade700,
      Colors.green.shade700,
    ];
    final idx = (classModel.className as String).length % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coloured top strip
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.groups, color: accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classModel.className as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: kNavy,
                              ),
                            ),
                            Text(
                              classModel.subject as String,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.schedule,
                        label: classModel.schedule as String,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 8),
                      if ((classModel.semesterLabel as String).isNotEmpty)
                        _InfoChip(
                          icon: Icons.calendar_month,
                          label: classModel.semesterLabel as String,
                          color: Colors.green.shade700,
                        ),
                      const Spacer(),
                      // Tabs preview
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MiniTab(Icons.menu_book_outlined, 'Lessons', accent),
                          const SizedBox(width: 4),
                          _MiniTab(Icons.task_alt_outlined, 'Tasks', accent),
                          const SizedBox(width: 4),
                          _MiniTab(
                            Icons.picture_as_pdf_outlined,
                            'PDFs',
                            accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MiniTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MiniTab(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 12, color: color),
    );
  }
}
