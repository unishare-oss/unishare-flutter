#!/usr/bin/env node
/**
 * Seed Firestore with universities, departments, and courses.
 *
 * Usage:
 *   cd tools && npm install
 *   node seed_firestore.js <path-to-service-account.json>
 *
 * Get the service account key from:
 *   Firebase Console → Project Settings → Service accounts → Generate new private key
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const universities = require('./seeds/universities');
const departments = [
  require('./seeds/cs'),
  require('./seeds/it'),
  require('./seeds/dsi'),
  require('./seeds/cpe'),
  require('./seeds/inc'),
  require('./seeds/eie'),
  require('./seeds/arc'),
  require('./seeds/dd'),
  require('./seeds/dt'),
  require('./seeds/env'),
  require('./seeds/cve'),
  require('./seeds/che'),
];

const serviceAccountPath = process.argv[2];
if (!serviceAccountPath) {
  console.error('Usage: node seed_firestore.js <path-to-service-account.json>');
  process.exit(1);
}

const resolved = path.resolve(serviceAccountPath);
if (!fs.existsSync(resolved)) {
  console.error(`Service account file not found: ${resolved}`);
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(require(resolved)) });
const db = admin.firestore();

async function seed() {
  console.log('Seeding universities...');
  for (const u of universities) {
    const { id, ...data } = u;
    await db.collection('universities').doc(id).set(data);
    console.log(`  ✓ ${u.shortName}`);
  }

  console.log('Seeding departments and courses...');
  for (const dept of departments) {
    const { id, courses, ...deptData } = dept;
    await db.collection('departments').doc(id).set(deptData);

    let batch = db.batch();
    let count = 0;
    const flushes = [];
    for (const course of courses) {
      const ref = db.collection('departments').doc(id).collection('courses').doc(course.code);
      const data = { code: course.code, name: course.name };
      if (course.yearLevel != null) data.yearLevel = course.yearLevel;
      batch.set(ref, data);
      if (++count === 500) {
        flushes.push(batch.commit());
        batch = db.batch();
        count = 0;
      }
    }
    if (count > 0) flushes.push(batch.commit());
    await Promise.all(flushes);
    console.log(`  ✓ ${dept.name} — ${courses.length} courses`);
  }

  console.log('Done.');
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Seed failed:', err.message);
    process.exit(1);
  });
