# Upload Progress Screen Design

**Date:** 2026-05-07
**Status:** Approved

## Problem

When a user attaches files to a post and hits Submit, the create-post screen blocks — buttons are disabled, the user is trapped until the upload finishes. For large files this is a poor experience.

## Decisions

- **Dedicated progress screen** pushed via GoRouter on Submit
- **Per-file detail** — each file listed with its own status (queued / uploading with inline bar / done)
- **Ring hero** — circular progress ring showing overall percentage, file count subtitle below
- **Auto-navigate to feed** after ~1.5 s once `CreatePostPublished` is emitted
- **Cancel = discard** — stops upload via Dio `CancelToken`, removes Hive draft entirely. No "save for later" because there is no drafts inbox.
- **Orphaned R2 files** — files already uploaded before cancel are left in storage (TODO: add worker DELETE endpoint for cleanup)
- **Fire-and-forget submit** — `submit()` is called without `await`, then `/upload-progress` is pushed immediately. The create-post screen never blocks.

## State Changes

Add `FileUploadPhase` and `FileUploadProgress` to `create_post_provider.dart`:

```dart
enum FileUploadPhase { queued, uploading, done }

class FileUploadProgress {
  final String filename;      // basename for display
  final FileUploadPhase phase;
  final double progress;      // 0.0–1.0, meaningful only when uploading
}

final class CreatePostUploading extends CreatePostState {
  final List<FileUploadProgress> files;
  final double overallProgress; // 0.0–1.0
}
```

The notifier holds:
- `CancelToken? _cancelToken` — Dio cancellation handle
- `PostDraft? _inflight` — reference to the in-flight draft for cancel cleanup

New `cancel()` method:
```dart
Future<void> cancel() async {
  _cancelToken?.cancel();
  // TODO: orphaned R2 files — add worker DELETE endpoint and call it
  // for each url in _inflight.uploadedUrls before removing the draft.
  final draft = _inflight;
  if (draft != null) {
    await ref.read(postRepositoryProvider).removeDraft(draft.id);
  }
  state = const CreatePostIdle();
}
```

`DioException` with `type == DioExceptionType.cancel` is caught silently in `submit()`.

## Per-file Progress Wiring

Add `onFileProgress(int fileIndex, double fileProgress)` callback alongside the existing `onProgress` in:
- `PostRepository.publishDraft` (domain interface)
- `PostRepositoryImpl.publishDraft` (implementation)
- `CreatePost.call` (use case)

In `PostRepositoryImpl`, drive both callbacks from the existing upload loop:
```dart
final progressFn = (fp) {
  onFileProgress?.call(i, fp);
  onProgress?.call((i + fp) / paths.length);
};
```

The notifier uses `onFileProgress` to emit `CreatePostUploading` with updated per-file state on each tick.

## Navigation

`CreatePostScreen._submit()` becomes synchronous (no `await`):
```dart
void _submit() {
  // build draft...
  ref.read(createPostProvider.notifier).submit(draft: draft, ...);
  context.push('/upload-progress');
}
```

Remove `isSubmitting` guard on nav buttons and inline progress/publishing banners from `CreatePostScreen` — no longer needed.

New GoRouter entry:
```dart
GoRoute(path: '/upload-progress', builder: (_, __) => const UploadProgressScreen()),
```

## Upload Progress Screen — UI States

### Uploading
- AppBar: "Uploading Post" + red Cancel button
- Ring: amber (`#D97706`), shows overall percentage in centre
- Subtitle: "X of Y files" + "Uploading \<filename\>…"
- File list: done rows show green checkmark + "Done"; active row shows spinner + inline progress bar + percentage; queued rows are dimmed with empty circle

### Publishing (all files done)
- Ring turns green (`#059669`), full, shows checkmark in centre
- Title: "Publishing…", subtitle: "Finishing up…"
- Cancel button is greyed out / disabled
- All file rows show green checkmark + "Done"
- Auto-navigates to feed after 1.5 s

### Error
- Ring turns red (`#DC2626`), stopped at progress-at-failure, shows `!` in centre
- Title: "Upload failed", subtitle: "\<filename\> could not be uploaded"
- Red error banner with human-readable message
- Amber Retry button — re-calls `submit()` with the same draft

## Files to Create / Modify

| File | Change |
|------|--------|
| `create_post_provider.dart` | Add `FileUploadPhase`, `FileUploadProgress`, update `CreatePostUploading`, add `_cancelToken`, `_inflight`, `cancel()` |
| `post_repository.dart` | Add `onFileProgress` param to `publishDraft` |
| `post_repository_impl.dart` | Wire `onFileProgress` in upload loop |
| `create_post.dart` | Pass through `onFileProgress` |
| `create_post_screen.dart` | Make `_submit` sync, push `/upload-progress`, remove inline progress UI |
| `upload_progress_screen.dart` | **New** — ring hero + file list, all three states |
| router | Add `/upload-progress` route |

## Out of Scope

- R2 orphan cleanup (TODO tracked in `cancel()`)
- "Save draft for later" / drafts inbox
- Parallel file uploads
