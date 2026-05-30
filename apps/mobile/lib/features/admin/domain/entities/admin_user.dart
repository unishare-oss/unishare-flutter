// Pure Dart — zero Flutter or Firebase imports.

/// A user as seen by the admin console. Carries the private fields (email,
/// role) that the owner-only `users` rule normally hides — surfaced here only
/// because the rules grant `isAdmin()` read access to the collection.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    this.banned = false,
  });

  final String id;
  final String name;
  final String email;

  /// 'student' | 'moderator' | 'admin' — see lib/features/auth (AppUser) and
  /// functions/src/lib/roles.ts for the canonical hierarchy.
  final String role;
  final String? photoUrl;

  /// TODO(admin-ban): there is no backend for this yet. The field is read
  /// defensively (defaults false) so the UI can render a ban toggle template.
  final bool banned;

  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator';
}
