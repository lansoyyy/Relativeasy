class Badge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final String emoji;
  final BadgeColor color;
  final String unlockCondition;
  final BadgeRarity rarity;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.emoji,
    required this.color,
    required this.unlockCondition,
    required this.rarity,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  static List<Badge> getAllBadges() {
    return [
      Badge(
        id: 'einstein_apprentice',
        name: 'Einstein Apprentice',
        description:
            'Complete the tutorial mode and learn the basics of special relativity',
        iconPath: 'assets/images/badges/einstein_apprentice.png',
        emoji: '🧠',
        color: BadgeColor.yellow,
        unlockCondition: 'Complete the tutorial mode',
        rarity: BadgeRarity.common,
      ),
      Badge(
        id: 'speed_sprinter',
        name: 'Speed Sprinter',
        description:
            'Master high-speed calculations by solving problems with velocities ≥ 0.8c',
        iconPath: 'assets/images/badges/speed_sprinter.png',
        emoji: '🚀',
        color: BadgeColor.green,
        unlockCondition: 'Solve 5 problems involving speeds ≥ 0.8c',
        rarity: BadgeRarity.common,
      ),
      Badge(
        id: 'time_twister',
        name: 'Time Twister',
        description: 'Become an expert in time dilation calculations',
        iconPath: 'assets/images/badges/time_twister.png',
        emoji: '⏱️',
        color: BadgeColor.blue,
        unlockCondition: 'Complete 3 time dilation problems at Expert level',
        rarity: BadgeRarity.rare,
      ),
      Badge(
        id: 'shrink_master',
        name: 'Shrink Master',
        description: 'Master the concept of length contraction',
        iconPath: 'assets/images/badges/shrink_master.png',
        emoji: '📏',
        color: BadgeColor.purple,
        unlockCondition:
            'Solve 3 length contraction problems at Intermediate level and above',
        rarity: BadgeRarity.rare,
      ),
      Badge(
        id: 'daily_streaker',
        name: 'Daily Streaker',
        description:
            'Show consistency in learning by maintaining a daily streak',
        iconPath: 'assets/images/badges/daily_streaker.png',
        emoji: '📚',
        color: BadgeColor.orange,
        unlockCondition: 'Complete daily exercises 5 days in a row',
        rarity: BadgeRarity.uncommon,
      ),
      Badge(
        id: 'relativity_challenger',
        name: 'Relativity Challenger',
        description: 'Achieve exceptional accuracy in daily challenges',
        iconPath: 'assets/images/badges/relativity_challenger.png',
        emoji: '🎯',
        color: BadgeColor.red,
        unlockCondition: 'Score 90% accuracy in 10 consecutive daily exercises',
        rarity: BadgeRarity.epic,
      ),
      Badge(
        id: 'formula_wizard',
        name: 'Formula Wizard',
        description:
            'Demonstrate mastery of relativistic formulas and rearrangements',
        iconPath: 'assets/images/badges/formula_wizard.png',
        emoji: '⚙️',
        color: BadgeColor.purple,
        unlockCondition:
            'Solve 10 problems requiring formula rearrangement (Intermediate/Expert)',
        rarity: BadgeRarity.rare,
      ),
      Badge(
        id: 'concept_crusher',
        name: 'Concept Crusher',
        description:
            'Perfect understanding of relativistic concepts and principles',
        iconPath: 'assets/images/badges/concept_crusher.png',
        emoji: '💡',
        color: BadgeColor.yellow,
        unlockCondition: 'Score 100% on all questions in Concept Quiz Mode',
        rarity: BadgeRarity.epic,
      ),
      Badge(
        id: 'level_legend',
        name: 'Level Legend',
        description: 'Achieve mastery across all difficulty levels',
        iconPath: 'assets/images/badges/level_legend.png',
        emoji: '🏅',
        color: BadgeColor.gold,
        unlockCondition: 'Reach Level 15 in total across all difficulty levels',
        rarity: BadgeRarity.legendary,
      ),
      Badge(
        id: 'grand_master',
        name: 'Grand Master of Relativity',
        description:
            'The ultimate achievement - complete mastery of special relativity',
        iconPath: 'assets/images/badges/grand_master.png',
        emoji: '🌌',
        color: BadgeColor.rainbow,
        unlockCondition: 'Earn all other badges',
        rarity: BadgeRarity.mythic,
      ),
    ];
  }

  Badge copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Badge(
      id: id,
      name: name,
      description: description,
      iconPath: iconPath,
      emoji: emoji,
      color: color,
      unlockCondition: unlockCondition,
      rarity: rarity,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'emoji': emoji,
      'color': color.index,
      'unlockCondition': unlockCondition,
      'rarity': rarity.index,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }
}

enum BadgeColor {
  yellow,
  green,
  blue,
  purple,
  orange,
  red,
  gold,
  rainbow,
}

enum BadgeRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

extension BadgeRarityExtension on BadgeRarity {
  String get displayName {
    switch (this) {
      case BadgeRarity.common:
        return 'Common';
      case BadgeRarity.uncommon:
        return 'Uncommon';
      case BadgeRarity.rare:
        return 'Rare';
      case BadgeRarity.epic:
        return 'Epic';
      case BadgeRarity.legendary:
        return 'Legendary';
      case BadgeRarity.mythic:
        return 'Mythic';
    }
  }
}
