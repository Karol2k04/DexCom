// screens/food_scan_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/nutrivision_service.dart';
import '../providers/glucose_provider.dart';
import '../theme/app_theme.dart';

class FoodScanScreen extends StatefulWidget {
  const FoodScanScreen({super.key});

  @override
  State<FoodScanScreen> createState() => _FoodScanScreenState();
}

class _FoodScanScreenState extends State<FoodScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final NutriVisionService _nutritionService = NutriVisionService();
  
  File? _imageFile;
  Uint8List? _webImage; // For web support
  bool _isAnalyzing = false;
  NutritionalInfo? _nutritionInfo;
  GlucosePrediction? _prediction;
  String? _errorMessage;

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
        nutritionInfo = await _nutritionService.analyzeFoodImageFromBytes(bytes);
      } else {
        // For mobile/desktop, use File
        nutritionInfo = await _nutritionService.analyzeFoodImage(File(imageFile.path));
      }
      
      // Get current glucose level
      final glucoseProvider = Provider.of<GlucoseProvider>(context, listen: false);
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
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to analyze food: $e';
        _isAnalyzing = false;
      });
    }
  }

  void _saveMeal() {
    if (_nutritionInfo == null) return;

    // TODO: Implement saving meal to database/provider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Meal saved successfully!'),
        backgroundColor: AppTheme.successGreen,
      ),
    );

    // Navigate back
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glucoseProvider = Provider.of<GlucoseProvider>(context);
    final currentGlucose = glucoseProvider.glucoseData.isNotEmpty 
        ? glucoseProvider.glucoseData.last.value 
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📸 Scan Food'),
        elevation: 0,
      ),
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
                                color: AppTheme.getGlucoseStatusColor(currentGlucose),
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
                      const Icon(Icons.error_outline, color: AppTheme.dangerRed),
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
                            child: Text(
                              _nutritionInfo!.foodName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                            color: _getRiskColor(_prediction!.riskLevel).withOpacity(0.2),
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
                  onPressed: _saveMeal,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save Meal',
                    style: TextStyle(
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

  Widget _buildNutrientRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
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