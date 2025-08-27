import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import '../widgets/text_widget.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Move data loading to initState instead of during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaderboardData();
    });
  }

  // Extract the loading logic to a separate method
  Future<void> _loadLeaderboardData() async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    if (provider.leaderboard == null && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      await provider.refreshLeaderboard();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        // Remove the conditional loading logic from the build method

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            title: TextWidget(
              text: 'Leaderboard',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            backgroundColor: primary,
            elevation: 0,
            actions: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.arrowsRotate),
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await provider.refreshLeaderboard();
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'All Time'),
                Tab(text: 'This Week'),
              ],
              indicatorColor: accent,
              labelColor: accent,
              unselectedLabelColor: textSecondary,
            ),
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(AppStateProvider provider) {
    // Show loading indicator
    if (provider.leaderboard == null && _isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: accent),
            SizedBox(height: 16),
            TextWidget(
              text: 'Loading leaderboard...',
              fontSize: 16,
              color: textSecondary,
            ),
          ],
        ),
      );
    }

    // Show error state
    if (provider.leaderboard == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.triangleExclamation,
                color: errorRed, size: 48),
            SizedBox(height: 16),
            TextWidget(
              text: 'Failed to load leaderboard',
              fontSize: 16,
              color: textSecondary,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLeaderboardData,
              child: TextWidget(
                text: 'Retry',
                fontSize: 16,
                color: textOnAccent,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show leaderboard data
    return TabBarView(
      controller: _tabController,
      children: [
        _buildLeaderboardList(
          provider.leaderboard!.allTimeLeaders,
          isWeekly: false,
        ),
        _buildLeaderboardList(
          provider.leaderboard!.weeklyLeaders,
          isWeekly: true,
        ),
      ],
    );
  }

  Widget _buildLeaderboardList(List entries, {required bool isWeekly}) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.trophy, color: textSecondary, size: 48),
            SizedBox(height: 16),
            TextWidget(
              text: 'No leaderboard data available',
              fontSize: 16,
              color: textSecondary,
            ),
          ],
        ),
      );
    }

    // Convert LeaderboardEntry objects to Map for UI consistency
    final leaderList =
        entries.map((entry) => _convertEntryToMap(entry)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Top 3 podium
          _buildPodium(leaderList.take(3).toList()),
          const SizedBox(height: 24),

          // Full rankings
          _buildRankingsList(leaderList),
        ],
      ),
    );
  }

  Map<String, dynamic> _convertEntryToMap(dynamic entry) {
    // Handle both LeaderboardEntry objects and already converted Maps
    if (entry is Map<String, dynamic>) {
      return entry;
    }

    return {
      'username': entry.username,
      'xp': entry.totalXP,
      'totalXP': entry.totalXP,
      'weeklyXP': entry.weeklyXP,
      'rank': entry.rank,
      'weeklyRank': entry.weeklyRank,
      'accuracy': (entry.averageAccuracy * 100).toInt(),
      'streak': entry.dailyStreak,
      'badges': entry.badgesEarned,
      'isCurrentUser': entry.username == 'You',
    };
  }

  Widget _buildPodium(List<Map<String, dynamic>> topThree) {
    return Container(
      height: 250, // Increased height to provide more space
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, primaryLight],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topThree.length > 1) _buildPodiumPosition(topThree[1], 2, 40),
          if (topThree.isNotEmpty) _buildPodiumPosition(topThree[0], 1, 70),
          if (topThree.length > 2) _buildPodiumPosition(topThree[2], 3, 20),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(
      Map<String, dynamic> user, int position, double height) {
    Color positionColor;
    IconData medal;

    switch (position) {
      case 1:
        positionColor = badgeGold;
        medal = FontAwesomeIcons.crown;
        break;
      case 2:
        positionColor = badgeSilver;
        medal = FontAwesomeIcons.medal;
        break;
      case 3:
        positionColor = badgeBronze;
        medal = FontAwesomeIcons.award;
        break;
      default:
        positionColor = grey;
        medal = FontAwesomeIcons.trophy;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(medal, color: positionColor, size: 24),
        const SizedBox(height: 8),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: positionColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: positionColor, width: 2),
          ),
          child: Center(
            child: TextWidget(
              text: user['username'][0].toUpperCase(),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: positionColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80, // Increased width to prevent overflow
          child: Column(
            children: [
              TextWidget(
                text: user['username'],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                align: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              TextWidget(
                text: '${user['xp']} XP',
                fontSize: 10,
                color: textSecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: positionColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: TextWidget(
              text: '#$position',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textOnAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingsList(List<Map<String, dynamic>> rankings) {
    return Column(
      children: [
        Row(
          children: [
            TextWidget(
              text: 'Full Rankings',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            Spacer(),
            FaIcon(FontAwesomeIcons.trophy, color: accent, size: 18),
          ],
        ),
        const SizedBox(height: 16),
        ...rankings.map((user) => _buildRankingItem(user)),
      ],
    );
  }

  Widget _buildRankingItem(Map<String, dynamic> user) {
    bool isCurrentUser = user['isCurrentUser'] ?? false;
    Color rankColor = _getRankColor(user['rank']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? accent.withOpacity(0.1) : surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? accent : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: TextWidget(
                text: '#${user['rank']}',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: TextWidget(
                        text: user['username'],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser ? accent : textPrimary,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextWidget(
                          text: 'YOU',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textOnAccent,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatChip('${user['xp']} XP', FontAwesomeIcons.bolt),
                    const SizedBox(width: 8),
                    _buildStatChip(
                        '${user['accuracy']}%', FontAwesomeIcons.bullseye),
                    const SizedBox(width: 8),
                    _buildStatChip('${user['streak']}🔥', null),
                  ],
                ),
              ],
            ),
          ),

          // Badges count
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(FontAwesomeIcons.medal,
                    color: badgeGold, size: 14),
                const SizedBox(width: 4),
                TextWidget(
                  text: user['badges'].toString(),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badgeGold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            FaIcon(icon, size: 10, color: textSecondary),
            const SizedBox(width: 2),
          ],
          TextWidget(
            text: text,
            fontSize: 10,
            color: textSecondary,
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) return badgeGold;
    if (rank <= 10) return badgeSilver;
    if (rank <= 25) return badgeBronze;
    return textSecondary;
  }
}
