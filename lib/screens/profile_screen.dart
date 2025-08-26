import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import '../widgets/text_widget.dart';
import '../widgets/button_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        final stats = provider.getProgressStats();

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            title: TextWidget(
              text: 'Profile',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            backgroundColor: primary,
            elevation: 0,
            actions: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.gear),
                onPressed: () {
                  _showSettingsDialog(context);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile header
                _buildProfileHeader(stats),
                const SizedBox(height: 24),

                // Quick stats
                _buildQuickStats(stats),
                const SizedBox(height: 24),

                // Achievement summary
                _buildAchievementSummary(provider),
                const SizedBox(height: 24),

                // Recent activity
                _buildRecentActivity(provider),
                const SizedBox(height: 24),

                // Action buttons
                _buildActionButtons(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 3),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.user,
                color: accent,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextWidget(
            text: 'Physics Enthusiast',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: lightSpeedGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(FontAwesomeIcons.star,
                    color: lightSpeedGold, size: 14),
                const SizedBox(width: 4),
                TextWidget(
                  text: 'Level ${stats['currentLevel']}',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: lightSpeedGold,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat(
                  'XP', stats['totalXP'].toString(), FontAwesomeIcons.bolt),
              _buildHeaderStat('Streak', stats['dailyStreak'].toString(),
                  FontAwesomeIcons.fire),
              _buildHeaderStat('Badges', stats['badgesEarned'].toString(),
                  FontAwesomeIcons.medal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        FaIcon(icon, color: textPrimary, size: 18),
        const SizedBox(height: 4),
        TextWidget(
          text: value,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        TextWidget(
          text: label,
          fontSize: 12,
          color: textSecondary,
        ),
      ],
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: 'Statistics',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Accuracy',
                  '${(stats['averageAccuracy'] * 100).toInt()}%',
                  FontAwesomeIcons.bullseye,
                  successGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Problems',
                  stats['totalProblems'].toString(),
                  FontAwesomeIcons.calculator,
                  infoBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (stats['averageAccuracy'] as double).clamp(0.0, 1.0),
            backgroundColor: grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              stats['averageAccuracy'] >= 0.8
                  ? successGreen
                  : stats['averageAccuracy'] >= 0.6
                      ? warningYellow
                      : errorRed,
            ),
          ),
          const SizedBox(height: 8),
          TextWidget(
            text:
                'Overall Performance: ${_getPerformanceLevel(stats['averageAccuracy'])}',
            fontSize: 12,
            color: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          FaIcon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          TextWidget(
            text: value,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          TextWidget(
            text: label,
            fontSize: 12,
            color: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementSummary(AppStateProvider provider) {
    final unlockedBadges = provider.getUnlockedBadges();
    final totalBadges = provider.badges.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextWidget(
                text: 'Achievements',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              const Spacer(),
              TextWidget(
                text: '${unlockedBadges.length}/$totalBadges',
                fontSize: 14,
                color: accent,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (unlockedBadges.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: unlockedBadges.take(5).map((badge) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: badgeGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else ...[
            TextWidget(
              text: 'Complete the tutorial to earn your first badge!',
              fontSize: 14,
              color: textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentActivity(AppStateProvider provider) {
    final recentCalculations = provider.calculationHistory.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: 'Recent Activity',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          const SizedBox(height: 16),
          if (recentCalculations.isNotEmpty) ...[
            ...recentCalculations.map((calc) => _buildActivityItem(calc)),
          ] else ...[
            TextWidget(
              text: 'No recent calculations. Start exploring!',
              fontSize: 14,
              color: textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItem(calculation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          FaIcon(
            calculation.type == 0 // TimeDilation
                ? FontAwesomeIcons.clock
                : FontAwesomeIcons.ruler,
            color: calculation.type == 0
                ? timeDilationPurple
                : lengthContractionCyan,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: calculation.type == 0
                      ? 'Time Dilation'
                      : 'Length Contraction',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                TextWidget(
                  text:
                      '${calculation.inputValue.toStringAsFixed(1)} → ${calculation.result.toStringAsFixed(2)} ${calculation.unit}',
                  fontSize: 12,
                  color: textSecondary,
                ),
              ],
            ),
          ),
          TextWidget(
            text: '${(calculation.velocity * 100).toStringAsFixed(0)}%c',
            fontSize: 12,
            color: accent,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppStateProvider provider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ButtonWidget(
            label: 'Restart Tutorial',
            onPressed: () {
              provider.startTutorial();
            },
            color: accent.withOpacity(0.2),
            textColor: accent,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ButtonWidget(
            label: 'View All Achievements',
            onPressed: () {
              provider.setCurrentIndex(2); // Navigate to achievements
            },
            color: badgeGold.withOpacity(0.2),
            textColor: badgeGold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ButtonWidget(
            label: 'Share Progress',
            onPressed: () {
              _showShareDialog(context, provider.getProgressStats());
            },
            color: secondary.withOpacity(0.2),
            textColor: secondary,
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: FaIcon(FontAwesomeIcons.palette),
              title: Text('Theme'),
              subtitle: Text('Dark theme enabled'),
            ),
            ListTile(
              leading: FaIcon(FontAwesomeIcons.bell),
              title: Text('Notifications'),
              subtitle: Text('Daily reminders on'),
            ),
            ListTile(
              leading: FaIcon(FontAwesomeIcons.volumeHigh),
              title: Text('Sound Effects'),
              subtitle: Text('Enabled'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context, Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Your Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Check out my progress in Relativeasy!'),
            const SizedBox(height: 16),
            Text('Level ${stats['currentLevel']} • ${stats['totalXP']} XP'),
            Text('${stats['badgesEarned']} badges earned'),
            Text('${(stats['averageAccuracy'] * 100).toInt()}% accuracy'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement sharing logic
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  String _getPerformanceLevel(double accuracy) {
    if (accuracy >= 0.9) return 'Excellent';
    if (accuracy >= 0.8) return 'Great';
    if (accuracy >= 0.7) return 'Good';
    if (accuracy >= 0.6) return 'Fair';
    return 'Needs Improvement';
  }
}
