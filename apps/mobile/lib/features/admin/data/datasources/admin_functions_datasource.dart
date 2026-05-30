import 'package:cloud_functions/cloud_functions.dart';

/// Privileged admin operations that run server-side via callable Cloud
/// Functions (admin SDK bypasses security rules). Same region as the
/// moderation callable.
class AdminFunctionsDatasource {
  AdminFunctionsDatasource({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFunctions _functions;

  /// Calls the admin-gated `setUserRole` callable (functions/src/callable).
  /// `role` must be one of: student | moderator | admin.
  Future<void> setUserRole(String uid, String role) async {
    await _functions.httpsCallable('setUserRole').call({
      'targetUid': uid,
      'role': role,
    });
  }

  /// TODO(admin-ban): no backend yet. To finish this:
  ///   1. Add a `setUserBanned` callable (admin-gated, sets users/{uid}.banned).
  ///   2. Enforce it — block banned users at sign-in (and/or disable the
  ///      Firebase Auth account), and consider a rules check so banned users
  ///      can't write posts/comments.
  ///   3. Replace the throw below with:
  ///        await _functions.httpsCallable('setUserBanned')
  ///            .call({'targetUid': uid, 'banned': banned});
  Future<void> setUserBanned(String uid, bool banned) async {
    throw UnimplementedError(
      'setUserBanned: implement the setUserBanned callable + enforcement first.',
    );
  }
}
