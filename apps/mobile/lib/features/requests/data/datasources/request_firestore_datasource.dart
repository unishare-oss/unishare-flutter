import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unishare_mobile/features/requests/data/models/request_dto.dart';
import 'package:unishare_mobile/features/requests/data/models/suggestion_dto.dart';
import 'package:unishare_mobile/features/requests/domain/entities/content_request.dart';
import 'package:unishare_mobile/features/requests/domain/entities/suggestion.dart';

class RequestFirestoreDatasource {
  RequestFirestoreDatasource({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('requests');

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('not_authenticated');
    return uid;
  }

  // ---------------------------------------------------------------------------
  // Watch requests
  // ---------------------------------------------------------------------------

  Stream<List<ContentRequest>> watchRequests({
    String? departmentId,
    String? year,
    String? courseId,
    RequestStatus? status,
  }) {
    Query<Map<String, dynamic>> q = _requests.orderBy(
      'createdAt',
      descending: true,
    );
    if (departmentId != null) {
      q = q.where('departmentId', isEqualTo: departmentId);
    }
    if (year != null) {
      q = q.where('year', isEqualTo: year);
    }
    if (courseId != null) {
      q = q.where('courseId', isEqualTo: courseId);
    }
    if (status != null) {
      q = q.where('status', isEqualTo: status.name);
    }
    return q.snapshots().map((snap) => snap.docs.map(_docToEntity).toList());
  }

  // ---------------------------------------------------------------------------
  // Create request
  // ---------------------------------------------------------------------------

  Future<void> createRequest({
    required String departmentId,
    required String departmentName,
    required String year,
    required String courseId,
    required String courseName,
    required String title,
    String? description,
    required String requesterName,
    String? requesterAvatar,
  }) async {
    final uid = _uid;
    final now = Timestamp.now();
    final ref = _requests.doc();
    await ref.set({
      'id': ref.id,
      'requesterId': uid,
      'requesterName': requesterName,
      'requesterAvatar': requesterAvatar,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'year': year,
      'courseId': courseId,
      'courseName': courseName,
      'title': title,
      'description': description,
      'status': 'open',
      'fulfilledByPostId': null,
      'fulfilledByPostTitle': null,
      'upvoteCount': 0,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  // ---------------------------------------------------------------------------
  // Watch suggestions
  // ---------------------------------------------------------------------------

  Stream<List<Suggestion>> watchSuggestions(String requestId) {
    return _requests
        .doc(requestId)
        .collection('suggestions')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => SuggestionDto.fromJson(doc.data()).toDomain())
              .toList(),
        );
  }

  // ---------------------------------------------------------------------------
  // Suggest fulfillment
  //
  // Firestore transactions cannot perform collection queries, so we:
  //   1. Write the suggestion document.
  //   2. Use AggregateQuery (count) to check if this was the first suggestion.
  //   3. If count == 1, use a transaction to atomically update the request doc.
  // ---------------------------------------------------------------------------

  Future<void> suggestFulfillment({
    required String requestId,
    required String postId,
    required String postTitle,
    required String postType,
    required String suggestedByName,
    String? suggestedByAvatar,
  }) async {
    final uid = _uid;
    final requestRef = _requests.doc(requestId);
    final suggestionsRef = requestRef.collection('suggestions');
    final now = Timestamp.now();

    // Write the new suggestion document first.
    final newSuggestionRef = suggestionsRef.doc();
    await newSuggestionRef.set({
      'id': newSuggestionRef.id,
      'postId': postId,
      'postTitle': postTitle,
      'postType': postType,
      'suggestedByUserId': uid,
      'suggestedByName': suggestedByName,
      'suggestedByAvatar': suggestedByAvatar,
      'createdAt': now,
    });

    // Check if this was the first suggestion. If yes, mark request fulfilled.
    final countSnap = await suggestionsRef.count().get();
    if ((countSnap.count ?? 0) == 1) {
      await _firestore.runTransaction((txn) async {
        final requestSnap = await txn.get(requestRef);
        if (!requestSnap.exists) return;
        // Only transition if still open (guard against concurrent writes).
        if ((requestSnap.data()?['status'] as String?) == 'open') {
          txn.update(requestRef, {
            'status': 'fulfilled',
            'fulfilledByPostId': postId,
            'fulfilledByPostTitle': postTitle,
            'updatedAt': now,
          });
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Toggle upvote (atomic transaction)
  // ---------------------------------------------------------------------------

  Future<void> toggleUpvote(String requestId) async {
    final uid = _uid;
    final requestRef = _requests.doc(requestId);
    final upvoteRef = requestRef.collection('upvotes').doc(uid);

    await _firestore.runTransaction((txn) async {
      final upvoteSnap = await txn.get(upvoteRef);
      if (upvoteSnap.exists) {
        txn.delete(upvoteRef);
        txn.update(requestRef, {
          'upvoteCount': FieldValue.increment(-1),
          'updatedAt': Timestamp.now(),
        });
      } else {
        txn.set(upvoteRef, {'userId': uid, 'createdAt': Timestamp.now()});
        txn.update(requestRef, {
          'upvoteCount': FieldValue.increment(1),
          'updatedAt': Timestamp.now(),
        });
      }
    });
  }

  Future<bool> hasUpvoted(String requestId) async {
    final uid = _uid;
    final snap = await _requests
        .doc(requestId)
        .collection('upvotes')
        .doc(uid)
        .get();
    return snap.exists;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  ContentRequest _docToEntity(DocumentSnapshot<Map<String, dynamic>> doc) {
    return RequestDto.fromJson(doc.data()!).toDomain();
  }
}
