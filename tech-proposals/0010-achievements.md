---
title: "0010: Achievements System"
description: "Achievement-only XP system with tiered badges to incentivize quality contribution to Unishare."
---

# PROP-0010: Achievements System

**Status:** PROPOSED
**Author:** Pyae Sone Shin Thant
**Date:** 2026-05-18
**Spec:** [SPEC-0010](../tech-specs/0010-achievements.md)
**Approved by:** (pending)

---

## Problem

Unishare is a content-sharing platform for academic materials, but contributing has no built-in feedback loop. A student who shares 50 high-quality CSE101 notes that get saved hundreds of times looks identical, on their profile, to one who joined yesterday. There is:

- **No signal of contribution** — profiles show post count, comment count, and saved count as raw numbers, with no notion of milestones or quality.
- **No incentive to share** — first-time contributors have nothing pulling them past the cold-start cliff (sign up → look around → leave without posting).
- **No way to surface community helpers** — students fulfilling each other's requests, contributing across departments, or receiving many saves go unrecognized.
- **No hook for future faculty / sponsor partnerships** — we have nothing to point at when asking ajarns or local businesses to recognize top contributors.

Unishare is pre-launch, so this is the right window to design the contribution-recognition layer before behavioural patterns are set.

## Proposed Solution

A four-piece **achievement system** built Firebase-native, fitting the existing Cloud Function trigger pattern.

1. **Badges as the only point source.** Doing actions (posting, commenting, saving) does not award points. Crossing milestone thresholds — "first post", "10 saves received", "5 requests fulfilled" — unlocks badges, and each badge carries a point value. Points roll up into a level (lookup table, tunable in Firestore). This removes per-action grinding incentives entirely.

2. **Tiered milestones for spam resistance.** Three tiers: **onboarding** (action-based, fast wins — intentionally gameable because gaming = doing exactly what new users should do), **progression** (mostly outcome-based: saves received, requests fulfilled, validated by *other users'* actions), **prestige** (pure outcome, rare). Quality-resistant badges are the bulk of the catalog.

3. **Server-authoritative evaluation.** Cloud Function triggers extend the existing notification / post-interaction triggers. Each interesting event updates denormalised counters on the user doc; an evaluator function targets only the badges whose condition matches the changed stat and writes the unlock atomically. Real-time, cheat-proof, and idempotent.

4. **Four v1 surfaces:** profile-card integration (level chip + selected title + displayed badges row + progress bar), dedicated `/achievements` screen, in-app earn moments (modal for onboarding/prestige/level-up, toast for progression), and a notification-feed entry per unlock (reusing the notification system already shipped in SPEC-0001).

**v1 launch set:** 20 badges spanning content, community, profile, and recognition categories. Selectable title (one earned badge name) and three displayed badges per user.

**Explicit out of scope for v1, deferred to v1.1:** department / semester leaderboards (need real activity data to tune); ajarn recognition button + ajarn-related badges (needs a faculty role on accounts); cosmetic profile accents at higher levels.

**Explicit out of scope permanently:** daily streaks / engagement-loop badges (we want quality contribution, not daily-active mechanics); paywalled feature unlocks (status-driven, not capability-driven); tangible / sponsored rewards in-app (will be handled as out-of-band partnerships if at all).

## Alternatives Considered

### A — Point-per-action XP (Stack Overflow / Reddit karma model)

Every action grants points: post = 10, save received = 2, request fulfilled = 15, etc. Badges unlock at point thresholds. Levels derived from total points.

**Rejected:** Creates a per-action grinding loop. The rational behaviour becomes "post as many low-effort items as possible," which is the *opposite* of what we want. Defending it requires complex point formulas, daily diminishing returns, quality multipliers, and moderation deductions — significantly more machinery than the achievement-only model, and easier to game in subtle ways.

### B — Badges only, no points or levels

Earn discrete badges. Display them. No numeric score, no leaderboard.

**Rejected:** Loses the "single legible 'I'm a strong contributor'" signal users want and that the future leaderboard (J in the rewards menu) needs to rank by. Badges alone don't sort. The chosen design awards points *only* via badges, but the points exist as a side-effect, which gives us a sortable score for free without re-introducing per-action grinding.

### C — Engagement-loop system (daily streaks, daily challenges, "log in 7 days in a row")

Duolingo / Snapchat / Strava-style daily mechanics.

**Rejected:** This would optimise for daily-active retention, not contribution quantity or quality — explicitly the wrong goal for Unishare per the brainstorming conversation. Worth revisiting if retention becomes a problem post-launch, but not v1.

### D — Tangible rewards (gift cards, vouchers) and in-app paywalled feature unlocks

Either reward top contributors with real-world value, or gate product features behind level/achievement requirements.

**Rejected for v1:** Tangible rewards need a sponsor / partnership program, fulfillment ops, and fraud protection — none of which exist today. Paywalled feature unlocks turn the achievement system into a progression gate on product value, which makes the app feel mean to new users. We deferred a *placeholder* faculty-recognition feature (L2) to v1.1 instead, which signals partnership intent without locking anyone out of features.

### E — Scheduled-batch badge evaluation (vs event-driven)

A single scheduled Cloud Function runs every 5–15 minutes, scanning all users and granting any newly-earned badges. Centralised eval logic, easy to add new badges by editing one file.

**Rejected:** Kills the real-time earn-moment UX (modal/toast popping seconds after the user makes their first post is what makes the system feel alive). Scales poorly with user count. Event-driven triggers fit the existing codebase pattern (the project already uses Firestore triggers for notifications and request fulfillment) and auto-deploy on push to main via CI.

## Open Questions

1. **Glyph family for badges** — preliminary direction is Phosphor (thin weight) via a Flutter package for refined, consistent line work without an asset pipeline. Alternative: outlined Material Symbols only (no new dep). To be confirmed during spec implementation; either is reversible in a single seed-file edit. *(Resolved during spec-writing: Phosphor.)*
2. **Daily integrity sweep window** — the spec proposes 03:00 ICT. Confirm with the team before scheduling.
3. **Moderation-strike threshold** — the spec proposes badge revocation at 3 moderation-removed posts. Open for adjustment when moderation tools land.

## Acceptance Criteria

- Users earn badges via Cloud Function triggers; no client can grant a badge to itself.
- Earning a badge writes one `users/{uid}/earnedBadges/{badgeId}` document, bumps `users/{uid}.gamification.totalPoints`, and recomputes `gamification.level` — atomically.
- The catalog of 20 v1 badges is seeded from `tools/seeds/badges.js` via the existing `seed_firestore.js` workflow, idempotently.
- Profile screen shows level chip on the name row, selected title under the name, up to 3 displayed badges, and a level-progress bar — always visible (empty state uses muted placeholders).
- A dedicated `/achievements` screen renders earned + locked badges with hints.
- Earning a badge fires the in-app earn moment (modal for onboarding/prestige/level-up, toast otherwise) when the user is on a "rest" surface; queues if the user is in a compose flow.
- Earning a badge also writes a notification doc via the existing notification system.
- All UI uses existing theme tokens (`ac.*`, `cs.*`, `theme.textTheme.*`, Space Grotesk / Fira Code) — no hardcoded colors or text styles.
- Firestore rules deny client writes to `stats`, `earnedBadges`, and `gamification.totalPoints` / `gamification.level`; allow client writes to `gamification.displayedBadges` (cap 3, must be earned) and `gamification.selectedTitle` (must be earned).
- Server-side evaluator and triggers reach ≥ 90% test coverage; Domain & pure helpers reach 100%; widget tests cover empty / populated / locked states for the profile section, achievements screen, picker, and earn moments.
- Integration test demonstrates end-to-end first-post → badge-earn → modal flow against the Firebase Emulator.
