---
title: "0007: Use Firestore array-contains-any for feed tag filtering"
description: "Server-side tag filtering on the post feed uses a Firestore array-contains-any query on the existing tags field, with a composite index, rather than fan-out writes or client-side filtering."
---

# 0007 — Use Firestore array-contains-any for feed tag filtering

**Status:** PROPOSED  
**Author:** Sudakarn  
**Date:** 2026-05-04

## Problem

The Unishare post feed shows every post to every student regardless of relevance. Students need to filter the feed to posts matching one or more subject/department tags. The solution must work offline, stay within the Firebase free tier, require no schema migration, and use no external paid services.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | `array-contains-any` query on existing `tags` field with a composite index | Zero migration; native Firestore operator; same read budget as today; single composite index | 30-value operator limit; cannot combine two `array-contains-any` clauses in one query |
| 2 | Fan-out writes to per-tag sub-collections at post creation time | Per-tag queries are simple ordered reads; no operator limit | Multiplies write cost by tag count; complex multi-cursor pagination for OR queries; partial-failure risk on deletion fan-out |
| 3 | Flat `primaryTag` field with equality composite index | Simple `==` + `orderBy` index; unambiguous per-tag query | Requires schema backfill on all existing posts (explicitly ruled out); loses multi-tag richness |

## Decision

**Chosen:** Option 1 — `array-contains-any` query on the existing `tags` field.

The `tags: string[]` field already exists on every post written since PROP-0004, so a Firestore composite index on `(tags array-contains, createdAt desc)` is all that is needed — no new collections, no write-path changes, no backfill. This fits the free tier because the index is free to create and the per-page read count is unchanged from the unfiltered feed. Options 2 and 3 both require either multiplicative write costs or a schema migration, making Option 1 the only approach that satisfies all three hard constraints (no migration, free tier, offline support) simultaneously.

## Reversal Cost

**Low.** The composite index can be dropped from `firestore.indexes.json` and the `tagFilter` parameter removed from `PostRepository.getPostFeed`. No documents need to be rewritten. The only residual cost is updating the Riverpod provider and filter UI if the team adopts a different approach.

## Consequences

- A composite Firestore index `(tags array-contains, createdAt desc)` must be declared in `firestore.indexes.json` and deployed before the filtered feed is released.
- The domain repository interface gains a `List<String> tagFilter` parameter; the data layer applies it conditionally — empty list → unfiltered query, non-empty list → `array-contains-any` query.
- Selecting more than 30 tags requires query batching in the data layer; the team must decide whether to cap the UI at a lower limit or handle batching transparently (tracked as an open question in PROP-0007).
- Posts predating PROP-0004 (with no `tags` field) are correctly excluded from filtered results. This is acceptable but must be communicated to users.
- A second independent tag-dimension filter (e.g., department AND subject type simultaneously via two `array-contains-any` clauses) is not possible in a single Firestore query; if that requirement emerges, this decision will need to be revisited.
