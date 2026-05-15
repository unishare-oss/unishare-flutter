import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/auth/domain/entities/app_user.dart';

part 'profile_form_provider.g.dart';

/// Mutable form state for the profile edit screen. Text controllers live in
/// the widget (TextEditingController has its own lifecycle and isn't a good
/// fit for Riverpod), but everything else lives here so the screen doesn't
/// need setState.
class ProfileFormState {
  const ProfileFormState({
    this.universityId,
    this.departmentId,
    this.enrollmentYearText = '',
    this.saving = false,
    this.seededFromUid,
  });

  final String? universityId;
  final String? departmentId;

  /// Raw enrollment-year input as typed by the user. Stored as text so
  /// unparseable input (e.g. "20a3") survives a rebuild and is surfaced to
  /// validation rather than being silently coerced to null.
  final String enrollmentYearText;

  final bool saving;

  /// UID of the [AppUser] the form was last seeded from. Used so the form
  /// re-initializes when the signed-in user changes — without this, a
  /// sign-out/sign-in-as-different-user flow would leave stale form state.
  /// Null means "never seeded".
  final String? seededFromUid;

  ProfileFormState copyWith({
    Object? universityId = _sentinel,
    Object? departmentId = _sentinel,
    String? enrollmentYearText,
    bool? saving,
    Object? seededFromUid = _sentinel,
  }) {
    return ProfileFormState(
      universityId: identical(universityId, _sentinel)
          ? this.universityId
          : universityId as String?,
      departmentId: identical(departmentId, _sentinel)
          ? this.departmentId
          : departmentId as String?,
      enrollmentYearText: enrollmentYearText ?? this.enrollmentYearText,
      saving: saving ?? this.saving,
      seededFromUid: identical(seededFromUid, _sentinel)
          ? this.seededFromUid
          : seededFromUid as String?,
    );
  }

  static const _sentinel = Object();
}

@riverpod
class ProfileForm extends _$ProfileForm {
  @override
  ProfileFormState build() => const ProfileFormState();

  /// Seed from the loaded user. Re-seeds when [user]'s uid differs from the
  /// previously seeded uid (e.g., user signed out and signed in as someone
  /// else). Subsequent calls with the same uid are no-ops so user edits
  /// aren't overwritten when the auth stream re-emits.
  void initFromUser(AppUser user) {
    if (state.seededFromUid == user.id) return;
    state = ProfileFormState(
      universityId: user.universityId,
      departmentId: user.departmentId,
      enrollmentYearText: user.enrollmentYear?.toString() ?? '',
      seededFromUid: user.id,
    );
  }

  void setUniversity(String? id) {
    // Reset department — the previous one may belong to a different uni.
    state = state.copyWith(universityId: id, departmentId: null);
  }

  void setDepartment(String? id) => state = state.copyWith(departmentId: id);

  void setEnrollmentYearText(String text) =>
      state = state.copyWith(enrollmentYearText: text);

  void setSaving(bool saving) => state = state.copyWith(saving: saving);
}
