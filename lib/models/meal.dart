import 'package:cloud_firestore/cloud_firestore.dart';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast:
        return '🍳';
      case MealType.lunch:
        return '🍽️';
      case MealType.dinner:
        return '🍖';
      case MealType.snack:
        return '🍎';
    }
  }

  static MealType fromString(String value) {
    return MealType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MealType.snack,
    );
  }
}

class Meal {
  final String id;
  final String userId;
  final MealType mealType;
  final String foodName;
  final DateTime timestamp;
  final String? imageUrl;
  final NutritionalData nutritionalData;
  final GlucoseImpact? glucoseImpact;
  final String? notes;

  Meal({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.foodName,
    required this.timestamp,
    this.imageUrl,
    required this.nutritionalData,
    this.glucoseImpact,
    this.notes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'mealType': mealType.name,
      'foodName': foodName,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'nutritionalData': nutritionalData.toMap(),
      'glucoseImpact': glucoseImpact?.toMap(),
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Meal.fromFirestore(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] as Timestamp?;

    return Meal(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      mealType: MealType.fromString(data['mealType'] ?? 'snack'),
      foodName: data['foodName'] ?? 'Unknown Food',
      timestamp: timestamp?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      nutritionalData: NutritionalData.fromMap(
        data['nutritionalData'] as Map<String, dynamic>? ?? {},
      ),
      glucoseImpact: data['glucoseImpact'] != null
          ? GlucoseImpact.fromMap(data['glucoseImpact'] as Map<String, dynamic>)
          : null,
      notes: data['notes'],
    );
  }

  // Helper getters
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  String get dateKey {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
  }
}

class NutritionalData {
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final double fiber;
  final double sugar;
  final double servingSize;
  final String servingUnit;

  NutritionalData({
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.servingSize,
    required this.servingUnit,
  });

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
    };
  }

  factory NutritionalData.fromMap(Map<String, dynamic> map) {
    return NutritionalData(
      calories: (map['calories'] ?? 0).toDouble(),
      carbs: (map['carbs'] ?? 0).toDouble(),
      protein: (map['protein'] ?? 0).toDouble(),
      fat: (map['fat'] ?? 0).toDouble(),
      fiber: (map['fiber'] ?? 0).toDouble(),
      sugar: (map['sugar'] ?? 0).toDouble(),
      servingSize: (map['servingSize'] ?? 100).toDouble(),
      servingUnit: map['servingUnit'] ?? 'g',
    );
  }

  double get netCarbs => carbs - fiber;
}

class GlucoseImpact {
  final double currentGlucose;
  final double predictedIncrease;
  final double predictedPeakGlucose;
  final int timeToProcessMinutes;
  final String riskLevel;
  final String recommendation;

  GlucoseImpact({
    required this.currentGlucose,
    required this.predictedIncrease,
    required this.predictedPeakGlucose,
    required this.timeToProcessMinutes,
    required this.riskLevel,
    required this.recommendation,
  });

  Map<String, dynamic> toMap() {
    return {
      'currentGlucose': currentGlucose,
      'predictedIncrease': predictedIncrease,
      'predictedPeakGlucose': predictedPeakGlucose,
      'timeToProcessMinutes': timeToProcessMinutes,
      'riskLevel': riskLevel,
      'recommendation': recommendation,
    };
  }

  factory GlucoseImpact.fromMap(Map<String, dynamic> map) {
    return GlucoseImpact(
      currentGlucose: (map['currentGlucose'] ?? 0).toDouble(),
      predictedIncrease: (map['predictedIncrease'] ?? 0).toDouble(),
      predictedPeakGlucose: (map['predictedPeakGlucose'] ?? 0).toDouble(),
      timeToProcessMinutes: map['timeToProcessMinutes'] ?? 0,
      riskLevel: map['riskLevel'] ?? 'Unknown',
      recommendation: map['recommendation'] ?? '',
    );
  }
}
