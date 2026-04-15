import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/offline_material_model.dart';
import '../providers/offline_provider.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/pdf_viewer_widget.dart';
import '../constants/app_colors.dart';
import '../widgets/dashboard_module.dart';

class OfflineDownloadsScreen extends ConsumerWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We grab the Hive box we opened in main.dart
    final box = Hive.box('downloadsBox');

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DashboardModulePage(
            title: 'My Offline Files',
            subtitle:
                'Open downloaded materials directly from local storage or remove them from this device.',
            child: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box currentBox, _) {
                if (currentBox.isEmpty) {
                  return const DashboardEmptyState(
                    icon: Icons.download_for_offline_outlined,
                    title: 'No offline materials yet',
                    message:
                        'Download lessons or reviewers from your classes to keep them available offline.',
                  );
                }

                final materials = currentBox.values
                    .cast<OfflineMaterial>()
                    .toList();

                return ListView.builder(
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    final isVideo = material.localFilePath.endsWith('.mp4');

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: isVideo
                              ? Colors.blue.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            isVideo
                                ? Icons.play_circle_fill
                                : Icons.picture_as_pdf,
                            color: isVideo ? Colors.blue : Colors.red,
                          ),
                        ),
                        title: Text(
                          material.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: kNavy,
                          ),
                        ),
                        subtitle: const Text('Available offline'),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Remove from device',
                          onPressed: () {
                            ref
                                .read(offlineStorageProvider)
                                .deleteFile(material.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${material.title} removed.'),
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          if (isVideo) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoPlayerWidget(
                                  title: material.title,
                                  urlOrPath: material.localFilePath,
                                  isOffline: true,
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfViewerWidget(
                                  title: material.title,
                                  urlOrPath: material.localFilePath,
                                  isOffline: true,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
