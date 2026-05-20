# Session: 2026-05-18-share-post

**Date:** 2026-05-18  
**Member:** Slade  
**Agent:** flutter-engineer  
**Task:** Implement share-post feature (SPEC-0010)

## Context

PROP-0010 and SPEC-0010 are both APPROVED. Stub files have been scaffolded.
See `tech-specs/0010-share-post.md` for the full file map, API contracts, and test plan.

Key decisions carried forward from the spec:
- `share_plus` is a new dependency — requires team approval (OQ2) before adding to `pubspec.yaml`
- Firebase Hosting domain is a placeholder (`<FIREBASE_HOSTING_DOMAIN>`) — must be confirmed (OQ1)
- Android SHA-256 fingerprints not yet filled in `hosting/public/.well-known/assetlinks.json` (OQ5)
- iOS deferred deep linking is best-effort / out of scope for v1
- Android Play Install Referrer is also descoped to post-v1

## Plan

1. Resolve OQ1 (Hosting domain), OQ2 (`share_plus` approval), OQ5 (SHA-256 fingerprints) with the team before writing any network config
2. Add `share_plus` to `pubspec.yaml`; run `flutter pub get`
3. Implement `SharePlusDataSource` — share text, clipboard fallback, `ShareFallbackResult`
4. Implement `ShareRepositoryImpl` — call datasource, propagate `ShareFallbackException`
5. Wire Riverpod providers: `sharePostUseCaseProvider`, `shareRepositoryProvider`, complete `sharePostProvider`
6. Modify `PostDetailScreen` — add share `IconButton` to `AppBar.actions`; `ref.listen` for `ShareFallbackException`; inline "Post not found" error state
7. Extend GoRouter redirect guard to preserve deep-link path as `?redirect=` on unauthenticated redirects
8. Configure `AndroidManifest.xml` intent-filter and `Runner.entitlements` associated-domains
9. Update `firebase.json` with hosting block
10. Fill in `apple-app-site-association`, `assetlinks.json` with real values
11. Write tests per test plan (4 files)
12. Run `dart run build_runner build --delete-conflicting-outputs`
13. Run `flutter analyze` + `dart format .`

## Notes

<!-- Running notes during the session -->

## Handoff

**To:** architect / qa-engineer (reviewer)  
**Done:** (fill in at end of session)  
**Not done:** (fill in at end of session)  
**Watch out for:**
- `share_plus` must NOT be imported anywhere in domain or presentation layer — data layer only
- GoRouter redirect change at `router.dart:118` affects ALL unauthenticated deep links — test other protected routes still work
- `assetlinks.json` needs separate fingerprints for debug vs release keystores; do not commit private key files
