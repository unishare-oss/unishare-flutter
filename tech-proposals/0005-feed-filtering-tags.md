---
title: "0005: Feed Filtering by Tags"
description: "Proposal for server-side tag filtering on the post feed using Firestore array-contains-any queries, with Hive offline cache support."
---

# PROP-0005: Feed Filtering by Tags

**Status:** APPROVED  
**Author:** Sudakarn  
**Date:** 2026-05-05  
**Spec:** [SPEC-0005](../tech-specs/0005-feed-filtering-tags.md)  
**Approved by:** Sudakarn

---

## Problem

Every authenticated student currently sees the entire global `posts` feed, ordered by recency, regardless of their university, department, or enrolled subjects. A student enrolled in three subjects — say, Computer Networks, Database Systems, and Software Engineering — still scrolls through posts tagged for Accounting, Biology, and every other discipline on the platform. As the content volume grows, the signal-to-noise ratio collapses.

Concrete impact today:

- A student following 3 subjects sees 100% of posts from all departments. If 30 departments each contribute equal volume, only ~10% of the feed is relevant.
- There is no way to surface "posts for my courses only," forcing students to abandon the feed entirely or rely on word-of-mouth sharing.
- Without relevance filtering, the feed's value proposition — peer content discovery — erodes at exactly the moment it becomes most needed (mid-semester, when content volume peaks).

The `posts/{postId}` schema already carries a `tags: string[]` field (established in PROP-0003). New posts written via the PROP-0004 write path populate `tags` at creation time. This means server-side filtering can be implemented without touching any existing document — no backfill is required for posts written after PROP-0004 shipped. Posts predating PROP-0004 with empty `tags` arrays will simply not appear in filtered results, which is the correct behavior (unclassified content should not pollute a subject-filtered view).

---

## Goals

1. A student can select one or more tags (e.g., subject codes or department slugs) and receive only posts matching at least one of those tags — filtered server-side, not in memory.
2. Filtered results support the same cursor-based pagination as the unfiltered feed (PROP-0003) — no regression in scroll behavior.
3. The last-applied filter set persists across app restarts (stored locally) so the student does not re-select tags on every session.
4. The filtered feed's first page is available offline via the existing Hive cache layer without requiring a live Firestore connection.
5. The solution stays within the Firestore free tier: no reads beyond what pagination already performs, no Cloud Functions, no third-party search services.

---

## Non-goals

- Free-text search within post bodies or titles — this requires a dedicated search index and is a separate proposal.
- Paid or external search services (Algolia, Typesense, Elastic, or equivalents).
- Back-filling `tags` on posts that predate PROP-0004 — existing untagged posts are intentionally excluded from filtered results.
- AI-based or collaborative-filtering recommendation systems.
- Tag management or curation (creating, renaming, or deleting canonical tags) — that is an admin feature outside this scope.
- Filtering by criteria other than tags (e.g., date range, author, media type).

---

## Options

### Option A — Firestore `array-contains-any` Query on `tags` Field (Recommended)

Firestore supports the `array-contains-any` operator, which returns documents where the `tags` array contains at least one value from a provided list (up to 30 values per query). When the user selects a filter set, the repository swaps the unfiltered feed query for a filtered one:

```
posts
  .where('tags', arrayContainsAny: selectedTags)
  .orderBy('createdAt', descending: true)
  .limit(pageSize)
```

A composite Firestore index on `(tags array-contains, createdAt desc)` is required and can be declared in `firestore.indexes.json` — it is free to create and free to query within the existing free tier read quota. No new collections, no writes beyond what already occurs.

The domain layer `PostRepository` interface gains a single optional parameter:

```
getPostFeed({int page, int pageSize, List<String> tagFilter})
```

When `tagFilter` is empty, the existing unfiltered query runs. When non-empty, the filtered query runs. The presentation layer passes the current filter selection from a Riverpod provider holding the user's preferences. Filter preferences are persisted in Hive under a well-known key so they survive app restarts.

For offline support, the first page of the filtered feed is cached to Hive the same way the unfiltered feed is cached today. On reconnect, the cache is refreshed.

**Pros:**
- Zero schema migration — exploits the `tags` field that already exists on new posts.
- Native Firestore operator — no extra infrastructure, no new collections, no Cloud Functions.
- Pagination and cursor logic from PROP-0003 are reused unchanged; only the query predicate changes.
- Composite index is declared in source control (`firestore.indexes.json`) and deployed with `firebase deploy --only firestore:indexes`.
- Stays entirely within the free tier: one composite index, same read count per page as today.
- The 30-value limit on `array-contains-any` is generous for a subject/department tag list.

**Cons:**
- Firestore does not allow `array-contains-any` combined with a second `array-contains` or `array-contains-any` clause in the same query — so filtering on two independent tag dimensions simultaneously (e.g., department AND subject type) would require a client-side merge of two queries. For v1, single-dimension filtering is sufficient.
- If a user selects more than 30 tags, the query must be split into batches and the results client-merged. This is unlikely in practice (students follow a small number of subjects) but must be handled gracefully.
- Unindexed `tags` values on old posts (pre-PROP-0004) mean those posts are invisible in filtered results. This is acceptable per the Non-goals but must be communicated to users.

**Effort:** S

---

### Option B — Fan-out Writes to Per-Tag Sub-Collections

At post creation time, the write path (PROP-0004) additionally writes a reference document into one or more `tags/{tagId}/posts/{postId}` sub-collections. The feed for a given tag is then a simple ordered query on that sub-collection:

```
tags/{tagId}/posts
  .orderBy('createdAt', descending: true)
  .limit(pageSize)
```

Multi-tag queries merge the results of multiple sub-collection queries client-side, de-duplicate by `postId`, and re-sort by `createdAt`.

**Pros:**
- Per-tag queries are simple ordered reads with no composite index.
- Sub-collection isolation means reads for one tag do not touch documents from unrelated tags.
- Scales to arbitrarily large tag populations without the 30-value operator limit.

**Cons:**
- Every post write fans out to N sub-collection writes (one per tag). A post with 5 tags costs 6 Firestore writes instead of 1, which is significant at free-tier write limits.
- Multi-tag "OR" queries require parallel sub-collection reads followed by client-side merge-sort — added latency and complexity that Option A avoids entirely.
- Pagination across merged results is non-trivial: cursor positions differ per sub-collection, requiring per-collection cursors to be tracked and reconciled.
- Post deletion or update must fan-out to all sub-collection references — a partial failure leaves stale references that show deleted posts.
- Requires schema changes to the write path (PROP-0004) that has already shipped; the fan-out logic must be added retroactively.

**Effort:** L

---

### Option C — Composite Index on a Flat `primaryTag` Field

Rather than `array-contains-any` on the full `tags` array, require each post to declare exactly one `primaryTag` (e.g., the first element of `tags`). A simple `==` equality filter on `primaryTag` combined with `orderBy('createdAt', desc)` uses a standard composite index. Multi-tag "OR" is handled by issuing one query per selected tag in parallel and merging results client-side.

**Pros:**
- `==` + `orderBy` composite indexes are simpler than array-contains indexes.
- Each per-tag query is independent and unambiguous; no operator limitations.

**Cons:**
- Requires adding a `primaryTag` field to the schema — a migration is needed for all existing posts, which is explicitly ruled out by the project constraints.
- Forces a single canonical tag per post, discarding the multi-tag richness already in the `tags` array.
- Parallel queries per selected tag multiply read costs and merge complexity in exactly the same way as Option B.

**Effort:** M (but immediately disqualified by the schema migration constraint)

---

### Rejected Approaches

**External search services (Algolia, Typesense, Meilisearch):** Ruled out explicitly by the product owner. These services require paid plans beyond trivial data volumes, add a sync pipeline from Firestore, and introduce operational dependencies outside the Firebase-native stack.

**Client-side filtering (download all, filter in memory):** Ruled out explicitly. Downloading the entire `posts` collection to filter in the client does not scale beyond a few hundred posts, wastes bandwidth, and violates the free-tier read constraint. It also makes offline support impossible without caching the entire corpus.

**Schema migration / backfill:** Ruled out explicitly. Any approach requiring `tags` to be retroactively written to pre-PROP-0004 posts is out of scope.

---

## Recommendation

**Chosen option:** Option A — Firestore `array-contains-any` Query on `tags` Field.

Option A is the only approach that satisfies all three hard constraints simultaneously: it requires no schema migration (the `tags` field already exists), it is free-tier compatible (one composite index, same read budget as today), and it supports offline via the Hive cache layer without additional infrastructure. Option B achieves similar query simplicity at the cost of multiplied write operations and a substantially more complex pagination model; that complexity is not justified when `array-contains-any` already handles the multi-tag OR case natively. Option C is immediately disqualified by the migration constraint. The 30-tag operator limit is not a practical concern for the student use case (typical subject selection is 3–8 tags), and the single-dimension filtering limitation is an acceptable v1 constraint.

---

## Open Questions

1. **Tag taxonomy ownership** — Who defines the canonical set of tags students can select? If tags are free-form strings entered by post authors, the filter UI cannot enumerate them reliably; if they are drawn from a curated reference collection (e.g., `universities/{uniId}/courses/{courseId}`), the UI can present a structured picker. Which model is authoritative? This must be decided before the spec defines the filter UI component and the tag validation in the write path.

2. **Filter persistence scope** — Should the selected filter set be per-device (Hive, local only) or per-account (synced to a `users/{uid}/preferences` Firestore document so the same filter applies when the student switches devices)? Per-account sync adds a Firestore read/write on login but provides a consistent experience across devices; per-device is simpler but forces re-selection on each new install.

3. **Empty-result UX contract** — When a student's selected tags return zero posts (e.g., a newly created course tag with no content yet), what does the feed show? An empty state with a prompt to broaden the filter, or a fallback to the unfiltered feed? This decision affects the repository interface (should it return an empty list or fall back transparently?) and must be resolved before the spec defines the use case behavior.

4. **Tag count ceiling** — The `array-contains-any` operator accepts up to 30 values. If a student can theoretically select more than 30 tags, the repository must split the query into batches and merge results. Should the UI enforce a maximum (e.g., 10 selected tags) to avoid this complexity, or should the data layer handle batching transparently? The spec must define which layer owns this constraint.

---

## Acceptance Criteria

- Selecting one or more tags in the filter UI causes the feed to show only posts whose `tags` array contains at least one of the selected values, with filtering applied server-side (verified by confirming the Firestore query predicate, not just the rendered list).
- Filtered feed pagination works correctly: scrolling to the end of the list fetches the next page of filtered results without duplicates or gaps, using the same cursor mechanism as the unfiltered feed.
- The selected filter set survives app restart — reopening the app presents the feed already filtered to the previously selected tags without requiring re-selection.
- When no filter is selected (empty tag set), the feed behaves identically to the existing unfiltered feed from PROP-0003 — no regression in behavior or performance.
- The first page of the filtered feed is available in offline mode (Hive cache) when the device has no connectivity, with a visible indicator distinguishing cached from live results.

---

## References

- PROP-0003: Post Feed — `tech-proposals/0003-post-feed.md` (defines the `posts/{postId}` schema and pagination model this proposal extends)
- PROP-0004: Post Integration — `tech-proposals/0004-post-integration.md` (defines the write path that populates `tags` on new posts)
- Firestore query limitations: [https://firebase.google.com/docs/firestore/query-data/queries#query_limitations](https://firebase.google.com/docs/firestore/query-data/queries#query_limitations)
