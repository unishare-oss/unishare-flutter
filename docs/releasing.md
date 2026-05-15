# Releasing Unishare

How to cut a release. The build/upload pipeline is fully automated — you just trigger a version bump.

**Source of truth: the latest `v*.*.*` git tag.** The Cut Release workflow reads the highest existing tag, computes the next version, and pushes a new annotated tag. `pubspec.yaml` is ignored for versioning — the build pipeline passes `--build-name` / `--build-number` derived from the tag into `flutter build`.

---

## Overview

```
Cut Release workflow         Release workflow
─────────────────────        ─────────────────
  workflow_dispatch  ──push tag──▶  on: tags
        │                              │
        │                              ├─▶ create-release  (GitHub Release shell + notes)
        │                              │
        │                              ├─▶ build-web      ─┐
        │                              │                   ├─▶ upload artifacts
        │                              ├─▶ build-android  ─┤
        │                              │                   │
        │                              └─▶ build-ios      ─┘
```

Two workflows. You only ever trigger the first.

---

## Normal release

**1. Confirm `main` is ready.** Everything you want shipped is merged, CI is green.

**2. GitHub → Actions → "Cut Release" → "Run workflow".**

| Field             | Value                       |
| ----------------- | --------------------------- |
| Use workflow from | `main`                      |
| bump_type         | `patch` / `minor` / `major` |
| dry_run           | unchecked                   |

Run.

**3. Wait ~30 seconds.** Cut Release:

- Reads the highest existing `v*.*.*` tag (e.g., `v0.3.0`)
- Computes the next version (e.g., `v0.4.0` for `minor`, `v1.0.0` for `major`)
- Creates and pushes an annotated tag — no commit to any branch

**4. The Release workflow auto-fires on the tag push.** Three build jobs (web, Android, iOS) run in parallel after the release shell is created. ~15-20 minutes total.

**5. Verify at `/releases`.** Should see the new tag with:

- Auto-generated notes (PRs merged since last tag)
- `unishare-vX.Y.Z.zip` (web)
- `unishare-vX.Y.Z.apk` + `unishare-vX.Y.Z.aab` (Android)
- `unishare-vX.Y.Z.ipa` (iOS — unsigned, see below)

---

## Dry run

Before doing this for real, especially the first time:

1. Actions → Cut Release → Run workflow
2. Tick **dry_run**, run

The job parses pubspec and prints "Previous: A+B, New: C+D" in the summary but doesn't commit, tag, or push. Confirm the new version is what you expect, then re-run without dry_run.

---

## Failure modes

### Cut Release fails before pushing the tag

Causes: tag already exists; tag protection rule blocks the bot.

→ Nothing is on the remote. Fix the cause, re-run Cut Release.

### Cut Release pushed the tag, but a Release build job failed

The tag and version-bump commit are already on `main`. The Release exists (possibly with partial artifacts).

→ Actions → Release → click the failed run → "Re-run failed jobs". Other artifacts stay attached.

### You need to un-release

```bash
git push origin :refs/tags/vX.Y.Z      # delete remote tag
# Then delete the GitHub Release in the UI
```

That's it — there's no source-side commit to revert.

---

## Hotfix to an older version

Scenario: shipped `v1.2.0`, found a critical bug, but `main` is already on `v1.3.0` work.

1. `git checkout -b hotfix/1.2.1 v1.2.0`, push the branch
2. Apply the fix on `hotfix/1.2.1`, push
3. Actions → Cut Release → Run workflow → **Use workflow from: `hotfix/1.2.1`** → bump_type: `patch`
4. Cut Release tags `v1.2.1` on the hotfix branch; the Release pipeline ships from there
5. Cherry-pick the fix back to `main` separately

---

## One-time setup

These have to be in place once per repo for the workflows to function.

### Tag protection (optional)

Branch protection on `main` does **not** affect this workflow — Cut Release only pushes a tag, never a commit.

If you've configured tag protection rules under Settings → Tags, you must allow `github-actions[bot]` to bypass them (or switch the workflow token to a PAT with `contents:write` saved as `RELEASE_TOKEN`).

### Workflow permissions

Settings → Actions → General → Workflow permissions → **Read and write permissions**.

### Required secrets

| Secret                     | Used by        | What it is                                                    |
| -------------------------- | -------------- | ------------------------------------------------------------- |
| `FIREBASE_OPTIONS`         | all build jobs | Contents of `apps/mobile/lib/firebase_options.dart`           |
| `WORKER_URL`               | all build jobs | R2 worker URL passed via `--dart-define`                      |
| `GOOGLE_SERVICES_JSON`     | build-android  | Contents of `apps/mobile/android/app/google-services.json`    |
| `KEYSTORE_BASE64`          | build-android  | Release keystore, base64-encoded                              |
| `STORE_PASSWORD`           | build-android  | Keystore password                                             |
| `KEY_PASSWORD`             | build-android  | Key password                                                  |
| `KEY_ALIAS`                | build-android  | Key alias                                                     |
| `GOOGLESERVICE_INFO_PLIST` | build-ios      | Contents of `apps/mobile/ios/Runner/GoogleService-Info.plist` |

---

## Known limitations

- **iOS IPA is unsigned.** Useful as a build verification artifact but users can't install it without re-signing. App Store / TestFlight distribution is handled separately in `app-distribution.yml`.
- **Android APK is `arm64-v8a` only.** The `.aab` covers all architectures for Play Store. If you need a sideloadable APK for older Android devices (armeabi-v7a) or emulators (x86_64), update the rename step in `release.yml` to also upload those splits.
- **Flutter version is pinned to `3.41.x`** in `release.yml` via the `FLUTTER_VERSION` env var. Bump there when upgrading Flutter so all four jobs move together.

---

## Source files

- `.github/workflows/cut-release.yml` — reads latest tag, pushes the next tag
- `.github/workflows/release.yml` — on tag push: resolves version from tag, builds, releases
- `apps/mobile/pubspec.yaml` — used for local dev only; ignored at release-build time
