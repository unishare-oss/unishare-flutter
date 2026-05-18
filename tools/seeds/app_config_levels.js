// Level threshold lookup for the achievements v1 system.
// Seeded into Firestore document: `app_config/levels`.
//
// Each entry maps a level number to the cumulative points required to reach it.
// Beyond level 10, every additional `perLevelAbove10` points grants the next level.

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
