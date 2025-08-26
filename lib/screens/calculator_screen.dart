import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state_provider.dart';
import '../services/relativity_calculator.dart';
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

  CalculationType _selectedType = CalculationType.timeDilation;
  String _selectedUnit = 'years';
  CalculationResult? _result;
  bool _showGraph = false;

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
  }

  @override
  void dispose() {
    _inputController.dispose();
    _velocityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    try {
      double inputValue = double.parse(_inputController.text);
      double velocity = double.parse(_velocityController.text) /
          100; // Convert percentage to fraction

      CalculationResult result;

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

      setState(() {
        _result = result;
        _showGraph = true;
      });

      _animationController.forward();

      // Add to calculation history
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      provider.addCalculationResult(result);

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
      child: Row(
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
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                      color: _selectedType == CalculationType.lengthContraction
                          ? textOnAccent
                          : textSecondary,
                    ),
                    const SizedBox(height: 4),
                    TextWidget(
                      text: 'Length Contraction',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _selectedType == CalculationType.lengthContraction
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
    );
  }

  Widget _buildInputFields() {
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

  Widget _buildResultsDisplay() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _selectedType == CalculationType.timeDilation
                  ? [
                      timeDilationPurple.withOpacity(0.2),
                      timeDilationPurple.withOpacity(0.1)
                    ]
                  : [
                      lengthContractionCyan.withOpacity(0.2),
                      lengthContractionCyan.withOpacity(0.1)
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectedType == CalculationType.timeDilation
                  ? timeDilationPurple
                  : lengthContractionCyan,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(
                    _selectedType == CalculationType.timeDilation
                        ? FontAwesomeIcons.clock
                        : FontAwesomeIcons.ruler,
                    color: _selectedType == CalculationType.timeDilation
                        ? timeDilationPurple
                        : lengthContractionCyan,
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
}
