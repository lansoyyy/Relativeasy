import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import '../utils/const.dart';
import '../widgets/text_widget.dart';
import '../widgets/button_widget.dart';

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < tutorialSteps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      _completeTutorial();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _completeTutorial() {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    provider.completeTutorial();
    Navigator.of(context).pop();
  }

  void _skipTutorial() {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    provider.completeTutorial();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primary, primaryLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: _buildContent(),
            ),

            // Navigation
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const FaIcon(
              FontAwesomeIcons.graduationCap,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextWidget(
              text: 'Special Relativity Tutorial',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          TextButton(
            onPressed: _skipTutorial,
            child: TextWidget(
              text: 'Skip',
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Step indicator
              _buildStepIndicator(),
              const SizedBox(height: 24),

              // Visual representation
              _buildVisual(),
              const SizedBox(height: 24),

              // Text content
              _buildTextContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(tutorialSteps.length, (index) {
        bool isActive = index == _currentStep;
        bool isCompleted = index < _currentStep;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isCompleted
                ? successGreen
                : isActive
                    ? accent
                    : textSecondary.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildVisual() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: _getStepVisual(),
      ),
    );
  }

  Widget _getStepVisual() {
    switch (_currentStep) {
      case 0:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🌟',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: 'Welcome to Relativeasy!',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ],
        );
      case 1:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.boltLightning,
              color: lightSpeedGold,
              size: 48,
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: 'c = 299,792,458 m/s',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: lightSpeedGold,
            ),
            TextWidget(
              text: 'Speed of Light',
              fontSize: 14,
              color: textSecondary,
            ),
          ],
        );
      case 2:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.clock,
                    color: timeDilationPurple, size: 32),
                const SizedBox(height: 8),
                TextWidget(text: 'Time', fontSize: 12, color: textSecondary),
              ],
            ),
            const FaIcon(FontAwesomeIcons.arrowsLeftRight,
                color: accent, size: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.ruler,
                    color: lengthContractionCyan, size: 32),
                const SizedBox(height: 8),
                TextWidget(text: 'Space', fontSize: 12, color: textSecondary),
              ],
            ),
          ],
        );
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.clock,
                color: timeDilationPurple, size: 48),
            const SizedBox(height: 8),
            TextWidget(
              text: 'Δt = Δt₀ / √(1 - v²/c²)',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: timeDilationPurple,
            ),
            TextWidget(
              text: 'Time Dilation Formula',
              fontSize: 12,
              color: textSecondary,
            ),
          ],
        );
      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.ruler,
                color: lengthContractionCyan, size: 48),
            const SizedBox(height: 8),
            TextWidget(
              text: 'L = L₀ × √(1 - v²/c²)',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: lengthContractionCyan,
            ),
            TextWidget(
              text: 'Length Contraction Formula',
              fontSize: 12,
              color: textSecondary,
            ),
          ],
        );
      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.calculator, color: accent, size: 48),
            const SizedBox(height: 8),
            TextWidget(
              text: 'Ready to Calculate!',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextWidget(
        text: tutorialSteps[_currentStep],
        fontSize: 14,
        color: textPrimary,
        align: TextAlign.center,
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: ButtonWidget(
                label: 'Previous',
                onPressed: _previousStep,
                color: surface,
                textColor: textSecondary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ButtonWidget(
              label: _currentStep < tutorialSteps.length - 1
                  ? 'Next'
                  : 'Get Started!',
              onPressed: _nextStep,
              color: accent,
              textColor: textOnAccent,
            ),
          ),
        ],
      ),
    );
  }
}
