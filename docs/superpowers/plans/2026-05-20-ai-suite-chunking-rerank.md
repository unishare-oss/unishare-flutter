# AI Suite — Chunking, Re-embed-on-Edit, RRF Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the three PROP-0011 gaps remaining after PR #78 — long-document chat (chunking + retrieval), search drift on edit (re-embed-on-edit), and naive hybrid ranking (Reciprocal Rank Fusion).

**Architecture:** A shared `embeddings.ts` worker helper centralizes BGE-base embedding calls. A new `chunking.ts` adds pure-function chunking + Vectorize-backed retrieval. A new `/ai/reindex` endpoint re-upserts the post-level vector on metadata edits. Client-side ranking switches to RRF.

**Tech Stack:** Cloudflare Workers (TypeScript), Cloudflare Vectorize (`@cf/baai/bge-base-en-v1.5`, 768-dim), Flutter + Riverpod, Firebase Auth ID tokens.

**Spec:** `docs/superpowers/specs/2026-05-20-ai-suite-chunking-rerank-design.md`

---

## File Structure

### Worker (TypeScript) — `worker/src/`
- **Create** `embeddings.ts` — `embedText(env, input): Promise<number[]>` and `embedTextBatch(env, inputs): Promise<number[][]>`. Single source of truth for BGE calls + 768-dim shape checks.
- **Create** `chunking.ts` — `chunkText(text): string[]` (pure) and `retrieveChunks(env, postId, query, k): Promise<string[]>`.
- **Create** `ai-reindex.ts` — `handleAiReindex(request, env, uid)` for the new POST `/ai/reindex` endpoint.
- **Modify** `ai-summarize.ts` — Replace inline embedding calls with `embeddings.ts` helpers; add `indexPostChunks()` invoked alongside existing `indexPostForSearch()`.
- **Modify** `ai-chat.ts` — Add threshold-gated retrieval path; accept optional `postId` in body.
- **Modify** `ai-search.ts` — Replace inline `env.AI.run` with `embedText()` helper (consistency only; behavior unchanged).
- **Modify** `index.ts` — Route `/ai/reindex` + add `POST_CHUNK_INDEX` to `Env` interface.
- **Modify** `wrangler.toml` — Add `POST_CHUNK_INDEX` Vectorize binding.

### Mobile (Dart) — `apps/mobile/lib/features/post/`
- **Create** `data/datasources/ai_reindex_datasource.dart` — POST `/ai/reindex` client with token-refresh-retry on 401.
- **Modify** `domain/repositories/ask_ai_repository.dart` — Add `postId` param to `ask()`.
- **Modify** `data/repositories/ask_ai_repository_impl.dart` — Forward `postId` to datasource.
- **Modify** `data/datasources/ask_ai_datasource.dart` — Forward `postId` to worker body.
- **Modify** `domain/usecases/ask_ai.dart` — `AskAiUseCase.call` passes `postId` through.
- **Modify** `domain/repositories/post_repository.dart` — Add `bool titleChanged` to `updatePost(...)`.
- **Modify** `data/repositories/post_repository_impl.dart` — Accept `titleChanged`; fire-and-forget reindex when title or description changed.
- **Modify** `presentation/screens/feed_screen.dart` — Replace `_mergeWithSemantic` with `_hybridRank` using RRF.

### Mobile tests — `apps/mobile/test/`
- **Create** `unit/features/post/data/datasources/ai_reindex_datasource_test.dart`
- **Create** `unit/features/feed/presentation/screens/feed_screen_rrf_test.dart`
- **Modify** `unit/features/post/data/repositories/post_repository_impl_test.dart` (extend with reindex-trigger group)

### Docs
- **Modify** `docs/system-overview.md` — Add chunking + reindex flows.

### Out-of-band infra (manual, one-time per environment)
- Vectorize index `unishare-post-chunks` created via `wrangler vectorize create`.

### Out of scope for this plan
- Worker unit-test infrastructure (vitest setup). Worker code verified by TypeScript type-checking and concrete manual smoke commands listed in each task.
- Backfill for pre-PR-#78 posts (separate effort).
- Re-embedding on user-tag changes (user tags don't feed the search blob today).

---

## Task 1 — Create Vectorize chunk index + binding

**Files:**
- Modify: `worker/wrangler.toml`

This is a one-time infra step. The Vectorize index must exist before any worker code that references `POST_CHUNK_INDEX` can be deployed.

- [ ] **Step 1: Create the chunk index in Cloudflare**

Run from repo root:
```bash
cd worker && npx wrangler vectorize create unishare-post-chunks --dimensions=768 --metric=cosine
```
Expected output:
```
✅ Successfully created index 'unishare-post-chunks'
```

If the index already exists (e.g. previously partially deployed), the command errors with `already exists`. That's fine — proceed.

- [ ] **Step 2: Add metadata index on `postId` for filter performance**

```bash
cd worker && npx wrangler vectorize create-metadata-index unishare-post-chunks --property-name=postId --type=string
```
Expected output:
```
✅ Successfully enqueued metadata index creation request
```

This lets `retrieveChunks` filter by `postId` efficiently. Without it, Vectorize falls back to full-index scan.

- [ ] **Step 3: Add the binding to wrangler.toml**

Modify `worker/wrangler.toml`, append after the existing `TAG_INDEX` block:

```toml
# wrangler vectorize create unishare-post-chunks --dimensions=768 --metric=cosine
# wrangler vectorize create-metadata-index unishare-post-chunks --property-name=postId --type=string
# PROP-0011 follow-up — per-post chunk index for RAG chat retrieval on long docs.
[[vectorize]]
binding = "POST_CHUNK_INDEX"
index_name = "unishare-post-chunks"
```

- [ ] **Step 4: Verify config**

Run:
```bash
cd worker && npx wrangler deploy --dry-run
```
Expected: dry-run completes, output lists three Vectorize bindings (`VECTORIZE`, `TAG_INDEX`, `POST_CHUNK_INDEX`).

- [ ] **Step 5: Commit**

```bash
git add worker/wrangler.toml
git commit -m "feat(worker): add POST_CHUNK_INDEX Vectorize binding"
```

---

## Task 2 — Create shared `embeddings.ts` helper

**Files:**
- Create: `worker/src/embeddings.ts`

Centralize the BGE-base call pattern that's currently duplicated across `ai-summarize.ts` (twice — `indexPostForSearch` and `dedupAndInsertTags`) and `ai-search.ts`. Pure helper, no behavior change.

- [ ] **Step 1: Write the file**

Create `worker/src/embeddings.ts`:

```ts
import type { Env } from './index'

export const EMBEDDING_MODEL = '@cf/baai/bge-base-en-v1.5'
export const EMBEDDING_DIM = 768

/// Single embedding for one input string. Throws if the model returns the
/// wrong shape — callers can catch and degrade gracefully.
export async function embedText(env: Env, input: string): Promise<number[]> {
  const result = (await env.AI.run(EMBEDDING_MODEL, { text: input })) as {
    data: number[][]
  }
  const vec = result.data?.[0]
  if (!Array.isArray(vec) || vec.length !== EMBEDDING_DIM) {
    throw new Error(`embed returned wrong shape: ${vec?.length ?? 'null'}`)
  }
  return vec
}

/// Batch embedding for multiple inputs in one model call. BGE accepts a
/// string[] and returns one vector per input — far cheaper than N round
/// trips. Throws when the result shape doesn't match the input length.
export async function embedTextBatch(
  env: Env,
  inputs: string[],
): Promise<number[][]> {
  if (inputs.length === 0) return []
  const result = (await env.AI.run(EMBEDDING_MODEL, { text: inputs })) as {
    data: number[][]
  }
  const vectors = result.data
  if (!Array.isArray(vectors) || vectors.length !== inputs.length) {
    throw new Error(
      `embed batch returned wrong count: expected ${inputs.length}, got ${vectors?.length ?? 'null'}`,
    )
  }
  for (const v of vectors) {
    if (!Array.isArray(v) || v.length !== EMBEDDING_DIM) {
      throw new Error(`embed batch vector wrong shape: ${v?.length ?? 'null'}`)
    }
  }
  return vectors
}
```

- [ ] **Step 2: Verify TypeScript compiles**

```bash
cd worker && npx tsc --noEmit
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add worker/src/embeddings.ts
git commit -m "feat(worker): add shared embeddings helper"
```

---

## Task 3 — Refactor existing embedding call sites to use the helper

**Files:**
- Modify: `worker/src/ai-summarize.ts` (remove local `EMBEDDING_MODEL` const + inline shape checks)
- Modify: `worker/src/ai-search.ts` (same)

No behavior change. Sets up the next task by removing duplication.

- [ ] **Step 1: Modify `ai-summarize.ts`**

At the top of the file, change the imports:
```ts
import { extractText } from './text-extractor'
import { embedText, embedTextBatch } from './embeddings'
```

Delete the local constant near line 277:
```ts
// DELETE THIS LINE:
const EMBEDDING_MODEL = '@cf/baai/bge-base-en-v1.5'
```

In `dedupAndInsertTags` (around line 307), replace:
```ts
const embedResult = (await env.AI.run(EMBEDDING_MODEL, {
  text: proposed,
})) as { data: number[][] }
const embeddings = embedResult.data
if (!Array.isArray(embeddings) || embeddings.length !== proposed.length) {
  return proposed
}
```
with:
```ts
let embeddings: number[][]
try {
  embeddings = await embedTextBatch(env, proposed)
} catch (e) {
  console.error('tag embed batch failed', e)
  return proposed
}
```

The inner `if (!Array.isArray(vec) || vec.length !== 768)` check inside the per-tag loop is now redundant — `embedTextBatch` already validated every vector. Remove that check; assume `vec` is valid.

In `indexPostForSearch` (around line 378), replace:
```ts
const embedResult = (await env.AI.run(EMBEDDING_MODEL, { text })) as {
  data: number[][]
}
const vector = embedResult.data?.[0]
if (!Array.isArray(vector) || vector.length !== 768) {
  throw new Error(`embed returned wrong shape: ${vector?.length ?? 'null'}`)
}
```
with:
```ts
const vector = await embedText(env, text)
```

- [ ] **Step 2: Modify `ai-search.ts`**

Replace the import block:
```ts
import type { Env } from './index'
import { embedText } from './embeddings'
import { json, jsonError } from './response'
```

Delete the local constant:
```ts
// DELETE THIS LINE:
const EMBEDDING_MODEL = '@cf/baai/bge-base-en-v1.5'
```

In `handleAiSearch`, replace the embed block (lines ~34-46):
```ts
let vector: number[]
try {
  const embedResult = (await env.AI.run(EMBEDDING_MODEL, { text: query })) as {
    data: number[][]
  }
  const v = embedResult.data?.[0]
  if (!Array.isArray(v) || v.length !== 768) {
    throw new Error(`embed returned wrong shape: ${v?.length ?? 'null'}`)
  }
  vector = v
} catch (e) {
  console.error('embed query failed', e)
  return jsonError('Embedding failed', 502)
}
```
with:
```ts
let vector: number[]
try {
  vector = await embedText(env, query)
} catch (e) {
  console.error('embed query failed', e)
  return jsonError('Embedding failed', 502)
}
```

- [ ] **Step 3: Verify TypeScript compiles**

```bash
cd worker && npx tsc --noEmit
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add worker/src/ai-summarize.ts worker/src/ai-search.ts
git commit -m "refactor(worker): use shared embeddings helper across ai-summarize and ai-search"
```

---

## Task 4 — Create `chunking.ts` with `chunkText`

**Files:**
- Create: `worker/src/chunking.ts`

Pure-function chunking with whitespace-preferring break. No Workers AI / Vectorize dependency at this stage — keep it pure so it's trivially testable.

- [ ] **Step 1: Write the file**

Create `worker/src/chunking.ts`:

```ts
import type { Env } from './index'
import { embedText } from './embeddings'

/// Target chunk size in characters. BGE-base-en-v1.5 truncates inputs at
/// ~2000 chars (512 tokens), so 800 stays well clear of the truncation line
/// while still giving each chunk 1-2 paragraphs of coherent context.
export const CHUNK_SIZE = 800

/// Overlap between consecutive chunks. 100 / 800 = 12.5% — enough to
/// preserve sentences that straddle a chunk boundary.
export const CHUNK_OVERLAP = 100

/// Max distance to walk back from the target boundary in search of
/// whitespace. Prevents distorting chunk sizes when the doc has long
/// whitespace-sparse runs (e.g. equations, code).
export const BOUNDARY_BACKTRACK = 60

/// Min text length below which we don't chunk at all. Aligned with the
/// chat handler's CONTEXT_CHAR_CAP so docs that fit whole in the chat
/// context don't pay for chunking infrastructure.
export const CHUNK_THRESHOLD = 30_000

/// Splits text into ~CHUNK_SIZE windows with CHUNK_OVERLAP characters
/// of overlap. Walks each boundary back up to BOUNDARY_BACKTRACK chars
/// to land on a whitespace character when one is nearby.
/// Pure function: same input → same output.
export function chunkText(text: string): string[] {
  const trimmed = text.trim()
  if (trimmed.length === 0) return []
  if (trimmed.length <= CHUNK_SIZE) return [trimmed]

  const chunks: string[] = []
  let start = 0

  while (start < trimmed.length) {
    const targetEnd = Math.min(start + CHUNK_SIZE, trimmed.length)
    let end = targetEnd

    // If we're not at the document end, prefer whitespace within ±backtrack.
    if (end < trimmed.length) {
      const backtrackLimit = Math.max(start + 1, end - BOUNDARY_BACKTRACK)
      for (let i = end; i > backtrackLimit; i--) {
        if (/\s/.test(trimmed[i - 1])) {
          end = i
          break
        }
      }
    }

    const chunk = trimmed.slice(start, end).trim()
    if (chunk.length > 0) chunks.push(chunk)

    if (end >= trimmed.length) break

    const nextStart = end - CHUNK_OVERLAP
    // Defensive: if overlap would push us backward (chunk too small),
    // advance by at least 1 to guarantee termination.
    start = nextStart > start ? nextStart : start + 1
  }

  return chunks
}
```

- [ ] **Step 2: Verify TypeScript compiles**

```bash
cd worker && npx tsc --noEmit
```
Expected: no errors.

- [ ] **Step 3: Smoke-check chunkText with a tsx one-off**

Create a temporary verification file inside the worker dir so relative imports resolve:

```bash
cat > worker/verify-chunk.ts << 'EOF'
import { chunkText } from './src/chunking'

console.log('empty:', JSON.stringify(chunkText('')))
console.log('short:', JSON.stringify(chunkText('hello world')))
const long = 'word '.repeat(2000)  // ~10 000 chars
const out = chunkText(long)
console.log(`long: ${out.length} chunks, first chunk size: ${out[0]?.length}`)
EOF
cd worker && npx -y tsx verify-chunk.ts && rm verify-chunk.ts
```

Expected output (approximately):
```
empty: []
short: ["hello world"]
long: 14 chunks, first chunk size: 800
```

The `long:` line should show 13-15 chunks (10 000 chars / (800-100 stride) ≈ 14) and a first-chunk size at or just below 800. If chunk count is 0, 1, or exceeds 20, the loop math is wrong — debug before proceeding. Always `rm` the verification file even if the run failed (don't commit it).

- [ ] **Step 4: Commit**

```bash
git add worker/src/chunking.ts
git commit -m "feat(worker): add chunkText pure-function chunker"
```

---

## Task 5 — Add `retrieveChunks` to `chunking.ts`

**Files:**
- Modify: `worker/src/chunking.ts`

The read side of chunking — embeds a query, queries the chunk index filtered by `postId`, returns top-k chunk texts.

- [ ] **Step 1: Append to `chunking.ts`**

After the `chunkText` function, add:

```ts
/// Retrieves the top-k most-relevant chunks for a given query, scoped to a
/// single post. Returns the chunk texts (read from Vectorize metadata,
/// not Firestore — saves a round-trip). Returns [] on any failure; callers
/// should fall back to the slice path.
export async function retrieveChunks(
  env: Env,
  postId: string,
  query: string,
  k: number = 5,
): Promise<string[]> {
  let vec: number[]
  try {
    vec = await embedText(env, query)
  } catch (e) {
    console.error('retrieveChunks: embed failed', e)
    return []
  }

  let matches: VectorizeMatches
  try {
    matches = await env.POST_CHUNK_INDEX.query(vec, {
      topK: k,
      filter: { postId },
      returnMetadata: 'all',
    })
  } catch (e) {
    console.error('retrieveChunks: vectorize query failed', e)
    return []
  }

  return (matches.matches ?? [])
    .map((m) => {
      const text = m.metadata?.chunkText
      return typeof text === 'string' ? text : ''
    })
    .filter((t) => t.length > 0)
}
```

- [ ] **Step 2: Verify TypeScript compiles**

```bash
cd worker && npx tsc --noEmit
```
Expected: a single error about `POST_CHUNK_INDEX` not existing on `Env`. We add it in Task 7. Skip ahead.

Actually, **resolve the type error inline now** by adding `POST_CHUNK_INDEX` to `Env` in `index.ts`. Edit `worker/src/index.ts`, in the `Env` interface, after the `TAG_INDEX` line, add:

```ts
  // PROP-0011 follow-up — per-post chunk index for RAG chat retrieval on long docs.
  POST_CHUNK_INDEX: VectorizeIndex;
```

Then rerun:
```bash
cd worker && npx tsc --noEmit
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add worker/src/chunking.ts worker/src/index.ts
git commit -m "feat(worker): add retrieveChunks + POST_CHUNK_INDEX type"
```

---

## Task 6 — Wire chunk writes into `ai-summarize.ts`

**Files:**
- Modify: `worker/src/ai-summarize.ts`

After the existing `indexPostForSearch` call, add a sibling chunk write.

- [ ] **Step 1: Add the import**

At the top of `ai-summarize.ts`, alongside the existing `embeddings` import:
```ts
import { embedText, embedTextBatch } from './embeddings'
import { chunkText, CHUNK_THRESHOLD } from './chunking'
```

- [ ] **Step 2: Add `indexPostChunks` function**

After `indexPostForSearch` (around line 365 after Task 3's refactor), add:

```ts
/// PROP-0011 follow-up — per-chunk vectors for RAG chat on long documents.
/// Skips short docs (those that fit in the chat handler's context budget).
/// Failure is logged and swallowed: the summarize response still succeeds
/// without chunks; chat will fall back to the slice path.
async function indexPostChunks(
  env: Env,
  params: { postId: string; extractedText: string },
): Promise<void> {
  if (params.extractedText.length < CHUNK_THRESHOLD) return

  const chunks = chunkText(params.extractedText)
  if (chunks.length === 0) return

  let vectors: number[][]
  try {
    vectors = await embedTextBatch(env, chunks)
  } catch (e) {
    console.error('indexPostChunks: embed batch failed', e)
    return
  }

  try {
    await env.POST_CHUNK_INDEX.upsert(
      chunks.map((text, i) => ({
        id: `${params.postId}#${i}`,
        values: vectors[i],
        metadata: { postId: params.postId, chunkText: text },
      })),
    )
  } catch (e) {
    console.error('indexPostChunks: upsert failed', e)
  }
}
```

- [ ] **Step 3: Call it from `handleAiSummarize`**

Find the existing block (around line 249 after Task 3's refactor):
```ts
if (postId) {
  try {
    await indexPostForSearch(env, {
      postId,
      title,
      summary: result.summary,
      aiTags: canonicalTags,
      extractedText: result.extractedText,
    })
  } catch (e) {
    console.error('vectorize upsert failed', e)
  }
}
```

Add a sibling chunk-write after it:
```ts
if (postId) {
  try {
    await indexPostForSearch(env, {
      postId,
      title,
      summary: result.summary,
      aiTags: canonicalTags,
      extractedText: result.extractedText,
    })
  } catch (e) {
    console.error('vectorize upsert failed', e)
  }

  // Best-effort chunk indexing for RAG chat on long docs (PROP-0011 follow-up).
  // Wrapped separately so a chunk-pipeline failure can't reach back and
  // un-do the post-level index above.
  try {
    await indexPostChunks(env, {
      postId,
      extractedText: result.extractedText,
    })
  } catch (e) {
    console.error('chunk upsert failed', e)
  }
}
```

- [ ] **Step 4: Verify TypeScript compiles**

```bash
cd worker && npx tsc --noEmit
```
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add worker/src/ai-summarize.ts
git commit -m "feat(worker): write per-post chunks to Vectorize on summarize"
```

---

## Task 7 — Add threshold-gated retrieval to `ai-chat.ts`

**Files:**
- Modify: `worker/src/ai-chat.ts`

Accept optional `postId` in body; when present and the doc exceeds threshold, retrieve top-5 chunks. Otherwise behave exactly as today.

- [ ] **Step 1: Add the import**

At the top of `ai-chat.ts`:
```ts
import { retrieveChunks } from './chunking'
import { CHUNK_THRESHOLD } from './chunking'
```

Or combined:
```ts
import { retrieveChunks, CHUNK_THRESHOLD } from './chunking'
```

- [ ] **Step 2: Add `postId` to the request type**

Replace the body type declaration:
```ts
let body: {
  summary?: string
  extractedText?: string
  postId?: string
  question: string
  history?: Array<{ role: 'user' | 'assistant'; content: string }>
}
```

And the destructure:
```ts
const { summary, extractedText, postId, question, history = [] } = body
```

- [ ] **Step 3: Replace the context-build block**

Find:
```ts
const summaryClean =
  typeof summary === 'string' && summary.trim() ? summary.trim() : ''
const extractedClean =
  typeof extractedText === 'string' && extractedText.trim()
    ? extractedText.trim().slice(0, CONTEXT_CHAR_CAP)
    : ''
const context = extractedClean || summaryClean
if (!context) return jsonError('summary or extractedText required', 400)
```

Replace with:
```ts
const summaryClean =
  typeof summary === 'string' && summary.trim() ? summary.trim() : ''
const extractedRaw =
  typeof extractedText === 'string' && extractedText.trim()
    ? extractedText.trim()
    : ''
const postIdClean = typeof postId === 'string' && postId.length > 0 ? postId : ''

let context: string
if (extractedRaw.length > CHUNK_THRESHOLD && postIdClean) {
  const trimmedQ = typeof question === 'string' ? question.trim() : ''
  const chunks = await retrieveChunks(env, postIdClean, trimmedQ, 5)
  if (chunks.length > 0) {
    context = chunks.join('\n\n---\n\n')
  } else {
    // Retrieval returned nothing (either failed or no chunks indexed —
    // common for pre-PROP-0011-followup posts). Fall back to the slice path.
    context = extractedRaw.slice(0, CONTEXT_CHAR_CAP)
  }
} else if (extractedRaw.length > 0) {
  context = extractedRaw.slice(0, CONTEXT_CHAR_CAP)
} else {
  context = summaryClean
}
if (!context) return jsonError('summary or extractedText required', 400)
```

Note: the slice path uses `CONTEXT_CHAR_CAP` (unchanged from current behavior). Only the gate condition uses `CHUNK_THRESHOLD`. Today both are 30 000 — the constants live in different files because they govern different concerns and may diverge later.

- [ ] **Step 4: Verify TypeScript compiles**

```bash
cd worker && npx tsc --noEmit
```
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add worker/src/ai-chat.ts
git commit -m "feat(worker): threshold-gated chunk retrieval in ai-chat"
```

---

## Task 8 — Create `/ai/reindex` endpoint

**Files:**
- Create: `worker/src/ai-reindex.ts`
- Modify: `worker/src/index.ts`

A dedicated endpoint for re-upserting the post-level vector after a metadata edit. Requires Firebase ID token + author ownership.

- [ ] **Step 1: Create the handler**

Create `worker/src/ai-reindex.ts`:

```ts
import type { Env } from './index'
import { embedText } from './embeddings'
import { json, jsonError } from './response'

const MAX_TITLE_LEN = 200
const MAX_DESCRIPTION_LEN = 5000
/// Mirrors ai-summarize.ts SEARCH_BLOB_CHAR_CAP; the search blob fed to the
/// embedding model is bounded by BGE's 512-token truncation.
const SEARCH_BLOB_CHAR_CAP = 2000

interface ReindexBody {
  postId: string
  title: string
  description: string
}

/// PROP-0011 follow-up — POST /ai/reindex.
/// Re-builds the post-level search blob from the incoming title/description
/// (Firestore replica may not have propagated yet) merged with persisted
/// summary + aiTags + extractedText, then upserts the post-level vector.
/// Chunks are NOT touched; extractedText doesn't change on a metadata edit.
export async function handleAiReindex(
  request: Request,
  env: Env,
  uid: string,
): Promise<Response> {
  let body: Partial<ReindexBody>
  try {
    body = (await request.json()) as Partial<ReindexBody>
  } catch {
    return jsonError('Invalid JSON body', 400)
  }

  const postId = typeof body.postId === 'string' ? body.postId.trim() : ''
  const title = typeof body.title === 'string' ? body.title.trim() : ''
  const description =
    typeof body.description === 'string' ? body.description.trim() : ''

  if (!postId) return jsonError('postId required', 400)
  if (title.length === 0 || title.length > MAX_TITLE_LEN) {
    return jsonError(`title required and ≤ ${MAX_TITLE_LEN} chars`, 400)
  }
  if (description.length > MAX_DESCRIPTION_LEN) {
    return jsonError(`description must be ≤ ${MAX_DESCRIPTION_LEN} chars`, 400)
  }

  // Fetch the post doc to confirm ownership + read persisted fields.
  // Worker uses Firestore REST (no Admin SDK in the runtime).
  const docUrl = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/posts/${encodeURIComponent(postId)}`
  let docRes: Response
  try {
    docRes = await fetch(docUrl)
  } catch (e) {
    console.error('reindex: firestore fetch failed', e)
    return jsonError('Failed to read post', 502)
  }
  if (docRes.status === 404) return jsonError('Post not found', 404)
  if (!docRes.ok) return jsonError('Failed to read post', 502)

  const doc = (await docRes.json()) as {
    fields?: Record<string, { stringValue?: string; arrayValue?: { values?: { stringValue?: string }[] } }>
  }
  const fields = doc.fields ?? {}
  const authorId = fields.authorId?.stringValue ?? ''
  if (authorId !== uid) return jsonError('Forbidden', 403)

  const summary = fields.summary?.stringValue ?? ''
  const extractedText = fields.extractedText?.stringValue ?? ''
  const aiTagsRaw = fields.aiTags?.arrayValue?.values ?? []
  const aiTags = aiTagsRaw
    .map((v) => v.stringValue)
    .filter((s): s is string => typeof s === 'string' && s.length > 0)

  // Rebuild the search blob — same composition as ai-summarize.ts buildSearchBlob.
  const parts: string[] = []
  if (title) parts.push(title)
  if (summary) parts.push(summary)
  if (description) parts.push(description)
  if (aiTags.length > 0) parts.push(aiTags.join(' '))
  if (extractedText) parts.push(extractedText.slice(0, 1500))
  const blob = parts.join('\n\n').slice(0, SEARCH_BLOB_CHAR_CAP)
  if (!blob.trim()) return jsonError('Nothing to index', 400)

  let vector: number[]
  try {
    vector = await embedText(env, blob)
  } catch (e) {
    console.error('reindex: embed failed', e)
    return jsonError('Embedding failed', 502)
  }

  try {
    await env.VECTORIZE.upsert([{ id: postId, values: vector }])
  } catch (e) {
    console.error('reindex: upsert failed', e)
    return jsonError('Upsert failed', 502)
  }

  return json({ reindexed: true })
}
```

Note on the search-blob composition: the spec calls for using *incoming* title/description (since the Firestore write may not have propagated). The persisted `summary`, `aiTags`, `extractedText` are read from the doc. `description` is added to the blob here even though `buildSearchBlob` in `ai-summarize.ts` doesn't include it today — that's intentional, because on a fresh post the worker doesn't have user-typed description yet (it's only set by the mobile client post-summary), but on a re-index it's the whole point of the operation.

- [ ] **Step 2: Register the route in `index.ts`**

Modify `worker/src/index.ts`. Add the import at the top:
```ts
import { handleAiReindex } from './ai-reindex';
```

Add the route, after the existing `/ai/search` block:
```ts
if (request.method === 'POST' && url.pathname === '/ai/reindex') {
  const uid = await requireAuth(request, env);
  if (uid instanceof Response) return uid;
  return handleAiReindex(request, env, uid);
}
```

Note that `requireAuth` returns the uid on success and a Response on failure; we now thread that uid into `handleAiReindex`. The other handlers don't need the uid because they don't enforce per-post ownership.

- [ ] **Step 3: Verify TypeScript compiles**

```bash
cd worker && npx tsc --noEmit
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add worker/src/ai-reindex.ts worker/src/index.ts
git commit -m "feat(worker): add /ai/reindex endpoint for re-embed on metadata edits"
```

---

## Task 9 — Deploy worker and smoke-test

**Files:** none modified.

Verify the worker changes end-to-end against a real Cloudflare deployment before touching the mobile side.

- [ ] **Step 1: Deploy**

```bash
cd worker && npx wrangler deploy
```
Expected: deployment completes, output shows the new routes registered and three Vectorize bindings.

- [ ] **Step 2: Get a fresh Firebase ID token for testing**

In a Chrome devtools console on a logged-in instance of the app (or via the existing test harness), run:
```js
await firebase.auth().currentUser.getIdToken(true)
```
Copy the token. Save as `$TOKEN` in your shell:
```bash
export TOKEN='<paste>'
export WORKER='https://<your-worker-domain>'
```

- [ ] **Step 3: Smoke-test `/ai/reindex` with a post you own**

Pick a postId you own. Run:
```bash
curl -X POST "$WORKER/ai/reindex" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"postId":"<YOUR_POST_ID>","title":"Updated title for smoke test","description":"Updated description for smoke test"}'
```
Expected: HTTP 200, body `{"reindexed":true}`.

- [ ] **Step 4: Smoke-test `/ai/reindex` 403**

Pick a postId you do NOT own. Same curl, different postId. Expected: HTTP 403, body `{"error":"Forbidden"}`.

- [ ] **Step 5: Smoke-test `/ai/reindex` 404**

```bash
curl -X POST "$WORKER/ai/reindex" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"postId":"definitely-not-a-real-post-id","title":"x","description":""}'
```
Expected: HTTP 404, body `{"error":"Post not found"}`.

- [ ] **Step 6: Smoke-test chunk write on a long post**

Re-trigger summarize on a long post (you can do this by editing the post in-app to force a re-summarize, or by directly calling the worker). After summarize succeeds, verify chunks were written:
```bash
cd worker && npx wrangler vectorize get-by-ids unishare-post-chunks --ids='<YOUR_POST_ID>#0,<YOUR_POST_ID>#1,<YOUR_POST_ID>#2'
```
Expected: at least 3 vectors returned, each with `metadata.postId == <YOUR_POST_ID>` and `metadata.chunkText` containing a substring of the post's `extractedText`.

If chunks are missing: check worker logs (`npx wrangler tail`) for `indexPostChunks` errors during the most recent summarize call.

- [ ] **Step 7: Smoke-test chat retrieval on a long post**

```bash
curl -X POST "$WORKER/ai/chat" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"postId":"<LONG_POST_ID>","extractedText":"<long text, can be the actual >30k value, but a synthetic 31000-char string works>","question":"What is in this document?"}'
```
Expected: streaming response that doesn't error. Tail `npx wrangler tail` in another terminal — look for the chunk-retrieval path (no error about Vectorize, no embed failure).

- [ ] **Step 8: Commit any worker-side fixes uncovered by smoke**

If everything passed, no commit needed. If smoke uncovered issues, fix them in the relevant task's file and commit.

---

## Task 10 — Pipe `postId` through the mobile AskAi chain (TDD)

**Files:**
- Modify: `apps/mobile/lib/features/post/domain/repositories/ask_ai_repository.dart`
- Modify: `apps/mobile/lib/features/post/data/repositories/ask_ai_repository_impl.dart`
- Modify: `apps/mobile/lib/features/post/data/datasources/ask_ai_datasource.dart`
- Modify: `apps/mobile/lib/features/post/domain/usecases/ask_ai.dart`

`AskAiParams.postId` already exists but is never forwarded to the worker. Plumb it through.

- [ ] **Step 1: Update `AskAiRepository` interface**

Modify `apps/mobile/lib/features/post/domain/repositories/ask_ai_repository.dart`:

```dart
import 'package:unishare_mobile/features/post/domain/entities/ai_message.dart';

abstract class AskAiRepository {
  Stream<AiMessage> ask({
    required String postId,
    required String summary,
    required List<AiMessage> history,
    required String question,
    String? extractedText,
  });
}

class AskAiException implements Exception {
  const AskAiException(this.message);
  final String message;
  @override
  String toString() => 'AskAiException: $message';
}
```

- [ ] **Step 2: Update `AskAiRepositoryImpl`**

Modify `apps/mobile/lib/features/post/data/repositories/ask_ai_repository_impl.dart`. Change the `ask` signature and forward `postId`:

```dart
@override
Stream<AiMessage> ask({
  required String postId,
  required String summary,
  required List<AiMessage> history,
  required String question,
  String? extractedText,
}) async* {
  // ... existing serialized history logic ...

  try {
    String accumulated = '';

    await for (final event in _datasource.stream(
      postId: postId,
      summary: summary,
      extractedText: extractedText,
      question: question,
      history: serialized,
    )) {
      // ... existing event handling ...
    }
  } catch (e) {
    if (e is AskAiException) rethrow;
    throw AskAiException(e.toString());
  }
}
```

- [ ] **Step 3: Update `AskAiDatasource.stream`**

Modify `apps/mobile/lib/features/post/data/datasources/ask_ai_datasource.dart`:

```dart
Stream<Map<String, dynamic>> stream({
  required String postId,
  required String summary,
  required String question,
  required List<Map<String, String>> history,
  String? extractedText,
}) async* {
  final token = await FirebaseAuth.instance.currentUser?.getIdToken();
  if (token == null) throw Exception('not_authenticated');

  final request = http.Request('POST', Uri.parse('$_workerBaseUrl/ai/chat'))
    ..headers['Content-Type'] = 'application/json'
    ..headers['Authorization'] = 'Bearer $token'
    ..body = jsonEncode({
      'postId': postId,
      'summary': summary,
      if (extractedText != null && extractedText.isNotEmpty)
        'extractedText': extractedText,
      'question': question,
      'history': history,
    });

  // ... rest unchanged ...
}
```

- [ ] **Step 4: Update `AskAiUseCase` to forward `postId`**

Modify `apps/mobile/lib/features/post/domain/usecases/ask_ai.dart`:

```dart
class AskAiUseCase {
  const AskAiUseCase(this._repository);

  final AskAiRepository _repository;

  Stream<AiMessage> call(AskAiParams params) => _repository.ask(
    postId: params.postId,
    summary: params.summary,
    extractedText: params.extractedText,
    history: params.history,
    question: params.question,
  );
}
```

- [ ] **Step 5: Run analyze + test to confirm no regressions**

```bash
cd apps/mobile && flutter analyze && flutter test
```
Expected: 0 issues from analyze. All existing tests pass (≥ 414).

If any existing tests fail (likely a `ask_ai_*_test.dart` or `ask_ai_section_test.dart` that constructs the params directly), update them to pass `postId` — keep the fix minimal (no other test changes).

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/post/domain/repositories/ask_ai_repository.dart \
        apps/mobile/lib/features/post/data/repositories/ask_ai_repository_impl.dart \
        apps/mobile/lib/features/post/data/datasources/ask_ai_datasource.dart \
        apps/mobile/lib/features/post/domain/usecases/ask_ai.dart \
        apps/mobile/test/  # only paths the analyzer touched, listed by `git status`
git commit -m "feat(mobile): forward postId from AskAi chain to worker"
```

---

## Task 11 — Create `AiReindexDatasource` (TDD)

**Files:**
- Create: `apps/mobile/lib/features/post/data/datasources/ai_reindex_datasource.dart`
- Create: `apps/mobile/test/unit/features/post/data/datasources/ai_reindex_datasource_test.dart`

POST `/ai/reindex` client with token-refresh-retry on 401.

- [ ] **Step 1: Write the failing test**

Create `apps/mobile/test/unit/features/post/data/datasources/ai_reindex_datasource_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unishare_mobile/features/post/data/datasources/ai_reindex_datasource.dart';

void main() {
  group('AiReindexDatasource', () {
    test('POSTs postId, title, description with bearer token', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req as http.Request;
        return http.Response(jsonEncode({'reindexed': true}), 200);
      });
      final ds = AiReindexDatasource(
        client: client,
        tokenProvider: ({bool forceRefresh = false}) async => 'fake-token',
      );

      final result = await ds.call(
        postId: 'p1',
        title: 'New title',
        description: 'New description',
      );

      expect(result, isTrue);
      expect(captured.method, 'POST');
      expect(captured.url.path, endsWith('/ai/reindex'));
      expect(captured.headers['Authorization'], 'Bearer fake-token');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['postId'], 'p1');
      expect(body['title'], 'New title');
      expect(body['description'], 'New description');
    });

    test('returns false on 4xx without retrying', () async {
      var callCount = 0;
      final client = MockClient((req) async {
        callCount++;
        return http.Response('{"error":"Forbidden"}', 403);
      });
      final ds = AiReindexDatasource(
        client: client,
        tokenProvider: ({bool forceRefresh = false}) async => 'fake-token',
      );

      final result = await ds.call(
        postId: 'p1',
        title: 't',
        description: 'd',
      );

      expect(result, isFalse);
      expect(callCount, 1);
    });

    test('retries once on 401 after forcing token refresh', () async {
      var callCount = 0;
      var refreshCount = 0;
      final client = MockClient((req) async {
        callCount++;
        final auth = req.headers['Authorization'];
        if (auth == 'Bearer stale-token') {
          return http.Response('{"error":"Unauthorized"}', 401);
        }
        return http.Response('{"reindexed":true}', 200);
      });
      final ds = AiReindexDatasource(
        client: client,
        tokenProvider: ({bool forceRefresh = false}) async {
          if (forceRefresh) {
            refreshCount++;
            return 'fresh-token';
          }
          return 'stale-token';
        },
      );

      final result = await ds.call(
        postId: 'p1',
        title: 't',
        description: 'd',
      );

      expect(result, isTrue);
      expect(callCount, 2);
      expect(refreshCount, 1);
    });

    test('gives up after a second 401', () async {
      var callCount = 0;
      final client = MockClient((req) async {
        callCount++;
        return http.Response('{"error":"Unauthorized"}', 401);
      });
      final ds = AiReindexDatasource(
        client: client,
        tokenProvider: ({bool forceRefresh = false}) async =>
            forceRefresh ? 'fresh-token' : 'stale-token',
      );

      final result = await ds.call(
        postId: 'p1',
        title: 't',
        description: 'd',
      );

      expect(result, isFalse);
      expect(callCount, 2); // initial + 1 retry, no further attempts
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd apps/mobile && flutter test test/unit/features/post/data/datasources/ai_reindex_datasource_test.dart
```
Expected: FAIL with "Error when reading 'lib/features/post/data/datasources/ai_reindex_datasource.dart': ...No such file..."

- [ ] **Step 3: Write the implementation**

Create `apps/mobile/lib/features/post/data/datasources/ai_reindex_datasource.dart`:

```dart
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

typedef TokenProvider = Future<String?> Function({bool forceRefresh});

const _workerBaseUrl = String.fromEnvironment('WORKER_URL');

/// POST /ai/reindex — re-upserts the post's search-blob embedding to
/// Vectorize after a title or description edit. Fire-and-forget from the
/// caller's perspective: a 4xx/5xx returns `false` and the caller logs it;
/// the edit itself already succeeded in Firestore so we never block the UI.
///
/// On 401, we force-refresh the ID token and retry exactly once. Two
/// consecutive 401s mean a real auth problem — give up.
class AiReindexDatasource {
  AiReindexDatasource({http.Client? client, TokenProvider? tokenProvider})
    : _client = client ?? http.Client(),
      _tokenProvider = tokenProvider ?? _defaultTokenProvider;

  final http.Client _client;
  final TokenProvider _tokenProvider;

  static Future<String?> _defaultTokenProvider({bool forceRefresh = false}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Future.value(null);
    return user.getIdToken(forceRefresh);
  }

  Future<bool> call({
    required String postId,
    required String title,
    required String description,
  }) async {
    final token = await _tokenProvider();
    if (token == null) return false;

    final body = jsonEncode({
      'postId': postId,
      'title': title,
      'description': description,
    });

    var response = await _post(token, body);
    if (response.statusCode == 401) {
      final fresh = await _tokenProvider(forceRefresh: true);
      if (fresh == null) return false;
      response = await _post(fresh, body);
    }
    return response.statusCode == 200;
  }

  Future<http.Response> _post(String token, String body) => _client.post(
    Uri.parse('$_workerBaseUrl/ai/reindex'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: body,
  );
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd apps/mobile && flutter test test/unit/features/post/data/datasources/ai_reindex_datasource_test.dart
```
Expected: PASS (4/4).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/post/data/datasources/ai_reindex_datasource.dart \
        apps/mobile/test/unit/features/post/data/datasources/ai_reindex_datasource_test.dart
git commit -m "feat(mobile): add AiReindexDatasource for POST /ai/reindex"
```

---

## Task 12 — Add `titleChanged` flag and reindex trigger in `PostRepository.updatePost` (TDD)

**Files:**
- Modify: `apps/mobile/lib/features/post/domain/repositories/post_repository.dart`
- Modify: `apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart`
- Modify: `apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart`

The interface gains `titleChanged`. The impl, after a successful Firestore update, fires the reindex datasource if title or description changed.

- [ ] **Step 1: Write the failing tests (extend existing test file)**

Open `apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart`. Add a new group at the bottom (inside `void main()`):

```dart
group('updatePost reindex trigger', () {
  test('calls reindex datasource once when title changed', () async {
    final mockReindex = _MockReindexDatasource();
    final mockFirestore = _MockFirestoreDatasource(); // existing test fixture
    final repo = PostRepositoryImpl(
      firestoreDatasource: mockFirestore,
      storageDatasource: _MockStorageDatasource(),
      draftBox: await _openDraftBox(),
      feedCache: FeedCache(),
      aiReindexDatasource: mockReindex,
    );

    await repo.updatePost(
      postId: 'p1',
      title: 'New title',
      description: 'unchanged description',
      tags: const [],
      moduleNumber: '1',
      descriptionChanged: false,
      titleChanged: true,
      currentSummaryStatus: null,
    );

    // Reindex is fire-and-forget; pump the microtask queue.
    await Future<void>.delayed(Duration.zero);

    expect(mockReindex.calls, hasLength(1));
    expect(mockReindex.calls.single.postId, 'p1');
    expect(mockReindex.calls.single.title, 'New title');
  });

  test('calls reindex datasource once when description changed', () async {
    final mockReindex = _MockReindexDatasource();
    final repo = PostRepositoryImpl(
      firestoreDatasource: _MockFirestoreDatasource(),
      storageDatasource: _MockStorageDatasource(),
      draftBox: await _openDraftBox(),
      feedCache: FeedCache(),
      aiReindexDatasource: mockReindex,
    );

    await repo.updatePost(
      postId: 'p1',
      title: 'unchanged title',
      description: 'New description',
      tags: const [],
      moduleNumber: '1',
      descriptionChanged: true,
      titleChanged: false,
      currentSummaryStatus: null,
    );

    await Future<void>.delayed(Duration.zero);
    expect(mockReindex.calls, hasLength(1));
  });

  test('does not call reindex when neither title nor description changed', () async {
    final mockReindex = _MockReindexDatasource();
    final repo = PostRepositoryImpl(
      firestoreDatasource: _MockFirestoreDatasource(),
      storageDatasource: _MockStorageDatasource(),
      draftBox: await _openDraftBox(),
      feedCache: FeedCache(),
      aiReindexDatasource: mockReindex,
    );

    await repo.updatePost(
      postId: 'p1',
      title: 'same',
      description: 'same',
      tags: const [],
      moduleNumber: '1',
      descriptionChanged: false,
      titleChanged: false,
      currentSummaryStatus: null,
    );

    await Future<void>.delayed(Duration.zero);
    expect(mockReindex.calls, isEmpty);
  });

  test('swallows reindex failure without rethrowing', () async {
    final failingReindex = _MockReindexDatasource(shouldFail: true);
    final repo = PostRepositoryImpl(
      firestoreDatasource: _MockFirestoreDatasource(),
      storageDatasource: _MockStorageDatasource(),
      draftBox: await _openDraftBox(),
      feedCache: FeedCache(),
      aiReindexDatasource: failingReindex,
    );

    await expectLater(
      repo.updatePost(
        postId: 'p1',
        title: 'New',
        description: 'd',
        tags: const [],
        moduleNumber: '1',
        descriptionChanged: false,
        titleChanged: true,
        currentSummaryStatus: null,
      ),
      completes,
    );
  });
});
```

Add the mock at the bottom of the test file (alongside whatever other mocks the existing test uses):

```dart
class _MockReindexDatasource implements AiReindexDatasource {
  _MockReindexDatasource({this.shouldFail = false});

  final bool shouldFail;
  final List<({String postId, String title, String description})> calls = [];

  @override
  Future<bool> call({
    required String postId,
    required String title,
    required String description,
  }) async {
    calls.add((postId: postId, title: title, description: description));
    if (shouldFail) throw Exception('reindex failed');
    return true;
  }

  // Inherit any other AiReindexDatasource members via noSuchMethod or stub.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
```

Add the import at the top:
```dart
import 'package:unishare_mobile/features/post/data/datasources/ai_reindex_datasource.dart';
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd apps/mobile && flutter test test/unit/features/post/data/repositories/post_repository_impl_test.dart
```
Expected: FAIL — `PostRepositoryImpl` doesn't accept `aiReindexDatasource` and `updatePost` doesn't accept `titleChanged`.

- [ ] **Step 3: Update the interface**

Modify `apps/mobile/lib/features/post/domain/repositories/post_repository.dart`. Change `updatePost`:

```dart
Future<void> updatePost({
  required String postId,
  required String title,
  required String description,
  required List<String> tags,
  String? externalUrl,
  required String moduleNumber,
  required bool descriptionChanged,
  required bool titleChanged,
  required SummaryStatus? currentSummaryStatus,
});
```

- [ ] **Step 4: Update the impl**

Modify `apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart`. Add the import:
```dart
import 'package:unishare_mobile/features/post/data/datasources/ai_reindex_datasource.dart';
import 'package:unishare_mobile/core/logging/app_logger.dart';
```

Add an optional constructor param + field:
```dart
class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl({
    required this.firestoreDatasource,
    required this.storageDatasource,
    required this.draftBox,
    required this.feedCache,
    this.cacheTtl = const Duration(minutes: 5),
    AiSummarizeDatasource? aiSummarizeDatasource,
    TagWhitelistService? tagWhitelistService,
    AiReindexDatasource? aiReindexDatasource,
  })  : _aiSummarizeDatasource =
            aiSummarizeDatasource ?? AiSummarizeDatasource(),
        _tagWhitelistService = tagWhitelistService,
        _aiReindexDatasource = aiReindexDatasource ?? AiReindexDatasource();

  // ... existing fields ...
  final AiReindexDatasource _aiReindexDatasource;
  // ... ...
}
```

Replace the existing `updatePost` impl:
```dart
@override
Future<void> updatePost({
  required String postId,
  required String title,
  required String description,
  required List<String> tags,
  String? externalUrl,
  required String moduleNumber,
  required bool descriptionChanged,
  required bool titleChanged,
  required SummaryStatus? currentSummaryStatus,
}) async {
  await firestoreDatasource.updatePost(
    postId: postId,
    title: title,
    description: description,
    tags: tags,
    externalUrl: externalUrl,
    moduleNumber: moduleNumber,
    descriptionChanged: descriptionChanged,
    currentSummaryStatus: currentSummaryStatus,
  );

  // PROP-0011 follow-up — fire-and-forget reindex when fields that feed the
  // semantic-search blob have changed. Failure is logged; the edit already
  // succeeded in Firestore so we never block the UI on a search-drift issue.
  if (titleChanged || descriptionChanged) {
    unawaited(
      _aiReindexDatasource
          .call(postId: postId, title: title, description: description)
          .catchError((Object e, StackTrace st) {
        // Non-fatal: edit already succeeded in Firestore; search-drift is
        // the only cost. AppLogger.error records to Crashlytics (non-fatal)
        // in release builds.
        AppLogger.error('reindex_failed: postId=$postId', error: e, stackTrace: st);
        return false;
      }),
    );
  }
}
```

Add the `unawaited` import if not already present:
```dart
import 'dart:async';   // for unawaited
```

- [ ] **Step 5: Update every existing call site of `updatePost`**

Find call sites:
```bash
cd apps/mobile && grep -rn 'updatePost(' lib test | grep -v '^lib/features/post/data/repositories/post_repository_impl.dart' | grep -v '^lib/features/post/domain/repositories/post_repository.dart'
```

For each call site, add `titleChanged: <expression>` where `<expression>` mirrors how `descriptionChanged` is currently computed at that site (compare incoming title to the post being edited). If there's no edit-post UI yet for title, default to `false`.

Likely call sites (verify with grep): the edit-post screen / its controller. Typical pattern:
```dart
await repo.updatePost(
  postId: post.id,
  title: newTitle,
  description: newDescription,
  // ... existing args ...
  descriptionChanged: newDescription != post.description,
  titleChanged: newTitle != post.title,   // NEW
  currentSummaryStatus: post.summaryStatus,
);
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
cd apps/mobile && flutter analyze && flutter test test/unit/features/post/data/repositories/post_repository_impl_test.dart
```
Expected: 0 analyze issues, PASS on all tests in that file (existing groups + new `updatePost reindex trigger` group).

If analyze flags missed call sites, fix them per Step 5.

- [ ] **Step 7: Run full mobile test suite to confirm no regressions**

```bash
cd apps/mobile && flutter test
```
Expected: all tests pass (≥ 414 + the 4 new ones).

- [ ] **Step 8: Commit**

```bash
git add apps/mobile/lib/features/post/domain/repositories/post_repository.dart \
        apps/mobile/lib/features/post/data/repositories/post_repository_impl.dart \
        apps/mobile/test/unit/features/post/data/repositories/post_repository_impl_test.dart \
        $(git status --porcelain | grep '^ M' | awk '{print $2}' | grep '\.dart$')
git commit -m "feat(mobile): trigger /ai/reindex on title or description edit"
```

(The `git status` line above grabs any edit-post call site files updated in Step 5.)

---

## Task 13 — Replace `_mergeWithSemantic` with RRF (`_hybridRank`) (TDD)

**Files:**
- Create: `apps/mobile/test/unit/features/feed/presentation/screens/feed_screen_rrf_test.dart`
- Modify: `apps/mobile/lib/features/feed/presentation/screens/feed_screen.dart`

The RRF blend is pure logic — extract it to a top-level function for testability, then call it from `_FeedScreenState.build`.

- [ ] **Step 1: Write the failing test**

Create `apps/mobile/test/unit/features/feed/presentation/screens/feed_screen_rrf_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:unishare_mobile/features/feed/presentation/screens/feed_screen.dart';
import 'package:unishare_mobile/features/post/domain/entities/post.dart';

Post _post(String id, {String title = '', PostType type = PostType.lectureNote}) {
  return Post(
    id: id,
    title: title,
    description: '',
    authorId: 'a',
    authorName: '',
    authorAvatar: '',
    createdAt: DateTime(2026, 1, 1),
    tags: const [],
    mediaUrls: const [],
    mediaTypes: const [],
    universityId: 'u',
    departmentId: 'd',
    courseId: 'c',
    year: 1,
    moduleNumber: '1',
    postType: type,
  );
}

void main() {
  group('hybridRankRRF', () {
    test('shared posts outrank single-source posts', () {
      final keyword = [_post('A'), _post('B')];
      final semantic = [_post('A'), _post('C')];
      final ranked = hybridRankRRF(keyword, semantic);
      // A appears in both → highest score, should be first.
      expect(ranked.first.id, 'A');
      expect(ranked.map((p) => p.id).toList(), containsAllInOrder(['A']));
      expect(ranked.length, 3);
    });

    test('empty semantic returns keyword list unchanged', () {
      final keyword = [_post('A'), _post('B'), _post('C')];
      final ranked = hybridRankRRF(keyword, const []);
      expect(ranked.map((p) => p.id).toList(), ['A', 'B', 'C']);
    });

    test('empty keyword returns semantic in order', () {
      final semantic = [_post('X'), _post('Y')];
      final ranked = hybridRankRRF(const [], semantic);
      expect(ranked.map((p) => p.id).toList(), ['X', 'Y']);
    });

    test('respects per-source rank — earlier rank scores higher', () {
      // A is first in keyword, last in semantic.
      // B is last in keyword, first in semantic.
      // Both appear in both. A's and B's scores tie (symmetric), so the test
      // just confirms both come before C (which is keyword-only at rank 2).
      final keyword = [_post('A'), _post('C'), _post('B')];
      final semantic = [_post('B'), _post('A')];
      final ranked = hybridRankRRF(keyword, semantic);
      final ids = ranked.map((p) => p.id).toList();
      // C is single-source mid-rank; A and B are dual-source.
      expect(ids.indexOf('C'), greaterThan(ids.indexOf('A')));
      expect(ids.indexOf('C'), greaterThan(ids.indexOf('B')));
    });

    test('caps result list at the provided cap', () {
      final keyword = List.generate(20, (i) => _post('k$i'));
      final semantic = List.generate(20, (i) => _post('s$i'));
      final ranked = hybridRankRRF(keyword, semantic, cap: 5);
      expect(ranked.length, 5);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd apps/mobile && flutter test test/unit/features/feed/presentation/screens/feed_screen_rrf_test.dart
```
Expected: FAIL — `hybridRankRRF` is undefined.

- [ ] **Step 3: Extract `hybridRankRRF` as a top-level function in `feed_screen.dart`**

Modify `apps/mobile/lib/features/feed/presentation/screens/feed_screen.dart`. Above the `class FeedScreen` declaration (after the `_kTabLabels` constant), add:

```dart
/// Reciprocal Rank Fusion blend of two ranked Post lists. A post that appears
/// in both lists gets the sum of `1 / (k + rank)` from each, naturally
/// floating dual-matched posts to the top. `k = 60` is the published default
/// from Cormack et al. — large enough that rank differences smooth out,
/// small enough that top-ranked items still dominate.
///
/// Pure function; no Riverpod / Flutter dependencies — exported for unit
/// testing. Callers apply tab/filter gating BEFORE calling this (so excluded
/// posts don't get votes in either list).
List<Post> hybridRankRRF(
  List<Post> keywordResults,
  List<Post> semanticPosts, {
  int cap = 30,
  int k = 60,
}) {
  if (semanticPosts.isEmpty) {
    return keywordResults.length <= cap
        ? keywordResults
        : keywordResults.take(cap).toList();
  }
  if (keywordResults.isEmpty) {
    return semanticPosts.length <= cap
        ? semanticPosts
        : semanticPosts.take(cap).toList();
  }

  final scores = <String, double>{};
  final posts = <String, Post>{};
  for (var i = 0; i < keywordResults.length; i++) {
    final p = keywordResults[i];
    scores[p.id] = (scores[p.id] ?? 0) + 1 / (k + i + 1);
    posts[p.id] = p;
  }
  for (var i = 0; i < semanticPosts.length; i++) {
    final p = semanticPosts[i];
    scores[p.id] = (scores[p.id] ?? 0) + 1 / (k + i + 1);
    posts[p.id] = p;
  }
  final ranked = scores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return ranked.take(cap).map((e) => posts[e.key]!).toList();
}
```

The import `Post` is already present at the top of `feed_screen.dart`.

- [ ] **Step 4: Replace `_mergeWithSemantic` with a wrapper that calls `hybridRankRRF`**

Inside `_FeedScreenState`, replace `_mergeWithSemantic` with `_hybridRank`:

```dart
/// Blended hybrid ranking: gate semantic results by tab/filter first
/// (so a NOTES-tab search doesn't surface exercises), then RRF-merge with
/// keyword results. Tag-mode (`#foo`) bypasses semantic entirely.
List<Post> _hybridRank(
  List<Post> keywordResults,
  List<Post> semanticPosts,
  FeedFilterState filter,
) {
  if (_searchQuery.startsWith('#')) return keywordResults;
  if (_searchQuery.isEmpty) return keywordResults;
  if (semanticPosts.isEmpty) return keywordResults;

  final gatedSemantic = semanticPosts
      .where((p) => _matchesTabAndFilter(p, filter))
      .toList(growable: false);
  if (gatedSemantic.isEmpty) return keywordResults;

  try {
    return hybridRankRRF(keywordResults, gatedSemantic, cap: _hybridResultCap);
  } catch (e) {
    // Defensive fallback — never block the feed on a rank-blend bug.
    return keywordResults;
  }
}
```

- [ ] **Step 5: Update the build method to call `_hybridRank`**

In the `build` method, find the call:
```dart
final posts = _mergeWithSemantic(
  keywordResults,
  semanticResults,
  filter,
);
```
Replace with:
```dart
final posts = _hybridRank(
  keywordResults,
  semanticResults,
  filter,
);
```

Delete the old `_mergeWithSemantic` method entirely (the lines 132-153 in the current file).

- [ ] **Step 6: Run tests**

```bash
cd apps/mobile && flutter test test/unit/features/feed/presentation/screens/feed_screen_rrf_test.dart
```
Expected: PASS (5/5).

```bash
cd apps/mobile && flutter analyze && flutter test
```
Expected: 0 analyze issues; all tests pass.

- [ ] **Step 7: Commit**

```bash
git add apps/mobile/lib/features/feed/presentation/screens/feed_screen.dart \
        apps/mobile/test/unit/features/feed/presentation/screens/feed_screen_rrf_test.dart
git commit -m "feat(mobile): RRF hybrid ranking in feed search"
```

---

## Task 14 — Update `docs/system-overview.md`

**Files:**
- Modify: `docs/system-overview.md`

Document the three new flows alongside the existing AI suite description added in PR #78.

- [ ] **Step 1: Read the existing file**

```bash
cd /Users/psst/Desktop/projects/unishare-flutter && head -100 docs/system-overview.md
```
Locate the section added in PR #78 about the AI suite. Find a suitable place to extend it (likely a "Write path" / "Read path" section).

- [ ] **Step 2: Append a new section after the existing AI suite content**

Open `docs/system-overview.md` and add:

````markdown
## AI suite — chunking, re-embed-on-edit, RRF (May 2026)

PR #78 shipped the AI suite foundation: cached `extractedText`, auto-tags, full-RAG chat, semantic search. The follow-up plan closed three gaps:

### Long-document chat — chunking + retrieval

```
publish post
   ↓
/ai/summarize (worker)
   ├─ summarize + auto-tag (unchanged)
   ├─ index post-level vector → unishare-posts          [search]
   └─ if extractedText > 30 000 chars:
        chunk into 800-char windows (100-char overlap)
        embed batch (BGE-base, 768 dim)
        upsert chunks → unishare-post-chunks            [RAG retrieval]
            id     = {postId}#{idx}
            meta   = { postId, chunkText }
```

When the chat handler sees a post with `extractedText > 30 000 chars` and the request includes `postId`, it embeds the user's question, queries `unishare-post-chunks` filtered by `postId` (top-5), joins the chunk texts with `\n---\n` separators, and uses *that* as the system-prompt context. Shorter docs continue to send the full text inline. Retrieval failures (no chunks, query error) fall back to the legacy slice path so chat never breaks.

### Re-embed on edit — `/ai/reindex`

`updatePost` (mobile, `post_repository_impl.dart`) fires `POST /ai/reindex` after Firestore confirms the write, whenever title or description changed:

```
edit title or description
   ↓
Firestore updatePost (mobile)
   ↓
unawaited fire-and-forget:
   POST /ai/reindex { postId, title, description }
   ↓
worker verifies Firebase ID token + post.authorId == uid
   ↓
worker rebuilds search blob:
   incoming title + persisted summary + incoming description
   + aiTags + first 1500 chars of extractedText
   ↓
embed → upsert to unishare-posts (same id, overwrites)
```

Chunks are NOT touched — `extractedText` doesn't change on a metadata edit.

### Hybrid search ranking — Reciprocal Rank Fusion

Client-side. `feed_screen.dart` computes a keyword-result list (existing in-memory filter) and a semantic-result list (from `/ai/search`), then blends them with RRF:

```
score(post) = Σ over each source S where post appears:
                  1 / (k + rank_S(post))
k = 60 (Cormack default)
```

Posts that appear in both lists naturally outrank single-source posts. Tag-mode (`#foo`) bypasses RRF and uses strict tag matching only.
````

Match the heading depth and prose tone of the existing file — adjust as needed when you see the actual context.

- [ ] **Step 3: Commit**

```bash
git add docs/system-overview.md
git commit -m "docs(system-overview): describe chunking, reindex, and RRF flows"
```

---

## Task 15 — Full integration sweep

**Files:** none modified.

Final end-to-end verification across mobile + worker.

- [ ] **Step 1: Run the full mobile test suite**

```bash
cd apps/mobile && flutter analyze && flutter test
```
Expected: 0 analyze issues; test count ≥ 414 + 9 new tests (= 423 minimum). All pass.

- [ ] **Step 2: Build the worker dry-run once more**

```bash
cd worker && npx tsc --noEmit && npx wrangler deploy --dry-run
```
Expected: clean.

- [ ] **Step 3: Manual smoke — long-doc chat**

1. Upload a PDF whose `extractedText` will exceed 30 000 chars (a textbook chapter or long lecture notes).
2. Wait for summarize to complete.
3. Verify chunks exist:
   ```bash
   cd worker && npx wrangler vectorize get-by-ids unishare-post-chunks --ids='<postId>#0,<postId>#5'
   ```
   Expected: two non-empty vectors with `metadata.chunkText` populated.
4. In the app, ask a chat question whose answer lives in the *tail* of the document (past the 30 000-char mark). Expected: the model answers using content the legacy slice would have dropped.

- [ ] **Step 4: Manual smoke — reindex on title edit**

1. Edit a post's title to something distinctive (e.g. include an unusual word like "platypus").
2. Wait ~3 seconds.
3. Open the feed search and type the distinctive word.
4. Expected: the edited post appears in results.

- [ ] **Step 5: Manual smoke — RRF blend**

1. Pick a post whose title contains keyword "X" and whose content semantically relates to a different word "Y".
2. Search for "X Y" (both words).
3. Expected: that post is in the top results.
4. Search for "Y" alone (no keyword match in title/desc).
5. Expected: the post still appears via semantic match.

- [ ] **Step 6: Push the branch and open PR**

```bash
git push -u origin feature/ai-suite-chunking-rerank
gh pr create --title "feat(ai): chunking, re-embed-on-edit, RRF hybrid ranking" --body "$(cat <<'EOF'
## Summary
Closes the three PROP-0011 gaps remaining after #78:
- **Long-document chat** — chunk extractedText into 800-char windows, write to new `unishare-post-chunks` Vectorize index at summarize time, retrieve top-5 chunks at chat time when the doc exceeds 30 000 chars.
- **Re-embed on edit** — new `POST /ai/reindex` worker endpoint; mobile fires it (fire-and-forget) when title or description changes.
- **Hybrid search ranking** — replace the dumb append-after-keyword merge in `feed_screen.dart` with Reciprocal Rank Fusion (k=60).

Spec: `docs/superpowers/specs/2026-05-20-ai-suite-chunking-rerank-design.md`
Plan: `docs/superpowers/plans/2026-05-20-ai-suite-chunking-rerank.md`

## Test plan
- [x] `flutter analyze` clean
- [x] `flutter test` — total ≥ 423 (was 414)
- [x] Worker `tsc --noEmit` clean
- [x] Manual: long-doc chat answers from the tail
- [x] Manual: edited post surfaces in semantic search within ~3s
- [x] Manual: dual-match posts top RRF results

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review checklist

Run through these before marking the plan complete:

1. **Spec coverage** — every spec section maps to a task:
   - Flow 1 (Write / chunking) → Tasks 4, 5, 6
   - Flow 2 (Chat threshold gate) → Task 7
   - Flow 3 (Reindex endpoint) → Task 8
   - Flow 4 (RRF) → Task 13
   - Mobile postId plumbing → Task 10
   - Reindex datasource + trigger → Tasks 11, 12
   - Shared embeddings helper → Tasks 2, 3
   - Wrangler binding + index creation → Task 1
   - Docs (`system-overview.md`) → Task 14
   - Tests per spec testing section → Tasks 11, 12, 13
   - Manual smoke per spec → Tasks 9, 15

2. **Placeholder scan** — no TBDs, no "implement later," no "add appropriate error handling." Every code block is concrete.

3. **Type consistency** — `AskAiRepository.ask({postId, ...})` matches `AskAiRepositoryImpl.ask({postId, ...})` matches `AskAiDatasource.stream({postId, ...})`. `PostRepository.updatePost(titleChanged: bool)` matches the impl. `AiReindexDatasource.call(postId, title, description)` matches both production and mock. `hybridRankRRF` exported top-level with the same signature in test and impl. `POST_CHUNK_INDEX` referenced in `chunking.ts` and `Env` interface in `index.ts`. `CHUNK_THRESHOLD` exported from `chunking.ts` and consumed in both `ai-summarize.ts` (Task 6) and `ai-chat.ts` (Task 7).

4. **Task ordering** — worker tasks 1-9 don't depend on mobile changes; mobile tasks 10-13 don't depend on each other but each builds on the previous (postId plumbing → reindex datasource → repository trigger → RRF). Docs task 14 can land any time. Integration sweep task 15 is the gate.
