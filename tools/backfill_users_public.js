#!/usr/bin/env node
/**
 * Backfills `users_public/{uid}` from existing `users/{uid}` documents.
 *
 * Idempotent: writes via `set({ merge: true })` so re-runs are safe.
 * Skips users whose profile is too incomplete to project (no name).
 *
 * Run once after deploying SPEC-0011 to populate the mirror for users
 * that existed before `onUserChangedPublicSync` was active. New users
 * are kept in sync by the trigger.
 *
 * Usage:
 *   cd tools && node backfill_users_public.js service-account.json
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = process.argv[2];
if (!serviceAccountPath) {
  console.error('Usage: node backfill_users_public.js <path-to-service-account.json>');
  process.exit(1);
}
const resolved = path.resolve(serviceAccountPath);
if (!fs.existsSync(resolved)) {
  console.error(`Service account file not found: ${resolved}`);
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(require(resolved)) });
const db = admin.firestore();

/**
 * Mirrors the TS [publicUserProjection] used by the trigger. Kept in
 * sync manually — projection logic is intentionally simple, and this
 * script runs once before launch.
 */
function publicUserProjection(uid, data) {
  if (!data) return null;
  const name = data.name;
  if (typeof name !== 'string' || name.length === 0) return null;

  const photoUrl =
    typeof data.photoUrl === 'string' && data.photoUrl.length > 0 ? data.photoUrl : null;
  const rawBio = typeof data.bio === 'string' ? data.bio.trim() : '';
  const bio = rawBio.length > 0 ? rawBio : null;

  const g = data.gamification || {};
  const level = typeof g.level === 'number' && g.level >= 1 ? g.level : 1;
  const selectedTitle =
    typeof g.selectedTitle === 'string' && g.selectedTitle.length > 0
      ? g.selectedTitle
      : null;
  const displayedBadges = Array.isArray(g.displayedBadges)
    ? g.displayedBadges.filter((b) => typeof b === 'string')
    : [];

  return { uid, name, photoUrl, bio, level, selectedTitle, displayedBadges };
}

const BATCH_SIZE = 400;

async function backfill() {
  console.log('Reading users/ ...');
  const snap = await db.collection('users').get();
  console.log(`  found ${snap.size} user docs`);

  let written = 0;
  let skipped = 0;
  let batch = db.batch();
  let pending = 0;

  for (const doc of snap.docs) {
    const proj = publicUserProjection(doc.id, doc.data());
    if (!proj) {
      skipped += 1;
      continue;
    }
    batch.set(
      db.collection('users_public').doc(doc.id),
      { ...proj, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
    written += 1;
    pending += 1;
    if (pending >= BATCH_SIZE) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
      console.log(`  ... ${written} written so far`);
    }
  }
  if (pending > 0) {
    await batch.commit();
  }

  console.log(`Done. Written: ${written}, skipped (incomplete profile): ${skipped}`);
}

backfill().catch((e) => {
  console.error(e);
  process.exit(1);
});
