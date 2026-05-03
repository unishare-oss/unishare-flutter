---
id: "0003"
title: "Use connectivity_plus and file_picker for post integration"
status: ACCEPTED
date: 2026-05-03
---

# 0003 — Use connectivity_plus and file_picker for post integration

**Date:** 2026-05-03
**Status:** ACCEPTED
**Author:** architect / Slade (CTO)

## Problem

SPEC-0004 (Post Integration) requires two new platform capabilities not yet in `pubspec.yaml`: (1) a real-time stream of network connectivity changes to trigger offline draft queue sync on reconnect, and (2) a file picker that supports all four media types the feature allows — JPEG, PNG, WebP, and PDF. Two candidate packages exist for each concern and a decision was needed before implementation could begin.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | `connectivity_plus` (connectivity) | Flutter Community standard; exposes `Stream<ConnectivityResult>` needed for reactive draft queue sync; supports iOS, Android, and Web | Adds a dependency |
| 2 | `dart:io` / `InternetAddress.lookup` (connectivity) | No new dependency | One-shot check only — cannot stream connectivity changes; requires polling workaround for draft queue trigger |
| 3 | `file_picker` (media selection) | Picks files of any type from device storage — covers JPEG, PNG, WebP, and PDF in one package; single dependency | Requires `NSPhotoLibraryUsageDescription` (iOS) and `READ_EXTERNAL_STORAGE` (Android) permission entries |
| 4 | `image_picker` (media selection) | Well-known; camera and gallery access | Images only — cannot pick PDF files; would require a second package alongside for document support |

## Decision

**Chosen:** Option 1 (`connectivity_plus`) and Option 3 (`file_picker`).

`connectivity_plus` is the only option that delivers a live stream of connectivity state, which `DraftQueueNotifier` requires to automatically trigger `SyncDraftQueue` without polling. `file_picker` is the only single-package solution covering all four MIME types in scope (JPEG, PNG, WebP, PDF); using `image_picker` alone would leave PDF support unimplemented, and pairing it with a second package adds more dependency surface than `file_picker` alone. Both choices rely on the assumption that the app will continue to target iOS, Android, and Web — if Web support were dropped, native alternatives could be reconsidered.

## Reversal Cost

Medium — both packages touch platform permission configuration (`Info.plist`, `AndroidManifest.xml`). Swapping either package would require updating permission entries, adjusting the datasource abstraction, and re-testing on both platforms.

## Consequences

- **Easier:** `DraftQueueNotifier` can subscribe to `connectivity_plus` stream directly with no polling timer; `MediaAttachmentPicker` handles all four MIME types with a single `FilePicker.platform.pickFiles` call.
- **Harder:** Two platform permission strings must be added and localised if the app ever ships in languages other than English.
- **Follow-up required:** Add `connectivity_plus` and `file_picker` to `pubspec.yaml`; add `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist`; add `READ_EXTERNAL_STORAGE` permission to `android/app/src/main/AndroidManifest.xml`.
