// screens/food_scan_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/nutrivision_service.dart';
import '../services/firestore_service.dart';
import '../providers/glucose_provider.dart';
import '../models/meal.dart';
import '../theme/app_theme.dart';

class FoodScanScreen extends StatefulWidget {
  const FoodScanScreen({super.key});

  @override
  State<FoodScanScreen> createState() => _FoodScanScreenState();
}

class _FoodScanScreenState extends State<FoodScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final NutriVisionService _nutritionService = NutriVisionService();
  final FirestoreService _firestoreService = FirestoreService();

  File? _imageFile;
  Uint8List? _webImage; // For web support
  bool _isAnalyzing = false;
  bool _isSaving = false;
  bool _isEditing = false;
  NutritionalInfo? _nutritionInfo;
  GlucosePrediction? _prediction;
  String? _errorMessage;
  MealType _selectedMealType = MealType.breakfast;
  final TextEditingController _notesController = TextEditingController();

  // Controllers for editing nutritional values
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _fiberController = TextEditingController();
  final TextEditingController _sugarController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _foodNameController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    super.dispose();
  }

  void _populateEditControllers() {
    if (_nutritionInfo != null) {
      _foodNameController.text = _nutritionInfo!.foodName;
      _caloriesController.text = _nutritionInfo!.calories.toStringAsFixed(0);
      _carbsController.text = _nutritionInfo!.carbs.toStringAsFixed(1);
      _proteinController.text = _nutritionInfo!.protein.toStringAsFixed(1);
      _fatController.text = _nutritionInfo!.fat.toStringAsFixed(1);
      _fiberController.text = _nutritionInfo!.fiber.toStringAsFixed(1);
      _sugarController.text = _nutritionInfo!.sugar.toStringAsFixed(1);
    }
  }

  void _updateNutritionFromControllers() {
    if (_nutritionInfo != null) {
      setState(() {
        _nutritionInfo = NutritionalInfo(
          foodName: _foodNameController.text,
          calories: double.tryParse(_caloriesController.text) ?? 0,
          carbs: double.tryParse(_carbsController.text) ?? 0,
          protein: double.tryParse(_proteinController.text) ?? 0,
          fat: double.tryParse(_fatController.text) ?? 0,
          fiber: double.tryParse(_fiberController.text) ?? 0,
          sugar: double.tryParse(_sugarController.text) ?? 0,
          servingSize: _nutritionInfo!.servingSize,
          servingUnit: _nutritionInfo!.servingUnit,
        );

        // Recalculate prediction
        final glucoseProvider = Provider.of<GlucoseProvider>(
          context,
          listen: false,
        );
        final currentGlucose = glucoseProvider.glucoseData.isNotEmpty
            ? glucoseProvider.glucoseData.last.value
            : 100.0;

        _prediction = _nutritionService.predictGlucoseImpact(
          nutrition: _nutritionInfo!,
          currentGlucose: currentGlucose,
        );

        _isEditing = false;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = null;
            _nutritionInfo = null;
            _prediction = null;
            _errorMessage = null;
          });
        } else {
          // For mobile/desktop
          setState(() {
            _imageFile = File(image.path);
            _webImage = null;
            _nutritionInfo = null;
            _prediction = null;
            _errorMessage = null;
          });
        }
        await _analyzeImage(image);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture image: $e';
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = null;
            _nutritionInfo = null;
            _prediction = null;
            _errorMessage = null;
          });
        } else {
          // For mobile/desktop
          setState(() {
            _imageFile = File(image.path);
            _webImage = null;
            _nutritionInfo = null;
            _prediction = null;
            _errorMessage = null;
          });
        }
        await _analyzeImage(image);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select image: $e';
      });
    }
  }

  Future<void> _analyzeImage(XFile imageFile) async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      NutritionalInfo nutritionInfo;

      if (kIsWeb) {
        // For web, use bytes directly
        final bytes = await imageFile.readAsBytes();
        nutritionInfo = await _nutritionService.analyzeFoodImageFromBytes(
          bytes,
        );
      } else {
        // For mobile/desktop, use File
        nutritionInfo = await _nutritionService.analyzeFoodImage(
          File(imageFile.path),
        );
      }

      // Get current glucose level
      final glucoseProvider = Provider.of<GlucoseProvider>(
        context,
        listen: false,
      );
      final currentGlucose = glucoseProvider.glucoseData.isNotEmpty
          ? glucoseProvider.glucoseData.last.value
          : 100.0; // Default if no data

      // Predict glucose impact
      final prediction = _nutritionService.predictGlucoseImpact(
        nutrition: nutritionInfo,
        currentGlucose: currentGlucose,
      );

      setState(() {
        _nutritionInfo = nutritionInfo;
        _prediction = prediction;
        _isAnalyzing = false;
      });

      // Populate edit controllers
      _populateEditControllers();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to analyze food: $e';
        _isAnalyzing = false;
      });
    }
  }

  void _saveMeal() async {
    if (_nutritionInfo == null) return;

    setState(() => _isSaving = true);

    try {
      final glucoseProvider = Provider.of<GlucoseProvider>(
        context,
        listen: false,
      );
      final currentGlucose = glucoseProvider.glucoseData.isNotEmpty
          ? glucoseProvider.glucoseData.last.value
          : 0.0;

      // Create meal object
      final meal = Meal(
        id: '', // Will be set by Firestore
        userId: '', // Will be set by Firestore
        mealType: _selectedMealType,
        foodName: _nutritionInfo!.foodName,
        timestamp: DateTime.now(),
        imageUrl: null, // TODO: Implement image upload to Firebase Storage
        nutritionalData: NutritionalData(
          calories: _nutritionInfo!.calories,
          carbs: _nutritionInfo!.carbs,
          protein: _nutritionInfo!.protein,
          fat: _nutritionInfo!.fat,
          fiber: _nutritionInfo!.fiber,
          sugar: _nutritionInfo!.sugar,
          servingSize: _nutritionInfo!.servingSize,
          servingUnit: _nutritionInfo!.servingUnit,
        ),
        glucoseImpact: _prediction != null
            ? GlucoseImpact(
                currentGlucose: currentGlucose,
                predictedIncrease: _prediction!.predictedIncrease,
                predictedPeakGlucose: _prediction!.predictedPeakGlucose,
                timeToProcessMinutes: _prediction!.timeToProcessMinutes,
                riskLevel: _prediction!.riskLevel,
                recommendation: _prediction!.recommendation,
              )
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Save to Firestore
      await _firestoreService.saveMeal(meal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${_selectedMealType.emoji} Meal saved successfully!',
            ),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving meal: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glucoseProvider = Provider.of<GlucoseProvider>(context);
    final currentGlucose = glucoseProvider.glucoseData.isNotEmpty
        ? glucoseProvider.glucoseData.last.value
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('📸 Scan Food'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Analyze Your Meal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.white : AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo to get instant nutritional info and glucose predictions',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : AppTheme.darkGray,
              ),
            ),
            const SizedBox(height: 24),

            // Current glucose display
            if (currentGlucose > 0)
              Card(
                elevation: 0,
                color: AppTheme.primaryBlue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        AppTheme.getGlucoseStatusEmoji(currentGlucose),
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Glucose Level',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${currentGlucose.toStringAsFixed(0)} mg/dL',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getGlucoseStatusColor(
                                  currentGlucose,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Image preview or buttons
            if (_imageFile == null && _webImage == null) ...[
              // Camera and Gallery buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt, size: 28),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing ? null : _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library, size: 28),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Image preview
              Card(
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Display image based on platform
                    if (kIsWeb && _webImage != null)
                      Image.memory(
                        _webImage!,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    else if (!kIsWeb && _imageFile != null)
                      Image.file(
                        _imageFile!,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _imageFile = null;
                            _webImage = null;
                            _nutritionInfo = null;
                            _prediction = null;
                          });
                        },
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Retake buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing ? null : _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing ? null : _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose Other'),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Meal Type Selector
            if (_nutritionInfo != null) ...[
              Card(
                elevation: 0,
                color: isDark ? AppTheme.darkCard : AppTheme.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('🍽️', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 8),
                          Text(
                            'Meal Type',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: MealType.values.map((type) {
                          final isSelected = _selectedMealType == type;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedMealType = type;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryBlue
                                        : (isDark
                                              ? AppTheme.darkSurface
                                              : AppTheme.lightGray),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryBlue
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        type.emoji,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        type.displayName,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? AppTheme.white
                                              : (isDark
                                                    ? AppTheme.white
                                                    : AppTheme.darkGray),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes field
              Card(
                elevation: 0,
                color: isDark ? AppTheme.darkCard : AppTheme.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📝 Notes (optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add any notes about this meal...',
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
            ],

            // Loading indicator
            if (_isAnalyzing)
              Card(
                elevation: 0,
                color: isDark ? AppTheme.darkCard : AppTheme.white,
                child: const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('🔍 Analyzing food...'),
                    ],
                  ),
                ),
              ),

            // Error message
            if (_errorMessage != null)
              Card(
                elevation: 0,
                color: AppTheme.dangerRed.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.dangerRed,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.dangerRed),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Nutrition info
            if (_nutritionInfo != null) ...[
              Card(
                elevation: 0,
                color: isDark ? AppTheme.darkCard : AppTheme.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🍽️', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _isEditing
                                ? TextField(
                                    controller: _foodNameController,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.all(8),
                                    ),
                                  )
                                : Text(
                                    _nutritionInfo!.foodName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (_isEditing) {
                                _updateNutritionFromControllers();
                              } else {
                                setState(() {
                                  _isEditing = true;
                                  _populateEditControllers();
                                });
                              }
                            },
                            icon: Icon(
                              _isEditing ? Icons.check : Icons.edit,
                              color: AppTheme.primaryBlue,
                            ),
                            tooltip: _isEditing ? 'Save' : 'Edit',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _isEditing
                          ? Column(
                              children: [
                                _buildEditableNutrientRow(
                                  'Calories',
                                  _caloriesController,
                                  Icons.local_fire_department,
                                  AppTheme.warningOrange,
                                  isDark,
                                ),
                                const SizedBox(height: 8),
                                _buildEditableNutrientRow(
                                  'Carbs (g)',
                                  _carbsController,
                                  Icons.grain,
                                  AppTheme.primaryBlue,
                                  isDark,
                                ),
                                const SizedBox(height: 8),
                                _buildEditableNutrientRow(
                                  'Sugar (g)',
                                  _sugarController,
                                  Icons.cookie,
                                  AppTheme.dangerRed,
                                  isDark,
                                ),
                                const SizedBox(height: 8),
                                _buildEditableNutrientRow(
                                  'Fiber (g)',
                                  _fiberController,
                                  Icons.eco,
                                  AppTheme.successGreen,
                                  isDark,
                                ),
                                const SizedBox(height: 8),
                                _buildEditableNutrientRow(
                                  'Protein (g)',
                                  _proteinController,
                                  Icons.fitness_center,
                                  AppTheme.darkBlue,
                                  isDark,
                                ),
                                const SizedBox(height: 8),
                                _buildEditableNutrientRow(
                                  'Fat (g)',
                                  _fatController,
                                  Icons.water_drop,
                                  Colors.amber,
                                  isDark,
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildNutrientRow(
                                  'Calories',
                                  '${_nutritionInfo!.calories.toStringAsFixed(0)} kcal',
                                  Icons.local_fire_department,
                                  AppTheme.warningOrange,
                                ),
                                _buildNutrientRow(
                                  'Carbs',
                                  '${_nutritionInfo!.carbs.toStringAsFixed(1)}g',
                                  Icons.grain,
                                  AppTheme.primaryBlue,
                                ),
                                _buildNutrientRow(
                                  'Sugar',
                                  '${_nutritionInfo!.sugar.toStringAsFixed(1)}g',
                                  Icons.cookie,
                                  AppTheme.dangerRed,
                                ),
                                _buildNutrientRow(
                                  'Fiber',
                                  '${_nutritionInfo!.fiber.toStringAsFixed(1)}g',
                                  Icons.eco,
                                  AppTheme.successGreen,
                                ),
                                _buildNutrientRow(
                                  'Protein',
                                  '${_nutritionInfo!.protein.toStringAsFixed(1)}g',
                                  Icons.fitness_center,
                                  AppTheme.darkBlue,
                                ),
                                _buildNutrientRow(
                                  'Fat',
                                  '${_nutritionInfo!.fat.toStringAsFixed(1)}g',
                                  Icons.water_drop,
                                  Colors.amber,
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Glucose prediction
              if (_prediction != null)
                Card(
                  elevation: 0,
                  color: _getRiskColor(_prediction!.riskLevel).withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('📊', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            const Text(
                              'Glucose Impact Prediction',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildPredictionRow(
                          'Expected Increase',
                          '+${_prediction!.predictedIncrease.toStringAsFixed(0)} mg/dL',
                        ),
                        _buildPredictionRow(
                          'Predicted Peak',
                          '${_prediction!.predictedPeakGlucose.toStringAsFixed(0)} mg/dL',
                        ),
                        _buildPredictionRow(
                          'Time to Process',
                          '~${_prediction!.timeToProcessMinutes} minutes',
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getRiskColor(
                              _prediction!.riskLevel,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Risk Level: ${_prediction!.riskLevel}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getRiskColor(_prediction!.riskLevel),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _prediction!.recommendation,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveMeal,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Meal',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableNutrientRow(
    String label,
    TextEditingController controller,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: label,
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionRow(String label, String value) {
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
