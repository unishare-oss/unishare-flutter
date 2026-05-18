# Achievements System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the v1 achievements system per SPEC-0010 — Cloud Function triggers maintain user-stat counters, an event-driven evaluator atomically grants milestone badges with points and recomputes level, and four Flutter surfaces (profile card section, dedicated `/achievements` screen, in-app earn moments, notification feed entries) surface progress in real-time.

**Architecture:** Achievement-only XP — points come exclusively from badge unlocks, never from raw actions. 20 v1 badges across onboarding / progression / prestige tiers are seeded into Firestore. Cloud Function triggers extend the existing notification pipeline to keep `users/{uid}.stats` counters in sync and call `evaluateBadges(uid, changedStatKeys)`, which writes earned badges + points + level in one transaction. The Flutter app streams the `earnedBadges` subcollection for real-time UX. Firestore rules deny client writes to all server-managed fields.

**Tech Stack:** Flutter / Riverpod (with code-gen) / Freezed / GoRouter / Hive / Cloud Firestore / Cloud Functions (TypeScript / Firebase Admin SDK) / Phosphor Flutter / Firebase Emulator.

**References:**
- [PROP-0010](../../../tech-proposals/0010-achievements.md)
- [SPEC-0010](../../../tech-specs/0010-achievements.md)
- [ADR-0010](../../decisions/0010-achievement-only-xp-and-event-driven-evaluation.md)

**Phases (each independently testable):**
- **Phase 0** — Seeds (badge catalog + level config in Firestore)
- **Phase 1** — Cloud Functions: counters, evaluator, triggers
- **Phase 2** — Firestore rules
- **Phase 3** — Flutter Domain layer (pure Dart entities + repositories)
- **Phase 4** — Flutter Data layer (Freezed DTOs + Firestore datasources + repo impls)
- **Phase 5** — Flutter Presentation: providers + display widgets
- **Phase 6** — Earn-moment dispatcher + routing
- **Phase 7** — Integration tests + goldens

Each task is TDD where applicable: write failing test → run to confirm failure → minimal implementation → run to confirm pass → commit. Pure-pipeline tasks (codegen, route wiring) skip the test step where there's nothing meaningful to assert.

---

## Phase 0 — Seeds

Adds the 20-badge catalog and the level-threshold lookup to Firestore via the existing `tools/seed_firestore.js` workflow. Idempotent — re-running on catalog changes updates definitions without touching `users/{uid}/earnedBadges` history.

### Task 0.1: Badge catalog seed file

**Files:**
- Create: `tools/seeds/badges.js`

- [ ] **Step 1: Create the seed file**

```js
// tools/seeds/badges.js
module.exports = [
  { id: 'profile_complete', name: 'Set the Stage', description: 'Complete your profile so others know who you are.', glyph: 'user-circle', points: 10, tier: 'onboarding', category: 'profile', condition: { type: 'profileCompleted', threshold: 1 }, order: 1, active: true },
  { id: 'first_post', name: 'First Steps', description: 'Share your first post with the community.', glyph: 'paper-plane-tilt', points: 15, tier: 'onboarding', category: 'content', condition: { type: 'postsCreated', threshold: 1 }, order: 2, active: true },
  { id: 'first_save_given', name: 'Curator', description: 'Save your first post from someone else.', glyph: 'bookmark-simple', points: 10, tier: 'onboarding', category: 'content', condition: { type: 'savesGiven', threshold: 1 }, order: 3, active: true },
  { id: 'first_comment', name: 'Conversation Starter', description: 'Leave your first comment.', glyph: 'chat-circle-dots', points: 10, tier: 'onboarding', category: 'community', condition: { type: 'commentsWritten', threshold: 1 }, order: 4, active: true },
  { id: 'first_request', name: 'Ask the Community', description: 'Create your first request.', glyph: 'hand-waving', points: 10, tier: 'onboarding', category: 'community', condition: { type: 'requestsCreated', threshold: 1 }, order: 5, active: true },
  { id: 'first_save_received', name: 'Someone Found It Useful', description: 'Receive your first save on a post you shared.', glyph: 'sparkle', points: 20, tier: 'onboarding', category: 'content', condition: { type: 'savesReceived', threshold: 1 }, order: 6, active: true },

  { id: 'steady_sharer', name: 'Steady Sharer', description: 'Share 10 posts with the community.', glyph: 'stack', points: 30, tier: 'progression', category: 'content', condition: { type: 'postsCreated', threshold: 10 }, order: 10, active: true },
  { id: 'useful', name: 'Useful', description: 'Receive 10 saves on your posts.', glyph: 'lightbulb', points: 40, tier: 'progression', category: 'content', condition: { type: 'savesReceived', threshold: 10 }, order: 11, active: true },
  { id: 'notes_master', name: 'Notes Master', description: 'Have 5 of your posts saved by at least one person.', glyph: 'notebook', points: 50, tier: 'progression', category: 'content', condition: { type: 'postsWithAtLeastOneSave', threshold: 5 }, order: 12, active: true },
  { id: 'active_voice', name: 'Active Voice', description: 'Write 25 comments.', glyph: 'chats', points: 30, tier: 'progression', category: 'community', condition: { type: 'commentsWritten', threshold: 25 }, order: 13, active: true },
  { id: 'helpful_hand', name: 'Helpful Hand', description: 'Help fulfill 5 requests from other students.', glyph: 'hand-heart', points: 50, tier: 'progression', category: 'community', condition: { type: 'requestsFulfilled', threshold: 5 }, order: 14, active: true },
  { id: 'cross_discipline', name: 'Cross-Discipline', description: 'Contribute posts to 3 different departments.', glyph: 'compass', points: 40, tier: 'progression', category: 'recognition', condition: { type: 'uniqueDepartmentsCount', threshold: 3 }, order: 15, active: true },
  { id: 'well_versed', name: 'Well-Versed', description: 'Share 25 posts.', glyph: 'books', points: 30, tier: 'progression', category: 'content', condition: { type: 'postsCreated', threshold: 25 }, order: 16, active: true },
  { id: 'lend_an_ear', name: 'Lend an Ear', description: 'Write 50 comments.', glyph: 'ear', points: 30, tier: 'progression', category: 'community', condition: { type: 'commentsWritten', threshold: 50 }, order: 17, active: true },
  { id: 'community_anchor', name: 'Community Anchor', description: 'Help fulfill 10 requests.', glyph: 'anchor', points: 60, tier: 'progression', category: 'community', condition: { type: 'requestsFulfilled', threshold: 10 }, order: 18, active: true },

  { id: 'beloved', name: 'Beloved', description: 'Receive 100 saves on your posts.', glyph: 'crown-simple', points: 100, tier: 'prestige', category: 'content', condition: { type: 'savesReceived', threshold: 100 }, order: 20, active: true },
  { id: 'pillar', name: 'Pillar of the Community', description: 'Help fulfill 25 requests.', glyph: 'tree', points: 100, tier: 'prestige', category: 'community', condition: { type: 'requestsFulfilled', threshold: 25 }, order: 21, active: true },
  { id: 'trusted_source', name: 'Trusted Source', description: 'Have 50 distinct people save your posts.', glyph: 'seal-check', points: 100, tier: 'prestige', category: 'content', condition: { type: 'uniqueSaversCount', threshold: 50 }, order: 22, active: true },
  { id: 'renaissance', name: 'Renaissance Contributor', description: 'Contribute posts to 5 different departments.', glyph: 'globe', points: 100, tier: 'prestige', category: 'recognition', condition: { type: 'uniqueDepartmentsCount', threshold: 5 }, order: 23, active: true },
  { id: 'legacy', name: 'Class of {year}', description: 'Awarded to top contributors per department at semester end.', glyph: 'medal', points: 50, tier: 'prestige', category: 'recognition', condition: { type: 'semesterCohort', threshold: 1 }, order: 24, active: true },
];
```

Note: `uniqueDepartmentsContributed` is stored as an array on the user; we expose its size as a derived stat key `uniqueDepartmentsCount` in the evaluator so all conditions are simple `value >= threshold` comparisons.

### Task 0.2: Level threshold seed file

**Files:**
- Create: `tools/seeds/app_config_levels.js`

- [ ] **Step 1: Create the seed file**

```js
// tools/seeds/app_config_levels.js
module.exports = {
  thresholds: [
    { level: 1, cumulative: 0 },
    { level: 2, cumulative: 30 },
    { level: 3, cumulative: 80 },
    { level: 4, cumulative: 150 },
    { level: 5, cumulative: 250 },
    { level: 6, cumulative: 400 },
    { level: 7, cumulative: 600 },
    { level: 8, cumulative: 900 },
    { level: 9, cumulative: 1300 },
    { level: 10, cumulative: 1800 },
  ],
  perLevelAbove10: 500,
};
```

### Task 0.3: Extend the seed runner

**Files:**
- Modify: `tools/seed_firestore.js`

- [ ] **Step 1: Add imports and two new seeding steps**

In `tools/seed_firestore.js`, add to the top alongside other `require` calls:

```js
const badges = require('./seeds/badges');
const appConfigLevels = require('./seeds/app_config_levels');
```

After the existing `seed()` function, add the new functions before its closing `}`:

```js
async function seedBadges() {
  console.log('Seeding badges...');
  const batch = db.batch();
  for (const b of badges) {
    batch.set(db.collection('badges').doc(b.id), b, { merge: true });
  }
  await batch.commit();
  console.log(`  ${badges.length} badges seeded.`);
}

async function seedAppConfig() {
  console.log('Seeding app_config/levels...');
  await db.collection('app_config').doc('levels').set(appConfigLevels, { merge: true });
  console.log('  levels seeded.');
}
```

Then within the existing `seed()` function body, after the existing universities / departments / courses calls, add:

```js
  await seedBadges();
  await seedAppConfig();
```

- [ ] **Step 2: Dry-run sanity-check (no commit)**

Run: `cd tools && node -e "const b = require('./seeds/badges'); console.log(b.length, b.every(x => x.id && x.condition.type && x.points))"`
Expected: `20 true`

- [ ] **Step 3: Commit**

```bash
git add tools/seeds/badges.js tools/seeds/app_config_levels.js tools/seed_firestore.js
git commit -m "feat(achievements): add badge catalog and level seeds"
```

### Task 0.4: Run the seed against the dev project

**Files:**
- (none — runtime action)

- [ ] **Step 1: Verify service-account file exists**

Run: `ls tools/service-account.json`
Expected: file is present (it's gitignored, but should exist locally per CLAUDE.md). If missing, fetch from Firebase Console → Project Settings → Service accounts.

- [ ] **Step 2: Run the seed**

Run: `cd tools && node seed_firestore.js service-account.json`
Expected: existing seed output for universities/departments/courses, followed by `Seeding badges... 20 badges seeded. Seeding app_config/levels... levels seeded.`

- [ ] **Step 3: Verify in Firebase Console**

Open the Firestore tab, confirm `badges/first_post` exists with the expected fields and `app_config/levels` contains the thresholds array.

---

## Phase 1 — Cloud Functions: counters and evaluator

Builds the server-side core: counter triggers extending existing pipelines, the targeted badge evaluator, and the daily integrity sweep.

### Task 1.1: Stat key + level lookup types

**Files:**
- Create: `functions/src/badges/types.ts`

- [ ] **Step 1: Create the types module**

```ts
// functions/src/badges/types.ts
export type StatKey =
  | 'postsCreated'
  | 'savesReceived'
  | 'postsWithAtLeastOneSave'
  | 'uniqueSaversCount'
  | 'requestsFulfilled'
  | 'requestsCreated'
  | 'commentsWritten'
  | 'savesGiven'
  | 'uniqueDepartmentsCount'
  | 'profileCompleted';

export type BadgeTier = 'onboarding' | 'progression' | 'prestige';
export type BadgeCategory = 'content' | 'community' | 'profile' | 'recognition';

export interface BadgeDoc {
  id: string;
  name: string;
  description: string;
  glyph: string;
  points: number;
  tier: BadgeTier;
  category: BadgeCategory;
  condition: { type: StatKey; threshold: number };
  order: number;
  active: boolean;
}

export interface UserStats {
  postsCreated: number;
  savesReceived: number;
  postsWithAtLeastOneSave: number;
  uniqueSaversCount: number;
  requestsFulfilled: number;
  requestsCreated: number;
  commentsWritten: number;
  savesGiven: number;
  uniqueDepartmentsContributed: string[];
  profileCompleted: boolean;
  moderationFlags: number;
  updatedAt: FirebaseFirestore.Timestamp | null;
}

export interface LevelThreshold {
  level: number;
  cumulative: number;
}

export interface LevelConfig {
  thresholds: LevelThreshold[];
  perLevelAbove10: number;
}

export const EMPTY_STATS: UserStats = {
  postsCreated: 0,
  savesReceived: 0,
  postsWithAtLeastOneSave: 0,
  uniqueSaversCount: 0,
  requestsFulfilled: 0,
  requestsCreated: 0,
  commentsWritten: 0,
  savesGiven: 0,
  uniqueDepartmentsContributed: [],
  profileCompleted: false,
  moderationFlags: 0,
  updatedAt: null,
};

export function statValue(stats: UserStats, key: StatKey): number {
  switch (key) {
    case 'profileCompleted': return stats.profileCompleted ? 1 : 0;
    case 'uniqueDepartmentsCount': return stats.uniqueDepartmentsContributed.length;
    default: return stats[key] as number;
  }
}
```

### Task 1.2: Level-for-points function (TDD)

**Files:**
- Create: `functions/test/badges/levelForPoints.test.ts`
- Create: `functions/src/badges/levelForPoints.ts`

- [ ] **Step 1: Write the failing tests**

```ts
// functions/test/badges/levelForPoints.test.ts
import { describe, it, expect } from 'vitest';
import { levelForPoints } from '../../src/badges/levelForPoints';
import type { LevelConfig } from '../../src/badges/types';

const config: LevelConfig = {
  thresholds: [
    { level: 1, cumulative: 0 },
    { level: 2, cumulative: 30 },
    { level: 3, cumulative: 80 },
    { level: 10, cumulative: 1800 },
  ],
  perLevelAbove10: 500,
};

describe('levelForPoints', () => {
  it('returns 1 for 0 points', () => {
    expect(levelForPoints(0, config)).toBe(1);
  });
  it('returns 1 just below the level-2 threshold', () => {
    expect(levelForPoints(29, config)).toBe(1);
  });
  it('returns 2 exactly at the level-2 threshold', () => {
    expect(levelForPoints(30, config)).toBe(2);
  });
  it('returns 10 at the level-10 cumulative', () => {
    expect(levelForPoints(1800, config)).toBe(10);
  });
  it('extrapolates linearly beyond level 10', () => {
    expect(levelForPoints(2300, config)).toBe(11);
    expect(levelForPoints(2800, config)).toBe(12);
    expect(levelForPoints(2299, config)).toBe(10);
  });
});
```

- [ ] **Step 2: Run to confirm failure**

Run: `cd functions && npx vitest run test/badges/levelForPoints.test.ts`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement**

```ts
// functions/src/badges/levelForPoints.ts
import type { LevelConfig } from './types';

export function levelForPoints(points: number, config: LevelConfig): number {
  const sorted = [...config.thresholds].sort((a, b) => a.cumulative - b.cumulative);
  let current = 1;
  let lastCumulative = 0;
  let lastLevel = 1;
  for (const t of sorted) {
    if (points >= t.cumulative) {
      current = t.level;
      lastCumulative = t.cumulative;
      lastLevel = t.level;
    } else {
      break;
    }
  }
  if (lastLevel >= 10 && config.perLevelAbove10 > 0) {
    const extra = Math.floor((points - lastCumulative) / config.perLevelAbove10);
    return lastLevel + extra;
  }
  return current;
}
```

- [ ] **Step 4: Run to confirm pass**

Run: `cd functions && npx vitest run test/badges/levelForPoints.test.ts`
Expected: PASS — 5 tests.

- [ ] **Step 5: Commit**

```bash
git add functions/src/badges/types.ts functions/src/badges/levelForPoints.ts functions/test/badges/levelForPoints.test.ts
git commit -m "feat(achievements): add stat-key types and level lookup helper"
```

### Task 1.3: Evaluator (TDD)

**Files:**
- Create: `functions/test/badges/evaluateBadges.test.ts`
- Create: `functions/src/badges/evaluateBadges.ts`

- [ ] **Step 1: Write the failing tests**

```ts
// functions/test/badges/evaluateBadges.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { initializeTestApp, clearFirestore } from '../helpers/emulator';
import { evaluateBadges } from '../../src/badges/evaluateBadges';

describe('evaluateBadges', () => {
  let db: FirebaseFirestore.Firestore;

  beforeEach(async () => {
    db = await initializeTestApp();
    await clearFirestore();
    await db.collection('app_config').doc('levels').set({
      thresholds: [
        { level: 1, cumulative: 0 },
        { level: 2, cumulative: 30 },
        { level: 3, cumulative: 80 },
      ],
      perLevelAbove10: 500,
    });
    await db.collection('badges').doc('first_post').set({
      id: 'first_post', name: 'First Steps', description: 'first',
      glyph: 'paper-plane-tilt', points: 15, tier: 'onboarding', category: 'content',
      condition: { type: 'postsCreated', threshold: 1 }, order: 1, active: true,
    });
    await db.collection('badges').doc('steady_sharer').set({
      id: 'steady_sharer', name: 'Steady Sharer', description: 'ten',
      glyph: 'stack', points: 30, tier: 'progression', category: 'content',
      condition: { type: 'postsCreated', threshold: 10 }, order: 10, active: true,
    });
  });

  it('grants a badge when threshold is crossed', async () => {
    await db.doc('users/u1').set({ stats: { postsCreated: 1, savesReceived: 0, postsWithAtLeastOneSave: 0, uniqueSaversCount: 0, requestsFulfilled: 0, requestsCreated: 0, commentsWritten: 0, savesGiven: 0, uniqueDepartmentsContributed: [], profileCompleted: false, moderationFlags: 0, updatedAt: null }, gamification: { totalPoints: 0, level: 1, selectedTitle: null, displayedBadges: [] } });
    const r = await evaluateBadges(db, 'u1', ['postsCreated']);
    expect(r.newlyEarnedIds).toEqual(['first_post']);
    expect(r.pointsAdded).toBe(15);
    expect(r.newLevel).toBe(1);
    const earned = await db.collection('users/u1/earnedBadges').get();
    expect(earned.docs.map(d => d.id)).toEqual(['first_post']);
    const user = await db.doc('users/u1').get();
    expect(user.data()?.gamification.totalPoints).toBe(15);
  });

  it('is idempotent — second run grants nothing', async () => {
    await db.doc('users/u1').set({ stats: { postsCreated: 1, savesReceived: 0, postsWithAtLeastOneSave: 0, uniqueSaversCount: 0, requestsFulfilled: 0, requestsCreated: 0, commentsWritten: 0, savesGiven: 0, uniqueDepartmentsContributed: [], profileCompleted: false, moderationFlags: 0, updatedAt: null }, gamification: { totalPoints: 0, level: 1, selectedTitle: null, displayedBadges: [] } });
    await evaluateBadges(db, 'u1', ['postsCreated']);
    const second = await evaluateBadges(db, 'u1', ['postsCreated']);
    expect(second.newlyEarnedIds).toEqual([]);
    expect(second.pointsAdded).toBe(0);
  });

  it('grants multiple badges in one call when several thresholds are crossed at once', async () => {
    await db.doc('users/u1').set({ stats: { postsCreated: 10, savesReceived: 0, postsWithAtLeastOneSave: 0, uniqueSaversCount: 0, requestsFulfilled: 0, requestsCreated: 0, commentsWritten: 0, savesGiven: 0, uniqueDepartmentsContributed: [], profileCompleted: false, moderationFlags: 0, updatedAt: null }, gamification: { totalPoints: 0, level: 1, selectedTitle: null, displayedBadges: [] } });
    const r = await evaluateBadges(db, 'u1', ['postsCreated']);
    expect(new Set(r.newlyEarnedIds)).toEqual(new Set(['first_post', 'steady_sharer']));
    expect(r.pointsAdded).toBe(45);
  });

  it('returns early when no relevant badges exist', async () => {
    await db.doc('users/u1').set({ stats: { postsCreated: 1, savesReceived: 0, postsWithAtLeastOneSave: 0, uniqueSaversCount: 0, requestsFulfilled: 0, requestsCreated: 0, commentsWritten: 0, savesGiven: 0, uniqueDepartmentsContributed: [], profileCompleted: false, moderationFlags: 0, updatedAt: null }, gamification: { totalPoints: 0, level: 1, selectedTitle: null, displayedBadges: [] } });
    const r = await evaluateBadges(db, 'u1', ['commentsWritten']);
    expect(r.newlyEarnedIds).toEqual([]);
  });

  it('recomputes level when points cross a threshold', async () => {
    await db.doc('users/u1').set({ stats: { postsCreated: 10, savesReceived: 0, postsWithAtLeastOneSave: 0, uniqueSaversCount: 0, requestsFulfilled: 0, requestsCreated: 0, commentsWritten: 0, savesGiven: 0, uniqueDepartmentsContributed: [], profileCompleted: false, moderationFlags: 0, updatedAt: null }, gamification: { totalPoints: 0, level: 1, selectedTitle: null, displayedBadges: [] } });
    const r = await evaluateBadges(db, 'u1', ['postsCreated']);
    expect(r.newLevel).toBe(2);
  });
});
```

- [ ] **Step 2: Create the emulator helper**

```ts
// functions/test/helpers/emulator.ts
import * as admin from 'firebase-admin';

let app: admin.app.App | null = null;

export async function initializeTestApp(): Promise<FirebaseFirestore.Firestore> {
  process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || 'localhost:8080';
  if (!app) {
    app = admin.initializeApp({ projectId: 'unishare-test' });
  }
  return admin.firestore();
}

export async function clearFirestore(): Promise<void> {
  const host = process.env.FIRESTORE_EMULATOR_HOST || 'localhost:8080';
  await fetch(`http://${host}/emulator/v1/projects/unishare-test/databases/(default)/documents`, { method: 'DELETE' });
}
```

- [ ] **Step 3: Run to confirm failure**

Run: `cd functions && firebase emulators:exec --only firestore "npx vitest run test/badges/evaluateBadges.test.ts"`
Expected: FAIL — evaluateBadges not implemented.

- [ ] **Step 4: Implement the evaluator**

```ts
// functions/src/badges/evaluateBadges.ts
import { FieldValue } from 'firebase-admin/firestore';
import type { BadgeDoc, LevelConfig, StatKey, UserStats } from './types';
import { EMPTY_STATS, statValue } from './types';
import { levelForPoints } from './levelForPoints';

export interface EvalResult {
  newlyEarnedIds: string[];
  pointsAdded: number;
  newLevel: number;
}

export async function evaluateBadges(
  db: FirebaseFirestore.Firestore,
  uid: string,
  changedStatKeys: StatKey[],
): Promise<EvalResult> {
  if (changedStatKeys.length === 0) {
    const user = await db.doc(`users/${uid}`).get();
    return { newlyEarnedIds: [], pointsAdded: 0, newLevel: user.data()?.gamification?.level ?? 1 };
  }

  const [userSnap, badgesSnap, earnedSnap, levelsSnap] = await Promise.all([
    db.doc(`users/${uid}`).get(),
    db.collection('badges')
      .where('active', '==', true)
      .where('condition.type', 'in', changedStatKeys)
      .get(),
    db.collection(`users/${uid}/earnedBadges`).get(),
    db.doc('app_config/levels').get(),
  ]);

  const stats: UserStats = { ...EMPTY_STATS, ...(userSnap.data()?.stats ?? {}) };
  const currentPoints: number = userSnap.data()?.gamification?.totalPoints ?? 0;
  const earnedIds = new Set(earnedSnap.docs.map(d => d.id));
  const levelConfig = (levelsSnap.data() as LevelConfig) ?? { thresholds: [{ level: 1, cumulative: 0 }], perLevelAbove10: 500 };

  const candidates: BadgeDoc[] = badgesSnap.docs.map(d => d.data() as BadgeDoc);
  const newlyEarned = candidates.filter(b => {
    if (earnedIds.has(b.id)) return false;
    return statValue(stats, b.condition.type) >= b.condition.threshold;
  });

  if (newlyEarned.length === 0) {
    return { newlyEarnedIds: [], pointsAdded: 0, newLevel: levelForPoints(currentPoints, levelConfig) };
  }

  const pointsAdded = newlyEarned.reduce((s, b) => s + b.points, 0);
  const newTotal = currentPoints + pointsAdded;
  const newLevel = levelForPoints(newTotal, levelConfig);

  await db.runTransaction(async tx => {
    for (const b of newlyEarned) {
      tx.set(db.doc(`users/${uid}/earnedBadges/${b.id}`), {
        badgeId: b.id,
        earnedAt: FieldValue.serverTimestamp(),
        pointsAwarded: b.points,
        snapshot: { value: statValue(stats, b.condition.type), threshold: b.condition.threshold },
      });
    }
    tx.update(db.doc(`users/${uid}`), {
      'gamification.totalPoints': newTotal,
      'gamification.level': newLevel,
    });
  });

  return { newlyEarnedIds: newlyEarned.map(b => b.id), pointsAdded, newLevel };
}
```

- [ ] **Step 5: Run to confirm pass**

Run: `cd functions && firebase emulators:exec --only firestore "npx vitest run test/badges/evaluateBadges.test.ts"`
Expected: PASS — 5 tests.

- [ ] **Step 6: Commit**

```bash
git add functions/src/badges/evaluateBadges.ts functions/test/badges/evaluateBadges.test.ts functions/test/helpers/emulator.ts
git commit -m "feat(achievements): add server-side badge evaluator with idempotent grants"
```

### Task 1.4: Notification dispatch helper

**Files:**
- Create: `functions/src/badges/grantNotification.ts`

- [ ] **Step 1: Inspect the existing notification schema**

Run: `grep -rn "notifications" functions/src/triggers/onCommentAdded.ts | head`
Use the same shape so the achievements unlocks fit into the existing notification feed.

- [ ] **Step 2: Implement the helper**

```ts
// functions/src/badges/grantNotification.ts
import { FieldValue } from 'firebase-admin/firestore';
import type { BadgeDoc } from './types';

export async function grantNotification(
  db: FirebaseFirestore.Firestore,
  uid: string,
  badge: BadgeDoc,
): Promise<void> {
  await db.collection('notifications').add({
    userId: uid,
    type: 'badge_unlock',
    title: badge.name,
    body: `${badge.description}  +${badge.points} pts`,
    targetRoute: `/achievements?highlight=${badge.id}`,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
    metadata: { badgeId: badge.id, tier: badge.tier, points: badge.points },
  });
}
```

- [ ] **Step 3: Wire into the evaluator**

In `functions/src/badges/evaluateBadges.ts`, at the end (after `runTransaction`), add:

```ts
import { grantNotification } from './grantNotification';
// ...inside the function, after runTransaction:
await Promise.all(newlyEarned.map(b => grantNotification(db, uid, b)));
```

- [ ] **Step 4: Re-run evaluator tests**

Run: `cd functions && firebase emulators:exec --only firestore "npx vitest run test/badges/evaluateBadges.test.ts"`
Expected: PASS — existing tests still pass; notification side-effect doesn't break them.

- [ ] **Step 5: Commit**

```bash
git add functions/src/badges/grantNotification.ts functions/src/badges/evaluateBadges.ts
git commit -m "feat(achievements): write notification doc for each badge unlock"
```

### Task 1.5: Counter helpers

**Files:**
- Create: `functions/src/badges/counters.ts`

- [ ] **Step 1: Implement helpers**

```ts
// functions/src/badges/counters.ts
import { FieldValue } from 'firebase-admin/firestore';
import type { StatKey } from './types';

export async function incrementStat(
  db: FirebaseFirestore.Firestore,
  uid: string,
  key: Exclude<StatKey, 'profileCompleted' | 'uniqueDepartmentsCount'>,
  delta: number = 1,
): Promise<void> {
  await db.doc(`users/${uid}`).set({
    stats: {
      [key]: FieldValue.increment(delta),
      updatedAt: FieldValue.serverTimestamp(),
    },
  }, { merge: true });
}

export async function addUniqueDepartment(
  db: FirebaseFirestore.Firestore,
  uid: string,
  departmentId: string,
): Promise<boolean> {
  const ref = db.doc(`users/${uid}`);
  return db.runTransaction(async tx => {
    const snap = await tx.get(ref);
    const arr: string[] = snap.data()?.stats?.uniqueDepartmentsContributed ?? [];
    if (arr.includes(departmentId)) return false;
    tx.set(ref, {
      stats: {
        uniqueDepartmentsContributed: FieldValue.arrayUnion(departmentId),
        updatedAt: FieldValue.serverTimestamp(),
      },
    }, { merge: true });
    return true;
  });
}

export async function setProfileCompleted(
  db: FirebaseFirestore.Firestore,
  uid: string,
  completed: boolean,
): Promise<void> {
  await db.doc(`users/${uid}`).set({
    stats: { profileCompleted: completed, updatedAt: FieldValue.serverTimestamp() },
  }, { merge: true });
}
```

- [ ] **Step 2: Commit**

```bash
git add functions/src/badges/counters.ts
git commit -m "feat(achievements): add stat counter helpers"
```

### Task 1.6: onPostCreated trigger

**Files:**
- Create: `functions/src/triggers/onPostCreated.ts`
- Create: `functions/test/triggers/onPostCreated.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
// functions/test/triggers/onPostCreated.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { initializeTestApp, clearFirestore } from '../helpers/emulator';
import { handlePostCreated } from '../../src/triggers/onPostCreated';

describe('handlePostCreated', () => {
  let db: FirebaseFirestore.Firestore;

  beforeEach(async () => {
    db = await initializeTestApp();
    await clearFirestore();
    await db.collection('app_config').doc('levels').set({ thresholds: [{ level: 1, cumulative: 0 }, { level: 2, cumulative: 15 }], perLevelAbove10: 500 });
    await db.collection('badges').doc('first_post').set({
      id: 'first_post', name: 'First Steps', description: 'first',
      glyph: 'paper-plane-tilt', points: 15, tier: 'onboarding', category: 'content',
      condition: { type: 'postsCreated', threshold: 1 }, order: 1, active: true,
    });
  });

  it('increments postsCreated and grants first_post badge', async () => {
    await handlePostCreated(db, 'p1', { authorId: 'u1', departmentId: 'cs' });
    const user = await db.doc('users/u1').get();
    expect(user.data()?.stats.postsCreated).toBe(1);
    expect(user.data()?.stats.uniqueDepartmentsContributed).toEqual(['cs']);
    const earned = await db.collection('users/u1/earnedBadges').get();
    expect(earned.docs.map(d => d.id)).toContain('first_post');
  });

  it('does not double-count departments on repeat posts', async () => {
    await handlePostCreated(db, 'p1', { authorId: 'u1', departmentId: 'cs' });
    await handlePostCreated(db, 'p2', { authorId: 'u1', departmentId: 'cs' });
    const user = await db.doc('users/u1').get();
    expect(user.data()?.stats.postsCreated).toBe(2);
    expect(user.data()?.stats.uniqueDepartmentsContributed).toEqual(['cs']);
  });
});
```

- [ ] **Step 2: Run to confirm failure**

Run: `cd functions && firebase emulators:exec --only firestore "npx vitest run test/triggers/onPostCreated.test.ts"`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement**

```ts
// functions/src/triggers/onPostCreated.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { incrementStat, addUniqueDepartment } from '../badges/counters';
import { evaluateBadges } from '../badges/evaluateBadges';
import type { StatKey } from '../badges/types';

export async function handlePostCreated(
  db: FirebaseFirestore.Firestore,
  postId: string,
  post: { authorId: string; departmentId?: string },
): Promise<void> {
  const changed: StatKey[] = ['postsCreated'];
  await incrementStat(db, post.authorId, 'postsCreated', 1);
  if (post.departmentId) {
    const added = await addUniqueDepartment(db, post.authorId, post.departmentId);
    if (added) changed.push('uniqueDepartmentsCount');
  }
  await evaluateBadges(db, post.authorId, changed);
}

export const onPostCreated = functions.firestore
  .document('posts/{postId}')
  .onCreate(async (snap, ctx) => {
    const post = snap.data();
    if (!post?.authorId) return;
    await handlePostCreated(admin.firestore(), ctx.params.postId, {
      authorId: post.authorId,
      departmentId: post.departmentId,
    });
  });
```

- [ ] **Step 4: Run to confirm pass**

Run: `cd functions && firebase emulators:exec --only firestore "npx vitest run test/triggers/onPostCreated.test.ts"`
Expected: PASS — 2 tests.

- [ ] **Step 5: Commit**

```bash
git add functions/src/triggers/onPostCreated.ts functions/test/triggers/onPostCreated.test.ts
git commit -m "feat(achievements): on-post-created trigger updates counters and evaluates"
```

### Task 1.7: onPostDeleted trigger

**Files:**
- Create: `functions/src/triggers/onPostDeleted.ts`

- [ ] **Step 1: Implement (no eval needed — decrement only)**

```ts
// functions/src/triggers/onPostDeleted.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { incrementStat } from '../badges/counters';

export async function handlePostDeleted(
  db: FirebaseFirestore.Firestore,
  post: { authorId: string },
): Promise<void> {
  await incrementStat(db, post.authorId, 'postsCreated', -1);
}

export const onPostDeleted = functions.firestore
  .document('posts/{postId}')
  .onDelete(async snap => {
    const post = snap.data();
    if (!post?.authorId) return;
    await handlePostDeleted(admin.firestore(), { authorId: post.authorId });
  });
```

- [ ] **Step 2: Commit**

```bash
git add functions/src/triggers/onPostDeleted.ts
git commit -m "feat(achievements): on-post-deleted trigger decrements postsCreated"
```

### Task 1.8: onPostSaved + onPostUnsaved triggers

**Files:**
- Create: `functions/src/triggers/onPostSaved.ts`
- Create: `functions/src/triggers/onPostUnsaved.ts`
- Create: `functions/test/triggers/onPostSaved.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
// functions/test/triggers/onPostSaved.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { initializeTestApp, clearFirestore } from '../helpers/emulator';
import { handlePostSaved } from '../../src/triggers/onPostSaved';

describe('handlePostSaved', () => {
  let db: FirebaseFirestore.Firestore;

  beforeEach(async () => {
    db = await initializeTestApp();
    await clearFirestore();
    await db.collection('app_config').doc('levels').set({ thresholds: [{ level: 1, cumulative: 0 }], perLevelAbove10: 500 });
    await db.collection('badges').doc('first_save_received').set({
      id: 'first_save_received', name: 'Someone Found It Useful', description: 'first',
      glyph: 'sparkle', points: 20, tier: 'onboarding', category: 'content',
      condition: { type: 'savesReceived', threshold: 1 }, order: 6, active: true,
    });
    await db.collection('badges').doc('first_save_given').set({
      id: 'first_save_given', name: 'Curator', description: 'first',
      glyph: 'bookmark-simple', points: 10, tier: 'onboarding', category: 'content',
      condition: { type: 'savesGiven', threshold: 1 }, order: 3, active: true,
    });
    await db.collection('posts').doc('p1').set({ authorId: 'author', departmentId: 'cs' });
  });

  it('increments author savesReceived + saver savesGiven and grants both badges', async () => {
    await handlePostSaved(db, 'p1', 'saver1');
    const author = await db.doc('users/author').get();
    const saver = await db.doc('users/saver1').get();
    expect(author.data()?.stats.savesReceived).toBe(1);
    expect(author.data()?.stats.postsWithAtLeastOneSave).toBe(1);
    expect(author.data()?.stats.uniqueSaversCount).toBe(1);
    expect(saver.data()?.stats.savesGiven).toBe(1);
  });

  it('rejects self-saves', async () => {
    await expect(handlePostSaved(db, 'p1', 'author')).rejects.toThrow(/self-save/);
  });

  it('does not double-count when same saver saves twice', async () => {
    await handlePostSaved(db, 'p1', 'saver1');
    await handlePostSaved(db, 'p1', 'saver1'); // no-op — uniqueSavers presence
    const author = await db.doc('users/author').get();
    expect(author.data()?.stats.uniqueSaversCount).toBe(1);
  });
});
```

- [ ] **Step 2: Implement**

```ts
// functions/src/triggers/onPostSaved.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { incrementStat } from '../badges/counters';
import { evaluateBadges } from '../badges/evaluateBadges';
import type { StatKey } from '../badges/types';

export async function handlePostSaved(
  db: FirebaseFirestore.Firestore,
  postId: string,
  saverUid: string,
): Promise<void> {
  const postSnap = await db.doc(`posts/${postId}`).get();
  const authorUid: string | undefined = postSnap.data()?.authorId;
  if (!authorUid) return;
  if (authorUid === saverUid) {
    throw new Error('self-save not permitted');
  }

  const wasFirstUniqueSaver = await db.runTransaction(async tx => {
    const ref = db.doc(`users/${authorUid}/uniqueSavers/${saverUid}`);
    const existing = await tx.get(ref);
    if (existing.exists) return false;
    tx.set(ref, { savedAt: FieldValue.serverTimestamp() });
    return true;
  });

  const wasFirstSaveOnPost = await db.runTransaction(async tx => {
    const ref = db.doc(`posts/${postId}`);
    const snap = await tx.get(ref);
    const cur: number = snap.data()?.saveCount ?? 0;
    tx.update(ref, { saveCount: FieldValue.increment(1) });
    return cur === 0;
  });

  await incrementStat(db, authorUid, 'savesReceived', 1);
  const changedAuthor: StatKey[] = ['savesReceived'];
  if (wasFirstUniqueSaver) {
    await incrementStat(db, authorUid, 'uniqueSaversCount', 1);
    changedAuthor.push('uniqueSaversCount');
  }
  if (wasFirstSaveOnPost) {
    await incrementStat(db, authorUid, 'postsWithAtLeastOneSave', 1);
    changedAuthor.push('postsWithAtLeastOneSave');
  }
  await evaluateBadges(db, authorUid, changedAuthor);

  await incrementStat(db, saverUid, 'savesGiven', 1);
  await evaluateBadges(db, saverUid, ['savesGiven']);
}

export const onPostSaved = functions.firestore
  .document('posts/{postId}/saves/{saverUid}')
  .onCreate(async (_snap, ctx) => {
    await handlePostSaved(admin.firestore(), ctx.params.postId, ctx.params.saverUid);
  });
```

```ts
// functions/src/triggers/onPostUnsaved.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { incrementStat } from '../badges/counters';

export async function handlePostUnsaved(
  db: FirebaseFirestore.Firestore,
  postId: string,
  saverUid: string,
): Promise<void> {
  const postSnap = await db.doc(`posts/${postId}`).get();
  const authorUid: string | undefined = postSnap.data()?.authorId;
  if (!authorUid || authorUid === saverUid) return;

  await db.doc(`posts/${postId}`).update({ saveCount: FieldValue.increment(-1) });
  await incrementStat(db, authorUid, 'savesReceived', -1);
  await incrementStat(db, saverUid, 'savesGiven', -1);
  // uniqueSavers/{saverUid} document stays; uniqueSaversCount is a monotonic high-water mark by design.
}

export const onPostUnsaved = functions.firestore
  .document('posts/{postId}/saves/{saverUid}')
  .onDelete(async (_snap, ctx) => {
    await handlePostUnsaved(admin.firestore(), ctx.params.postId, ctx.params.saverUid);
  });
```

- [ ] **Step 3: Run tests**

Run: `cd functions && firebase emulators:exec --only firestore "npx vitest run test/triggers/onPostSaved.test.ts"`
Expected: PASS — 3 tests.

- [ ] **Step 4: Commit**

```bash
git add functions/src/triggers/onPostSaved.ts functions/src/triggers/onPostUnsaved.ts functions/test/triggers/onPostSaved.test.ts
git commit -m "feat(achievements): save/unsave triggers maintain author and saver counters"
```

### Task 1.9: Extend onCommentAdded; create onCommentRemoved

**Files:**
- Modify: `functions/src/triggers/onCommentAdded.ts`
- Create: `functions/src/triggers/onCommentRemoved.ts`

- [ ] **Step 1: Add to onCommentAdded**

After the existing notification logic in `onCommentAdded.ts`, add (use existing `db` reference; if module-scope `admin.firestore()` is used elsewhere, mirror that):

```ts
import { incrementStat } from '../badges/counters';
import { evaluateBadges } from '../badges/evaluateBadges';

// inside the onCreate handler, after the existing logic:
const authorId: string | undefined = snap.data()?.authorId;
if (authorId) {
  await incrementStat(admin.firestore(), authorId, 'commentsWritten', 1);
  await evaluateBadges(admin.firestore(), authorId, ['commentsWritten']);
}
```

- [ ] **Step 2: Create onCommentRemoved**

```ts
// functions/src/triggers/onCommentRemoved.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { incrementStat } from '../badges/counters';

export const onCommentRemoved = functions.firestore
  .document('comments/{commentId}')
  .onDelete(async snap => {
    const authorId = snap.data()?.authorId;
    if (!authorId) return;
    await incrementStat(admin.firestore(), authorId, 'commentsWritten', -1);
  });
```

- [ ] **Step 3: Commit**

```bash
git add functions/src/triggers/onCommentAdded.ts functions/src/triggers/onCommentRemoved.ts
git commit -m "feat(achievements): comment triggers update commentsWritten counter"
```

### Task 1.10: onRequestCreated; extend onRequestFulfilled

**Files:**
- Create: `functions/src/triggers/onRequestCreated.ts`
- Modify: `functions/src/triggers/onRequestFulfilled.ts`

- [ ] **Step 1: Create onRequestCreated**

```ts
// functions/src/triggers/onRequestCreated.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { incrementStat } from '../badges/counters';
import { evaluateBadges } from '../badges/evaluateBadges';

export const onRequestCreated = functions.firestore
  .document('requests/{requestId}')
  .onCreate(async snap => {
    const requesterId = snap.data()?.requesterId;
    if (!requesterId) return;
    await incrementStat(admin.firestore(), requesterId, 'requestsCreated', 1);
    await evaluateBadges(admin.firestore(), requesterId, ['requestsCreated']);
  });
```

- [ ] **Step 2: Extend onRequestFulfilled**

After the existing logic, add a block that identifies the fulfilling user (the user whose post fulfilled the request — already part of your fulfilment flow, check existing code for the field name; commonly `fulfilledByUid` or `fulfilledByAuthorId`). Then:

```ts
import { incrementStat } from '../badges/counters';
import { evaluateBadges } from '../badges/evaluateBadges';

// inside the handler, after existing logic, with the fulfillerId resolved:
if (fulfillerId && fulfillerId !== request.requesterId) {
  await incrementStat(admin.firestore(), fulfillerId, 'requestsFulfilled', 1);
  await evaluateBadges(admin.firestore(), fulfillerId, ['requestsFulfilled']);
}
```

- [ ] **Step 3: Commit**

```bash
git add functions/src/triggers/onRequestCreated.ts functions/src/triggers/onRequestFulfilled.ts
git commit -m "feat(achievements): request triggers update requestsCreated and requestsFulfilled"
```

### Task 1.11: onProfileUpdated

**Files:**
- Create: `functions/src/triggers/onProfileUpdated.ts`

- [ ] **Step 1: Implement**

```ts
// functions/src/triggers/onProfileUpdated.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { setProfileCompleted } from '../badges/counters';
import { evaluateBadges } from '../badges/evaluateBadges';

function isProfileComplete(user: Record<string, unknown>): boolean {
  return Boolean(user.name && user.departmentId && user.enrollmentYear && (user.bio ?? '').toString().length > 0);
}

export const onProfileUpdated = functions.firestore
  .document('users/{uid}')
  .onUpdate(async (change, ctx) => {
    const before = change.before.data() ?? {};
    const after = change.after.data() ?? {};
    const beforeComplete = before.stats?.profileCompleted === true;
    const afterComplete = isProfileComplete(after);
    if (beforeComplete === afterComplete) return;
    await setProfileCompleted(admin.firestore(), ctx.params.uid, afterComplete);
    if (afterComplete) {
      await evaluateBadges(admin.firestore(), ctx.params.uid, ['profileCompleted']);
    }
  });
```

- [ ] **Step 2: Commit**

```bash
git add functions/src/triggers/onProfileUpdated.ts
git commit -m "feat(achievements): profile-updated trigger flips profileCompleted stat"
```

### Task 1.12: Daily integrity sweep

**Files:**
- Create: `functions/src/scheduled/integritySweep.ts`

- [ ] **Step 1: Implement**

```ts
// functions/src/scheduled/integritySweep.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as logger from 'firebase-functions/logger';
import { evaluateBadges } from '../badges/evaluateBadges';
import type { StatKey } from '../badges/types';

export const integritySweep = functions.pubsub
  .schedule('0 3 * * *')
  .timeZone('Asia/Bangkok')
  .onRun(async () => {
    const db = admin.firestore();
    const cutoff = Date.now() - 24 * 60 * 60 * 1000;
    const active = await db.collection('users')
      .where('stats.updatedAt', '>=', new Date(cutoff))
      .get();

    for (const userDoc of active.docs) {
      const uid = userDoc.id;
      const stored = userDoc.data().stats ?? {};

      const [posts, comments, requestsFulfilled, requestsCreated, savedByMe, uniqueSavers] = await Promise.all([
        db.collection('posts').where('authorId', '==', uid).count().get(),
        db.collection('comments').where('authorId', '==', uid).count().get(),
        db.collection('requests').where('fulfilledByUid', '==', uid).count().get(),
        db.collection('requests').where('requesterId', '==', uid).count().get(),
        db.collectionGroup('saves').where('saverUid', '==', uid).count().get(),
        db.collection(`users/${uid}/uniqueSavers`).count().get(),
      ]);

      const truth = {
        postsCreated: posts.data().count,
        commentsWritten: comments.data().count,
        requestsFulfilled: requestsFulfilled.data().count,
        requestsCreated: requestsCreated.data().count,
        savesGiven: savedByMe.data().count,
        uniqueSaversCount: uniqueSavers.data().count,
      };

      const drifted: StatKey[] = [];
      const fixes: Record<string, number> = {};
      for (const [k, v] of Object.entries(truth)) {
        if (Math.abs((stored[k] ?? 0) - v) > 0) {
          drifted.push(k as StatKey);
          fixes[`stats.${k}`] = v;
        }
      }

      if (drifted.length > 0) {
        logger.warn('counter drift detected', { uid, drifted, fixes });
        await db.doc(`users/${uid}`).update(fixes);
        await evaluateBadges(db, uid, drifted);
      }
    }
  });
```

- [ ] **Step 2: Commit**

```bash
git add functions/src/scheduled/integritySweep.ts
git commit -m "feat(achievements): daily integrity sweep corrects counter drift"
```

### Task 1.13: Wire functions exports + account-deletion cascade

**Files:**
- Modify: `functions/src/index.ts`
- Modify: any existing user-deletion handler (grep first to locate)

- [ ] **Step 1: Locate the user-deletion path**

Run: `grep -rn "onUserDeleted\|users/{uid}.*onDelete\|deleteUser" functions/src/ | head`
If a handler exists, modify it. If not, add the cascade inside a new trigger.

- [ ] **Step 2: Add cascade-delete for new subcollections**

In whichever file owns user deletion, add:

```ts
async function deleteUserAchievementsSubcollections(db: FirebaseFirestore.Firestore, uid: string) {
  for (const sub of ['earnedBadges', 'uniqueSavers']) {
    const snap = await db.collection(`users/${uid}/${sub}`).get();
    const batch = db.batch();
    snap.docs.forEach(d => batch.delete(d.ref));
    if (snap.size > 0) await batch.commit();
  }
}
```

Call it from the existing deletion path.

- [ ] **Step 3: Wire exports**

In `functions/src/index.ts`, add:

```ts
export { onPostCreated } from './triggers/onPostCreated';
export { onPostDeleted } from './triggers/onPostDeleted';
export { onPostSaved } from './triggers/onPostSaved';
export { onPostUnsaved } from './triggers/onPostUnsaved';
export { onCommentRemoved } from './triggers/onCommentRemoved';
export { onRequestCreated } from './triggers/onRequestCreated';
export { onProfileUpdated } from './triggers/onProfileUpdated';
export { integritySweep } from './scheduled/integritySweep';
```

- [ ] **Step 4: Build to confirm**

Run: `cd functions && npm run build`
Expected: success, no TS errors.

- [ ] **Step 5: Commit**

```bash
git add functions/src/index.ts functions/src/triggers/onUserDeleted.ts
git commit -m "feat(achievements): wire triggers and add subcollection cascade on user delete"
```

---

## Phase 2 — Firestore Rules

### Task 2.1: Update rules

**Files:**
- Modify: `firestore.rules`

- [ ] **Step 1: Add the new clauses**

Append to `firestore.rules` (inside the `match /databases/{database}/documents` block):

```
match /badges/{badgeId} {
  allow read: if request.auth != null;
  allow write: if false;
}

match /app_config/{docId} {
  allow read: if request.auth != null;
  allow write: if false;
}

match /users/{uid}/earnedBadges/{badgeId} {
  allow read: if request.auth != null;
  allow write: if false;
}

match /users/{uid}/uniqueSavers/{saverUid} {
  allow read, write: if false;
}
```

Then locate the existing `match /users/{uid}` rule and ensure the `update` rule rejects writes to `stats.*` and to `gamification.totalPoints` / `gamification.level`. The cleanest way:

```
match /users/{uid} {
  allow read: if request.auth != null;
  allow create: if request.auth.uid == uid;
  allow update: if request.auth.uid == uid
    && !affects(['stats', 'gamification.totalPoints', 'gamification.level'])
    && validDisplayedBadges(uid)
    && validSelectedTitle(uid);

  function affects(paths) {
    return request.resource.data.diff(resource.data).affectedKeys().hasAny(paths);
  }

  function validDisplayedBadges(uid) {
    let proposed = request.resource.data.gamification.displayedBadges;
    return proposed is list
      && proposed.size() <= 3
      && proposed.toSet().size() == proposed.size()
      && proposed.toSet().difference(earnedBadgeIdsList(uid).toSet()).size() == 0;
  }

  function earnedBadgeIdsList(uid) {
    return resource.data.gamification.earnedBadgesCache != null
      ? resource.data.gamification.earnedBadgesCache
      : [];
  }

  function validSelectedTitle(uid) {
    let t = request.resource.data.gamification.selectedTitle;
    return t == null || earnedBadgeIdsList(uid).hasAny([t]);
  }
}
```

The rule relies on a `gamification.earnedBadgesCache` mirror field that the evaluator maintains alongside writes to `earnedBadges` — Firestore Rules cannot list a subcollection in O(1). Update the evaluator transaction (`functions/src/badges/evaluateBadges.ts`) to also push new badge ids onto this list:

```ts
tx.update(db.doc(`users/${uid}`), {
  'gamification.totalPoints': newTotal,
  'gamification.level': newLevel,
  'gamification.earnedBadgesCache': FieldValue.arrayUnion(...newlyEarned.map(b => b.id)),
});
```

- [ ] **Step 2: Deploy and test rules**

Run: `firebase deploy --only firestore:rules`
Expected: rules compile and deploy.

Manual test in emulator: try to write to `users/{uid}.stats.postsCreated` as a user → fails. Try to set `gamification.displayedBadges` to a badge not in `earnedBadgesCache` → fails. Set to one that is → succeeds.

- [ ] **Step 3: Commit**

```bash
git add firestore.rules functions/src/badges/evaluateBadges.ts
git commit -m "feat(achievements): firestore rules guard stats and gamification fields"
```

---

## Phase 3 — Flutter Domain Layer

Pure Dart entities and repository interfaces. **Zero Flutter or Firebase imports.**

### Task 3.1: Badge entity

**Files:**
- Create: `apps/mobile/lib/features/achievements/domain/entities/badge.dart`

- [ ] **Step 1: Implement**

```dart
enum BadgeTier { onboarding, progression, prestige }
enum BadgeCategory { content, community, profile, recognition }

class BadgeCondition {
  final String statKey;
  final int threshold;
  const BadgeCondition({required this.statKey, required this.threshold});
}

class AchievementBadge {
  final String id;
  final String name;
  final String description;
  final String glyph;
  final int points;
  final BadgeTier tier;
  final BadgeCategory category;
  final BadgeCondition condition;
  final int order;
  final bool active;

  const AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.glyph,
    required this.points,
    required this.tier,
    required this.category,
    required this.condition,
    required this.order,
    required this.active,
  });
}
```

The class is named `AchievementBadge` to avoid collision with Flutter's `Badge` widget elsewhere in the codebase.

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/features/achievements/domain/entities/badge.dart
git commit -m "feat(achievements): domain Badge entity"
```

### Task 3.2: EarnedBadge entity

**Files:**
- Create: `apps/mobile/lib/features/achievements/domain/entities/earned_badge.dart`

- [ ] **Step 1: Implement**

```dart
class EarnedBadge {
  final String badgeId;
  final DateTime earnedAt;
  final int pointsAwarded;

  const EarnedBadge({
    required this.badgeId,
    required this.earnedAt,
    required this.pointsAwarded,
  });
}
```

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/features/achievements/domain/entities/earned_badge.dart
git commit -m "feat(achievements): domain EarnedBadge entity"
```

### Task 3.3: UserGamification + UserStats entities

**Files:**
- Create: `apps/mobile/lib/features/achievements/domain/entities/user_gamification.dart`
- Create: `apps/mobile/lib/features/achievements/domain/entities/user_stats.dart`

- [ ] **Step 1: Implement**

```dart
// user_gamification.dart
class UserGamification {
  final int totalPoints;
  final int level;
  final String? selectedTitle;
  final List<String> displayedBadges;

  const UserGamification({
    required this.totalPoints,
    required this.level,
    required this.selectedTitle,
    required this.displayedBadges,
  });

  static const empty = UserGamification(
    totalPoints: 0, level: 1, selectedTitle: null, displayedBadges: [],
  );
}
```

```dart
// user_stats.dart
class UserStats {
  final int postsCreated;
  final int savesReceived;
  final int postsWithAtLeastOneSave;
  final int uniqueSaversCount;
  final int requestsFulfilled;
  final int requestsCreated;
  final int commentsWritten;
  final int savesGiven;
  final List<String> uniqueDepartmentsContributed;
  final bool profileCompleted;

  const UserStats({
    required this.postsCreated,
    required this.savesReceived,
    required this.postsWithAtLeastOneSave,
    required this.uniqueSaversCount,
    required this.requestsFulfilled,
    required this.requestsCreated,
    required this.commentsWritten,
    required this.savesGiven,
    required this.uniqueDepartmentsContributed,
    required this.profileCompleted,
  });

  int valueFor(String statKey) {
    switch (statKey) {
      case 'postsCreated': return postsCreated;
      case 'savesReceived': return savesReceived;
      case 'postsWithAtLeastOneSave': return postsWithAtLeastOneSave;
      case 'uniqueSaversCount': return uniqueSaversCount;
      case 'requestsFulfilled': return requestsFulfilled;
      case 'requestsCreated': return requestsCreated;
      case 'commentsWritten': return commentsWritten;
      case 'savesGiven': return savesGiven;
      case 'uniqueDepartmentsCount': return uniqueDepartmentsContributed.length;
      case 'profileCompleted': return profileCompleted ? 1 : 0;
      default: return 0;
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/features/achievements/domain/entities/user_gamification.dart apps/mobile/lib/features/achievements/domain/entities/user_stats.dart
git commit -m "feat(achievements): domain UserGamification + UserStats entities"
```

### Task 3.4: LevelProgress + ComputeLevelProgress use case (TDD)

**Files:**
- Create: `apps/mobile/lib/features/achievements/domain/entities/level_tier.dart`
- Create: `apps/mobile/lib/features/achievements/domain/usecases/compute_level_progress.dart`
- Create: `apps/mobile/test/unit/features/achievements/level_formula_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/unit/features/achievements/level_formula_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/level_tier.dart';
import 'package:unishare_mobile/features/achievements/domain/usecases/compute_level_progress.dart';

void main() {
  const config = LevelConfig(
    thresholds: [
      LevelThreshold(level: 1, cumulative: 0),
      LevelThreshold(level: 2, cumulative: 30),
      LevelThreshold(level: 3, cumulative: 80),
      LevelThreshold(level: 10, cumulative: 1800),
    ],
    perLevelAbove10: 500,
  );

  final compute = ComputeLevelProgress(config);

  test('0 points → Lv 1, 0 into level, 30 to next', () {
    final r = compute(0);
    expect(r.currentLevel, 1);
    expect(r.pointsIntoLevel, 0);
    expect(r.pointsToNextLevel, 30);
    expect(r.fractionToNext, 0.0);
  });

  test('29 points → Lv 1, 29 into, 1 to next', () {
    final r = compute(29);
    expect(r.currentLevel, 1);
    expect(r.pointsIntoLevel, 29);
    expect(r.pointsToNextLevel, 1);
  });

  test('30 points → Lv 2', () {
    expect(compute(30).currentLevel, 2);
  });

  test('past Lv 10 extrapolates by perLevelAbove10', () {
    expect(compute(1800).currentLevel, 10);
    expect(compute(2300).currentLevel, 11);
    expect(compute(2800).currentLevel, 12);
  });
}
```

- [ ] **Step 2: Run to confirm failure**

Run: `cd apps/mobile && flutter test test/unit/features/achievements/level_formula_test.dart`
Expected: FAIL — files missing.

- [ ] **Step 3: Implement**

```dart
// domain/entities/level_tier.dart
class LevelThreshold {
  final int level;
  final int cumulative;
  const LevelThreshold({required this.level, required this.cumulative});
}

class LevelConfig {
  final List<LevelThreshold> thresholds;
  final int perLevelAbove10;
  const LevelConfig({required this.thresholds, required this.perLevelAbove10});
}

class LevelProgress {
  final int currentLevel;
  final int pointsIntoLevel;
  final int pointsToNextLevel;
  final double fractionToNext;
  const LevelProgress({
    required this.currentLevel,
    required this.pointsIntoLevel,
    required this.pointsToNextLevel,
    required this.fractionToNext,
  });
}
```

```dart
// domain/usecases/compute_level_progress.dart
import 'package:unishare_mobile/features/achievements/domain/entities/level_tier.dart';

class ComputeLevelProgress {
  final LevelConfig config;
  const ComputeLevelProgress(this.config);

  LevelProgress call(int totalPoints) {
    final sorted = [...config.thresholds]..sort((a, b) => a.cumulative.compareTo(b.cumulative));
    var currentLevel = 1;
    var lastCumulative = 0;
    var lastLevel = 1;
    for (final t in sorted) {
      if (totalPoints >= t.cumulative) {
        currentLevel = t.level;
        lastCumulative = t.cumulative;
        lastLevel = t.level;
      } else {
        break;
      }
    }
    if (lastLevel >= 10) {
      final extra = (totalPoints - lastCumulative) ~/ config.perLevelAbove10;
      currentLevel = lastLevel + extra;
    }
    final nextCumulative = sorted
        .firstWhere((t) => t.cumulative > totalPoints, orElse: () => LevelThreshold(level: currentLevel + 1, cumulative: lastCumulative + config.perLevelAbove10))
        .cumulative;
    final intoLevel = totalPoints - lastCumulative;
    final toNext = nextCumulative - totalPoints;
    final span = nextCumulative - lastCumulative;
    return LevelProgress(
      currentLevel: currentLevel,
      pointsIntoLevel: intoLevel,
      pointsToNextLevel: toNext,
      fractionToNext: span == 0 ? 1.0 : intoLevel / span,
    );
  }
}
```

- [ ] **Step 4: Run to confirm pass**

Run: `cd apps/mobile && flutter test test/unit/features/achievements/level_formula_test.dart`
Expected: PASS — 4 tests.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/achievements/domain/entities/level_tier.dart apps/mobile/lib/features/achievements/domain/usecases/compute_level_progress.dart apps/mobile/test/unit/features/achievements/level_formula_test.dart
git commit -m "feat(achievements): pure-Dart level progress computation with tests"
```

### Task 3.5: Repository interfaces

**Files:**
- Create: `apps/mobile/lib/features/achievements/domain/repositories/badge_repository.dart`
- Create: `apps/mobile/lib/features/achievements/domain/repositories/gamification_repository.dart`

- [ ] **Step 1: Implement**

```dart
// badge_repository.dart
import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';

abstract class BadgeRepository {
  Stream<List<AchievementBadge>> watchCatalog();
  Stream<List<EarnedBadge>> watchEarnedBadges(String uid);
}
```

```dart
// gamification_repository.dart
import 'package:unishare_mobile/features/achievements/domain/entities/user_gamification.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/user_stats.dart';

abstract class GamificationRepository {
  Stream<UserGamification> watchGamification(String uid);
  Stream<UserStats> watchStats(String uid);
  Future<void> setDisplayedBadges(String uid, List<String> badgeIds);
  Future<void> setSelectedTitle(String uid, String? badgeId);
}
```

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/features/achievements/domain/repositories/
git commit -m "feat(achievements): domain repository interfaces"
```

### Task 3.6: Use cases (set displayed badges + set title with validation; TDD)

**Files:**
- Create: `apps/mobile/lib/features/achievements/domain/usecases/set_displayed_badges.dart`
- Create: `apps/mobile/lib/features/achievements/domain/usecases/set_selected_title.dart`
- Create: `apps/mobile/test/unit/features/achievements/displayed_badges_validator_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/unit/features/achievements/displayed_badges_validator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/achievements/domain/usecases/set_displayed_badges.dart';

void main() {
  group('validateDisplayedBadgesSelection', () {
    test('accepts a valid selection of earned badges', () {
      validateDisplayedBadgesSelection(
        proposed: ['a', 'b'],
        earnedIds: {'a', 'b', 'c'},
      );
    });

    test('rejects more than 3 badges', () {
      expect(
        () => validateDisplayedBadgesSelection(proposed: ['a', 'b', 'c', 'd'], earnedIds: {'a', 'b', 'c', 'd'}),
        throwsA(isA<DisplayedBadgesException>()),
      );
    });

    test('rejects duplicates', () {
      expect(
        () => validateDisplayedBadgesSelection(proposed: ['a', 'a'], earnedIds: {'a'}),
        throwsA(isA<DisplayedBadgesException>()),
      );
    });

    test('rejects unearned badges', () {
      expect(
        () => validateDisplayedBadgesSelection(proposed: ['a', 'x'], earnedIds: {'a'}),
        throwsA(isA<DisplayedBadgesException>()),
      );
    });
  });
}
```

- [ ] **Step 2: Run to confirm failure**

Run: `cd apps/mobile && flutter test test/unit/features/achievements/displayed_badges_validator_test.dart`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement**

```dart
// set_displayed_badges.dart
import 'package:unishare_mobile/features/achievements/domain/repositories/gamification_repository.dart';

class DisplayedBadgesException implements Exception {
  final String message;
  const DisplayedBadgesException(this.message);
  @override
  String toString() => 'DisplayedBadgesException: $message';
}

void validateDisplayedBadgesSelection({
  required List<String> proposed,
  required Set<String> earnedIds,
}) {
  if (proposed.length > 3) {
    throw const DisplayedBadgesException('At most 3 badges may be displayed.');
  }
  if (proposed.toSet().length != proposed.length) {
    throw const DisplayedBadgesException('Duplicate badges are not allowed.');
  }
  for (final id in proposed) {
    if (!earnedIds.contains(id)) {
      throw DisplayedBadgesException('Badge "$id" is not earned.');
    }
  }
}

class SetDisplayedBadges {
  final GamificationRepository repo;
  const SetDisplayedBadges(this.repo);

  Future<void> call({
    required String uid,
    required List<String> proposed,
    required Set<String> earnedIds,
  }) async {
    validateDisplayedBadgesSelection(proposed: proposed, earnedIds: earnedIds);
    await repo.setDisplayedBadges(uid, proposed);
  }
}
```

```dart
// set_selected_title.dart
import 'package:unishare_mobile/features/achievements/domain/repositories/gamification_repository.dart';
import 'package:unishare_mobile/features/achievements/domain/usecases/set_displayed_badges.dart';

class SetSelectedTitle {
  final GamificationRepository repo;
  const SetSelectedTitle(this.repo);

  Future<void> call({
    required String uid,
    required String? badgeId,
    required Set<String> earnedIds,
  }) async {
    if (badgeId != null && !earnedIds.contains(badgeId)) {
      throw DisplayedBadgesException('Title "$badgeId" is not earned.');
    }
    await repo.setSelectedTitle(uid, badgeId);
  }
}
```

- [ ] **Step 4: Run to confirm pass**

Run: `cd apps/mobile && flutter test test/unit/features/achievements/displayed_badges_validator_test.dart`
Expected: PASS — 4 tests.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/achievements/domain/usecases/set_displayed_badges.dart apps/mobile/lib/features/achievements/domain/usecases/set_selected_title.dart apps/mobile/test/unit/features/achievements/displayed_badges_validator_test.dart
git commit -m "feat(achievements): use cases for displayed badges and selected title"
```

---

## Phase 4 — Flutter Data Layer

Freezed DTOs, Firestore datasources, and repository implementations.

### Task 4.1: Add Phosphor + Freezed deps + DTOs

**Files:**
- Modify: `apps/mobile/pubspec.yaml`
- Create: `apps/mobile/lib/features/achievements/data/models/badge_dto.dart`
- Create: `apps/mobile/lib/features/achievements/data/models/earned_badge_dto.dart`
- Create: `apps/mobile/lib/features/achievements/data/models/user_gamification_dto.dart`
- Create: `apps/mobile/lib/features/achievements/data/models/user_stats_dto.dart`

- [ ] **Step 1: Add Phosphor dependency**

Edit `apps/mobile/pubspec.yaml`, add under `dependencies:`:

```yaml
  phosphor_flutter: ^2.1.0
```

Run: `cd apps/mobile && flutter pub get`
Expected: dependency resolves.

- [ ] **Step 2: Implement BadgeDto**

```dart
// data/models/badge_dto.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';

part 'badge_dto.freezed.dart';
part 'badge_dto.g.dart';

@freezed
class BadgeConditionDto with _$BadgeConditionDto {
  const factory BadgeConditionDto({
    required String type,
    required int threshold,
  }) = _BadgeConditionDto;
  factory BadgeConditionDto.fromJson(Map<String, dynamic> json) => _$BadgeConditionDtoFromJson(json);
}

@freezed
class BadgeDto with _$BadgeDto {
  const BadgeDto._();
  const factory BadgeDto({
    required String id,
    required String name,
    required String description,
    required String glyph,
    required int points,
    required String tier,
    required String category,
    required BadgeConditionDto condition,
    required int order,
    required bool active,
  }) = _BadgeDto;

  factory BadgeDto.fromJson(Map<String, dynamic> json) => _$BadgeDtoFromJson(json);
  factory BadgeDto.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) =>
      BadgeDto.fromJson({...s.data()!, 'id': s.id});

  AchievementBadge toEntity() => AchievementBadge(
        id: id,
        name: name,
        description: description,
        glyph: glyph,
        points: points,
        tier: BadgeTier.values.firstWhere((t) => t.name == tier, orElse: () => BadgeTier.progression),
        category: BadgeCategory.values.firstWhere((c) => c.name == category, orElse: () => BadgeCategory.content),
        condition: BadgeCondition(statKey: condition.type, threshold: condition.threshold),
        order: order,
        active: active,
      );
}
```

- [ ] **Step 3: Implement EarnedBadgeDto**

```dart
// data/models/earned_badge_dto.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';

part 'earned_badge_dto.freezed.dart';
part 'earned_badge_dto.g.dart';

@freezed
class EarnedBadgeDto with _$EarnedBadgeDto {
  const EarnedBadgeDto._();
  const factory EarnedBadgeDto({
    required String badgeId,
    required Timestamp earnedAt,
    required int pointsAwarded,
  }) = _EarnedBadgeDto;

  factory EarnedBadgeDto.fromJson(Map<String, dynamic> json) => _$EarnedBadgeDtoFromJson(json);
  factory EarnedBadgeDto.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) =>
      EarnedBadgeDto.fromJson({...s.data()!, 'badgeId': s.id});

  EarnedBadge toEntity() => EarnedBadge(
        badgeId: badgeId,
        earnedAt: earnedAt.toDate(),
        pointsAwarded: pointsAwarded,
      );
}
```

- [ ] **Step 4: Implement UserGamificationDto + UserStatsDto**

```dart
// data/models/user_gamification_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/user_gamification.dart';

part 'user_gamification_dto.freezed.dart';
part 'user_gamification_dto.g.dart';

@freezed
class UserGamificationDto with _$UserGamificationDto {
  const UserGamificationDto._();
  const factory UserGamificationDto({
    @Default(0) int totalPoints,
    @Default(1) int level,
    String? selectedTitle,
    @Default(<String>[]) List<String> displayedBadges,
  }) = _UserGamificationDto;

  factory UserGamificationDto.fromJson(Map<String, dynamic> json) => _$UserGamificationDtoFromJson(json);

  UserGamification toEntity() => UserGamification(
        totalPoints: totalPoints,
        level: level,
        selectedTitle: selectedTitle,
        displayedBadges: displayedBadges,
      );
}
```

```dart
// data/models/user_stats_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/user_stats.dart';

part 'user_stats_dto.freezed.dart';
part 'user_stats_dto.g.dart';

@freezed
class UserStatsDto with _$UserStatsDto {
  const UserStatsDto._();
  const factory UserStatsDto({
    @Default(0) int postsCreated,
    @Default(0) int savesReceived,
    @Default(0) int postsWithAtLeastOneSave,
    @Default(0) int uniqueSaversCount,
    @Default(0) int requestsFulfilled,
    @Default(0) int requestsCreated,
    @Default(0) int commentsWritten,
    @Default(0) int savesGiven,
    @Default(<String>[]) List<String> uniqueDepartmentsContributed,
    @Default(false) bool profileCompleted,
  }) = _UserStatsDto;

  factory UserStatsDto.fromJson(Map<String, dynamic> json) => _$UserStatsDtoFromJson(json);

  UserStats toEntity() => UserStats(
        postsCreated: postsCreated,
        savesReceived: savesReceived,
        postsWithAtLeastOneSave: postsWithAtLeastOneSave,
        uniqueSaversCount: uniqueSaversCount,
        requestsFulfilled: requestsFulfilled,
        requestsCreated: requestsCreated,
        commentsWritten: commentsWritten,
        savesGiven: savesGiven,
        uniqueDepartmentsContributed: uniqueDepartmentsContributed,
        profileCompleted: profileCompleted,
      );
}
```

- [ ] **Step 5: Run codegen**

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`
Expected: success, four `.freezed.dart` + four `.g.dart` files generated.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/pubspec.yaml apps/mobile/pubspec.lock apps/mobile/lib/features/achievements/data/models/
git commit -m "feat(achievements): freezed DTOs and phosphor_flutter dependency"
```

### Task 4.2: Firestore datasources

**Files:**
- Create: `apps/mobile/lib/features/achievements/data/datasources/badge_firestore_datasource.dart`
- Create: `apps/mobile/lib/features/achievements/data/datasources/earned_badges_firestore_datasource.dart`

- [ ] **Step 1: Implement**

```dart
// badge_firestore_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unishare_mobile/features/achievements/data/models/badge_dto.dart';
import 'package:unishare_mobile/features/achievements/data/models/user_gamification_dto.dart';
import 'package:unishare_mobile/features/achievements/data/models/user_stats_dto.dart';

class BadgeFirestoreDatasource {
  final FirebaseFirestore _db;
  BadgeFirestoreDatasource(this._db);

  Stream<List<BadgeDto>> watchCatalog() => _db
      .collection('badges')
      .where('active', isEqualTo: true)
      .orderBy('order')
      .snapshots()
      .map((s) => s.docs.map((d) => BadgeDto.fromSnapshot(d)).toList());

  Stream<UserGamificationDto> watchGamification(String uid) => _db
      .doc('users/$uid')
      .snapshots()
      .map((s) {
        final map = (s.data()?['gamification'] as Map<String, dynamic>?) ?? const {};
        return UserGamificationDto.fromJson(map);
      });

  Stream<UserStatsDto> watchStats(String uid) => _db
      .doc('users/$uid')
      .snapshots()
      .map((s) {
        final map = (s.data()?['stats'] as Map<String, dynamic>?) ?? const {};
        return UserStatsDto.fromJson(map);
      });

  Future<void> setDisplayedBadges(String uid, List<String> badgeIds) =>
      _db.doc('users/$uid').update({'gamification.displayedBadges': badgeIds});

  Future<void> setSelectedTitle(String uid, String? badgeId) =>
      _db.doc('users/$uid').update({'gamification.selectedTitle': badgeId});
}
```

```dart
// earned_badges_firestore_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unishare_mobile/features/achievements/data/models/earned_badge_dto.dart';

class EarnedBadgesFirestoreDatasource {
  final FirebaseFirestore _db;
  EarnedBadgesFirestoreDatasource(this._db);

  Stream<List<EarnedBadgeDto>> watch(String uid) => _db
      .collection('users/$uid/earnedBadges')
      .orderBy('earnedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => EarnedBadgeDto.fromSnapshot(d)).toList());
}
```

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/features/achievements/data/datasources/
git commit -m "feat(achievements): firestore datasources for badge catalog and earned badges"
```

### Task 4.3: Repository implementations

**Files:**
- Create: `apps/mobile/lib/features/achievements/data/repositories/badge_repository_impl.dart`
- Create: `apps/mobile/lib/features/achievements/data/repositories/gamification_repository_impl.dart`

- [ ] **Step 1: Implement**

```dart
// badge_repository_impl.dart
import 'package:unishare_mobile/features/achievements/data/datasources/badge_firestore_datasource.dart';
import 'package:unishare_mobile/features/achievements/data/datasources/earned_badges_firestore_datasource.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/domain/repositories/badge_repository.dart';

class BadgeRepositoryImpl implements BadgeRepository {
  final BadgeFirestoreDatasource _catalog;
  final EarnedBadgesFirestoreDatasource _earned;
  BadgeRepositoryImpl(this._catalog, this._earned);

  @override
  Stream<List<AchievementBadge>> watchCatalog() =>
      _catalog.watchCatalog().map((dtos) => dtos.map((d) => d.toEntity()).toList());

  @override
  Stream<List<EarnedBadge>> watchEarnedBadges(String uid) =>
      _earned.watch(uid).map((dtos) => dtos.map((d) => d.toEntity()).toList());
}
```

```dart
// gamification_repository_impl.dart
import 'package:unishare_mobile/features/achievements/data/datasources/badge_firestore_datasource.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/user_gamification.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/user_stats.dart';
import 'package:unishare_mobile/features/achievements/domain/repositories/gamification_repository.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  final BadgeFirestoreDatasource _ds;
  GamificationRepositoryImpl(this._ds);

  @override
  Stream<UserGamification> watchGamification(String uid) =>
      _ds.watchGamification(uid).map((d) => d.toEntity());

  @override
  Stream<UserStats> watchStats(String uid) =>
      _ds.watchStats(uid).map((d) => d.toEntity());

  @override
  Future<void> setDisplayedBadges(String uid, List<String> badgeIds) =>
      _ds.setDisplayedBadges(uid, badgeIds);

  @override
  Future<void> setSelectedTitle(String uid, String? badgeId) =>
      _ds.setSelectedTitle(uid, badgeId);
}
```

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/features/achievements/data/repositories/
git commit -m "feat(achievements): repository implementations bridge data + domain"
```

---

## Phase 5 — Flutter Presentation: providers + display widgets

### Task 5.1: Riverpod providers

**Files:**
- Create: `apps/mobile/lib/features/achievements/presentation/providers/badge_catalog_provider.dart`
- Create: `apps/mobile/lib/features/achievements/presentation/providers/earned_badges_provider.dart`
- Create: `apps/mobile/lib/features/achievements/presentation/providers/user_gamification_provider.dart`
- Create: `apps/mobile/lib/features/achievements/presentation/providers/level_progress_provider.dart`

- [ ] **Step 1: Implement**

```dart
// badge_catalog_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/achievements/data/datasources/badge_firestore_datasource.dart';
import 'package:unishare_mobile/features/achievements/data/datasources/earned_badges_firestore_datasource.dart';
import 'package:unishare_mobile/features/achievements/data/repositories/badge_repository_impl.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/repositories/badge_repository.dart';

part 'badge_catalog_provider.g.dart';

@riverpod
BadgeRepository badgeRepository(Ref ref) {
  final db = FirebaseFirestore.instance;
  return BadgeRepositoryImpl(
    BadgeFirestoreDatasource(db),
    EarnedBadgesFirestoreDatasource(db),
  );
}

@riverpod
Stream<List<AchievementBadge>> badgeCatalog(Ref ref) =>
    ref.watch(badgeRepositoryProvider).watchCatalog();
```

```dart
// earned_badges_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';

part 'earned_badges_provider.g.dart';

@riverpod
Stream<List<EarnedBadge>> earnedBadges(Ref ref, String uid) =>
    ref.watch(badgeRepositoryProvider).watchEarnedBadges(uid);
```

```dart
// user_gamification_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/achievements/data/datasources/badge_firestore_datasource.dart';
import 'package:unishare_mobile/features/achievements/data/repositories/gamification_repository_impl.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/user_gamification.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/user_stats.dart';
import 'package:unishare_mobile/features/achievements/domain/repositories/gamification_repository.dart';

part 'user_gamification_provider.g.dart';

@riverpod
GamificationRepository gamificationRepository(Ref ref) =>
    GamificationRepositoryImpl(BadgeFirestoreDatasource(FirebaseFirestore.instance));

@riverpod
Stream<UserGamification> userGamification(Ref ref, String uid) =>
    ref.watch(gamificationRepositoryProvider).watchGamification(uid);

@riverpod
Stream<UserStats> userStats(Ref ref, String uid) =>
    ref.watch(gamificationRepositoryProvider).watchStats(uid);
```

```dart
// level_progress_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/level_tier.dart';
import 'package:unishare_mobile/features/achievements/domain/usecases/compute_level_progress.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/user_gamification_provider.dart';

part 'level_progress_provider.g.dart';

@riverpod
Future<LevelConfig> levelConfig(Ref ref) async {
  final snap = await FirebaseFirestore.instance.doc('app_config/levels').get();
  final data = snap.data() ?? const {};
  final thresholds = ((data['thresholds'] as List?) ?? const [])
      .map((t) => LevelThreshold(level: t['level'] as int, cumulative: t['cumulative'] as int))
      .toList();
  return LevelConfig(thresholds: thresholds, perLevelAbove10: (data['perLevelAbove10'] as int?) ?? 500);
}

@riverpod
LevelProgress? levelProgress(Ref ref, String uid) {
  final gamification = ref.watch(userGamificationProvider(uid)).valueOrNull;
  final config = ref.watch(levelConfigProvider).valueOrNull;
  if (gamification == null || config == null) return null;
  return ComputeLevelProgress(config)(gamification.totalPoints);
}
```

- [ ] **Step 2: Run codegen**

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`
Expected: `.g.dart` files generated.

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/lib/features/achievements/presentation/providers/
git commit -m "feat(achievements): riverpod providers for catalog, earned, gamification, level"
```

### Task 5.2: BadgeFrame widget (TDD via colors only — golden tests are separate)

**Files:**
- Create: `apps/mobile/lib/features/achievements/presentation/widgets/badge_frame.dart`
- Create: `apps/mobile/test/widget/features/achievements/badge_frame_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/widget/features/achievements/badge_frame_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_frame.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart' show appLightTheme;

void main() {
  testWidgets('onboarding earned has amber fill', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: appLightTheme, home: const BadgeFrame(tier: BadgeTier.onboarding, locked: false, child: Icon(Icons.star), size: 48)));
    final containerFinder = find.byKey(const Key('badge_frame_container'));
    expect(containerFinder, findsOneWidget);
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration;
    final element = tester.element(containerFinder);
    final ac = Theme.of(element).extension<AppColors>()!;
    expect(decoration.color, ac.amber);
  });

  testWidgets('locked uses muted fill regardless of tier', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: appLightTheme, home: const BadgeFrame(tier: BadgeTier.prestige, locked: true, child: Icon(Icons.lock), size: 48)));
    final container = tester.widget<Container>(find.byKey(const Key('badge_frame_container')));
    final decoration = container.decoration as BoxDecoration;
    final ac = Theme.of(tester.element(find.byKey(const Key('badge_frame_container')))).extension<AppColors>()!;
    expect(decoration.color, ac.muted);
  });
}
```

The test imports the existing theme entry point; if its file path differs (e.g., `app_theme.dart` vs `theme.dart`), adjust the import. Run `grep -rn "appLightTheme\|appTheme " apps/mobile/lib/shared/theme/ | head` to locate.

- [ ] **Step 2: Run to confirm failure**

Run: `cd apps/mobile && flutter test test/widget/features/achievements/badge_frame_test.dart`
Expected: FAIL — widget not found.

- [ ] **Step 3: Implement**

```dart
// widgets/badge_frame.dart
import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class BadgeFrame extends StatelessWidget {
  const BadgeFrame({
    super.key,
    required this.tier,
    required this.locked,
    required this.child,
    this.size = 48,
  });

  final BadgeTier tier;
  final bool locked;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;

    final Color fill;
    final Border? border;
    Widget? topAccent;

    if (locked) {
      fill = ac.muted;
      border = null;
    } else {
      switch (tier) {
        case BadgeTier.onboarding:
          fill = ac.amber;
          border = null;
          break;
        case BadgeTier.progression:
          fill = ac.amberSubtle;
          border = Border.all(color: ac.amber, width: 1.5);
          break;
        case BadgeTier.prestige:
          fill = ac.surfaceDark;
          border = null;
          topAccent = Positioned(
            top: 0, left: 0, right: 0,
            child: Container(height: 2, color: ac.amber),
          );
          break;
      }
    }

    final radius = size * (8 / 48);
    return Container(
      key: const Key('badge_frame_container'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (topAccent != null) topAccent,
          IconTheme.merge(
            data: IconThemeData(
              color: locked
                  ? ac.textMuted
                  : (tier == BadgeTier.onboarding ? ac.surfaceDark : ac.amber),
              size: size * (24 / 48),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run to confirm pass**

Run: `cd apps/mobile && flutter test test/widget/features/achievements/badge_frame_test.dart`
Expected: PASS — 2 tests.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/achievements/presentation/widgets/badge_frame.dart apps/mobile/test/widget/features/achievements/badge_frame_test.dart
git commit -m "feat(achievements): BadgeFrame widget with tier and locked variants"
```

### Task 5.3: BadgeIcon (frame + Phosphor glyph)

**Files:**
- Create: `apps/mobile/lib/features/achievements/presentation/widgets/badge_icon.dart`

- [ ] **Step 1: Implement glyph resolver**

```dart
// widgets/badge_icon.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_frame.dart';

IconData _resolveGlyph(String name) {
  switch (name) {
    case 'user-circle': return PhosphorIconsThin.userCircle;
    case 'paper-plane-tilt': return PhosphorIconsThin.paperPlaneTilt;
    case 'bookmark-simple': return PhosphorIconsThin.bookmarkSimple;
    case 'chat-circle-dots': return PhosphorIconsThin.chatCircleDots;
    case 'hand-waving': return PhosphorIconsThin.handWaving;
    case 'sparkle': return PhosphorIconsThin.sparkle;
    case 'stack': return PhosphorIconsThin.stack;
    case 'lightbulb': return PhosphorIconsThin.lightbulb;
    case 'notebook': return PhosphorIconsThin.notebook;
    case 'chats': return PhosphorIconsThin.chats;
    case 'hand-heart': return PhosphorIconsThin.handHeart;
    case 'compass': return PhosphorIconsThin.compass;
    case 'books': return PhosphorIconsThin.books;
    case 'ear': return PhosphorIconsThin.ear;
    case 'anchor': return PhosphorIconsThin.anchor;
    case 'crown-simple': return PhosphorIconsThin.crownSimple;
    case 'tree': return PhosphorIconsThin.tree;
    case 'seal-check': return PhosphorIconsThin.sealCheck;
    case 'globe': return PhosphorIconsThin.globe;
    case 'medal': return PhosphorIconsThin.medal;
    default: return PhosphorIconsThin.question;
  }
}

class BadgeIcon extends StatelessWidget {
  const BadgeIcon({
    super.key,
    required this.badge,
    required this.locked,
    this.size = 48,
  });

  final AchievementBadge badge;
  final bool locked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return BadgeFrame(
      tier: badge.tier,
      locked: locked,
      size: size,
      child: Icon(locked ? PhosphorIconsThin.lock : _resolveGlyph(badge.glyph)),
    );
  }
}
```

The exact Phosphor symbol identifiers (`PhosphorIconsThin.foo`) come from the `phosphor_flutter` package. If a name doesn't compile, `grep -rn "class PhosphorIconsThin" .dart_tool/` to find the canonical reference, and update mapping.

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/features/achievements/presentation/widgets/badge_icon.dart
git commit -m "feat(achievements): BadgeIcon composes frame + phosphor glyph"
```

### Task 5.4: LevelChip + TitleChip + LevelProgressBar

**Files:**
- Create: `apps/mobile/lib/features/achievements/presentation/widgets/level_chip.dart`
- Create: `apps/mobile/lib/features/achievements/presentation/widgets/title_chip.dart`
- Create: `apps/mobile/lib/features/achievements/presentation/widgets/level_progress_bar.dart`

- [ ] **Step 1: Implement**

```dart
// level_chip.dart
import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class LevelChip extends StatelessWidget {
  const LevelChip({super.key, required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ac.amberSubtle,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Lv $level',
        style: AppTypography.mono(
          base: theme.textTheme.labelSmall?.copyWith(
            color: ac.amber,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
```

```dart
// title_chip.dart
import 'package:flutter/material.dart';

import 'package:unishare_mobile/shared/theme/app_colors.dart';

class TitleChip extends StatelessWidget {
  const TitleChip({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.bodySmall?.copyWith(color: ac.mutedForeground),
    );
  }
}
```

```dart
// level_progress_bar.dart
import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/level_tier.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class LevelProgressBar extends StatelessWidget {
  const LevelProgressBar({super.key, required this.progress, required this.totalPoints});
  final LevelProgress progress;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.fractionToNext.clamp(0.0, 1.0),
            backgroundColor: ac.muted,
            valueColor: AlwaysStoppedAnimation(ac.amber),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$totalPoints / ${totalPoints + progress.pointsToNextLevel} pts to Lv ${progress.currentLevel + 1}',
          style: AppTypography.mono(
            base: theme.textTheme.labelSmall?.copyWith(
              color: ac.textMuted,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/features/achievements/presentation/widgets/level_chip.dart apps/mobile/lib/features/achievements/presentation/widgets/title_chip.dart apps/mobile/lib/features/achievements/presentation/widgets/level_progress_bar.dart
git commit -m "feat(achievements): LevelChip, TitleChip, LevelProgressBar widgets"
```

### Task 5.5: ProfileAchievementsSection (widget test + impl)

**Files:**
- Create: `apps/mobile/lib/features/achievements/presentation/widgets/profile_achievements_section.dart`
- Create: `apps/mobile/test/widget/features/achievements/profile_achievements_section_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/widget/features/achievements/profile_achievements_section_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/level_tier.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/user_gamification.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/level_progress_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/user_gamification_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/profile_achievements_section.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart' show appLightTheme;

void main() {
  testWidgets('shows muted placeholders when no badges earned', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        earnedBadgesProvider('u1').overrideWith((ref) => Stream.value(<EarnedBadge>[])),
        userGamificationProvider('u1').overrideWith((ref) => Stream.value(UserGamification.empty)),
        badgeCatalogProvider.overrideWith((ref) => Stream.value(<AchievementBadge>[])),
        levelProgressProvider('u1').overrideWith((ref) => const LevelProgress(currentLevel: 1, pointsIntoLevel: 0, pointsToNextLevel: 30, fractionToNext: 0)),
      ],
      child: MaterialApp(theme: appLightTheme, home: const Scaffold(body: ProfileAchievementsSection(uid: 'u1'))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('ACHIEVEMENTS'), findsOneWidget);
    expect(find.text('Earn badges to display them here'), findsOneWidget);
  });

  testWidgets('shows up to 3 displayed badges when set', (tester) async {
    final catalog = [
      AchievementBadge(id: 'first_post', name: 'First Steps', description: '', glyph: 'paper-plane-tilt', points: 15, tier: BadgeTier.onboarding, category: BadgeCategory.content, condition: BadgeCondition(statKey: 'postsCreated', threshold: 1), order: 2, active: true),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        earnedBadgesProvider('u1').overrideWith((ref) => Stream.value([EarnedBadge(badgeId: 'first_post', earnedAt: DateTime.now(), pointsAwarded: 15)])),
        userGamificationProvider('u1').overrideWith((ref) => Stream.value(const UserGamification(totalPoints: 15, level: 1, selectedTitle: null, displayedBadges: ['first_post']))),
        badgeCatalogProvider.overrideWith((ref) => Stream.value(catalog)),
        levelProgressProvider('u1').overrideWith((ref) => const LevelProgress(currentLevel: 1, pointsIntoLevel: 15, pointsToNextLevel: 15, fractionToNext: 0.5)),
      ],
      child: MaterialApp(theme: appLightTheme, home: const Scaffold(body: ProfileAchievementsSection(uid: 'u1'))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('First Steps'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Implement**

```dart
// widgets/profile_achievements_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/level_progress_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/user_gamification_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_frame.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_icon.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/level_progress_bar.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class ProfileAchievementsSection extends ConsumerWidget {
  const ProfileAchievementsSection({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final gamification = ref.watch(userGamificationProvider(uid)).valueOrNull;
    final earned = ref.watch(earnedBadgesProvider(uid)).valueOrNull ?? const [];
    final catalog = ref.watch(badgeCatalogProvider).valueOrNull ?? const [];
    final progress = ref.watch(levelProgressProvider(uid));

    final displayedIds = gamification?.displayedBadges ?? const <String>[];
    final catalogById = {for (final b in catalog) b.id: b};
    final displayed = displayedIds
        .map((id) => catalogById[id])
        .whereType<AchievementBadge>()
        .toList();

    return InkWell(
      onTap: () => context.push('/achievements/$uid'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACHIEVEMENTS',
                  style: AppTypography.mono(
                    base: theme.textTheme.labelSmall?.copyWith(
                      color: ac.textMuted, letterSpacing: 0.5,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text('View all', style: theme.textTheme.labelSmall?.copyWith(color: ac.textMuted)),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 14, color: ac.textMuted),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (displayed.isEmpty)
              _EmptyState(ac: ac)
            else
              Wrap(
                spacing: 12,
                children: displayed
                    .map((b) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BadgeIcon(badge: b, locked: false, size: 48),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 64,
                              child: Text(
                                b.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(color: ac.textSecondary),
                              ),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            const SizedBox(height: 16),
            if (progress != null && gamification != null)
              LevelProgressBar(progress: progress, totalPoints: gamification.totalPoints),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.ac});
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i == 2 ? 0 : 12),
              child: BadgeFrame(
                tier: BadgeTier.progression,
                locked: true,
                size: 48,
                child: const Icon(Icons.lock_outline),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Earn badges to display them here',
          style: theme.textTheme.labelSmall?.copyWith(color: ac.textMuted),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Run tests**

Run: `cd apps/mobile && flutter test test/widget/features/achievements/profile_achievements_section_test.dart`
Expected: PASS — 2 tests.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/features/achievements/presentation/widgets/profile_achievements_section.dart apps/mobile/test/widget/features/achievements/profile_achievements_section_test.dart
git commit -m "feat(achievements): ProfileAchievementsSection with empty + populated states"
```

### Task 5.6: Integrate into ProfileCard

**Files:**
- Modify: `apps/mobile/lib/features/profile/presentation/widgets/profile_card.dart`

- [ ] **Step 1: Add the level chip to the name row + title under name**

In `profile_card.dart`, locate the `Text(user.name, ...)` widget (around line 60). Wrap it in a `Row`:

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Expanded(
      child: Text(
        user.name,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    ),
    Consumer(builder: (context, ref, _) {
      final g = ref.watch(userGamificationProvider(user.id)).valueOrNull;
      return LevelChip(level: g?.level ?? 1);
    }),
  ],
),
```

Imports needed at the top:

```dart
import 'package:unishare_mobile/features/achievements/presentation/providers/user_gamification_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/level_chip.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/title_chip.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/profile_achievements_section.dart';
```

After the email `Text` widget, add a conditional title chip:

```dart
Consumer(builder: (context, ref, _) {
  final g = ref.watch(userGamificationProvider(user.id)).valueOrNull;
  if (g?.selectedTitle == null) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 2),
    child: TitleChip(title: g!.selectedTitle!),
  );
}),
```

At the end of the existing `Column` (after the stats row), add another divider + the achievements section:

```dart
const SizedBox(height: 16),
Divider(color: theme.dividerColor),
const SizedBox(height: 8),
ProfileAchievementsSection(uid: user.id),
```

- [ ] **Step 2: Run profile card tests**

Run: `cd apps/mobile && flutter test test/widget/features/profile/`
Expected: existing tests still pass.

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/lib/features/profile/presentation/widgets/profile_card.dart
git commit -m "feat(achievements): integrate level chip, title, and achievements section into profile card"
```

### Task 5.7: AchievementsScreen + BadgeDetailSheet

**Files:**
- Create: `apps/mobile/lib/features/achievements/presentation/screens/achievements_screen.dart`
- Create: `apps/mobile/lib/features/achievements/presentation/widgets/badge_detail_sheet.dart`
- Create: `apps/mobile/test/widget/features/achievements/achievements_screen_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/widget/features/achievements/achievements_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart' show appLightTheme;

void main() {
  testWidgets('renders earned and locked sections', (tester) async {
    final catalog = [
      AchievementBadge(id: 'first_post', name: 'First Steps', description: 'first post', glyph: 'paper-plane-tilt', points: 15, tier: BadgeTier.onboarding, category: BadgeCategory.content, condition: BadgeCondition(statKey: 'postsCreated', threshold: 1), order: 2, active: true),
      AchievementBadge(id: 'beloved', name: 'Beloved', description: '100 saves', glyph: 'crown-simple', points: 100, tier: BadgeTier.prestige, category: BadgeCategory.content, condition: BadgeCondition(statKey: 'savesReceived', threshold: 100), order: 20, active: true),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        badgeCatalogProvider.overrideWith((ref) => Stream.value(catalog)),
        earnedBadgesProvider('u1').overrideWith((ref) => Stream.value([EarnedBadge(badgeId: 'first_post', earnedAt: DateTime.now(), pointsAwarded: 15)])),
      ],
      child: MaterialApp(theme: appLightTheme, home: const AchievementsScreen(uid: 'u1')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('First Steps'), findsOneWidget);
    expect(find.text('Beloved'), findsOneWidget);
    expect(find.text('Earned · 1'), findsOneWidget);
    expect(find.textContaining('Locked'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Implement BadgeDetailSheet**

```dart
// widgets/badge_detail_sheet.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_icon.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class BadgeDetailSheet extends StatelessWidget {
  const BadgeDetailSheet({super.key, required this.badge, this.earned});
  final AchievementBadge badge;
  final EarnedBadge? earned;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BadgeIcon(badge: badge, locked: earned == null, size: 96),
          const SizedBox(height: 16),
          Text(badge.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: ac.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            earned == null
                ? '+${badge.points} pts when unlocked'
                : 'Earned ${DateFormat.yMMMd().format(earned!.earnedAt)} · +${earned!.pointsAwarded} pts',
            style: theme.textTheme.labelSmall?.copyWith(color: ac.textMuted),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Implement AchievementsScreen**

```dart
// screens/achievements_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_detail_sheet.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_icon.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';
import 'package:unishare_mobile/shared/theme/app_typography.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final catalog = ref.watch(badgeCatalogProvider).valueOrNull ?? const [];
    final earned = ref.watch(earnedBadgesProvider(uid)).valueOrNull ?? const [];
    final earnedMap = {for (final e in earned) e.badgeId: e};

    final unlocked = catalog.where((b) => earnedMap.containsKey(b.id)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final locked = catalog.where((b) => !earnedMap.containsKey(b.id)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Earned · ${unlocked.length}',
                style: AppTypography.mono(base: theme.textTheme.labelSmall?.copyWith(color: ac.textMuted)),
              ),
            ),
          ),
          _BadgeGrid(badges: unlocked, earnedMap: earnedMap),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Locked · ${locked.length}',
                style: AppTypography.mono(base: theme.textTheme.labelSmall?.copyWith(color: ac.textMuted)),
              ),
            ),
          ),
          _BadgeGrid(badges: locked, earnedMap: earnedMap),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges, required this.earnedMap});
  final List<AchievementBadge> badges;
  final Map<String, EarnedBadge> earnedMap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 96,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final b = badges[i];
            final earned = earnedMap[b.id];
            return InkWell(
              onTap: () => showModalBottomSheet(
                context: context,
                builder: (_) => BadgeDetailSheet(badge: b, earned: earned),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BadgeIcon(badge: b, locked: earned == null, size: 72),
                  const SizedBox(height: 6),
                  Text(
                    b.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            );
          },
          childCount: badges.length,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test**

Run: `cd apps/mobile && flutter test test/widget/features/achievements/achievements_screen_test.dart`
Expected: PASS — 1 test.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/achievements/presentation/screens/achievements_screen.dart apps/mobile/lib/features/achievements/presentation/widgets/badge_detail_sheet.dart apps/mobile/test/widget/features/achievements/achievements_screen_test.dart
git commit -m "feat(achievements): AchievementsScreen with earned + locked grids and BadgeDetailSheet"
```

### Task 5.8: BadgePickerSheet + TitlePickerSheet

**Files:**
- Create: `apps/mobile/lib/features/achievements/presentation/widgets/badge_picker_sheet.dart`
- Create: `apps/mobile/lib/features/achievements/presentation/widgets/title_picker_sheet.dart`

- [ ] **Step 1: Implement BadgePickerSheet**

```dart
// widgets/badge_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/repositories/gamification_repository.dart';
import 'package:unishare_mobile/features/achievements/domain/usecases/set_displayed_badges.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/user_gamification_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_icon.dart';

class BadgePickerSheet extends ConsumerStatefulWidget {
  const BadgePickerSheet({super.key, required this.uid});
  final String uid;

  @override
  ConsumerState<BadgePickerSheet> createState() => _BadgePickerSheetState();
}

class _BadgePickerSheetState extends ConsumerState<BadgePickerSheet> {
  List<String> _selected = const [];

  @override
  void initState() {
    super.initState();
    final g = ref.read(userGamificationProvider(widget.uid)).valueOrNull;
    _selected = List.of(g?.displayedBadges ?? const []);
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (_selected.length < 3) {
        _selected.add(id);
      }
    });
  }

  Future<void> _save() async {
    final earned = ref.read(earnedBadgesProvider(widget.uid)).valueOrNull ?? const [];
    final earnedIds = earned.map((e) => e.badgeId).toSet();
    final usecase = SetDisplayedBadges(ref.read(gamificationRepositoryProvider));
    await usecase(uid: widget.uid, proposed: _selected, earnedIds: earnedIds);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(badgeCatalogProvider).valueOrNull ?? const [];
    final earned = ref.watch(earnedBadgesProvider(widget.uid)).valueOrNull ?? const [];
    final earnedIds = earned.map((e) => e.badgeId).toSet();
    final available = catalog.where((b) => earnedIds.contains(b.id)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Pick up to 3 badges to display', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: available.map((b) {
              final isSelected = _selected.contains(b.id);
              return InkWell(
                onTap: () => _toggle(b.id),
                child: Opacity(
                  opacity: isSelected ? 1.0 : 0.5,
                  child: BadgeIcon(badge: b, locked: false, size: 56),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Implement TitlePickerSheet**

```dart
// widgets/title_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/achievements/domain/usecases/set_selected_title.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/user_gamification_provider.dart';

class TitlePickerSheet extends ConsumerWidget {
  const TitlePickerSheet({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(badgeCatalogProvider).valueOrNull ?? const [];
    final earned = ref.watch(earnedBadgesProvider(uid)).valueOrNull ?? const [];
    final earnedIds = earned.map((e) => e.badgeId).toSet();
    final available = catalog.where((b) => earnedIds.contains(b.id)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    Future<void> select(String? id) async {
      final repo = ref.read(gamificationRepositoryProvider);
      await SetSelectedTitle(repo)(uid: uid, badgeId: id, earnedIds: earnedIds);
      if (context.mounted) Navigator.of(context).pop();
    }

    return ListView(
      shrinkWrap: true,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Pick a title to display under your name', textAlign: TextAlign.center),
        ),
        ListTile(
          title: const Text('No title'),
          onTap: () => select(null),
        ),
        ...available.map((b) => ListTile(
              title: Text(b.name),
              onTap: () => select(b.id),
            )),
      ],
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/lib/features/achievements/presentation/widgets/badge_picker_sheet.dart apps/mobile/lib/features/achievements/presentation/widgets/title_picker_sheet.dart
git commit -m "feat(achievements): badge picker and title picker sheets"
```

### Task 5.9: EarnMomentModal + EarnMomentToast

**Files:**
- Create: `apps/mobile/lib/features/achievements/presentation/widgets/earn_moment_modal.dart`
- Create: `apps/mobile/lib/features/achievements/presentation/widgets/earn_moment_toast.dart`

- [ ] **Step 1: Implement modal**

```dart
// widgets/earn_moment_modal.dart
import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_icon.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

class EarnMomentModal extends StatelessWidget {
  const EarnMomentModal({super.key, required this.badge, required this.points, this.levelUp});
  final AchievementBadge badge;
  final int points;
  final int? levelUp;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: BadgeIcon(badge: badge, locked: false, size: 96)),
          const SizedBox(height: 16),
          Text(
            'Achievement unlocked',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(color: ac.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: ac.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            '+$points pts${levelUp != null ? ' · Level up to Lv $levelUp' : ''}',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(color: ac.amber, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nice'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Implement toast**

```dart
// widgets/earn_moment_toast.dart
import 'package:flutter/material.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_icon.dart';
import 'package:unishare_mobile/shared/theme/app_colors.dart';

SnackBar buildEarnMomentToast(BuildContext context, AchievementBadge badge, int points) {
  final ac = Theme.of(context).extension<AppColors>()!;
  final theme = Theme.of(context);
  return SnackBar(
    duration: const Duration(seconds: 3),
    backgroundColor: ac.surfaceDark,
    content: Row(
      children: [
        BadgeIcon(badge: badge, locked: false, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(badge.name, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.surface)),
              Text('+$points pts', style: theme.textTheme.labelSmall?.copyWith(color: ac.amber)),
            ],
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/lib/features/achievements/presentation/widgets/earn_moment_modal.dart apps/mobile/lib/features/achievements/presentation/widgets/earn_moment_toast.dart
git commit -m "feat(achievements): earn moment modal and toast variants"
```

---

## Phase 6 — Earn-Moment Dispatcher + Routing

### Task 6.1: NewBadgeAlertNotifier (Hive-backed lastSeenAt)

**Files:**
- Create: `apps/mobile/lib/features/achievements/presentation/providers/new_badge_alert_provider.dart`

- [ ] **Step 1: Implement**

```dart
// presentation/providers/new_badge_alert_provider.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/earned_badges_provider.dart';

part 'new_badge_alert_provider.g.dart';

const _kBoxName = 'achievements_alerts';
const _kLastSeenKey = 'lastSeenAt';

@riverpod
class NewBadgeAlertNotifier extends _$NewBadgeAlertNotifier {
  @override
  List<EarnedBadge> build(String uid) {
    final earned = ref.watch(earnedBadgesProvider(uid)).valueOrNull ?? const [];
    final lastSeen = _readLastSeen();
    return earned.where((e) => e.earnedAt.isAfter(lastSeen)).toList()
      ..sort((a, b) => a.earnedAt.compareTo(b.earnedAt));
  }

  DateTime _readLastSeen() {
    final box = Hive.box(_kBoxName);
    final ts = box.get(_kLastSeenKey) as int?;
    return ts == null ? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(ts);
  }

  Future<void> markSeen(EarnedBadge earned) async {
    final box = Hive.box(_kBoxName);
    final cur = _readLastSeen();
    final next = earned.earnedAt.isAfter(cur) ? earned.earnedAt : cur;
    await box.put(_kLastSeenKey, next.millisecondsSinceEpoch);
    ref.invalidateSelf();
  }
}

Future<void> openAlertsBox() async {
  if (!Hive.isBoxOpen(_kBoxName)) {
    await Hive.openBox(_kBoxName);
  }
}
```

- [ ] **Step 2: Open the box at app startup**

In `apps/mobile/lib/main.dart`, find the Hive initialization (likely `Hive.initFlutter()` + box openings). Add:

```dart
import 'package:unishare_mobile/features/achievements/presentation/providers/new_badge_alert_provider.dart';

// alongside other Hive.openBox() calls:
await openAlertsBox();
```

- [ ] **Step 3: Run codegen**

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`
Expected: success.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/features/achievements/presentation/providers/new_badge_alert_provider.dart apps/mobile/lib/main.dart
git commit -m "feat(achievements): queue new badge alerts with hive-persisted lastSeenAt"
```

### Task 6.2: Route + dispatcher observer

**Files:**
- Modify: app router file (locate via `grep -rn "GoRouter\|GoRoute" apps/mobile/lib | head`)
- Create: `apps/mobile/lib/features/achievements/presentation/earn_moment_dispatcher.dart`

- [ ] **Step 1: Implement dispatcher**

```dart
// presentation/earn_moment_dispatcher.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/earned_badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/badge_catalog_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/providers/new_badge_alert_provider.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/earn_moment_modal.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/earn_moment_toast.dart';
import 'package:unishare_mobile/features/auth/presentation/providers/current_user_provider.dart';

const _restRoutes = {
  '/feed', '/profile', '/achievements', '/notifications',
};

bool isRestRoute(String location) {
  if (location.startsWith('/profile/')) return true;
  if (location.startsWith('/achievements/')) return true;
  return _restRoutes.contains(location);
}

class EarnMomentDispatcher extends ConsumerStatefulWidget {
  const EarnMomentDispatcher({super.key, required this.child, required this.currentLocation});
  final Widget child;
  final String currentLocation;

  @override
  ConsumerState<EarnMomentDispatcher> createState() => _EarnMomentDispatcherState();
}

class _EarnMomentDispatcherState extends ConsumerState<EarnMomentDispatcher> {
  bool _isDraining = false;
  int _lastShownLevel = -1;

  @override
  void didUpdateWidget(covariant EarnMomentDispatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tryDrain();
  }

  void _tryDrain() {
    if (_isDraining || !isRestRoute(widget.currentLocation)) return;
    final uid = ref.read(currentUserProvider).valueOrNull?.id;
    if (uid == null) return;
    final queue = ref.read(newBadgeAlertNotifierProvider(uid));
    if (queue.isEmpty) return;
    _isDraining = true;
    Future(() async {
      for (final earned in List.of(queue)) {
        await _showOne(earned, uid);
        await ref.read(newBadgeAlertNotifierProvider(uid).notifier).markSeen(earned);
      }
      _isDraining = false;
    });
  }

  Future<void> _showOne(EarnedBadge earned, String uid) async {
    final catalog = ref.read(badgeCatalogProvider).valueOrNull ?? const [];
    final badge = catalog.firstWhere(
      (b) => b.id == earned.badgeId,
      orElse: () => AchievementBadge(id: earned.badgeId, name: earned.badgeId, description: '', glyph: 'sparkle', points: earned.pointsAwarded, tier: BadgeTier.progression, category: BadgeCategory.content, condition: BadgeCondition(statKey: 'postsCreated', threshold: 0), order: 0, active: true),
    );

    final isModalTier = badge.tier == BadgeTier.onboarding || badge.tier == BadgeTier.prestige;
    if (!mounted) return;
    if (isModalTier) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => EarnMomentModal(badge: badge, points: earned.pointsAwarded),
      );
    } else {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(buildEarnMomentToast(context, badge, earned.pointsAwarded));
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

- [ ] **Step 2: Register routes and mount dispatcher in the router shell**

In the app router (e.g., `apps/mobile/lib/app.dart` or wherever `GoRouter` is configured):

Register:

```dart
GoRoute(
  path: '/achievements',
  builder: (context, state) {
    final uid = ref.read(currentUserProvider).value!.id;
    return AchievementsScreen(uid: uid);
  },
),
GoRoute(
  path: '/achievements/:uid',
  builder: (context, state) => AchievementsScreen(uid: state.pathParameters['uid']!),
),
```

Wrap the existing shell route's `builder` with `EarnMomentDispatcher`, passing `state.matchedLocation` as `currentLocation`.

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/lib/features/achievements/presentation/earn_moment_dispatcher.dart apps/mobile/lib/app.dart
git commit -m "feat(achievements): dispatcher mounts on rest routes; /achievements routes registered"
```

---

## Phase 7 — Integration Tests + Goldens

### Task 7.1: Golden tests per tier × size

**Files:**
- Create: `apps/mobile/test/goldens/badges/onboarding_48.png` (generated)
- Create: `apps/mobile/test/widget/features/achievements/badge_frame_golden_test.dart`

- [ ] **Step 1: Write golden test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/achievements/domain/entities/badge.dart';
import 'package:unishare_mobile/features/achievements/presentation/widgets/badge_frame.dart';
import 'package:unishare_mobile/shared/theme/app_theme.dart' show appLightTheme;

void main() {
  final cases = <(BadgeTier, bool, double, String)>[
    (BadgeTier.onboarding, false, 48, 'onboarding_48'),
    (BadgeTier.onboarding, false, 72, 'onboarding_72'),
    (BadgeTier.progression, false, 48, 'progression_48'),
    (BadgeTier.progression, false, 72, 'progression_72'),
    (BadgeTier.prestige, false, 48, 'prestige_48'),
    (BadgeTier.prestige, false, 72, 'prestige_72'),
    (BadgeTier.progression, true, 48, 'locked_48'),
  ];

  for (final (tier, locked, size, name) in cases) {
    testWidgets('golden $name', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: appLightTheme,
        home: Scaffold(body: Center(child: BadgeFrame(tier: tier, locked: locked, size: size, child: const Icon(Icons.star)))),
      ));
      await expectLater(find.byType(BadgeFrame), matchesGoldenFile('../../goldens/badges/$name.png'));
    });
  }
}
```

- [ ] **Step 2: Generate the goldens**

Run: `cd apps/mobile && flutter test --update-goldens test/widget/features/achievements/badge_frame_golden_test.dart`
Expected: PNGs created under `test/goldens/badges/`.

- [ ] **Step 3: Verify they match on a re-run**

Run: `cd apps/mobile && flutter test test/widget/features/achievements/badge_frame_golden_test.dart`
Expected: PASS — 7 golden cases.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/test/goldens/badges/ apps/mobile/test/widget/features/achievements/badge_frame_golden_test.dart
git commit -m "test(achievements): goldens for badge frame variants"
```

### Task 7.2: Integration test — first-post earn flow

**Files:**
- Create: `apps/mobile/integration_test/achievements/first_post_earn_flow_test.dart`

- [ ] **Step 1: Implement integration test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unishare_mobile/main.dart' as app;
import 'package:unishare_mobile/features/achievements/presentation/widgets/earn_moment_modal.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first post triggers first_post badge modal', (tester) async {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

    await FirebaseFirestore.instance.collection('badges').doc('first_post').set({
      'id': 'first_post', 'name': 'First Steps', 'description': 'first',
      'glyph': 'paper-plane-tilt', 'points': 15, 'tier': 'onboarding',
      'category': 'content', 'condition': {'type': 'postsCreated', 'threshold': 1},
      'order': 2, 'active': true,
    });
    await FirebaseFirestore.instance.doc('app_config/levels').set({
      'thresholds': [{'level': 1, 'cumulative': 0}, {'level': 2, 'cumulative': 30}],
      'perLevelAbove10': 500,
    });

    final cred = await FirebaseAuth.instance.signInAnonymously();
    final uid = cred.user!.uid;
    await FirebaseFirestore.instance.doc('users/$uid').set({
      'name': 'Test', 'email': 'test@kmutt.ac.th',
    });

    app.main();
    await tester.pumpAndSettle();

    // Simulate the post creation via Firestore (the trigger fires server-side)
    await FirebaseFirestore.instance.collection('posts').add({
      'authorId': uid, 'title': 'Test', 'departmentId': 'cs', 'createdAt': FieldValue.serverTimestamp(),
    });

    // Wait for the trigger to fire and the stream to deliver
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byType(EarnMomentModal), findsOneWidget);
    expect(find.text('First Steps'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run integration test**

Run the Firebase emulator suite first: `firebase emulators:start --only firestore,auth,functions`

Then in another shell: `cd apps/mobile && flutter test integration_test/achievements/first_post_earn_flow_test.dart`
Expected: PASS — modal shows after the trigger fires.

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/integration_test/achievements/first_post_earn_flow_test.dart
git commit -m "test(achievements): integration test for first-post earn moment"
```

### Task 7.3: Final acceptance pass

- [ ] **Step 1: Run all tests**

Run: `cd apps/mobile && flutter analyze && flutter test`
Expected: no analyze warnings; all unit + widget + golden tests pass.

Run: `cd functions && npm run build && firebase emulators:exec --only firestore "npx vitest run"`
Expected: all server-side tests pass.

- [ ] **Step 2: Open PR**

Run: `gh pr create --title "feat(achievements): v1 system" --body "Implements PROP-0010 / SPEC-0010. Achievement-only XP, 20 badges, profile section, /achievements screen, earn moments, notification entries. See SPEC-0010 for details."`

- [ ] **Step 3: Note follow-up**

Open a tracking issue for v1.1: leaderboards, ajarn recognition, cosmetic profile accents.

---

## Self-Review (post-write)

**Spec coverage:**
- ✅ Data model (badges, users.stats, users.gamification, earnedBadges, uniqueSavers, app_config/levels) — Phases 0, 3, 4.
- ✅ Cloud Function triggers (post created/deleted/saved/unsaved, comment added/removed, request created/fulfilled, profile updated) — Phase 1.
- ✅ Evaluator + level lookup — Phase 1.
- ✅ Notifications integration — Task 1.4.
- ✅ Integrity sweep — Task 1.12.
- ✅ Firestore rules — Phase 2 (introduces `gamification.earnedBadgesCache` mirror to enable rule validation in O(1); evaluator updated accordingly).
- ✅ Cascade delete — Task 1.13.
- ✅ Domain layer (entities + repository interfaces + use cases + level formula) — Phase 3.
- ✅ Data layer (DTOs + datasources + repositories) — Phase 4.
- ✅ Providers (catalog, earnedBadges, gamification, stats, levelProgress, newBadgeAlertNotifier) — Phases 5, 6.
- ✅ Profile-card integration (level chip, title, achievements section) — Task 5.6.
- ✅ AchievementsScreen + BadgeDetailSheet + pickers — Tasks 5.7, 5.8.
- ✅ EarnMoment modal + toast — Task 5.9.
- ✅ Dispatcher + route registration — Task 6.2.
- ✅ Test plan (unit, widget, golden, server-side, integration) — interleaved across phases.
- ✅ Out-of-scope items kept out — leaderboards, ajarn recognition, cosmetic accents deferred to v1.1.

**Placeholder scan:** No "TBD" / "fill in" / "similar to X" / "etc." entries. Every code block is complete. Two paths are intentionally grep-located rather than hard-coded (the existing `onUserDeleted` handler, the app router file) because the engineer will resolve them as the first step of those tasks.

**Type consistency:** `AchievementBadge` is used consistently (not `Badge`, to avoid Flutter's `Badge` widget collision). `BadgeCondition.statKey` is the Dart field name; Firestore stores `condition.type` — DTO maps between them. `uniqueDepartmentsContributed` (array) and `uniqueDepartmentsCount` (derived) are both referenced where appropriate. Evaluator updates `gamification.earnedBadgesCache` alongside the subcollection write — required by Firestore rules in Phase 2 and reflected by the modification to `evaluateBadges.ts` in Task 2.1.

**Scope check:** Plan covers v1 only. v1.1 items (leaderboards, ajarn recognition, cosmetic profile accents) are explicitly out of scope and noted in Task 7.3 follow-up.
