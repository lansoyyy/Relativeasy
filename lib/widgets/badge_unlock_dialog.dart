import 'package:flutter/material.dart'
    hide Badge; // Hide Flutter's Badge to avoid conflict
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/badge.dart';
import '../utils/colors.dart';
import '../widgets/text_widget.dart';
import '../widgets/button_widget.dart';
import 'dart:math' as dart_math;

class BadgeUnlockDialog extends StatefulWidget {
  final Badge badge;

  const BadgeUnlockDialog({
    super.key,
    required this.badge,
  });

  @override
  State<BadgeUnlockDialog> createState() => _BadgeUnlockDialogState();
}

class _BadgeUnlockDialogState extends State<BadgeUnlockDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _particleController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
    );

    // Start animations
    _scaleController.forward();
    _glowController.repeat(reverse: true);
    _particleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Color _getBadgeColor() {
    switch (widget.badge.color) {
      case BadgeColor.yellow:
        return warningYellow;
      case BadgeColor.green:
        return successGreen;
      case BadgeColor.blue:
        return infoBlue;
      case BadgeColor.purple:
        return timeDilationPurple;
      case BadgeColor.orange:
        return secondary;
      case BadgeColor.red:
        return errorRed;
      case BadgeColor.gold:
        return badgeGold;
      case BadgeColor.rainbow:
        return badgeSpecial;
      default:
        return Colors.grey; // Default color to prevent null return
    }
  }

  String _getRarityText() {
    switch (widget.badge.rarity) {
      case BadgeRarity.common:
        return 'Common Achievement';
      case BadgeRarity.uncommon:
        return 'Uncommon Achievement';
      case BadgeRarity.rare:
        return 'Rare Achievement';
      case BadgeRarity.epic:
        return 'Epic Achievement';
      case BadgeRarity.legendary:
        return 'Legendary Achievement';
      case BadgeRarity.mythic:
        return 'Mythic Achievement';
      default:
        return 'Achievement'; // Default text to prevent null return
    }
  }

  @override
  Widget build(BuildContext context) {
    Color badgeColor = _getBadgeColor();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Particle effects
          _buildParticleEffects(),

          // Main content
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    badgeColor.withOpacity(0.2),
                    background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Achievement unlocked text
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextWidget(
                      text: '🎉 ACHIEVEMENT UNLOCKED! 🎉',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textOnAccent,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Badge icon with glow effect
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              badgeColor.withOpacity(
                                  0.3 + 0.2 * _glowAnimation.value),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: badgeColor, width: 3),
                            ),
                            child: Center(
                              child: Text(
                                widget.badge.emoji,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Badge name
                  TextWidget(
                    text: widget.badge.name,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),

                  const SizedBox(height: 8),

                  // Rarity
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextWidget(
                      text: _getRarityText(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  TextWidget(
                    text: widget.badge.description,
                    fontSize: 14,
                    color: textSecondary,
                  ),

                  const SizedBox(height: 20),

                  // Unlock condition
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.check,
                            color: successGreen, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextWidget(
                            text: widget.badge.unlockCondition,
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ButtonWidget(
                      label: 'Awesome!',
                      onPressed: () => Navigator.of(context).pop(),
                      color: badgeColor,
                      textColor: textOnAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticleEffects() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return Stack(
          children: List.generate(20, (index) {
            double angle = (index * 18) * (3.14159 / 180); // 18 degrees apart
            double distance = 150 * _particleAnimation.value;
            double x = distance * dart_math.cos(angle);
            double y = distance * dart_math.sin(angle);

            return Positioned(
              left: 150 + x,
              top: 200 + y,
              child: Opacity(
                opacity: 1 - _particleAnimation.value,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _getBadgeColor(),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
