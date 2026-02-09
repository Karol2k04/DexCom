import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../models/meal.dart';
import '../services/firestore_service.dart';
import '../providers/glucose_provider.dart';

// Ekran dodawania posiłku
class AddMealScreen extends StatefulWidget {
  final VoidCallback onBack;

  const AddMealScreen({super.key, required this.onBack});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mealNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();
  final _sugarController = TextEditingController();
  final _notesController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  int selectedIcon = 0;
  TimeOfDay selectedTime = TimeOfDay.now();
  bool showSuccess = false;
  bool _isSaving = false;

  final List<Map<String, dynamic>> mealIcons = [
    {
      'icon': Icons.coffee,
      'emoji': '🍳',
      'label': 'Breakfast',
      'type': MealType.breakfast,
      'color': AppTheme.warningOrange,
    },
    {
      'icon': Icons.soup_kitchen,
      'emoji': '🍽️',
      'label': 'Lunch',
      'type': MealType.lunch,
      'color': AppTheme.primaryBlue,
    },
    {
      'icon': Icons.dinner_dining,
      'emoji': '🍖',
      'label': 'Dinner',
      'type': MealType.dinner,
      'color': AppTheme.dangerRed,
    },
    {
      'icon': Icons.apple,
      'emoji': '🍎',
      'label': 'Snack',
      'type': MealType.snack,
      'color': AppTheme.successGreen,
    },
  ];

  @override
  void dispose() {
    _mealNameController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final now = DateTime.now();
        final mealDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        final glucoseProvider = Provider.of<GlucoseProvider>(
          context,
          listen: false,
        );
        final currentGlucose = glucoseProvider.glucoseData.isNotEmpty
            ? glucoseProvider.glucoseData.last.value
            : 0.0;

        final meal = Meal(
          id: '',
          userId: '',
          mealType: mealIcons[selectedIcon]['type'] as MealType,
          foodName: _mealNameController.text.trim(),
          timestamp: mealDateTime,
          imageUrl: null,
          nutritionalData: NutritionalData(
            calories: double.tryParse(_caloriesController.text) ?? 0,
            carbs: double.tryParse(_carbsController.text) ?? 0,
            protein: double.tryParse(_proteinController.text) ?? 0,
            fat: double.tryParse(_fatController.text) ?? 0,
            fiber: double.tryParse(_fiberController.text) ?? 0,
            sugar: double.tryParse(_sugarController.text) ?? 0,
            servingSize: 100,
            servingUnit: 'g',
          ),
          glucoseImpact: currentGlucose > 0
              ? GlucoseImpact(
                  currentGlucose: currentGlucose,
                  predictedIncrease:
                      (double.tryParse(_carbsController.text) ?? 0) * 4.0,
                  predictedPeakGlucose:
                      currentGlucose +
                      ((double.tryParse(_carbsController.text) ?? 0) * 4.0),
                  timeToProcessMinutes: 90,
                  riskLevel: 'Moderate',
                  recommendation:
                      'Monitor your glucose levels after this meal.',
                )
              : null,
          notes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
        );

        await _firestoreService.saveMeal(meal);

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ ${mealIcons[selectedIcon]['emoji']} Meal saved successfully!',
              ),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );

          // Reset form
          setState(() {
            _mealNameController.clear();
            _caloriesController.clear();
            _carbsController.clear();
            _proteinController.clear();
            _fatController.clear();
            _fiberController.clear();
            _sugarController.clear();
            _notesController.clear();
            selectedIcon = 0;
            selectedTime = TimeOfDay.now();
            _isSaving = false;
          });

          // Reset form validation
          _formKey.currentState?.reset();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving meal: $e'),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (showSuccess) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.successGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successGreen.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.check, size: 48, color: AppTheme.white),
            ),
            const SizedBox(height: 16),
            const Text(
              '✅ Meal saved!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your meal has been recorded',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header z przyciskiem wstecz
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Text(
                  '🍴 Add Meal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Typ posiłku (glass)
            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(16),
              blur: 6.0,
              overlayColor: isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.white.withOpacity(0.6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meal type',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : AppTheme.darkGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: mealIcons.length,
                    itemBuilder: (context, index) {
                      final item = mealIcons[index];
                      final isSelected = selectedIcon == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIcon = index;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (item['color'] as Color).withOpacity(0.25)
                                : (isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: item['color'] as Color,
                                    width: 2.5,
                                  )
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: (item['color'] as Color)
                                          .withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['emoji'] as String,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['label'] as String,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nazwa posiłku
            Card(
              elevation: 0,
              color: isDark ? AppTheme.darkCard : AppTheme.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meal name',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _mealNameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Oatmeal with fruits',
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.darkSurface
                            : AppTheme.lightGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the meal name';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nutritional Information Card
            Card(
              elevation: 0,
              color: isDark ? AppTheme.darkCard : AppTheme.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Nutritional Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Calories
                    _buildNutrientField(
                      controller: _caloriesController,
                      label: 'Calories',
                      hint: 'e.g. 250',
                      icon: Icons.local_fire_department,
                      iconColor: AppTheme.warningOrange,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // Carbs
                    _buildNutrientField(
                      controller: _carbsController,
                      label: 'Carbohydrates (g)',
                      hint: 'e.g. 45',
                      icon: Icons.grain,
                      iconColor: AppTheme.primaryBlue,
                      isDark: isDark,
                      required: true,
                    ),
                    const SizedBox(height: 12),

                    // Protein
                    _buildNutrientField(
                      controller: _proteinController,
                      label: 'Protein (g)',
                      hint: 'e.g. 15',
                      icon: Icons.fitness_center,
                      iconColor: AppTheme.successGreen,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // Fat
                    _buildNutrientField(
                      controller: _fatController,
                      label: 'Fat (g)',
                      hint: 'e.g. 8',
                      icon: Icons.water_drop,
                      iconColor: Colors.amber,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // Sugar
                    _buildNutrientField(
                      controller: _sugarController,
                      label: 'Sugar (g)',
                      hint: 'e.g. 10',
                      icon: Icons.cookie,
                      iconColor: AppTheme.dangerRed,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // Fiber
                    _buildNutrientField(
                      controller: _fiberController,
                      label: 'Fiber (g)',
                      hint: 'e.g. 5',
                      icon: Icons.eco,
                      iconColor: AppTheme.successGreen,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Card(
              elevation: 0,
              color: isDark ? AppTheme.darkCard : AppTheme.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 Notes (optional)',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Add any notes...',
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.darkSurface
                            : AppTheme.lightGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Czas
            Card(
              elevation: 0,
              color: isDark ? AppTheme.darkCard : AppTheme.white,
              child: ListTile(
                leading: const Icon(
                  Icons.access_time,
                  color: AppTheme.primaryBlue,
                ),
                title: const Text('Time'),
                subtitle: Text(selectedTime.format(context)),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedTime = picked;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // Przycisk zapisu
            ElevatedButton(
              onPressed: _isSaving ? null : handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.white,
                        ),
                      ),
                    )
                  : const Text(
                      'Save Meal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    bool required = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              filled: true,
              fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            validator: required
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
