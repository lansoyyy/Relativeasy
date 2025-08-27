import 'package:cloud_firestore/cloud_firestore.dart';

class Discussion {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String category;
  final int replies;
  final int likes;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final bool isPinned;
  final bool isLocked;

  Discussion({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.category,
    this.replies = 0,
    this.likes = 0,
    this.likedBy = const [],
    required this.createdAt,
    this.lastUpdated,
    this.isPinned = false,
    this.isLocked = false,
  });

  factory Discussion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Discussion(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      category: data['category'] ?? 'General',
      replies: data['replies'] ?? 0,
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
      isPinned: data['isPinned'] ?? false,
      isLocked: data['isLocked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'category': category,
      'replies': replies,
      'likes': likes,
      'likedBy': likedBy,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated ?? createdAt,
      'isPinned': isPinned,
      'isLocked': isLocked,
    };
  }

  Discussion copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    String? category,
    int? replies,
    int? likes,
    List<String>? likedBy,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? isPinned,
    bool? isLocked,
  }) {
    return Discussion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      category: category ?? this.category,
      replies: replies ?? this.replies,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

class DiscussionReply {
  final String id;
  final String discussionId;
  final String content;
  final String authorId;
  final String authorName;
  final int likes;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final bool isAcceptedAnswer;

  DiscussionReply({
    required this.id,
    required this.discussionId,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.likes = 0,
    this.likedBy = const [],
    required this.createdAt,
    this.lastUpdated,
    this.isAcceptedAnswer = false,
  });

  factory DiscussionReply.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiscussionReply(
      id: doc.id,
      discussionId: data['discussionId'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
      isAcceptedAnswer: data['isAcceptedAnswer'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'discussionId': discussionId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'likes': likes,
      'likedBy': likedBy,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated ?? createdAt,
      'isAcceptedAnswer': isAcceptedAnswer,
    };
  }
}
