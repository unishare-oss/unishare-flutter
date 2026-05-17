import { setGlobalOptions } from 'firebase-functions/v2';

export const REGION = 'asia-southeast1';

setGlobalOptions({
  region: REGION,
  maxInstances: 10,
});

export const BILLING_BUDGET_TOPIC = 'billing-budget-alerts';

export const NOTIFICATION_RETENTION_DAYS = 30;
