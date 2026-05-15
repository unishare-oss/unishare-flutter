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
    this.enrollmentYear,
    this.saving = false,
    this.initialized = false,
  });

  final String? universityId;
  final String? departmentId;
  final int? enrollmentYear;
  final bool saving;

  /// True once the form has been seeded from the loaded [AppUser]. Prevents
  /// re-initialization clobbering user edits when the screen rebuilds.
  final bool initialized;

  ProfileFormState copyWith({
    Object? universityId = _sentinel,
    Object? departmentId = _sentinel,
    Object? enrollmentYear = _sentinel,
    bool? saving,
    bool? initialized,
  }) {
    return ProfileFormState(
      universityId: identical(universityId, _sentinel)
          ? this.universityId
          : universityId as String?,
      departmentId: identical(departmentId, _sentinel)
          ? this.departmentId
          : departmentId as String?,
      enrollmentYear: identical(enrollmentYear, _sentinel)
          ? this.enrollmentYear
          : enrollmentYear as int?,
      saving: saving ?? this.saving,
      initialized: initialized ?? this.initialized,
    );
  }

  static const _sentinel = Object();
}

@riverpod
class ProfileForm extends _$ProfileForm {
  @override
  ProfileFormState build() => const ProfileFormState();

  /// Seed once from the loaded user. Subsequent calls are no-ops so user
  /// edits aren't overwritten when the auth stream re-emits.
  void initFromUser(AppUser user) {
    if (state.initialized) return;
    state = state.copyWith(
      universityId: user.universityId,
      departmentId: user.departmentId,
      enrollmentYear: user.enrollmentYear,
      initialized: true,
    );
  }

  void setUniversity(String? id) {
    // Reset department — the previous one may belong to a different uni.
    state = state.copyWith(universityId: id, departmentId: null);
  }

  void setDepartment(String? id) => state = state.copyWith(departmentId: id);

  void setEnrollmentYear(int? year) =>
      state = state.copyWith(enrollmentYear: year);

  void setSaving(bool saving) => state = state.copyWith(saving: saving);
}
