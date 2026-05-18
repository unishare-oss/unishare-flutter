/// Public-safe projection of a user that any signed-in user can read.
/// Mirrors `users_public/{uid}` — see SPEC-0011.
class PublicUser {
  final String uid;
  final String name;
  final String? photoUrl;
  final String? bio;
  final int level;
  final String? selectedTitle;
  final List<String> displayedBadges;

  const PublicUser({
    required this.uid,
    required this.name,
    required this.photoUrl,
    required this.bio,
    required this.level,
    required this.selectedTitle,
    required this.displayedBadges,
  });
}
