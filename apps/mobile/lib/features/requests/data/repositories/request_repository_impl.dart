import 'package:firebase_auth/firebase_auth.dart';

import 'package:unishare_mobile/features/requests/data/datasources/request_firestore_datasource.dart';
import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/domain/entities/suggestion.dart';
import 'package:unishare_mobile/features/requests/domain/repositories/request_repository.dart';

class RequestRepositoryImpl implements RequestRepository {
  RequestRepositoryImpl({required this.datasource, FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final RequestFirestoreDatasource datasource;
  final FirebaseAuth _auth;

  @override
  Stream<List<ContentRequest>> watchRequests({
    String? departmentId,
    String? year,
    String? courseId,
    RequestStatus? status,
  }) => datasource.watchRequests(
    departmentId: departmentId,
    year: year,
    courseId: courseId,
    status: status,
  );

  @override
  Future<void> createRequest({
    required String departmentId,
    required String departmentName,
    required String year,
    required String courseId,
    required String courseName,
    required String title,
    String? description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('not_authenticated');
    await datasource.createRequest(
      departmentId: departmentId,
      departmentName: departmentName,
      year: year,
      courseId: courseId,
      courseName: courseName,
      title: title,
      description: description,
      requesterName: user.displayName ?? user.email ?? '',
      requesterAvatar: user.photoURL,
    );
  }

  @override
  Stream<List<Suggestion>> watchSuggestions(String requestId) =>
      datasource.watchSuggestions(requestId);

  @override
  Future<void> suggestFulfillment({
    required String requestId,
    required String postId,
    required String postTitle,
    required String postType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('not_authenticated');
    await datasource.suggestFulfillment(
      requestId: requestId,
      postId: postId,
      postTitle: postTitle,
      postType: postType,
      suggestedByName: user.displayName ?? user.email ?? '',
      suggestedByAvatar: user.photoURL,
    );
  }

  @override
  Future<void> toggleUpvote(String requestId) =>
      datasource.toggleUpvote(requestId);

  @override
  Future<bool> hasUpvoted(String requestId) => datasource.hasUpvoted(requestId);
}
