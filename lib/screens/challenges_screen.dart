import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import '../utils/const.dart';
import '../widgets/text_widget.dart';
import '../widgets/button_widget.dart';
import '../widgets/challenge_dialog.dart';
import '../models/daily_challenge.dart';
import '../models/calculation_result.dart';
import '../models/daily_challenge.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  bool _isLoading = false;
  bool _isSyncing = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _syncChallengesWithCloud();
  }

  Future<void> _syncChallengesWithCloud() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load challenges from Firestore
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('challenges')
            .orderBy('date')
            .get();

        final provider = Provider.of<AppStateProvider>(context, listen: false);
        final challenges = provider.dailyChallenges;

        // Update local challenges with cloud data
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final challengeId = data['id'];

          // Find matching local challenge
          final localChallengeIndex =
              challenges.indexWhere((c) => c.id == challengeId);
          if (localChallengeIndex != -1 && data['isCompleted'] == true) {
            // Update local challenge with completion data
            final updatedChallenge = DailyChallenge(
              id: data['id'],
              title: data['title'],
              question: data['question'],
              difficulty: DifficultyLevel.values[data['difficulty']],
              type: CalculationType.values[data['type']],
              expectedAnswer: data['expectedAnswer'].toDouble(),
              unit: data['unit'],
              parameters: Map<String, dynamic>.from(data['parameters']),
              explanation: data['explanation'],
              hint: data['hint'],
              date: DateTime.parse(data['date']),
              isCompleted: data['isCompleted'],
              userAnswer: data['userAnswer']?.toDouble(),
              isCorrect: data['isCorrect'],
              completedAt: data['completedAt'] != null
                  ? DateTime.parse(data['completedAt'])
                  : null,
            );

            challenges[localChallengeIndex] = updatedChallenge;
          }
        }

        provider.notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing challenges with cloud: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _saveChallengeToCloud(DailyChallenge challenge) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('challenges')
            .doc(challenge.id)
            .set(challenge.toJson());
      }
    } catch (e) {
      debugPrint('Error saving challenge to cloud: $e');
    }
  }

  Future<void> _navigateToNextChallenge(
      BuildContext context, AppStateProvider provider) async {
    // Find the next uncompleted challenge
    final completedChallengeIds = provider.dailyChallenges
        .where((c) => c.isCompleted)
        .map((c) => c.id)
        .toSet();

    // Get uncompleted challenges and sort by difficulty level
    final uncompletedChallenges = provider.dailyChallenges
        .where((c) => !completedChallengeIds.contains(c.id))
        .toList();

    // Sort by difficulty (beginner first, then intermediate, then expert)
    uncompletedChallenges
        .sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));

    final nextChallenge =
        uncompletedChallenges.isNotEmpty ? uncompletedChallenges.first : null;

    if (nextChallenge != null) {
      // Show the next challenge dialog
      _showChallengeDialog(context, nextChallenge, provider);
    } else {
      // All challenges completed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text:
                'Great job! You\'ve completed all available challenges. Check back tomorrow for new ones!',
            fontSize: 14,
            color: Colors.white,
          ),
          backgroundColor: successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          key: _scaffoldKey,
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
            actions: [
              if (_isSyncing)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textOnPrimary),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.sync),
                  onPressed: _syncChallengesWithCloud,
                ),
            ],
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
                _buildTodaysChallenge(context, provider),
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
          Row(
            children: [
              TextWidget(
                text: 'Your Progress',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textOnAccent,
              ),
              const Spacer(),
              TextWidget(
                text: 'Level ${stats['currentLevel']}',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textOnAccent,
              ),
            ],
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
          const SizedBox(height: 16),
          // XP Progress bar
          _buildXPProgress(stats),
        ],
      ),
    );
  }

  Widget _buildXPProgress(Map<String, dynamic> stats) {
    final currentLevel = stats['currentLevel'];
    final xpForNextLevel = currentLevel * 100; // Simple formula for XP needed
    final currentXPInLevel = stats['totalXP'] % 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget(
              text: 'XP: $currentXPInLevel/$xpForNextLevel',
              fontSize: 12,
              color: textOnAccent,
            ),
            TextWidget(
              text: 'Next Level',
              fontSize: 12,
              color: textOnAccent,
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: currentXPInLevel / xpForNextLevel,
          backgroundColor: textOnAccent.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ],
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ButtonWidget(
                    label: 'Next Challenge',
                    onPressed: () {
                      final BuildContext? contextRef =
                          _scaffoldKey.currentContext;
                      if (contextRef != null) {
                        _navigateToNextChallenge(contextRef, provider);
                      }
                    },
                    color: accent,
                    textColor: textOnAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: ButtonWidget(
                    label: '?',
                    onPressed: () {
                      _showExplanationDialog(context, challenge);
                    },
                    color: infoBlue,
                    textColor: textOnAccent,
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
        ...challenges
            .map((challenge) => _buildChallengeListItem(challenge, provider)),
      ],
    );
  }

  Widget _buildChallengeListItem(challenge, AppStateProvider provider) {
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
          ] else ...[
            FaIcon(
              FontAwesomeIcons.lockOpen,
              color: accent,
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
      builder: (context) => ChallengeDialog(
        challenge: challenge,
        onChallengeCompleted: (bool isCorrect) {
          // This callback will be called when the challenge is completed
          if (isCorrect) {
            // Save challenge to cloud immediately
            _saveChallengeToCloud(challenge);

            // Wait for the dialog to close
            Future.delayed(const Duration(seconds: 3), () {
              // Store the context reference for later use
              final BuildContext? contextRef = _scaffoldKey.currentContext;
              if (mounted && contextRef != null) {
                // Show option to proceed to next challenge
                showDialog(
                  context: contextRef,
                  builder: (BuildContext dialogContext) => AlertDialog(
                    backgroundColor: surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: TextWidget(
                      text: 'Challenge Completed!',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                    content: TextWidget(
                      text: 'Would you like to proceed to the next challenge?',
                      fontSize: 14,
                      color: textSecondary,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: TextWidget(
                          text: 'Later',
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          // Use a slight delay to ensure dialog is fully closed
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted) {
                              // Get fresh context reference
                              final BuildContext? freshContext =
                                  _scaffoldKey.currentContext;
                              if (freshContext != null) {
                                _navigateToNextChallenge(
                                    freshContext, provider);
                              }
                            }
                          });
                        },
                        child: TextWidget(
                          text: 'Next Challenge',
                          fontSize: 14,
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }
            });
          }
        },
      ),
    ).then((_) {
      // Only sync the challenge to cloud if not already synced in the callback
      if (challenge.isCompleted && challenge.isCorrect != true) {
        _saveChallengeToCloud(challenge);
      }
    });
  }

  void _showExplanationDialog(BuildContext context, DailyChallenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: TextWidget(
          text: 'Explanation',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        content: SingleChildScrollView(
          child: TextWidget(
            text: challenge.explanation,
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: TextWidget(
              text: 'Close',
              fontSize: 14,
              color: accent,
            ),
          ),
        ],
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
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
