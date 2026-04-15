import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import 'dashboard_module.dart';
import 'pdf_file_loader_stub.dart'
    if (dart.library.io) 'pdf_file_loader_io.dart';

class PdfViewerWidget extends StatefulWidget {
  final String title;
  final String urlOrPath;
  final bool isOffline;

  const PdfViewerWidget({
    super.key,
    required this.title,
    required this.urlOrPath,
    this.isOffline = false,
  });

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  late final Future<_PdfAvailability> _availabilityFuture =
      _checkAvailability();

  Future<_PdfAvailability> _checkAvailability() async {
    try {
      if (widget.isOffline) {
        if (widget.urlOrPath.startsWith('http')) {
          final response = await http.get(Uri.parse(widget.urlOrPath));
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return _PdfAvailability.remote();
          }
          return _PdfAvailability.error(
            'PDF is not available right now. Server returned ${response.statusCode}.',
          );
        }
        await loadPdfFileBytes(widget.urlOrPath);
        return _PdfAvailability.local();
      }

      final response = await http.get(Uri.parse(widget.urlOrPath));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _PdfAvailability.remote();
      }
      return _PdfAvailability.error(
        'PDF is not available right now. Server returned ${response.statusCode}.',
      );
    } catch (e) {
      return _PdfAvailability.error('Could not load PDF: $e');
    }
  }

  Future<void> _openPdfInBrowser() async {
    final uri = Uri.parse(widget.urlOrPath);
    final didLaunch = await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!didLaunch && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the PDF in a new tab.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Uint8List> _loadRemoteBytes() async {
    final response = await http.get(Uri.parse(widget.urlOrPath));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  Widget _buildOfflineBody() {
    final isRemoteRecord = widget.urlOrPath.startsWith('http');
    final bytesFuture = isRemoteRecord
        ? _loadRemoteBytes()
        : loadPdfFileBytes(widget.urlOrPath);

    return FutureBuilder<Uint8List>(
      future: bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: kNavy));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _PdfStateCard(
            icon: Icons.error_outline,
            title: 'PDF Unavailable',
            message: 'Could not load PDF: ${snapshot.error ?? 'Unknown error'}',
          );
        }
        return SfPdfViewer.memory(snapshot.data!);
      },
    );
  }

  Widget _buildWebRemoteBody() {
    return FutureBuilder<_PdfAvailability>(
      future: _availabilityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PdfStateCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Checking PDF',
            message: 'Verifying that the file is available.',
          );
        }

        final availability = snapshot.data;
        if (availability == null || availability.errorMessage != null) {
          return _PdfStateCard(
            icon: Icons.error_outline,
            title: 'PDF Unavailable',
            message: availability?.errorMessage ?? 'Could not load PDF.',
          );
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: kNavy.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: kNavy,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PDF Ready',
                    style: TextStyle(
                      color: kNavy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open the file in a browser tab for the best web viewing experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey.shade700),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: kNavy),
                    onPressed: _openPdfInBrowser,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open PDF'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.isOffline
        ? _buildOfflineBody()
        : kIsWeb
        ? _buildWebRemoteBody()
        : SfPdfViewer.network(widget.urlOrPath);

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DashboardModulePage(
            title: widget.title,
            subtitle: widget.isOffline
                ? 'Offline PDF viewer'
                : 'Open and read the attached PDF material.',
            child: DashboardSectionCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PdfAvailability {
  final String? errorMessage;

  const _PdfAvailability._({required this.errorMessage});

  factory _PdfAvailability.local() =>
      const _PdfAvailability._(errorMessage: null);

  factory _PdfAvailability.remote() =>
      const _PdfAvailability._(errorMessage: null);

  factory _PdfAvailability.error(String message) =>
      _PdfAvailability._(errorMessage: message);
}

class _PdfStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _PdfStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kNavy.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: kNavy, size: 42),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: kNavy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
