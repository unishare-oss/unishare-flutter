# Cloud Functions

TypeScript Firebase Cloud Functions (Gen 2, Node 20) for the Unishare notification system and billing safety net.

Deploys to `asia-southeast1`. See [`../tech-specs/0001-notification.md`](../tech-specs/0001-notification.md) for the full design contract.

## Function Map

| Function | Trigger | What it does |
|---|---|---|
| `onCommentAdded` | onCreate `posts/{postId}/comments/{commentId}` | Top-level comment → notify post owner |
| `onCommentReply` | onCreate same path, when `parentId` is set | Reply → notify parent author |
| `onPostLiked` | onCreate `posts/{postId}/likes/{userId}` | Like → notify post owner |
| `onRequestUpvoted` | onCreate `requests/{requestId}/upvotes/{userId}` | Upvote → notify requester |
| `onSuggestionSubmitted` | onCreate `requests/{requestId}/suggestions/{suggestionId}` | Suggestion → notify requester |
| `onRequestFulfilled` | onUpdate `requests/{requestId}` when `status` → `fulfilled` | Notify the winning suggester |
| `purgeOldNotifications` | Scheduled, every 24 h | Delete notifications older than 30 days |
| `autoDisableBilling` | Pub/Sub on topic `billing-budget-alerts` | Detach billing account if budget exceeded |

Each notification trigger writes one document to `users/{recipientUid}/notifications/{notifId}` via the Admin SDK and fans out an FCM multicast to the recipient's `fcmTokens` subcollection. Stale tokens (rejected with `messaging/registration-token-not-registered`) are pruned automatically.

## Local Development

Install once at the repo root:

```bash
cd functions
npm install
```

Run the lint + build:

```bash
npm run lint
npm run build
```

Run unit tests:

```bash
npm test
```

Start the Firebase emulator suite to exercise triggers end-to-end against a local Firestore:

```bash
# From the repo root, because firebase.json lives there.
firebase emulators:start --only auth,firestore,functions,pubsub
```

The Emulator UI is at <http://localhost:4000>. Write a synthetic comment to `posts/<postId>/comments/<commentId>` and watch the `users/<owner>/notifications` subcollection populate in real time.

## Deploy

Prerequisites — done once per environment:

1. **Firebase Blaze plan** must be active on the project. Cloud Functions cannot deploy on Spark.
2. **Cloud Billing budget** at $1/month with a Pub/Sub topic named `billing-budget-alerts`. Create from Cloud Console → Billing → Budgets & alerts. The `autoDisableBilling` function subscribes to this topic.
3. **IAM grant for `autoDisableBilling`.** The Gen 2 runtime service account needs `roles/billing.projectManager` (a.k.a. "Project Billing Manager") on the **billing account** (not the project). Grant once.

   The default Gen 2 runtime SA is the **compute** service account:
   `PROJECT_NUMBER-compute@developer.gserviceaccount.com`

   Find your project number in Firebase Console → Project Settings → General (or grep `firebase apps:list` output for the numeric segment in app IDs like `1:NUMBER:android:...`).

   **Console (no gcloud needed):**
   - <https://console.cloud.google.com/billing> → click your billing account
   - Account management → **+ Add Principal**
   - Principal: `PROJECT_NUMBER-compute@developer.gserviceaccount.com`
   - Role: search "Project Billing Manager"

   **CLI (if gcloud installed):**
   ```bash
   gcloud beta billing accounts add-iam-policy-binding BILLING_ACCOUNT_ID \
     --member=serviceAccount:PROJECT_NUMBER-compute@developer.gserviceaccount.com \
     --role=roles/billing.projectManager
   ```

   Without this binding the function will fail with `PERMISSION_DENIED` when attempting to detach billing.

Then deploy:

```bash
firebase deploy --only functions
```

To deploy a single function (faster):

```bash
firebase deploy --only functions:onCommentAdded
```

## Logs

```bash
firebase functions:log
firebase functions:log --only autoDisableBilling
```

## How the Billing Safety Net Works

1. Monthly spend approaches the $1 budget.
2. Cloud Billing publishes a JSON message to `billing-budget-alerts` containing `costAmount`, `budgetAmount`, `budgetDisplayName`.
3. `autoDisableBilling` parses the message; if `costAmount >= budgetAmount`, it calls `cloudbilling.projects.updateBillingInfo` with an empty `billingAccountName` to detach billing from the project.
4. Once billing is detached, Cloud Functions stops executing, Firestore reverts to Spark-tier limits, and no further spend can accrue.
5. Re-attach manually from Firebase Console when ready to resume.

Budget data lags by hours, so a small overshoot is possible. The cap is a safety net, not a hard ceiling.
