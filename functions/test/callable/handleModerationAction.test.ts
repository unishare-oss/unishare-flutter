import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('firebase-functions/v2', () => ({
  logger: { info: vi.fn(), warn: vi.fn(), error: vi.fn() },
}));
vi.mock('firebase-functions/v2/https', () => ({
  HttpsError: class HttpsError extends Error {
    code: string;
    constructor(code: string, message: string) {
      super(message);
      this.code = code;
    }
  },
  onCall: (h: unknown) => h,
}));
vi.mock('../../src/admin', () => ({
  db: {},
  FieldValue: {
    serverTimestamp: () => 'SERVER_TS',
    delete: () => 'DELETE',
  },
}));

import {
  handleModerationActionHandler,
  type ModerationActionDeps,
} from '../../src/callable/handleModerationAction';

function deps(
  callerRole: unknown,
  post: { status?: string } | null,
): ModerationActionDeps {
  return {
    getCallerRole: vi.fn().mockResolvedValue(callerRole),
    getPost: vi.fn().mockResolvedValue(post),
    applyUpdate: vi.fn().mockResolvedValue(undefined),
  };
}

async function codeOf(p: Promise<unknown>): Promise<string> {
  try {
    await p;
    return 'NO_THROW';
  } catch (e) {
    return (e as { code: string }).code;
  }
}

describe('handleModerationActionHandler', () => {
  let d: ModerationActionDeps;
  beforeEach(() => {
    d = deps('moderator', { status: 'pending' });
  });

  it('approves a pending post', async () => {
    const res = await handleModerationActionHandler(
      'mod1',
      { postId: 'p1', action: 'approve' },
      d,
    );
    expect(res).toEqual({ ok: true });
    expect(d.applyUpdate).toHaveBeenCalledWith('p1', {
      status: 'approved',
      moderatedBy: 'mod1',
      moderatedAt: 'SERVER_TS',
    });
  });

  it('rejects a pending post with a reason', async () => {
    await handleModerationActionHandler(
      'mod1',
      { postId: 'p1', action: 'reject', reason: '  spam  ' },
      d,
    );
    expect(d.applyUpdate).toHaveBeenCalledWith('p1', {
      status: 'rejected',
      moderatedBy: 'mod1',
      moderatedAt: 'SERVER_TS',
      rejectionReason: 'spam',
    });
  });

  it('requires a non-blank reason on reject', async () => {
    expect(
      await codeOf(
        handleModerationActionHandler(
          'mod1',
          { postId: 'p1', action: 'reject', reason: '   ' },
          d,
        ),
      ),
    ).toBe('invalid-argument');
    expect(d.applyUpdate).not.toHaveBeenCalled();
  });

  it('restores a rejected post back to pending, clearing the decision', async () => {
    const rd = deps('admin', { status: 'rejected' });
    const res = await handleModerationActionHandler(
      'mod1',
      { postId: 'p1', action: 'restore' },
      rd,
    );
    expect(res).toEqual({ ok: true });
    expect(rd.applyUpdate).toHaveBeenCalledWith('p1', {
      status: 'pending',
      moderatedBy: 'DELETE',
      moderatedAt: 'DELETE',
      rejectionReason: 'DELETE',
    });
  });

  it('refuses to restore a post that is not rejected', async () => {
    // default deps has status 'pending'
    expect(
      await codeOf(
        handleModerationActionHandler(
          'mod1',
          { postId: 'p1', action: 'restore' },
          d,
        ),
      ),
    ).toBe('failed-precondition');
    expect(d.applyUpdate).not.toHaveBeenCalled();
  });

  it('refuses to approve a post that is not pending', async () => {
    const rd = deps('moderator', { status: 'rejected' });
    expect(
      await codeOf(
        handleModerationActionHandler(
          'mod1',
          { postId: 'p1', action: 'approve' },
          rd,
        ),
      ),
    ).toBe('failed-precondition');
  });

  it('rejects an unauthenticated caller', async () => {
    expect(
      await codeOf(
        handleModerationActionHandler(
          undefined,
          { postId: 'p1', action: 'approve' },
          d,
        ),
      ),
    ).toBe('unauthenticated');
  });

  it('rejects a non-moderator caller', async () => {
    const sd = deps('student', { status: 'pending' });
    expect(
      await codeOf(
        handleModerationActionHandler(
          'u1',
          { postId: 'p1', action: 'approve' },
          sd,
        ),
      ),
    ).toBe('permission-denied');
    expect(sd.applyUpdate).not.toHaveBeenCalled();
  });

  it('rejects an unknown action', async () => {
    expect(
      await codeOf(
        handleModerationActionHandler(
          'mod1',
          { postId: 'p1', action: 'nuke' as never },
          d,
        ),
      ),
    ).toBe('invalid-argument');
  });

  it('404s when the post does not exist', async () => {
    const nd = deps('moderator', null);
    expect(
      await codeOf(
        handleModerationActionHandler(
          'mod1',
          { postId: 'ghost', action: 'approve' },
          nd,
        ),
      ),
    ).toBe('not-found');
  });
});
