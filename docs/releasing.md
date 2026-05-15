# Releasing Unishare

How to cut a release. The build/upload pipeline is fully automated — you just trigger a version bump.

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

- Reads `version: X.Y.Z+N` from `apps/mobile/pubspec.yaml`
- Computes the next version
- Commits the bump to `main`
- Tags `vX.Y.Z` and pushes the tag

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

Causes: tag already exists, branch protection blocks the bot, pubspec version line is malformed.

→ Nothing is on the remote. Fix the cause, re-run Cut Release.

### Cut Release pushed the tag, but a Release build job failed

The tag and version-bump commit are already on `main`. The Release exists (possibly with partial artifacts).

→ Actions → Release → click the failed run → "Re-run failed jobs". Other artifacts stay attached.

### You need to un-release

```bash
git push origin :refs/tags/vX.Y.Z      # delete remote tag
# Delete the GitHub Release in the UI
git revert <bump-commit-sha>           # undo the pubspec bump
git push origin main
```

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

### Branch protection on `main`

If `main` is protected, `github-actions[bot]` must be allowed to bypass the PR requirement so Cut Release can push the version-bump commit.

Settings → Branches → Branch protection rule for `main` → "Allow specified actors to bypass required pull requests" → add `github-actions[bot]`.

Alternative: create a PAT with `contents:write`, save as `RELEASE_TOKEN`, and replace `token: ${{ secrets.GITHUB_TOKEN }}` in `cut-release.yml` with `${{ secrets.RELEASE_TOKEN }}`.

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

- `.github/workflows/cut-release.yml` — the version-bump + tag-push trigger
- `.github/workflows/release.yml` — the build/upload pipeline
- `apps/mobile/pubspec.yaml` — version of record
