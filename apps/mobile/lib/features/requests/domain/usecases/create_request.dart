// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/requests/domain/repositories/request_repository.dart';

class CreateRequest {
  const CreateRequest(this._repository);
  final RequestRepository _repository;

  Future<void> call({
    required String departmentId,
    required String departmentName,
    required String year,
    required String courseId,
    required String courseName,
    required String title,
    String? description,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Title must not be empty.');
    }
    if (title.length > 120) {
      throw ArgumentError('Title must be 120 characters or fewer.');
    }
    if (description != null && description.length > 500) {
      throw ArgumentError('Description must be 500 characters or fewer.');
    }
    return _repository.createRequest(
      departmentId: departmentId,
      departmentName: departmentName,
      year: year,
      courseId: courseId,
      courseName: courseName,
      title: title.trim(),
      description: description,
    );
  }
}
