---
title: '0011: AI Post Summary'
description: 'Pre-generate an AI summary and auto-tags for every uploaded post so students can judge relevance without opening the file, and enable an in-context "Ask AI" chat grounded on the document.'
---

# PROP-0011: AI Post Summary

**Status:** PROPOSED
**Author:** Slade
**Date:** 2026-05-14
**Spec:** (pending approval)
**Approved by:** (fill in when accepted)

---

## Problem

The Unishare feed is content-rich but opaque at the list level. A post entry shows a title, course tag, and uploader name — none of which reliably conveys whether the document inside answers the specific question a student has right now. The only way to find out is to open the post detail screen, download or preview the file, and read enough of it to make a judgement. For large lecture decks, past exams, or multi-week note compilations, that round-trip takes two to five minutes per file. When a student is preparing for an exam and scanning the feed for relevant material, that friction compounds quickly.

The result is lower engagement with genuinely useful content and a higher abandonment rate on the post detail screen. Uploaders also lose signal: if students bounce before reading the file, the uploader receives no feedback that their material was valuable.

A concise AI-generated summary — shown directly on the post detail screen before any download — gives students enough signal to decide in under ten seconds whether the file is worth their time. Auto-tagging is a secondary benefit: posts uploaded without tags receive machine-assigned tags, improving feed filtering for everyone downstream.

The feature must be free to operate (no paid infra), must not run on every view (pre-generation at upload time only), and must stay entirely within the Firebase ecosystem (no external server).

---

## Proposed Solution

### Overview

A Firebase Cloud Function is triggered by the Firestore `onCreate` event on `posts/{postId}`. The function fetches the uploaded file from Firebase Storage, extracts up to 6,000 characters of plain text, calls the Groq API (`llama-3.3-70b-versatile`) to produce a summary, and writes the result back to the same Firestore document. The Flutter app reads the `summary` field as part of its existing `watchPost` stream and renders a collapsible summary panel on the post detail screen. A second HTTPS-callable Cloud Function backs the "Ask AI" chat feature.

No Flutter client ever calls Groq directly. The API key lives only in Cloud Functions environment config (`functions.config()` or Secret Manager).

### Cloud Function: `generatePostSummary` (Firestore onCreate trigger)

Trigger: `firestore.document('posts/{postId}').onCreate`

Steps:

1. Read `mediaUrls[0]` and `mediaType` from the new post document.
2. Download the file bytes from Firebase Storage using the Admin SDK.
3. Extract text:
   - PDF: `pdf-parse` library, first 6,000 characters of extracted text.
   - DOCX: `mammoth` library, plain-text output, first 6,000 characters.
   - Other types: write `summary: null` and `summaryError: 'unsupported_type'`; exit early.
4. Content screening pass (single Groq call): ask the model whether the text contains any harmful, plagiarised, or policy-violating content. If the screen returns `FLAGGED`, write `summary: null`, `summaryStatus: 'flagged'`, and exit — do not proceed to summarise.
5. Summary call (single Groq call): system prompt instructs the model to produce exactly one introductory sentence followed by 3–7 bullet points prefixed with `•`. Max output tokens: 300.
6. Auto-tag call (conditional, single Groq call): if the post document has an empty or absent `tags` array, ask the model to return up to 5 relevant academic tags as a JSON array. Merge these tags into the `tags` field.
7. Write to Firestore:

```
posts/{postId}
  summary:        string   (the formatted summary text)
  summaryStatus:  string   ('done' | 'flagged' | 'unsupported_type' | 'error')
  summarizedAt:   Timestamp
  tags:           string[] (merged with any user-supplied tags — auto-tag path only)
```

All writes are a single `update()` call to avoid overwriting the rest of the post document.

**In-memory text cache:** The extracted raw text is held in a module-level `Map<string, string>` keyed by `postId` for the lifetime of the Cloud Function instance (one hour maximum before cold restart). This satisfies the Redis-equivalent caching requirement without provisioning any additional infrastructure. The "Ask AI" function (below) benefits from this cache when the same instance handles both calls.

**Groq rate-limit strategy:** Cloud Functions for Firebase enforce a maximum of one concurrent instance per deployment by default on the free tier (Spark plan). Posts are therefore processed serially. If the Groq free tier rate limit (30 req/min on `llama-3.3-70b-versatile`) is approached, the function catches `429` responses and retries with exponential back-off up to three times before writing `summaryStatus: 'error'`. No queuing infrastructure is required at this scale.

### Cloud Function: `askAiAboutPost` (HTTPS callable)

Accepts: `{ postId: string, conversationHistory: Message[], question: string }`

The function loads the extracted text for `postId` from the in-memory cache if available, or re-downloads and re-extracts from Firebase Storage (same logic as above). It then calls Groq with the full conversation history prepended by a system prompt that grounds the model on the document text. If the question is classified as off-topic (no overlap with the document content), the model is instructed to reply with the literal string `OFF_TOPIC` so the client can show a friendly redirect message.

The caller must be authenticated (Firebase Auth token verified via `context.auth`). Unauthenticated calls are rejected with `unauthenticated`.

### Firestore schema additions

The following fields are added to existing `posts/{postId}` documents (no new collection required):

```
summary:        string?    null until the function completes
summaryStatus:  string?    'pending' (set by client at upload) | 'done' | 'flagged' | 'unsupported_type' | 'error'
summarizedAt:   Timestamp? null until the function completes
```

No index changes are required — these fields are never used as query predicates.

### Flutter changes

**Domain layer (`features/posts/domain/`):**

- Add `summary`, `summaryStatus`, and `summarizedAt` fields to the `Post` entity (pure Dart, no new imports).
- Add `SummaryStatus` enum: `pending`, `done`, `flagged`, `unsupportedType`, `error`.
- Add `AskAiRepository` abstract interface with `askAi(postId, history, question)` method returning `Future<String>`.
- Add `AskAiUseCase` wrapping the repository.

**Data layer (`features/posts/data/`):**

- Update `PostDto` / mapper to read the three new fields.
- Add `AskAiRemoteDatasource` that calls the `askAiAboutPost` HTTPS callable function via `cloud_functions`.
- Add `AskAiRepositoryImpl`.

**Presentation layer (`features/posts/presentation/`):**

- Extend `PostDetailScreen` with a `AiSummaryPanel` widget: collapsible card, amber Sparkles icon, "AI SUMMARY" label in `AppTypography.mono`, intro sentence in `theme.textTheme.bodyMedium`, bullet points with amber dot prefix.
- When `summaryStatus == pending`, show a shimmer placeholder.
- When `summaryStatus == flagged`, show a muted "Content could not be summarised" message.
- Add `AskAiSection` widget below the summary panel: collapsible, chat input field, message list. The section is only rendered when `summaryStatus == done`.
- Add `askAiProvider` (`AsyncNotifier`) that calls `AskAiUseCase` and maintains local conversation history.

### Clean Architecture layers

| Layer | Artifact |
|---|---|
| `domain/entities/` | `Post` entity (extended), `SummaryStatus` enum, `AiMessage` entity |
| `domain/repositories/` | `AskAiRepository` abstract interface |
| `domain/usecases/` | `AskAiUseCase` |
| `data/datasources/` | `AskAiRemoteDatasource` (HTTPS callable) |
| `data/repositories/` | `AskAiRepositoryImpl` |
| `presentation/providers/` | `askAiProvider` |
| `presentation/widgets/` | `AiSummaryPanel`, `AskAiSection`, `AiMessageBubble` |

The Cloud Function code lives outside the Flutter app at `functions/src/` in the repo root (standard Firebase project layout). It is not part of the `apps/mobile` package and introduces no Flutter or Dart dependencies.

---

## Alternatives Considered

### A — Client-side text extraction and direct LLM call from Flutter

Extract text from the file on the device using a Dart PDF or DOCX library, then call the Groq HTTP API directly from Flutter.

**Pros:** No Cloud Functions required. No server-side infrastructure to maintain. Summary could be generated lazily on first view rather than at upload time, meaning only viewed posts incur API cost.

**Cons:** The Groq API key would be embedded in the Flutter app binary, where it is trivially extractable by any user with a decompiler. This violates the project's no-plaintext-secrets convention and would expose the team's free-tier quota to abuse. Text extraction on mobile is CPU and battery intensive for large PDFs; a 40-page lecture deck can take several seconds on a mid-range Android device. Offline extraction fails entirely when the user has no local copy of the file. The client also has no server-side caching surface, so the same file would be extracted repeatedly on every device that views the post. **Rejected:** API key exposure is a non-negotiable disqualifier. Battery and UX cost are secondary concerns that reinforce the rejection.

### B — Gemini (Google AI) instead of Groq

Use Gemini via the Vertex AI Firebase extension or direct Gemini API calls from Cloud Functions.

**Pros:** Gemini is deeply integrated with the Google/Firebase ecosystem. The Firebase Genkit framework provides first-class Firestore trigger patterns, reducing boilerplate. Gemini 1.5 Flash has a generous free tier (15 req/min, 1M tokens/day on AI Studio free tier) with a 1M-token context window — the 6,000-character document extract is trivial.

**Cons:** The team has already configured Groq API credentials in the environment. Switching to Gemini requires setting up a new API project, a separate billing account (even for free tier), and a different SDK. Gemini API latency from the Bangkok region has historically been higher than Groq for small-context requests. The Genkit framework is still in beta and adds a new dependency with an uncertain stability surface. The `llama-3.3-70b-versatile` model on Groq has demonstrated strong academic summarisation quality in the NestJS reference implementation. **Not rejected outright** — if Groq free-tier rate limits prove insufficient at scale, migrating to Gemini Flash is a viable path. The reversal cost is moderate: the Cloud Function logic is self-contained, so swapping the LLM client touches only the function code, not the Flutter app or Firestore schema.

### C — On-demand summary (generated on first view, not at upload)

Instead of triggering summarisation on `onCreate`, trigger it when the first user opens the post detail screen — either via a Firestore write from the client that the function watches, or via a direct HTTPS callable that the screen invokes if `summary` is null.

**Pros:** Only viewed posts are ever summarised, reducing Groq API call volume for posts that receive zero traffic (stale or niche uploads). Cold-start behaviour is visible only to the first viewer, not silently deferred.

**Cons:** The first viewer of any post experiences a 2–4 second loading delay while the function runs. This is particularly poor UX for popular posts where many users arrive at the same moment (Firestore `onUpdate` could trigger the function multiple times for a single document). Race conditions between concurrent first-view requests require deduplication logic (check-then-set). The upload-time trigger is cleaner: summarisation is a side-effect of ingestion, not of viewing, which aligns with the principle that the feed should always be ready to consume. The user brief explicitly states "pre-generated once at upload time." **Rejected:** the user brief rules it out directly, and the UX degradation for first viewers is not acceptable.

---

## Open Questions

1. **Supported file types at launch.** The reference implementation handles PDF and DOCX. Should PPTX (PowerPoint) be in scope for launch, given that many lecture slides are shared in that format? `python-pptx` or `officeparser` could extract slide text in the Node.js function, but adds a dependency and increases cold-start time. A decision is needed before the spec enumerates extraction libraries.

2. **Cold-start latency on the free Spark plan.** The Firebase free tier does not support Cloud Functions with minimum instance configuration, meaning every cold start downloads `pdf-parse` and `mammoth` from the module cache. Cold starts on the Spark plan can take 3–8 seconds for Node.js functions with heavy native dependencies. Students uploading a post will not see the summary panel populate for up to 10–15 seconds after upload. Is this acceptable, or should a loading/pending state on the post detail screen persist until the `summary` field is written (real-time listener handles this automatically)?

3. **Groq free-tier rate limit at scale.** The `llama-3.3-70b-versatile` model on the Groq free tier allows 30 requests per minute and 14,400 requests per day. Each summarisation consumes up to three requests (screen + summary + auto-tag). At 100 posts uploaded per day, the daily cap is safe. At 500+ posts per day, the daily cap is breached. What is the expected upload volume at launch, and is a graceful degradation path (skip auto-tag to save one request, or fall back to a smaller model) acceptable?

4. **"Ask AI" availability gate.** Should the Ask AI chat section be rendered only when `summaryStatus == done`, or should it be available as soon as the post document exists (even before summarisation completes)? Showing it only when `done` simplifies the UX and avoids chat sessions where the model has no document context. However, it means users who open a post in the first 15 seconds after upload see no AI affordance at all. The preferred behaviour must be confirmed before the presentation layer is specced.

5. **Conversation history persistence.** The `askAiProvider` holds conversation history in local Riverpod state (lost on screen pop). Should conversation history be persisted to Firestore (`posts/{postId}/aiChats/{userId}`) so users can resume a session? This significantly increases read/write volume and adds a new sub-collection. The simpler path (ephemeral in-memory history) should be the default unless there is a specific UX requirement for persistence.

6. **Summary display when `summaryStatus == error`.** If the Cloud Function fails (Groq timeout, extraction failure), the post detail screen shows no summary. Should there be a manual "Retry summary" action available to the post author, or is a silent failure (summary panel simply absent) acceptable for the first release?

---

## Acceptance Criteria

- When an authenticated user uploads a PDF or DOCX post, a `summary` field is written to the corresponding Firestore document within 30 seconds of the upload completing, without any additional client action.
- The post detail screen displays the `AiSummaryPanel` when `summaryStatus == done`. The panel shows one introductory sentence and between three and seven bullet points prefixed with an amber dot.
- The `AiSummaryPanel` is collapsible. Its expanded/collapsed state persists for the lifetime of the screen but is not persisted to storage.
- When `summaryStatus == pending`, the summary panel area displays a shimmer placeholder. When `summaryStatus` is `flagged`, `unsupported_type`, or `error`, the panel displays a muted descriptive message and the Ask AI section is not rendered.
- A post uploaded without tags receives auto-generated tags (up to 5) written to its `tags` array by the Cloud Function. A post uploaded with tags is not modified by the auto-tag step.
- The "Ask AI" section is rendered only when `summaryStatus == done`. It accepts a free-text question and returns a response grounded on the document content. If the question is off-topic, the UI displays a friendly "This question is outside the document's scope" message.
- The `askAiAboutPost` HTTPS callable function rejects unauthenticated requests with a Firebase `unauthenticated` error.
- The Groq API key is never present in Flutter source code, `pubspec.yaml`, or any file committed to the repository. It is stored exclusively in Cloud Functions environment configuration.
- The `Post` domain entity, `SummaryStatus` enum, `AiMessage` entity, and `AskAiRepository` interface contain zero Flutter or Firebase imports.
- `AiSummaryPanel` and `AskAiSection` each have a widget test covering the `pending`, `done`, and error states.
- `AskAiUseCase` has a unit test against a mock `AskAiRepository` covering successful response and `OFF_TOPIC` reply paths.
- `flutter analyze` reports zero errors or warnings on all new Dart code.
- Firestore security rules do not grant read access to `summary` or `summaryStatus` to unauthenticated users (consistent with existing post-read rules).
