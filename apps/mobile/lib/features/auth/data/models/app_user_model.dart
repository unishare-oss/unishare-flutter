import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/app_user.dart';

part 'app_user_model.freezed.dart';
part 'app_user_model.g.dart';

@freezed
abstract class AppUserModel with _$AppUserModel {
  const AppUserModel._();

  const factory AppUserModel({
    required String id,
    required String name,
    required String email,
    String? photoUrl,
    String? universityId,
    String? departmentId,
    int? enrollmentYear,
    @Default('student') String role,
  }) = _AppUserModel;

  factory AppUserModel.fromJson(Map<String, dynamic> json) =>
      _$AppUserModelFromJson(json);

  factory AppUserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AppUserModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      universityId: data['universityId'] as String?,
      departmentId: data['departmentId'] as String?,
      enrollmentYear: data['enrollmentYear'] as int?,
      role: data['role'] as String? ?? 'student',
    );
  }

  AppUser toEntity() => AppUser(
    id: id,
    name: name,
    email: email,
    photoUrl: photoUrl,
    universityId: universityId,
    departmentId: departmentId,
    enrollmentYear: enrollmentYear,
    role: role,
  );
}
