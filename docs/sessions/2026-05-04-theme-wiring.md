# Session: Wire app theme throughout the app

**Date:** 2026-05-04  
**Agent:** flutter-engineer  
**Status:** HANDOFF — ready to implement

---

## Problem

The user has a multi-theme system (`AppThemes`) but the theme is not applied to the whole app. The root cause: widgets hardcode colors instead of reading from `Theme.of(context)`.

---

## Theme system (already built, do not change)

| File | Role |
|------|------|
| `lib/shared/theme/app_theme_data.dart` | `AppThemeData` — typed token struct |
| `lib/shared/theme/themes.dart` | `AppThemes.all` — 12 named themes |
| `lib/shared/theme/app_theme.dart` | `AppTheme.build()` → `ThemeData` |
| `lib/shared/theme/providers/theme_provider.dart` | `activeThemeProvider` → `ThemeData` |
| `lib/main.dart` | `MaterialApp.router(theme: theme)` ✅ wired |

`AppTheme.build()` already sets:
- `scaffoldBackgroundColor: d.background`
- `colorScheme.surface: d.background`, `onSurface: d.foreground`, `primary: d.primary`
- `inputDecorationTheme`: `fillColor: d.card`, borders from `d.border`, focus from `d.amber`
- `AppColors` extension with `muted`, `textSecondary`, `textMuted`, `amber`, `surfaceDark`, etc.

To read custom tokens: `Theme.of(context).extension<AppColors>()!`

---

## Key fix: AuthTextField

`lib/features/auth/presentation/widgets/auth_text_field.dart`

Currently hardcodes ALL decoration. Since `AppTheme.build()` already defines `inputDecorationTheme`, just remove the redundant overrides:

```dart
decoration: InputDecoration(
  hintText: widget.hint,
  hintStyle: GoogleFonts.spaceGrotesk(fontSize: 14, color: Theme.of(context).extension<AppColors>()!.textSecondary),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
  isDense: true,
  errorStyle: GoogleFonts.spaceGrotesk(fontSize: 12, color: Theme.of(context).colorScheme.error),
  suffixIconConstraints: const BoxConstraints.tightFor(width: 36, height: 36),
  suffixIcon: ...,
),
```

Remove: `filled`, `fillColor`, `border`, `enabledBorder`, `focusedBorder`, `errorBorder`, `focusedErrorBorder` — all come from `inputDecorationTheme` automatically.

---

## Welcome screen

`lib/features/auth/presentation/screens/welcome_screen.dart`

Has a comment: *"Web-matched auth palette — hardcoded so these screens always look correct regardless of the active app theme."*

**Decision needed:** Should the auth screen respect the active theme, or always use the Unishare light palette?

- If **always fixed**: leave hardcoded colors as-is. Only fix `AuthTextField`.
- If **theme-aware**: replace `_kBg`, `_kForeground`, `_kPrimary`, `_kBorder`, etc. with `Theme.of(context).colorScheme.*` and `AppColors` extension reads.

---

## Other screens to audit

Run this to find other files with hardcoded hex colors:
```bash
grep -rn "Color(0x" apps/mobile/lib --include="*.dart" | grep -v "theme\|_k\|const.*Color" | grep -v "\.g\.dart\|\.freezed\.dart"
```

---

## What was done this session (do NOT redo)

- Firestore rules: `universities`, `departments`, `courses` → `allow read: if true` (public reference data)
- `firestore_user_datasource.dart`: `createUser` omits null fields; `updateAcademicProfile` omits null `enrollmentYear`; `getUniversities`/`getDepartments` use `get()` not `snapshots()`
- `auth_repository_impl.dart`: sign-up and Google sign-in no longer do extra `getUser` round-trip
- `welcome_screen.dart`: university dropdown fixed (white fill, "No university" hint, `Icons.keyboard_arrow_down`, `isExpanded: true`)
- `auth_text_field.dart`: fill color changed from amber `0xFFFEF3C7` to `Colors.white`
- `tools/seeds/` + `tools/seed_firestore.js`: Firestore seed for 1 university + 12 departments + all courses
- `firebase.json` created at repo root for `firebase deploy --only firestore:rules`

---

## Pending (not done yet)

1. Wire theme colors into `AuthTextField` (remove hardcoded decoration)
2. Decide if welcome screen should be theme-aware or fixed-palette
3. Revert debug error display in welcome screen back to user-friendly messages (currently shows raw `e.toString()` — changed for debugging, never reverted)
4. Commit all outstanding changes
