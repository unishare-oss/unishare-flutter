---
title: "0010: Achievement-only XP with event-driven badge evaluation"
description: "Points are awarded only by unlocking badges (not per action), and badges are evaluated by Cloud Function triggers extending the existing notification pipeline."
---

# 0010 — Achievement-only XP with event-driven badge evaluation

**Status:** ACCEPTED
**Author:** Pyae Sone Shin Thant
**Date:** 2026-05-18

## Problem

Unishare wants to recognise quality contribution before launch, but without creating a per-action grinding loop that incentivises low-effort posting. Whatever scoring mechanism we pick has to also support a future leaderboard (sortable score), real-time earn-moment UX (the user sees their badge pop seconds after triggering it), and resist spam from sybil rings and self-engagement.

Two coupled decisions had to be made together: (1) where do points come from, and (2) where does the badge-evaluation logic run?

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Point-per-action XP, badges as side milestones, evaluation embedded in trigger code | Familiar (Stack Overflow / Reddit), clear feedback per action | Strong grinding incentive — rational user posts as many low-effort items as possible; defending it needs quality multipliers, diminishing returns, deductions — significantly more machinery and still gameable |
| 2 | Achievement-only XP (points only from badges), event-driven evaluator extending existing Firestore triggers | No per-action grinding loop; one transactional grant per unlock; idempotent by doc id; real-time earn moments; fits the existing `onPostLiked` / `onRequestFulfilled` / `onCommentAdded` trigger pattern; cheat-proof | A few more triggers to maintain; counters need invariant upkeep across event types; needs a daily integrity sweep as belt-and-braces |
| 3 | Achievement-only XP, scheduled batch evaluator (every 5–15 min) | Centralised eval logic in one file; trivial to add new badges | Kills the "Bing! you earned X" moment for onboarding (modal arriving 7 minutes later isn't the same dopamine hit); scales poorly with user count; won't catch the high-stakes first-post flow |
| 4 | Badges only, no points or levels | Simplest possible model; no leaderboard incentive surface | Loses the legible "I'm a strong contributor" signal; leaderboards (v1.1) have nothing to rank by; rep-score reward type (F in the rewards menu) becomes impossible |

## Decision

**Chosen:** Option 2 — Achievement-only XP with event-driven Cloud Function evaluator.

Points are awarded **exclusively** by unlocking milestone badges; raw actions (creating a post, writing a comment, saving a post) increment denormalised counters but never directly grant points. Cloud Function triggers — extending the existing notification / engagement trigger pipeline — call a targeted `evaluateBadges(uid, changedStatKeys)` function that examines only the badges whose `condition.type` matches the changed stat. Newly-earned badges are written into `users/{uid}/earnedBadges/{badgeId}` and points / level are bumped in one Firestore transaction. The client streams the subcollection for real-time earn moments. A daily 03:00 ICT integrity sweep recomputes counters from source-of-truth queries and re-runs the evaluator to catch any trigger failures.

This combination removes the spam vector entirely (you can't grind points without unlocking a new milestone, and milestones are dominated by outcome-based conditions like "10 saves received" or "5 requests fulfilled" that require other users' validating actions), gives real-time UX, and slots into the codebase's existing trigger pattern without inventing new infrastructure.

It relies on the assumption that the evaluator's targeted query (`badges where active == true && condition.type IN changedStatKeys`) keeps eval cost O(small constant) even as the badge catalog grows, and that Firestore transactions make double-grants impossible. Both hold for the v1 catalog of 20 badges and the planned v1.1 expansion.

## Reversal Cost

**Medium.** The achievement-only XP shape is encoded across Cloud Functions, Firestore rules, Riverpod providers, and the badge catalog schema. Switching to a point-per-action model would require:

- Adding per-action point values to each trigger
- Replacing the badge-condition shape (currently `{type, threshold}` against a stat) with a more complex point-source model
- Migrating existing earnedBadges / gamification data to the new schema

It is reversible — we are pre-launch with no users — but the migration is more than a one-line config flip. Switching the evaluation site (Option 3, scheduled batch) is cheaper: same data model, different scheduler. The shape is the bigger commitment.

## Consequences

**Easier:**

- New badges added by editing `tools/seeds/badges.js` and re-running the seed; no client redeploy needed for catalog changes (only for badges that need new stats to be tracked, which require trigger work).
- Anti-abuse story is simple — there's nothing to abuse at the per-action level. Defences only have to cover sybil and self-engagement at the milestone level.
- Earn-moment UX is real-time and reliable (Firestore stream + idempotent write).
- Cloud Function code lives next to existing notification triggers, making counter maintenance and notification dispatch share patterns and tests.

**Harder:**

- Counters must be maintained carefully across `onCreate` and `onDelete` (and the moderation-removal path). A bug that leaves a counter out of sync produces silent wrong badge grants; the integrity sweep is the safety net but it isn't free.
- Adding a badge that needs a stat we don't already track means: new stat field, new trigger work to maintain it, possible backfill — not just a seed-file edit.
- The level-progress UX between badges is chunky (no continuous progress within a badge interval, since points only land when a badge unlocks). This is mostly hidden by always showing a "X / Y pts to Lv N+1" progress bar tied to total points, but users will notice the jumps. Considered acceptable.

**Follow-up decisions required:**

- v1.1 leaderboard ranking key — total points or some normalised "active points" decay-weighted by time since earn? Decide once we have launch data.
- Moderation revocation threshold — currently proposed at 3 strikes; revisit when moderation tools land.
- Whether to maintain `uniqueDepartmentsContributed` as an array (current spec, used for two badges) or a denormalised count for cleaner evaluator code. Defer to implementation.
