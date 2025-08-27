import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/discussion.dart';

class DiscussionService {
  static DiscussionService? _instance;
  static DiscussionService get instance => _instance ??= DiscussionService._();

  DiscussionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  String get currentUserName => _auth.currentUser?.displayName ?? 'Anonymous';

  // Create a new discussion topic
  Future<Discussion?> createDiscussion(
      String title, String content, String category) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore.collection('discussions').add({
        'title': title,
        'content': content,
        'authorId': currentUserId,
        'authorName': currentUserName,
        'category': category,
        'replies': 0,
        'likes': 0,
        'likedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'isPinned': false,
        'isLocked': false,
      });

      // Get the created document to return it
      final snapshot = await doc.get();
      if (snapshot.exists) {
        return Discussion.fromFirestore(snapshot);
      }

      return null;
    } catch (e) {
      print('Error creating discussion: $e');
      return null;
    }
  }

  // Get all discussions
  Future<List<Discussion>> getDiscussions({String? category}) async {
    try {
      Query query = _firestore
          .collection('discussions')
          .orderBy('isPinned', descending: true)
          .orderBy('createdAt', descending: true);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => Discussion.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting discussions: $e');
      return [];
    }
  }

  // Get hot discussions (most likes or replies)
  Future<List<Discussion>> getHotDiscussions({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('discussions')
          .orderBy('likes', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Discussion.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting hot discussions: $e');
      return [];
    }
  }

  // Get a single discussion by ID
  Future<Discussion?> getDiscussion(String discussionId) async {
    try {
      final doc =
          await _firestore.collection('discussions').doc(discussionId).get();

      if (doc.exists) {
        return Discussion.fromFirestore(doc);
      }

      return null;
    } catch (e) {
      print('Error getting discussion: $e');
      return null;
    }
  }

  // Like a discussion
  Future<bool> likeDiscussion(String discussionId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final doc =
          await _firestore.collection('discussions').doc(discussionId).get();
      if (!doc.exists) return false;

      final discussion = Discussion.fromFirestore(doc);

      // Check if user already liked this discussion
      if (discussion.likedBy.contains(currentUserId)) {
        // Unlike
        await _firestore.collection('discussions').doc(discussionId).update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        // Like
        await _firestore.collection('discussions').doc(discussionId).update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([currentUserId]),
        });
      }

      return true;
    } catch (e) {
      print('Error liking discussion: $e');
      return false;
    }
  }

  // Add a reply to a discussion
  Future<DiscussionReply?> addReply(String discussionId, String content) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // First increment the reply count on the discussion
      await _firestore.collection('discussions').doc(discussionId).update({
        'replies': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Then add the reply
      final doc = await _firestore
          .collection('discussions')
          .doc(discussionId)
          .collection('replies')
          .add({
        'discussionId': discussionId,
        'content': content,
        'authorId': currentUserId,
        'authorName': currentUserName,
        'likes': 0,
        'likedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'isAcceptedAnswer': false,
      });

      // Get the created document to return it
      final snapshot = await doc.get();
      if (snapshot.exists) {
        return DiscussionReply.fromFirestore(snapshot);
      }

      return null;
    } catch (e) {
      print('Error adding reply: $e');
      return null;
    }
  }

  // Get replies for a discussion
  Future<List<DiscussionReply>> getReplies(String discussionId) async {
    try {
      final snapshot = await _firestore
          .collection('discussions')
          .doc(discussionId)
          .collection('replies')
          .orderBy('isAcceptedAnswer', descending: true)
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map((doc) => DiscussionReply.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting replies: $e');
      return [];
    }
  }

  // Like a reply
  Future<bool> likeReply(String discussionId, String replyId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection('discussions')
          .doc(discussionId)
          .collection('replies')
          .doc(replyId)
          .get();

      if (!doc.exists) return false;

      final reply = DiscussionReply.fromFirestore(doc);

      // Check if user already liked this reply
      if (reply.likedBy.contains(currentUserId)) {
        // Unlike
        await _firestore
            .collection('discussions')
            .doc(discussionId)
            .collection('replies')
            .doc(replyId)
            .update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        // Like
        await _firestore
            .collection('discussions')
            .doc(discussionId)
            .collection('replies')
            .doc(replyId)
            .update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([currentUserId]),
        });
      }

      return true;
    } catch (e) {
      print('Error liking reply: $e');
      return false;
    }
  }

  // Mark a reply as the accepted answer
  Future<bool> acceptAnswer(String discussionId, String replyId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if the user is the author of the discussion
      final discussionDoc =
          await _firestore.collection('discussions').doc(discussionId).get();
      if (!discussionDoc.exists) return false;

      final discussion = Discussion.fromFirestore(discussionDoc);

      // Only the author can accept an answer
      if (discussion.authorId != currentUserId) {
        throw Exception('Only the discussion author can accept an answer');
      }

      // First reset all replies to not be accepted
      final repliesSnapshot = await _firestore
          .collection('discussions')
          .doc(discussionId)
          .collection('replies')
          .where('isAcceptedAnswer', isEqualTo: true)
          .get();

      for (var doc in repliesSnapshot.docs) {
        await _firestore
            .collection('discussions')
            .doc(discussionId)
            .collection('replies')
            .doc(doc.id)
            .update({'isAcceptedAnswer': false});
      }

      // Then set the specified reply as accepted
      await _firestore
          .collection('discussions')
          .doc(discussionId)
          .collection('replies')
          .doc(replyId)
          .update({'isAcceptedAnswer': true});

      return true;
    } catch (e) {
      print('Error accepting answer: $e');
      return false;
    }
  }
}
