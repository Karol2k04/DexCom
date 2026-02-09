import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class MealsHistoryScreen extends StatefulWidget {
  const MealsHistoryScreen({super.key});

  @override
  State<MealsHistoryScreen> createState() => _MealsHistoryScreenState();
}

class _MealsHistoryScreenState extends State<MealsHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _selectedDate = DateTime.now();
  MealType? _filterMealType;

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday =
        _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Scaffold(
      appBar: AppBar(title: const Text('🍽️ Meal History'), elevation: 0),
      body: Column(
        children: [
          // Date selector
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppTheme.darkCard : AppTheme.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousDay,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Column(
                        children: [
                          Text(
                            DateFormat('EEEE').format(_selectedDate),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(_selectedDate),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: isToday ? null : _nextDay,
                      icon: Icon(
                        Icons.chevron_right,
                        color: isToday ? Colors.grey : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Meal type filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      const SizedBox(width: 8),
                      ...MealType.values.map((type) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            '${type.emoji} ${type.displayName}',
                            type,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Meals list
          Expanded(
            child: StreamBuilder<List<Meal>>(
              stream: _firestoreService.getMealsStream(
                startDate: DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                ),
                endDate: DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  23,
                  59,
                  59,
                ),
                mealType: _filterMealType,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final meals = snapshot.data ?? [];

                if (meals.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '🍽️',
                          style: TextStyle(
                            fontSize: 64,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No meals recorded',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start tracking your meals!',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate daily totals
                final dailyTotals = _calculateDailyTotals(meals);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Daily summary card
                    Card(
                      elevation: 0,
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📊 Daily Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem(
                                  '🔥',
                                  '${dailyTotals['calories']!.toStringAsFixed(0)} kcal',
                                  'Calories',
                                ),
                                _buildSummaryItem(
                                  '🍞',
                                  '${dailyTotals['carbs']!.toStringAsFixed(1)}g',
                                  'Carbs',
                                ),
                                _buildSummaryItem(
                                  '🥩',
                                  '${dailyTotals['protein']!.toStringAsFixed(1)}g',
                                  'Protein',
                                ),
                                _buildSummaryItem(
                                  '🧈',
                                  '${dailyTotals['fat']!.toStringAsFixed(1)}g',
                                  'Fat',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Meals list grouped by type
                    ...meals.map((meal) => _buildMealCard(meal, isDark)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, MealType? type) {
    final isSelected = _filterMealType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterMealType = selected ? type : null;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppTheme.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.white : AppTheme.darkGray,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSummaryItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildMealCard(Meal meal, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDark ? AppTheme.darkCard : AppTheme.white,
      child: InkWell(
        onTap: () => _showMealDetails(meal),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.mealType.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meal.foodName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    meal.formattedTime,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildNutrientBadge(
                    '${meal.nutritionalData.calories.toStringAsFixed(0)} kcal',
                    Icons.local_fire_department,
                    AppTheme.warningOrange,
                  ),
                  const SizedBox(width: 8),
                  _buildNutrientBadge(
                    '${meal.nutritionalData.carbs.toStringAsFixed(1)}g carbs',
                    Icons.grain,
                    AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  _buildNutrientBadge(
                    '${meal.nutritionalData.protein.toStringAsFixed(1)}g protein',
                    Icons.fitness_center,
                    AppTheme.successGreen,
                  ),
                ],
              ),
              if (meal.glucoseImpact != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getRiskColor(
                      meal.glucoseImpact!.riskLevel,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 16,
                        color: _getRiskColor(meal.glucoseImpact!.riskLevel),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Predicted peak: ${meal.glucoseImpact!.predictedPeakGlucose.toStringAsFixed(0)} mg/dL',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getRiskColor(meal.glucoseImpact!.riskLevel),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showMealDetails(Meal meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      meal.mealType.emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.mealType.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            meal.foodName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${meal.formattedDate} at ${meal.formattedTime}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                const Text(
                  '📊 Nutritional Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Calories',
                  '${meal.nutritionalData.calories.toStringAsFixed(0)} kcal',
                ),
                _buildDetailRow(
                  'Carbohydrates',
                  '${meal.nutritionalData.carbs.toStringAsFixed(1)}g',
                ),
                _buildDetailRow(
                  '  - Sugar',
                  '${meal.nutritionalData.sugar.toStringAsFixed(1)}g',
                ),
                _buildDetailRow(
                  '  - Fiber',
                  '${meal.nutritionalData.fiber.toStringAsFixed(1)}g',
                ),
                _buildDetailRow(
                  'Protein',
                  '${meal.nutritionalData.protein.toStringAsFixed(1)}g',
                ),
                _buildDetailRow(
                  'Fat',
                  '${meal.nutritionalData.fat.toStringAsFixed(1)}g',
                ),
                _buildDetailRow(
                  'Serving Size',
                  '${meal.nutritionalData.servingSize.toStringAsFixed(0)} ${meal.nutritionalData.servingUnit}',
                ),
                if (meal.glucoseImpact != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    '📈 Glucose Impact',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getRiskColor(
                        meal.glucoseImpact!.riskLevel,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          'Current Glucose',
                          '${meal.glucoseImpact!.currentGlucose.toStringAsFixed(0)} mg/dL',
                        ),
                        _buildDetailRow(
                          'Predicted Increase',
                          '+${meal.glucoseImpact!.predictedIncrease.toStringAsFixed(0)} mg/dL',
                        ),
                        _buildDetailRow(
                          'Predicted Peak',
                          '${meal.glucoseImpact!.predictedPeakGlucose.toStringAsFixed(0)} mg/dL',
                        ),
                        _buildDetailRow(
                          'Time to Process',
                          '~${meal.glucoseImpact!.timeToProcessMinutes} minutes',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Risk Level: ${meal.glucoseImpact!.riskLevel}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getRiskColor(meal.glucoseImpact!.riskLevel),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          meal.glucoseImpact!.recommendation,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
                if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    '📝 Notes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(meal.notes!, style: const TextStyle(fontSize: 14)),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteMeal(meal);
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: AppTheme.dangerRed,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: AppTheme.dangerRed),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _deleteMeal(Meal meal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text('Are you sure you want to delete "${meal.foodName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteMeal(meal.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Meal deleted'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting meal: $e'),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
      }
    }
  }

  Map<String, double> _calculateDailyTotals(List<Meal> meals) {
    double totalCalories = 0;
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (final meal in meals) {
      totalCalories += meal.nutritionalData.calories;
      totalCarbs += meal.nutritionalData.carbs;
      totalProtein += meal.nutritionalData.protein;
      totalFat += meal.nutritionalData.fat;
    }

    return {
      'calories': totalCalories,
      'carbs': totalCarbs,
      'protein': totalProtein,
      'fat': totalFat,
    };
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
