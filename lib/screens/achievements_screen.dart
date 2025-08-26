import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/app_state_provider.dart';
import '../models/badge.dart' as app_badge;
import '../utils/colors.dart';
import '../widgets/text_widget.dart';
import '../widgets/button_widget.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        final unlockedBadges = provider.getUnlockedBadges();
        final lockedBadges = provider.getLockedBadges();

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            title: TextWidget(
              text: 'Achievements',
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
                _buildProgressOverview(
                    unlockedBadges.length, provider.badges.length),
                const SizedBox(height: 24),

                // Unlocked badges
                if (unlockedBadges.isNotEmpty) ...[
                  TextWidget(
                    text: 'Unlocked Achievements',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: unlockedBadges.length,
                    itemBuilder: (context, index) {
                      return _buildBadgeCard(
                          unlockedBadges[index], true, context);
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Locked badges
                TextWidget(
                  text: 'Locked Achievements',
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
                    childAspectRatio: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: lockedBadges.length,
                  itemBuilder: (context, index) {
                    return _buildBadgeCard(lockedBadges[index], false, context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressOverview(int unlockedCount, int totalCount) {
    double progress = unlockedCount / totalCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [badgeGold, badgeSilver],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextWidget(
            text: 'Achievement Progress',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textOnAccent,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const FaIcon(FontAwesomeIcons.trophy,
                      color: textOnAccent, size: 24),
                  const SizedBox(height: 8),
                  TextWidget(
                    text: unlockedCount.toString(),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textOnAccent,
                  ),
                  TextWidget(
                    text: 'Unlocked',
                    fontSize: 12,
                    color: textOnAccent,
                  ),
                ],
              ),
              Column(
                children: [
                  const FaIcon(FontAwesomeIcons.percentage,
                      color: textOnAccent, size: 24),
                  const SizedBox(height: 8),
                  TextWidget(
                    text: '${(progress * 100).toInt()}%',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textOnAccent,
                  ),
                  TextWidget(
                    text: 'Complete',
                    fontSize: 12,
                    color: textOnAccent,
                  ),
                ],
              ),
              Column(
                children: [
                  const FaIcon(FontAwesomeIcons.lock,
                      color: textOnAccent, size: 24),
                  const SizedBox(height: 8),
                  TextWidget(
                    text: (totalCount - unlockedCount).toString(),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textOnAccent,
                  ),
                  TextWidget(
                    text: 'Remaining',
                    fontSize: 12,
                    color: textOnAccent,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: textOnAccent.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(textOnAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(
      app_badge.Badge badge, bool isUnlocked, BuildContext context) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(badge, context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnlocked ? surface : surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? _getBadgeColor(badge.color)
                : grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? _getBadgeColor(badge.color).withOpacity(0.2)
                    : grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                badge.emoji,
                style: TextStyle(
                  fontSize: 24,
                  color: isUnlocked ? null : grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: badge.name,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? textPrimary : textLight,
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? _getBadgeColor(badge.color).withOpacity(0.2)
                    : grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextWidget(
                text: badge.rarity.displayName,
                fontSize: 10,
                color: isUnlocked ? _getBadgeColor(badge.color) : textLight,
              ),
            ),
            if (!isUnlocked) ...[
              const SizedBox(height: 8),
              const FaIcon(
                FontAwesomeIcons.lock,
                color: grey,
                size: 12,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(app_badge.Badge badge, BuildContext context) {
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
              // Badge display
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: badge.isUnlocked
                      ? _getBadgeColor(badge.color).withOpacity(0.2)
                      : grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        badge.isUnlocked ? _getBadgeColor(badge.color) : grey,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    badge.emoji,
                    style: TextStyle(
                      fontSize: 32,
                      color: badge.isUnlocked ? null : grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Badge name and rarity
              TextWidget(
                text: badge.name,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: badge.isUnlocked
                      ? _getBadgeColor(badge.color).withOpacity(0.2)
                      : grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextWidget(
                  text: badge.rarity.displayName,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badge.isUnlocked ? _getBadgeColor(badge.color) : grey,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextWidget(
                text: badge.description,
                fontSize: 14,
                color: textSecondary,
              ),
              const SizedBox(height: 16),

              // Unlock condition
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        FaIcon(
                          badge.isUnlocked
                              ? FontAwesomeIcons.check
                              : FontAwesomeIcons.lock,
                          color: badge.isUnlocked ? successGreen : grey,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        TextWidget(
                          text: 'Unlock Condition',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextWidget(
                      text: badge.unlockCondition,
                      fontSize: 12,
                      color: textSecondary,
                    ),
                    if (badge.isUnlocked && badge.unlockedAt != null) ...[
                      const SizedBox(height: 8),
                      TextWidget(
                        text: 'Unlocked on ${_formatDate(badge.unlockedAt!)}',
                        fontSize: 10,
                        color: successGreen,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: surface,
                    foregroundColor: textSecondary,
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getBadgeColor(app_badge.BadgeColor badgeColor) {
    switch (badgeColor) {
      case app_badge.BadgeColor.yellow:
        return warningYellow;
      case app_badge.BadgeColor.green:
        return successGreen;
      case app_badge.BadgeColor.blue:
        return infoBlue;
      case app_badge.BadgeColor.purple:
        return timeDilationPurple;
      case app_badge.BadgeColor.orange:
        return secondary;
      case app_badge.BadgeColor.red:
        return errorRed;
      case app_badge.BadgeColor.gold:
        return badgeGold;
      case app_badge.BadgeColor.rainbow:
        return badgeSpecial;
    }
  }
}
