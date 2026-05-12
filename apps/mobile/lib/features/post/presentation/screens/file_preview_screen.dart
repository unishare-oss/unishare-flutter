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

// Fix 5: extracted constant — used by videoCachePath() and _VideoViewerState.
const _videoCacheSubdir = 'unishare_video';

/// Returns the local file-system path where a video should be cached.
///
/// Strips query-string parameters from [url] so the filename is stable across
/// signed URLs that change on every fetch.
Future<String> videoCachePath(String url) async {
  final dir = await getTemporaryDirectory();
  final filename = url.split('/').last.split('?').first;
  return '${dir.path}/$_videoCacheSubdir/$filename';
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
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: ac.surfaceDark,
      appBar: AppBar(
        backgroundColor: ac.surfaceDark,
        iconTheme: IconThemeData(color: cs.surface),
        title: Text(widget.filename, style: TextStyle(color: cs.surface)),
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
                  errorWidget: (context, url, error) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: cs.surface.withValues(alpha: 0.54),
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: ac.textMuted),
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
  bool _isLoading = true;
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
    if (page != _currentPage ||
        count != _pageCount ||
        (_isLoading && _pdfController.isReady)) {
      setState(() {
        _currentPage = page;
        _pageCount = count;
        if (_pdfController.isReady) _isLoading = false;
      });
    }
  }

  void _retry() {
    final old = _pdfController;
    setState(() {
      _hasError = false;
      _isLoading = true;
      _reloadKey++;
      old.removeListener(_onControllerChanged);
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
          : Stack(
              children: [
                PdfViewer.uri(
                  key: ValueKey(_reloadKey),
                  Uri.parse(widget.url),
                  controller: _pdfController,
                  params: PdfViewerParams(
                    errorBannerBuilder:
                        (context, error, stackTrace, documentRef) {
                          // Trigger retry UI on next frame so setState is not
                          // called during build.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _hasError = true);
                          });
                          return const SizedBox.shrink();
                        },
                  ),
                ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
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
  // Fix 3: single Dio instance, closed in dispose().
  final Dio _dio = Dio();
  // Fix 4: cancel token to abort in-flight downloads on widget disposal.
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Fix 1: removed setState() here — fields are already initialised at
    // declaration (_state = loading, _downloadProgress = 0). Calling setState
    // inside initState fires before the first build and violates the framework
    // contract. The retry button resets state before calling _init() instead.

    final cachePath = await videoCachePath(widget.url);

    if (File(cachePath).existsSync()) {
      await _initControllerFromFile(cachePath);
      return;
    }

    // Not cached — check connectivity.
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none) &&
        connectivity.length == 1) {
      if (mounted) {
        setState(() => _state = _VideoDownloadState.offlineUnavailable);
      }
      return;
    }

    // Online — download first.
    if (mounted) setState(() => _state = _VideoDownloadState.downloading);

    final dir = Directory(
      '${(await getTemporaryDirectory()).path}/$_videoCacheSubdir',
    );
    await dir.create(recursive: true);

    try {
      // Fix 4: fresh token for each download attempt.
      _cancelToken = CancelToken();
      // Fix 3: reuse _dio instead of creating a throwaway instance.
      await _dio.download(
        widget.url,
        cachePath,
        cancelToken: _cancelToken,
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
      materialProgressColors: ChewieProgressColors(
        // ignore: use_build_context_synchronously
        playedColor: Theme.of(context).extension<AppColors>()!.amber,
      ),
    );

    setState(() {
      _videoController = controller;
      _chewieController = chewie;
      _state = _VideoDownloadState.ready;
    });
  }

  @override
  void dispose() {
    // Fix 4: cancel any in-flight download before tearing down resources.
    _cancelToken?.cancel('widget disposed');
    // Fix 3: close the Dio instance to free its connection pool.
    _dio.close(force: true);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: ac.surfaceDark,
      appBar: AppBar(
        backgroundColor: ac.surfaceDark,
        iconTheme: IconThemeData(color: cs.surface),
        title: Text(widget.filename, style: TextStyle(color: cs.surface)),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
              style: TextStyle(color: cs.surface.withValues(alpha: 0.70)),
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
            Text(
              'Download failed',
              style: TextStyle(color: cs.surface.withValues(alpha: 0.70)),
            ),
            const SizedBox(height: 8),
            // Fix 1: reset state here (not inside _init) so _init is safe to
            // call from initState without an early setState.
            TextButton(
              onPressed: () {
                setState(() {
                  _state = _VideoDownloadState.loading;
                  _downloadProgress = 0;
                });
                _init();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      _VideoDownloadState.offlineUnavailable => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off,
              color: cs.surface.withValues(alpha: 0.54),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Not available offline',
              style: TextStyle(color: cs.surface.withValues(alpha: 0.70)),
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
