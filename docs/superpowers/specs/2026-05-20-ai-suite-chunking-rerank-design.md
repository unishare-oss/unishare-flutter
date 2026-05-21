# AI Suite — Chunking, Re-embed-on-Edit, RRF Hybrid Ranking — Design Spec

**Status:** Approved — ready for implementation plan
**Date:** 2026-05-20
**Branch:** `feature/ai-suite-chunking-rerank` (to be created)
**References:**
- PROP-0011 — `tech-proposals/0011-ai-content-suite.md`
- PR #78 — `feat(ai): extractedText caching, auto-tags, full-RAG chat, semantic search`

## Problem

PR #78 shipped the AI Content Suite foundation (cached `extractedText`, auto-tags, full-RAG chat, semantic search). Three gaps remain that PROP-0011 anticipated but did not implement:

1. **Long-document chat silently drops the tail.** `worker/src/ai-chat.ts` hard-slices `extractedText` at `CONTEXT_CHAR_CAP = 30 000` chars. Questions about content past that boundary fail without any signal to the user. The proposal called for chunk + top-k retrieval when content exceeds budget; today there is no chunking layer.
2. **Semantic search drifts after edits.** `post_repository_impl.dart:296 updatePost` writes title/description/tags to Firestore but never re-upserts to Vectorize. A renamed or substantially-rewritten post keeps its stale embedding indefinitely.
3. **Hybrid search ranking is naive.** `feed_screen.dart:136 _mergeWithSemantic` appends vector results after keyword matches with no score blending. A perfect vector hit ranks below a tangential keyword match on a common word.

## Goal

Close all three gaps in a single bundled PR. Reuse the embedding infrastructure already in `worker/src/ai-summarize.ts` and `ai-search.ts`. No regressions for posts that work today (short docs, no edits, exact-keyword searches).

## Non-goals

- **Backfilling pre-PR-#78 posts.** Old posts will continue to lack `extractedText` and Vectorize entries; chat falls through to the existing summary-grounded path. A separate backfill effort is out of scope.
- **Re-embedding on user-tag changes.** User `tags` don't feed the search blob today; only `aiTags` do (see `worker/src/ai-summarize.ts:279 buildSearchBlob`).
- **Server-side hybrid ranking.** Ranking stays client-side. The new `/ai/search` endpoint and the existing keyword filter both keep their current contracts; only the merge changes.
- **Re-summarization on edit.** Title/description edits trigger a re-embed only — not a fresh LLM call. The summary and `aiTags` from the original `/ai/summarize` are reused.

---

## Architecture

Three flows, sharing one new embedding helper:

```
worker/
  src/
    embeddings.ts                 (NEW — embedText() helper, single source of truth)
    chunking.ts                   (NEW — chunkText() + retrieveChunks())
    ai-summarize.ts               (MODIFIED — also writes chunks to POST_CHUNK_INDEX)
    ai-chat.ts                    (MODIFIED — threshold-gated chunk retrieval)
    ai-reindex.ts                 (NEW — POST /ai/reindex, re-embed-only)
    index.ts                      (MODIFIED — route /ai/reindex)
  wrangler.toml                   (MODIFIED — new POST_CHUNK_INDEX binding)

apps/mobile/lib/features/
  feed/presentation/screens/
    feed_screen.dart              (MODIFIED — _mergeWithSemantic → _hybridRank using RRF)
  post/data/datasources/
    ai_reindex_datasource.dart    (NEW — POST /ai/reindex client)
  post/data/repositories/
    post_repository_impl.dart     (MODIFIED — updatePost triggers reindex)
  post/domain/usecases/
    ask_ai.dart                   (MODIFIED — optional postId on AskAiParams)
  post/data/datasources/
    ask_ai_datasource.dart        (MODIFIED — forward postId to worker)

docs/
  system-overview.md              (MODIFIED — new write/read/edit flow diagrams)
```

---

## Flow 1 — Write (publish a post)

`/ai/summarize` does what it does today, then additionally writes chunks.

### `chunking.ts`

```ts
export function chunkText(text: string): string[]
```

- 800-char windows with 100-char overlap.
- Whitespace-preferring break: when a chunk boundary lands inside a word, walk backwards up to 60 chars to find a whitespace character. Prevents mid-word splits without distorting chunk sizes for whitespace-sparse content (e.g. equations).
- Deterministic: same input → same chunks. (Important for idempotent re-runs.)
- Edge cases: empty / whitespace-only input → `[]`. `chunkText` does NOT know about `CHUNK_THRESHOLD` — it is a pure transformation. The caller decides whether the doc is long enough to warrant chunking.

### Write path in `ai-summarize.ts`

After the existing `indexPostForSearch(env, ...)` call, add a sibling `indexPostChunks(env, { postId, extractedText })`:

```ts
async function indexPostChunks(env, { postId, extractedText }) {
  if (extractedText.length < CHUNK_THRESHOLD) return       // short doc → skip
  const chunks = chunkText(extractedText)
  if (chunks.length === 0) return                          // defensive (whitespace-only)

  const embedResult = await env.AI.run(EMBEDDING_MODEL, { text: chunks })
  const vectors = embedResult.data
  if (!Array.isArray(vectors) || vectors.length !== chunks.length) return

  await env.POST_CHUNK_INDEX.upsert(
    chunks.map((text, i) => ({
      id: `${postId}#${i}`,
      values: vectors[i],
      metadata: { postId, chunkText: text },               // text stored in metadata
    })),
  )
}
```

**Storing chunk text in Vectorize metadata** lets retrieval skip a Firestore round-trip. Vectorize metadata is capped at 10KB/vector; 800-char chunks are well within.

**Failure isolation:** wrapped in try/catch like the existing `indexPostForSearch`. Chunk-write failure logs to `console.error` and does NOT fail the summarize response. The next summarize-retrigger on the same post (e.g. a republish) will reattempt.

### Wrangler binding

`worker/wrangler.toml` gains:

```toml
[[vectorize]]
binding = "POST_CHUNK_INDEX"
index_name = "post-chunks"
```

The Vectorize index is created out-of-band via `wrangler vectorize create post-chunks --dimensions=768 --metric=cosine` and documented in the implementation plan.

---

## Flow 2 — Chat (long doc)

`ai-chat.ts` gets a threshold gate before its existing context-build step.

### Request body addition

```ts
{
  summary?: string
  extractedText?: string
  postId?: string         // NEW — required for chunk retrieval; optional for back-compat
  question: string
  history?: ...
}
```

### Decision logic

```ts
const CHUNK_THRESHOLD = 30000   // same as today's CONTEXT_CHAR_CAP

if (postId && extractedClean.length > CHUNK_THRESHOLD) {
  try {
    const chunks = await retrieveChunks(env, postId, trimmedQuestion, 5)
    if (chunks.length > 0) {
      context = chunks.join('\n\n---\n\n')
    } else {
      context = extractedClean.slice(0, CHUNK_THRESHOLD)   // fall-through
    }
  } catch (e) {
    console.error('retrieveChunks failed', e)
    context = extractedClean.slice(0, CHUNK_THRESHOLD)     // fall-through
  }
} else {
  context = extractedClean || summaryClean                 // existing path
}
```

### `retrieveChunks` in `chunking.ts`

```ts
export async function retrieveChunks(
  env: Env,
  postId: string,
  query: string,
  k: number = 5,
): Promise<string[]> {
  const embedResult = await env.AI.run(EMBEDDING_MODEL, { text: query })
  const vec = embedResult.data?.[0]
  if (!Array.isArray(vec) || vec.length !== 768) return []

  const matches = await env.POST_CHUNK_INDEX.query(vec, {
    topK: k,
    filter: { postId },                                    // scope to this post only
    returnMetadata: true,
  })

  return (matches.matches ?? [])
    .map((m) => (m.metadata?.chunkText as string | undefined) ?? '')
    .filter((t) => t.length > 0)
}
```

### Mobile-side wiring

- `AskAiParams` (Freezed entity in `apps/mobile/lib/features/post/domain/usecases/ask_ai.dart`) gains `String? postId`. Domain layer stays pure Dart — one new optional field.
- `ask_ai_datasource.dart` forwards `postId` in the request body when present.
- `ask_ai_section.dart` (the chat widget) passes the post's `id` through.

---

## Flow 3 — Edit (updatePost)

A new dedicated `/ai/reindex` endpoint re-builds the post-level search blob and re-upserts. **No chunk re-embedding** — `extractedText` does not change on a metadata edit.

### Endpoint contract

```
POST /ai/reindex
Authorization: Bearer <Firebase ID token>
Body:    { postId: string, title: string, description: string }
Returns: 200 { reindexed: true }
         401 unauthorized (bad/missing token)
         403 forbidden    (caller is not the post author)
         404 not_found    (postId does not exist)
         5xx              (embed or upsert failed)
```

### Steps

1. Verify Firebase ID token → decode `uid`.
2. Fetch post doc from Firestore via REST (same pattern as other worker reads).
3. Assert `post.authorId === uid`. Return 403 on mismatch.
4. Build the search blob using the **incoming** title + description (since the Firestore write may not have propagated to the worker's read replica) merged with the persisted `summary`, `aiTags`, `extractedText`.
5. Embed → upsert to `VECTORIZE` (post-level index, same id, overwrites cleanly).

### Mobile trigger

`post_repository_impl.dart updatePost` already takes a `descriptionChanged: bool` flag. We extend the call site:

```dart
// After Firestore confirms the update:
if (titleChanged || descriptionChanged) {
  unawaited(_aiReindexDatasource.call(
    postId: postId,
    title: title,
    description: description,
  ));
}
```

Fire-and-forget. Failure logged via `AppLogger.warn`. No UI surface — search drift is the worst-case, never blocks the edit.

`titleChanged` is computed at the call site by comparing incoming title against the post being edited (`updatePost` currently doesn't take a `titleChanged` flag — we add one, mirroring `descriptionChanged`).

### Auth: token-refresh retry

`ai_reindex_datasource.dart` retries once on a 401, calling `user.getIdToken(true)` to force-refresh before retrying. Second 401 logs and gives up — no retry storm.

---

## Flow 4 — Search ranking (client-side RRF)

Replace `_mergeWithSemantic` in `feed_screen.dart` with `_hybridRank` using Reciprocal Rank Fusion.

### Algorithm

```dart
List<Post> _hybridRank(
  List<Post> keywordResults,
  List<Post> semanticPosts,
  FeedFilterState filter,
) {
  if (_searchQuery.startsWith('#')) return keywordResults;       // tag mode unchanged
  if (_searchQuery.isEmpty) return keywordResults;
  if (semanticPosts.isEmpty) return keywordResults;

  const k = 60;                                                  // standard RRF constant
  final scores = <String, double>{};
  final posts = <String, Post>{};

  for (var i = 0; i < keywordResults.length; i++) {
    final p = keywordResults[i];
    scores[p.id] = (scores[p.id] ?? 0) + 1 / (k + i + 1);
    posts[p.id] = p;
  }
  for (var i = 0; i < semanticPosts.length; i++) {
    final p = semanticPosts[i];
    if (!_matchesTabAndFilter(p, filter)) continue;              // tab/filter gate
    scores[p.id] = (scores[p.id] ?? 0) + 1 / (k + i + 1);
    posts[p.id] = p;
  }

  final ranked = scores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return ranked.take(_hybridResultCap).map((e) => posts[e.key]!).toList();
}
```

### Properties

- A post that hits both lists gets ~2× the score of a single-source post — overlapping matches naturally float.
- A pure vector hit still surfaces, ranked by its semantic strength.
- The existing tab/filter gate (`_matchesTabAndFilter`) still applies, so a NOTES-tab search doesn't surface exercises.
- The 30-result cap (`_hybridResultCap = 30`) is preserved.
- Tag mode (`#foo`) keeps the strict path — vector neighbors of a tag query are usually noise.

### Wrapping in try/catch

The whole blend is wrapped; on any throw we fall back to `keywordResults`. Today's behavior remains the safety net.

---

## Error handling & graceful degradation

| Failure | Behavior | Why |
|---|---|---|
| Chunk embed batch fails during summarize | Log + skip chunk upsert; post-level vector + summary + aiTags still persist | Chat falls back to the slice path on long docs; search/tags unaffected. |
| `POST_CHUNK_INDEX.upsert` fails | Log + continue | Same as above. Next summarize re-trigger retries. |
| `retrieveChunks` fails at chat time | Fall through to `extractedClean.slice(0, CHUNK_THRESHOLD)` | User gets an answer; no error surfaced. |
| `retrieveChunks` returns empty (pre-PR post, no chunks indexed) | Fall through to slice path | Backward compat handled by the same branch. |
| `/ai/reindex` 4xx/5xx | Mobile logs via `AppLogger.warn`, no UI surface | Edit already succeeded in Firestore. |
| `/ai/reindex` 401 (token expired) | Refresh token, retry once; second 401 gives up | Avoids fragile loops on transient token expiry. |
| RRF blend throws | Catch and fall back to `keywordResults` | Today's behavior is the safety net. |
| Semantic search provider in error state | Treated as `semanticPosts = []` (existing) | Keyword path preserved verbatim. |

---

## Testing

### Worker (`worker/test/`)

| Test | Verifies |
|---|---|
| `chunking_test.ts → chunkText` | 800-char windows, 100-char overlap, whitespace-preferring break, deterministic output |
| `chunking_test.ts → chunkText edge cases` | empty → `[]`, whitespace-only → `[]` |
| `ai-summarize_test.ts → indexPostChunks happy path` | long extractedText → N chunks written to `POST_CHUNK_INDEX` with correct id/metadata shape |
| `ai-summarize_test.ts → indexPostChunks skip` | extractedText < CHUNK_THRESHOLD → zero chunk upserts (caller threshold check) |
| `ai-summarize_test.ts → indexPostChunks failure isolation` | mocked chunk upsert throws → summarize still returns `summaryStatus: 'done'` |
| `ai-chat_test.ts → threshold path` | extractedText > 30K + postId → `retrieveChunks` called, context = joined chunks |
| `ai-chat_test.ts → fallthrough path` | extractedText > 30K + retrieveChunks throws → falls back to slice; no 5xx |
| `ai-chat_test.ts → short-doc path` | extractedText < 30K → full text used, no Vectorize call |
| `ai-reindex_test.ts → happy path` | valid token + post owner + body → embed + upsert called once, 200 |
| `ai-reindex_test.ts → authorization` | mismatched uid → 403, no Vectorize calls |
| `ai-reindex_test.ts → bad token` | invalid/missing token → 401 |

### Mobile (`apps/mobile/test/`)

| Test | Verifies |
|---|---|
| `unit/.../ai_reindex_datasource_test.dart` | POST body shape, ID-token header, 200/4xx/5xx handling, 401 → refresh + retry once |
| `unit/.../post_repository_impl_test.dart` (extend existing) | `updatePost` with title or description change → reindex datasource called once; metadata unchanged → not called |
| `unit/.../feed_screen_rrf_test.dart` | RRF math: shared post scores higher than single-source; tab/filter gate applies; tag mode bypasses RRF; empty semantic list returns keyword unchanged |
| `widget/.../feed_screen_test.dart` (extend existing) | Searching surfaces a vector-only result above a tangential keyword-only match when its semantic rank is high enough |

### Manual smoke (documented; not automated)

- Upload a long (~50K char) PDF → chat about content in the tail → expect a sourced answer.
- Edit a post's title → wait ~3 s → semantic-search for the new title's terms → expect the post in results.
- Search a query that overlaps keyword + vector → top result should be the overlapping post.

**Coverage target:** keep total tests ≥ PR #78's 414 baseline; new code paths covered by the named tests above.

---

## Documentation deliverable

Update `docs/system-overview.md` with the new three flows:

- **Write flow** — extend the existing summarize sequence with the chunk-upsert step.
- **Chat flow** — show the threshold gate and the retrieve-vs-slice branch.
- **Edit flow** — new section showing `updatePost` → `/ai/reindex` → Vectorize upsert.

Diagrams stay in the same style as the rest of `system-overview.md`.

---

## Acceptance criteria

- A long-document (> 30 000 chars) chat answer can cite content from the tail of the document. The previously-silent slice is replaced with retrieval.
- Editing a post's title or description causes its semantic-search ranking to reflect the new content within a few seconds (Vectorize upsert latency).
- A query whose terms appear in both a keyword match and a vector match places the overlapping post above either single-source match.
- All existing chat / search / publish flows continue to work unchanged for posts that fit under the chunk threshold or have no edits.
- Total test count ≥ 414; all new code paths have named tests above.
- `docs/system-overview.md` reflects the new flows.

## Open questions

1. **Chunk index name conflict on staging vs prod.** The Vectorize binding `POST_CHUNK_INDEX` needs a real index in both Wrangler environments. Implementation plan should list the exact `wrangler vectorize create` commands and the env-specific names.
2. **Reindex on bulk edit.** If we ever ship a bulk-edit feature, fire-and-forget per-post reindex could storm Vectorize. Out of scope for this PR; flagged for future.
3. **RRF `k` tuning.** `k = 60` is the published default but our keyword + vector list sizes (≤30 each) are smaller than typical IR benchmarks. Worth revisiting once we have usage data; not blocking the ship.
