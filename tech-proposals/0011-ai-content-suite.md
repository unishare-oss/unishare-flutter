---
title: "0011: AI content suite — auto-tags, semantic search, full-RAG chat"
description: "Layer auto-tagging, semantic search, and full-document chat on top of a single cached-extracted-text foundation."
---

# PROP-0011: AI content suite — auto-tags, semantic search, full-RAG chat

**Status:** ACCEPTED
**Author:** Pyae Sone Shin Thant
**Date:** 2026-05-19
**Spec:** (intentionally omitted — implemented directly per author/reviewer agreement)
**Approved by:** Pyae Sone Shin Thant (2026-05-20)

---

## Problem

Three gaps in the current AI surface limit how useful uploaded content is to other students:

1. **Tags are user-typed only.** Posts uploaded with empty `tags` get no auto-classification, so feed filtering and discovery miss them. Two students searching for the same topic with different vocabulary won't find each other's notes.
2. **Chat-with-note is summary-grounded, not RAG.** `ai-chat.ts` sends only the 3-7 bullet summary as context, so questions like "what enzyme is mentioned on page 2" can't be answered. Users perceive the feature as shallow.
3. **No semantic search.** A student searching "Newton's second law examples" only matches posts whose title/tags/description contain those exact words. Notes that cover the topic with different phrasing are invisible.

Image posts (handwritten notes, scans) — first-class today for summary thanks to PROP-0010's vision work — are second-class for every downstream feature because we never extract their text.

## Proposed Solution

Introduce a **shared foundation** of cached extracted text on each post, then layer three features on top.

### Foundation — `extractedText` on post doc

Add an `extractedText: string` field to the Firestore post document, populated during the existing summarize flow:

- **Text path** (PDF/DOCX): already extracted by `text-extractor.ts`. Persist the truncated extraction (currently 6000 chars) to Firestore alongside the summary write.
- **Image path** (PROP-0010): extend the Llama 4 Scout call to return a JSON object with both a `transcribedText` and `summary` field, rather than just a summary string. Persist `transcribedText` to `extractedText`.

Size cap: 60 000 chars (~80 KB), well under Firestore's 1 MB doc limit even with all other post fields. Truncate on overflow with a `extractedTextTruncated: true` flag.

### Feature 1 — Auto-tags

During summarization, return a structured response containing AI-derived classification:

```json
{
  "summary": "...",
  "transcribedText": "...",
  "aiTags": { "subject": "Biology", "level": "undergraduate", "type": "lecture-notes", "topics": ["Krebs cycle", "ATP synthesis", "mitochondria"] }
}
```

`aiTags` lives in its own Firestore field (not merged into user `tags`) so provenance is preserved. UI shows AI tags with a visual distinction (e.g. dimmed background, sparkle icon) and includes both in filter/search indexing.

#### Tag vocabulary control

Without control, the same concept will appear under many surface forms ("Krebs Cycle", "krebs cycle", "TCA cycle", "citric acid cycle"), fragmenting filters and search. Two-stage approach:

1. **Phase A — Whitelist-in-prompt (ships with auto-tags).** Query Firestore for the top 50-100 most-used `aiTags.topics` (cached, refreshed daily via a scheduled worker). Inject into the summarize prompt as "Prefer these tags when applicable; only invent new ones for genuinely new topics: [list]". Cheap, works well, the model naturally gravitates to reuse.

2. **Phase B — Embedding dedup (ships with semantic search).** Once Vectorize is live, embed every distinct AI tag once and persist the embedding alongside the tag. Before persisting a newly-proposed tag, embed it and snap to the nearest existing tag if cosine similarity exceeds a threshold (start at 0.85, tune from there). Re-uses the same embedding infrastructure as semantic search — no new pipeline.

**Cold start:** Bootstrap the vocabulary from real uploads rather than pre-seeding with a curated subject/topic list. Rationale: a pre-seeded list inevitably reflects one author's view of "what subjects exist" and gets stuck; letting real student uploads shape the taxonomy means it self-corrects to what students actually study and call things. The first ~50 posts will have looser tags; that's an acceptable warmup cost.

### Feature 2 — Full-RAG chat

Upgrade `ai-chat.ts` to send `extractedText` instead of (or in addition to) the summary. Backfill strategy for posts created before this proposal: re-extract on first chat request (one-shot cost).

For very long content where `extractedText` plus chat history exceeds the model's effective context budget, chunk + retrieve the top-k chunks by embedding similarity (the same embeddings used by Feature 3 — no second pipeline).

### Feature 3 — Semantic search

- **Embedding model:** Cloudflare Workers AI `@cf/baai/bge-base-en-v1.5` (768-dim, free on Workers).
- **Vector store:** Cloudflare Vectorize, with a `posts` index scoped per `universityId` via metadata filter.
- **Write path:** When `extractedText` is persisted, the worker also generates an embedding and upserts to Vectorize keyed by `postId`.
- **Read path:** New `/ai/search` endpoint accepts `{ query, universityId, limit }`. Embeds the query, runs `topK` on Vectorize, returns post IDs ordered by similarity.
- **UX (hybrid):** Existing search bar stays. Backend blends keyword + vector: keyword matches always shown first; vector matches fill remaining slots up to the limit and rerank empty keyword result sets. Single search experience, no toggle.

### Shipping order

1. **Foundation** — add `extractedText` field + image transcription. No new user-facing feature; unblocks the rest.
2. **Auto-tags** — extend summarize response with `aiTags`. UI displays both tag types. Includes Phase A vocabulary control (daily-cached whitelist of top tags injected into prompt).
3. **Full-RAG chat** — swap `summary` for `extractedText` in `ai-chat.ts`. Chunking deferred until Feature 3's embeddings exist.
4. **Semantic search + tag dedup** — Vectorize index, embedding worker, hybrid search endpoint, mobile search blend. Also enables Phase B tag dedup (embed-and-snap-to-canonical) which reuses the same embedding pipeline.

Each phase is its own tech spec + PR.

## Alternatives Considered

### A — Extracted text in R2 instead of Firestore

Store `extractedText` as `extracted/{postId}.txt` in R2. No size limit, but every chat/search/embed call needs an extra fetch hop, and the post lifecycle no longer atomically owns its derived text. **Rejected:** 60 KB cap covers ~95% of academic uploads; the simpler model wins until we see real overflow.

### B — Merge AI tags into user `tags` field

Cleaner data model but loses provenance — a future moderation decision ("remove auto-generated tag X") becomes impossible because the system doesn't know which tags it owns. **Rejected:** separate field is one extra Firestore property and unlocks future UI affordances (e.g. "let me reject this AI tag").

### C — Semantic search as a separate "Smart search" tab

Easier to ship (no ranking blend), but bifurcates user attention and most users never discover the second tab. **Rejected:** unified search bar with hybrid blend respects existing user habit.

### D — Skip image OCR (images stay summary-only)

Cheaper per-summary call, but contradicts PROP-0010's investment in vision — handwritten notes would be searchable only by their summary bullets. **Rejected:** the use case we built vision for *is* handwritten notes; making them searchable is the payoff.

### E — Pinecone / Supabase pgvector for embeddings

Both work; both add a non-Cloudflare dependency and a paid tier we don't need at this scale. **Rejected:** Vectorize is native to the worker stack, free tier covers planned scale (5M vectors).

## Open Questions

1. **Image transcription accuracy threshold.** Llama 4 Scout will sometimes produce garbled text on cursive handwriting. Do we still persist low-confidence transcriptions (and accept poor downstream search), or gate on a confidence signal (e.g. drop if transcription < N tokens or contains > K consecutive non-alpha runs)?
2. **Embedding re-write triggers.** Embed once on summarize. Do we also re-embed on `post.description` edit, on `aiTags` change, or only on full source-file replacement?
3. **Hybrid search ranking weights.** Concretely: when keyword returns 3 results and vector returns 20, how many vector results fill the page, and what similarity floor cuts off bad matches? Needs an evaluation set.
4. **Vectorize per-university partitioning.** Single index with metadata filter vs one index per university. Filter is simpler; per-uni index has stricter isolation but management overhead.
5. **Cost ceiling.** Free tiers cover dev. At what monthly active user count do we hit paid (Groq paid tier ~$0.05/M tokens for vision, Vectorize paid after 5M vectors, Workers AI free for now)? Worth budgeting before launch.
6. **Backfill for existing posts.** Re-summarize all existing posts to populate `extractedText` + `aiTags` + embedding, or backfill lazily (on next chat/search hit)? Lazy is cheaper; eager makes search complete on day one.
7. **Tag whitelist refresh cadence.** Daily scheduled worker is the proposal default. Alternatives: refresh on tag-change Firestore trigger (always-fresh, more reads), or on cache miss (eventual consistency, simplest). Daily likely fine but worth pinning in the spec.
8. **Tag dedup similarity threshold.** Phase B uses cosine ≥ 0.85 as the "snap to canonical" cutoff. Needs validation against a held-out set of known synonyms (e.g. "Krebs cycle" vs "TCA cycle" — are they 0.85+ apart in BGE space?). The spec should include a small calibration exercise.

## Acceptance Criteria

- A new image or PDF post completes the full pipeline (extract → summarize → tag → embed) in a single worker call, with all derived fields written atomically with the post doc.
- `extractedText` is present on every new post (text or image) and bounded to ≤ 60 000 chars.
- `aiTags` are displayed in the post UI visually distinct from user `tags`, and both contribute to feed filtering.
- AI-generated tags reuse existing canonical tags when applicable: Phase A (whitelist prompt) demonstrates measurable tag reuse on a held-out test set; Phase B (embedding dedup) collapses near-synonyms to a single canonical form above the chosen threshold.
- Chat-with-note answers questions whose answer exists in the document body but not in the summary.
- Semantic search returns relevant posts for queries whose terms don't appear verbatim in any post's title/tags/description.
- Hybrid search blends keyword and vector results in one ranked list, with documented ranking logic.
- Free-tier service limits are respected at the proposal's projected scale (documented in the spec).
- Existing posts continue to function (no breaking schema changes); backfill strategy is documented and reversible.
