/**
 * Public-safe projection of a `users/{uid}` document. Mirrored into
 * `users_public/{uid}` by the [onUserChangedPublicSync] trigger so other
 * authenticated users can read the safe subset without exposing private
 * fields like `email`, `stats`, `totalPoints`, or `earnedBadgesCache`.
 *
 * Pure — server-only. Returns null when there isn't enough info to expose
 * the user publicly yet (e.g., between auth-account-create and profile-
 * setup).
 */
export interface PublicUserDoc {
  uid: string;
  name: string;
  photoUrl: string | null;
  bio: string | null;
  level: number;
  selectedTitle: string | null;
  displayedBadges: string[];
}

export function publicUserProjection(
  uid: string,
  data: Record<string, unknown> | undefined,
): PublicUserDoc | null {
  if (!data) return null;
  const name = data.name;
  if (typeof name !== 'string' || name.length === 0) return null;

  const photoUrl = typeof data.photoUrl === 'string' && data.photoUrl.length > 0
    ? data.photoUrl
    : null;

  const rawBio = typeof data.bio === 'string' ? data.bio.trim() : '';
  const bio = rawBio.length > 0 ? rawBio : null;

  const g = (data.gamification ?? {}) as Record<string, unknown>;
  const level = typeof g.level === 'number' && g.level >= 1 ? g.level : 1;
  const selectedTitle = typeof g.selectedTitle === 'string' && g.selectedTitle.length > 0
    ? g.selectedTitle
    : null;
  const displayedBadgesRaw = g.displayedBadges;
  const displayedBadges = Array.isArray(displayedBadgesRaw)
    ? displayedBadgesRaw.filter((b): b is string => typeof b === 'string')
    : [];

  return {
    uid,
    name,
    photoUrl,
    bio,
    level,
    selectedTitle,
    displayedBadges,
  };
}

/**
 * Equality check for two projections — used by the sync trigger's
 * diff-and-skip path. Order-sensitive on `displayedBadges` because the
 * displayed list is user-curated; reordering counts as a real change.
 */
export function publicUserProjectionsEqual(
  a: PublicUserDoc | null,
  b: PublicUserDoc | null,
): boolean {
  if (a === b) return true;
  if (!a || !b) return false;
  if (a.uid !== b.uid) return false;
  if (a.name !== b.name) return false;
  if (a.photoUrl !== b.photoUrl) return false;
  if (a.bio !== b.bio) return false;
  if (a.level !== b.level) return false;
  if (a.selectedTitle !== b.selectedTitle) return false;
  if (a.displayedBadges.length !== b.displayedBadges.length) return false;
  for (let i = 0; i < a.displayedBadges.length; i++) {
    if (a.displayedBadges[i] !== b.displayedBadges[i]) return false;
  }
  return true;
}
