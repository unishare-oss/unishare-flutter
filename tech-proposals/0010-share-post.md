---
title: "0010: Share Post"
description: "Allow users to share academic posts outside the app via platform share sheets, with deferred deep links so recipients who do not yet have the app are routed to the correct post on first launch."
---

# PROP-0010: Share Post

**Status:** ACCEPTED  
**Author:** Slade  
**Date:** 2026-05-17  
**Spec:** [SPEC-0010](../tech-specs/0010-share-post.md)  
**Approved by:** Slade

---

## Problem

Unishare has no affordance for sharing a post outside the application. A student who finds a relevant lecture summary, past exam paper, or course note cannot forward it to a classmate through WhatsApp, Telegram, iMessage, or any other channel — they can only describe it verbally or copy-paste the post title and hope the recipient finds it independently. An educator cannot promote newly uploaded material on a department group chat.

This matters at two levels. First, there is no share button anywhere on the post detail screen, so the action is entirely invisible to users. Second, even if a raw URL were shared manually, there is no URL structure in the app to open a specific post, and no infrastructure to route a non-user who taps the link to the App Store or Play Store and then onward to the correct post after installation (deferred deep link). Links shared without deferred deep linking are dead ends for recipients who have not yet installed the app — the group most important to grow the user base.

The absence of sharing also limits organic growth. Academic content communities depend heavily on peer recommendation; without a low-friction share mechanism, posts circulate only within the existing in-app audience.

From a technical standpoint the app currently has no:
- Share trigger in the presentation layer (no "share" button or action sheet entry on post detail).
- Canonical URL structure for individual posts.
- Firebase Hosting configuration for web serving (the `firebase.json` does not contain a `hosting` key).
- Universal Links (`/.well-known/apple-app-site-association`) or App Links (`/.well-known/assetlinks.json`) configuration.
- `share_plus` dependency in `pubspec.yaml`.
- Deferred deep link landing page or launch-state handling in GoRouter.

All of these gaps must be addressed together for end-to-end sharing to work.

---

## Proposed Solution

### Overview

The recommended approach is **self-hosted Universal Links and App Links via Firebase Hosting** (Option A below). A share button on the post detail screen invokes `share_plus` to trigger the platform share sheet (iOS, Android) or the Web Share API (web). The shared URL points to a Firebase Hosting domain under the team's control. On a device with the app installed, the OS intercepts the link and opens the app directly to the correct post. On a device without the app, the browser lands on a minimal Firebase Hosting HTML redirect page that stores the target post ID (in `sessionStorage` or a URL fragment) and redirects the user to the App Store or Play Store. When the user subsequently installs and opens the app, a first-launch routine reads a stored post ID and navigates GoRouter to that post detail screen.

This approach uses only Firebase Hosting (already part of the Firebase project, free tier) and `share_plus` (free, open-source). No paid service is required.

### Canonical URL structure

Every post gets a shareable URL of the form:

```
https://<firebase-hosting-domain>/posts/<postId>
```

Example: `https://unishare-app.web.app/posts/abc123`

The `postId` is the Firestore document ID already assigned at upload time — no new identifier is introduced.

### iOS: Universal Links

A JSON file is deployed to Firebase Hosting at:

```
/.well-known/apple-app-site-association
```

It lists the app's Team ID and Bundle ID and associates the `/posts/*` path pattern with the app. When an iOS device with the app installed receives a tap on a `https://unishare-app.web.app/posts/<id>` URL (in iMessage, WhatsApp, Safari, etc.), iOS intercepts the link and calls `AppDelegate.application(_:continue:restorationHandler:)` without opening the browser. The app's GoRouter deep-link handler (already in place for push notification routing) parses the incoming URL and navigates to the post detail screen for the given `postId`.

### Android: App Links

A JSON file is deployed to Firebase Hosting at:

```
/.well-known/assetlinks.json
```

It lists the app's SHA-256 certificate fingerprint and package name. Android verifies this file at install time and on OS startup (Digital Asset Links verification). When the app is installed and a matching URL is tapped, Android routes it directly to the app via an intent filter with `android:autoVerify="true"`.

### Web platform: Web Share API

On web, `share_plus` 10.x wraps the browser's `navigator.share()` API. When `navigator.share()` is available (Chrome for Android, Safari on iOS/macOS, Edge), the native system share sheet opens with the post title and URL pre-populated. When `navigator.share()` is unavailable (desktop Chrome, Firefox), `share_plus` falls back to copying the URL to the clipboard and showing a snackbar.

### Deferred deep link: landing page

Firebase Hosting serves an `index.html` at `/posts/<postId>` via a rewrite rule (catch-all SPA rewrite, same pattern used for web app hosting). This page contains:

1. Open Graph and Twitter Card meta tags (`og:title`, `og:description`, `og:image`) populated via a Cloud Function that renders the page server-side, or — for v1 — static meta tags with a generic title and the post URL. (OG tag strategy is an open question below.)
2. A small JavaScript snippet that detects the platform (iOS / Android / other) and redirects to the App Store, Play Store, or a web fallback. Before redirecting, it writes the `postId` to `localStorage` under a key such as `unishare_pending_post`.

### Deferred deep link: first-launch handling in Flutter

On app cold start, a Riverpod provider (e.g., `pendingShareProvider`) checks whether a stored post ID exists. On native platforms the mechanism differs:

- **iOS/Android:** The landing page cannot write to the app's `localStorage`, so deferred state must be passed through the store install flow. The standard approach without a third-party SDK is a Firebase Hosting redirect that appends the post ID to the App Store URL as a referral parameter (iOS) or via a Play Install Referrer API value (Android). For v1, a simpler fallback is acceptable: after first install and first Firebase Auth sign-in, the app checks `flutter_secure_storage` for a value written by a background URL handler. This is only possible if the OS delivers the link before the app is fully initialised — which Universal Links and App Links do when the user taps the link after installation (not a true deferred case). True deferred deep linking (link tapped before installation) without a third-party SDK requires the Play Install Referrer API on Android and has no reliable native equivalent on iOS without asking the user to re-tap the link.

The practical v1 recommendation: deferred deep linking is supported on Android via the Play Install Referrer API (no paid service needed, the API is free), and best-effort on iOS (Universal Link is delivered if the app is already installed; post-install routing on iOS for genuinely new users is deferred to v2 or resolved via Branch.io if the team later prioritises it). This scopes the work honestly without over-promising.

### Flutter package addition

`share_plus` (pub.dev, BSD-3-Clause, maintained by the Flutter community) must be added to `pubspec.yaml`. This requires team approval per the project's dependency policy. No other new package is required for the core share flow. The Play Install Referrer API on Android is accessed through the existing Android manifest and intent handling; no additional pub.dev package is needed unless the team adopts `app_links` for a unified URL handler (also free, open-source — flagged as an option in the spec phase).

### Clean Architecture layers

| Layer | Artifact |
|---|---|
| `domain/entities/` | No new entity — `Post` entity gains no new fields |
| `domain/repositories/` | `ShareRepository` abstract interface: `share(Post post)` → `Future<void>` |
| `domain/usecases/` | `SharePostUseCase` |
| `data/datasources/` | `SharePlusDataSource` (wraps `share_plus` `SharePlus.instance.share()`) |
| `data/repositories/` | `ShareRepositoryImpl` |
| `presentation/providers/` | `sharePostProvider` (simple `FutureProvider.family` keyed on `postId`) |
| `presentation/widgets/` | Share icon button added to `PostDetailScreen` app bar |

The Domain layer touches no Flutter or Firebase import. `share_plus` is consumed exclusively in the Data layer datasource.

### Firebase Hosting

`firebase.json` gains a `hosting` block pointing to the web build output (`apps/mobile/build/web`). The rewrite rule serves `index.html` for all `/posts/*` paths that are not static assets, supporting both the Flutter web SPA and the deferred deep link landing page. This doubles as the web deployment of the Unishare Flutter web app, which is currently absent.

---

## Alternatives Considered

### A — Self-hosted Universal Links + App Links via Firebase Hosting (recommended)

A Firebase Hosting domain hosts `/.well-known/apple-app-site-association` (iOS) and `/.well-known/assetlinks.json` (Android). `share_plus` generates the shareable URL and triggers the platform share sheet. GoRouter handles the incoming deep link on devices with the app installed. Deferred deep linking is handled via the Play Install Referrer API on Android; iOS deferred linking is best-effort in v1. Web sharing uses `share_plus`'s Web Share API wrapper.

**Pros:**
- Zero additional cost: Firebase Hosting is free tier, `share_plus` is free open-source.
- No dependency on any third-party managed service that could change pricing, shut down, or require an account.
- The team retains full control of the well-known files and the landing page HTML.
- Universal Links and App Links are the OS-native mechanism — they work inside iMessage, WhatsApp, Telegram, and every browser without any special integration.
- Web Share API via `share_plus` handles web platform with a single call.
- Firebase Hosting deployment is already understood by the team (existing `firebase deploy` workflow).

**Cons:**
- True deferred deep linking on iOS (link tapped before app is installed) has no free, first-party solution. This gap affects only brand-new iOS users who have not yet installed the app — an edge case for v1.
- The team must host and maintain the well-known files, the landing page HTML, and the Firebase Hosting configuration. This is a few hours of setup but ongoing maintenance is minimal.
- App Links on Android require SHA-256 certificate fingerprint registration, which must be repeated for every signing key variant (debug, release, CI). The spec must document all required fingerprints.
- OG meta tag pre-population for rich link previews (title, image in iMessage/WhatsApp) requires either a Cloud Function that renders post metadata server-side or a static placeholder. A Cloud Function adds complexity; a static placeholder gives poor preview quality.

**Effort:** Medium. Firebase Hosting setup (~2 hours), well-known file deployment (~1 hour), GoRouter deep link handler (~2 hours), Play Install Referrer integration (~3 hours), `share_plus` UI integration (~2 hours). Total: ~10 hours.

### B — Custom URL scheme only (no Universal Links or App Links)

Register a custom URI scheme (`unishare://`) in the iOS `Info.plist` and Android `AndroidManifest.xml`. Share a `unishare://posts/<postId>` link via `share_plus`. GoRouter registers a handler for the custom scheme.

**Pros:**
- Simplest possible implementation: no well-known files, no Firebase Hosting, no OS verification step.
- Works immediately on devices with the app installed when the user taps the link inside another app that can open custom schemes.
- No new infrastructure.

**Cons:**
- Custom scheme links do not open in a browser — they are opaque to web surfaces. If a `unishare://` link is tapped in a Twitter/X web card, email client, or desktop browser, the OS shows "no application can handle this link" on devices without the app and simply does nothing on the web platform.
- Deferred deep linking is impossible: there is no web landing page, so a non-user who taps the link cannot be redirected to the store.
- The Web Share API cannot share a `unishare://` URI — the browser will refuse to share non-http(s) URLs in most implementations.
- Rich link previews (OG tags) are impossible with a custom scheme.
- iOS explicitly discourages custom schemes for user-facing links in App Store guidelines and App Review may flag an app that relies on them as the primary sharing mechanism.

**Effort:** Low (~4 hours). But the resulting feature does not meet the stated constraint of supporting deferred deep links or web sharing.

**Rejected for v1** because it fails the deferred deep link requirement and web sharing requirement stated in the problem constraints. It may be added as a supplementary scheme (for app-to-app internal routing) in a future spec.

### C — Third-party deep link service (Branch.io free tier)

Integrate Branch.io, which provides a fully managed deferred deep link pipeline including a dashboard, Universal Links / App Links configuration, link analytics, and true deferred deep linking on both iOS and Android.

**Pros:**
- True deferred deep linking works on iOS and Android out of the box, including the genuinely new user case (link tapped before app installation).
- Rich link preview metadata (OG tags, custom images per post) can be configured via the Branch dashboard without a server-side rendering function.
- Branch's free tier (up to 10,000 monthly active users or 10,000 attributed installs — limits vary by plan) has no monetary cost at low volume.
- The `flutter_branch_sdk` pub.dev package wraps the Branch SDK with a Flutter API.
- Branch handles the `/.well-known/` file hosting; the team does not need to configure Firebase Hosting for deep links.

**Cons:**
- Introduces a third-party managed service dependency. If Branch changes its free-tier limits, discontinues the free plan, or shuts down (as Firebase Dynamic Links did in August 2025), the team must migrate on short notice. This is exactly the failure mode that happened with Dynamic Links.
- The Branch SDK adds ~2–4 MB to the app binary (native SDK for iOS and Android).
- `flutter_branch_sdk` is a community-maintained package, not a Flutter/Google-supported package, introducing maintenance risk.
- Branch's free tier requires creating a Branch account and domain verification — non-trivial onboarding for a team that has not used it before.
- Any analytics or attribution data generated by Branch links is stored on Branch's servers, raising data governance questions (particularly relevant for a university academic platform).

**Effort:** Medium-high (~12 hours including SDK integration, account setup, domain verification, and testing across both platforms).

**Not recommended** for v1 because the third-party service dependency risk is directly analogous to the Firebase Dynamic Links shutdown that prompted this proposal. Option A achieves the same outcome for the in-app use case without the dependency risk. If true iOS deferred deep linking becomes a hard business requirement, Option C can be revisited at that point — the reversal cost from Option A to Option C is moderate (Branch SDK integration requires adding the SDK, replacing the share URL construction logic, and removing the custom landing page; GoRouter's deep link handler logic is reusable).

### D — Firebase App Distribution / Invite Links (not applicable)

Firebase App Distribution invite links are for distributing pre-release builds to testers — not for end-user content sharing. Included here only to pre-empt the question; it does not address the problem.

---

## Open Questions

1. **Firebase Hosting domain and project configuration.** The current `firebase.json` has no `hosting` key, which means Firebase Hosting has not been configured for this project. Is the Firebase project already linked to a Hosting domain (e.g., `<project-id>.web.app`)? Has the team verified ownership of any custom domain (`unishare.app` or similar) that should be used for the shareable URL? The canonical URL structure in the spec depends on this answer — if a custom domain is in use, the `assetlinks.json` and `apple-app-site-association` files must list it specifically, not `*.web.app`.

2. **`share_plus` approval as a new dependency.** `share_plus` is not currently in `pubspec.yaml`. Per the project's dependency policy, new packages require team approval. The team should confirm that `share_plus` (BSD-3-Clause, Flutter Favourite, maintained by the Flutter community) is acceptable before the spec phase begins. If `share_plus` is not approved, Option B (custom scheme, clipboard fallback) is the only path forward.

3. **Deferred deep link scope for v1.** True deferred deep linking on iOS (for users who tap a link before installing the app) requires either a third-party service (Option C) or a non-trivial workaround. The recommended approach (Option A) handles Android deferred deep linking via the Play Install Referrer API and leaves iOS deferred deep linking as best-effort. Is iOS deferred deep linking a hard requirement for v1, or is "link opens the app if installed; opens the store if not installed (no post routing after install on iOS)" acceptable for launch?

4. **OG meta tag strategy for rich link previews.** When a post URL is shared in iMessage, WhatsApp, or Telegram, the messaging app's link preview bot fetches the URL and renders a card using Open Graph meta tags (`og:title`, `og:description`, `og:image`). For this to show post-specific content (title, file type, uploader), the landing page must be rendered server-side with post metadata — either via a Cloud Functions SSR endpoint or via Firebase Hosting's dynamic rewrites. A static fallback (generic "Unishare — Academic Content" title, app icon as image) is simpler but produces low-quality previews. Which approach is required for v1?

5. **Android signing key variants and SHA-256 fingerprints.** App Links digital asset verification requires the app's SHA-256 certificate fingerprint in `assetlinks.json`. The debug keystore fingerprint differs from the release keystore fingerprint, and a CI/CD signing key may be a third variant. The spec must enumerate all fingerprints and define how they are managed without committing private keys to the repository. Does the team have a documented key management process, or does the spec need to define one?

6. **Sharing from the post list screen vs. post detail screen only.** Should the share affordance appear only on the post detail screen (one tap to open the post, then share), or also as a swipe action or context menu on post cards in the feed? The latter reduces friction but is a wider implementation scope. The proposal assumes post detail screen only for v1.

---

## Acceptance Criteria

- A share icon button is present in the `PostDetailScreen` app bar. Tapping it triggers the platform share sheet on iOS and Android, and the Web Share API (or clipboard fallback) on web.
- The shared payload contains a canonical `https://` URL of the form `https://<hosting-domain>/posts/<postId>` and the post title as the share text.
- On a device with the Unishare app installed, tapping the shared URL (in iMessage, WhatsApp, Telegram, or any browser) opens the app directly to the correct post detail screen without navigating through the feed first.
- On an Android device without the app installed, tapping the shared URL opens the browser landing page and redirects to the Google Play Store. After installation and first launch, the app navigates to the shared post (Play Install Referrer deferred deep link).
- On an iOS device without the app installed, tapping the shared URL opens the browser landing page and redirects to the App Store. After installation and first launch, the app makes a best-effort attempt to route to the shared post; if the OS does not deliver the link after install, the user lands on the home feed (acceptable for v1).
- The Firebase Hosting deployment serves `/.well-known/apple-app-site-association` with correct Team ID, Bundle ID, and `/posts/*` path association.
- The Firebase Hosting deployment serves `/.well-known/assetlinks.json` with the correct SHA-256 certificate fingerprints for debug and release builds.
- The `ShareRepository` interface and `SharePostUseCase` in the domain layer contain zero Flutter or Firebase imports.
- `share_plus` is consumed only in the data layer datasource (`SharePlusDataSource`); it does not appear in domain or presentation layer imports.
- `SharePostUseCase` has a unit test against a mock `ShareRepository` covering the success path.
- The share button widget has a widget test verifying it renders on the post detail screen and invokes the use case when tapped.
- `flutter analyze` reports zero errors or warnings on all new Dart code.
- The feature is accessible: the share button has a `Semantics` label of "Share post".
