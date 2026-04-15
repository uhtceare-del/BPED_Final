import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../widgets/dashboard_module.dart';

class ClassScreen extends ConsumerWidget {
  const ClassScreen({super.key});

  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(allClassesProvider);

    return DashboardModulePage(
      title: 'Classes',
      subtitle:
          'Manage class sections, schedules, join codes, and roster access from one consistent workspace.',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kNavy,
        onPressed: () => _showCreateSheet(context, ref),
        label: const Text('New Class', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      child: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return DashboardEmptyState(
              icon: Icons.class_outlined,
              title: 'No classes yet',
              message:
                  'Create a class section to generate a join code and start organizing curriculum and submissions.',
              action: FilledButton.icon(
                onPressed: () => _showCreateSheet(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Create class'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final cls = classes[index];
              return _ClassCard(
                cls: cls,
                onTap: () => _showRosterSheet(context, ref, cls),
                onEdit: () => _showEditSheet(context, ref, cls),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kNavy)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final schedCtrl = TextEditingController();
    final code = _generateCode();
    String semLabel = '1st Semester';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) {
          bool saving = false;
          return _sheet(
            ctx: ctx,
            title: 'Create New Class',
            content: [
              _field(
                nameCtrl,
                'Class Name (e.g. BPED 2-A)',
                caps: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              _field(subjectCtrl, 'Subject'),
              const SizedBox(height: 12),
              _field(schedCtrl, 'Schedule (e.g. Mon/Wed 1:00PM)'),
              const SizedBox(height: 16),
              _semPicker(semLabel, (v) => ss(() => semLabel = v)),
              const SizedBox(height: 16),
              _codeBox(ctx, code),
            ],
            buttonLabel: 'CREATE CLASS',
            buttonColor: kNavy,
            saving: saving,
            onTap: () async {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Class name required.')),
                );
                return;
              }
              ss(() => saving = true);
              try {
                await ref
                    .read(classRepositoryProvider)
                    .createClass(
                      ClassModel(
                        id: '',
                        className: nameCtrl.text.trim(),
                        subject: subjectCtrl.text.trim(),
                        schedule: schedCtrl.text.trim(),
                        classCode: code,
                        semesterLabel: semLabel,
                        instructorId: '',
                        enrolledStudentIds: const [],
                      ),
                    );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              } catch (e) {
                ss(() => saving = false);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
          );
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, ClassModel cls) {
    final nameCtrl = TextEditingController(text: cls.className);
    final subjectCtrl = TextEditingController(text: cls.subject);
    final schedCtrl = TextEditingController(text: cls.schedule);
    String semLabel = cls.semesterLabel.isNotEmpty
        ? cls.semesterLabel
        : '1st Semester';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) {
          bool saving = false;
          return _sheet(
            ctx: ctx,
            title: 'Edit Class',
            content: [
              _field(
                nameCtrl,
                'Class Name',
                caps: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              _field(subjectCtrl, 'Subject'),
              const SizedBox(height: 12),
              _field(schedCtrl, 'Schedule'),
              const SizedBox(height: 16),
              _semPicker(semLabel, (v) => ss(() => semLabel = v)),
              const SizedBox(height: 16),
              _codeBox(ctx, cls.classCode),
            ],
            buttonLabel: 'SAVE CHANGES',
            buttonColor: Colors.blueAccent,
            saving: saving,
            onTap: () async {
              ss(() => saving = true);
              try {
                await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(cls.id)
                    .update({
                      'className': nameCtrl.text.trim(),
                      'subject': subjectCtrl.text.trim(),
                      'schedule': schedCtrl.text.trim(),
                      'semesterLabel': semLabel,
                    });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              } catch (e) {
                ss(() => saving = false);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
          );
        },
      ),
    );
  }

  void _showRosterSheet(BuildContext context, WidgetRef ref, ClassModel cls) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (ctx, sc) => _RosterSheet(cls: cls, scrollController: sc),
      ),
    );
  }

  Widget _sheet({
    required BuildContext ctx,
    required String title,
    required List<Widget> content,
    required String buttonLabel,
    required Color buttonColor,
    required bool saving,
    required VoidCallback onTap,
  }) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
      top: 28,
      left: 24,
      right: 24,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handle(),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kNavy,
            ),
          ),
          const SizedBox(height: 16),
          ...content,
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: saving ? null : onTap,
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      buttonLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  Widget _handle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextCapitalization caps = TextCapitalization.sentences,
  }) => TextField(
    controller: ctrl,
    textCapitalization: caps,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );

  Widget _semPicker(String selected, ValueChanged<String> onChange) => Row(
    children: ['1st Semester', '2nd Semester'].map((s) {
      final sel = selected == s;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChange(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? kNavy : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sel ? kNavy : Colors.grey.shade300),
            ),
            child: Text(
              s,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: sel ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _codeBox(BuildContext ctx, String code) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kNavySurface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: kNavyBorder),
    ),
    child: Row(
      children: [
        const Icon(Icons.vpn_key_outlined, size: 18, color: kNavy),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Class Join Code',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                code,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: kNavy,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18, color: kNavy),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('Code copied!'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    ),
  );
}

class _ClassCard extends StatelessWidget {
  final ClassModel cls;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ClassCard({
    required this.cls,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kNavySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.groups, color: kNavy, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cls.className,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kNavy,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${cls.subject} • ${cls.schedule}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                    onPressed: onEdit,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (cls.semesterLabel.isNotEmpty)
                    DashboardTag(
                      label: cls.semesterLabel,
                      color: Colors.green.shade700,
                    ),
                  DashboardTag(
                    label: '${cls.enrolledStudentIds.length} students',
                    color: kNavy,
                    icon: Icons.people_outline,
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: cls.classCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copied!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: DashboardTag(
                      label: cls.classCode,
                      color: kMaroon,
                      icon: Icons.vpn_key_outlined,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 11,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to view roster',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
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

class _RosterSheet extends ConsumerWidget {
  final ClassModel cls;
  final ScrollController scrollController;

  const _RosterSheet({required this.cls, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsInClassProvider(cls.id));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cls.className,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kNavy,
                      ),
                    ),
                    Text(
                      '${cls.subject} • ${cls.schedule}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: cls.classCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Code copied!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kNavySurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kNavyBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.vpn_key_outlined,
                        size: 14,
                        color: kNavy,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cls.classCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: kNavy,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.copy_outlined, size: 13, color: kNavy),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (cls.semesterLabel.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Text(
                cls.semesterLabel,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 14,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 6),
                Text(
                  'ROSTER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
                const Spacer(),
                studentsAsync.when(
                  data: (s) => Text(
                    '${s.length} enrolled',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No students enrolled yet.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share code "${cls.classCode}" with students.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: students.length,
                  itemBuilder: (context, i) {
                    final s = students[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: kNavyTint,
                        backgroundImage: s.avatarUrl.isNotEmpty
                            ? NetworkImage(s.avatarUrl)
                            : null,
                        child: s.avatarUrl.isEmpty
                            ? const Icon(Icons.person, color: kNavy, size: 18)
                            : null,
                      ),
                      title: Text(
                        s.fullName ?? s.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        s.email,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        tooltip: 'Remove from class',
                        onPressed: () => _confirmRemove(context, ref, s),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: kNavy)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, AppUser student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove Student',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Remove ${student.fullName ?? student.email} from this class?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(classRepositoryProvider)
                  .unenrollStudent(classId: cls.id, studentId: student.uid);
              ref.invalidate(studentsInClassProvider(cls.id));
            },
            child: const Text('REMOVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
