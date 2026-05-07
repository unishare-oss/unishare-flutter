---
title: "0007: Unified /preview GoRoute with FilePreviewArgs extra"
description: "A single GoRouter route replaces three scattered MaterialPageRoute builders and a SnackBar stub for file attachment previewing."
---

# 0007 — Unified /preview GoRoute with FilePreviewArgs extra

**Status:** ACCEPTED  
**Author:** Architect  
**Date:** 2026-05-07

## Problem

Preview logic for image, PDF, and video attachments is split across three `Navigator.push` blocks inside `_AttachmentRow._onView` in `attachment_list.dart` and a fourth duplicated `_openPdfViewer` in `attachment_carousel.dart`. Video shows a `SnackBar` stub. There is no testable abstraction: anonymous `MaterialPageRoute` builders cannot be widget-tested without rendering the full `PostDetailScreen` tree. Any cross-cutting concern (analytics, accessibility labels, deep-link support) must be applied at every call site independently.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Patch in place — fix each inline block separately | Zero new files; no routing change | Two permanently divergent call sites; anonymous builders remain untestable in isolation; scales poorly as new attachment types are added |
| 2 | Unified `FilePreviewScreen` on a single `/preview` GoRoute (chosen) | One testable widget; one call site shape; one place for analytics, accessibility, and deep-link handling | Requires GoRouter `extra` typing discipline; must add `/preview` to the redirect guard's `knownPrefixes` |
| 3 | Three separate routes: `/preview/image`, `/preview/pdf`, `/preview/video` | Each screen is smaller and focused | Type-branching moves into every caller; boilerplate (AppBar, back nav, error states) is triplicated; no encapsulation gain over Option 1 |

## Decision

**Chosen:** Option 2 — Unified `FilePreviewScreen` on `/preview`.

A single `GoRoute` at path `/preview` accepts a `FilePreviewArgs` Dart record via `state.extra`, then switches on `type` to render one of four private sub-widgets. This gives the team one testable widget boundary, one call site contract, and one extension point for future concerns such as analytics events or accessibility labels. It relies on the team maintaining the discipline of always casting `state.extra` to `FilePreviewArgs` — a constraint enforced by the typed record and caught at runtime by a `!` cast on first access.

## Reversal Cost

Medium. Undoing this decision means reintroducing inline `MaterialPageRoute` builders at each call site and deleting the `/preview` route. The `FilePreviewScreen` file can be deleted cleanly; the two call-site widgets must be reverted. No Firestore schema or domain entity changes are involved, so data-layer reversal is zero. Test files for the screen would be discarded.

## Consequences

- **Easier:** Adding a new attachment type (e.g., audio) requires adding one `case` in `FilePreviewScreen` and one new sub-widget — no call-site changes.
- **Easier:** Widget-testing all four preview types in isolation without rendering `PostDetailScreen`.
- **Easier:** Adding analytics or accessibility improvements in a single place.
- **Harder:** Deep-linking directly to `/preview` from a push notification or share URL requires the `FilePreviewArgs` to be reconstructable from a URL — `extra` is not serialisable across process restarts. If deep-link support is added in future, path parameters or query parameters will need to be used instead of `extra`, requiring a breaking change to the route contract.
- **Follow-up required:** The `knownPrefixes` guard in `_RouterNotifier.redirect` must include `'/preview'` to prevent unauthenticated users from deep-linking into the screen.
