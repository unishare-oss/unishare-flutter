# Session: 2026-05-14-ai-post-summary

**Date:** 2026-05-14
**Member:** Slade
**Agent:** flutter-engineer
**Task:** Implement AI Post Summary feature (SPEC-0009)

## Context

Branch: `feature/ai-post-summary`
Spec: `tech-specs/0009-ai-post-summary.md` (status: REVIEW)
Proposal: `tech-proposals/0009-ai-post-summary.md`

Architecture decision: AI summarization runs in the **existing Cloudflare Worker** (`worker/`), NOT Firebase Cloud Functions. Worker routes added:
- `POST /ai/summarize` — fetches file from R2, extracts text, calls Groq, returns `{summaryStatus, summary}`
- `POST /ai/chat` — accepts `{summary, question, history}`, calls Groq, returns `{reply, isOffTopic}`

Flutter calls the Worker over HTTP after `createPost()`. Worker writes nothing to Firestore — Flutter writes the summary result back itself.

Files are stored in **Cloudflare R2** (not Firebase Storage). Worker fetches them via their public URL (`https://cdn.psstee.dev/...`).

## What is already done (do NOT redo)

**Worker** (`worker/`) — fully scaffolded, ready to deploy:
- `src/index.ts` — routing + `requireAuth` helper + `Env` interface updated
- `src/ai-summarize.ts` — complete implementation
- `src/ai-chat.ts` — complete implementation
- `src/text-extractor.ts` — complete implementation (`unpdf` for PDF, `mammoth` for DOCX)
- `package.json` — `groq-sdk`, `mammoth`, `unpdf` added (run `npm install`)
- `wrangler.toml` — `GROQ_API_KEY` secret documented

**Flutter stubs** — scaffolded but bodies are `Placeholder` / empty, need full implementation:
- `domain/entities/ai_message.dart` — complete ✓
- `domain/repositories/ask_ai_repository.dart` — complete ✓
- `domain/usecases/ask_ai.dart` — complete ✓
- `data/datasources/ask_ai_datasource.dart` — complete ✓ (HTTP POST to `/ai/chat`)
- `data/datasources/ai_summarize_datasource.dart` — complete ✓ (HTTP POST to `/ai/summarize`)
- `data/repositories/ask_ai_repository_impl.dart` — complete ✓
- `presentation/providers/ask_ai_repository_provider.dart` — complete ✓
- `presentation/providers/ask_ai_provider.dart` — complete ✓
- `presentation/widgets/ai_summary_panel.dart` — **STUB, needs implementation**
- `presentation/widgets/ask_ai_section.dart` — **STUB, needs implementation**
- `presentation/widgets/ai_message_bubble.dart` — **STUB, needs implementation**

## What the flutter-engineer must implement (in order)

### 1. Extend `Post` entity
File: `apps/mobile/lib/features/post/domain/entities/post.dart`

Add `SummaryStatus` enum and three new optional fields:
```dart
enum SummaryStatus {
  pending, done, flagged, unsupportedType, error;

  static SummaryStatus? fromFirestore(String? raw) => switch (raw) {
    'pending'          => SummaryStatus.pending,
    'done'             => SummaryStatus.done,
    'flagged'          => SummaryStatus.flagged,
    'unsupported_type' => SummaryStatus.unsupportedType,
    'error'            => SummaryStatus.error,
    _                  => null,
  };
}
```
New fields on `Post`: `final String? summary`, `final SummaryStatus? summaryStatus`, `final DateTime? summarizedAt`

### 2. Update `PostFirestoreDatasource`
File: `apps/mobile/lib/features/post/data/datasources/post_firestore_datasource.dart`

- `_docToPost()`: read `summary`, `summaryStatus` (via `SummaryStatus.fromFirestore`), `summarizedAt`
- `createPost()`: add `'summaryStatus': 'pending'` to the Firestore write when `mediaTypes` contains `'pdf'` or `'docx'`
- Add new method `updatePostSummary(String postId, String? summary, String summaryStatus)` that calls `ref.update({...})`

### 3. Add `http` to pubspec
File: `apps/mobile/pubspec.yaml`
Add: `http: ^1.2.0`
Then run: `flutter pub get`

### 4. Run codegen
```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
```
This generates `ask_ai_provider.g.dart` and `ask_ai_repository_provider.g.dart`.

### 5. Implement `AiSummaryPanel`
File: `apps/mobile/lib/features/post/presentation/widgets/ai_summary_panel.dart`

Design (from screenshot): rounded card, `border: theme.dividerColor`, `color: ac.muted` background.
- Header row: `Icons.auto_awesome` in `ac.amber` + `"AI SUMMARY"` in `AppTypography.mono` uppercase `ac.amber` size 11 + chevron (rotates on collapse)
- `status == null` → `SizedBox.shrink()`
- `status == pending` → shimmer skeleton (3 lines, animated opacity)
- `status == done` → collapsible (default expanded), intro sentence in `theme.textTheme.bodyMedium`, bullet list: 6px amber dot (`ac.amber`) + `bodyMedium` text. Parse `summary` by splitting on `\n`: first non-`•` line is intro, `•` lines are bullets.
- `status == flagged || error` → muted chip: `Icons.warning_amber_rounded` + "Summary unavailable"
- `status == unsupportedType` → muted chip: "Summary not supported for this file type"

### 6. Implement `AiMessageBubble`
File: `apps/mobile/lib/features/post/presentation/widgets/ai_message_bubble.dart`

- `isPending` → left-aligned, `ac.muted` bg, 12dp `CircularProgressIndicator`
- `isUser` → right-aligned, `cs.primary` bg, `cs.onPrimary` text, `BorderRadius` 0 at bottom-right
- `isOffTopic` → left-aligned, `ac.muted` bg, `Icons.warning_amber_rounded` (14, `ac.amber`) + italic `bodySmall`
- default AI → left-aligned, `ac.muted` bg, `cs.onSurface` text, `BorderRadius` 0 at bottom-left

### 7. Implement `AskAiSection`
File: `apps/mobile/lib/features/post/presentation/widgets/ask_ai_section.dart`

- Header: `Icons.smart_toy` in blue + `"ASK AI"` monospace + chevron
- Collapsed by default
- Expanded: `ConstrainedBox(maxHeight: 240)` with `ListView.builder` of `AiMessageBubble`, auto-scroll via `ScrollController`
- Empty state: hint text "Ask anything about this document…" in `ac.textMuted`
- Input row: `TextField` (max 500 chars) + send `IconButton`
- On send: call `ref.read(askAiProvider(postId).notifier).sendMessage(question)` passing `post.summary!` — wait, the notifier needs `summary` for the chat call. Wire `summary` through or read from `postDetailProvider`.
- Catch `AskAiException` and show `SnackBar`

### 8. Update `AskAiRepositoryImpl`
The `ask` method currently passes `postId` but the Worker now needs `summary` (not `postId`). Update `AskAiRepository`, `AskAiUseCase`, and `AskAiRepositoryImpl` to accept `summary` instead of `postId`, OR keep `postId` and look up the post summary from the provider. **Recommended**: add `summary` to `AskAiParams`.

### 9. Wire into `PostDetailScreen`
File: `apps/mobile/lib/features/post/presentation/screens/post_detail_screen.dart`

After the post body/description section, add:
```dart
AiSummaryPanel(
  status: post.summaryStatus,
  summary: post.summary,
),
const SizedBox(height: 12),
if (post.summaryStatus == SummaryStatus.done)
  AskAiSection(postId: post.id, summary: post.summary!),
```

### 10. Trigger summarize after createPost
In `create_post_provider.dart` (or `CreatePostUseCase`), after a successful post creation, if the post has a PDF/DOCX file:
1. Call `AiSummarizeDatasource().call(fileUrl: mediaUrls.first, filename: ...)`
2. Write result to Firestore via `PostFirestoreDatasource().updatePostSummary(postId, summary, summaryStatus)`

### 11. Write tests (9 files per SPEC-0009 test plan)
See `tech-specs/0009-ai-post-summary.md` → Test plan section.

## Handoff

**To:** flutter-engineer (next session)
**Done:** Full scaffold — all domain/data files complete, worker fully implemented, stubs in place for widgets
**Not done:** Steps 1–11 above — none of the Flutter implementation has been written yet
**Watch out for:**
- `ask_ai_provider.g.dart` does NOT exist yet — `build_runner` must run before any compile
- Worker `/ai/chat` accepts `summary` (the text), not `postId` — the Flutter repository impl must pass `post.summary` through `AskAiParams`
- `http: ^1.2.0` must be added to `pubspec.yaml` before the datasources will compile
- Worker must be deployed and `WORKER_BASE_URL` dart-define set before testing end-to-end
- Deploy worker first: `cd worker && npm install && wrangler secret put GROQ_API_KEY && wrangler deploy`
