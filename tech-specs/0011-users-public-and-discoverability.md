---
title: "0011: users_public mirror + achievements discoverability"
description: "Public-safe user projection for cross-user UI plus three small discoverability surfaces for v1 achievements."
---

# SPEC-0011: users_public mirror + achievements discoverability

**Status:** DRAFT
**Author:** Pyae Sone Shin Thant
**Date:** 2026-05-18
**Proposal:** _none — lightweight v1.1 follow-up to [PROP-0010](../tech-proposals/0010-achievements.md)_
**Approved by:** (pending)

---

## Overview

Two coupled deliverables. (1) Introduce a `users_public/{uid}` Firestore collection that mirrors the public-safe subset of `users/{uid}` (name, photoUrl, bio, gamification.level, gamification.selectedTitle, gamification.displayedBadges). Server-maintained by a Cloud Function trigger; public-readable. This unblocks any cross-user gamification surface, which is currently blocked because v1's owner-only `users/{uid}` rule keeps the private collection from being read by other users. (2) Use that mirror to ship three small discoverability tweaks: a tappable `LevelChip`, an "Achievements" entry in the More drawer, and a level chip next to author names on `PostCard`.

## Architecture

```mermaid
flowchart LR
    subgraph Client[Flutter App]
        PC[PostCard]
        PA[ProfileCard]
        MD[MoreDrawer]
        AS[AchievementsScreen]
    end

    subgraph Firestore
        UPriv[users/{uid}<br/>owner-only]
        UPub[users_public/{uid}<br/>public read]
    end

    subgraph CloudFns
        Sync[onUserChangedPublicSync]
    end

    UPriv -- onUpdate --> Sync
    Sync -- diff-and-skip<br/>set merge:true --> UPub

    PC -- watches by authorId --> UPub
    PA -- watches own --> UPriv
    MD -- new tile --> AS
```

**Boundary:** the client never writes to `users_public/{uid}`. Profile edits write `users/{uid}`; the trigger fans out the public projection.

## Data Model

### Firestore — `users_public/{uid}`

```json
{
  "uid": "abc123",
  "name": "Jane Doe",
  "photoUrl": "https://...",
  "bio": "MSc CS — focus on theory and algorithms.",
  "level": 3,
  "selectedTitle": "first_post",
  "displayedBadges": ["first_post", "first_save_given", "helpful_hand"],
  "updatedAt": "<ts>"
}
```

**Excluded** (stay private in `users/{uid}`): `email`, `enrollmentYear`, `role`, `departmentId`, `universityId`, `stats`, `gamification.totalPoints`, `gamification.earnedBadgesCache`, FCM tokens, fcm subscription state, etc.

**Note on `bio`:** included because the contributor-display use case needs context. This is a behavioral change from v1 (where bio was effectively private — only owners could read their own `users/{uid}`). Mitigation:
- One-time in-app notice on next sign-in: "Your bio is now visible to other students. Edit it on your profile if needed." Dismissible toast with a button to open profile.
- No content filter / length cap in v1.1 — bios remain freeform. Add length cap later if abuse appears.

### Firestore — `users/{uid}` (unchanged)

Continues to hold the full private user doc. Owner-only read.

## File map

### Cloud Functions

| Action | Path | Responsibility |
|---|---|---|
| Create | `functions/src/triggers/onUserChangedPublicSync.ts` | Diff public-projection between before/after; if changed, `set({ merge: true })` to `users_public/{uid}`. Diff-and-skip loops by exiting early when the projection is identical. |
| Create | `functions/src/lib/publicUserProjection.ts` | Pure function: takes a `users/{uid}` doc and returns the `users_public/{uid}` projection (or `null` if the doc is incomplete). Unit-tested. |
| Create | `functions/test/lib/publicUserProjection.test.ts` | Table-driven tests for the projection function. |
| Create | `functions/test/triggers/onUserChangedPublicSync.test.ts` | Mock-based test: same input pre/post → no write; differing input → exactly one write with the expected projection. |
| Modify | `functions/src/index.ts` | Export `onUserChangedPublicSync`. |
| Modify | `functions/src/triggers/onUserDeleted.ts` (or wherever the cascade lives) | Delete `users_public/{uid}` when the user is deleted. _Note: there's no existing user-deletion handler in the codebase per the v1 plan deferral. If still none in v1.1, defer this to the same future feature._ |

### Firestore rules + indexes

| Action | Path | Responsibility |
|---|---|---|
| Modify | `firestore.rules` | Add `match /users_public/{uid}` — `allow read: if request.auth != null; allow write: if false;`. |

### Seeds + backfill

| Action | Path | Responsibility |
|---|---|---|
| Create | `tools/backfill_users_public.js` | One-off script. Reads every `users/{uid}`, computes projection, batched-writes to `users_public/{uid}`. Idempotent. Skip users where projection returns `null`. |

### Flutter app

| Action | Path | Responsibility |
|---|---|---|
| Create | `apps/mobile/lib/features/achievements/domain/entities/public_user.dart` | Pure-Dart entity matching the projection. |
| Create | `apps/mobile/lib/features/achievements/data/models/public_user_dto.dart` | Freezed DTO; `fromSnapshot` factory. |
| Create | `apps/mobile/lib/features/achievements/data/datasources/public_user_firestore_datasource.dart` | `watch(uid)` and `watchMany(Iterable<uid>)` (per-uid stream so Riverpod auto-dedupes). |
| Create | `apps/mobile/lib/features/achievements/presentation/providers/public_user_provider.dart` | `@riverpod Stream<PublicUser?> publicUser(Ref ref, String uid)`. |
| Modify | `apps/mobile/lib/features/achievements/presentation/widgets/level_chip.dart` | Wrap in `InkWell` with `onTap` parameter (optional, no behavior change at call site when null). |
| Modify | `apps/mobile/lib/features/profile/presentation/widgets/profile_card.dart` | Wire `onTap` on the level chip → `/achievements/<user.id>`. |
| Modify | `apps/mobile/lib/features/feed/presentation/widgets/post_card.dart` | Inline `LevelChip` next to author name. Watches `publicUserProvider(post.authorId)` — falls back to no chip if loading / null. |
| Modify | `apps/mobile/lib/features/more/presentation/widgets/more_drawer_grid.dart` | Add fifth "ACHIEVEMENTS" tile alongside SAVED / DEPARTMENTS / REQUESTS / PROFILE. Grid becomes 5-wide or wraps; spec is "tile renders, navigation to `/achievements/<currentUid>` works". |
| Modify | `apps/mobile/lib/features/more/presentation/widgets/more_drawer.dart` | Pass `onAchievementsTap` callback. |
| Create | `apps/mobile/lib/features/profile/presentation/widgets/bio_visibility_notice.dart` | Dismissible amber banner shown once after launch. Persisted via Hive `bio_visibility_dismissed: true`. Banner copy + "OK, got it" button + "Edit profile" button. |
| Modify | `apps/mobile/lib/features/profile/presentation/screens/profile_screen.dart` | Mount the bio-visibility notice above the profile card. |
| Modify | `apps/mobile/lib/main.dart` | Open the `users_public` Hive box if we add one (or reuse `settings`). |

### Tests

| Action | Path | Responsibility |
|---|---|---|
| Create | `apps/mobile/test/widget/features/achievements/level_chip_test.dart` | Tappable variant: tapping pushes the expected route. |
| Create | `apps/mobile/test/widget/features/feed/post_card_level_chip_test.dart` | Renders chip when public user loads; renders nothing when null / loading. |
| Create | `apps/mobile/test/widget/features/more/more_drawer_grid_test.dart` (or update existing) | Achievements tile renders and navigates. |
| Create | `apps/mobile/test/widget/features/profile/bio_visibility_notice_test.dart` | Renders once, dismissed state persists, "Edit profile" navigates to /profile. |

## API contracts

### Pure projection function

```ts
// functions/src/lib/publicUserProjection.ts
export interface PublicUserDoc {
  uid: string;
  name: string;
  photoUrl: string | null;
  bio: string | null;
  level: number;
  selectedTitle: string | null;
  displayedBadges: string[];
}

/**
 * Returns the public projection of a `users/{uid}` doc, or null when the
 * doc doesn't have enough information to expose publicly (e.g., during the
 * brief window after auth account create + before profile is set).
 *
 * Pure — server-only — caller passes the raw Firestore data.
 */
export function publicUserProjection(
  uid: string,
  data: Record<string, unknown> | undefined,
): PublicUserDoc | null;
```

### Trigger contract

```ts
export const onUserChangedPublicSync = onDocumentUpdated(
  'users/{uid}',
  /* handler: diff projection, skip if unchanged, else set merge:true */
);
```

Behaviour:
- Compute `before` and `after` projections.
- If projection is unchanged (deep equal), return without writing.
- Else `set({ merge: true })` to `users_public/{uid}` with `after` + a server timestamp.

### Riverpod provider

```dart
@riverpod
Stream<PublicUser?> publicUser(Ref ref, String uid);
```

Returns `null` while loading or if doc is missing. Consumers fall back to no chip in that case.

## UX Contracts

### Tappable `LevelChip`

Existing `LevelChip(level: 5)` keeps working unchanged. New optional `onTap` parameter:
```dart
LevelChip(level: 5, onTap: () => context.push('/achievements/<uid>'))
```
When `onTap` is provided, the chip is wrapped in a `Material(transparent) + InkWell` with a borderRadius matching the chip (4px). Tap ripple confined to the chip.

### More drawer "Achievements" tile

Fifth tile in `MoreDrawerGrid`. Label: `ACHIEVEMENTS`. Icon: `Icons.workspace_premium_outlined`. Tap closes the drawer and navigates to `/achievements/<currentUid>`. Grid layout becomes either 5-wide (compact) or 2-row.

### PostCard level chip

Inline next to the author display name. Size 18dp (smaller than the 24dp profile chip — it's a label, not a control). Hidden when:
- `post.postingIdentity == PostingIdentity.anonymous`
- `publicUser(post.authorId)` is loading or null
- Level == 1 (clutter reduction — anyone who hasn't earned anything yet doesn't need a chip)

### Bio visibility notice

One-time amber banner above the profile card on first launch after v1.1. Copy: "Your bio is now visible to other students. Tap to review or edit." Two buttons: "Edit profile" → `/profile` edit, "Got it" → dismiss. Persisted via Hive key `bio_visibility_notice_dismissed: bool`. Shown only when:
- User is signed in
- Hive key is unset
- User has a non-empty bio (no reason to nag users with empty bios)

## Security & Anti-Abuse

### Rule additions

```
match /users_public/{uid} {
  allow read: if request.auth != null;
  allow write: if false;
}
```

### Loop prevention

The trigger fires on `users/{uid}` onUpdate. Diff-and-skip ensures that:
- The trigger doesn't write to its own watched path (it writes to `users_public/{uid}`).
- The `onProfileUpdated` trigger's writes to `stats.profileCompleted` don't cause `users_public` rewrites because the projection ignores stats.
- The evaluator's writes to `gamification.totalPoints` / `earnedBadgesCache` don't cause rewrites because the projection ignores those fields too.
- Only changes to `name`, `photoUrl`, `bio`, `gamification.level`, `gamification.selectedTitle`, or `gamification.displayedBadges` actually flow through to a write.

### Bio privacy

Mitigations beyond the in-app notice are intentionally out of scope. If abuse surfaces:
- Add length cap (280 char) in the projection function — cheap.
- Add URL / phone regex stripping — moderately complex, can wait until needed.

## Test plan

| Test file | Covers |
|---|---|
| `functions/test/lib/publicUserProjection.test.ts` | All-fields-present → full projection. Missing required field → null. Optional fields default appropriately. |
| `functions/test/triggers/onUserChangedPublicSync.test.ts` | (1) Same projection pre/post → no write. (2) Name changes → one write. (3) Only stats change → no write. (4) Only `gamification.totalPoints` change → no write. (5) `gamification.level` change → one write. |
| `apps/mobile/test/widget/features/achievements/level_chip_test.dart` | Renders without InkWell when no onTap. With onTap, tapping triggers callback. |
| `apps/mobile/test/widget/features/feed/post_card_level_chip_test.dart` | Anonymous post → no chip. publicUser loading → no chip. Level 1 → no chip. Level 2+ → chip with correct level. |
| `apps/mobile/test/widget/features/more/more_drawer_grid_test.dart` | Achievements tile renders, tapping calls `onAchievementsTap`. |
| `apps/mobile/test/widget/features/profile/bio_visibility_notice_test.dart` | Renders when Hive flag unset + bio non-empty. Hidden when dismissed. "Got it" persists flag. |

### Coverage targets

- Projection function: 100%.
- Trigger: 100% of branches via mock-based tests.
- Flutter widgets: covered by widget tests above.

## Out of scope

- **Leaderboards** — needs `users_public` but also new screens / ranking queries. Separate spec.
- **Ajarn recognition (L2)** — needs a `role: 'faculty'` flag and faculty-only UI. Separate spec.
- **Cosmetic profile accents** at Lv 10/20 — pure design work, not blocked on infrastructure.
- **Account-deletion cascade** for `users_public/{uid}` — depends on the broader user-deletion feature still being absent.
- **PostCard level chip authored-by-current-user case** — works via `userGamificationProvider` (faster, owner-readable), but for v1.1 simplicity we use `publicUserProvider` everywhere on PostCard. One-frame staleness vs your own actions is acceptable.
- **Realtime level-up animation on PostCard chip** — when the chip ticks up, no special FX; the existing earn-moment modal carries the celebration.

## Open questions

- [ ] Confirm Hive key naming for the bio-visibility dismissal. Proposed: `bio_visibility_notice_dismissed` in the existing `settings` box.
- [ ] Confirm 5-tile More-drawer grid layout (5-wide vs 2-row). Depends on tablet visual.
- [ ] Whether to add a `client_version` field to the projection so clients can detect schema drift if we add fields later (defer if not obviously useful).
