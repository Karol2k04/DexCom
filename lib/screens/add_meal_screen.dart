import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

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
  final _carbsController = TextEditingController();
  int selectedIcon = 0;
  TimeOfDay selectedTime = TimeOfDay.now();
  bool showSuccess = false;

  final List<Map<String, dynamic>> mealIcons = [
    {
      'icon': Icons.coffee,
      'emoji': '🍳',
      'label': 'Breakfast',
      'color': AppTheme.warningOrange,
    },
    {
      'icon': Icons.soup_kitchen,
      'emoji': '🍽️',
      'label': 'Lunch',
      'color': AppTheme.primaryBlue,
    },
    {
      'icon': Icons.dinner_dining,
      'emoji': '🍖',
      'label': 'Dinner',
      'color': AppTheme.dangerRed,
    },
    {
      'icon': Icons.apple,
      'emoji': '🍎',
      'label': 'Snack',
      'color': AppTheme.successGreen,
    },
  ];

  @override
  void dispose() {
    _mealNameController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  void handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        showSuccess = true;
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        widget.onBack();
      });
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

            // Węglowodany
            Card(
              elevation: 0,
              color: isDark ? AppTheme.darkCard : AppTheme.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carbs (g)',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _carbsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g. 45',
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
                          return 'Please enter carbohydrate amount';
                        }
                        return null;
                      },
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
              onPressed: handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Meal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
