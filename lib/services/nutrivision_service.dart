// services/nutrivision_service.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

// Import your API key file
import 'api_key.dart';

// -------------------- MODELS --------------------

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

// -------------------- SERVICE --------------------

class NutriVisionService {
  // Initialize model using the key from api_key.dart
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: googleGeminiApiKey, // <--- Using the imported constant here
    generationConfig: GenerationConfig(responseMimeType: 'application/json'),
  );

  /// Analyze food image from File (Mobile/Desktop)
  Future<NutritionalInfo> analyzeFoodImage(File imageFile) async {
    try {
      debugPrint('Analyzing food image file with Gemini...');
      final bytes = await imageFile.readAsBytes();
      return await analyzeFoodImageFromBytes(bytes);
    } catch (e) {
      debugPrint('Error analyzing food image: $e');
      rethrow;
    }
  }

  /// Analyze food from URL
  Future<NutritionalInfo> analyzeFoodFromUrl(String imageUrl) async {
    try {
      debugPrint('Downloading food image from URL...');
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        return await analyzeFoodImageFromBytes(response.bodyBytes);
      } else {
        throw Exception(
          'Failed to download image from URL: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Core Method: Analyze food image from Bytes
  Future<NutritionalInfo> analyzeFoodImageFromBytes(
    Uint8List imageBytes,
  ) async {
    try {
      // 1. Create the prompt
      final prompt = Content.multi([
        TextPart(
          "You are a nutritionist. Analyze this food image. Identify the food and estimate its nutritional content. Return ONLY raw JSON with these keys: food_name (string), calories (number), carbohydrates (number), protein (number), fat (number), fiber (number), sugar (number), serving_size (number), serving_unit (string).",
        ),
        DataPart('image/jpeg', imageBytes),
      ]);

      // 2. Send to Gemini
      debugPrint('Sending request to Gemini SDK...');
      final response = await _model.generateContent([prompt]);

      // 3. Process Response
      final responseText = response.text;
      debugPrint('Gemini Response: $responseText');

      if (responseText == null) {
        throw Exception('Empty response from Gemini');
      }

      // 4. Parse JSON (Robust handling for List vs Map)
      final dynamic decodedJson = json.decode(responseText);
      Map<String, dynamic> finalData;

      if (decodedJson is List) {
        if (decodedJson.isNotEmpty) {
          finalData = decodedJson.first as Map<String, dynamic>;
        } else {
          throw Exception('Gemini returned an empty list.');
        }
      } else if (decodedJson is Map) {
        finalData = decodedJson as Map<String, dynamic>;
      } else {
        throw Exception('Unexpected JSON format: ${decodedJson.runtimeType}');
      }

      return NutritionalInfo.fromJson(finalData);
    } catch (e) {
      debugPrint('Gemini Error: $e');
      rethrow;
    }
  }

  // -------------------- LOGIC --------------------

  GlucosePrediction predictGlucoseImpact({
    required NutritionalInfo nutrition,
    required double currentGlucose,
  }) {
    final netCarbs = nutrition.carbs - nutrition.fiber;
    final fiberAdjustment = nutrition.fiber > 0 ? 0.8 : 1.0;
    final predictedIncrease = netCarbs * 4.0 * fiberAdjustment;
    final predictedPeak = currentGlucose + predictedIncrease;

    final sugarRatio = nutrition.sugar / (nutrition.carbs + 0.1);
    final fiberRatio = nutrition.fiber / (nutrition.carbs + 0.1);

    int timeToProcess = 90;
    if (sugarRatio > 0.5) {
      timeToProcess = 60;
    } else if (fiberRatio > 0.2)
      timeToProcess = 120;

    String riskLevel;
    String recommendation;

    if (predictedPeak < 140) {
      riskLevel = 'Low';
      recommendation =
          '✅ This meal should keep your glucose in a healthy range.';
    } else if (predictedPeak < 180) {
      riskLevel = 'Moderate';
      recommendation =
          '⚡ Your glucose may rise moderately. Consider a short walk.';
    } else if (predictedPeak < 250) {
      riskLevel = 'High';
      recommendation =
          '🔴 High spike expected. Consider reducing portion size.';
    } else {
      riskLevel = 'Very High';
      recommendation = '🆘 Very high spike expected. Caution advised.';
    }

    return GlucosePrediction(
      predictedIncrease: predictedIncrease,
      predictedPeakGlucose: predictedPeak,
      timeToProcessMinutes: timeToProcess,
      riskLevel: riskLevel,
      recommendation: recommendation,
    );
  }

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
