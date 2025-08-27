import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/app_state_provider.dart';
import '../models/daily_challenge.dart';
import '../models/calculation_result.dart';
import '../utils/colors.dart';
import '../utils/const.dart';
import '../widgets/text_widget.dart';
import '../widgets/button_widget.dart';
import '../widgets/app_text_form_field.dart';

class ChallengeDialog extends StatefulWidget {
  final DailyChallenge challenge;
  final Function(bool isCorrect)? onChallengeCompleted;

  const ChallengeDialog({
    super.key,
    required this.challenge,
    this.onChallengeCompleted,
  });

  @override
  State<ChallengeDialog> createState() => _ChallengeDialogState();
}

class _ChallengeDialogState extends State<ChallengeDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _answerController = TextEditingController();

  bool _showHint = false;
  bool _isSubmitted = false;
  bool? _isCorrect;
  String? _feedback;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _successController;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _successAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _successController, curve: Curves.bounceOut),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    _shakeController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _submitAnswer() {
    if (!_formKey.currentState!.validate()) return;

    double userAnswer = double.parse(_answerController.text);
    double tolerance = widget.challenge.expectedAnswer * 0.05; // 5% tolerance

    bool correct =
        (userAnswer - widget.challenge.expectedAnswer).abs() <= tolerance;

    setState(() {
      _isSubmitted = true;
      _isCorrect = correct;
      _feedback = _generateFeedback(userAnswer, correct);
    });

    if (correct) {
      _successController.forward();
      HapticFeedback.lightImpact();

      // Add XP and complete challenge
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      provider.completeDailyChallenge(widget.challenge.id, userAnswer);

      // Call the completion callback if provided
      if (widget.onChallengeCompleted != null) {
        // Slight delay to ensure state is updated
        Future.delayed(Duration.zero, () {
          widget.onChallengeCompleted!(true);
        });
      }

      // Auto-close after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      _shakeController.forward().then((_) => _shakeController.reset());
      HapticFeedback.heavyImpact();

      // Call the completion callback if provided
      if (widget.onChallengeCompleted != null) {
        widget.onChallengeCompleted!(false);
      }
    }
  }

  String _generateFeedback(double userAnswer, bool correct) {
    if (correct) {
      List<String> successMessages = [
        "Excellent! Einstein would be proud! 🌟",
        "Perfect calculation! You're mastering relativity! 🚀",
        "Outstanding work! The physics is strong with you! ⚡",
        "Brilliant! You've got the relativistic touch! 🧠",
      ];
      return successMessages[
          DateTime.now().millisecond % successMessages.length];
    } else {
      double difference = (userAnswer - widget.challenge.expectedAnswer).abs();
      double percentError =
          (difference / widget.challenge.expectedAnswer) * 100;

      if (percentError < 10) {
        return "Very close! Check your calculation once more. The correct answer is ${widget.challenge.expectedAnswer.toStringAsFixed(2)} ${widget.challenge.unit}.";
      } else if (percentError < 25) {
        return "Good attempt! You're on the right track. Remember to use the relativistic formula carefully.";
      } else {
        return "Not quite right. Try using the hint below and double-check your formula application.";
      }
    }
  }

  Color _getDifficultyColor() {
    switch (widget.challenge.difficulty) {
      case DifficultyLevel.beginner:
        return successGreen;
      case DifficultyLevel.intermediate:
        return warningYellow;
      case DifficultyLevel.expert:
        return errorRed;
    }
  }

  String _getDifficultyLabel() {
    switch (widget.challenge.difficulty) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.intermediate:
        return 'Intermediate';
      case DifficultyLevel.expert:
        return 'Expert';
    }
  }

  IconData _getDifficultyIcon() {
    switch (widget.challenge.difficulty) {
      case DifficultyLevel.beginner:
        return FontAwesomeIcons.seedling;
      case DifficultyLevel.intermediate:
        return FontAwesomeIcons.fire;
      case DifficultyLevel.expert:
        return FontAwesomeIcons.crown;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color difficultyColor = _getDifficultyColor();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: difficultyColor, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(difficultyColor),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question
                    _buildQuestion(),
                    const SizedBox(height: 20),

                    // Answer input
                    if (!_isSubmitted) _buildAnswerInput(),

                    // Feedback
                    if (_isSubmitted) _buildFeedback(),

                    // Hint section
                    if (!_isSubmitted) _buildHintSection(),

                    const SizedBox(height: 20),

                    // Formula reference
                    _buildFormulaReference(),
                  ],
                ),
              ),
            ),

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color difficultyColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: difficultyColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: difficultyColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(
              _getDifficultyIcon(),
              color: difficultyColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: widget.challenge.title,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: difficultyColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextWidget(
                    text:
                        '${_getDifficultyLabel()} • +${xpValues[widget.challenge.difficulty]} XP',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textOnAccent,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const FaIcon(FontAwesomeIcons.xmark, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.question, color: accent, size: 16),
              const SizedBox(width: 8),
              TextWidget(
                text: 'Challenge Question',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextWidget(
            text: widget.challenge.question,
            fontSize: 16,
            color: textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerInput() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: 'Your Answer',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AppTextFormField(
                        controller: _answerController,
                        labelText: 'Enter your answer',
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an answer';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                        onEditingComplete: () => _submitAnswer(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: textSecondary.withOpacity(0.3)),
                      ),
                      child: TextWidget(
                        text: widget.challenge.unit,
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedback() {
    return ScaleTransition(
      scale: _successAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isCorrect!
              ? successGreen.withOpacity(0.1)
              : errorRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isCorrect! ? successGreen : errorRed,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                FaIcon(
                  _isCorrect! ? FontAwesomeIcons.check : FontAwesomeIcons.xmark,
                  color: _isCorrect! ? successGreen : errorRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                TextWidget(
                  text: _isCorrect! ? 'Correct!' : 'Incorrect',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isCorrect! ? successGreen : errorRed,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: _feedback!,
              fontSize: 14,
              color: textPrimary,
            ),
            if (_isCorrect!) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightSpeedGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(FontAwesomeIcons.plus,
                        color: lightSpeedGold, size: 12),
                    const SizedBox(width: 4),
                    TextWidget(
                      text:
                          '+${xpValues[widget.challenge.difficulty]} XP earned!',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: lightSpeedGold,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHintSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            setState(() {
              _showHint = !_showHint;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: infoBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: infoBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                FaIcon(
                  _showHint ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                  color: infoBlue,
                  size: 14,
                ),
                const SizedBox(width: 8),
                TextWidget(
                  text: _showHint ? 'Hide Hint' : 'Show Hint',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: infoBlue,
                ),
                const Spacer(),
                FaIcon(
                  _showHint
                      ? FontAwesomeIcons.chevronUp
                      : FontAwesomeIcons.chevronDown,
                  color: infoBlue,
                  size: 12,
                ),
              ],
            ),
          ),
        ),
        if (_showHint) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextWidget(
              text: widget.challenge.hint,
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormulaReference() {
    String formula = widget.challenge.type == CalculationType.timeDilation
        ? 'Δt = Δt₀ / √(1 - v²/c²)'
        : 'L = L₀ × √(1 - v²/c²)';

    Color formulaColor = widget.challenge.type == CalculationType.timeDilation
        ? timeDilationPurple
        : lengthContractionCyan;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: formulaColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          FaIcon(
            widget.challenge.type == CalculationType.timeDilation
                ? FontAwesomeIcons.clock
                : FontAwesomeIcons.ruler,
            color: formulaColor,
            size: 14,
          ),
          const SizedBox(width: 8),
          TextWidget(
            text: formula,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: formulaColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (!_isSubmitted) ...[
            Expanded(
              child: ButtonWidget(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
                color: surface,
                textColor: textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ButtonWidget(
                label: 'Submit Answer',
                onPressed: _submitAnswer,
                color: _getDifficultyColor(),
                textColor: textOnAccent,
              ),
            ),
          ] else ...[
            if (!_isCorrect!) ...[
              Expanded(
                child: ButtonWidget(
                  label: 'Try Again',
                  onPressed: () {
                    setState(() {
                      _isSubmitted = false;
                      _isCorrect = null;
                      _feedback = null;
                      _answerController.clear();
                    });
                  },
                  color: _getDifficultyColor(),
                  textColor: textOnAccent,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ButtonWidget(
                label: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                color: surface,
                textColor: textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
