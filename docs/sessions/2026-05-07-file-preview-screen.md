# Session: 2026-05-07-file-preview-screen

**Date:** 2026-05-07  
**Member:** Pyae Sone Shin Thant  
**Agent:** flutter-engineer  
**Task:** Implement SPEC-0007 — unified FilePreviewScreen for image, PDF, video, and unsupported attachments

## Context

PROP-0007 approved and SPEC-0007 approved today. All open questions resolved.

Relevant documents:
- Proposal: `tech-proposals/0007-file-preview-screen.md`
- Spec: `tech-specs/0007-file-preview-screen.md`
- ADR: `docs/decisions/0007-file-preview-unified-route.md`

The problem: `attachment_list.dart` and `attachment_carousel.dart` each have scattered inline
`Navigator.push` / `MaterialPageRoute` builders for image and PDF, plus a "coming soon" SnackBar
for video. This session replaces all of them with a single GoRouter `/preview` route backed by
`FilePreviewScreen`.

## Plan

1. Add `video_player`, `chewie`, `path_provider` to `pubspec.yaml` and run `flutter pub get`
2. Implement `FilePreviewScreen` at `lib/features/post/presentation/screens/file_preview_screen.dart`:
   - `FilePreviewArgs` typedef (Dart record: url, type, filename)
   - `FilePreviewScreen` StatelessWidget — switches on type
   - `_ImageViewer` StatefulWidget — InteractiveViewer + CachedNetworkImage + TransformationController
   - `_PdfViewer` StatefulWidget — PdfViewer.uri + loading/error/retry states + PdfViewerController
   - `_VideoViewer` StatefulWidget — videoCachePath(), dio download, video_player + Chewie; all five _VideoDownloadState branches
   - `_UnsupportedViewer` StatelessWidget — attachment icon + message
3. Register `/preview` GoRoute in `lib/core/router/router.dart`; add `'/preview'` to `knownPrefixes`
4. Update `attachment_list.dart` — replace `_AttachmentRow._onView` three branches with single `context.push('/preview', extra: FilePreviewArgs(...))`
5. Update `attachment_carousel.dart` — replace `_PdfSlot._openPdfViewer`, the image fallback tap, and `_VideoSlot` SnackBar with `context.push('/preview', extra: FilePreviewArgs(...))`
6. Write widget tests in `test/widget/features/post/file_preview_screen_test.dart` — all four branches + error states
7. Write unit tests in `test/unit/features/post/video_cache_path_test.dart` — videoCachePath strip/no-query-params cases
8. Run `flutter analyze` and `dart format .`

## Notes

### Key constraints from spec
- `_ImageViewer` must be StatefulWidget (owns TransformationController for double-tap reset)
- `videoCachePath(String url)` must be package-private (not inside _VideoViewer) for unit testability
- GoRoute must be at top-level routes list, NOT nested inside the StatefulShellRoute
- `'/preview'` must be added to `knownPrefixes` in `_RouterNotifier.redirect`
- `FilePreviewArgs` is a Dart record — not serialisable across process restarts (limitation logged in ADR-0007)
- Video seek bar color: `ChewieProgressColors(playedColor: Colors.amber)` to match app theme
- Chewie: autoPlay: false, looping: false, allowFullScreen: true

### Existing deps already in pubspec (no need to add)
- `dio: ^5.9.2` — used for video download
- `connectivity_plus: ^7.1.1` — used for offline check
- `pdfrx: 2.3.0` — used for PDF viewer (no change)
- `cached_network_image: ^3.4.1` — used for image viewer (no change)

### _VideoDownloadState enum
```
loading → checking cache / starting download
downloading → dio in progress, show _downloadProgress (0.0–1.0)
ready → file exists, Chewie rendered
downloadError → DioException, show retry
offlineUnavailable → ConnectivityResult.none + no cache
```

## Handoff

**To:** qa-engineer or architect (reviewer)  
**Done:** (fill in after session)  
**Not done:** (fill in after session)  
**Watch out for:** (fill in after session)
