import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('firebase-functions/v2', () => ({
  logger: { info: vi.fn(), warn: vi.fn(), error: vi.fn() },
}));
vi.mock('firebase-functions/v2/firestore', () => ({
  onDocumentUpdated: (_opts: unknown, h: unknown) => h,
}));
// defineSecret/defineString are evaluated at module load; stub them so the
// handler module imports without a live Functions runtime.
vi.mock('firebase-functions/params', () => ({
  defineSecret: () => ({ value: () => 'test-key' }),
  defineString: () => ({ value: () => 'https://worker.test' }),
}));
vi.mock('../../src/admin', () => ({
  db: {},
  FieldValue: { serverTimestamp: () => 'SERVER_TS' },
}));

import {
  onPostUpdatedHandler,
  type AiVerdict,
} from '../../src/triggers/onPostUpdated';

function deps() {
  return {
    moderate: vi.fn<
      (input: unknown) => Promise<AiVerdict>
    >().mockResolvedValue({ recommended: 'approve', confidence: 0.8, reason: 'ok' }),
    writeVerdict: vi.fn().mockResolvedValue(undefined),
  };
}

const base = {
  title: 'Calculus Notes',
  description: 'week 3',
  tags: ['calculus'],
  postType: 'lectureNote',
  status: 'pending',
};

describe('onPostUpdatedHandler', () => {
  let d: ReturnType<typeof deps>;
  beforeEach(() => {
    d = deps();
  });

  it('moderates on the pending→done settling edge and writes the verdict', async () => {
    await onPostUpdatedHandler(
      'p1',
      { ...base, summaryStatus: 'pending' },
      { ...base, summaryStatus: 'done', extractedText: 'real document text' },
      d,
    );
    expect(d.moderate).toHaveBeenCalledWith(
      expect.objectContaining({ title: 'Calculus Notes', extractedText: 'real document text' }),
    );
    expect(d.writeVerdict).toHaveBeenCalledWith('p1', {
      recommended: 'approve',
      confidence: 0.8,
      reason: 'ok',
    });
  });

  it('takes the flagged shortcut without calling the classifier', async () => {
    await onPostUpdatedHandler(
      'p1',
      { ...base, summaryStatus: 'pending' },
      { ...base, summaryStatus: 'flagged' },
      d,
    );
    expect(d.moderate).not.toHaveBeenCalled();
    expect(d.writeVerdict).toHaveBeenCalledWith(
      'p1',
      expect.objectContaining({ recommended: 'reject' }),
    );
  });

  it('does nothing when summaryStatus did not change (no settling edge)', async () => {
    await onPostUpdatedHandler(
      'p1',
      { ...base, summaryStatus: 'done', likesCount: 1 } as never,
      { ...base, summaryStatus: 'done', likesCount: 2 } as never,
      d,
    );
    expect(d.moderate).not.toHaveBeenCalled();
    expect(d.writeVerdict).not.toHaveBeenCalled();
  });

  it('is idempotent — skips when a verdict already exists', async () => {
    await onPostUpdatedHandler(
      'p1',
      { ...base, summaryStatus: 'pending' },
      { ...base, summaryStatus: 'done', aiVerdict: { recommended: 'approve' } },
      d,
    );
    expect(d.moderate).not.toHaveBeenCalled();
    expect(d.writeVerdict).not.toHaveBeenCalled();
  });

  it('skips when a human already moderated (status no longer pending)', async () => {
    await onPostUpdatedHandler(
      'p1',
      { ...base, summaryStatus: 'pending' },
      { ...base, status: 'approved', summaryStatus: 'done' },
      d,
    );
    expect(d.moderate).not.toHaveBeenCalled();
    expect(d.writeVerdict).not.toHaveBeenCalled();
  });

  it('fails open to a defer-to-human verdict when the classifier throws', async () => {
    d.moderate.mockRejectedValueOnce(new Error('worker 502'));
    await onPostUpdatedHandler(
      'p1',
      { ...base, summaryStatus: 'pending' },
      { ...base, summaryStatus: 'done' },
      d,
    );
    expect(d.writeVerdict).toHaveBeenCalledWith(
      'p1',
      expect.objectContaining({ recommended: 'approve', confidence: 0 }),
    );
  });
});
