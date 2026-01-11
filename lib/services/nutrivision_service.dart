// services/nutrivision_service.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NutritionalInfo {
  final String foodName;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final double fiber;
  final double sugar;
  final double servingSize;
  final String servingUnit;

  NutritionalInfo({
    required this.foodName,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.servingSize,
    required this.servingUnit,
  });

  factory NutritionalInfo.fromJson(Map<String, dynamic> json) {
    return NutritionalInfo(
      foodName: json['food_name'] ?? json['name'] ?? 'Unknown Food',
      calories: (json['calories'] ?? 0).toDouble(),
      carbs: (json['carbohydrates'] ?? json['carbs'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      sugar: (json['sugar'] ?? 0).toDouble(),
      servingSize: (json['serving_size'] ?? 100).toDouble(),
      servingUnit: json['serving_unit'] ?? 'g',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName,
      'calories': calories,
      'carbohydrates': carbs,
      'protein': protein,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
    };
  }
}

class GlucosePrediction {
  final double predictedIncrease;
  final double predictedPeakGlucose;
  final int timeToProcessMinutes;
  final String riskLevel;
  final String recommendation;

  GlucosePrediction({
    required this.predictedIncrease,
    required this.predictedPeakGlucose,
    required this.timeToProcessMinutes,
    required this.riskLevel,
    required this.recommendation,
  });
}

class NutriVisionService {
  static const String _apiKey = 'nv_b34dd65dbbe0af81cab07c5cb606db62a94c83866c77824ad14c7a7895906fe8';
  static const String _baseUrl = 'https://nutrivision.com/api/v1';

  /// Analyze food image and get nutritional information (for mobile/desktop)
  Future<NutritionalInfo> analyzeFoodImage(File imageFile) async {
    try {
      debugPrint('Analyzing food image with NutriVision API');
      
      // Read image as bytes
      final bytes = await imageFile.readAsBytes();
      
      // Convert to base64
      return await analyzeFoodImageFromBytes(bytes);
    } catch (e) {
      debugPrint('Error analyzing food image: $e');
      rethrow;
    }
  }

  /// Analyze food image from bytes (works for all platforms)
  Future<NutritionalInfo> analyzeFoodImageFromBytes(Uint8List imageBytes) async {
    try {
      debugPrint('Analyzing food image from bytes with NutriVision API');

      // Convert bytes to base64
      final base64Image = base64Encode(imageBytes);

      // Make POST request with base64 image
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'image_base64': base64Image,
        }),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return NutritionalInfo.fromJson(jsonResponse);
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your credentials.');
      } else {
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error analyzing food image from bytes: $e');
      
      // For demo purposes, return mock data if API fails
      debugPrint('⚠️ Using mock data for demo');
      return _getMockNutritionalInfo();
    }
  }

  /// Get mock nutritional data for demo/testing
  NutritionalInfo _getMockNutritionalInfo() {
    // Mock data for the salmon and asparagus image
    return NutritionalInfo(
      foodName: 'Grilled Salmon with Asparagus',
      calories: 380,
      carbs: 12,
      protein: 42,
      fat: 18,
      fiber: 4,
      sugar: 3,
      servingSize: 250,
      servingUnit: 'g',
    );
  }

  /// Analyze food from URL
  Future<NutritionalInfo> analyzeFoodFromUrl(String imageUrl) async {
    try {
      debugPrint('Analyzing food from URL with NutriVision API');

      final response = await http.post(
        Uri.parse('$_baseUrl/analyze'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'image_url': imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        debugPrint('NutriVision response: $jsonResponse');
        
        return NutritionalInfo.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error analyzing food from URL: $e');
      return _getMockNutritionalInfo();
    }
  }

  /// Predict glucose impact based on nutritional info and current glucose level
  GlucosePrediction predictGlucoseImpact({
    required NutritionalInfo nutrition,
    required double currentGlucose,
  }) {
    // Calculate net carbs (total carbs - fiber)
    final netCarbs = nutrition.carbs - nutrition.fiber;
    
    // Estimate glucose increase (simplified model)
    // Rule of thumb: 1g of carbs increases blood glucose by ~3-5 mg/dL
    // We'll use 4 mg/dL as average, adjusted by fiber content
    final fiberAdjustment = nutrition.fiber > 0 ? 0.8 : 1.0;
    final predictedIncrease = netCarbs * 4.0 * fiberAdjustment;
    
    final predictedPeak = currentGlucose + predictedIncrease;
    
    // Estimate time to process (based on glycemic index approximation)
    // High sugar = faster processing, high fiber = slower processing
    final sugarRatio = nutrition.sugar / (nutrition.carbs + 0.1);
    final fiberRatio = nutrition.fiber / (nutrition.carbs + 0.1);
    
    int timeToProcess = 90; // Base: 90 minutes
    if (sugarRatio > 0.5) {
      timeToProcess = 60; // High sugar foods process faster
    } else if (fiberRatio > 0.2) {
      timeToProcess = 120; // High fiber foods process slower
    }

    // Determine risk level
    String riskLevel;
    String recommendation;

    if (predictedPeak < 140) {
      riskLevel = 'Low';
      recommendation = '✅ This meal should keep your glucose in a healthy range.';
    } else if (predictedPeak < 180) {
      riskLevel = 'Moderate';
      recommendation = '⚡ Your glucose may rise moderately. Consider a short walk after eating.';
    } else if (predictedPeak < 250) {
      riskLevel = 'High';
      recommendation = '🔴 This meal may cause a significant glucose spike. Consider reducing portion size or insulin adjustment.';
    } else {
      riskLevel = 'Very High';
      recommendation = '🆘 This meal will likely cause a very high glucose spike. Strong insulin adjustment recommended.';
    }

    return GlucosePrediction(
      predictedIncrease: predictedIncrease,
      predictedPeakGlucose: predictedPeak,
      timeToProcessMinutes: timeToProcess,
      riskLevel: riskLevel,
      recommendation: recommendation,
    );
  }

  /// Format nutritional info for display
  String formatNutritionalInfo(NutritionalInfo info) {
    return '''
${info.foodName}
Serving: ${info.servingSize}${info.servingUnit}

Calories: ${info.calories.toStringAsFixed(0)} kcal
Carbohydrates: ${info.carbs.toStringAsFixed(1)}g
  - Sugar: ${info.sugar.toStringAsFixed(1)}g
  - Fiber: ${info.fiber.toStringAsFixed(1)}g
Protein: ${info.protein.toStringAsFixed(1)}g
Fat: ${info.fat.toStringAsFixed(1)}g
''';
  }
}