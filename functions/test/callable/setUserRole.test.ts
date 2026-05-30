import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('firebase-functions/v2', () => ({
  logger: { info: vi.fn(), warn: vi.fn(), error: vi.fn() },
}));
// Real throwable HttpsError carrying a `code`, and a passthrough onCall.
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
  FieldValue: { serverTimestamp: () => 'SERVER_TS' },
}));

import { setUserRoleHandler } from '../../src/callable/setUserRole';

function deps(callerRole: unknown, opts: { targetExists?: boolean } = {}) {
  return {
    getCallerRole: vi.fn().mockResolvedValue(callerRole),
    targetExists: vi.fn().mockResolvedValue(opts.targetExists ?? true),
    writeRole: vi.fn().mockResolvedValue(undefined),
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

describe('setUserRoleHandler', () => {
  let d: ReturnType<typeof deps>;
  beforeEach(() => {
    d = deps('admin');
  });

  it('lets an admin set a valid role on an existing user', async () => {
    const res = await setUserRoleHandler('admin1', { targetUid: 'u2', role: 'moderator' }, d);
    expect(res).toEqual({ ok: true });
    expect(d.writeRole).toHaveBeenCalledWith('u2', 'moderator', 'admin1');
  });

  it('rejects an unauthenticated caller', async () => {
    expect(await codeOf(setUserRoleHandler(undefined, { targetUid: 'u2', role: 'admin' }, d)))
      .toBe('unauthenticated');
  });

  it('rejects a non-admin caller', async () => {
    const md = deps('moderator');
    expect(await codeOf(setUserRoleHandler('m1', { targetUid: 'u2', role: 'admin' }, md)))
      .toBe('permission-denied');
    expect(md.writeRole).not.toHaveBeenCalled();
  });

  it('rejects an unknown role', async () => {
    expect(await codeOf(setUserRoleHandler('admin1', { targetUid: 'u2', role: 'superuser' as never }, d)))
      .toBe('invalid-argument');
  });

  it('rejects a missing targetUid', async () => {
    expect(await codeOf(setUserRoleHandler('admin1', { role: 'admin' }, d)))
      .toBe('invalid-argument');
  });

  it('prevents an admin from demoting themselves', async () => {
    expect(await codeOf(setUserRoleHandler('admin1', { targetUid: 'admin1', role: 'student' }, d)))
      .toBe('failed-precondition');
    expect(d.writeRole).not.toHaveBeenCalled();
  });

  it('allows an admin to re-affirm their own admin role (no-op)', async () => {
    const res = await setUserRoleHandler('admin1', { targetUid: 'admin1', role: 'admin' }, d);
    expect(res).toEqual({ ok: true });
  });

  it('404s when the target user does not exist', async () => {
    const nd = deps('admin', { targetExists: false });
    expect(await codeOf(setUserRoleHandler('admin1', { targetUid: 'ghost', role: 'moderator' }, nd)))
      .toBe('not-found');
  });
});
