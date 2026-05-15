---
title: "0007: Feed Filtering by Tags"
description: "Full implementation spec for server-side tag filtering on the post feed using Firestore array-contains-any, curated tag enumeration, cross-device preference persistence, and Hive offline cache."
---

# SPEC-0007: Feed Filtering by Tags

**Status:** APPROVED  
**Author:** Sudakarn  
**Date:** 2026-05-05  
**Proposal:** [PROP-0007](../tech-proposals/0007-feed-filtering-tags.md)  
**Approved by:** Sudakarn

---

## Overview

This spec defines the complete implementation for server-side tag filtering on the Unishare post feed. A student can open a filter picker, select one or more curated tags drawn from a Firestore reference collection, and receive only posts whose `tags` array contains at least one of the selected values — filtered by Firestore, not in memory. The active filter set is persisted to `users/{uid}/preferences` in Firestore so it survives app restarts and syncs across devices. The first page of the filtered feed is cached to Hive so it is available offline. When a filter returns zero posts, a dedicated empty-state widget is shown — there is no silent fallback to the unfiltered feed. The domain layer gains two new interfaces (`TagRepository`, `PostFilterPreferences` entity) and three new use cases; the existing `PostRepository` interface is extended with a `tagFilter` parameter; the existing feed screen is modified, not replaced.

---

## Architecture

```mermaid
flowchart TD
    subgraph Presentation
        FeedScreen[FeedScreen\n(modified)]
        FilterPicker[FilterPickerWidget\n(new)]
        FeedProv[feedProvider\n(modified AsyncNotifier)]
        FilterPrefProv[filterPreferencesProvider\n(new AsyncNotifier)]
        TagListProv[tagListProvider\n(new AutoDisposeFutureProvider)]
    end

    subgraph Domain
        PFPE[PostFilterPreferences\nentity (new)]
        TagE[TagEntity\n(new)]
        PR[PostRepository interface\n(modified — add tagFilter)]
        TR[TagRepository interface\n(new)]
        GTL[GetTagList use case\n(new)]
        SFP[SaveFilterPreferences\nuse case (new)]
        GFP[GetFilterPreferences\nuse case (new)]
    end

    subgraph Data
        PFD[PostFirestoreDatasource\n(modified — conditional predicate)]
        TagFD[TagFirestoreDatasource\n(new)]
        PrefFD[PreferencesFirestoreDatasource\n(new)]
        PRI[PostRepositoryImpl\n(modified)]
        TRI[TagRepositoryImpl\n(new)]
        PrefRI[PreferencesRepositoryImpl\n(new)]
        FeedCacheModel[FeedCacheModel\n(Hive — modified key)]
    end

    subgraph External
        FSPosts[(Firestore\nposts/)]
        FSTags[(Firestore\ncourses/ or tags/)]
        FSPrefs[(Firestore\nusers/{uid}/preferences)]
        HV[(Hive\nfeed_cache box)]
    end

    FeedScreen --> FeedProv
    FeedScreen --> FilterPicker
    FilterPicker --> FilterPrefProv
    FilterPicker --> TagListProv
    FeedProv --> FilterPrefProv
    FeedProv --> PR
    FilterPrefProv --> SFP
    FilterPrefProv --> GFP
    TagListProv --> GTL
    GTL --> TR
    SFP --> TR
    GFP --> TR
    SFP --> PFPE
    GFP --> PFPE
    PR --> PRI
    TR --> TRI
    GFP --> PrefRI
    SFP --> PrefRI
    PRI --> PFD
    PRI --> FeedCacheModel
    TRI --> TagFD
    PrefRI --> PrefFD
    PFD --> FSPosts
    TagFD --> FSTags
    PrefFD --> FSPrefs
    FeedCacheModel --> HV
```

The Domain layer holds zero Flutter or Firebase imports. `PostRepository`, `TagRepository`, all three use cases, and both entities depend only on pure Dart types. The Data layer owns all Firestore SDK calls. The Presentation layer reads domain types via Riverpod providers and never imports from `data/` directly.

---

## File map

| Action | Path | Responsibility |
|---|---|---|
| Create | `lib/features/post/domain/entities/post_filter_preferences.dart` | Pure Dart entity holding `selectedTags` list and `updatedAt`; no framework imports |
| Create | `lib/features/post/domain/entities/tag_entity.dart` | Pure Dart entity for one curated tag: `id`, `label`, `department`, `code` |
| Modify | `lib/features/post/domain/repositories/post_repository.dart` | Add `getPostFeed` method with `tagFilter` parameter alongside existing methods |
| Create | `lib/features/post/domain/repositories/tag_repository.dart` | Abstract interface: `getTags()` returning curated tag list |
| Create | `lib/features/post/domain/repositories/preferences_repository.dart` | Abstract interface: `saveFilterPreferences`, `getFilterPreferences` |
| Create | `lib/features/post/domain/usecases/get_tag_list.dart` | Delegates to `TagRepository.getTags()`; single responsibility |
| Create | `lib/features/post/domain/usecases/save_filter_preferences.dart` | Validates tag list (max 30, all non-empty strings), delegates to `PreferencesRepository` |
| Create | `lib/features/post/domain/usecases/get_filter_preferences.dart` | Reads from `PreferencesRepository`; returns empty `PostFilterPreferences` if no document exists |
| Create | `lib/features/post/data/datasources/tag_firestore_datasource.dart` | Reads curated tag reference collection from Firestore; maps documents to `TagEntity` |
| Create | `lib/features/post/data/datasources/preferences_firestore_datasource.dart` | Reads and writes `users/{uid}/preferences` document; returns raw map |
| Modify | `lib/features/post/data/datasources/post_firestore_datasource.dart` | Swap query predicate: `array-contains-any` when `tagFilter` is non-empty; fallback to unfiltered `orderBy` when empty |
| Create | `lib/features/post/data/models/tag_model.dart` | Freezed model mirroring `TagEntity`; `fromFirestore` factory and `toEntity()` method |
| Create | `lib/features/post/data/models/post_filter_preferences_model.dart` | Freezed model mirroring `PostFilterPreferences`; `fromFirestore` and `toEntity()` |
| Create | `lib/features/post/data/repositories/tag_repository_impl.dart` | Implements `TagRepository`; delegates to `TagFirestoreDatasource` |
| Create | `lib/features/post/data/repositories/preferences_repository_impl.dart` | Implements `PreferencesRepository`; delegates to `PreferencesFirestoreDatasource` |
| Modify | `lib/features/post/data/repositories/post_repository_impl.dart` | Pass `tagFilter` through to `PostFirestoreDatasource`; use tag-aware cache key in Hive |
| Modify | `lib/features/post/presentation/screens/feed_screen.dart` | Add filter chip row at top; wire to `filterPreferencesProvider`; render empty-state widget when feed list is empty and filter is active |
| Create | `lib/features/post/presentation/widgets/filter_picker_widget.dart` | Bottom-sheet or dialog listing all curated tags from `tagListProvider`; checkboxes reflecting `filterPreferencesProvider` selection; confirm / clear buttons |
| Create | `lib/features/post/presentation/widgets/feed_empty_state_widget.dart` | Renders message and "Clear filter" button when filtered feed returns zero posts |
| Create | `lib/features/post/presentation/providers/tag_list_provider.dart` | `@riverpod` `AutoDisposeFutureProvider` calling `GetTagList` use case |
| Create | `lib/features/post/presentation/providers/filter_preferences_provider.dart` | `@riverpod` `AsyncNotifier<PostFilterPreferences>` calling `GetFilterPreferences` on build; `save` method calls `SaveFilterPreferences` |
| Modify | `lib/features/post/presentation/providers/feed_provider.dart` | Read `filterPreferencesProvider`; pass `selectedTags` as `tagFilter` to `PostRepository.getPostFeed` |
| Modify | `firestore.indexes.json` | Add composite index: `posts` collection, `tags` (Arrays) + `createdAt` (Descending) |
| Modify | `firestore.rules` | Add `allow read, write` rule for `users/{uid}/preferences`; scope write to authenticated owner |

---

## API contracts

### Domain entity — `PostFilterPreferences`

```dart
// lib/features/post/domain/entities/post_filter_preferences.dart

/// Holds the user's currently saved tag filter selection.
/// No Flutter or Firebase imports — pure Dart only.
class PostFilterPreferences {
  const PostFilterPreferences({
    required this.selectedTags,
    required this.updatedAt,
  });

  /// The canonical tag identifiers the user has selected.
  /// Empty list means no filter is active (unfiltered feed).
  final List<String> selectedTags;

  /// Last time the preferences were written to Firestore.
  final DateTime updatedAt;

  bool get isActive => selectedTags.isNotEmpty;

  PostFilterPreferences copyWith({
    List<String>? selectedTags,
    DateTime? updatedAt,
  }) {
    return PostFilterPreferences(
      selectedTags: selectedTags ?? this.selectedTags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Canonical empty state — no filter active.
  static PostFilterPreferences empty() => PostFilterPreferences(
        selectedTags: const [],
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
}
```

### Domain entity — `TagEntity`

```dart
// lib/features/post/domain/entities/tag_entity.dart

/// One canonical tag drawn from the curated Firestore reference collection.
/// No Flutter or Firebase imports — pure Dart only.
class TagEntity {
  const TagEntity({
    required this.id,
    required this.label,
    required this.department,
    required this.code,
  });

  /// Firestore document ID — used as the value stored in `posts[].tags`
  /// and in `PostFilterPreferences.selectedTags`.
  final String id;

  /// Human-readable display name, e.g. "Database Systems".
  final String label;

  /// Department slug this tag belongs to, e.g. "computer-science".
  final String department;

  /// Short course code, e.g. "CS301".
  final String code;
}
```

### Domain repository interface — `PostRepository` (modified)

```dart
// lib/features/post/domain/repositories/post_repository.dart

import '../entities/post.dart';
import '../entities/post_draft.dart';

abstract interface class PostRepository {
  // --- existing from PROP-0003 (preserved) ---
  Stream<List<Post>> watchFeed({int limit = 20});

  // --- existing from SPEC-0004 (preserved) ---
  Future<void> saveDraft(PostDraft draft);
  Future<void> removeDraft(String draftId);
  Future<List<PostDraft>> loadDraftQueue();
  Future<void> publishDraft(
    PostDraft draft, {
    void Function(double progress)? onProgress,
  });

  // --- new for SPEC-0007 ---

  /// Returns the first [pageSize] posts ordered by createdAt descending.
  ///
  /// When [tagFilter] is non-empty, applies `array-contains-any` on `tags`.
  /// When [tagFilter] is empty, returns the unfiltered feed — identical
  /// behaviour to the existing [watchFeed] query, preserving backward compat.
  ///
  /// [cursor] is the last [DocumentSnapshot] from the previous page; omit for
  /// the first page. The cursor type is `Object?` to avoid importing
  /// cloud_firestore in the domain layer — the data layer casts it internally.
  ///
  /// If [tagFilter] contains more than 30 values the data layer MUST split
  /// the list into batches of 30 and merge results by createdAt before
  /// returning, so callers are not exposed to the Firestore operator limit.
  Future<List<Post>> getPostFeed({
    int pageSize = 20,
    Object? cursor,
    List<String> tagFilter = const [],
  });
}
```

### Domain repository interface — `TagRepository` (new)

```dart
// lib/features/post/domain/repositories/tag_repository.dart

import '../entities/tag_entity.dart';

abstract interface class TagRepository {
  /// Returns the full list of canonical tags from the curated reference
  /// collection. Results are sorted by [TagEntity.department] then
  /// [TagEntity.code] ascending to produce a stable picker order.
  Future<List<TagEntity>> getTags();
}
```

### Domain repository interface — `PreferencesRepository` (new)

```dart
// lib/features/post/domain/repositories/preferences_repository.dart

import '../entities/post_filter_preferences.dart';

abstract interface class PreferencesRepository {
  /// Reads the authenticated user's filter preferences from
  /// `users/{uid}/preferences`. Returns [PostFilterPreferences.empty()]
  /// if no document exists yet — callers must not treat a missing document
  /// as an error.
  Future<PostFilterPreferences> getFilterPreferences(String uid);

  /// Writes [preferences] to `users/{uid}/preferences` using merge-write
  /// semantics so that unrelated fields on the preferences document are
  /// preserved.
  Future<void> saveFilterPreferences(String uid, PostFilterPreferences preferences);
}
```

### Domain use case — `GetTagList` (new)

```dart
// lib/features/post/domain/usecases/get_tag_list.dart

import '../entities/tag_entity.dart';
import '../repositories/tag_repository.dart';

class GetTagList {
  const GetTagList(this._repository);

  final TagRepository _repository;

  /// Returns the full curated tag list in department-then-code order.
  /// Throws on network failure; callers must handle the error state.
  Future<List<TagEntity>> call() => _repository.getTags();
}
```

### Domain use case — `SaveFilterPreferences` (new)

```dart
// lib/features/post/domain/usecases/save_filter_preferences.dart

import '../entities/post_filter_preferences.dart';
import '../repositories/preferences_repository.dart';

class SaveFilterPreferences {
  const SaveFilterPreferences(this._repository);

  final PreferencesRepository _repository;

  /// Validates [selectedTags] (no empty strings; list length <= 30 per the
  /// Firestore operator limit that the data layer enforces via batching — the
  /// UI cap is advisory, not enforced here) then persists to Firestore.
  ///
  /// [uid] is the authenticated user's Firebase UID.
  /// Throws [ArgumentError] if any tag string is blank.
  Future<void> call({
    required String uid,
    required List<String> selectedTags,
  }) {
    if (selectedTags.any((t) => t.trim().isEmpty)) {
      throw ArgumentError('tag strings must not be blank');
    }
    final preferences = PostFilterPreferences(
      selectedTags: selectedTags,
      updatedAt: DateTime.now(),
    );
    return _repository.saveFilterPreferences(uid, preferences);
  }
}
```

### Domain use case — `GetFilterPreferences` (new)

```dart
// lib/features/post/domain/usecases/get_filter_preferences.dart

import '../entities/post_filter_preferences.dart';
import '../repositories/preferences_repository.dart';

class GetFilterPreferences {
  const GetFilterPreferences(this._repository);

  final PreferencesRepository _repository;

  /// Reads saved preferences for [uid]. Returns [PostFilterPreferences.empty()]
  /// when no preferences document exists — never throws for a missing document.
  Future<PostFilterPreferences> call(String uid) =>
      _repository.getFilterPreferences(uid);
}
```

### Riverpod provider signatures (new / modified)

```dart
// lib/features/post/presentation/providers/tag_list_provider.dart

@riverpod
Future<List<TagEntity>> tagList(TagListRef ref) async {
  final useCase = GetTagList(ref.read(tagRepositoryProvider));
  return useCase.call();
}
```

```dart
// lib/features/post/presentation/providers/filter_preferences_provider.dart

@riverpod
class FilterPreferencesNotifier extends _$FilterPreferencesNotifier {
  @override
  Future<PostFilterPreferences> build() async {
    final uid = ref.read(currentUserProvider).requireValue.uid;
    final useCase = GetFilterPreferences(ref.read(preferencesRepositoryProvider));
    return useCase.call(uid);
  }

  /// Saves [selectedTags] to Firestore and updates the local state.
  Future<void> save(List<String> selectedTags) async {
    final uid = ref.read(currentUserProvider).requireValue.uid;
    final useCase = SaveFilterPreferences(ref.read(preferencesRepositoryProvider));
    await useCase.call(uid: uid, selectedTags: selectedTags);
    final updated = PostFilterPreferences(
      selectedTags: selectedTags,
      updatedAt: DateTime.now(),
    );
    state = AsyncData(updated);
  }

  /// Clears all selected tags and persists the empty set.
  Future<void> clear() => save(const []);
}
```

```dart
// lib/features/post/presentation/providers/feed_provider.dart
// (modified — derives tagFilter from filterPreferencesProvider)

@riverpod
class FeedNotifier extends _$FeedNotifier {
  @override
  Future<List<Post>> build() async {
    // Read active filter; default to empty (unfiltered) if preferences are
    // still loading or errored.
    final prefsAsync = ref.watch(filterPreferencesNotifierProvider);
    final tagFilter = prefsAsync.valueOrNull?.selectedTags ?? const [];

    final repository = ref.read(postRepositoryProvider);
    return repository.getPostFeed(tagFilter: tagFilter);
  }

  /// Fetches the next page using the last document as a cursor.
  Future<void> fetchNextPage(Object? cursor) async {
    final prefsAsync = ref.read(filterPreferencesNotifierProvider);
    final tagFilter = prefsAsync.valueOrNull?.selectedTags ?? const [];
    final repository = ref.read(postRepositoryProvider);
    final nextPage = await repository.getPostFeed(
      cursor: cursor,
      tagFilter: tagFilter,
    );
    state = AsyncData([...state.requireValue, ...nextPage]);
  }
}
```

---

## Firestore schema

### `posts/{postId}` — unchanged

The `tags: string[]` field established by PROP-0004 is the sole filter target. No new fields are added; no existing documents are migrated. Posts written before PROP-0004 (with an empty or missing `tags` field) will not appear in filtered results — this is the correct and accepted behavior.

```
posts/{postId}
  authorId:     string
  authorName:   string
  authorAvatar: string
  title:        string
  body:         string
  mediaUrls:    string[]
  tags:         string[]   ← primary filter target; populated at write time by SPEC-0004
  likesCount:   int
  createdAt:    Timestamp
  updatedAt:    Timestamp
```

### `users/{uid}/preferences` — new fields

Preferences are stored as a named document at the path `users/{uid}/preferences`. This is a sub-document — not a subcollection — meaning it is a single Firestore document addressed by a fixed path within the user's data scope.

```
users/{uid}/preferences
  selectedTags:  string[]   ← canonical tag IDs matching TagEntity.id values
  updatedAt:     Timestamp  ← server timestamp written on every save
```

Security rule (to be added to `firestore.rules`):

```
match /users/{uid}/preferences {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

The rule does not currently exist; the flutter-engineer must verify that the parent `users/{uid}` rule in `firestore.rules` does not already cover this path with a conflicting grant.

### Curated tag reference collection — `courses/{courseId}` (provisional)

The exact collection name must be confirmed against the seed data produced by `tools/seed_firestore.js` before this spec moves to APPROVED (see Open questions). The schema below uses `courses/{courseId}` as the working placeholder.

```
courses/{courseId}
  label:       string   ← human-readable name, e.g. "Database Systems"
  department:  string   ← department slug, e.g. "computer-science"
  code:        string   ← short course code, e.g. "CS301"
```

This document ID (`courseId`) is used as the canonical tag value stored in `posts[].tags` and in `PostFilterPreferences.selectedTags`. All reads on this collection are list reads (fetch entire collection once on picker open); no per-tag sub-queries are issued.

Security rule (read-only for authenticated users):

```
match /courses/{courseId} {
  allow read: if request.auth != null;
  allow write: if false;  // admin seeding only via service account
}
```

---

## Composite Firestore index

Add to `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "tags",      "arrayConfig": "CONTAINS" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

This index is required for the `array-contains-any` + `orderBy('createdAt', descending: true)` query to execute without a full collection scan. Without it, Firestore will reject the filtered query at runtime. Deploy before shipping the feature:

```bash
firebase deploy --only firestore:indexes
```

---

## Hive offline cache

### Existing mechanism (from PROP-0003)

The unfiltered first page of the feed is already cached to a Hive box named `feed_cache`. The cache key used today is a fixed string (e.g., `"feed_page_0"` or equivalent) because there is only one feed variant.

### Changes for SPEC-0007

The cache key must incorporate the active tag filter to prevent the unfiltered cache from being served when a filter is active, and to prevent different filter selections from colliding in the same cache slot.

Cache key derivation:

```dart
String _cacheKey(List<String> tagFilter) {
  if (tagFilter.isEmpty) return 'feed_page_0';
  final sorted = [...tagFilter]..sort();          // canonical order
  final hash   = sorted.join(',').hashCode.toRadixString(16);
  return 'feed_filtered_${hash}_page_0';
}
```

Sorting before hashing guarantees that `['cs301', 'cs401']` and `['cs401', 'cs301']` produce the same cache key.

On first load (or after filter change), `PostRepositoryImpl.getPostFeed` writes the first page result to Hive under the derived key before returning to the caller. On subsequent loads when the device is offline, the implementation reads from Hive under the same derived key and returns the cached list. Subsequent pages (page 2 onward) are not cached — this matches the existing behavior for the unfiltered feed.

The Hive `FeedCacheModel` class already exists from PROP-0003. The flutter-engineer must verify that the existing model stores the full list of `Post` fields needed by the feed cards, and must not change the Hive `typeId` assignment.

---

## Test plan

| Test file | Covers |
|---|---|
| `test/unit/features/post/domain/usecases/get_tag_list_test.dart` | `GetTagList.call` — delegates to `TagRepository.getTags()`; returns sorted list on success; propagates `Exception` from repository without swallowing |
| `test/unit/features/post/domain/usecases/save_filter_preferences_test.dart` | `SaveFilterPreferences.call` — throws `ArgumentError` when any tag string is blank; writes `PostFilterPreferences` with correct `selectedTags` and non-null `updatedAt`; passes `uid` through to repository unchanged |
| `test/unit/features/post/domain/usecases/get_filter_preferences_test.dart` | `GetFilterPreferences.call` — returns `PostFilterPreferences.empty()` when repository returns empty (no doc); returns populated entity when repository returns saved data; propagates repository exceptions |
| `test/unit/features/post/data/repositories/post_repository_impl_filter_test.dart` | Filtered query path — `getPostFeed` with non-empty `tagFilter` issues `array-contains-any` predicate, not equality; empty `tagFilter` falls back to unfiltered `orderBy` query; `tagFilter` with 31 values is split into two batches merged by `createdAt`; Hive cache key differs between unfiltered and filtered calls |
| `test/widget/features/post/screens/feed_screen_filter_test.dart` | Empty-state widget renders when `feedProvider` returns empty list and `filterPreferencesProvider` has active tags; "Clear filter" button on empty-state calls `filterPreferencesProvider.clear()`; active tag chips are visible in the filter row when preferences are non-empty; no empty-state rendered when feed returns posts regardless of filter state |
| `test/widget/features/post/widgets/filter_picker_widget_test.dart` | All tags from `tagListProvider` are rendered as checkboxes; tags already in `filterPreferencesProvider.selectedTags` render as checked on open; tapping a tag toggles its checked state locally before confirm; tapping "Confirm" calls `filterPreferencesProvider.save` with the updated selection; tapping "Clear" calls `filterPreferencesProvider.clear` |

---

## Deferred to data-layer phase

The following components are scaffolded (stub classes with `UnimplementedError`) in this phase but intentionally not wired to Firestore yet. They will be completed in the follow-on data-layer phase once `currentUserProvider` exists and the open questions below are resolved:

- `PreferencesRepositoryImpl` — delegates to `PreferencesFirestoreDatasource`; must return `PostFilterPreferences.empty()` when the Firestore document is absent and use merge-write on save
- `FilterPreferencesNotifier` — reads uid from `currentUserProvider`, calls `GetFilterPreferences` use case on build, calls `SaveFilterPreferences` on `save()`
- `FeedNotifier` — watches `filterPreferencesNotifierProvider` for active tags, calls `PostRepository.watchFeed()` with the tag filter

In the interim, the feed screen uses mock data and `activeTagFiltersProvider` (a session-local `Notifier<List<String>>`) to drive filter chip state. No UI currently reads the stubbed providers, so there is no live `UnimplementedError` crash risk.

---

## Out of scope

- Free-text search within post titles or bodies — requires a dedicated search index and is a separate proposal.
- Admin tag management: creating, renaming, or deleting canonical tags in the curated reference collection. Tags are seeded by `tools/seed_firestore.js` and are read-only to the mobile client.
- Filtering by criteria other than tags (date range, author, media type, university, etc.).
- Back-filling `tags` on posts that predate SPEC-0004 — those posts are correctly absent from filtered results.
- Push notifications of any kind.
- Filtering across two independent tag dimensions simultaneously (e.g., department AND subject type) — the Firestore `array-contains-any` operator does not support combining two such clauses in one query.
- Offline caching of pages beyond the first page of the filtered feed.
- Tag analytics or usage counters.

---

## Open questions

- [ ] **Curated tag collection name** — The spec uses `courses/{courseId}` as a working placeholder. The collection name must be confirmed against the data actually seeded by `tools/seed_firestore.js` before this spec moves to APPROVED. If the seed uses a different collection name (e.g., `subjects`, `tags`, or `universities/{uid}/courses`), every reference in this spec and in `TagFirestoreDatasource` must be updated to match. The flutter-engineer must not begin `TagRepositoryImpl` until this is resolved.

- [ ] **`users/{uid}/preferences` document vs. field** — This spec treats `preferences` as a named Firestore document at the path `users/{uid}/preferences` (i.e., a fixed document ID `"preferences"` inside the `users` collection's `{uid}` document hierarchy). An alternative is to store `selectedTags` and `updatedAt` as top-level fields directly on the `users/{uid}` document. The distinction affects the Security Rules path, the datasource read/write calls, and whether the existing `users/{uid}` document rule already grants the needed access. This must be decided and the Security Rules audited before implementation begins.
