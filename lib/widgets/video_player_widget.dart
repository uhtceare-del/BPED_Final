import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../constants/app_colors.dart';
import 'dashboard_module.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String title;
  final String urlOrPath;
  final bool isOffline;

  const VideoPlayerWidget({
    super.key,
    required this.title,
    required this.urlOrPath,
    this.isOffline = false,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final primaryColor = Theme.of(context).primaryColor;

    // 1. Choose the data source
    if (widget.isOffline) {
      _videoPlayerController = VideoPlayerController.file(
        File(widget.urlOrPath),
      );
    } else {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.urlOrPath),
      );
    }

    // 2. Initialize the player
    await _videoPlayerController.initialize();

    // 3. Wrap it in Chewie for the UI controls
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: primaryColor,
        handleColor: primaryColor,
        backgroundColor: Colors.grey.shade300,
        bufferedColor: Colors.grey.shade400,
      ),
    );

    // Rebuild the UI now that the video is ready
    setState(() {});
  }

  @override
  void dispose() {
    // ALWAYS dispose controllers to prevent memory leaks
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DashboardModulePage(
            title: widget.title,
            subtitle: widget.isOffline
                ? 'Offline video player'
                : 'Watch the attached lesson video.',
            child: DashboardSectionCard(
              padding: const EdgeInsets.all(12),
              child: Container(
                color: Colors.black,
                child: Center(
                  child:
                      _chewieController != null &&
                          _chewieController!
                              .videoPlayerController
                              .value
                              .isInitialized
                      ? Chewie(controller: _chewieController!)
                      : const CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
