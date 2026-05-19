---
title: "0008: Use Firebase Hosting + share_plus for universal deep-link sharing"
description: "Self-hosted Universal Links / App Links via Firebase Hosting with share_plus for the OS share sheet, rather than a third-party deep-link SDK or a custom server."
---

# 0008 — Use Firebase Hosting + share_plus for universal deep-link sharing

**Status:** ACCEPTED
**Author:** Slade
**Date:** 2026-05-18

## Problem

Users need to share a post with non-users or users on other devices. The share mechanism must produce a URL that re-opens the app to the exact post on iOS and Android, degrades gracefully to a web landing page if the app is not installed, and avoids adding a heavyweight SDK dependency. The team needs to decide where the well-known files are hosted, which package drives the OS share sheet, and how to handle the cold-start unauthenticated case in GoRouter.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Firebase Hosting + `share_plus` (self-hosted AASA / assetlinks.json) | No new vendor; Firebase already in the stack; BSD-3-Clause license; full control over well-known files | Must manage AASA and assetlinks.json manually; iOS deferred deep link is best-effort only |
| 2 | Branch.io SDK | Robust deferred deep linking on iOS and Android; attribution analytics built-in | Adds a large closed-source SDK; requires separate Branch dashboard; introduces a new vendor dependency requiring team approval |
| 3 | Dynamic Links (Firebase) | Already in Firebase ecosystem; handles deferred links on both platforms | Firebase Dynamic Links was deprecated in August 2025 and is scheduled for shutdown; not a viable long-term choice |

## Decision

**Chosen:** Option 1 — Firebase Hosting + `share_plus`

Firebase Hosting is already deployed for the project and can serve the two well-known files with the correct `Content-Type` headers at no additional cost. `share_plus` is a thin, BSD-3-licensed wrapper that delegates directly to the platform share sheet and the Web Share API, adding no background services or analytics. Dynamic Links is deprecated; Branch.io would introduce a vendor dependency and dashboard overhead that the team has not approved for v1.

## Reversal Cost

Medium. Replacing `share_plus` with Branch.io or another SDK later requires adding the SDK, migrating the `SharePlusDataSource`, updating AndroidManifest and Info.plist, and moving deferred-link logic into the new SDK — estimated at 2–3 days. The Firebase Hosting well-known files and GoRouter changes are reusable regardless of which share package is chosen.

## Consequences

- The `/.well-known/apple-app-site-association` and `/.well-known/assetlinks.json` files must be kept in sync with any bundle ID, team ID, or signing-certificate changes.
- iOS deferred deep linking (app not installed, user installs from App Store, then lands on correct post) is best-effort for v1. A follow-up ADR is needed when true deferred linking is prioritised.
- GoRouter's redirect guard is extended to preserve the original URI as a `redirect` query parameter so post-auth navigation resumes correctly.
- `share_plus` must receive explicit team approval before being added to `pubspec.yaml` (OQ2).
