import 'package:flutter/material.dart';

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
    {'icon': Icons.coffee, 'label': 'Śniadanie', 'color': Colors.amber},
    {'icon': Icons.soup_kitchen, 'label': 'Obiad', 'color': Colors.orange},
    {'icon': Icons.dinner_dining, 'label': 'Kolacja', 'color': Colors.red},
    {'icon': Icons.apple, 'label': 'Przekąska', 'color': Colors.green},
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
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Posiłek zapisany!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  'Dodaj posiłek',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Typ posiłku
            Card(
              elevation: 0,
              color: isDark ? Colors.grey[850] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Typ posiłku',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                                  ? (item['color'] as Color).withOpacity(0.2)
                                  : (isDark
                                        ? Colors.grey[700]
                                        : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item['icon'] as IconData,
                                  color: item['color'] as Color,
                                  size: 28,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['label'] as String,
                                  style: TextStyle(fontSize: 10),
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
            ),
            const SizedBox(height: 16),

            // Nazwa posiłku
            Card(
              elevation: 0,
              color: isDark ? Colors.grey[850] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nazwa posiłku',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _mealNameController,
                      decoration: InputDecoration(
                        hintText: 'np. Płatki owsiane z owocami',
                        filled: true,
                        fillColor: isDark ? Colors.grey[700] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Proszę podać nazwę posiłku';
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
              color: isDark ? Colors.grey[850] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Węglowodany (g)',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _carbsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'np. 45',
                        filled: true,
                        fillColor: isDark ? Colors.grey[700] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Proszę podać ilość węglowodanów';
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
              color: isDark ? Colors.grey[850] : Colors.white,
              child: ListTile(
                leading: Icon(Icons.access_time, color: Colors.blue),
                title: const Text('Czas'),
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Zapisz posiłek',
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
