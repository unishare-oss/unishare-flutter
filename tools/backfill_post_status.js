// One-time backfill: sets status='approved' on every existing posts/* doc that
// is missing the field so legacy content stays visible after the feed query
// change (watchFeed now filters where status == 'approved').
//
// Run ONCE per environment, before deploying the SPEC-0013 Flutter build:
//   node tools/backfill_post_status.js tools/service-account.json
//
// service-account.json is gitignored. Get it from:
//   Firebase Console → Project Settings → Service accounts → Generate new key
const admin = require('firebase-admin');
const cert = require(process.argv[2]);

admin.initializeApp({ credential: admin.credential.cert(cert) });
const db = admin.firestore();

(async () => {
  const BATCH_SIZE = 400;
  let scanned = 0;
  let updated = 0;
  let lastDoc = null;

  console.log('Starting post status backfill…');

  while (true) {
    let q = db.collection('posts').orderBy('__name__').limit(BATCH_SIZE);
    if (lastDoc) q = q.startAfter(lastDoc);

    const snap = await q.get();
    if (snap.empty) break;

    const batch = db.batch();
    let batchUpdates = 0;
    for (const doc of snap.docs) {
      scanned++;
      if (!('status' in doc.data())) {
        batch.update(doc.ref, { status: 'approved' });
        batchUpdates++;
        updated++;
      }
    }
    if (batchUpdates > 0) await batch.commit();
    lastDoc = snap.docs[snap.docs.length - 1];
    console.log(`  scanned=${scanned} updated=${updated}`);
  }

  console.log(`Done. Scanned ${scanned} posts, set status='approved' on ${updated}.`);
  process.exit(0);
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
