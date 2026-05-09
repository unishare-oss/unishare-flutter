---
Date: 2026-05-09 00:00
Member: Nang Hayman Aye Mya
Agent: architect
Task: Write Tech Proposal PROP-0008 for the request-post feature
Prompt: Write a Tech Proposal for the "request-post" feature in the Unishare Flutter app. Save it at tech-proposals/0008-request-post.md. Students want to request specific academic content that hasn't been uploaded yet, so uploaders know what to create/share. Uploaders can respond to a request by linking one of their existing posts to that request. Constraints: real-time updates, course/subject scoping, authenticated users only. Preferred approach: Request tab inside the existing More navigation section.

Outcome: Wrote tech-proposals/0008-request-post.md (PROP-0008, DRAFT). Proposal covers Firestore flat-collection schema for requests/{requestId}, real-time stream listener pattern, course scoping via courseId field with two composite indexes, Clean Architecture layer breakdown, three alternatives with rejection reasoning, five open questions, and ten acceptance criteria.
Decisions: Chose flat top-level requests/ collection over course sub-collection (Option C) to keep cross-course queries simple and consistent with the existing posts/ pattern. Adopted single-fulfillment schema as the baseline but flagged multi-fulfillment as Open Question 1 before data layer implementation. Kept placement at /more/requests per team preference rather than promoting to a fifth top-level tab (Option B).
Handoff: Proposal is DRAFT and must be reviewed and accepted by the team before a tech spec (SPEC-0008) can be written. Open Questions 1 (single vs. multiple fulfillments) and 2 (who can mark fulfilled) must be resolved first as they directly affect the Firestore schema and security rules. Open Question 5 (one-request-per-course limit) affects whether a Cloud Function is needed.

---
Date: 2026-05-07 12:30
Member: Nang Hayman Aye Mya
Agent: flutter-engineer
Task: Scaffold and implement SPEC-0007 Save Post feature
Prompt: /new-feature save-post — scaffold the folder structure, stub files, and session scratchpad for the save-post feature per SPEC-0007 (APPROVED).
Outcome: Full Save Post feature implemented — domain, data, core storage, presentation layers; PostCard save button wired; SavedScreen; PostDetailScreen save button; guest shell (FEED|SAVED|SIGN IN).
Decisions: Used async* generator streams instead of rxdart for Hive; abstract class keyword on SavedPostDto for Freezed v3; .asData?.value instead of .valueOrNull (not in riverpod 3.3.1); Branch 4 added to StatefulShellRoute for /saved (guest top-level); Consumer in StatefulShellRoute.builder to conditionally render GuestShellScaffold vs ShellScaffold; redirect rule added — auth users at /saved → /more/saved.
Handoff: flutter analyze passes with 0 issues. All 10 plan steps complete. Needs QA widget tests and architect review before merge.
Review: PENDING
