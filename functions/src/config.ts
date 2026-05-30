import { setGlobalOptions } from "firebase-functions/v2";

export const REGION = "asia-southeast1";

setGlobalOptions({
  region: REGION,
  maxInstances: 10,
});

export const BILLING_BUDGET_TOPIC = "billing-budget-alerts";

export const NOTIFICATION_RETENTION_DAYS = 30;

// Days a rejected post's media stays in R2 before the scheduled sweep purges
// it. Leaves an appeal/resubmit window while bounding storage of unpublished
// (and potentially abusive) content.
export const REJECTED_MEDIA_RETENTION_DAYS = 14;
