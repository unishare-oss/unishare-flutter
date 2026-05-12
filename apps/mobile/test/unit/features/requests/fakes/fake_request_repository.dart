import 'dart:async';

import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/domain/entities/suggestion.dart';
import 'package:unishare_mobile/features/requests/domain/repositories/request_repository.dart';

class FakeRequestRepository implements RequestRepository {
  final StreamController<List<ContentRequest>> requestsController =
      StreamController<List<ContentRequest>>.broadcast();

  final StreamController<List<Suggestion>> suggestionsController =
      StreamController<List<Suggestion>>.broadcast();

  bool createRequestCalled = false;
  bool suggestFulfillmentCalled = false;
  bool toggleUpvoteCalled = false;
  bool hasUpvotedResult = false;
  String? lastCreateRequestTitle;
  String? lastSuggestRequestId;
  String? lastSuggestPostId;
  String? lastSuggestPostTitle;
  String? lastSuggestPostType;
  String? lastToggleUpvoteRequestId;

  @override
  Stream<List<ContentRequest>> watchRequests({
    String? departmentId,
    String? year,
    String? courseId,
    RequestStatus? status,
  }) => requestsController.stream;

  @override
  Stream<ContentRequest> watchRequest(String requestId) =>
      requestsController.stream.map(
        (list) => list.firstWhere(
          (r) => r.id == requestId,
          orElse: () => throw StateError('request_not_found'),
        ),
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
    createRequestCalled = true;
    lastCreateRequestTitle = title;
  }

  @override
  Stream<List<Suggestion>> watchSuggestions(String requestId) =>
      suggestionsController.stream;

  @override
  Future<void> suggestFulfillment({
    required String requestId,
    required String postId,
    required String postTitle,
    required String postType,
  }) async {
    suggestFulfillmentCalled = true;
    lastSuggestRequestId = requestId;
    lastSuggestPostId = postId;
    lastSuggestPostTitle = postTitle;
    lastSuggestPostType = postType;
  }

  @override
  Future<void> toggleUpvote(String requestId) async {
    toggleUpvoteCalled = true;
    lastToggleUpvoteRequestId = requestId;
  }

  @override
  Future<bool> hasUpvoted(String requestId) async => hasUpvotedResult;

  @override
  Future<void> deleteRequest(String requestId) async {}

  @override
  Future<void> acceptSuggestion({
    required String requestId,
    required String suggestionId,
    required String postId,
    required String postTitle,
  }) async {}

  @override
  Future<void> removeSuggestion({
    required String requestId,
    required String suggestionId,
  }) async {}
}

// ---------------------------------------------------------------------------
// Factories
// ---------------------------------------------------------------------------

ContentRequest fakeRequest({
  String id = 'req-1',
  RequestStatus status = RequestStatus.open,
  int upvoteCount = 0,
}) {
  final now = DateTime(2026, 5, 9);
  return ContentRequest(
    id: id,
    requesterId: 'user-1',
    requesterName: 'Alice',
    departmentId: 'dept-1',
    departmentName: 'Computer Science',
    year: '2',
    courseId: 'CSC234',
    courseName: 'CSC234',
    title: 'Data Structures notes',
    status: status,
    upvoteCount: upvoteCount,
    createdAt: now,
    updatedAt: now,
  );
}

Suggestion fakeSuggestion({String id = 'sug-1'}) {
  return Suggestion(
    id: id,
    postId: 'post-1',
    postTitle: 'DS midterm notes',
    postType: 'lectureNote',
    suggestedByUserId: 'user-2',
    suggestedByName: 'Bob',
    createdAt: DateTime(2026, 5, 9),
  );
}
