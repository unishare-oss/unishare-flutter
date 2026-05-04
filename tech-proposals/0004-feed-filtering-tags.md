---
id: PROP-0004
title: "Feed Filtering & Tags"
status: DRAFT
author: architect
date: 2026-05-03
---

# PROP-0004: Feed Filtering & Tags

**Status:** DRAFT | **Author:** architect | **Date:** 2026-05-03

---

## Problem

Students currently see a single reverse-chronological feed with no way to narrow it to specific courses, post types (notes, exercises, past exams), or tags. The base feed defined in PROP-0003 renders all posts in `posts/{postId}` ordered by `createdAt` descending and exposes no filtering surface at any layer — domain, data, or presentation. As content volume grows, relevance degrades: a student looking for CS101 notes must scroll past unrelated posts from other courses and post types to find what they need. There is also no mechanism to restore a previously chosen filter when the user navigates away and returns to the feed, so every navigation cycle resets context and increases friction.

---

## Goals

- Filter the feed by one or more course tags (e.g. "CS101", "Calculus") using the existing `tags: string[]` field on each post document — no schema migration required.
- Filter the feed by post type using the `PostType` enum already defined on the `Post` entity (`note`, `exercise`, `pastExam`).
- Combine tag and type filters with AND semantics: active tag filter AND active type filter must both match.
- Cursor-based pagination continues to work correctly under any combination of active filters, consistent with the PROP-0003 pagination contract.
- Filter state is preserved in Riverpod provider state so navigating to a post detail and returning to the feed restores the previously selected filter without a refetch from scratch.

---

## Non-goals

- Full-text keyword search — reserved for a future Algolia or Typesense layer per PROP-0003 Alternatives section. Keyword matching is not part of this proposal.
- ML-based feed ranking or personalized recommendations.
- Per-user filter preferences persisted across app restarts (Hive persistence of filter state is explicitly deferred to a later proposal).
- Multi-tag AND semantics beyond what Firestore supports natively — queries will use `arrayContainsAny` (OR across supplied tags), which is the maximum Firestore supports in a single query without merging result sets.
- A `tags` administration UI or curated tag taxonomy — tag values are free text in v1.

---

## Options

### Option A: Client-side filtering

Fetch all posts using the existing unfiltered `getPostFeed` query, then apply tag and type predicates as Dart list operations in the repository implementation or a use case.

**Pros:**
- Zero Firestore index changes — no `firebase.indexes.json` additions.
- Implementation is entirely within the data and domain layers; the Firestore data source is untouched.
- Simple to unit-test: the filter logic is pure Dart with no async dependencies.

**Cons:**
- Loads the full unfiltered document set from Firestore on every page fetch; when 10 % of posts match the active filter, 90 % of reads are wasted, burning quota.
- Pagination breaks: a page of 20 Firestore documents may yield 3 matching posts after filtering, forcing multiple round trips before the UI can fill the viewport — undermining the cursor-based contract from PROP-0003.
- Bandwidth and latency scale with total post volume, not result set size. Unusable at meaningful content scale.

**Effort:** S

---

### Option B: Firestore composite query

Push filter predicates into the Firestore query at the data source layer using `where('postType', isEqualTo: type)` and `where('tags', arrayContainsAny: tags)` clauses, backed by composite indexes. Introduce a `PostFeedFilter` value object in the domain layer; thread it through `PostRepository.getPostFeed` and `PostFirestoreDataSource.getPostFeed`. The cursor cache in the data source is keyed by `(page, filter)` so different active filters maintain independent cursor chains.

**Pros:**
- Only matching documents are transferred from Firestore — reads and bandwidth scale with the result set, not the corpus.
- Pagination correctness is preserved: `startAfterDocument` operates on the already-filtered query, so each page returns exactly `pageSize` matching documents.
- Domain interface change is minimal and additive: `getPostFeed` gains an optional `filter` parameter with a neutral default, leaving all existing call sites unaffected.
- `arrayContainsAny` supports up to 10 tag values per query — sufficient for the realistic case of a student filtering by one or two course codes simultaneously.

**Cons:**
- Requires new composite Firestore indexes: at minimum `(postType ASC, createdAt DESC)` and `(tags ARRAY, createdAt DESC)`. These must be declared in `firestore.indexes.json` and deployed before the feature ships.
- Firestore supports only one `arrayContains` / `arrayContainsAny` clause per query. Multi-tag AND semantics (posts that have tag "CS101" AND tag "Calculus") are not expressible in a single query; the proposal accepts `arrayContainsAny` OR semantics for multi-tag, which covers the primary use case of narrowing by course code.
- The cursor cache invalidation strategy must account for filter changes: switching the active filter must clear cached cursors for the previous filter to avoid serving stale page boundaries.

**Effort:** M

---

### Option C: Dedicated materialized view collection

Maintain a separate Firestore collection (e.g. `tag_posts/{tag}/posts/{postId}`) as a denormalized index, written by a Cloud Function on every post create or update. Query this sub-collection directly when a tag filter is active, falling back to the main `posts` collection when no filter is set.

**Pros:**
- Single-tag queries are trivially fast: no composite index needed — the collection itself is the index.
- Query path is entirely independent of the main `posts` collection, so filtering never competes with unfiltered feed reads.

**Cons:**
- Introduces a write-time fan-out: every post write triggers a Cloud Function that writes one document per tag. A post with 5 tags produces 5 additional writes plus the base write — multiplied across all create and update operations.
- Schema complexity is significantly higher: two code paths in the data source, two cursor-cache strategies, and a Cloud Function that must be kept consistent with the `posts` schema as it evolves.
- Risk of consistency drift: if the Cloud Function fails or is delayed, the materialized view lags the source collection. Handling this correctly requires retry logic and a backfill strategy — out of scope for v1.
- Not worth the operational cost at current content volume, per the same reasoning that deferred Algolia in PROP-0003.

**Effort:** L

---

## Recommendation

**Chosen option:** Option B — Firestore composite query.

This option pushes filtering to Firestore where it belongs, keeps reads proportional to the result set, and preserves the cursor-based pagination contract established in PROP-0003 without introducing a new Firestore sub-structure or Cloud Function dependency. The domain interface change is backward-compatible: a `PostFeedFilter` value object with a neutral empty-filter default means no existing call sites break. The composite indexes required are a one-time deployment cost that Firestore manages automatically once declared in `firestore.indexes.json`, which is a standard part of any Firebase project's CI pipeline.

The known limitation — `arrayContainsAny` delivering OR rather than AND semantics across tags — is an acceptable trade-off for v1. The primary user story is "show me posts tagged CS101," not "show me posts tagged both CS101 and Advanced Algorithms simultaneously." AND semantics across multiple tags can be layered on top later via client-side intersection of two separate queries without changing the domain interface.

---

## Open questions

- [ ] Should active filter state be persisted across app restarts (Hive) or held in Riverpod session memory only? Hive persistence gives continuity but couples the presentation layer to a storage concern; session-only is simpler and avoids stale tag state if the user's course list changes between sessions.
- [ ] Tag taxonomy: should tag values be free-form strings entered by the post author, or drawn from a curated `tags` Firestore collection maintained by an admin? Free-form is simpler but risks fragmentation ("cs101", "CS 101", "CS-101" as separate filter values). A curated list adds a dependency but improves filter accuracy.
- [ ] UI affordance for active filters: filter chips pinned below the AppBar (always visible, low friction), a bottom sheet opened from a filter icon (clean default view, more options space), or a collapsible drawer panel? The choice affects GoRouter state restoration scope.
- [ ] Empty-state behavior: when no posts match the active filter combination, should the feed silently show an empty list with a generic message, or explicitly surface the active filters and offer a one-tap clear action?

---

## References

- PROP-0003: Post Feed — `tech-proposals/0003-post-feed.md`
- Firestore `array-contains-any` operator documentation: https://firebase.google.com/docs/firestore/query-data/queries#array_membership
- Firestore composite index documentation: https://firebase.google.com/docs/firestore/query-data/index-overview#composite_indexes
- GoRouter state restoration: https://pub.dev/packages/go_router (state restoration section)
