import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/glucose_reading.dart';
import '../../models/meal.dart';
import '../../services/doctor_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class PatientDetailsScreen extends StatefulWidget {
  final UserProfile patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final DoctorService _doctorService = DoctorService();
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? _statistics;
  bool _loadingStats = true;
  int _selectedTab = 0; // 0 = Glucose, 1 = Meals

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _loadingStats = true);
    try {
      final stats = await _doctorService.getPatientStatistics(
        widget.patient.uid,
      );
      setState(() {
        _statistics = stats;
        _loadingStats = false;
      });
    } catch (e) {
      setState(() => _loadingStats = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd ładowania statystyk: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient.displayName),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: AppTheme.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informacje o pacjencie
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppTheme.primaryBlue.withOpacity(0.1),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryBlue,
                    child: Text(
                      widget.patient.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.patient.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.patient.email,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTab == 0
                                  ? AppTheme.primaryBlue
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          '📊 Glucose',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: _selectedTab == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _selectedTab == 0
                                ? AppTheme.primaryBlue
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTab == 1
                                  ? AppTheme.primaryBlue
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          '🍽️ Meals',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: _selectedTab == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _selectedTab == 1
                                ? AppTheme.primaryBlue
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Statystyki
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statystyki (30 dni)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_loadingStats)
                    const Center(child: CircularProgressIndicator())
                  else if (_statistics != null)
                    _buildStatisticsCards(_statistics!)
                  else
                    const Center(child: Text('Brak danych')),
                ],
              ),
            ),

            // Wykres odczytów glukozy
            if (_selectedTab == 0)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ostatnie odczyty',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<GlucoseReading>>(
                      stream: _doctorService.getPatientGlucoseReadings(
                        widget.patient.uid,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('Brak odczytów glukozy'),
                            ),
                          );
                        }

                        final readings = snapshot.data!;
                        return _buildReadingsList(readings);
                      },
                    ),
                  ],
                ),
              ),

            // Patient meals
            if (_selectedTab == 1)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ostatnie posiłki',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<Meal>>(
                      stream: _firestoreService.getPatientMealsStream(
                        patientId: widget.patient.uid,
                        limit: 30,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('Brak zarejestrowanych posiłków'),
                            ),
                          );
                        }

                        final meals = snapshot.data!;
                        return _buildMealsList(meals);
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Średnia',
          '${stats['average'].toStringAsFixed(0)} mg/dL',
          Icons.show_chart,
          AppTheme.primaryBlue,
        ),
        _buildStatCard(
          'Czas w zakresie',
          '${stats['timeInRange'].toStringAsFixed(1)}%',
          Icons.timer,
          AppTheme.successGreen,
        ),
        _buildStatCard(
          'Min',
          '${stats['min'].toStringAsFixed(0)} mg/dL',
          Icons.arrow_downward,
          AppTheme.lowRed,
        ),
        _buildStatCard(
          'Max',
          '${stats['max'].toStringAsFixed(0)} mg/dL',
          Icons.arrow_upward,
          AppTheme.warningOrange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingsList(List<GlucoseReading> readings) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: readings.length > 20 ? 20 : readings.length,
      itemBuilder: (context, index) {
        final reading = readings[index];
        final date = DateTime.fromMillisecondsSinceEpoch(reading.timestamp);
        final value = reading.value;

        Color valueColor = AppTheme.successGreen;
        if (value < 70) {
          valueColor = AppTheme.lowRed;
        } else if (value > 180) {
          valueColor = AppTheme.warningOrange;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: valueColor.withOpacity(0.1),
              child: Icon(Icons.water_drop, color: valueColor),
            ),
            title: Text(
              '${value.toStringAsFixed(0)} mg/dL',
              style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
            ),
            subtitle: Text(
              '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealsList(List<Meal> meals) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                meal.mealType.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            title: Text(
              meal.foodName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${DateFormat('MMM d, yyyy').format(meal.timestamp)} at ${meal.formattedTime} • ${meal.mealType.displayName}',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nutritional Info:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMealDetailRow(
                      'Calories',
                      '${meal.nutritionalData.calories.toStringAsFixed(0)} kcal',
                    ),
                    _buildMealDetailRow(
                      'Carbs',
                      '${meal.nutritionalData.carbs.toStringAsFixed(1)}g',
                    ),
                    _buildMealDetailRow(
                      'Protein',
                      '${meal.nutritionalData.protein.toStringAsFixed(1)}g',
                    ),
                    _buildMealDetailRow(
                      'Fat',
                      '${meal.nutritionalData.fat.toStringAsFixed(1)}g',
                    ),
                    if (meal.glucoseImpact != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Glucose Impact:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getRiskColor(
                            meal.glucoseImpact!.riskLevel,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMealDetailRow(
                              'Predicted Peak',
                              '${meal.glucoseImpact!.predictedPeakGlucose.toStringAsFixed(0)} mg/dL',
                            ),
                            _buildMealDetailRow(
                              'Risk Level',
                              meal.glucoseImpact!.riskLevel,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              meal.glucoseImpact!.recommendation,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Notes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meal.notes!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Low':
        return AppTheme.successGreen;
      case 'Moderate':
        return AppTheme.warningOrange;
      case 'High':
        return AppTheme.dangerRed;
      case 'Very High':
        return AppTheme.lowRed;
      default:
        return AppTheme.primaryBlue;
    }
  }
}
