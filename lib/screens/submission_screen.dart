import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/submission_model.dart';
import '../providers/submission_provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/dashboard_module.dart';

class SubmissionScreen extends ConsumerWidget {
  const SubmissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(securedSubmissionsProvider);
    final user = ref.watch(currentUserProvider).value;
    final isInstructor = user?.role.toLowerCase() == 'instructor';

    return DashboardModulePage(
      title: 'Submissions',
      subtitle: isInstructor
          ? 'Review student uploads, open files, and grade submitted work.'
          : 'Track the work you have already submitted and check grading status.',
      child: submissionsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kNavy)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (submissions) {
          if (submissions.isEmpty) {
            return DashboardEmptyState(
              icon: Icons.assignment_turned_in_outlined,
              title: 'No submissions found',
              message: isInstructor
                  ? 'Student uploads will appear here once tasks start receiving responses.'
                  : 'Your submitted work will appear here after you turn in a task.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final sub = submissions[index];
              final isGraded = sub.grade != null && sub.grade!.isNotEmpty;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  title: Text(
                    sub.studentEmail,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: kNavy,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        DashboardTag(
                          label:
                              'Submitted ${sub.submittedAt.day}/${sub.submittedAt.month}/${sub.submittedAt.year}',
                          color: kNavy,
                          icon: Icons.schedule_outlined,
                        ),
                        DashboardTag(
                          label: isGraded ? 'Graded' : 'Awaiting grade',
                          color: isGraded
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                          icon: Icons.grading_outlined,
                        ),
                      ],
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: isGraded
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                  ),
                  onTap: () => _showGradingDialog(context, ref, sub),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showGradingDialog(
    BuildContext context,
    WidgetRef ref,
    SubmissionModel submission,
  ) {
    final gradeController = TextEditingController(text: submission.grade);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Review Submission',
          style: TextStyle(color: kNavy, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (submission.fileUrl != null) ...[
              DashboardSectionCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student file',
                      style: TextStyle(
                        color: kNavy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      submission.studentEmail,
                      style: TextStyle(color: Colors.blueGrey.shade700),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () =>
                          launchUrl(Uri.parse(submission.fileUrl!)),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Student File'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: gradeController,
              decoration: const InputDecoration(
                labelText: 'Grade (e.g. 95/100)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(submissionRepositoryProvider)
                  .updateGrade(submission.id, gradeController.text);
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Grade saved successfully.')),
              );
            },
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );
  }
}
