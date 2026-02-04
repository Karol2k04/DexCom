import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Native implementation (Android/iOS) of HealthService using the `health` package.
/// Public API uses string metric keys to remain platform-safe and avoid web-only compilation issues.
class HealthService {
  final HealthFactory _health = HealthFactory();

  // Metric keys exposed to the app (strings)
  static const List<String> allMetrics = [
    'STEPS',
    'HEART_RATE',
    'SLEEP_ASLEEP',
    'SLEEP_AWAKE',
    'WEIGHT',
    'BLOOD_GLUCOSE',
    'BLOOD_PRESSURE_SYSTOLIC',
    'BLOOD_PRESSURE_DIASTOLIC',
    'BODY_TEMPERATURE',
    'BLOOD_OXYGEN',
    'ACTIVE_ENERGY_BURNED',
    'BASAL_ENERGY_BURNED',
  ];

  // Internal mapping to HealthDataType
  static final Map<String, HealthDataType> _mapping = {
    'STEPS': HealthDataType.STEPS,
    'HEART_RATE': HealthDataType.HEART_RATE,
    'SLEEP_ASLEEP': HealthDataType.SLEEP_ASLEEP,
    'SLEEP_AWAKE': HealthDataType.SLEEP_AWAKE,
    'WEIGHT': HealthDataType.WEIGHT,
    'BLOOD_GLUCOSE': HealthDataType.BLOOD_GLUCOSE,
    'BLOOD_PRESSURE_SYSTOLIC': HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    'BLOOD_PRESSURE_DIASTOLIC': HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    'BODY_TEMPERATURE': HealthDataType.BODY_TEMPERATURE,
    'BLOOD_OXYGEN': HealthDataType.BLOOD_OXYGEN,
    'ACTIVE_ENERGY_BURNED': HealthDataType.ACTIVE_ENERGY_BURNED,
    'BASAL_ENERGY_BURNED': HealthDataType.BASAL_ENERGY_BURNED,
  };

  /// Request permissions for all selected metrics
  Future<bool> requestPermissions() async {
    try {
      final types = _mapping.values.toList();
      final ok = await _health.requestAuthorization(types);
      return ok;
    } catch (e) {
      debugPrint('Health permission request failed: $e');
      return false;
    }
  }

  /// Read data for the given metric (by key) over the provided range
  /// Returns list of maps with keys: value, dateFrom, dateTo
  Future<List<Map<String, dynamic>>> fetchData(
    String metric,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final type = _mapping[metric];
      if (type == null) return [];

      final ok = await _health.requestAuthorization([type]);
      if (!ok) return [];

      final list = await _health.getHealthDataFromTypes(start, end, [type]);
      return list
          .map(
            (p) => {
              'value': p.value,
              'dateFrom': p.dateFrom,
              'dateTo': p.dateTo,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error fetching $metric: $e');
      return [];
    }
  }

  /// Fetch latest values for each metric (last [range] window)
  Future<Map<String, List<Map<String, dynamic>>>> fetchAll({
    Duration range = const Duration(days: 1),
  }) async {
    final now = DateTime.now();
    final from = now.subtract(range);

    final result = <String, List<Map<String, dynamic>>>{};

    for (final m in allMetrics) {
      final pts = await fetchData(m, from, now);
      result[m] = pts;
    }

    return result;
  }
}
