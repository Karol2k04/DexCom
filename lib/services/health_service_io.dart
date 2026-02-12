import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// Opens Health Connect settings where user can manually grant permissions
  Future<bool> openHealthConnectSettings() async {
    try {
      if (!Platform.isAndroid) return false;

      // Try to open Health Connect app directly
      final uri = Uri.parse('package:com.google.android.apps.healthdata');
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('Failed to open Health Connect settings: $e');
      return false;
    }
  }

  /// Request permissions for all selected metrics
  /// Returns a map: { 'ok': bool, 'message': String }
  Future<Map<String, dynamic>> requestPermissions() async {
    try {
      final types = _mapping.values.toList();

      debugPrint('Requesting health permissions for ${types.length} types...');

      final has = await _health.hasPermissions(types);
      debugPrint('Health.hasPermissions -> $has');

      // If already has permissions, return success
      if (has == true) {
        return {'ok': true, 'message': 'Health permissions already granted'};
      }

      // Request authorization
      final ok = await _health.requestAuthorization(types);
      debugPrint('requestAuthorization result: $ok');

      if (ok == true) {
        return {'ok': true, 'message': 'Health permissions granted'};
      }

      return {'ok': false, 'message': 'Authorization denied or incomplete'};
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
      if (type == null) {
        debugPrint('Unknown metric: $metric');
        return [];
      }

      // Request authorization for this specific type
      debugPrint('Requesting authorization for $metric from $start to $end');
      final ok = await _health.requestAuthorization([type]);
      if (!ok) {
        debugPrint('Authorization denied for $metric');
        return [];
      }

      debugPrint('Fetching data for $metric...');
      final list = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [type],
      );

      debugPrint('Fetched ${list.length} data points for $metric');

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
    Duration range = const Duration(days: 7),
  }) async {
    final now = DateTime.now();
    final from = now.subtract(range);

    debugPrint(
      '=== Fetching all ${allMetrics.length} metrics from $from to $now ===',
    );

    final result = <String, List<Map<String, dynamic>>>{};

    for (final m in allMetrics) {
      try {
        debugPrint('>>> Fetching metric: $m');
        final pts = await fetchData(m, from, now);
        result[m] = pts;
        debugPrint('<<< $m: ${pts.length} points retrieved');
      } catch (e) {
        debugPrint('!!! Error fetching metric $m: $e');
        result[m] = []; // Continue with other metrics
      }
    }

    debugPrint('=== Fetch complete: ${result.length} metrics processed ===');
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
