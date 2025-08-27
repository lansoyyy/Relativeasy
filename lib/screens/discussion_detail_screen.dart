import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/colors.dart';
import '../widgets/text_widget.dart';
import '../widgets/button_widget.dart';
import '../models/discussion.dart';
import '../services/discussion_service.dart';

class DiscussionDetailScreen extends StatefulWidget {
  final Discussion discussion;

  const DiscussionDetailScreen({
    Key? key,
    required this.discussion,
  }) : super(key: key);

  @override
  State<DiscussionDetailScreen> createState() => _DiscussionDetailScreenState();
}

class _DiscussionDetailScreenState extends State<DiscussionDetailScreen> {
  late Discussion _discussion;
  List<DiscussionReply> _replies = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  final DiscussionService _discussionService = DiscussionService.instance;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _discussion = widget.discussion;
    _loadReplies();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get updated discussion
      final updatedDiscussion =
          await _discussionService.getDiscussion(_discussion.id);
      if (updatedDiscussion != null) {
        _discussion = updatedDiscussion;
      }

      // Get replies
      final replies = await _discussionService.getReplies(_discussion.id);

      if (mounted) {
        setState(() {
          _replies = replies;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading replies: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Store a reference to the context
        final scaffoldContext = _scaffoldKey.currentContext ?? context;
        if (scaffoldContext != null) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(
              content: Text('Failed to load replies. Please try again.'),
              backgroundColor: errorRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _submitReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    // Store a reference to the context
    final scaffoldContext = context;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(
              content: Text('You need to be logged in to reply.'),
              backgroundColor: infoBlue,
            ),
          );
        }
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final reply = await _discussionService.addReply(_discussion.id, content);

      if (reply != null) {
        _replyController.clear();
        // Reload to show the new reply
        await _loadReplies();

        // Scroll to the bottom after a short delay to ensure the list is built
        Future.delayed(Duration(milliseconds: 300), () {
          if (_scrollController.hasClients && mounted) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        throw Exception('Failed to add reply');
      }
    } catch (e) {
      print('Error submitting reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Failed to submit reply. Please try again.'),
            backgroundColor: errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _likeDiscussion() async {
    // Store a reference to the context
    final scaffoldContext = context;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(
              content: Text('You need to be logged in to like discussions.'),
              backgroundColor: infoBlue,
            ),
          );
        }
        return;
      }

      final success = await _discussionService.likeDiscussion(_discussion.id);

      if (success) {
        await _loadReplies(); // Reload to show updated like count
      }
    } catch (e) {
      print('Error liking discussion: $e');
      if (mounted) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Failed to like discussion. Please try again.'),
            backgroundColor: errorRed,
          ),
        );
      }
    }
  }

  Future<void> _likeReply(String replyId) async {
    // Store a reference to the context
    final scaffoldContext = context;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(
              content: Text('You need to be logged in to like replies.'),
              backgroundColor: infoBlue,
            ),
          );
        }
        return;
      }

      final success =
          await _discussionService.likeReply(_discussion.id, replyId);

      if (success) {
        await _loadReplies(); // Reload to show updated like count
      }
    } catch (e) {
      print('Error liking reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Failed to like reply. Please try again.'),
            backgroundColor: errorRed,
          ),
        );
      }
    }
  }

  Future<void> _acceptAnswer(String replyId) async {
    // Store a reference to the context
    final scaffoldContext = context;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(
              content: Text('You need to be logged in to accept answers.'),
              backgroundColor: infoBlue,
            ),
          );
        }
        return;
      }

      // Check if the current user is the author of the discussion
      if (_discussion.authorId != user.uid) {
        if (mounted) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(
              content: Text('Only the discussion author can accept answers.'),
              backgroundColor: infoBlue,
            ),
          );
        }
        return;
      }

      final success =
          await _discussionService.acceptAnswer(_discussion.id, replyId);

      if (success) {
        await _loadReplies(); // Reload to show updated status
        if (mounted) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(
              content: Text('Answer accepted!'),
              backgroundColor: successGreen,
            ),
          );
        }
      }
    } catch (e) {
      print('Error accepting answer: $e');
      if (mounted) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Failed to accept answer. Please try again.'),
            backgroundColor: errorRed,
          ),
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    }

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    }

    if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    }

    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    }

    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: background,
      appBar: AppBar(
        title: TextWidget(
          text: 'Discussion',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        backgroundColor: primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowsRotate),
            onPressed: _loadReplies,
          ),
        ],
      ),
      body: Column(
        children: [
          // Discussion content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: accent),
                  )
                : RefreshIndicator(
                    onRefresh: _loadReplies,
                    color: accent,
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Discussion details
                        _buildDiscussionHeader(),
                        const SizedBox(height: 8),
                        _buildDiscussionContent(),
                        const SizedBox(height: 24),

                        // Replies header
                        Row(
                          children: [
                            TextWidget(
                              text: 'Replies (${_replies.length})',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                            const Spacer(),
                            if (_replies.isNotEmpty)
                              TextWidget(
                                text: 'Latest first',
                                fontSize: 12,
                                color: textSecondary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Replies
                        if (_replies.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: TextWidget(
                                text: 'No replies yet. Be the first to reply!',
                                fontSize: 14,
                                color: textSecondary,
                                align: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          ...List.generate(_replies.length, (index) {
                            return _buildReplyCard(_replies[index]);
                          }),
                      ],
                    ),
                  ),
          ),

          // Reply input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    focusNode: _replyFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Write a reply...',
                      filled: true,
                      fillColor: background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(
                      fontSize: 14,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: accent,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _isSubmitting ? null : _submitReply,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: textOnAccent,
                                strokeWidth: 2,
                              ),
                            )
                          : FaIcon(
                              FontAwesomeIcons.paperPlane,
                              color: textOnAccent,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextWidget(
                  text: _discussion.category,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const Spacer(),
              TextWidget(
                text: _getTimeAgo(_discussion.createdAt),
                fontSize: 12,
                color: textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextWidget(
            text: _discussion.title,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.user,
                  color: textSecondary, size: 12),
              const SizedBox(width: 4),
              TextWidget(
                text: _discussion.authorName,
                fontSize: 12,
                color: textSecondary,
              ),
              const Spacer(),
              GestureDetector(
                onTap: _likeDiscussion,
                child: Row(
                  children: [
                    FaIcon(
                      _discussion.likedBy
                              .contains(_discussionService.currentUserId)
                          ? FontAwesomeIcons.solidHeart
                          : FontAwesomeIcons.heart,
                      color: errorRed,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    TextWidget(
                      text: '${_discussion.likes}',
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextWidget(
        text: _discussion.content,
        fontSize: 14,
        color: textPrimary,
      ),
    );
  }

  Widget _buildReplyCard(DiscussionReply reply) {
    final isCurrentUser = reply.authorId == _discussionService.currentUserId;
    final isDiscussionAuthor =
        _discussion.authorId == _discussionService.currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: reply.isAcceptedAnswer ? successGreen.withOpacity(0.1) : surface,
        borderRadius: BorderRadius.circular(12),
        border: reply.isAcceptedAnswer
            ? Border.all(color: successGreen.withOpacity(0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextWidget(
                text: reply.authorName,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? accent : textPrimary,
              ),
              if (isCurrentUser) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextWidget(
                    text: 'YOU',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ],
              if (_discussion.authorId == reply.authorId && !isCurrentUser) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextWidget(
                    text: 'AUTHOR',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
              const Spacer(),
              if (reply.isAcceptedAnswer) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: successGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.check,
                          color: textOnAccent, size: 10),
                      const SizedBox(width: 4),
                      TextWidget(
                        text: 'ACCEPTED',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: textOnAccent,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 8),
              TextWidget(
                text: _getTimeAgo(reply.createdAt),
                fontSize: 12,
                color: textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextWidget(
            text: reply.content,
            fontSize: 14,
            color: textPrimary,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Like button
              GestureDetector(
                onTap: () => _likeReply(reply.id),
                child: Row(
                  children: [
                    FaIcon(
                      reply.likedBy.contains(_discussionService.currentUserId)
                          ? FontAwesomeIcons.solidHeart
                          : FontAwesomeIcons.heart,
                      color: errorRed,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    TextWidget(
                      text: '${reply.likes}',
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ],
                ),
              ),

              // Accept answer button (only for discussion author)
              if (isDiscussionAuthor && !reply.isAcceptedAnswer) ...[
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _acceptAnswer(reply.id),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: successGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.check,
                            color: successGreen, size: 12),
                        const SizedBox(width: 4),
                        TextWidget(
                          text: 'Accept',
                          fontSize: 12,
                          color: successGreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
