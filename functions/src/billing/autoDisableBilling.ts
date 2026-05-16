import { onMessagePublished } from 'firebase-functions/v2/pubsub';
import { logger } from 'firebase-functions/v2';
import { CloudBillingClient } from '@google-cloud/billing';

import { BILLING_BUDGET_TOPIC } from '../config';

interface BudgetAlert {
  budgetDisplayName?: string;
  costAmount?: number;
  budgetAmount?: number;
  budgetAmountType?: string;
  currencyCode?: string;
  alertThresholdExceeded?: number;
}

/**
 * Listens to budget-alert messages published by GCP Billing on the
 * `billing-budget-alerts` Pub/Sub topic. When monthly spend meets or
 * exceeds the configured budget amount, detaches the billing account
 * from the project. This halts all paid services — Cloud Functions
 * stops, Firestore reverts to Spark-tier limits — and protects the
 * user from runaway charges.
 *
 * IAM: this function's runtime service account must hold
 * `roles/billing.projectManager` on the billing account (not the
 * project). Grant once after first deploy.
 */
export const autoDisableBilling = onMessagePublished(
  {
    topic: BILLING_BUDGET_TOPIC,
  },
  async (event) => {
    const payload = event.data.message.json as BudgetAlert | undefined;
    if (!payload) {
      logger.warn('autoDisableBilling: empty or non-JSON message', {
        messageId: event.data.message.messageId,
      });
      return;
    }

    const { costAmount, budgetAmount, budgetDisplayName } = payload;

    if (typeof costAmount !== 'number' || typeof budgetAmount !== 'number') {
      logger.info('autoDisableBilling: alert missing cost/budget fields, ignoring', {
        budgetDisplayName,
      });
      return;
    }

    if (costAmount < budgetAmount) {
      logger.info('autoDisableBilling: under budget, no action', {
        budgetDisplayName,
        costAmount,
        budgetAmount,
      });
      return;
    }

    const projectId = process.env.GCLOUD_PROJECT;
    if (!projectId) {
      logger.error('autoDisableBilling: GCLOUD_PROJECT env var not set');
      return;
    }

    const projectName = `projects/${projectId}`;
    const billing = new CloudBillingClient();

    const [info] = await billing.getProjectBillingInfo({ name: projectName });
    if (!info.billingEnabled) {
      logger.info('autoDisableBilling: billing already disabled', { projectId });
      return;
    }

    await billing.updateProjectBillingInfo({
      name: projectName,
      projectBillingInfo: { billingAccountName: '' },
    });

    logger.warn('autoDisableBilling: billing DETACHED from project', {
      projectId,
      budgetDisplayName,
      costAmount,
      budgetAmount,
    });
  },
);
