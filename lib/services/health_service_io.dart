import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Native implementation (Android/iOS) of HealthService using the `health` package.
/// Public API uses string metric keys to remain platform-safe and avoid web-only compilation issues.
class HealthService {
  final Health _health = Health();

  HealthService() {
    // Attempt to configure plugin (loads device id) but do not fail if it errors
    _health.configure().catchError(
      (e) => debugPrint('Health configure failed: $e'),
    );
  }

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
  /// Returns a map: { 'ok': bool, 'message': String }
  Future<Map<String, dynamic>> requestPermissions() async {
    try {
      final types = _mapping.values.toList();

      // Android: ensure Health Connect availability
      if (Platform.isAndroid) {
        final avail = await _health.isHealthConnectAvailable();
        if (!avail) {
          final msg = 'Google Health Connect is not available on this device';
          debugPrint(msg);
          return {'ok': false, 'message': msg};
        }
      }

      final has = await _health.hasPermissions(types);
      debugPrint('Health.hasPermissions -> $has');

      final ok = await _health.requestAuthorization(types);
      if (ok == true) {
        return {'ok': true, 'message': 'Health permissions granted'};
      }

      // On Android some read operations may require the Health Data History permission
      if (Platform.isAndroid) {
        final histAvailable = await _health.isHealthDataHistoryAvailable();
        final histAuthorized = await _health.isHealthDataHistoryAuthorized();
        debugPrint(
          'Health history available=$histAvailable authorized=$histAuthorized',
        );
        if (histAvailable && !histAuthorized) {
          final histOk = await _health.requestHealthDataHistoryAuthorization();
          if (histOk == true) {
            return {
              'ok': true,
              'message': 'Health Data History permission granted',
            };
          }
          return {
            'ok': false,
            'message': 'Health Data History permission denied',
          };
        }
      }

      return {'ok': false, 'message': 'Request authorization denied'};
    } catch (e) {
      debugPrint('Health permission request failed: $e');
      return {'ok': false, 'message': 'Exception: $e'};
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

      final list = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [type],
      );
      return list.map((p) {
        dynamic v;
        try {
          if (p.value is NumericHealthValue) {
            v = (p.value as NumericHealthValue).numericValue;
          } else {
            v = p.value.toJson();
          }
        } catch (_) {
          v = p.value.toString();
        }

        return {'value': v, 'dateFrom': p.dateFrom, 'dateTo': p.dateTo};
      }).toList();
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

  /// Request that the user install Health Connect (Android) if not available.
  Future<void> installHealthConnect() async {
    try {
      await _health.installHealthConnect();
    } catch (e) {
      debugPrint('installHealthConnect failed: $e');
    }
  }

  /// Returns true if Google Health Connect is available on Android (true on iOS)
  Future<bool> isHealthConnectAvailable() async {
    try {
      if (!Platform.isAndroid) return true; // iOS does not use Health Connect
      return await _health.isHealthConnectAvailable();
    } catch (e) {
      debugPrint('isHealthConnectAvailable failed: $e');
      return false;
    }
  }
}
