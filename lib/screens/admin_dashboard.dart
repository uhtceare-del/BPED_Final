import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../models/class_model.dart';
import '../models/submission_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import '../providers/submission_provider.dart';
import '../providers/task_provider.dart';
import '../screens/trash_screen.dart';
import '../widgets/dashboard_analytics.dart';
import '../widgets/dashboard_module.dart';
import '../widgets/dashboard_shell.dart';

final _adminTabProvider = StateProvider<int>((ref) => 0);

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  static const _labels = ['Classes', 'Reports', 'Users', 'Uploads'];
  static const _icons = [
    Icons.groups_outlined,
    Icons.bar_chart_outlined,
    Icons.people_outline,
    Icons.upload_file_outlined,
  ];
  static const _activeIcons = [
    Icons.groups,
    Icons.bar_chart,
    Icons.people,
    Icons.upload_file,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_adminTabProvider);
    final userAsync = ref.watch(currentUserProvider);
    final screens = const [
      _AdminClassesTab(),
      _AdminReportsTab(),
      _AdminUsersTab(),
      _AdminUploadsTab(),
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
        data: (user) => _AdminHeader(user: user),
        loading: () => const _AdminHeader(user: null),
        error: (error, stackTrace) => const _AdminHeader(user: null),
      ),
      navigationItems: navItems,
      selectedIndex: tab,
      onDestinationSelected: (i) =>
          ref.read(_adminTabProvider.notifier).state = i,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: screens[tab],
      ),
    );
  }
}

class _AdminHeader extends ConsumerWidget {
  const _AdminHeader({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardTopBar(
      title: user?.fullName?.toUpperCase() ?? 'ADMIN',
      subtitle: 'Administrator · LNU BPED Department',
      fallbackIcon: Icons.admin_panel_settings,
      avatarUrl: user?.avatarUrl,
      actions: [
        DashboardActionButton(
          icon: Icons.restore_from_trash_outlined,
          tooltip: 'Trash',
          onPressed: () => _showTrashSheet(context),
        ),
        DashboardActionButton(
          icon: Icons.logout_rounded,
          tooltip: 'Logout',
          onPressed: () => _showLogoutDialog(context, ref),
        ),
      ],
    );
  }

  void _showTrashSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: DefaultTabController(
          length: 4,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recovery Center',
                    style: TextStyle(
                      color: kNavy,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Restore deleted users, tasks, lessons, and reviewers.',
                    style: TextStyle(
                      color: kGrey38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Users'),
                  Tab(text: 'Tasks'),
                  Tab(text: 'Lessons'),
                  Tab(text: 'Reviewers'),
                ],
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    TrashScreen(collection: 'users'),
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
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(color: kNavy, fontWeight: FontWeight.w900),
        ),
        content: const Text('Sign out of the admin portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authControllerProvider).signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _AdminClassesTab extends ConsumerWidget {
  const _AdminClassesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(allClassesProvider);

    return Stack(
      children: [
        classesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: kNavy)),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (classes) {
            if (classes.isEmpty) {
              return DashboardEmptyState(
                icon: Icons.groups_outlined,
                title: 'No class sections yet',
                message:
                    'Create class sections so instructors and students can start organizing curriculum and tasks.',
                action: FilledButton.icon(
                  onPressed: () => _showClassSheet(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Create class'),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 88),
              itemCount: classes.length,
              itemBuilder: (context, i) {
                final cls = classes[i];
                return _AdminClassCard(
                  cls: cls,
                  onEdit: () => _showClassSheet(context, ref, existing: cls),
                  onDelete: () => _showDeleteDialog(
                    context,
                    title: 'Delete Class',
                    content:
                        "Delete '${cls.className}'? This will permanently remove the class section.",
                    onConfirm: () => FirebaseFirestore.instance
                        .collection('classes')
                        .doc(cls.id)
                        .delete(),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: FloatingActionButton.extended(
            backgroundColor: kNavy,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'New Class',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            onPressed: () => _showClassSheet(context, ref),
          ),
        ),
      ],
    );
  }

  void _showClassSheet(
    BuildContext context,
    WidgetRef ref, {
    ClassModel? existing,
  }) {
    final nameCtrl = TextEditingController(text: existing?.className ?? '');
    final subjectCtrl = TextEditingController(text: existing?.subject ?? '');
    final schedCtrl = TextEditingController(text: existing?.schedule ?? '');
    String semester = existing?.semesterLabel.isNotEmpty == true
        ? existing!.semesterLabel
        : '1st Semester';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => _AdminFormSheet(
          title: existing == null ? 'Create New Class' : 'Edit Class Section',
          subtitle:
              'Manage the class name, subject, schedule, and semester label.',
          fields: [
            _AdminOutlineField(
              controller: nameCtrl,
              label: 'Class Name (e.g. BPED 2-A)',
              caps: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            _AdminOutlineField(controller: subjectCtrl, label: 'Subject'),
            const SizedBox(height: 12),
            _AdminOutlineField(
              controller: schedCtrl,
              label: 'Schedule (e.g. Mon/Wed 1:00PM)',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: semester,
              decoration: const InputDecoration(labelText: 'Semester'),
              items: const [
                DropdownMenuItem(
                  value: '1st Semester',
                  child: Text('1st Semester'),
                ),
                DropdownMenuItem(
                  value: '2nd Semester',
                  child: Text('2nd Semester'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setSheet(() => semester = value);
                }
              },
            ),
          ],
          buttonLabel: existing == null ? 'CREATE CLASS' : 'SAVE CHANGES',
          buttonColor: existing == null ? kNavy : Colors.blueAccent,
          onSubmit: () async {
            if (nameCtrl.text.trim().isEmpty) {
              throw Exception('Class name is required.');
            }

            if (existing == null) {
              await ref
                  .read(classRepositoryProvider)
                  .createClass(
                    ClassModel(
                      id: '',
                      className: nameCtrl.text.trim(),
                      subject: subjectCtrl.text.trim(),
                      schedule: schedCtrl.text.trim(),
                      classCode: '',
                      semesterLabel: semester,
                      instructorId: '',
                      enrolledStudentIds: const [],
                    ),
                  );
            } else {
              await FirebaseFirestore.instance
                  .collection('classes')
                  .doc(existing.id)
                  .update({
                    'className': nameCtrl.text.trim(),
                    'subject': subjectCtrl.text.trim(),
                    'schedule': schedCtrl.text.trim(),
                    'semesterLabel': semester,
                  });
            }
          },
        ),
      ),
    );
  }
}

class _AdminClassCard extends StatelessWidget {
  const _AdminClassCard({
    required this.cls,
    required this.onEdit,
    required this.onDelete,
  });

  final ClassModel cls;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kNavy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.groups, color: kNavy),
        ),
        title: Text(
          cls.className,
          style: const TextStyle(fontWeight: FontWeight.w900, color: kNavy),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DashboardTag(label: cls.subject, color: kNavy),
              if (cls.schedule.isNotEmpty)
                DashboardTag(
                  label: cls.schedule,
                  color: Colors.blueGrey,
                  icon: Icons.schedule,
                ),
              DashboardTag(
                label: '${cls.enrolledStudentIds.length} students',
                color: Colors.teal.shade700,
                icon: Icons.people_outline,
              ),
              if (cls.classCode.isNotEmpty)
                DashboardTag(
                  label: cls.classCode,
                  color: kMaroon,
                  icon: Icons.vpn_key_outlined,
                ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminReportsTab extends ConsumerStatefulWidget {
  const _AdminReportsTab();

  @override
  ConsumerState<_AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends ConsumerState<_AdminReportsTab> {
  int _selectedChart = 0;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final classesAsync = ref.watch(allClassesProvider);
    final tasksAsync = ref.watch(allTasksProvider);
    final submissionsAsync = ref.watch(submissionProvider);

    if (usersAsync.isLoading ||
        classesAsync.isLoading ||
        tasksAsync.isLoading ||
        submissionsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: kNavy));
    }

    if (usersAsync.hasError) {
      return Center(child: Text('Error: ${usersAsync.error}'));
    }
    if (classesAsync.hasError) {
      return Center(child: Text('Error: ${classesAsync.error}'));
    }
    if (tasksAsync.hasError) {
      return Center(child: Text('Error: ${tasksAsync.error}'));
    }
    if (submissionsAsync.hasError) {
      return Center(child: Text('Error: ${submissionsAsync.error}'));
    }

    final users = usersAsync.value ?? const <Map<String, dynamic>>[];
    final classes = classesAsync.value ?? const <ClassModel>[];
    final tasks = tasksAsync.value ?? const <TaskModel>[];
    final submissions = submissionsAsync.value ?? const <SubmissionModel>[];
    final classesById = {for (final cls in classes) cls.id: cls};
    final progressItems = buildTaskProgressData(
      tasks: tasks,
      submissions: submissions,
      classesById: classesById,
    );

    final roleCounts = <String, int>{'student': 0, 'instructor': 0, 'admin': 0};
    for (final user in users) {
      final role = (user['role'] ?? '').toString().toLowerCase();
      if (roleCounts.containsKey(role)) {
        roleCounts[role] = roleCounts[role]! + 1;
      }
    }

    final totalOnTime = progressItems.fold<int>(
      0,
      (total, item) => total + item.onTimeCount,
    );
    final totalLate = progressItems.fold<int>(
      0,
      (total, item) => total + item.lateCount,
    );
    final totalPending = progressItems.fold<int>(
      0,
      (total, item) => total + item.pendingCount,
    );

    final chartSets = [
      <DashboardBarDatum>[
        DashboardBarDatum(
          label: 'Students',
          value: roleCounts['student'] ?? 0,
          color: kNavy,
        ),
        DashboardBarDatum(
          label: 'Instructors',
          value: roleCounts['instructor'] ?? 0,
          color: kGold,
        ),
        DashboardBarDatum(
          label: 'Admins',
          value: roleCounts['admin'] ?? 0,
          color: kMaroon,
        ),
        DashboardBarDatum(
          label: 'Classes',
          value: classes.length,
          color: Colors.teal.shade700,
        ),
      ],
      <DashboardBarDatum>[
        DashboardBarDatum(label: 'Tasks', value: tasks.length, color: kNavy),
        DashboardBarDatum(
          label: 'Submitted',
          value: submissions.length,
          color: Colors.green.shade700,
        ),
        DashboardBarDatum(
          label: 'On time',
          value: totalOnTime,
          color: Colors.lightGreen.shade700,
        ),
        DashboardBarDatum(
          label: 'Late',
          value: totalLate,
          color: Colors.orange.shade800,
        ),
      ],
      <DashboardBarDatum>[
        DashboardBarDatum(
          label: 'Pending',
          value: totalPending,
          color: kMaroon,
        ),
        DashboardBarDatum(
          label: 'Active tasks',
          value: progressItems.length,
          color: kNavy,
        ),
        DashboardBarDatum(
          label: 'Classes live',
          value: classes.length,
          color: Colors.indigo.shade700,
        ),
        DashboardBarDatum(
          label: 'Uploads',
          value: submissions.length,
          color: Colors.cyan.shade700,
        ),
      ],
    ];

    final chartTitles = [
      'Population snapshot',
      'Submission timing',
      'Workload pressure',
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        InsightShell(
          title: 'Department pulse',
          subtitle:
              'Interactive reporting for enrollment, submissions, and task completion.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('Population'),
                    selected: _selectedChart == 0,
                    onSelected: (_) => setState(() => _selectedChart = 0),
                  ),
                  ChoiceChip(
                    label: const Text('Submissions'),
                    selected: _selectedChart == 1,
                    onSelected: (_) => setState(() => _selectedChart = 1),
                  ),
                  ChoiceChip(
                    label: const Text('Backlog'),
                    selected: _selectedChart == 2,
                    onSelected: (_) => setState(() => _selectedChart = 2),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    StatBadge(
                      label: 'Active users',
                      value: '${users.length}',
                      tone: kNavy,
                    ),
                    const SizedBox(width: 10),
                    StatBadge(
                      label: 'Classes',
                      value: '${classes.length}',
                      tone: Colors.teal.shade700,
                    ),
                    const SizedBox(width: 10),
                    StatBadge(
                      label: 'Tasks',
                      value: '${tasks.length}',
                      tone: kGold,
                    ),
                    const SizedBox(width: 10),
                    StatBadge(
                      label: 'Late submissions',
                      value: '$totalLate',
                      tone: kMaroon,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              InteractiveBarChart(
                title: chartTitles[_selectedChart],
                data: chartSets[_selectedChart],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Task Progress Spotlight',
          style: TextStyle(
            color: kNavy,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        TaskProgressBoard(items: progressItems),
      ],
    );
  }
}

class _AdminUsersTab extends ConsumerStatefulWidget {
  const _AdminUsersTab();

  @override
  ConsumerState<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<_AdminUsersTab> {
  String _search = '';
  String _roleFilter = 'all';
  static const _roles = ['all', 'student', 'instructor', 'admin'];

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> users) {
    return users.where((user) {
      final name = (user['fullName'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? '').toString().toLowerCase();
      return (_search.isEmpty ||
              name.contains(_search) ||
              email.contains(_search)) &&
          (_roleFilter == 'all' || role == _roleFilter);
    }).toList();
  }

  void _openUserSheet([Map<String, dynamic>? existing]) {
    final isEdit = existing != null;
    final uid = existing?['id']?.toString();
    final nameCtrl = TextEditingController(
      text: (existing?['fullName'] ?? '').toString(),
    );
    final emailCtrl = TextEditingController(
      text: (existing?['email'] ?? '').toString(),
    );
    final passwordCtrl = TextEditingController();
    String role = (existing?['role'] ?? 'student').toString();
    String? selectedYear = (existing?['yearLevel'] ?? '').toString().isEmpty
        ? null
        : (existing?['yearLevel'] ?? '').toString();
    String? selectedSection = (existing?['section'] ?? '').toString().isEmpty
        ? null
        : (existing?['section'] ?? '').toString();
    bool showPassword = false;

    List<String> sectionsForYear(String year) => [
      'PE-${year}1',
      'PE-${year}2',
      'PE-${year}3',
      'PE-${year}4',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => _AdminFormSheet(
          title: isEdit ? 'Edit User' : 'Create New User',
          subtitle: isEdit
              ? 'Update role access and profile metadata.'
              : 'Create a managed user account and set a temporary password.',
          fields: [
            _AdminOutlineField(
              controller: nameCtrl,
              label: 'Full Name',
              caps: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            _AdminOutlineField(
              controller: emailCtrl,
              label: 'Email Address',
              keyboard: TextInputType.emailAddress,
            ),
            if (!isEdit) ...[
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: 'Temporary Password',
                  helperText:
                      'Leave blank to require password activation later.',
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setSheet(() => showPassword = !showPassword),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Role',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 8),
            _RolePicker(
              selected: role,
              onChanged: (value) => setSheet(() => role = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedYear,
              decoration: const InputDecoration(labelText: 'Year Level'),
              items: const [
                DropdownMenuItem(value: '1', child: Text('Year 1')),
                DropdownMenuItem(value: '2', child: Text('Year 2')),
                DropdownMenuItem(value: '3', child: Text('Year 3')),
                DropdownMenuItem(value: '4', child: Text('Year 4')),
              ],
              onChanged: (value) => setSheet(() {
                selectedYear = value;
                selectedSection = null;
              }),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: selectedSection,
              decoration: const InputDecoration(labelText: 'Section'),
              items: selectedYear == null
                  ? const []
                  : sectionsForYear(selectedYear!)
                        .map(
                          (section) => DropdownMenuItem(
                            value: section,
                            child: Text(section),
                          ),
                        )
                        .toList(),
              onChanged: selectedYear == null
                  ? null
                  : (value) => setSheet(() => selectedSection = value),
            ),
          ],
          buttonLabel: isEdit ? 'SAVE CHANGES' : 'CREATE USER',
          buttonColor: isEdit ? Colors.blueAccent : kNavy,
          onSubmit: () async {
            final name = nameCtrl.text.trim();
            final email = emailCtrl.text.trim();
            if (name.isEmpty || email.isEmpty) {
              throw Exception('Name and email are required.');
            }

            final data = <String, dynamic>{
              'fullName': name,
              'email': email,
              'role': role,
              'yearLevel': selectedYear ?? '',
              'section': selectedSection ?? '',
            };

            if (isEdit) {
              await adminUpdateUser(uid!, data);
            } else {
              await adminCreateUser({
                ...data,
                'password': passwordCtrl.text.trim(),
                'avatarUrl': '',
                'onboardingCompleted': true,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final disabledUsersAsync = ref.watch(adminDisabledUsersProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Stack(
      children: [
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Active Users'),
                  Tab(text: 'Disabled Users'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                          child: Column(
                            children: [
                              TextField(
                                onChanged: (value) => setState(
                                  () => _search = value.toLowerCase(),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search by name or email',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: kNavy,
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _roles.map((role) {
                                    final selected = _roleFilter == role;
                                    return GestureDetector(
                                      onTap: () =>
                                          setState(() => _roleFilter = role),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? kNavy
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: selected
                                                ? kNavy
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          role == 'all'
                                              ? 'All'
                                              : role[0].toUpperCase() +
                                                    role.substring(1),
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                : Colors.grey.shade700,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: usersAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(color: kNavy),
                            ),
                            error: (e, _) => Center(child: Text('Error: $e')),
                            data: (allUsers) {
                              final users = _filter(allUsers);
                              if (users.isEmpty) {
                                return const DashboardEmptyState(
                                  icon: Icons.people_outline,
                                  title: 'No users found',
                                  message:
                                      'Adjust the search or create a new user account.',
                                );
                              }
                              return ListView.builder(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 88),
                                itemCount: users.length,
                                itemBuilder: (context, i) {
                                  final user = users[i];
                                  final isSelf =
                                      user['id'].toString() == currentUser?.uid;
                                  return _UserCard(
                                    user: user,
                                    onEditPermissions: () =>
                                        _openUserSheet(user),
                                    onDisable: isSelf
                                        ? null
                                        : () => _showDeleteDialog(
                                            context,
                                            title: 'Disable User',
                                            content:
                                                "Disable '${(user['fullName'] ?? user['email']).toString()}'? Sign in will be blocked until the account is re-enabled.",
                                            onConfirm: () => adminDisableUser(
                                              user['id'].toString(),
                                              disabledBy: currentUser?.uid,
                                            ),
                                          ),
                                    onDelete: isSelf
                                        ? null
                                        : () => _showDeleteDialog(
                                            context,
                                            title: 'Delete User',
                                            content:
                                                "Move '${(user['fullName'] ?? user['email']).toString()}' to trash? You can recover the profile later from Recovery Center.",
                                            onConfirm: () => adminDeleteUser(
                                              user['id'].toString(),
                                              deletedBy: currentUser?.uid,
                                            ),
                                          ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    disabledUsersAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: kNavy),
                      ),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (users) {
                        if (users.isEmpty) {
                          return const DashboardEmptyState(
                            icon: Icons.person_off_outlined,
                            title: 'No disabled users',
                            message:
                                'Disabled accounts will appear here for recovery.',
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 16, bottom: 24),
                          itemCount: users.length,
                          itemBuilder: (context, i) {
                            final user = users[i];
                            return _UserCard(
                              user: user,
                              onEditPermissions: () => _openUserSheet(user),
                              onEnable: () => adminEnableUser(
                                user['id'].toString(),
                              ),
                              onDelete: () => _showDeleteDialog(
                                context,
                                title: 'Delete User',
                                content:
                                    "Move '${(user['fullName'] ?? user['email']).toString()}' to trash? You can recover the profile later from Recovery Center.",
                                onConfirm: () => adminDeleteUser(
                                  user['id'].toString(),
                                  deletedBy: currentUser?.uid,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: FloatingActionButton.extended(
            backgroundColor: kNavy,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text(
              'Create User',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            onPressed: _openUserSheet,
          ),
        ),
      ],
    );
  }
}

enum _UserMenuAction { editPermissions, disable, enable, delete }

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onEditPermissions,
    this.onDisable,
    this.onEnable,
    required this.onDelete,
  });

  final Map<String, dynamic> user;
  final VoidCallback onEditPermissions;
  final VoidCallback? onDisable;
  final VoidCallback? onEnable;
  final VoidCallback? onDelete;

  static Color _roleColor(String role) => switch (role.toLowerCase()) {
    'admin' => Colors.deepPurple,
    'instructor' => Colors.blue,
    _ => Colors.teal,
  };

  static IconData _roleIcon(String role) => switch (role.toLowerCase()) {
    'admin' => Icons.admin_panel_settings,
    'instructor' => Icons.school,
    _ => Icons.person,
  };

  @override
  Widget build(BuildContext context) {
    final name = (user['fullName'] ?? 'No name').toString();
    final email = (user['email'] ?? '').toString();
    final role = (user['role'] ?? 'student').toString();
    final section = (user['section'] ?? '').toString();
    final year = (user['yearLevel'] ?? '').toString();
    final avatar = (user['avatarUrl'] ?? '').toString();
    final roleColor = _roleColor(role);
    final isDisabled = user['isDisabled'] == true;
    const hasActions = true;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: roleColor.withValues(alpha: 0.12),
          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
          child: avatar.isEmpty
              ? Icon(_roleIcon(role), color: roleColor, size: 20)
              : null,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: kNavy,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  DashboardTag(label: role, color: roleColor),
                  if (isDisabled)
                    const DashboardTag(
                      label: 'Disabled',
                      color: Colors.redAccent,
                      icon: Icons.block_outlined,
                    ),
                  if (year.isNotEmpty || section.isNotEmpty)
                    DashboardTag(
                      label: [
                        if (year.isNotEmpty) 'Year $year',
                        if (section.isNotEmpty) section,
                      ].join(' • '),
                      color: Colors.blueGrey,
                    ),
                ],
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<_UserMenuAction>(
              enabled: hasActions,
              tooltip: 'User actions',
              icon: const Icon(Icons.more_vert, color: kNavy),
              onSelected: (action) {
                switch (action) {
                  case _UserMenuAction.editPermissions:
                    onEditPermissions();
                    break;
                  case _UserMenuAction.disable:
                    onDisable?.call();
                    break;
                  case _UserMenuAction.enable:
                    onEnable?.call();
                    break;
                  case _UserMenuAction.delete:
                    onDelete?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<_UserMenuAction>(
                  value: _UserMenuAction.editPermissions,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.manage_accounts_outlined),
                    title: Text('Edit permissions'),
                  ),
                ),
                if (!isDisabled)
                  PopupMenuItem<_UserMenuAction>(
                    value: _UserMenuAction.disable,
                    enabled: onDisable != null,
                    child: const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.block_outlined),
                      title: Text('Disable'),
                    ),
                  ),
                if (isDisabled)
                  PopupMenuItem<_UserMenuAction>(
                    value: _UserMenuAction.enable,
                    enabled: onEnable != null,
                    child: const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.check_circle_outline),
                      title: Text('Enable'),
                    ),
                  ),
                PopupMenuItem<_UserMenuAction>(
                    value: _UserMenuAction.delete,
                    enabled: onDelete != null,
                    child: const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      title: Text('Delete'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminUploadsTab extends ConsumerWidget {
  const _AdminUploadsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(adminTasksProvider);
    final lessonsAsync = ref.watch(adminLessonsProvider);
    final reviewersAsync = ref.watch(adminReviewersProvider);
    final classesAsync = ref.watch(allClassesProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Tasks'),
              Tab(text: 'Lessons'),
              Tab(text: 'Reviewers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                tasksAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: kNavy),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return const DashboardEmptyState(
                        icon: Icons.assignment_outlined,
                        title: 'No tasks uploaded yet',
                        message:
                            'Task and quiz items will appear here for admin review.',
                      );
                    }

                    final classesById = {
                      for (final cls
                          in (classesAsync.value ?? const <ClassModel>[]))
                        cls.id: cls,
                    };
                    final availableClasses = classesById.values.toList();

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 16, bottom: 24),
                      itemCount: tasks.length,
                      itemBuilder: (context, i) {
                        final task = tasks[i];
                        final classLabel =
                            classesById[task['classId']]?.className ??
                            'Unassigned';
                        final deadline = _formatDate(task['deadline']);
                        final titleCtrl = TextEditingController(
                          text: (task['title'] ?? '').toString(),
                        );
                        final descCtrl = TextEditingController(
                          text: (task['description'] ?? '').toString(),
                        );
                        final scoreCtrl = TextEditingController(
                          text: (task['maxScore'] ?? 0).toString(),
                        );

                        return _AdminContentCard(
                          icon: Icons.assignment_outlined,
                          iconBg: kNavy.withValues(alpha: 0.08),
                          iconColor: kNavy,
                          title: (task['title'] ?? 'Untitled').toString(),
                          subtitle: (task['description'] ?? '').toString(),
                          chips: [
                            DashboardTag(label: classLabel, color: kNavy),
                            DashboardTag(
                              label:
                                  '${(task['maxScore'] ?? 0).toString()} pts',
                              color: Colors.orange.shade800,
                            ),
                            if (deadline != null)
                              DashboardTag(
                                label: deadline,
                                color: kMaroon,
                                icon: Icons.schedule,
                              ),
                          ],
                          onEdit: () => _showTaskEditSheet(
                            context,
                            taskId: task['id'].toString(),
                            titleCtrl: titleCtrl,
                            descCtrl: descCtrl,
                            scoreCtrl: scoreCtrl,
                            initialClassId: task['classId']?.toString() ?? '',
                            initialDeadline: _taskDate(task['deadline']),
                            classes: availableClasses,
                          ),
                          onDelete: () => _showDeleteDialog(
                            context,
                            title: 'Delete Task',
                            content:
                                "Move '${(task['title'] ?? 'Untitled').toString()}' to trash?",
                            onConfirm: () => adminDeleteTask(
                              task['id'].toString(),
                              deletedBy: currentUser?.uid,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                lessonsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: kNavy),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (lessons) {
                    if (lessons.isEmpty) {
                      return const DashboardEmptyState(
                        icon: Icons.menu_book_outlined,
                        title: 'No lessons uploaded yet',
                        message:
                            'Uploaded curriculum materials will appear here for editing and recovery.',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 16, bottom: 24),
                      itemCount: lessons.length,
                      itemBuilder: (context, i) {
                        final lesson = lessons[i];
                        final titleCtrl = TextEditingController(
                          text: (lesson['title'] ?? '').toString(),
                        );
                        final descCtrl = TextEditingController(
                          text: (lesson['description'] ?? '').toString(),
                        );
                        final subjectCtrl = TextEditingController(
                          text: (lesson['subject'] ?? lesson['category'] ?? '')
                              .toString(),
                        );
                        return _AdminContentCard(
                          icon: Icons.menu_book,
                          iconBg: kNavy.withValues(alpha: 0.08),
                          iconColor: kNavy,
                          title: (lesson['title'] ?? 'Untitled').toString(),
                          subtitle: (lesson['description'] ?? '').toString(),
                          chips: [
                            if ((lesson['subject'] ?? '').toString().isNotEmpty)
                              DashboardTag(
                                label: lesson['subject'].toString(),
                                color: kNavy,
                              ),
                            if ((lesson['videoUrl'] ?? '')
                                .toString()
                                .isNotEmpty)
                              const DashboardTag(
                                label: 'Video',
                                color: Colors.blue,
                              ),
                            if ((lesson['pdfUrl'] ?? '').toString().isNotEmpty)
                              const DashboardTag(
                                label: 'PDF',
                                color: Colors.red,
                              ),
                          ],
                          onEdit: () => _showEditSheet(
                            context,
                            title: 'Edit Lesson',
                            fields: [
                              _AdminOutlineField(
                                controller: titleCtrl,
                                label: 'Title',
                              ),
                              const SizedBox(height: 12),
                              _AdminOutlineField(
                                controller: descCtrl,
                                label: 'Description',
                                maxLines: 3,
                              ),
                              const SizedBox(height: 12),
                              _AdminOutlineField(
                                controller: subjectCtrl,
                                label: 'Subject',
                              ),
                            ],
                            onSubmit: () =>
                                adminUpdateLesson(lesson['id'].toString(), {
                                  'title': titleCtrl.text.trim(),
                                  'description': descCtrl.text.trim(),
                                  'subject': subjectCtrl.text.trim(),
                                }),
                          ),
                          onDelete: () => _showDeleteDialog(
                            context,
                            title: 'Delete Lesson',
                            content:
                                "Move '${(lesson['title'] ?? 'Untitled').toString()}' to trash?",
                            onConfirm: () => adminDeleteLesson(
                              lesson['id'].toString(),
                              deletedBy: currentUser?.uid,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                reviewersAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: kNavy),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (reviewers) {
                    if (reviewers.isEmpty) {
                      return const DashboardEmptyState(
                        icon: Icons.picture_as_pdf_outlined,
                        title: 'No reviewers uploaded yet',
                        message:
                            'Reviewer PDFs will appear here for admin editing and recovery.',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 16, bottom: 24),
                      itemCount: reviewers.length,
                      itemBuilder: (context, i) {
                        final reviewer = reviewers[i];
                        final titleCtrl = TextEditingController(
                          text: (reviewer['title'] ?? '').toString(),
                        );
                        final subjectCtrl = TextEditingController(
                          text:
                              (reviewer['subject'] ??
                                      reviewer['category'] ??
                                      '')
                                  .toString(),
                        );
                        return _AdminContentCard(
                          icon: Icons.picture_as_pdf,
                          iconBg: Colors.red.shade50,
                          iconColor: Colors.red,
                          title: (reviewer['title'] ?? 'Untitled').toString(),
                          subtitle:
                              (reviewer['subject'] ??
                                      reviewer['category'] ??
                                      '')
                                  .toString(),
                          chips: const [
                            DashboardTag(label: 'PDF', color: Colors.red),
                          ],
                          onEdit: () => _showEditSheet(
                            context,
                            title: 'Edit Reviewer',
                            fields: [
                              _AdminOutlineField(
                                controller: titleCtrl,
                                label: 'Title',
                              ),
                              const SizedBox(height: 12),
                              _AdminOutlineField(
                                controller: subjectCtrl,
                                label: 'Subject',
                              ),
                            ],
                            onSubmit: () =>
                                adminUpdateReviewer(reviewer['id'].toString(), {
                                  'title': titleCtrl.text.trim(),
                                  'subject': subjectCtrl.text.trim(),
                                }),
                          ),
                          onDelete: () => _showDeleteDialog(
                            context,
                            title: 'Delete Reviewer',
                            content:
                                "Move '${(reviewer['title'] ?? 'Untitled').toString()}' to trash?",
                            onConfirm: () => adminDeleteReviewer(
                              reviewer['id'].toString(),
                              deletedBy: currentUser?.uid,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(
    BuildContext context, {
    required String title,
    required List<Widget> fields,
    required Future<void> Function() onSubmit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AdminFormSheet(
        title: title,
        subtitle: 'Update the selected content item.',
        fields: fields,
        buttonLabel: 'SAVE CHANGES',
        buttonColor: Colors.blueAccent,
        onSubmit: onSubmit,
      ),
    );
  }

  void _showTaskEditSheet(
    BuildContext context, {
    required String taskId,
    required TextEditingController titleCtrl,
    required TextEditingController descCtrl,
    required TextEditingController scoreCtrl,
    required String initialClassId,
    required DateTime initialDeadline,
    required List<ClassModel> classes,
  }) {
    var selectedClassId = initialClassId;
    var selectedDeadline = initialDeadline;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => _AdminFormSheet(
          title: 'Edit Task',
          subtitle: 'Update the selected task, class, score, and deadline.',
          fields: [
            _AdminOutlineField(controller: titleCtrl, label: 'Title'),
            const SizedBox(height: 12),
            _AdminOutlineField(
              controller: descCtrl,
              label: 'Description',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _AdminOutlineField(
              controller: scoreCtrl,
              label: 'Maximum Score',
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedClassId.isEmpty ? null : selectedClassId,
              decoration: const InputDecoration(labelText: 'Assigned Class'),
              items: classes
                  .map(
                    (cls) => DropdownMenuItem(
                      value: cls.id,
                      child: Text('${cls.className} · ${cls.subject}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setSheet(() => selectedClassId = value ?? ''),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDeadline,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setSheet(() => selectedDeadline = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Deadline',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(_formatDate(selectedDeadline) ?? ''),
              ),
            ),
          ],
          buttonLabel: 'SAVE CHANGES',
          buttonColor: Colors.blueAccent,
          onSubmit: () {
            final maxScore = int.tryParse(scoreCtrl.text.trim());
            if (titleCtrl.text.trim().isEmpty) {
              throw Exception('Task title is required.');
            }
            if (maxScore == null) {
              throw Exception('Maximum score must be a valid number.');
            }
            if (selectedClassId.isEmpty) {
              throw Exception('Select a class for this task.');
            }
            return adminUpdateTask(taskId, {
              'title': titleCtrl.text.trim(),
              'description': descCtrl.text.trim(),
              'maxScore': maxScore,
              'classId': selectedClassId,
              'deadline': Timestamp.fromDate(selectedDeadline),
            });
          },
        ),
      ),
    );
  }
}

class _AdminContentCard extends StatelessWidget {
  const _AdminContentCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.chips,
    this.onEdit,
    required this.onDelete,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Widget> chips;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, color: kNavy),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: chips),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                onPressed: onEdit,
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

void _showDeleteDialog(
  BuildContext context, {
  required String title,
  required String content,
  required Future<void> Function() onConfirm,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () async {
            Navigator.pop(ctx);
            await onConfirm();
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

String? _formatDate(dynamic raw) {
  if (raw is Timestamp) {
    final value = raw.toDate();
    return '${value.month}/${value.day}/${value.year}';
  }
  if (raw is DateTime) {
    return '${raw.month}/${raw.day}/${raw.year}';
  }
  return null;
}

DateTime _taskDate(dynamic raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
  return DateTime.now();
}

class _AdminFormSheet extends StatelessWidget {
  const _AdminFormSheet({
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onSubmit,
  });

  final String title;
  final String subtitle;
  final List<Widget> fields;
  final String buttonLabel;
  final Color buttonColor;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: kNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            ...fields,
            const SizedBox(height: 18),
            _SubmitButton(
              label: buttonLabel,
              color: buttonColor,
              onSubmit: onSubmit,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  const _SubmitButton({
    required this.label,
    required this.color,
    required this.onSubmit,
  });

  final String label;
  final Color color;
  final Future<void> Function() onSubmit;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: widget.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                try {
                  await widget.onSubmit();
                  if (mounted) {
                    navigator.pop();
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _loading = false);
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}

class _AdminOutlineField extends StatelessWidget {
  const _AdminOutlineField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboard,
    this.caps = TextCapitalization.sentences,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboard;
  final TextCapitalization caps;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      textCapitalization: caps,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['student', 'instructor', 'admin'].map((role) {
        final isSelected = selected == role;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? kNavy : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? kNavy : Colors.grey.shade300,
                ),
              ),
              child: Text(
                role[0].toUpperCase() + role.substring(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
