---
name: Auth feature follow-ups
description: Known gaps after auth feature implementation (2026-04-30) that need addressing before shipping
type: project
---

Auth feature is implemented and tests pass. Two required follow-ups before runtime works:

1. **GoogleSignIn.instance.initialize()** must be called in `apps/mobile/lib/core/firebase/firebase_init.dart` before Google sign-in will function on Android/iOS. Without it, `GoogleSignIn.instance.authenticate()` throws at runtime.

2. **Firestore security rules** for `users/{uid}` are not written. The create path (first sign-up) and update path (academic profile) need separate rules. Needs architect review.

**Why:** These were out of scope for the flutter-engineer implementation task but are blocking for production use.
**How to apply:** Flag these immediately if anyone asks "why doesn't Google sign-in work?" or if Firestore writes are rejected.
