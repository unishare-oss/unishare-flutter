// Pure Dart — zero Flutter or Firebase imports.

import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/domain/entities/suggestion.dart';

abstract interface class RequestRepository {
  /// Streams all requests, optionally filtered. Ordered by createdAt DESC.
  Stream<List<ContentRequest>> watchRequests({
    String? departmentId,
    String? year,
    String? courseId,
    RequestStatus? status,
  });

  Future<void> createRequest({
    required String departmentId,
    required String departmentName,
    required String year,
    required String courseId,
    required String courseName,
    required String title,
    String? description,
  });

  /// Streams all suggestions for a given request, ordered by createdAt ASC.
  Stream<List<Suggestion>> watchSuggestions(String requestId);

  /// Links one of the current user's posts as a fulfillment suggestion.
  /// If this is the first suggestion, also sets request status → fulfilled.
  Future<void> suggestFulfillment({
    required String requestId,
    required String postId,
    required String postTitle,
    required String postType,
  });

  Future<void> toggleUpvote(String requestId);
  Future<bool> hasUpvoted(String requestId);

  /// Deletes a request. Only the request owner may call this.
  Future<void> deleteRequest(String requestId);

  /// Owner accepts a suggestion — sets request status to fulfilled.
  Future<void> acceptSuggestion({
    required String requestId,
    required String suggestionId,
    required String postId,
    required String postTitle,
  });

  /// Owner removes a suggestion from the list.
  Future<void> removeSuggestion({
    required String requestId,
    required String suggestionId,
  });
}
