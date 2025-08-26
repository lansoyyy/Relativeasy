import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/colors.dart';
import '../widgets/text_widget.dart';
import '../widgets/button_widget.dart';

class DiscussionsScreen extends StatefulWidget {
  const DiscussionsScreen({super.key});

  @override
  State<DiscussionsScreen> createState() => _DiscussionsScreenState();
}

class _DiscussionsScreenState extends State<DiscussionsScreen> {
  final List<Map<String, dynamic>> _discussionTopics = [
    {
      'title': 'What happens at the speed of light?',
      'author': 'PhysicsStudent',
      'replies': 12,
      'likes': 25,
      'time': '2 hours ago',
      'category': 'Theory',
      'isHot': true,
    },
    {
      'title': 'Help with time dilation calculation',
      'author': 'QuantumLearner',
      'replies': 8,
      'likes': 15,
      'time': '4 hours ago',
      'category': 'Help',
      'isHot': false,
    },
    {
      'title': 'Real-world applications of special relativity',
      'author': 'EinsteinFan',
      'replies': 20,
      'likes': 45,
      'time': '1 day ago',
      'category': 'Applications',
      'isHot': true,
    },
    {
      'title': 'Twin Paradox explained simply',
      'author': 'RelativityMaster',
      'replies': 15,
      'likes': 35,
      'time': '2 days ago',
      'category': 'Paradoxes',
      'isHot': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            icon: const FaIcon(FontAwesomeIcons.plus),
            onPressed: _showNewTopicDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.2), accent.withOpacity(0.1)],
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
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
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
      {
        'name': 'Applications',
        'icon': FontAwesomeIcons.rocket,
        'color': accent
      },
      {
        'name': 'Paradoxes',
        'icon': FontAwesomeIcons.infinity,
        'color': secondary
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: 'Categories',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
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
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: (category['color'] as Color).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  FaIcon(
                    category['icon'] as IconData,
                    color: category['color'] as Color,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  TextWidget(
                    text: category['name'] as String,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHotTopicsSection() {
    final hotTopics =
        _discussionTopics.where((topic) => topic['isHot']).toList();

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
        ...hotTopics.map((topic) => _buildTopicCard(topic, isHot: true)),
      ],
    );
  }

  Widget _buildRecentDiscussionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: 'Recent Discussions',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        const SizedBox(height: 16),
        ..._discussionTopics.map((topic) => _buildTopicCard(topic)),
      ],
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic, {bool isHot = false}) {
    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextWidget(
                  text: topic['category'],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const Spacer(),
              TextWidget(
                text: topic['time'],
                fontSize: 12,
                color: textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextWidget(
            text: topic['title'],
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
                text: topic['author'],
                fontSize: 12,
                color: textSecondary,
              ),
              const SizedBox(width: 16),
              const FaIcon(FontAwesomeIcons.comment,
                  color: textSecondary, size: 12),
              const SizedBox(width: 4),
              TextWidget(
                text: '${topic['replies']} replies',
                fontSize: 12,
                color: textSecondary,
              ),
              const SizedBox(width: 16),
              const FaIcon(FontAwesomeIcons.heart, color: errorRed, size: 12),
              const SizedBox(width: 4),
              TextWidget(
                text: '${topic['likes']}',
                fontSize: 12,
                color: textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNewTopicDialog() {
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
            children: [
              TextWidget(
                text: 'Start a Discussion',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: infoBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    FaIcon(FontAwesomeIcons.lightbulb,
                        color: infoBlue, size: 32),
                    SizedBox(height: 8),
                    TextWidget(
                      text: 'Coming Soon!',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: infoBlue,
                    ),
                    SizedBox(height: 4),
                    TextWidget(
                      text:
                          'The discussion feature is under development. Stay tuned for community interactions!',
                      fontSize: 12,
                      color: textSecondary,
                      align: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ButtonWidget(
                  label: 'Got it!',
                  onPressed: () => Navigator.pop(context),
                  color: accent,
                  textColor: textOnAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
