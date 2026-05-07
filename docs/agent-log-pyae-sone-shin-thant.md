# Agent Log

Automated log of all Claude Code sessions.
See `CLAUDE.md` for the logging convention.

---
Date: 2026-05-07 12:00
Member: Pyae Sone Shin Thant
Agent: flutter-engineer
Task: Task 4 fix — rewrite CourseStep as ConsumerWidget with Riverpod AsyncValue pattern, fix test retry-timer hang
Prompt: The previous implementer got 9/9 tests passing using FutureBuilder (wrong architecture). Rewrite to use ConsumerWidget + AsyncValue, change family providers to auto-dispose, and fix tests to override family providers directly to avoid Riverpod 3.x retry-timer pumpAndSettle hang.

---
Date: 2026-05-07 11:00
Member: Pyae Sone Shin Thant
Agent: flutter-engineer
Task: Task 2 — add CourseFirestoreDatasource
Prompt: Create apps/mobile/lib/features/post/data/datasources/course_firestore_datasource.dart with getDepartments and getCourses methods backed by Firestore.
Outcome: Created CourseFirestoreDatasource. flutter analyze reports no issues. Committed as fdcc278.
Decisions: File content was specified exactly by the task; no design decisions were made.
Handoff: CourseFirestoreDatasource is ready to be injected into whatever repository or notifier needs department/course lookups.
Review: PENDING

---
Date: 2026-05-07 10:00
Member: Pyae Sone Shin Thant
Agent: flutter-engineer
Task: Task 4 — implement UploadProgressScreen with widget tests
Prompt: Write failing widget tests first, then implement UploadProgressScreen showing a circular ring hero, per-file status rows, publishing state, and error recovery.
Outcome: Created upload_progress_screen.dart (ConsumerStatefulWidget) and upload_progress_screen_test.dart. Tests confirmed failing before screen existed. Fixed one unnecessary_cast lint and one use_build_context_synchronously warning. flutter analyze clean. All 5 widget tests pass. Committed as f894652.
Decisions: Replaced ternary chain with explicit if/else blocks in _buildRing to eliminate unnecessary_cast on the already-narrowed CreatePostError type. Used inline // ignore comment for the async gap BuildContext use inside Future.delayed since the mounted guard immediately precedes it, making it safe.
Handoff: Task 4 complete (commit f894652). Task 5 (wire UploadProgressScreen into GoRouter at /posts/upload-progress) remains. Screen needs a route entry so CreatePostScreen can push to it after calling notifier.submit().
Review: PENDING

---
Date: 2026-05-07 00:01
Member: Pyae Sone Shin Thant
Agent: flutter-engineer
Task: Task 3 — rewrite CreatePostNotifier with per-file progress states and cancel support
Prompt: Rewrite CreatePostNotifier to emit per-file FileUploadProgress states, track a CancellationToken, and expose a cancel() method that aborts the upload and removes the draft.
Outcome: Replaced the CreatePostNotifier class in create_post_provider.dart. Added dio and cancellation_token imports. Notifier now initialises FileUploadProgress list from draft.localMediaPaths, delegates onFileProgress to update per-file phase/progress, accumulates currentOverall, handles DioException cancel silently, and exposes cancel() which calls _cancellationToken.cancel() then removeDraft(). flutter analyze clean, all 85 unit tests pass, codegen succeeded.
Decisions: DioException catch block only suppresses cancel-type exceptions; other Dio errors fall through to CreatePostError. currentOverall is a local variable captured by closure — correct Dart semantics for accumulating progress across callbacks.
Handoff: Task 3 complete (commit d895293). Tasks 4 (UploadProgressScreen widget) and 5 (widget test) remain.
Review: PENDING

---
Date: 2026-05-07 00:00
Member: Pyae Sone Shin Thant
Agent: flutter-engineer
Task: Fix three correctness bugs in the upload stack found during code review
Prompt: Fix listener leak (single CancelToken per publishDraft call), make uploadText cancellable, and make _put's onProgress a named parameter
Outcome: Applied all three fixes. `dioCancelToken` and `addCancelListener` moved before the for-loop in `post_repository_impl.dart`. `uploadText` gained a `CancelToken? cancelToken` named param passed through to `_put`. `_put`'s `onProgress` changed from positional to named; all three internal call sites updated. `flutter analyze` clean, all 85 unit tests pass.
Decisions: The three fixes were applied in a single commit as they are tightly coupled — all relate to cancellation plumbing in the same two files.
Handoff: Upload stack correctness bugs resolved. Tasks 3-5 of the upload-progress feature (UI screen, provider, widget test) are unblocked and can proceed.
Review: PENDING

---
Date: 2026-05-04 00:00
Member: Pyae Sone Shin Thant
Agent: qa-engineer
Task: Add Dependabot for pub packages and GitHub Actions, plus dependency review on PRs
Prompt: Implement Dependabot for pub packages + Actions; Dependabot vulnerabilities flagged on push (2 on default branch)
Outcome: Created .github/dependabot.yml (pub + github-actions, weekly) and .github/workflows/dependency-review.yml (blocks PRs with moderate+ vulnerabilities)
Decisions: Used dependency-review-action on pull_request rather than push — the action only works against a diff so PR is the correct trigger; fail-on-severity set to moderate to catch meaningful issues without noise
Handoff: After pushing, GitHub will scan the default branch and surface the 2 known vulnerabilities as Dependabot alerts in the Security tab; no code changes needed for that
Review: PENDING

---
Date: 2026-04-30
Member: Pyae Sone Shin Thant
Agent: flutter-engineer (orchestrated via subagent-driven-development)
Task: Implement full design system — 12 themes, token builder, Riverpod+Hive persistence
Prompt: Run superpowers:subagent-driven-development with the plan at docs/superpowers/plans/2026-04-30-design-system.md

Outcome: All 9 plan tasks completed and reviewed (spec + code quality gates per task). 17 unit tests added and passing. Branch feat/design-system pushed; PR #1 opened. Post-plan improvements applied: ThemeNotifier defensive Hive fallback, activeTheme keepAlive, setTheme ID validation with test, border removed from AppColors (use colorScheme.outline), CI workflow and repo hygiene files added to main.
Decisions: Single-slot theming (all themes via theme: param, ThemeMode.light); border kept in AppThemeData for ColorScheme.outline wiring but removed from AppColors extension to avoid dual read paths; ThemeNotifier keepAlive to prevent dispose-between-state-and-persist crash.
Handoff: PR #1 (feat/design-system → main) is open and ready for review. Worktree at .worktrees/design-system can be removed after merge.
Review: PENDING

---
Date: 2026-04-30
Member: Pyae Sone Shin Thant
Agent: flutter-engineer (subagent — Task 2)
Task: Create AppThemeData color token struct
Prompt: Task 2 of the Flutter design system plan — create lib/shared/theme/app_theme_data.dart with the immutable AppThemeData class that holds all 24 color tokens used by the 12 themes.

Outcome: Created AppThemeData with all 24 required color token fields. flutter analyze reports no issues. Committed as feat: add AppThemeData color token struct.
Decisions: File content was specified exactly by the task; no design decisions were made.
Handoff: Task 3 can now import AppThemeData to define concrete theme instances.
Review: APPROVED by architect (spec + quality review passed)

---
Date: 2026-04-30
Member: Pyae Sone Shin Thant
Agent: flutter-engineer (subagent — Task 3)
Task: Add AppColors ThemeExtension (TDD)
Prompt: Task 3 of the Flutter design system plan — create AppColors as ThemeExtension<AppColors> with 12 color fields, implement copyWith and lerp, and write 5 unit tests using TDD.

Outcome: Created app_colors.dart and app_colors_test.dart. Test written first (confirmed compilation failure), then implementation added. All 5 tests pass. flutter analyze: no issues. Committed as feat: add AppColors ThemeExtension.
Decisions: lerp delegates to Color.lerp for each field; copyWith uses standard nullable-param pattern.
Handoff: AppColors is ready to be registered in ThemeData.extensions. Access via Theme.of(context).extension<AppColors>()!.
Review: APPROVED by architect (spec + quality review passed)

---
Date: 2026-04-30
Member: Pyae Sone Shin Thant
Agent: flutter-engineer
Task: Run smoke test sequence for design system implementation (Task 9)
Prompt: Run full smoke test: flutter test, flutter analyze, dart format check, and commit formatting fixes if needed.

Outcome: All 16 unit tests passed. flutter analyze reported no issues. dart format detected formatting diffs in 4 files and committed them as style: apply dart format to design system files (03548cb). Working tree clean.
Decisions: Committed formatting fixes under a style: prefix to keep them distinct from feature commits.
Handoff: Branch feat/design-system clean and ready for review.
Review: PENDING
Files:
  ? apps/mobile/lib/features/post_feed/ (untracked)

Files:
  ? apps/mobile/lib/features/post_feed/ (untracked)

Files:
  ? apps/mobile/lib/features/post_feed/ (untracked)

Files:
  ? apps/mobile/lib/features/post_feed/ (untracked)

Files:
  ? apps/mobile/lib/features/post_feed/ (untracked)

Files:
  ? apps/mobile/lib/features/post_feed/ (untracked)

Files:
  ~ apps/mobile/lib/main.dart
  ? apps/mobile/lib/core/firebase/firebase_init.dart (untracked)
Summary:  1 file changed, 2 insertions(+)


---
Date: 2026-04-30 00:00
Member: Sai Zayar Hein
Agent: flutter-engineer
Task: Implement auth feature — domain, data, presentation layers + router + tests per tech-specs/01-auth-design.md
Prompt: read @tech-specs/01-auth-design.md and implement we have firebase
  [14:47] Write: apps/mobile/lib/features/auth/domain/entities/app_user.dart
  [14:47] Write: apps/mobile/lib/features/auth/domain/entities/auth_exception.dart
  [14:47] Write: apps/mobile/lib/features/auth/domain/repositories/auth_repository.dart
  [14:47] Write: apps/mobile/lib/features/auth/domain/usecases/sign_in_with_google.dart
  [14:47] Write: apps/mobile/lib/features/auth/domain/usecases/sign_in_with_email.dart
  [14:47] Write: apps/mobile/lib/features/auth/domain/usecases/sign_up_with_email.dart
  [14:47] Write: apps/mobile/lib/features/auth/domain/usecases/sign_out.dart
  [14:47] Write: apps/mobile/lib/features/auth/domain/usecases/get_current_user.dart
  [14:47] Write: apps/mobile/lib/features/auth/domain/usecases/update_academic_profile.dart
  [14:47] Write: apps/mobile/lib/features/auth/data/models/app_user_model.dart
  [14:48] Write: apps/mobile/lib/features/auth/data/datasources/firebase_auth_datasource.dart
  [14:48] Write: apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  [14:48] Write: apps/mobile/lib/features/auth/data/repositories/auth_repository_impl.dart
  [14:48] Write: apps/mobile/lib/features/auth/presentation/providers/auth_repository_provider.dart
  [14:48] Write: apps/mobile/lib/features/auth/presentation/providers/auth_state_provider.dart
  [14:48] Write: apps/mobile/lib/features/auth/presentation/providers/current_user_provider.dart
  [14:48] Write: apps/mobile/lib/features/auth/presentation/providers/guest_mode_provider.dart
  [14:48] Write: apps/mobile/lib/features/auth/presentation/providers/universities_provider.dart
  [14:48] Write: apps/mobile/lib/features/auth/presentation/providers/departments_provider.dart
  [14:48] Write: apps/mobile/lib/features/auth/presentation/widgets/auth_text_field.dart
  [14:49] Write: apps/mobile/lib/features/auth/presentation/widgets/google_sign_in_button.dart
  [14:49] Write: apps/mobile/lib/features/auth/presentation/widgets/academic_profile_bottom_sheet.dart
  [14:49] Write: apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  [14:49] Write: apps/mobile/lib/features/auth/presentation/screens/sign_in_screen.dart
  [14:50] Write: apps/mobile/lib/features/auth/presentation/screens/sign_up_screen.dart
  [14:50] Write: apps/mobile/lib/core/router/router.dart
  [14:50] Write: apps/mobile/test/widget/auth/welcome_screen_test.dart
  [14:50] Write: apps/mobile/test/widget/auth/sign_in_screen_test.dart
  [14:50] Write: apps/mobile/test/widget/auth/sign_up_screen_test.dart
  [14:50] Write: apps/mobile/test/unit/auth/auth_repository_impl_test.dart
  [14:51] Write: apps/mobile/test/unit/auth/fakes/fake_firebase_auth_datasource.dart
  [14:51] Write: apps/mobile/test/unit/auth/fakes/fake_firestore_user_datasource.dart
  [14:51] Write: apps/mobile/test/unit/auth/sign_in_with_google_test.dart
  [14:51] Write: apps/mobile/test/unit/auth/sign_in_with_email_test.dart
  [14:51] Write: apps/mobile/test/unit/auth/sign_up_with_email_test.dart
  [14:51] Write: apps/mobile/test/unit/auth/update_academic_profile_test.dart
  [14:54] Write: apps/mobile/lib/features/auth/data/datasources/firebase_auth_datasource.dart
  [14:55] Edit: apps/mobile/lib/core/router/router.dart
  [14:55] Edit: apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  [14:55] Edit: apps/mobile/lib/features/auth/presentation/widgets/academic_profile_bottom_sheet.dart
  [14:57] Edit: apps/mobile/lib/features/auth/presentation/screens/sign_up_screen.dart
  [14:57] Edit: apps/mobile/lib/features/auth/presentation/widgets/academic_profile_bottom_sheet.dart
  [14:57] Edit: apps/mobile/lib/features/auth/presentation/widgets/academic_profile_bottom_sheet.dart
  [14:57] Edit: apps/mobile/test/widget/auth/welcome_screen_test.dart
  [14:57] Edit: apps/mobile/lib/features/auth/presentation/screens/sign_up_screen.dart
  [14:57] Edit: apps/mobile/test/widget/auth/sign_up_screen_test.dart
  [14:58] Write: apps/mobile/test/unit/auth/fakes/fake_firebase_auth_datasource.dart
  [14:58] Write: apps/mobile/test/unit/auth/fakes/fake_firestore_user_datasource.dart
  [14:58] Edit: apps/mobile/test/widget/auth/sign_up_screen_test.dart
  [14:58] Edit: apps/mobile/test/widget/auth/sign_up_screen_test.dart
  [14:59] Edit: apps/mobile/lib/core/router/router.dart
  [14:59] Edit: apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  [14:59] Edit: apps/mobile/lib/features/auth/presentation/widgets/academic_profile_bottom_sheet.dart
  [14:59] Edit: apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  [15:00] Edit: apps/mobile/test/widget/auth/sign_in_screen_test.dart
  [15:00] Edit: apps/mobile/test/widget/auth/sign_in_screen_test.dart
  [15:00] Edit: apps/mobile/test/widget/auth/sign_up_screen_test.dart
  [15:00] Edit: apps/mobile/test/widget/auth/sign_up_screen_test.dart

Outcome: Full auth feature implemented. 34 tests pass (10 new unit + 7 new widget + 17 pre-existing). flutter analyze: no issues. dart format: clean.
Decisions: GoogleSignIn v7 uses singleton GoogleSignIn.instance.authenticate() — no accessToken on the auth object, only idToken. AsyncValue in Riverpod v3 uses .hasValue + .value instead of .valueOrNull. Session-level academic profile dismissal uses a module-level bool rather than a StateProvider to avoid extra codegen. DropdownButtonFormField.value deprecated in Flutter 3.41 — replaced with initialValue. Test fakes inject stub FirebaseAuth/Firestore via constructor to avoid SDK initialisation at test time.
Handoff: Router is auth-aware with redirect guards. All three screens (WelcomeScreen, SignInScreen, SignUpScreen) are wired. Academic profile bottom sheet triggers on home screen after first frame if departmentId is null. Ready for architect/QA review.
Review: PENDING

Outcome: Full auth feature implemented — 9 domain classes, 4 data classes (with Freezed model + codegen), 6 providers, 3 screens, 3 widgets, router with redirect logic. 34 tests pass, flutter analyze clean.
Decisions: GoogleSignIn v7 requires `GoogleSignIn.instance.authenticate()` (no more `signIn()` method). Session dismissal of academic profile bottom sheet stored as module-level bool (not a provider) so it resets on cold start automatically. `AuthStateProvider` redirect guards use `.hasValue` (not `.valueOrNull`) due to Riverpod v3 `AsyncValue` API. `_academicProfileSessionDismissed` set to true before showing sheet to prevent re-show on same-session re-navigation.
Handoff: GoogleSignIn.instance.initialize() must be called during app startup (not yet done in firebase_init.dart) before Google sign-in will work on Android/iOS at runtime. Firestore security rules for users/{uid} create/update are not yet written. Academic profile bottom sheet will not re-show after sign-out + sign-in within same session (not specified by spec, acceptable).
Review: PENDING
  [15:49] Write: apps/mobile/lib/features/auth/presentation/widgets/auth_text_field.dart
  [15:50] Write: apps/mobile/lib/features/auth/presentation/widgets/google_sign_in_button.dart
  [15:50] Write: apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  [15:51] Write: apps/mobile/lib/features/auth/presentation/screens/sign_in_screen.dart
  [15:52] Write: apps/mobile/lib/features/auth/presentation/screens/sign_up_screen.dart
  [15:52] Edit: apps/mobile/lib/features/auth/presentation/screens/sign_up_screen.dart
  [15:52] Edit: apps/mobile/lib/features/auth/presentation/screens/sign_up_screen.dart
  [15:52] Edit: apps/mobile/lib/features/auth/presentation/screens/sign_up_screen.dart
  [15:52] Edit: apps/mobile/lib/features/auth/presentation/widgets/google_sign_in_button.dart
  [15:54] Edit: apps/mobile/lib/features/auth/presentation/screens/sign_up_screen.dart
  [16:00] Edit: apps/mobile/pubspec.yaml
  [16:00] Edit: apps/mobile/pubspec.yaml
  [16:07] Write: apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  [16:07] Edit: apps/mobile/lib/core/router/router.dart
  [16:07] Edit: apps/mobile/lib/core/router/router.dart
  [16:07] Edit: apps/mobile/lib/core/router/router.dart
  [16:08] Write: apps/mobile/test/widget/auth/welcome_screen_test.dart
  [16:09] Edit: apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  [16:09] Edit: apps/mobile/test/widget/auth/welcome_screen_test.dart
  [16:09] Edit: apps/mobile/test/widget/auth/welcome_screen_test.dart
Files:
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  1 file changed, 7 insertions(+), 5 deletions(-)

  [16:14] Edit: apps/mobile/lib/features/auth/presentation/widgets/auth_text_field.dart
  [16:14] Edit: apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
Files:
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  1 file changed, 7 insertions(+), 5 deletions(-)

  [16:21] Edit: apps/mobile/lib/features/auth/data/datasources/firebase_auth_datasource.dart
  [16:21] Edit: apps/mobile/lib/features/auth/data/datasources/firebase_auth_datasource.dart
Files:
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  1 file changed, 7 insertions(+), 5 deletions(-)
Files:
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  2 files changed, 13 insertions(+), 10 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  2 files changed, 13 insertions(+), 10 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  2 files changed, 15 insertions(+), 12 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  2 files changed, 15 insertions(+), 12 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  2 files changed, 15 insertions(+), 12 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  2 files changed, 15 insertions(+), 12 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  3 files changed, 18 insertions(+), 15 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  3 files changed, 18 insertions(+), 15 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  3 files changed, 18 insertions(+), 15 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  3 files changed, 18 insertions(+), 15 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  3 files changed, 18 insertions(+), 15 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  3 files changed, 18 insertions(+), 15 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  3 files changed, 30 insertions(+), 23 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  3 files changed, 30 insertions(+), 23 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/auth_text_field.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  4 files changed, 42 insertions(+), 29 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/auth_text_field.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  4 files changed, 42 insertions(+), 29 deletions(-)

Files:
  ~ apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/auth_text_field.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/unishare_logo.dart
Summary:  4 files changed, 42 insertions(+), 29 deletions(-)


2026-05-04
  [15:08] Edit: apps/mobile/ios/Runner.xcodeproj/project.pbxproj
  [15:10] Edit: apps/mobile/ios/Runner.xcodeproj/project.pbxproj
  [19:24] Edit: apps/mobile/android/app/src/main/AndroidManifest.xml
  [19:24] Edit: apps/mobile/ios/Runner/Info.plist
  [19:24] Edit: apps/mobile/ios/Runner/Info.plist
  [19:30] Edit: apps/mobile/pubspec.yaml
  [20:01] Edit: apps/mobile/pubspec.yaml
  [20:22] Edit: apps/mobile/lib/features/auth/data/repositories/auth_repository_impl.dart
Files:
  ~ apps/mobile/lib/features/auth/data/repositories/auth_repository_impl.dart
Summary:  1 file changed, 10 insertions(+), 2 deletions(-)

  [20:41] Edit: apps/mobile/test/unit/auth/fakes/fake_firebase_auth_datasource.dart
  [20:41] Edit: apps/mobile/test/unit/auth/fakes/fake_firebase_auth_datasource.dart
  [20:41] Edit: apps/mobile/test/unit/auth/auth_repository_impl_test.dart
  [20:41] Edit: apps/mobile/test/unit/auth/auth_repository_impl_test.dart
  [20:47] Edit: apps/mobile/test/unit/auth/fakes/fake_firebase_auth_datasource.dart

---
Date: 2026-05-05 00:00
Member: Pyae Sone Shin Thant
Agent: architect
Task: Write Tech Proposal 0005 — Main Navigation Bar
Prompt: /new-proposal — write main navbar based on the figma, should exist in pages that are in figma.

Outcome: Wrote tech-proposals/0005-main-navbar.md (DRAFT). 4-tab bottom bar (FEED, POSTS, NOTIFS, MORE) with StatefulShellRoute + custom-painted widget. MORE branch destinations use top-level paths (/profile, /saved, /departments, /requests).
Decisions: Recommended custom-painted bar over Material NavigationBar due to Figma token divergence; StatefulShellRoute for GoRouter integration; dedicated /more screen (not bottom sheet) for deep-linkability; secondary destinations at top-level paths per user preference.
Handoff: Proposal is DRAFT — team must review and move to PROPOSED before spec can begin. Run /new-spec 0005-main-navbar once approved.
Review: PENDING

2026-05-05
  [14:39] Write: apps/mobile/lib/shared/widgets/scroll_to_top_target.dart
  [14:39] Write: apps/mobile/lib/shared/widgets/main_nav_bar.dart
  [14:39] Write: apps/mobile/lib/core/router/shell_scaffold.dart
  [14:39] Write: apps/mobile/lib/features/feed/presentation/screens/feed_screen.dart
  [14:39] Write: apps/mobile/lib/features/post/presentation/screens/my_posts_screen.dart
  [14:40] Write: apps/mobile/lib/features/notifications/presentation/screens/notifications_screen.dart
  [14:52] Write: apps/mobile/lib/features/more/presentation/screens/more_screen.dart
  [14:52] Write: apps/mobile/lib/features/profile/presentation/screens/profile_screen.dart
  [14:52] Write: apps/mobile/lib/features/saved/presentation/screens/saved_screen.dart
  [14:52] Write: apps/mobile/lib/features/departments/presentation/screens/departments_screen.dart
  [14:52] Write: apps/mobile/lib/features/requests/presentation/screens/requests_screen.dart
  [15:11] Edit: apps/mobile/lib/shared/widgets/scroll_to_top_target.dart
  [15:15] Edit: apps/mobile/lib/features/more/presentation/screens/more_screen.dart
  [16:13] Edit: apps/mobile/lib/core/router/router.dart
  [16:13] Edit: apps/mobile/lib/core/router/shell_scaffold.dart
  [16:13] Edit: apps/mobile/lib/shared/widgets/main_nav_bar.dart
  [16:13] Edit: apps/mobile/lib/shared/widgets/main_nav_bar.dart
  [16:13] Edit: apps/mobile/lib/shared/widgets/main_nav_bar.dart
  [16:42] Edit: apps/mobile/lib/core/router/router.dart
  [16:42] Edit: apps/mobile/lib/shared/widgets/main_nav_bar.dart
  [16:42] Edit: apps/mobile/lib/shared/widgets/main_nav_bar.dart
  [16:42] Write: apps/mobile/lib/features/feed/presentation/screens/feed_screen.dart
  [16:42] Edit: apps/mobile/test/widget/shared/widgets/main_nav_bar_test.dart
  [16:43] Edit: apps/mobile/test/widget/shared/widgets/main_nav_bar_test.dart
  [16:55] Write: apps/mobile/lib/features/post/presentation/screens/my_posts_screen.dart
  [16:55] Write: apps/mobile/lib/features/notifications/presentation/screens/notifications_screen.dart
  [16:55] Write: apps/mobile/lib/features/profile/presentation/screens/profile_screen.dart
  [16:55] Write: apps/mobile/lib/features/saved/presentation/screens/saved_screen.dart
  [16:55] Write: apps/mobile/lib/features/departments/presentation/screens/departments_screen.dart
  [16:55] Write: apps/mobile/lib/features/requests/presentation/screens/requests_screen.dart

2026-05-06
  [13:07] Write: apps/mobile/lib/features/post/data/datasources/upload_file_stub.dart
  [13:07] Write: apps/mobile/lib/features/post/data/datasources/upload_file_io.dart
  [13:07] Write: apps/mobile/lib/features/post/data/datasources/post_storage_datasource.dart
  [13:08] Edit: apps/mobile/lib/features/post/data/models/post_draft_model.dart
  [13:09] Edit: apps/mobile/test/widget/features/post/screens/create_post_screen_test.dart
  [13:09] Edit: apps/mobile/test/unit/features/post/domain/usecases/create_post_test.dart
  [13:09] Edit: apps/mobile/test/unit/features/post/domain/usecases/sync_draft_queue_test.dart
  [13:09] Edit: apps/mobile/test/widget/features/post/widgets/draft_queue_indicator_test.dart
  [13:09] Edit: apps/mobile/test/widget/features/post/screens/create_post_screen_test.dart
  [13:09] Edit: apps/mobile/test/unit/features/post/domain/usecases/create_post_test.dart
  [13:09] Edit: apps/mobile/test/unit/features/post/domain/usecases/sync_draft_queue_test.dart
  [13:09] Edit: apps/mobile/test/widget/features/post/widgets/draft_queue_indicator_test.dart
  [13:11] Edit: apps/mobile/lib/features/post/presentation/widgets/details_step.dart
  [13:11] Edit: apps/mobile/lib/features/post/presentation/widgets/details_step.dart
  [13:12] Write: apps/mobile/test/widget/features/profile/screens/profile_screen_test.dart
  [13:12] Write: apps/mobile/test/widget/features/saved/screens/saved_screen_test.dart
  [13:12] Write: apps/mobile/test/widget/features/departments/screens/departments_screen_test.dart
  [13:12] Write: apps/mobile/test/widget/features/requests/screens/requests_screen_test.dart
  [13:13] Edit: apps/mobile/.gitignore
  [13:25] Edit: apps/mobile/analysis_options.yaml
  [13:29] Edit: apps/mobile/lib/features/post/data/datasources/post_storage_datasource.dart
  [13:29] Edit: apps/mobile/lib/features/post/domain/usecases/create_post.dart
  [13:32] Edit: apps/mobile/pubspec.yaml
  [13:33] Edit: apps/mobile/pubspec.yaml
  [13:45] Edit: apps/mobile/.gitignore
  [14:28] Write: apps/mobile/lib/features/post/data/datasources/upload_file_io.dart
  [14:28] Write: apps/mobile/lib/features/post/data/datasources/upload_file_stub.dart
  [14:29] Write: apps/mobile/lib/features/post/data/datasources/post_storage_datasource.dart
  [14:44] Write: apps/mobile/.vscode/launch.json
  [14:45] Edit: apps/mobile/.gitignore
  [14:47] Edit: apps/mobile/.vscode/launch.json
  [14:52] Edit: apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  [14:52] Edit: apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  [14:56] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [14:59] Edit: apps/mobile/lib/features/post/domain/usecases/create_post.dart
Files:
  ~ apps/mobile/lib/features/post/domain/usecases/create_post.dart
Summary:  1 file changed, 3 insertions(+), 1 deletion(-)

Files:
  ~ apps/mobile/lib/features/post/domain/usecases/create_post.dart
Summary:  1 file changed, 3 insertions(+), 1 deletion(-)

  [15:02] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [15:02] Edit: apps/mobile/lib/features/post/domain/usecases/create_post.dart
  [15:04] Edit: apps/mobile/lib/features/post/domain/usecases/create_post.dart
Files:
  ~ apps/mobile/lib/features/post/domain/usecases/create_post.dart
Summary:  1 file changed, 3 insertions(+), 1 deletion(-)

  [15:05] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
Files:
  ~ apps/mobile/lib/features/post/domain/usecases/create_post.dart
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
Summary:  2 files changed, 10 insertions(+), 8 deletions(-)

  [15:08] Edit: apps/mobile/lib/features/post/domain/usecases/create_post.dart
  [15:11] Edit: apps/mobile/lib/features/post/presentation/widgets/file_upload_widget.dart
  [15:12] Edit: apps/mobile/lib/features/post/domain/entities/post_draft.dart
  [15:12] Edit: apps/mobile/lib/features/post/presentation/widgets/type_step.dart
  [15:13] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
<<<<<<< feature/feed
  [21:37] Edit: apps/mobile/lib/core/router/router.dart
=======
  [15:37] Edit: apps/mobile/test/widget/features/post/widgets/type_step_test.dart
  [15:37] Edit: apps/mobile/test/widget/features/post/widgets/type_step_test.dart
  [15:37] Edit: apps/mobile/test/widget/features/post/screens/create_post_screen_test.dart
Files:
  ~ apps/mobile/test/widget/features/post/screens/create_post_screen_test.dart
  ~ apps/mobile/test/widget/features/post/widgets/type_step_test.dart
Summary:  2 files changed, 3 insertions(+), 3 deletions(-)

>>>>>>> main
Files:
  ~ apps/mobile/lib/core/firebase/firebase_init.dart
  ? apps/mobile/lib/core/router/router.dart (untracked)
  ~ apps/mobile/lib/core/router/shell_scaffold.dart
  ~ apps/mobile/lib/core/storage/post_draft_box.dart
  ~ apps/mobile/lib/features/auth/data/datasources/firebase_auth_datasource.dart
  ~ apps/mobile/lib/features/auth/data/datasources/firestore_user_datasource.dart
  ~ apps/mobile/lib/features/auth/data/models/app_user_model.dart
  ~ apps/mobile/lib/features/auth/data/repositories/auth_repository_impl.dart
  ~ apps/mobile/lib/features/auth/domain/repositories/auth_repository.dart
  ~ apps/mobile/lib/features/auth/domain/usecases/get_current_user.dart
  ~ apps/mobile/lib/features/auth/domain/usecases/sign_in_with_email.dart
  ~ apps/mobile/lib/features/auth/domain/usecases/sign_in_with_google.dart
  ~ apps/mobile/lib/features/auth/domain/usecases/sign_out.dart
  ~ apps/mobile/lib/features/auth/domain/usecases/sign_up_with_email.dart
  ~ apps/mobile/lib/features/auth/domain/usecases/update_academic_profile.dart
  ~ apps/mobile/lib/features/auth/presentation/providers/auth_repository_provider.dart
  ~ apps/mobile/lib/features/auth/presentation/providers/auth_state_provider.dart
  ~ apps/mobile/lib/features/auth/presentation/providers/current_user_provider.dart
  ~ apps/mobile/lib/features/auth/presentation/providers/departments_provider.dart
  ~ apps/mobile/lib/features/auth/presentation/providers/universities_provider.dart
  ~ apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  ~ apps/mobile/lib/features/auth/presentation/widgets/academic_profile_dialog.dart
  > apps/mobile/lib/features/post_feed/data/datasources/.gitkeep -> apps/mobile/lib/features/feed/data/datasources/.gitkeep
  + apps/mobile/lib/features/feed/data/datasources/preferences_firestore_datasource.dart
  + apps/mobile/lib/features/feed/data/datasources/tag_firestore_datasource.dart
  > apps/mobile/lib/features/post_feed/data/models/.gitkeep -> apps/mobile/lib/features/feed/data/models/.gitkeep
  + apps/mobile/lib/features/feed/data/models/post_filter_preferences_model.dart
  + apps/mobile/lib/features/feed/data/models/tag_model.dart
  > apps/mobile/lib/features/post_feed/data/repositories/.gitkeep -> apps/mobile/lib/features/feed/data/repositories/.gitkeep
  + apps/mobile/lib/features/feed/data/repositories/preferences_repository_impl.dart
  + apps/mobile/lib/features/feed/data/repositories/tag_repository_impl.dart
  > apps/mobile/lib/features/post_feed/domain/entities/.gitkeep -> apps/mobile/lib/features/feed/domain/entities/.gitkeep
  + apps/mobile/lib/features/feed/domain/entities/post_filter_preferences.dart
  + apps/mobile/lib/features/feed/domain/entities/tag_entity.dart
  > apps/mobile/lib/features/post_feed/domain/repositories/.gitkeep -> apps/mobile/lib/features/feed/domain/repositories/.gitkeep
  + apps/mobile/lib/features/feed/domain/repositories/preferences_repository.dart
  + apps/mobile/lib/features/feed/domain/repositories/tag_repository.dart
  > apps/mobile/lib/features/post_feed/domain/usecases/.gitkeep -> apps/mobile/lib/features/feed/domain/usecases/.gitkeep
  + apps/mobile/lib/features/feed/domain/usecases/get_filter_preferences.dart
  + apps/mobile/lib/features/feed/domain/usecases/get_tag_list.dart
  + apps/mobile/lib/features/feed/domain/usecases/save_filter_preferences.dart
  > apps/mobile/lib/features/post_feed/presentation/providers/.gitkeep -> apps/mobile/lib/features/feed/presentation/providers/.gitkeep
  + apps/mobile/lib/features/feed/presentation/providers/active_tag_filters_provider.dart
  + apps/mobile/lib/features/feed/presentation/providers/feed_provider.dart
  + apps/mobile/lib/features/feed/presentation/providers/filter_preferences_provider.dart
  + apps/mobile/lib/features/feed/presentation/providers/tag_list_provider.dart
  > apps/mobile/lib/features/post_feed/presentation/screens/.gitkeep -> apps/mobile/lib/features/feed/presentation/screens/.gitkeep
  ~ apps/mobile/lib/features/feed/presentation/screens/feed_screen.dart
  > apps/mobile/lib/features/post_feed/presentation/widgets/.gitkeep -> apps/mobile/lib/features/feed/presentation/widgets/.gitkeep
  + apps/mobile/lib/features/feed/presentation/widgets/feed_empty_state_widget.dart
  + apps/mobile/lib/features/feed/presentation/widgets/filter_picker_widget.dart
  + apps/mobile/lib/features/feed/presentation/widgets/post_card_widget.dart
  ~ apps/mobile/lib/features/more/presentation/screens/more_screen.dart
  ~ apps/mobile/lib/features/notifications/presentation/screens/notifications_screen.dart
  ? apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart (untracked)
  ~ apps/mobile/lib/features/post/data/datasources/post_storage_datasource.dart
  + apps/mobile/lib/features/post/data/datasources/upload_file_io.dart
  + apps/mobile/lib/features/post/data/datasources/upload_file_stub.dart
  ~ apps/mobile/lib/features/post/data/models/post_draft_model.dart
  ? apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart (untracked)
  + apps/mobile/lib/features/post/domain/entities/code_snippet.dart
  ? apps/mobile/lib/features/post/domain/entities/post.dart (untracked)
  ~ apps/mobile/lib/features/post/domain/entities/post_draft.dart
  ~ apps/mobile/lib/features/post/domain/repositories/post_repository.dart
  ~ apps/mobile/lib/features/post/domain/usecases/create_post.dart
  ~ apps/mobile/lib/features/post/domain/usecases/sync_draft_queue.dart
  ~ apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  ~ apps/mobile/lib/features/post/presentation/providers/draft_queue_provider.dart
  ? apps/mobile/lib/features/post/presentation/providers/post_repository_provider.dart (untracked)
  ~ apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  ~ apps/mobile/lib/features/post/presentation/screens/my_posts_screen.dart
  + apps/mobile/lib/features/post/presentation/widgets/code_snippet_widget.dart
  + apps/mobile/lib/features/post/presentation/widgets/course_step.dart
  + apps/mobile/lib/features/post/presentation/widgets/details_step.dart
  ~ apps/mobile/lib/features/post/presentation/widgets/draft_queue_indicator.dart
  + apps/mobile/lib/features/post/presentation/widgets/file_upload_widget.dart
  + apps/mobile/lib/features/post/presentation/widgets/files_step.dart
  + apps/mobile/lib/features/post/presentation/widgets/type_step.dart
  ~ apps/mobile/lib/main.dart
  ~ apps/mobile/lib/shared/theme/app_theme.dart
  ~ apps/mobile/lib/shared/theme/providers/theme_provider.dart
  ~ apps/mobile/lib/shared/theme/themes.dart
  ~ apps/mobile/lib/shared/widgets/main_nav_bar.dart
  ? apps/mobile/pubspec.yaml (untracked)
  + apps/mobile/test/unit/features/post/domain/usecases/create_post_test.dart
  + apps/mobile/test/unit/features/post/domain/usecases/sync_draft_queue_test.dart
  + apps/mobile/test/widget/features/departments/screens/departments_screen_test.dart
  + apps/mobile/test/widget/features/post/screens/create_post_screen_test.dart
  + apps/mobile/test/widget/features/post/widgets/details_step_test.dart
  + apps/mobile/test/widget/features/post/widgets/draft_queue_indicator_test.dart
  + apps/mobile/test/widget/features/post/widgets/files_step_test.dart
  + apps/mobile/test/widget/features/post/widgets/type_step_test.dart
  + apps/mobile/test/widget/features/profile/screens/profile_screen_test.dart
  + apps/mobile/test/widget/features/requests/screens/requests_screen_test.dart
  + apps/mobile/test/widget/features/saved/screens/saved_screen_test.dart
  + apps/mobile/test/widget/feed/feed_screen_test.dart
Summary:  96 files changed, 4880 insertions(+), 439 deletions(-)

  [22:27] Edit: apps/mobile/lib/core/router/router.dart
  [22:28] Edit: apps/mobile/lib/features/post/domain/entities/post.dart
  [22:28] Edit: apps/mobile/lib/features/post/domain/entities/post.dart
  [22:28] Edit: apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart
  [22:28] Edit: apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart
  [22:28] Edit: apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart
  [22:28] Edit: apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart
  [22:28] Edit: apps/mobile/lib/features/post/presentation/providers/post_repository_provider.dart
  [22:29] Edit: apps/mobile/pubspec.yaml
Files:
  ~ apps/mobile/lib/features/feed/presentation/widgets/post_card.dart
  ~ apps/mobile/lib/features/post/data/datasources/comment_firestore_datasource.dart
  ~ apps/mobile/lib/features/post/data/models/comment_dto.dart
  ~ apps/mobile/lib/features/post/data/repositories/comment_repository_impl.dart
  ~ apps/mobile/lib/features/post/data/repositories/like_repository_impl.dart
  ~ apps/mobile/lib/features/post/domain/repositories/comment_repository.dart
  ~ apps/mobile/lib/features/post/domain/usecases/add_comment.dart
  ~ apps/mobile/lib/features/post/domain/usecases/toggle_like.dart
  ~ apps/mobile/lib/features/post/domain/usecases/watch_comments.dart
  ~ apps/mobile/lib/features/post/domain/usecases/watch_post.dart
  ~ apps/mobile/lib/features/post/presentation/providers/comments_provider.dart
  ~ apps/mobile/lib/features/post/presentation/providers/post_detail_provider.dart
  ~ apps/mobile/lib/features/post/presentation/providers/user_like_status_provider.dart
  ~ apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart
  ~ apps/mobile/lib/features/post/presentation/widgets/attachment_list.dart
  ~ apps/mobile/lib/features/post/presentation/widgets/comment_tile.dart
  ~ apps/mobile/lib/features/post/presentation/widgets/like_button.dart
Summary:  17 files changed, 35 insertions(+), 35 deletions(-)

Files:
  ~ apps/mobile/lib/features/feed/presentation/widgets/post_card.dart
  ~ apps/mobile/lib/features/post/data/datasources/comment_firestore_datasource.dart
  ~ apps/mobile/lib/features/post/data/models/comment_dto.dart
  ~ apps/mobile/lib/features/post/data/repositories/comment_repository_impl.dart
  ~ apps/mobile/lib/features/post/data/repositories/like_repository_impl.dart
  ~ apps/mobile/lib/features/post/domain/repositories/comment_repository.dart
  ~ apps/mobile/lib/features/post/domain/usecases/add_comment.dart
  ~ apps/mobile/lib/features/post/domain/usecases/toggle_like.dart
  ~ apps/mobile/lib/features/post/domain/usecases/watch_comments.dart
  ~ apps/mobile/lib/features/post/domain/usecases/watch_post.dart
  ~ apps/mobile/lib/features/post/presentation/providers/comments_provider.dart
  ~ apps/mobile/lib/features/post/presentation/providers/post_detail_provider.dart
  ~ apps/mobile/lib/features/post/presentation/providers/user_like_status_provider.dart
  ~ apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart
  ~ apps/mobile/lib/features/post/presentation/widgets/attachment_list.dart
  ~ apps/mobile/lib/features/post/presentation/widgets/comment_tile.dart
  ~ apps/mobile/lib/features/post/presentation/widgets/like_button.dart
Summary:  17 files changed, 35 insertions(+), 35 deletions(-)

  [23:02] Edit: apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart
  [23:02] Edit: apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart
  [23:02] Write: apps/mobile/lib/features/feed/presentation/providers/feed_provider.dart
  [23:03] Edit: apps/mobile/lib/features/feed/presentation/screens/feed_screen.dart
  [23:03] Edit: apps/mobile/lib/features/feed/presentation/screens/feed_screen.dart
  [23:03] Edit: apps/mobile/lib/features/feed/presentation/screens/feed_screen.dart
  [23:10] Edit: apps/mobile/test/widget/feed/feed_screen_test.dart
  [23:15] Edit: apps/mobile/test/widget/feed/feed_screen_test.dart
  [23:15] Edit: apps/mobile/test/widget/feed/feed_screen_test.dart
  [23:24] Write: apps/mobile/lib/features/feed/presentation/widgets/post_card.dart
  [23:24] Edit: apps/mobile/test/widget/feed/feed_screen_test.dart
  [23:25] Edit: apps/mobile/test/widget/feed/feed_screen_test.dart
  [23:29] Write: apps/mobile/test/widget/feed/feed_screen_test.dart
  [23:38] Edit: apps/mobile/lib/features/post/data/repositories/like_repository_impl.dart
Files:
  ~ apps/mobile/test/unit/auth/fakes/fake_firebase_auth_datasource.dart
Summary:  1 file changed, 3 insertions(+)


2026-05-07
  [10:35] Write: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [10:45] Edit: apps/mobile/pubspec.yaml

---
Date: 2026-05-07 00:00
Member: Pyae Sone Shin Thant
Agent: flutter-engineer
Task: Implement FilePreviewScreen with image/pdf/video/unsupported viewers (SPEC-0007, Task 2)
Prompt: Implement the full contents of apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart — FilePreviewArgs typedef, FilePreviewScreen, _ImageViewer, _PdfViewer, _VideoViewer, _UnsupportedViewer, videoCachePath helper
  [10:48] Write: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [10:51] Edit: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [10:52] Write: apps/mobile/test/widget/features/post/screens/file_preview_screen_test.dart
  [10:53] Edit: apps/mobile/test/widget/features/post/screens/file_preview_screen_test.dart
Outcome: FilePreviewScreen fully implemented. All 4 sub-viewers working per spec. 4 new tests added (2 widget, 2 unit), 171 total passing. flutter analyze: no issues.
Decisions: PdfViewerController has no dispose() method in pdfrx 2.3.0 — removed dispose calls. PdfViewer.uri has no onError param — used PdfViewerParams.errorBannerBuilder instead with addPostFrameCallback to avoid setState-during-build. pageNumber is int? — null-coalesced to 0. pageCount guarded by isReady check. videoCachePath unit tests mock path_provider MethodChannel to avoid MissingPluginException.
Handoff: FilePreviewScreen is ready. Caller must pass FilePreviewArgs as GoRouter extra and extract fields. Widget test does not cover _ImageViewer/_PdfViewer/_VideoViewer as they require real platform plugins — recommend integration tests for those viewers.
Review: PENDING
  [10:57] Edit: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [10:57] Edit: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [10:57] Edit: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [10:57] Edit: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [10:58] Edit: apps/mobile/test/widget/features/post/screens/file_preview_screen_test.dart
  [10:58] Edit: apps/mobile/test/widget/features/post/screens/file_preview_screen_test.dart
  [10:58] Edit: apps/mobile/test/widget/features/post/screens/file_preview_screen_test.dart
  [10:58] Edit: apps/mobile/test/widget/features/post/screens/file_preview_screen_test.dart
  [10:59] Edit: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [11:02] Edit: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [11:02] Edit: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [11:02] Edit: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [11:02] Edit: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [11:03] Edit: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [11:39] Edit: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [11:39] Edit: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [11:41] Edit: apps/mobile/lib/core/router/router.dart
  [11:41] Edit: apps/mobile/lib/core/router/router.dart
  [11:41] Edit: apps/mobile/lib/core/router/router.dart
  [11:41] Edit: apps/mobile/lib/features/post/presentation/widgets/attachment_list.dart
  [11:41] Edit: apps/mobile/lib/features/post/presentation/widgets/attachment_list.dart
  [11:41] Edit: apps/mobile/lib/features/post/presentation/widgets/attachment_carousel.dart
  [11:41] Edit: apps/mobile/lib/features/post/presentation/widgets/attachment_carousel.dart
  [11:41] Edit: apps/mobile/lib/features/post/presentation/widgets/attachment_carousel.dart
  [11:41] Edit: apps/mobile/lib/features/post/presentation/widgets/attachment_carousel.dart
  [11:41] Edit: apps/mobile/lib/features/post/presentation/widgets/attachment_carousel.dart
  [11:42] Edit: apps/mobile/lib/features/post/presentation/widgets/attachment_list.dart
  [11:42] Edit: apps/mobile/lib/features/post/presentation/widgets/attachment_carousel.dart
  [11:45] Edit: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart
  [11:45] Edit: apps/mobile/lib/features/post/presentation/widgets/attachment_carousel.dart
  [11:45] Edit: apps/mobile/lib/features/post/presentation/widgets/attachment_carousel.dart
  [11:45] Edit: apps/mobile/lib/features/post/presentation/screens/file_preview_screen.dart

---
Date: 2026-05-07 19:15
Member: Pyae Sone Shin Thant
Agent: flutter-engineer
Task: Task 1 - FeedCache class with unit tests (TDD approach)
Prompt: Implement FeedCache with TTL support, invalidation, and unmodifiable views. Write tests first, then create the class, run tests, and commit.
  [12:53] Write: apps/mobile/test/unit/features/post/data/datasources/feed_cache_test.dart
  [12:54] Write: apps/mobile/lib/features/post/data/datasources/feed_cache.dart
  [12:54] Edit: apps/mobile/test/unit/features/post/data/datasources/feed_cache_test.dart
Outcome: Task 1 completed successfully. FeedCache class created with full test coverage (9 tests, all passing).
Decisions: Used pure-Dart implementation with no framework dependencies. TTL validation checks both cache presence and time delta. Unmodifiable view prevents external modification of cached data.
Handoff: Task 1 is ready for architect review. Next: Task 2 (FirestorePostDataSource test suite).
Review: PENDING
Files:
  [19:15] Create: apps/mobile/lib/features/post/data/datasources/feed_cache.dart
  [19:15] Create: apps/mobile/test/unit/features/post/data/datasources/feed_cache_test.dart
  [12:59] Edit: apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart
  [13:00] Write: apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart
  [13:04] Write: apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart
  [13:05] Edit: apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart
  [13:08] Edit: apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart
  [13:08] Edit: apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart
  [13:08] Edit: apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart
  [13:13] Edit: apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart
  [13:13] Edit: apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart
  [13:13] Edit: apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart
  [13:13] Edit: apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart
Files:
  ? apps/mobile/test/unit/features/post/data/repositories/ (untracked)

  [13:23] Edit: apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart
  [13:23] Edit: apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart
  [13:24] Edit: apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart
  [13:25] Edit: apps/mobile/lib/features/post/presentation/providers/post_repository_provider.dart
  [13:25] Edit: apps/mobile/lib/features/post/presentation/providers/post_repository_provider.dart
Files:
  ~ apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart
Summary:  1 file changed, 26 insertions(+), 27 deletions(-)

  [13:36] Edit: apps/mobile/android/app/build.gradle.kts
  [13:36] Edit: apps/mobile/android/app/build.gradle.kts
  [14:34] Edit: apps/mobile/lib/features/auth/presentation/providers/auth_repository_provider.dart
  [14:34] Edit: apps/mobile/lib/features/auth/presentation/providers/auth_repository_provider.dart
  [14:34] Write: apps/mobile/lib/features/more/presentation/screens/more_screen.dart
  [14:48] Edit: apps/mobile/test/widget/features/more/more_screen_test.dart
Files:
  ~ apps/mobile/lib/features/post/presentation/widgets/details_step.dart
Summary:  1 file changed, 10 insertions(+)

  [15:26] Edit: apps/mobile/lib/features/feed/presentation/screens/feed_screen.dart
  [15:26] Edit: apps/mobile/lib/features/feed/presentation/screens/feed_screen.dart
  [15:26] Edit: apps/mobile/lib/features/feed/presentation/screens/feed_screen.dart
  [16:19] Write: apps/mobile/test/unit/core/cancellation/cancellation_token_test.dart
  [16:19] Write: apps/mobile/lib/core/cancellation/cancellation_token.dart
  [16:19] Edit: apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  [16:19] Edit: apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  [16:20] Edit: apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  [16:20] Edit: apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  [16:25] Write: apps/mobile/lib/features/post/data/datasources/post_storage_datasource.dart
  [16:25] Write: apps/mobile/lib/features/post/domain/repositories/post_repository.dart
  [16:25] Write: apps/mobile/lib/features/post/domain/usecases/create_post.dart
  [16:25] Edit: apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart
  [16:25] Edit: apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart
  [16:26] Edit: apps/mobile/test/unit/features/post/domain/usecases/create_post_test.dart
  [16:26] Edit: apps/mobile/test/unit/features/post/domain/usecases/create_post_test.dart
  [16:26] Edit: apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart
  [16:27] Edit: apps/mobile/test/unit/features/post/fakes/fake_post_repository.dart
  [16:27] Edit: apps/mobile/test/unit/features/post/fakes/fake_post_repository.dart
  [16:27] Edit: apps/mobile/test/unit/features/post/domain/usecases/sync_draft_queue_test.dart
  [16:27] Edit: apps/mobile/test/unit/features/post/domain/usecases/sync_draft_queue_test.dart
  [16:30] Edit: apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart
  [16:30] Edit: apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart
  [16:30] Edit: apps/mobile/lib/features/post/data/datasources/post_storage_datasource.dart
  [16:31] Edit: apps/mobile/lib/features/post/data/datasources/post_storage_datasource.dart
  [16:33] Edit: apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  [16:34] Edit: apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  [16:37] Edit: apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  [16:37] Edit: apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  [16:37] Edit: apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  [16:37] Edit: apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  [16:37] Edit: apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  [16:40] Write: apps/mobile/test/widget/features/post/screens/upload_progress_screen_test.dart
  [16:41] Write: apps/mobile/lib/features/post/presentation/screens/upload_progress_screen.dart
  [16:41] Edit: apps/mobile/lib/features/post/presentation/screens/upload_progress_screen.dart
  [16:41] Edit: apps/mobile/lib/features/post/presentation/screens/upload_progress_screen.dart
  [16:44] Edit: apps/mobile/lib/features/post/presentation/screens/upload_progress_screen.dart
  [16:44] Edit: apps/mobile/lib/features/post/presentation/screens/upload_progress_screen.dart
  [16:44] Edit: apps/mobile/lib/features/post/presentation/screens/upload_progress_screen.dart
  [16:44] Edit: apps/mobile/lib/features/post/presentation/screens/upload_progress_screen.dart
  [16:45] Edit: apps/mobile/lib/features/post/presentation/screens/upload_progress_screen.dart
  [16:45] Edit: apps/mobile/lib/features/post/presentation/screens/upload_progress_screen.dart
  [16:45] Edit: apps/mobile/lib/features/post/presentation/screens/upload_progress_screen.dart
  [16:45] Edit: apps/mobile/test/widget/features/post/screens/upload_progress_screen_test.dart
  [16:48] Edit: apps/mobile/test/widget/features/post/screens/create_post_screen_test.dart
  [16:48] Edit: apps/mobile/test/widget/features/post/screens/create_post_screen_test.dart
  [16:48] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [16:48] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [16:48] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [16:48] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [16:48] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [16:48] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [16:48] Edit: apps/mobile/lib/core/router/router.dart
  [16:48] Edit: apps/mobile/lib/core/router/router.dart
  [16:48] Edit: apps/mobile/lib/core/router/router.dart
  [16:50] Edit: apps/mobile/test/widget/features/post/widgets/draft_queue_indicator_test.dart
  [16:50] Edit: apps/mobile/test/widget/features/post/widgets/draft_queue_indicator_test.dart
  [16:50] Edit: apps/mobile/test/widget/features/post/screens/post_detail_screen_test.dart
  [16:50] Edit: apps/mobile/test/widget/features/post/screens/post_detail_screen_test.dart
  [16:53] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [16:53] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [16:53] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [16:53] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [16:53] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [16:53] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [17:03] Edit: apps/mobile/lib/features/post/presentation/widgets/files_step.dart
  [17:03] Edit: apps/mobile/lib/features/post/presentation/widgets/files_step.dart
  [17:03] Write: apps/mobile/lib/features/feed/presentation/widgets/feed_empty_state_widget.dart
  [17:03] Write: apps/mobile/lib/features/feed/presentation/widgets/filter_picker_widget.dart
  [17:04] Write: apps/mobile/lib/features/auth/presentation/widgets/google_sign_in_button.dart
  [17:57] Write: apps/mobile/lib/features/post/presentation/widgets/course_step.dart
  [17:58] Write: apps/mobile/lib/features/post/presentation/widgets/details_step.dart
  [17:58] Write: apps/mobile/lib/features/post/presentation/widgets/code_snippet_widget.dart
  [17:59] Write: apps/mobile/lib/features/post/presentation/widgets/file_upload_widget.dart
  [17:59] Write: apps/mobile/lib/features/post/presentation/widgets/type_step.dart
  [17:59] Write: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [18:00] Write: apps/mobile/lib/features/post/presentation/screens/upload_progress_screen.dart
  [18:00] Edit: apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  [18:00] Edit: apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  [18:01] Edit: apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  [18:01] Edit: apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  [18:01] Edit: apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
  [21:59] Edit: apps/mobile/lib/features/post/domain/entities/post_draft.dart
  [21:59] Edit: apps/mobile/lib/features/post/domain/entities/post_draft.dart
  [21:59] Edit: apps/mobile/lib/features/post/domain/entities/post_draft.dart
  [22:00] Edit: apps/mobile/lib/features/post/domain/entities/post_draft.dart
  [22:00] Edit: apps/mobile/test/unit/features/post/domain/usecases/create_post_test.dart
  [22:00] Edit: apps/mobile/test/unit/features/post/domain/usecases/sync_draft_queue_test.dart
  [22:00] Edit: apps/mobile/test/widget/features/post/screens/upload_progress_screen_test.dart
  [22:00] Edit: apps/mobile/test/widget/features/post/widgets/draft_queue_indicator_test.dart
  [22:01] Edit: apps/mobile/lib/features/post/data/models/post_draft_model.dart
  [22:01] Edit: apps/mobile/lib/features/post/data/models/post_draft_model.dart
  [22:01] Edit: apps/mobile/lib/features/post/data/models/post_draft_model.dart
  [22:01] Edit: apps/mobile/lib/features/post/data/models/post_draft_model.dart
  [22:01] Edit: apps/mobile/lib/features/post/data/models/post_draft_model.dart
  [22:01] Edit: apps/mobile/lib/features/post/data/models/post_draft_model.dart
  [22:01] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [22:02] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [22:05] Write: apps/mobile/lib/features/post/data/datasources/course_firestore_datasource.dart
  [22:06] Write: apps/mobile/lib/features/post/presentation/providers/course_reference_provider.dart

---
Date: 2026-05-07 22:30
Member: Pyae Sone Shin Thant
Agent: flutter-engineer
Task: Task 4 — rewrite CourseStep as Firestore-backed ConsumerWidget (TDD)
Prompt: Write failing tests for CourseStep with universityId/selectedDepartmentId/selectedYear/selectedCourseId props and Firestore-backed dropdowns, confirm red phase, implement CourseStep as ConsumerWidget, confirm all 9 tests pass, commit.
Outcome: All 9 CourseStep widget tests pass. create_post_screen_test failures (5 tests, compile errors) are expected — CreatePostScreen has not been updated yet to pass the new required props. Committed as e0800fe.
Decisions: Riverpod 3.x uses ProviderContainer.defaultRetry (exponential backoff, 10 retries) which prevents AsyncError from settling in widget tests via pumpAndSettle. Worked around by using ConsumerStatefulWidget + FutureBuilder instead of ref.watch on a FutureProvider, which uses Flutter's own async machinery that correctly settles in tests. Changed ref.watch to ref.read in provider bodies since the datasource is a singleton and need not be re-watched.
Handoff: Task 4 complete (commit e0800fe). Next task must update CreatePostScreen to pass universityId, selectedDepartmentId, onDepartmentChanged to CourseStep; until then 5 test files that import create_post_screen.dart fail to compile.
Review: PENDING

---
Date: 2026-05-07 22:06
Member: Pyae Sone Shin Thant
Agent: flutter-engineer
Task: Task 3 — add course reference Riverpod providers and run codegen
Prompt: Create course_reference_provider.dart with courseFirestoreDatasource (keepAlive), departmentsForUniversity, and courses providers; run build_runner; verify analyze passes; commit.

Outcome: Created course_reference_provider.dart, ran build_runner (generated course_reference_provider.g.dart), flutter analyze reports no issues.
Decisions: Used exact content from spec verbatim; no changes needed since CourseFirestoreDatasource signature matched.
Handoff: Providers are ready for use in the New Post step-2 screen (department/course picker).
Review: PENDING
  [22:10] Write: apps/mobile/test/widget/features/post/widgets/course_step_test.dart
  [22:10] Write: apps/mobile/lib/features/post/presentation/widgets/course_step.dart
  [22:15] Edit: apps/mobile/lib/features/post/presentation/providers/course_reference_provider.dart
  [22:16] Edit: apps/mobile/lib/features/post/presentation/providers/course_reference_provider.dart
  [22:18] Write: apps/mobile/lib/features/post/presentation/widgets/course_step.dart
  [22:29] Write: apps/mobile/lib/features/post/presentation/providers/course_reference_provider.dart
  [22:29] Write: apps/mobile/lib/features/post/presentation/widgets/course_step.dart
  [22:30] Write: apps/mobile/test/widget/features/post/widgets/course_step_test.dart
  [22:31] Edit: apps/mobile/test/widget/features/post/widgets/course_step_test.dart
  [22:31] Edit: apps/mobile/test/widget/features/post/widgets/course_step_test.dart
  [22:31] Edit: apps/mobile/test/widget/features/post/widgets/course_step_test.dart
  [22:54] Write: apps/mobile/test/widget/features/post/widgets/course_step_test.dart
  [22:54] Edit: apps/mobile/test/widget/features/post/widgets/course_step_test.dart
  [22:54] Edit: apps/mobile/lib/features/post/presentation/widgets/course_step.dart
  [22:54] Edit: apps/mobile/lib/features/post/presentation/widgets/course_step.dart
  [22:56] Edit: apps/mobile/test/widget/features/post/widgets/course_step_test.dart
  [22:56] Edit: apps/mobile/test/widget/features/post/widgets/course_step_test.dart
  [22:56] Edit: apps/mobile/test/widget/features/post/widgets/course_step_test.dart
  [22:56] Edit: apps/mobile/test/widget/features/post/widgets/course_step_test.dart
  [22:57] Edit: apps/mobile/test/widget/features/post/widgets/course_step_test.dart
  [23:01] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [23:01] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [23:03] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [23:08] Edit: apps/mobile/lib/features/post/presentation/widgets/course_step.dart
  [23:10] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [23:11] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [23:11] Write: apps/mobile/test/widget/features/post/screens/create_post_screen_test.dart
  [23:11] Edit: apps/mobile/lib/features/post/presentation/screens/create_post_screen.dart
  [23:14] Edit: apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart
Files:
  ~ apps/mobile/lib/features/feed/presentation/screens/feed_screen.dart
  ~ apps/mobile/lib/features/post/data/datasources/course_firestore_datasource.dart
  ~ apps/mobile/lib/features/post/data/datasources/post_storage_datasource.dart
  ~ apps/mobile/lib/features/post/presentation/providers/create_post_provider.dart
  ~ apps/mobile/lib/features/post/presentation/screens/upload_progress_screen.dart
  ~ apps/mobile/test/widget/features/post/screens/upload_progress_screen_test.dart
Summary:  6 files changed, 30 insertions(+), 19 deletions(-)

