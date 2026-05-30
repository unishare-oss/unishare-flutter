import { describe, it, expect } from 'vitest';

import {
  canModerate,
  isAdminRole,
  isAssignableRole,
  ASSIGNABLE_ROLES,
} from '../../src/lib/roles';

describe('roles', () => {
  it('canModerate is true for moderator and admin only', () => {
    expect(canModerate('moderator')).toBe(true);
    expect(canModerate('admin')).toBe(true);
    expect(canModerate('student')).toBe(false);
    expect(canModerate(undefined)).toBe(false);
    expect(canModerate(null)).toBe(false);
    expect(canModerate('Moderator')).toBe(false); // case-sensitive
  });

  it('isAdminRole is true for admin only', () => {
    expect(isAdminRole('admin')).toBe(true);
    expect(isAdminRole('moderator')).toBe(false);
    expect(isAdminRole('student')).toBe(false);
    expect(isAdminRole(undefined)).toBe(false);
  });

  it('isAssignableRole accepts exactly the known roles', () => {
    for (const r of ASSIGNABLE_ROLES) expect(isAssignableRole(r)).toBe(true);
    expect(isAssignableRole('superuser')).toBe(false);
    expect(isAssignableRole('')).toBe(false);
    expect(isAssignableRole(42)).toBe(false);
  });
});
