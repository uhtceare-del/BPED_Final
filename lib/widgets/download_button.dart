import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/offline_provider.dart';

final _downloadedIdsProvider =
    StateNotifierProvider<_DownloadedIdsNotifier, Set<String>>((ref) {
      ref.keepAlive();
      final service = ref.read(offlineStorageProvider);
      final existing = service
          .getDownloadedMaterials()
          .map((m) => m.id)
          .toSet();
      return _DownloadedIdsNotifier(existing);
    });

class _DownloadedIdsNotifier extends StateNotifier<Set<String>> {
  _DownloadedIdsNotifier(super.state);

  void add(String id) => state = {...state, id};

  void remove(String id) => state = {...state}..remove(id);
}

class DownloadButton extends ConsumerStatefulWidget {
  final String materialId;
  final String title;
  final String url;
  final String fileExtension; // e.g., '.pdf' or '.mp4'

  const DownloadButton({
    super.key,
    required this.materialId,
    required this.title,
    required this.url,
    required this.fileExtension,
  });

  @override
  ConsumerState<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends ConsumerState<DownloadButton> {
  bool _isDownloading = false;
  double _progress = 0;

  Future<void> _download() async {
    if (kIsWeb) {
      final uri = Uri.parse(widget.url);
      await launchUrl(uri, mode: LaunchMode.platformDefault);
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0;
    });

    try {
      await ref
          .read(offlineStorageProvider)
          .downloadFile(
            id: widget.materialId,
            title: widget.title,
            url: widget.url,
            fileExtension: widget.fileExtension,
            onProgress: (progress) {
              if (mounted) {
                setState(() => _progress = progress);
              }
            },
          );

      ref.read(_downloadedIdsProvider.notifier).add(widget.materialId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved for offline use!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _showDownloadedActions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              const Text('This file is already saved for offline use.'),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.refresh),
                title: const Text('Re-download'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref
                      .read(offlineStorageProvider)
                      .deleteFile(widget.materialId);
                  ref
                      .read(_downloadedIdsProvider.notifier)
                      .remove(widget.materialId);
                  await _download();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Remove from device',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref
                      .read(offlineStorageProvider)
                      .deleteFile(widget.materialId);
                  ref
                      .read(_downloadedIdsProvider.notifier)
                      .remove(widget.materialId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.title} removed from device.'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offlineService = ref.watch(offlineStorageProvider);
    final downloadedIds = ref.watch(_downloadedIdsProvider);
    final isDownloaded =
        downloadedIds.contains(widget.materialId) ||
        offlineService.isDownloaded(widget.materialId);

    if (kIsWeb) {
      return IconButton(
        icon: const Icon(Icons.open_in_browser_outlined),
        tooltip: 'Open / Download',
        onPressed: _download,
      );
    }

    if (isDownloaded) {
      return IconButton(
        icon: const Icon(Icons.check_circle, color: Colors.green),
        tooltip: 'Available Offline',
        onPressed: _showDownloadedActions,
      );
    }

    if (_isDownloading) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            value: _progress > 0 ? _progress : null,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.download),
      tooltip: 'Download for offline use',
      onPressed: _download,
    );
  }
}
