# Unishare — System Overview

## Architecture

Clean Architecture with three layers. Data only flows inward — UI never touches Firestore directly.

```
Widget / Screen
    ↓ watches
Riverpod Provider
    ↓ calls
Use Case  (domain — pure Dart, no Firebase imports)
    ↓ calls
Repository Interface  (domain)
    ↓ implemented by
Repository Impl  (data)
    ↓ delegates to
Datasource  (data — Firestore / R2 Worker / Hive)
```

---

## External Services

| Service | What it does |
|---|---|
| Firebase Auth | User identity, session tokens |
| Cloud Firestore | All structured data (posts, users, comments, likes) |
| Cloudflare R2 | File storage (images, PDFs, videos, code snippets) |
| Cloudflare Worker | Auth-gated presigned URL generator for R2 |
| Firebase Remote Config | Feature flags |
| Firebase Crashlytics | Error reporting |
| Hive | Local offline storage for draft posts |

---

## Authentication

```
User taps Sign In
    ↓
FirebaseAuthDatasource
    ├── Email/password  →  FirebaseAuth.signInWithEmailAndPassword()
    └── Google          →  GoogleSignIn.authenticate()
                               ↓ idToken
                           GoogleAuthProvider.credential()
                               ↓
                           FirebaseAuth.signInWithCredential()
    ↓
UserCredential  →  authStateChanges() stream  →  AuthStateProvider  →  GoRouter redirects
```

Auth state is a live stream — GoRouter listens and redirects automatically on sign-in/sign-out.

---

## Reading Data (Feed, Posts, Comments)

All reads are **real-time Firestore streams** via `.snapshots()`. The UI never polls.

```
feedProvider (Riverpod)
    → PostRepository.watchFeed()
        → PostFirestoreDatasource
            → Firestore: posts
                .orderBy('createdAt', descending: true)
                .limit(20)
                .snapshots()
    → Stream<List<Post>>  →  widget rebuilds on every change
```

```
postDetailProvider(postId)
    → PostRepository.watchPost(postId)
        → Firestore: posts/{postId}.snapshots()

commentsProvider(postId)
    → CommentFirestoreDatasource.watchComments(postId)
        → Firestore: posts/{postId}/comments
            .orderBy('createdAt', ascending)
            .snapshots()
```

---

## Publishing a Post

Drafts are persisted in Hive first so nothing is lost on crash or network drop.

```
User fills form  →  CreatePostProvider.saveDraft()
    → Hive box: stores PostDraftModel locally

User submits  →  PostRepository.publishDraft(draft)
    ↓
    For each file in draft.localMediaPaths:
        1. Check draft.uploadedUrls — skip if already uploaded (crash recovery)
        2. POST to Cloudflare Worker
               Authorization: Bearer <Firebase ID token>
               { filename, contentType }
           Worker verifies token (see below), returns { uploadUrl, publicUrl }
        3. PUT file bytes directly to R2 via presigned uploadUrl
        4. Save publicUrl to draft.uploadedUrls in Hive (partial progress persisted)

    For code snippets:
        Same flow — uploaded as text/plain

    Final step:
        POST to Firestore: posts/{draftId}.set({ ...fields, mediaUrls, mediaTypes })
        → Remove draft from Hive on success
        → On failure: mark draft as DraftStatus.queued for retry
```

### File upload key format in R2

```
posts/{uid}/{timestamp}-{16-char-random}.{ext}
```

User's original filename is never used — prevents collisions and path traversal.

---

## How the Worker Verifies Firebase Tokens

The Cloudflare Worker has no Firebase Admin SDK — it verifies JWTs manually:

```
1. Parse JWT header → confirm alg = RS256
2. Parse JWT payload → check:
       exp > now
       aud = FIREBASE_PROJECT_ID
       iss = https://securetoken.google.com/{projectId}
       sub present (this is the uid)
3. Fetch Google's public JWKS:
       https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com
   Match key by kid from JWT header
   (Cloudflare caches this fetch automatically)
4. crypto.subtle.verify(RS256, publicKey, signature, header.payload)
5. Return payload.sub (uid) on success, 401 on any failure
```

---

## Likes

Likes use a **Firestore transaction** to keep the counter consistent:

```
toggleLike(postId)
    → runTransaction:
        read  posts/{postId}/likes/{uid}
        if exists:  delete it  +  likesCount -= 1
        if absent:  create it  +  likesCount += 1
```

`watchLikeStatus(postId)` streams `posts/{postId}/likes/{uid}.snapshots()` → `bool`.

---

## Draft Queue & Offline Resilience

```
SyncDraftQueue use case:
    loadDraftQueue() from Hive  (sorted by createdAt)
    for each draft with status != published:
        publishDraft(draft)  →  yield DraftStatus.published
        on error             →  yield DraftStatus.error, stop (preserves ordering)
```

Because each uploaded URL is written back to Hive immediately, a retry resumes from where it failed — already-uploaded files are skipped.

---

## Firestore Collections

```
posts/{postId}
    authorId, authorName, authorAvatar
    postType, year, courseId, semester, moduleNumber
    title, description, tags[]
    mediaUrls[], mediaTypes[]
    codeSnippetUrl, externalUrl
    likesCount, createdAt, updatedAt
    postingIdentity (named | anonymous)

    /comments/{commentId}
        authorId, authorName, authorAvatar, body, createdAt

    /likes/{uid}
        createdAt

users/{uid}
    (academic profile, set via update_academic_profile use case)

universities/{id} / departments/{id} / courses/{id}
    (seeded reference data — read-only at runtime)
```

---

## CI / Deployment

```
firestore-deploy.yml  (triggers on push to main when .rules or .indexes.json change)
    google-github-actions/auth  ←  FIREBASE_SERVICE_ACCOUNT secret
    firebase deploy --only firestore
        deploys firestore.rules   (compiled + validated by Firebase Rules API)
        deploys firestore.indexes.json  (composite indexes only — single-field auto-managed by Firestore)
```
