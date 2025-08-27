import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/colors.dart';
import '../widgets/text_widget.dart';
import '../widgets/button_widget.dart';
import '../models/discussion.dart';
import '../services/discussion_service.dart';
import 'discussion_detail_screen.dart';

class DiscussionsScreen extends StatefulWidget {
  const DiscussionsScreen({super.key});

  @override
  State<DiscussionsScreen> createState() => _DiscussionsScreenState();
}

class _DiscussionsScreenState extends State<DiscussionsScreen> {
  bool _isLoading = false;
  String? _selectedCategory;
  List<Discussion> _discussions = [];
  List<Discussion> _hotDiscussions = [];
  final DiscussionService _discussionService = DiscussionService.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Theory',
      'icon': FontAwesomeIcons.atom,
      'color': timeDilationPurple
    },
    {
      'name': 'Help',
      'icon': FontAwesomeIcons.handHoldingHeart,
      'color': successGreen
    },
    {'name': 'Applications', 'icon': FontAwesomeIcons.rocket, 'color': accent},
    {
      'name': 'Paradoxes',
      'icon': FontAwesomeIcons.infinity,
      'color': secondary
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDiscussions();
  }

  Future<void> _loadDiscussions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    await _reloadDiscussions();
  }

  Future<void> _reloadDiscussions() async {
    try {
      // Get hot discussions first
      final hotDiscussions = await _discussionService.getHotDiscussions();

      // Then get all discussions filtered by category if selected
      final discussions = await _discussionService.getDiscussions(
        category: _selectedCategory,
      );

      if (mounted) {
        setState(() {
          _hotDiscussions = hotDiscussions;
          _discussions = discussions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading discussions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        final scaffoldContext = _scaffoldKey.currentContext ?? context;
        if (scaffoldContext != null) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(
              content: Text('Failed to load discussions. Please try again.'),
              backgroundColor: errorRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _likeDiscussion(String discussionId) async {
    final scaffoldContext = _scaffoldKey.currentContext ?? context;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (scaffoldContext != null) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(
              content: Text('You need to be logged in to like discussions.'),
              backgroundColor: infoBlue,
            ),
          );
        }
        return;
      }

      final success = await _discussionService.likeDiscussion(discussionId);

      if (success) {
        await _reloadDiscussions(); // Reload to show updated like count
      }
    } catch (e) {
      print('Error liking discussion: $e');
      if (scaffoldContext != null) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Failed to like discussion. Please try again.'),
            backgroundColor: errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: background,
      appBar: AppBar(
        title: TextWidget(
          text: 'Discussions',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        backgroundColor: primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowsRotate),
            onPressed: _loadDiscussions,
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.plus),
            onPressed: _showNewTopicDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: accent),
            )
          : RefreshIndicator(
              onRefresh: _reloadDiscussions,
              color: accent,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withOpacity(0.2),
                            accent.withOpacity(0.1)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: '💬 Join the Community!',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          SizedBox(height: 8),
                          TextWidget(
                            text:
                                'Ask questions, share insights, and learn together with fellow physics enthusiasts!',
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Categories
                    _buildCategoriesSection(),

                    const SizedBox(height: 24),

                    // Hot topics
                    _buildHotTopicsSection(),

                    const SizedBox(height: 24),

                    // Recent discussions
                    _buildRecentDiscussionsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextWidget(
              text: 'Categories',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            const Spacer(),
            if (_selectedCategory != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                  });
                  _reloadDiscussions();
                },
                child: TextWidget(
                  text: 'Clear Filter',
                  fontSize: 14,
                  color: accent,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category['name'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['name'] as String;
                });
                _reloadDiscussions();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (category['color'] as Color).withOpacity(0.2)
                      : surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (category['color'] as Color)
                        : (category['color'] as Color).withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      category['icon'] as IconData,
                      color: category['color'] as Color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: TextWidget(
                        text: category['name'] as String,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHotTopicsSection() {
    if (_hotDiscussions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.fire, color: secondary, size: 18),
              const SizedBox(width: 8),
              TextWidget(
                text: 'Hot Topics',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: TextWidget(
                text:
                    'No hot topics yet. Be the first to start a trending discussion!',
                fontSize: 14,
                color: textSecondary,
                align: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const FaIcon(FontAwesomeIcons.fire, color: secondary, size: 18),
            const SizedBox(width: 8),
            TextWidget(
              text: 'Hot Topics',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._hotDiscussions
            .map((discussion) => _buildTopicCard(discussion, isHot: true)),
      ],
    );
  }

  Widget _buildRecentDiscussionsSection() {
    if (_discussions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: _selectedCategory != null
                ? '$_selectedCategory Discussions'
                : 'Recent Discussions',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: TextWidget(
                text: _selectedCategory != null
                    ? 'No discussions in this category yet. Start a new one!'
                    : 'No discussions yet. Be the first to start a conversation!',
                fontSize: 14,
                color: textSecondary,
                align: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ButtonWidget(
              label: 'Start a New Discussion',
              onPressed: _showNewTopicDialog,
              color: accent,
              textColor: textOnAccent,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: _selectedCategory != null
              ? '$_selectedCategory Discussions'
              : 'Recent Discussions',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        const SizedBox(height: 16),
        ..._discussions.map((discussion) => _buildTopicCard(discussion)),
      ],
    );
  }

  Widget _buildTopicCard(Discussion discussion, {bool isHot = false}) {
    final timeAgo = _getTimeAgo(discussion.createdAt);

    return GestureDetector(
      onTap: () => _navigateToDiscussionDetail(discussion),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: isHot ? Border.all(color: secondary.withOpacity(0.5)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isHot) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextWidget(
                      text: 'HOT',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textOnAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextWidget(
                    text: discussion.category,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const Spacer(),
                TextWidget(
                  text: timeAgo,
                  fontSize: 12,
                  color: textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: discussion.title,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.user,
                    color: textSecondary, size: 12),
                const SizedBox(width: 4),
                TextWidget(
                  text: discussion.authorName,
                  fontSize: 12,
                  color: textSecondary,
                ),
                const SizedBox(width: 16),
                const FaIcon(FontAwesomeIcons.comment,
                    color: textSecondary, size: 12),
                const SizedBox(width: 4),
                TextWidget(
                  text: '${discussion.replies} replies',
                  fontSize: 12,
                  color: textSecondary,
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _likeDiscussion(discussion.id),
                  child: Row(
                    children: [
                      FaIcon(
                        discussion.likedBy
                                .contains(_discussionService.currentUserId)
                            ? FontAwesomeIcons.solidHeart
                            : FontAwesomeIcons.heart,
                        color: errorRed,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      TextWidget(
                        text: '${discussion.likes}',
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDiscussionDetail(Discussion discussion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscussionDetailScreen(discussion: discussion),
      ),
    );
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

  void _showNewTopicDialog() {
    final _titleController = TextEditingController();
    final _contentController = TextEditingController();
    String _category = 'Theory'; // Default category

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: 'Start a Discussion',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              const SizedBox(height: 16),

              // Title field
              TextWidget(
                text: 'Title',
                fontSize: 14,
                color: textPrimary,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter discussion title',
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Category dropdown
              TextWidget(
                text: 'Category',
                fontSize: 14,
                color: textPrimary,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: StatefulBuilder(
                    builder: (context, setState) => DropdownButton<String>(
                      value: _category,
                      isExpanded: true,
                      dropdownColor: surface,
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['name'] as String,
                          child: Row(
                            children: [
                              FaIcon(
                                category['icon'] as IconData,
                                color: category['color'] as Color,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              TextWidget(
                                text: category['name'] as String,
                                fontSize: 14,
                                color: textPrimary,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _category = value);
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Content field
              TextWidget(
                text: 'Content',
                fontSize: 14,
                color: textPrimary,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter discussion content',
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: TextWidget(
                      text: 'Cancel',
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      // Store context reference before any operations
                      final scaffoldContext = _scaffoldKey.currentContext;

                      if (_titleController.text.isEmpty ||
                          _contentController.text.isEmpty) {
                        if (scaffoldContext != null) {
                          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                            SnackBar(
                              content: Text('Please fill all fields'),
                              backgroundColor: errorRed,
                            ),
                          );
                        }
                        return;
                      }

                      Navigator.pop(context);

                      // Show loading indicator
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          if (mounted && scaffoldContext != null) {
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'You need to be logged in to create discussions.'),
                                backgroundColor: infoBlue,
                              ),
                            );
                          }
                          setState(() {
                            _isLoading = false;
                          });
                          return;
                        }

                        final discussion =
                            await _discussionService.createDiscussion(
                          _titleController.text,
                          _contentController.text,
                          _category,
                        );

                        if (discussion != null) {
                          try {
                            // Reload discussions to show the new one without showing loading indicator
                            await _reloadDiscussions();
                          } finally {
                            // Ensure loading indicator is hidden
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }

                          if (mounted && scaffoldContext != null) {
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Discussion created successfully!'),
                                backgroundColor: successGreen,
                              ),
                            );
                          }
                        } else {
                          throw Exception('Failed to create discussion');
                        }
                      } catch (e) {
                        print('Error creating discussion: $e');
                        if (mounted && scaffoldContext != null) {
                          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Failed to create discussion. Please try again.'),
                              backgroundColor: errorRed,
                            ),
                          );
                        }
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: TextWidget(
                      text: 'Create',
                      fontSize: 14,
                      color: textOnAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
