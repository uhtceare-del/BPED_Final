import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/lesson_model.dart';
import '../widgets/dashboard_module.dart';
import '../widgets/pdf_viewer_widget.dart';
import '../widgets/video_player_widget.dart';

class LessonDetailScreen extends StatelessWidget {
  final LessonModel lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final hasVideo = lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty;
    final hasPdf = lesson.pdfUrl != null && lesson.pdfUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DashboardModulePage(
            title: 'Lesson Details',
            subtitle: 'Open the attached curriculum materials for this lesson.',
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                DashboardSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          color: kNavy,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (lesson.category != null &&
                          lesson.category!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (lesson.subject.trim().isNotEmpty)
                                _InfoChip(
                                  icon: Icons.subject_outlined,
                                  label: lesson.subject.trim(),
                                ),
                              _InfoChip(
                                icon: Icons.category_outlined,
                                label: lesson.category!.trim(),
                              ),
                            ],
                          ),
                        ),
                      if (lesson.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          lesson.description,
                          style: TextStyle(
                            color: Colors.blueGrey.shade700,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (hasVideo)
                  _ActionCard(
                    icon: Icons.play_circle_fill_outlined,
                    title: 'Watch Lesson Video',
                    subtitle: 'Open the uploaded lesson video player.',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerWidget(
                            title: lesson.title,
                            urlOrPath: lesson.videoUrl!,
                            isOffline: false,
                          ),
                        ),
                      );
                    },
                  ),
                if (hasPdf)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _ActionCard(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'Open Lesson PDF',
                      subtitle: 'View the uploaded PDF material.',
                      color: Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfViewerWidget(
                              title: lesson.title,
                              urlOrPath: lesson.pdfUrl!,
                              isOffline: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (!hasVideo && !hasPdf)
                  const DashboardSectionCard(
                    child: Row(
                      children: [
                        Icon(Icons.text_snippet_outlined, color: kNavy),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This lesson currently has no attached video or PDF.',
                            style: TextStyle(color: kNavy),
                          ),
                        ),
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
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: kNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.blueGrey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kNavy),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: kNavy,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
