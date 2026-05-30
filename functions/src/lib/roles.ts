/// Role model shared by callables and triggers. Mirrors the hierarchy in
/// firestore.rules: `admin` is a superset of `moderator`.
///
/// Single source of truth for the literal role strings so a rename can't drift
/// between the rules, the callables, and the app.
export type UserRole = 'student' | 'moderator' | 'admin';

/// Roles that setUserRole is allowed to assign.
export const ASSIGNABLE_ROLES: readonly UserRole[] = ['student', 'moderator', 'admin'];

/// True when the role may perform moderation actions (approve/reject posts,
/// view the pending queue). Admins inherit moderator capability.
export function canModerate(role: unknown): boolean {
  return role === 'moderator' || role === 'admin';
}

/// True for the full-project superuser role.
export function isAdminRole(role: unknown): boolean {
  return role === 'admin';
}

export function isAssignableRole(role: unknown): role is UserRole {
  return ASSIGNABLE_ROLES.includes(role as UserRole);
}
