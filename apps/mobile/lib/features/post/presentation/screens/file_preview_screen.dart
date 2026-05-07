// SPEC-0007: File Preview Screen
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:video_player/video_player.dart';

/// Named record used as GoRouter extra when navigating to [FilePreviewScreen].
typedef FilePreviewArgs = ({
  String url,

  /// One of: "image", "pdf", "video" — anything else shows [_UnsupportedViewer].
  String type,
  String filename,
});

// ---------------------------------------------------------------------------
// Top-level helper — public so unit tests can import it directly.
// ---------------------------------------------------------------------------

/// Returns the local file-system path where a video should be cached.
///
/// Strips query-string parameters from [url] so the filename is stable across
/// signed URLs that change on every fetch.
Future<String> videoCachePath(String url) async {
  final dir = await getTemporaryDirectory();
  final filename = url.split('/').last.split('?').first;
  return '${dir.path}/unishare_video/$filename';
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class FilePreviewScreen extends StatelessWidget {
  const FilePreviewScreen({
    super.key,
    required this.url,
    required this.type,
    required this.filename,
  });

  final String url;
  final String type;
  final String filename;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      'image' => _ImageViewer(url: url, filename: filename),
      'pdf' => _PdfViewer(url: url, filename: filename),
      'video' => _VideoViewer(url: url, filename: filename),
      _ => _UnsupportedViewer(filename: filename),
    };
  }
}

// ---------------------------------------------------------------------------
// Image viewer
// ---------------------------------------------------------------------------

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({required this.url, required this.filename});

  final String url;
  final String filename;

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetZoom() => _controller.value = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.filename,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onDoubleTap: _resetZoom,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                transformationController: _controller,
                child: CachedNetworkImage(
                  imageUrl: widget.url,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Pinch to zoom',
              style: TextStyle(
                color: appColors?.textMuted ?? Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PDF viewer
// ---------------------------------------------------------------------------

class _PdfViewer extends StatefulWidget {
  const _PdfViewer({required this.url, required this.filename});

  final String url;
  final String filename;

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  late PdfViewerController _pdfController;
  int _currentPage = 0;
  int _pageCount = 0;
  bool _hasError = false;
  int _reloadKey = 0;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _pdfController.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final page = _pdfController.pageNumber ?? 0;
    final count = _pdfController.isReady ? _pdfController.pageCount : 0;
    if (page != _currentPage || count != _pageCount) {
      setState(() {
        _currentPage = page;
        _pageCount = count;
      });
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _reloadKey++;
      _pdfController.removeListener(_onControllerChanged);
      _pdfController = PdfViewerController();
      _pdfController.addListener(_onControllerChanged);
    });
  }

  @override
  void dispose() {
    _pdfController.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filename),
        actions: [
          if (_pageCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Page $_currentPage / $_pageCount',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: _hasError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load PDF'),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _retry, child: const Text('Retry')),
                ],
              ),
            )
          : PdfViewer.uri(
              key: ValueKey(_reloadKey),
              Uri.parse(widget.url),
              controller: _pdfController,
              params: PdfViewerParams(
                errorBannerBuilder: (context, error, stackTrace, documentRef) {
                  // Trigger retry UI on next frame so setState is not
                  // called during build.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _hasError = true);
                  });
                  return const SizedBox.shrink();
                },
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Video viewer
// ---------------------------------------------------------------------------

enum _VideoDownloadState {
  loading,
  downloading,
  ready,
  downloadError,
  offlineUnavailable,
}

class _VideoViewer extends StatefulWidget {
  const _VideoViewer({required this.url, required this.filename});

  final String url;
  final String filename;

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  _VideoDownloadState _state = _VideoDownloadState.loading;
  double _downloadProgress = 0;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _state = _VideoDownloadState.loading;
      _downloadProgress = 0;
    });

    final cachePath = await videoCachePath(widget.url);

    if (File(cachePath).existsSync()) {
      await _initControllerFromFile(cachePath);
      return;
    }

    // Not cached — check connectivity.
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none) &&
        connectivity.length == 1) {
      if (mounted)
        setState(() => _state = _VideoDownloadState.offlineUnavailable);
      return;
    }

    // Online — download first.
    if (mounted) setState(() => _state = _VideoDownloadState.downloading);

    final dir = Directory(
      '${(await getTemporaryDirectory()).path}/unishare_video',
    );
    await dir.create(recursive: true);

    try {
      await Dio().download(
        widget.url,
        cachePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );
      await _initControllerFromFile(cachePath);
    } on DioException {
      if (mounted) setState(() => _state = _VideoDownloadState.downloadError);
    }
  }

  Future<void> _initControllerFromFile(String path) async {
    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();

    if (!mounted) {
      await controller.dispose();
      return;
    }

    final chewie = ChewieController(
      videoPlayerController: controller,
      autoPlay: false,
      looping: false,
      allowFullScreen: true,
      materialProgressColors: ChewieProgressColors(playedColor: Colors.amber),
    );

    setState(() {
      _videoController = controller;
      _chewieController = chewie;
      _state = _VideoDownloadState.ready;
    });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.filename,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return switch (_state) {
      _VideoDownloadState.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      _VideoDownloadState.downloading => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: _downloadProgress),
            const SizedBox(height: 16),
            Text(
              'Downloading… ${(_downloadProgress * 100).toInt()}%',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
      _VideoDownloadState.ready => Center(
        child: Chewie(controller: _chewieController!),
      ),
      _VideoDownloadState.downloadError => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Download failed',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _init, child: const Text('Retry')),
          ],
        ),
      ),
      _VideoDownloadState.offlineUnavailable => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, color: Colors.white54, size: 48),
            SizedBox(height: 12),
            Text(
              'Not available offline',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Unsupported viewer
// ---------------------------------------------------------------------------

class _UnsupportedViewer extends StatelessWidget {
  const _UnsupportedViewer({required this.filename});

  final String filename;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(filename)),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.attach_file, size: 64),
            SizedBox(height: 16),
            Text('Preview not available for this file type'),
          ],
        ),
      ),
    );
  }
}
