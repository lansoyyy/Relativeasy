import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import '../widgets/text_widget.dart';
import '../widgets/button_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            title: TextWidget(
              text: 'Relativeasy',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            backgroundColor: primary,
            elevation: 0,
            actions: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.bell),
                onPressed: () {
                  // Show notifications
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primary, primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: 'Welcome to Special Relativity',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      const SizedBox(height: 8),
                      TextWidget(
                        text:
                            'Explore Einstein\'s theories through interactive calculations',
                        fontSize: 14,
                        color: textSecondary,
                      ),
                      const SizedBox(height: 16),
                      ButtonWidget(
                        label: provider.tutorialCompleted
                            ? 'Explore Calculator'
                            : 'Start Tutorial',
                        onPressed: () {
                          if (!provider.tutorialCompleted) {
                            provider.startTutorial();
                          }
                          // Navigate to calculator tab
                          provider.setCurrentIndex(0);
                        },
                        color: accent,
                        textColor: textOnAccent,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Level',
                        provider.userProgress?.currentLevel.toString() ?? '1',
                        FontAwesomeIcons.star,
                        lightSpeedGold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'XP',
                        provider.userProgress?.totalXP.toString() ?? '0',
                        FontAwesomeIcons.bolt,
                        accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Streak',
                        provider.userProgress?.dailyStreak.toString() ?? '0',
                        FontAwesomeIcons.fire,
                        secondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Today's challenge preview
                TextWidget(
                  text: 'Today\'s Challenge',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.trophy,
                            color: accent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          TextWidget(
                            text: provider.getTodaysChallenge()?.title ??
                                'No challenge today',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextWidget(
                        text: provider.getTodaysChallenge()?.question ??
                            'Check back tomorrow for a new challenge!',
                        fontSize: 14,
                        color: textSecondary,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      ButtonWidget(
                        label: 'Solve Challenge',
                        onPressed: () {
                          provider.setCurrentIndex(1); // Navigate to challenges
                        },
                        color: accent.withOpacity(0.2),
                        textColor: accent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          FaIcon(
            icon,
            color: color,
            size: 20,
          ),
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
}
