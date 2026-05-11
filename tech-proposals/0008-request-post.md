---
title: '0008: Request Post'
description: 'Allow authenticated students to post content requests tied to a specific course, and allow uploaders to fulfill a request by linking one of their existing posts to it.'
---

# PROP-0008: Request Post

**Status:** APPROVED
**Author:**  
**Date:** 2026-05-09  
**Spec:** (pending approval)  
**Approved by:** (fill in when accepted)

---

## Problem

The Unishare feed is entirely supply-driven: content appears only after an uploader decides to share it. Students who need a specific resource — the past exam for CPE-231, the solution set for week-7 exercises, lecture notes for a module they missed — have no mechanism to signal that gap. They must either search and come up empty, or leave the app to ask classmates through external channels (LINE groups, Discord).

The result is two-sided friction. Potential uploaders, who may have the material, do not know there is demand for it. Students who need material do not know whether to wait, ask, or give up. The upload side of the platform therefore lacks one of the strongest motivators for contribution: a visible, specific, unsatisfied request from a peer.

This gap is most acute in course-specific contexts. A request for "CPE-231 midterm 2024" is actionable and discoverable by the handful of students enrolled in that course who may have the file. A generic "please upload more notes" sentiment is not. The missing feature is a structured, course-scoped, real-time request surface.

Anonymous requests were evaluated and ruled out. Without identity, there is no accountability for spam, no way to notify a requester when their request is fulfilled, and no way to enforce the one-request-per-user-per-course limit that prevents flooding. All requests must be tied to an authenticated Firebase user.

---

## Proposed Solution

Add a **Requests** screen under the existing MORE navigation branch (`/more/requests`). A placeholder screen already exists at that route; this proposal fills it in. The navbar and routing are untouched.

### User flows

**Requester flow:** An authenticated user opens More → Requests. The screen shows all open requests filtered to their enrolled courses by default, with an option to view all courses. They tap a FAB to create a new request, fill in a course (required), a short title, and an optional description. The request is saved to Firestore and appears in the list in real time for all users watching that course.

**Fulfiller flow:** A user browsing the Requests list sees an open request that matches a post they have already uploaded. They tap "Fulfill" on the request card. A bottom sheet lists their existing posts that match the request's `courseId`. They select one post. The request's `fulfilledByPostId` field is written and its `status` field is set to `fulfilled`. The requester is not notified in this release (deferred — see Open Questions).

### Firestore schema

```
requests/{requestId}
  id:                  string      (== document ID)
  requesterId:         string      (UID of the requesting user)
  requesterName:       string      (denormalized display name — snapshot at write time)
  courseId:            string      (Firestore reference data ID — required)
  courseName:          string      (denormalized — snapshot at write time)
  title:               string      (max 120 characters)
  description:         string      (optional, max 500 characters)
  status:              string      ("open" | "fulfilled")
  fulfilledByPostId:   string?     (null until fulfilled; set to posts/{postId})
  fulfilledByUserId:   string?     (UID of the fulfilling uploader)
  createdAt:           Timestamp
  updatedAt:           Timestamp
```

There are no sub-collections on `requests`. The `fulfilledByPostId` is a plain string referencing a `posts` document; the client resolves it lazily when the user taps through to view the fulfilling post.

Composite indexes required:

- `courseId ASC, status ASC, createdAt DESC` — for scoped, status-filtered, chronological listing
- `requesterId ASC, createdAt DESC` — for "my requests" view

### Real-time updates

The Requests screen subscribes to a Firestore `snapshots()` stream scoped by `courseId` and optionally by `status`. Riverpod exposes this as a `StreamProvider` (or `AsyncNotifier` with a stream) so that new requests and status changes propagate to the UI without a manual refresh. This is consistent with the existing `watchFeed` and `watchPost` patterns already in `PostFirestoreDatasource`.

### Course scoping

Every request document carries a required `courseId`. The Create Request form reuses the existing course picker widget already present in the post-creation flow. The Requests list defaults to showing requests from the user's enrolled courses (drawn from their Firestore profile). A "Show all courses" toggle switches to a broader unfiltered view. This is the same filtering model used by the feed's tag-filter mechanism.

### Clean Architecture layers

| Layer                     | Artifact                                                                       |
| ------------------------- | ------------------------------------------------------------------------------ |
| `domain/entities/`        | `ContentRequest` (pure Dart), `RequestStatus` enum                             |
| `domain/repositories/`    | `RequestRepository` abstract interface                                         |
| `domain/usecases/`        | `WatchRequests`, `CreateRequest`, `FulfillRequest`                             |
| `data/datasources/`       | `RequestFirestoreDatasource`                                                   |
| `data/models/`            | `RequestDto` (Freezed + `json_serializable`)                                   |
| `data/repositories/`      | `RequestRepositoryImpl`                                                        |
| `presentation/providers/` | `requestsProvider` (stream), `createRequestProvider`, `fulfillRequestProvider` |
| `presentation/screens/`   | `RequestsScreen` (list), `CreateRequestScreen` (form)                          |
| `presentation/widgets/`   | `RequestCard`, `FulfillBottomSheet`                                            |

The feature lives at `apps/mobile/lib/features/requests/`. The Domain layer carries zero Flutter or Firebase imports.

### What is explicitly out of scope for this release

- Push notifications to the requester when their request is fulfilled
- Upvoting or voting on requests (demand signaling beyond simple creation)
- Anonymous requests (ruled out — see Problem section)
- Request expiry (see Open Questions)
- Multiple fulfillments for a single request (see Open Questions)

---

## Alternatives Considered

### A — Requests as a special post type mixed into the main feed

Extend `PostType` with a `request` variant. Request creation reuses the existing create-post flow. Requests appear in the feed interleaved with uploaded content, differentiated by a visual badge.

**Pros:** No new Firestore collection; reuses existing `posts` schema, `PostRepository`, create-post flow, and `PostCard` widget. Fulfillment is just a comment or a reply post.

**Cons:** The feed becomes semantically mixed — users browsing for study materials see unfulfilled requests alongside actual content, degrading the discovery value of the feed. Filtering requests out of the feed requires an additional `postType != request` predicate on every feed query, adding a Firestore composite index and complicating the query path. The `Post` entity already carries fields (`mediaUrls`, `mediaTypes`, `codeSnippetUrl`) that are meaningless for a request, leading to a widening entity that serves two unrelated purposes. Fulfillment semantics (linking a response post back to the request) have no natural fit in the comment or reply model. **Rejected:** semantic pollution of the feed and entity bloat outweigh the reuse benefit. A dedicated collection is a cleaner boundary.

### B — Dedicated top-level navigation tab (fifth tab: REQUESTS)

Add a fifth bottom-bar tab alongside FEED, POSTS, NOTIFS, MORE. The Requests screen is a first-class destination at the same level as the feed.

**Pros:** Maximum discoverability. Users never need to navigate through MORE to find it. A dedicated tab could also carry a badge count for new or open requests.

**Cons:** The bottom bar currently has four tabs matching the Figma design (FEED, POSTS, NOTIFS, MORE). Adding a fifth tab breaks the established design system and requires updating `ShellScaffold`, `StatefulShellRoute`, and the custom bar widget — a non-trivial change with no approved design backing. The MORE tab was explicitly designed as the collection point for secondary destinations; Requests fits that role given its initial niche use. If Requests proves high-traffic after launch, promoting it to a top-level tab is a one-step migration (change the router branch order and update the bar widget). **Rejected by the user:** the team explicitly chose MORE-nested placement. Reversal cost is low if usage data later justifies promotion.

### C — Requests as a sub-collection under each course document (`courses/{courseId}/requests`)

Store requests as sub-collections nested under the corresponding course document rather than in a flat top-level `requests` collection.

**Pros:** Data is physically co-located with its course; security rules can scope reads and writes to course members without cross-collection joins. Queries for a single course require no composite index (just a collection-group query or a direct sub-collection read).

**Cons:** Showing a "my requests" view (all requests the current user has created across all their courses) requires a Firestore `collectionGroup('requests')` query, which demands a collection group index and opens the query surface wider than intended. Adding a global "all open requests" view becomes difficult without collectionGroup. The flat top-level collection with `courseId` as a field is a standard Firestore denormalization pattern that keeps all query paths simple and consistent with the existing `posts` collection design. **Rejected:** the collectionGroup query complexity for cross-course views outweighs the locality benefit, particularly since the `posts` collection already established the flat-collection-with-foreign-key pattern for this app.

---

## Open Questions

1. **Single vs. multiple fulfillments.** The schema above allows exactly one fulfilling post (`fulfilledByPostId` is a single nullable string). Can a request be fulfilled by more than one post — for example, two different uploaders both sharing relevant material for the same request? If so, the schema needs to change to a `fulfillments` sub-collection (or an array of fulfillment objects), and the `status` field logic becomes more complex (e.g., `open` → `partially_fulfilled` → `fulfilled`). This must be decided before the data layer is implemented.

2. **Who can mark a request as fulfilled?** The current proposal allows any authenticated user (the fulfiller) to link their own post and transition `status` to `fulfilled`. Should the requester also be able to mark their own request as fulfilled manually — for example, if they found the material outside the app? Should admins or moderators have override capability? Firestore security rules depend on this decision.

3. **Request expiry.** Stale open requests from past semesters will accumulate. Should requests carry a `expiresAt` timestamp (e.g., end of the current semester)? If so, who sets it — the requester, the system, or a Cloud Function? Alternatively, should requests be soft-deleted by the requester, or simply filtered out of the default view after a configurable age? An unbounded open request list degrades the signal-to-noise ratio of the Requests screen over time.

4. **Requester notification.** When a request transitions to `fulfilled`, should the requester receive a push notification? This is deferred from the current scope, but the domain event (`RequestFulfilled`) should be defined now so that the notification feature can be wired in later without a schema change. The team must decide whether a `notifyOnFulfill: bool` flag should be captured at request-creation time.

5. **One-request-per-user-per-course limit.** Should a user be prevented from creating multiple open requests for the same `courseId`? Enforcing this in the client is straightforward but bypassable; enforcing it in Firestore security rules requires a read-before-write that is awkward in rules. A Cloud Function trigger is the correct enforcement point, but adds operational surface. The team must decide whether to enforce the limit and at which layer.

---

## Acceptance Criteria

- An authenticated user can create a content request by specifying a course (required), a title (required, max 120 characters), and an optional description (max 500 characters). Unauthenticated and guest-mode users cannot access the create-request flow.
- The Requests screen at `/more/requests` displays open requests in reverse-chronological order. New requests submitted by any user appear in the list without a manual refresh (real-time Firestore listener).
- Each request is scoped to exactly one course. The course picker in the create-request form reuses the existing course selection widget from the post-creation flow.
- An authenticated user can fulfill a request by selecting one of their own existing posts from a bottom sheet. After fulfillment, the request card displays the linking post's title and the status badge changes from "Open" to "Fulfilled" without a page reload.
- A fulfilled request's `fulfilledByPostId` resolves to a navigable post — tapping it pushes `/posts/:postId` inside the MORE branch navigator.
- The Requests screen defaults to showing requests from the current user's enrolled courses. A toggle switches to all-courses view.
- `flutter analyze` reports zero errors or warnings on all new code.
- The `ContentRequest` domain entity and `RequestRepository` interface contain zero Flutter or Firebase imports.
- `RequestsScreen`, `CreateRequestScreen`, and `RequestCard` each have a widget test. `WatchRequests`, `CreateRequest`, and `FulfillRequest` use cases each have a unit test against a mock `RequestRepository`.
- Firestore security rules deny request creation to unauthenticated users and deny fulfillment writes where `fulfilledByUserId` does not match the authenticated user's UID.
