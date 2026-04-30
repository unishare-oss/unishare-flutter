# Auth Feature Design

**Date:** 2026-04-30
**Status:** Approved
**Scope:** Firebase-native authentication for the Unishare Flutter app (separate product from the NestJS web platform)

---

## Overview

Implement authentication as the first feature of the Flutter app. The app is Firebase-native with no dependency on the NestJS API. Auth supports Google sign-in and email/password, with MS OAuth deferred to a later phase. Guest browsing (read-only) is supported.

---

## Screens & Navigation

Five entry points in the auth feature:

| Route | Screen | Access |
|---|---|---|
| `/welcome` | Logo, tagline, Google button, "Sign in with email", "Create account", "Continue as guest" | Unauthenticated |
| `/sign-in` | Email + password form with back navigation | Unauthenticated |
| `/sign-up` | Name + university (optional) + email + password + confirm + consent | Unauthenticated |
| `/` | Home feed | All (guest = read-only) |
| overlay | Academic profile bottom sheet | Authenticated + `departmentId == null` |

**GoRouter redirect rules:**
- No session + not guest → `/welcome`
- Authenticated → `/` (feed)
- Authenticated user hits `/welcome`, `/sign-in`, `/sign-up` → redirect to `/`
- Authenticated + `departmentId == null` → feed loads, bottom sheet overlays on top (not a redirect)

---

## Firebase & Data Layer

**Firebase Auth:** `firebase_auth` + `google_sign_in`. Auth state exposed as a Riverpod stream provider watching `FirebaseAuth.instance.authStateChanges()`.

**Firestore user document** — created on first sign-in:

```
users/{uid}
  name: String
  email: String
  photoUrl: String?
  universityId: String?       ← collected during email sign-up
  departmentId: String?       ← collected via academic profile modal
  enrollmentYear: int?        ← collected via academic profile modal
  role: 'student' | 'admin'   ← defaults to 'student'
  consentGivenAt: Timestamp?  ← written on email sign-up
  createdAt: Timestamp
```

**Supporting collections (read-only at this phase):**
- `universities/{id}` — sign-up university dropdown
- `departments/{id}` — academic profile modal dropdown

**Guest mode:** no Firestore user doc. Router allows `/` feed. All write actions (upload, react, comment) show a "sign in to continue" prompt.

---

## Clean Architecture Layers

### Domain (pure Dart — zero Firebase/Flutter imports)

```
features/auth/domain/
  entities/
    app_user.dart                  ← id, name, email, photoUrl, universityId,
                                      departmentId, enrollmentYear, role
  repositories/
    auth_repository.dart           ← abstract interface
  usecases/
    sign_in_with_google.dart
    sign_in_with_email.dart
    sign_up_with_email.dart
    sign_out.dart
    get_current_user.dart
    update_academic_profile.dart
```

### Data

```
features/auth/data/
  datasources/
    firebase_auth_datasource.dart  ← Firebase Auth calls
    firestore_user_datasource.dart ← user doc reads/writes
  models/
    app_user_model.dart            ← Freezed + JSON, extends AppUser
  repositories/
    auth_repository_impl.dart
```

### Presentation

```
features/auth/presentation/
  providers/
    auth_state_provider.dart       ← streams FirebaseAuth.authStateChanges()
    current_user_provider.dart     ← fetches Firestore user doc
  screens/
    welcome_screen.dart
    sign_in_screen.dart
    sign_up_screen.dart
  widgets/
    academic_profile_bottom_sheet.dart
    google_sign_in_button.dart
    auth_text_field.dart
```

---

## Error Handling & Edge Cases

**Auth errors** mapped to user-facing messages:

| Firebase code | User message |
|---|---|
| `wrong-password` / `user-not-found` | "Invalid email or password" |
| `email-already-in-use` | "An account with this email already exists" |
| `network-request-failed` | "Check your connection and try again" |
| Google sign-in cancelled | Silent — no snackbar |

**First-time Google sign-in:** after Firebase Auth succeeds, check if `users/{uid}` exists. If not, create the doc from the OAuth token (name + photoUrl). University and department left null → triggers academic profile bottom sheet.

**Academic profile modal:**
- "Do it later" dismisses for the session only
- On next cold start, re-appears if `departmentId` is still null
- Department dropdown is required to enable the save button
- User can always escape via "Do it later"

**Consent:**
- Email sign-up: explicit checkbox; `consentGivenAt` written to Firestore on submit
- Google sign-up: footnote only ("By continuing you agree to Terms & Privacy") — no checkbox, matches web behaviour

---

## Testing

**Widget tests (one per screen, mandatory per CLAUDE.md):**

| File | What it covers |
|---|---|
| `welcome_screen_test.dart` | Renders Google button, email links, guest link; tapping each navigates correctly |
| `sign_in_screen_test.dart` | Validation errors for empty/invalid fields; submit calls use case |
| `sign_up_screen_test.dart` | Password mismatch error; consent required before submit |

**Unit tests:**

| File | What it covers |
|---|---|
| `auth_repository_impl_test.dart` | Mocked datasources; Firebase user → AppUser mapping |
| `sign_in_with_google_test.dart` | Delegates to repository |
| `sign_in_with_email_test.dart` | Delegates to repository |
| `sign_up_with_email_test.dart` | Delegates to repository |
| `update_academic_profile_test.dart` | Delegates to repository |

No golden tests at this phase — auth screens are simple enough that widget tests suffice.

---

## Out of Scope (this phase)

- MS OAuth (deferred)
- Forgot password / email reset flow
- Email verification gate
- Admin role enforcement (read from Firestore but not acted on yet)
