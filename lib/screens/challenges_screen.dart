import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import '../utils/const.dart';
import '../widgets/text_widget.dart';
import '../widgets/button_widget.dart';
import '../widgets/challenge_dialog.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            title: TextWidget(
              text: 'Daily Challenges',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            backgroundColor: primary,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress overview
                _buildProgressOverview(provider),
                const SizedBox(height: 24),

                // Today's challenge
                _buildTodaysChallenge(
                    context, provider), // Added context parameter
                const SizedBox(height: 24),

                // Difficulty levels
                _buildDifficultyLevels(),
                const SizedBox(height: 24),

                // Recent challenges
                _buildRecentChallenges(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressOverview(AppStateProvider provider) {
    final stats = provider.getProgressStats();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [accent, accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: 'Your Progress',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textOnAccent,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressStat('Streak', stats['dailyStreak'].toString(),
                  FontAwesomeIcons.fire),
              _buildProgressStat('Level', stats['currentLevel'].toString(),
                  FontAwesomeIcons.star),
              _buildProgressStat(
                  'Accuracy',
                  '${(stats['averageAccuracy'] * 100).toInt()}%',
                  FontAwesomeIcons.bullseye),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Column(
      children: [
        FaIcon(icon, color: textOnAccent, size: 20),
        const SizedBox(height: 8),
        TextWidget(
          text: value,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textOnAccent,
        ),
        TextWidget(
          text: label,
          fontSize: 12,
          color: textOnAccent,
        ),
      ],
    );
  }

  Widget _buildTodaysChallenge(
      BuildContext context, AppStateProvider provider) {
    // Added BuildContext parameter
    final challenge = provider.getTodaysChallenge();

    if (challenge == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            FaIcon(FontAwesomeIcons.calendar, color: textSecondary, size: 32),
            const SizedBox(height: 16),
            TextWidget(
              text: 'No challenge available today',
              fontSize: 16,
              color: textSecondary,
              align: TextAlign.center,
            ),
          ],
        ),
      );
    }

    Color difficultyColor = _getDifficultyColor(challenge.difficulty);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: difficultyColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: difficultyColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextWidget(
                  text: _getDifficultyLabel(challenge.difficulty),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textOnAccent,
                ),
              ),
              const Spacer(),
              if (challenge.isCompleted) ...[
                const FaIcon(FontAwesomeIcons.check,
                    color: successGreen, size: 16),
                const SizedBox(width: 4),
                TextWidget(
                  text: 'Completed',
                  fontSize: 12,
                  color: successGreen,
                ),
              ] else ...[
                TextWidget(
                  text: '+${xpValues[challenge.difficulty]} XP',
                  fontSize: 12,
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          TextWidget(
            text: challenge.title,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          const SizedBox(height: 8),
          TextWidget(
            text: challenge.question,
            fontSize: 14,
            color: textSecondary,
          ),
          const SizedBox(height: 16),
          if (!challenge.isCompleted) ...[
            ButtonWidget(
              label: 'Solve Challenge',
              onPressed: () {
                _showChallengeDialog(context, challenge, provider);
              },
              color: difficultyColor,
              textColor: textOnAccent,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: challenge.isCorrect == true
                          ? successGreen.withOpacity(0.2)
                          : errorRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        TextWidget(
                          text: challenge.isCorrect == true
                              ? 'Correct!'
                              : 'Incorrect',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: challenge.isCorrect == true
                              ? successGreen
                              : errorRed,
                        ),
                        TextWidget(
                          text:
                              'Your answer: ${challenge.userAnswer?.toStringAsFixed(2)} ${challenge.unit}',
                          fontSize: 12,
                          color: textSecondary,
                        ),
                        TextWidget(
                          text:
                              'Correct answer: ${challenge.expectedAnswer.toStringAsFixed(2)} ${challenge.unit}',
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDifficultyLevels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: 'Difficulty Levels',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDifficultyCard(DifficultyLevel.beginner)),
            const SizedBox(width: 12),
            Expanded(child: _buildDifficultyCard(DifficultyLevel.intermediate)),
            const SizedBox(width: 12),
            Expanded(child: _buildDifficultyCard(DifficultyLevel.expert)),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyCard(DifficultyLevel difficulty) {
    Color color = _getDifficultyColor(difficulty);
    int xp = xpValues[difficulty]!;
    int problemsToLevel = problemsToLevelUp[difficulty]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              _getDifficultyIcon(difficulty),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          TextWidget(
            text: _getDifficultyLabel(difficulty),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          TextWidget(
            text: '+$xp XP',
            fontSize: 12,
            color: color,
          ),
          TextWidget(
            text: '$problemsToLevel problems to level up',
            fontSize: 10,
            color: textSecondary,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentChallenges(AppStateProvider provider) {
    final challenges = provider.dailyChallenges.take(5).toList();

    if (challenges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: 'Recent Challenges',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        const SizedBox(height: 16),
        ...challenges.map((challenge) => _buildChallengeListItem(challenge)),
      ],
    );
  }

  Widget _buildChallengeListItem(challenge) {
    Color difficultyColor = _getDifficultyColor(challenge.difficulty);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: difficultyColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              _getDifficultyIcon(challenge.difficulty),
              color: difficultyColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: challenge.title,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                TextWidget(
                  text: _formatDate(challenge.date),
                  fontSize: 12,
                  color: textSecondary,
                ),
              ],
            ),
          ),
          if (challenge.isCompleted) ...[
            FaIcon(
              challenge.isCorrect == true
                  ? FontAwesomeIcons.check
                  : FontAwesomeIcons.xmark,
              color: challenge.isCorrect == true ? successGreen : errorRed,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  void _showChallengeDialog(
      BuildContext context, challenge, AppStateProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChallengeDialog(challenge: challenge),
    );
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return successGreen;
      case DifficultyLevel.intermediate:
        return warningYellow;
      case DifficultyLevel.expert:
        return errorRed;
    }
  }

  String _getDifficultyLabel(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.intermediate:
        return 'Intermediate';
      case DifficultyLevel.expert:
        return 'Expert';
    }
  }

  IconData _getDifficultyIcon(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return FontAwesomeIcons.seedling;
      case DifficultyLevel.intermediate:
        return FontAwesomeIcons.fire;
      case DifficultyLevel.expert:
        return FontAwesomeIcons.crown;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
