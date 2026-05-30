import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db, FieldValue } from '../admin';
import { isAdminRole, isAssignableRole, ASSIGNABLE_ROLES, type UserRole } from '../lib/roles';

interface Input {
  targetUid: string;
  role: UserRole;
}

interface SetUserRoleDeps {
  /** Role of the calling user, or undefined if the user doc is missing. */
  getCallerRole: (uid: string) => Promise<unknown>;
  /** True if the target user exists. */
  targetExists: (uid: string) => Promise<boolean>;
  /** Persists the new role onto the target user. */
  writeRole: (targetUid: string, role: UserRole, by: string) => Promise<void>;
}

/// Pure authorization + validation logic, extracted for unit testing.
/// Role changes are deliberately server-only: firestore.rules block every
/// client write to `users/{uid}.role`, so this admin-gated callable is the
/// only path that can change a role.
export async function setUserRoleHandler(
  callerUid: string | undefined,
  data: Partial<Input>,
  deps: SetUserRoleDeps,
): Promise<{ ok: true }> {
  if (!callerUid) throw new HttpsError('unauthenticated', 'Sign in required');

  const callerRole = await deps.getCallerRole(callerUid);
  if (!isAdminRole(callerRole)) {
    logger.warn('setUserRole denied — caller is not an admin', { callerUid });
    throw new HttpsError('permission-denied', 'Admin role required');
  }

  const { targetUid, role } = data;
  if (typeof targetUid !== 'string' || targetUid.length === 0) {
    throw new HttpsError('invalid-argument', 'targetUid required');
  }
  if (!isAssignableRole(role)) {
    throw new HttpsError(
      'invalid-argument',
      `role must be one of: ${ASSIGNABLE_ROLES.join(', ')}`,
    );
  }
  // Guard against an admin locking the project out of admin access by
  // demoting themselves. They must promote another admin first.
  if (targetUid === callerUid && role !== 'admin') {
    throw new HttpsError(
      'failed-precondition',
      'Admins cannot remove their own admin role',
    );
  }

  if (!(await deps.targetExists(targetUid))) {
    throw new HttpsError('not-found', 'Target user not found');
  }

  await deps.writeRole(targetUid, role, callerUid);
  logger.info('user role updated', { targetUid, role, by: callerUid });
  return { ok: true };
}

export const setUserRole = onCall<Input>(async (request) =>
  setUserRoleHandler(request.auth?.uid, request.data ?? {}, {
    getCallerRole: async (uid) =>
      (await db.collection('users').doc(uid).get()).data()?.role,
    targetExists: async (uid) =>
      (await db.collection('users').doc(uid).get()).exists,
    writeRole: async (targetUid, role, by) => {
      await db.collection('users').doc(targetUid).update({
        role,
        roleUpdatedAt: FieldValue.serverTimestamp(),
        roleUpdatedBy: by,
      });
    },
  }),
);
