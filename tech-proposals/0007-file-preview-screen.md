---
title: "0007: File Preview Screen"
description: "Replace scattered inline preview logic with a unified FilePreviewScreen that delivers pinch-to-zoom images, full PDF scrolling, and video playback with controls."
---

# PROP-0007: File Preview Screen

**Status:** ACCEPTED  
**Author:** Architect  
**Date:** 2026-05-07  
**Spec:** (pending approval)  
**Approved by:** Pyae Sone Shin Thant (2026-05-07)

---

## Problem

Every authenticated student who opens the Post Detail screen to view an academic attachment hits one of three broken experiences today:

- **Images** open in a plain `CachedNetworkImage` fullscreen scaffold with no gesture support. There is no pinch-to-zoom and no pan, making it impossible to read text in lecture slides or diagrams uploaded as images.
- **PDFs** open via `PdfViewer.uri` from `pdfrx`, which renders but has never been tested. The viewer is assembled inline as an anonymous `MaterialPageRoute` builder — there is no shared logic, no error state, and no loading indicator beyond whatever `pdfrx` provides internally.
- **Videos** show a `SnackBar` that reads "Video playback coming soon". Students who upload video recordings of lectures have no path to viewing them at all.

The root technical cause is that preview routing is split across three separate `Navigator.push` blocks inside `_AttachmentRow._onView` in `attachment_list.dart`, plus a fourth duplicated `_openPdfViewer` method in `attachment_carousel.dart`. There is no shared abstraction. Fixing any behaviour requires touching multiple call sites, and the inconsistency will compound as more attachment types are added.

The user impact is direct: the primary value proposition of Unishare is accessing peer-uploaded academic content. When that content cannot be viewed, the app fails its core job.

---

## Proposed Solution

Introduce a single `FilePreviewScreen` widget under `features/post/presentation/screens/` that accepts a URL, a media type string (`"image"`, `"pdf"`, `"video"`), and an optional display filename. The screen is registered as a GoRouter route and receives its arguments via `extra`. All existing call sites (`_AttachmentRow._onView` and `_PdfSlot._openPdfViewer`) are replaced with a single `context.push('/preview', extra: previewArgs)` call.

Inside `FilePreviewScreen`, a type-switch selects the appropriate viewer sub-widget:

- **Image viewer** — `InteractiveViewer` wrapping `CachedNetworkImage`. `InteractiveViewer` is part of the Flutter SDK (no new dependency) and provides pinch-to-zoom and pan out of the box. A double-tap gesture resets zoom.
- **PDF viewer** — `PdfViewer.uri` from `pdfrx` (already in `pubspec.yaml` at 2.3.0). The screen adds an explicit loading indicator and a retry-on-error state that the current inline usage omits.
- **Video viewer** — `Chewie` widget backed by `video_player`. `video_player` is the Flutter-team-maintained package (free, open-source). `chewie` (free, open-source) adds a polished control layer: play/pause button, seek bar, mute toggle, and fullscreen toggle. Both packages must be added to `pubspec.yaml` — this must be flagged for team sign-off per the no-new-dependency rule (see Open Questions).

`AttachmentList` and `AttachmentCarousel` become thin callers: they each emit one `context.push` when the view action is triggered. No preview rendering logic remains in either widget.

---

## Alternatives Considered

### A — Patch in place: fix `_onView` without extracting a screen

Each gap is fixed where it sits: add `InteractiveViewer` to the image block, add loading/error states to the PDF block, wire up `video_player` + `chewie` inside the video `else` branch. The two duplicated call sites (`attachment_list.dart` and `attachment_carousel.dart`) are patched independently.

**Rejected:** This is the lowest-friction path but leaves the structural problem intact. Two call sites means every future change (accessibility labels, analytics events, deep-link support) must be applied twice. The inline anonymous builders cannot be widget-tested without a full `PostDetailScreen` render tree. As more attachment types are added (e.g., audio, code files), the `if/else` chain grows without bound, and there is no natural boundary at which to stop. The short-term savings are real; the long-term cost is higher.

### B — Unified `FilePreviewScreen` (the proposed solution)

A named GoRouter route that centralises all preview logic. One widget to test, one call site to change, one place to add analytics or accessibility improvements.

This is the recommended option — see Proposed Solution above.

### C — Per-type screens: `ImagePreviewScreen`, `PdfPreviewScreen`, `VideoPreviewScreen`

Three separate screens, each registered as a GoRouter route. Callers choose the route based on type.

**Rejected:** This avoids a type-switch inside one screen by moving it into every caller. Each call site still branches on type to decide which route to push. There is no meaningful encapsulation gain over Option A. Three screens also triple the test surface for boilerplate concerns (AppBar title, back navigation, error states) that are identical across types. The only scenario where separate screens would be justified is if the routing arguments, lifecycle hooks, or state management differed substantially per type — they do not here.

---

## Open Questions

1. **Video offline support.** ✅ **RESOLVED — in scope.** Pre-download via `dio` to `getTemporaryDirectory()` (OS-managed cache, same as `CachedNetworkImage`). Files are invisible to the user, evicted automatically when storage is low. Requires adding `path_provider` dependency. First view downloads and caches; subsequent views play from local file URI offline.

2. **Multi-image swipe navigation.** ✅ **RESOLVED — deferred.** Single-image fullscreen for this release. Swipe navigation requires `PageView` + passing the full image list and starting index, making `FilePreviewScreen` stateful. Will be addressed in a follow-up.

3. **New dependency approval.** ✅ **RESOLVED — approved.** `video_player`, `chewie`, and `path_provider` approved by Pyae Sone Shin Thant (2026-05-07).

4. **Unsupported types.** ✅ **RESOLVED — placeholder.** Show "Preview not available" message. No `url_launcher` fallback.

---

## Acceptance Criteria

- Tapping the view action on an image attachment opens `FilePreviewScreen` with pinch-to-zoom and pan gesture support. Double-tap resets zoom to fit.
- Tapping the view action on a PDF attachment opens `FilePreviewScreen` showing the full document via `pdfrx`. A loading indicator is visible while the PDF fetches. An error state with a retry button is shown if loading fails.
- Tapping the view action on a video attachment opens `FilePreviewScreen` with a `chewie` player: play/pause, seek bar, mute toggle, and fullscreen toggle are all functional.
- All three preview types are reached via a single GoRouter route (`/preview`). No inline `MaterialPageRoute` builders remain in `attachment_list.dart` or `attachment_carousel.dart`.
- `FilePreviewScreen` has a widget test for each media type branch (image, pdf, video, unknown/fallback).
- The screen is mobile-only (iOS + Android); web is explicitly out of scope.
- No new dependencies are added without team sign-off recorded in the decision log.
