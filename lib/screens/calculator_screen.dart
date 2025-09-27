import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_state_provider.dart';
import '../services/relativity_calculator.dart';
import '../services/kinematics_calculator.dart';
import '../models/calculation_result.dart';
import '../utils/colors.dart';
import '../widgets/text_widget.dart';
import '../widgets/button_widget.dart';
import '../widgets/app_text_form_field.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _inputController = TextEditingController();
  final _velocityController = TextEditingController();
  final _initialVelocityController = TextEditingController();
  final _finalVelocityController = TextEditingController();
  final _accelerationController = TextEditingController();
  final _timeController = TextEditingController();

  CalculationType _selectedType = CalculationType.timeDilation;
  String _selectedUnit = 'years';
  CalculationResult? _result;
  bool _showGraph = false;
  bool _isLoadingHistory = false;
  List<CalculationResult> _calculationHistory = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _timeUnits = [
    'seconds',
    'minutes',
    'hours',
    'days',
    'years'
  ];
  final List<String> _lengthUnits = ['meters', 'kilometers', 'light-years'];
  final List<String> _velocityUnits = ['m/s', 'km/h', 'mph'];
  final List<String> _accelerationUnits = ['m/s²', 'km/h²'];

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

    // Load calculation history
    _loadCalculationHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _velocityController.dispose();
    _initialVelocityController.dispose();
    _finalVelocityController.dispose();
    _accelerationController.dispose();
    _timeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCalculationHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('calculations')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();

        setState(() {
          _calculationHistory = snapshot.docs.map((doc) {
            final data = doc.data();
            return CalculationResult(
              id: data['id'] ?? doc.id,
              type: CalculationType.values[data['type']],
              inputValue: (data['inputValue'] as num).toDouble(),
              velocity: (data['velocity'] as num).toDouble(),
              result: (data['result'] as num).toDouble(),
              explanation: data['explanation'],
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              unit: data['unit'],
            );
          }).toList();
        });
      }
    } catch (e) {
      // Handle error silently or show a message
      debugPrint('Error loading calculation history: $e');
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _saveCalculationToFirebase(CalculationResult result) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('calculations')
            .doc(result.id)
            .set({
          'id': result.id,
          'type': result.type.index,
          'inputValue': result.inputValue,
          'velocity': result.velocity,
          'result': result.result,
          'explanation': result.explanation,
          'timestamp': result.timestamp,
          'unit': result.unit,
        });

        // Add to local history
        setState(() {
          _calculationHistory.insert(0, result);
          // Keep only last 10 calculations
          if (_calculationHistory.length > 10) {
            _calculationHistory.removeLast();
          }
        });
      }
    } catch (e) {
      // Handle error silently or show a message
      debugPrint('Error saving calculation to Firebase: $e');
    }
  }

  void _calculate() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      CalculationResult result;

      // Handle relativity calculations
      if (_selectedType == CalculationType.timeDilation ||
          _selectedType == CalculationType.lengthContraction) {
        double inputValue = double.parse(_inputController.text);
        double velocity = double.parse(_velocityController.text) /
            100; // Convert percentage to fraction

        if (_selectedType == CalculationType.timeDilation) {
          result = RelativityCalculator.calculateTimeDilation(
            properTime: inputValue,
            velocity: velocity,
            unit: _selectedUnit,
          );
        } else {
          result = RelativityCalculator.calculateLengthContraction(
            properLength: inputValue,
            velocity: velocity,
            unit: _selectedUnit,
          );
        }
      }
      // Handle kinematics calculations
      else {
        double initialVelocity = double.parse(_initialVelocityController.text);

        switch (_selectedType) {
          case CalculationType.displacement:
            double acceleration = double.parse(_accelerationController.text);
            double time = double.parse(_timeController.text);
            result = KinematicsCalculator.calculateDisplacement(
              initialVelocity: initialVelocity,
              acceleration: acceleration,
              time: time,
              unit: _selectedUnit,
            );
            break;

          case CalculationType.velocity:
            double acceleration = double.parse(_accelerationController.text);
            double time = double.parse(_timeController.text);
            result = KinematicsCalculator.calculateVelocity(
              initialVelocity: initialVelocity,
              acceleration: acceleration,
              time: time,
              unit: _selectedUnit,
            );
            break;

          case CalculationType.acceleration:
            double finalVelocity = double.parse(_finalVelocityController.text);
            double time = double.parse(_timeController.text);
            result = KinematicsCalculator.calculateAcceleration(
              initialVelocity: initialVelocity,
              finalVelocity: finalVelocity,
              time: time,
              unit: _selectedUnit,
            );
            break;

          case CalculationType.time:
            double finalVelocity = double.parse(_finalVelocityController.text);
            double acceleration = double.parse(_accelerationController.text);
            result = KinematicsCalculator.calculateTime(
              initialVelocity: initialVelocity,
              finalVelocity: finalVelocity,
              acceleration: acceleration,
              unit: _selectedUnit,
            );
            break;

          default:
            throw Exception('Unknown calculation type');
        }
      }

      setState(() {
        _result = result;
        _showGraph = true;
      });

      _animationController.forward();

      // Add to calculation history
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      provider.addCalculationResult(result);

      // Save to Firebase
      await _saveCalculationToFirebase(result);

      // Haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorSnackBar('Please check your input values');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String? _validateInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    }
    double? parsed = double.tryParse(value);
    if (parsed == null) {
      return 'Please enter a valid number';
    }
    if (parsed <= 0) {
      return 'Value must be positive';
    }
    return null;
  }

  String? _validateVelocity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter velocity';
    }
    double? parsed = double.tryParse(value);
    if (parsed == null) {
      return 'Please enter a valid number';
    }
    if (parsed < 1) {
      return 'Velocity must be at least 1%';
    }
    if (parsed >= 100) {
      return 'Velocity must be less than 100%';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: TextWidget(
          text: 'Relativity Calculator',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        backgroundColor: primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.history),
            onPressed: _loadCalculationHistory,
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.chartLine),
            onPressed: () {
              setState(() {
                _showGraph = !_showGraph;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calculation type selector
              _buildCalculationTypeSelector(),
              const SizedBox(height: 24),

              // Input fields
              _buildInputFields(),
              const SizedBox(height: 24),

              // Calculate button
              SizedBox(
                width: double.infinity,
                child: ButtonWidget(
                  label: 'Calculate',
                  onPressed: _calculate,
                  color: accent,
                  textColor: textOnAccent,
                ),
              ),
              const SizedBox(height: 24),

              // Results display
              if (_result != null) ...[
                _buildResultsDisplay(),
                const SizedBox(height: 24),
              ],

              // Calculation history
              _buildCalculationHistory(),
              const SizedBox(height: 24),

              // Graph display
              if (_showGraph) _buildGraphDisplay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculationTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Relativity calculations row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = CalculationType.timeDilation;
                      _selectedUnit = 'years';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedType == CalculationType.timeDilation
                          ? timeDilationPurple
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.clock,
                          color: _selectedType == CalculationType.timeDilation
                              ? textOnAccent
                              : textSecondary,
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text: 'Time Dilation',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _selectedType == CalculationType.timeDilation
                              ? textOnAccent
                              : textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = CalculationType.lengthContraction;
                      _selectedUnit = 'meters';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedType == CalculationType.lengthContraction
                          ? lengthContractionCyan
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.ruler,
                          color:
                              _selectedType == CalculationType.lengthContraction
                                  ? textOnAccent
                                  : textSecondary,
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text: 'Length Contraction',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color:
                              _selectedType == CalculationType.lengthContraction
                                  ? textOnAccent
                                  : textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Kinematics calculations row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = CalculationType.displacement;
                      _selectedUnit = 'meters';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedType == CalculationType.displacement
                          ? Colors.orange
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.arrowsLeftRight,
                          color: _selectedType == CalculationType.displacement
                              ? textOnAccent
                              : textSecondary,
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text: 'Displacement',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _selectedType == CalculationType.displacement
                              ? textOnAccent
                              : textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = CalculationType.velocity;
                      _selectedUnit = 'm/s';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedType == CalculationType.velocity
                          ? Colors.green
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.gaugeHigh,
                          color: _selectedType == CalculationType.velocity
                              ? textOnAccent
                              : textSecondary,
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text: 'Velocity',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _selectedType == CalculationType.velocity
                              ? textOnAccent
                              : textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Second row of kinematics calculations
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = CalculationType.acceleration;
                      _selectedUnit = 'm/s²';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedType == CalculationType.acceleration
                          ? Colors.red
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.rocket,
                          color: _selectedType == CalculationType.acceleration
                              ? textOnAccent
                              : textSecondary,
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text: 'Acceleration',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _selectedType == CalculationType.acceleration
                              ? textOnAccent
                              : textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = CalculationType.time;
                      _selectedUnit = 'seconds';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedType == CalculationType.time
                          ? Colors.purple
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.hourglassHalf,
                          color: _selectedType == CalculationType.time
                              ? textOnAccent
                              : textSecondary,
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text: 'Time',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _selectedType == CalculationType.time
                              ? textOnAccent
                              : textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    // For relativity calculations
    if (_selectedType == CalculationType.timeDilation ||
        _selectedType == CalculationType.lengthContraction) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AppTextFormField(
                  controller: _inputController,
                  labelText: _selectedType == CalculationType.timeDilation
                      ? 'Proper Time'
                      : 'Proper Length',
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  validator: _validateInput,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: (_selectedType == CalculationType.timeDilation
                          ? _timeUnits
                          : _lengthUnits)
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUnit = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextFormField(
            textInputAction: TextInputAction.done,
            controller: _velocityController,
            labelText: 'Velocity (% of light speed)',
            keyboardType: TextInputType.number,
            validator: _validateVelocity,
            suffixIcon: const Icon(Icons.speed),
          ),
        ],
      );
    }

    // For kinematics calculations
    List<String> units = [];
    String inputLabel1 = '';
    String inputLabel2 = '';
    String inputLabel3 = '';

    switch (_selectedType) {
      case CalculationType.displacement:
        units = _lengthUnits;
        inputLabel1 = 'Initial Velocity';
        inputLabel2 = 'Acceleration';
        inputLabel3 = 'Time';
        break;
      case CalculationType.velocity:
        units = _velocityUnits;
        inputLabel1 = 'Initial Velocity';
        inputLabel2 = 'Acceleration';
        inputLabel3 = 'Time';
        break;
      case CalculationType.acceleration:
        units = _accelerationUnits;
        inputLabel1 = 'Initial Velocity';
        inputLabel2 = 'Final Velocity';
        inputLabel3 = 'Time';
        break;
      case CalculationType.time:
        units = _timeUnits;
        inputLabel1 = 'Initial Velocity';
        inputLabel2 = 'Final Velocity';
        inputLabel3 = 'Acceleration';
        break;
      default:
        return Container(); // Should not happen
    }

    return Column(
      children: [
        // First input field
        AppTextFormField(
          controller: _initialVelocityController,
          labelText: inputLabel1,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.number,
          validator: _validateInput,
        ),
        const SizedBox(height: 16),

        // Second input field
        AppTextFormField(
          controller: _selectedType == CalculationType.displacement ||
                  _selectedType == CalculationType.velocity
              ? _accelerationController
              : _finalVelocityController,
          labelText: inputLabel2,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.number,
          validator: _validateInput,
        ),
        const SizedBox(height: 16),

        // Third input field
        AppTextFormField(
          controller: _selectedType == CalculationType.displacement ||
                  _selectedType == CalculationType.velocity
              ? _timeController
              : _accelerationController,
          labelText: inputLabel3,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.number,
          validator: _validateInput,
        ),
        const SizedBox(height: 16),

        // Unit selector
        DropdownButtonFormField<String>(
          value: _selectedUnit,
          decoration: InputDecoration(
            labelText: 'Unit',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: units
              .map((unit) => DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedUnit = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildResultsDisplay() {
    // Determine colors and icons based on calculation type
    Color primaryColor;
    Color secondaryColor;
    IconData icon;

    if (_selectedType == CalculationType.timeDilation) {
      primaryColor = timeDilationPurple;
      secondaryColor = timeDilationPurple.withOpacity(0.2);
      icon = FontAwesomeIcons.clock;
    } else if (_selectedType == CalculationType.lengthContraction) {
      primaryColor = lengthContractionCyan;
      secondaryColor = lengthContractionCyan.withOpacity(0.2);
      icon = FontAwesomeIcons.ruler;
    } else if (_selectedType == CalculationType.displacement) {
      primaryColor = Colors.orange;
      secondaryColor = Colors.orange.withOpacity(0.2);
      icon = FontAwesomeIcons.arrowsLeftRight;
    } else if (_selectedType == CalculationType.velocity) {
      primaryColor = Colors.green;
      secondaryColor = Colors.green.withOpacity(0.2);
      icon = FontAwesomeIcons.gaugeHigh;
    } else if (_selectedType == CalculationType.acceleration) {
      primaryColor = Colors.red;
      secondaryColor = Colors.red.withOpacity(0.2);
      icon = FontAwesomeIcons.rocket;
    } else {
      // time
      primaryColor = Colors.purple;
      secondaryColor = Colors.purple.withOpacity(0.2);
      icon = FontAwesomeIcons.hourglassHalf;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [secondaryColor, secondaryColor.withOpacity(0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(
                    icon,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  TextWidget(
                    text: _selectedType.displayName,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text:
                          'Result: ${_result!.result.toStringAsFixed(3)} ${_result!.unit}',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                    const SizedBox(height: 8),

                    // Show different information based on calculation type
                    if (_selectedType == CalculationType.timeDilation ||
                        _selectedType == CalculationType.lengthContraction) ...[
                      TextWidget(
                        text:
                            'Input: ${_result!.inputValue.toStringAsFixed(2)} ${_result!.unit}',
                        fontSize: 14,
                        color: textSecondary,
                      ),
                      TextWidget(
                        text:
                            'Velocity: ${(_result!.velocity * 100).toStringAsFixed(1)}% of light speed',
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ] else ...[
                      // For kinematics calculations, show the formula
                      TextWidget(
                        text: 'Formula: ${_selectedType.formula}',
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                title: TextWidget(
                  text: 'Detailed Explanation',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextWidget(
                      text: _result!.explanation,
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculationHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextWidget(
              text: 'Recent Calculations',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            const Spacer(),
            if (_isLoadingHistory)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_calculationHistory.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextWidget(
              text: 'No calculation history yet. Start calculating!',
              fontSize: 14,
              color: textSecondary,
              align: TextAlign.center,
            ),
          ),
        ] else ...[
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _calculationHistory.take(5).map((calc) {
                return _buildHistoryItem(calc);
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoryItem(CalculationResult calc) {
    // Determine icon and color based on calculation type
    IconData icon;
    Color iconColor;

    if (calc.type == CalculationType.timeDilation) {
      icon = FontAwesomeIcons.clock;
      iconColor = timeDilationPurple;
    } else if (calc.type == CalculationType.lengthContraction) {
      icon = FontAwesomeIcons.ruler;
      iconColor = lengthContractionCyan;
    } else if (calc.type == CalculationType.displacement) {
      icon = FontAwesomeIcons.arrowsLeftRight;
      iconColor = Colors.orange;
    } else if (calc.type == CalculationType.velocity) {
      icon = FontAwesomeIcons.gaugeHigh;
      iconColor = Colors.green;
    } else if (calc.type == CalculationType.acceleration) {
      icon = FontAwesomeIcons.rocket;
      iconColor = Colors.red;
    } else {
      // time
      icon = FontAwesomeIcons.hourglassHalf;
      iconColor = Colors.purple;
    }

    // Format the subtitle based on calculation type
    String subtitle;
    if (calc.type == CalculationType.timeDilation ||
        calc.type == CalculationType.lengthContraction) {
      subtitle =
          '${(calc.velocity * 100).toStringAsFixed(0)}%c • ${_formatDateTime(calc.timestamp)}';
    } else {
      subtitle = '${_formatDateTime(calc.timestamp)}';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white10, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          FaIcon(
            icon,
            color: iconColor,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text:
                      '${calc.inputValue.toStringAsFixed(1)} ${calc.unit} → ${calc.result.toStringAsFixed(2)} ${calc.unit}',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                TextWidget(
                  text: subtitle,
                  fontSize: 12,
                  color: textSecondary,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.play, size: 16),
            onPressed: () {
              // Load this calculation into the form
              setState(() {
                _selectedType = calc.type;
                _selectedUnit = calc.unit;

                // Set appropriate input fields based on calculation type
                if (calc.type == CalculationType.timeDilation ||
                    calc.type == CalculationType.lengthContraction) {
                  _inputController.text = calc.inputValue.toStringAsFixed(2);
                  _velocityController.text =
                      (calc.velocity * 100).toStringAsFixed(1);
                } else {
                  // For kinematics calculations, we need to set multiple fields
                  // This is a simplified version - in a real app, we'd need to store all input values
                  _initialVelocityController.text =
                      calc.inputValue.toStringAsFixed(2);

                  if (calc.type == CalculationType.displacement ||
                      calc.type == CalculationType.velocity) {
                    // For these types, velocity field stores acceleration
                    _accelerationController.text =
                        calc.velocity.toStringAsFixed(2);
                    _timeController.text = "5.0"; // Default time
                  } else if (calc.type == CalculationType.acceleration) {
                    // For acceleration, velocity field stores final velocity
                    _finalVelocityController.text =
                        calc.velocity.toStringAsFixed(2);
                    _timeController.text = "5.0"; // Default time
                  } else {
                    // time
                    // For time, velocity field stores final velocity
                    _finalVelocityController.text =
                        calc.velocity.toStringAsFixed(2);
                    _accelerationController.text =
                        "2.0"; // Default acceleration
                  }
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGraphDisplay() {
    final data = _selectedType == CalculationType.timeDilation
        ? RelativityCalculator.generateTimeDilationGraph()
        : RelativityCalculator.generateLengthContractionGraph();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: 'Velocity vs ${_selectedType.displayName}',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value * 100).toInt()}%',
                          style: const TextStyle(
                              color: textSecondary, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(
                              color: textSecondary, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: data
                        .map((point) => FlSpot(
                              point['velocity']!,
                              _selectedType == CalculationType.timeDilation
                                  ? point['dilation']!
                                  : point['contraction']!,
                            ))
                        .toList(),
                    isCurved: true,
                    color: _selectedType == CalculationType.timeDilation
                        ? timeDilationPurple
                        : lengthContractionCyan,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
