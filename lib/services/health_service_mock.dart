import 'dart:math';
import 'package:flutter/foundation.dart';

/// Temporary mock HealthService used for emulator/device testing when
/// real platform plugins are not available or cause build issues.
/// Returns synthetic but realistic-looking data for the metrics used
/// by the app.
class HealthService {
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

  /// Simulate granting permissions quickly
  Future<bool> requestPermissions() async {
    debugPrint('Mock HealthService: requestPermissions() called');
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('Mock HealthService: permissions granted');
    return true;
  }

  /// Returns a list of synthetic points for the metric between start and end.
  Future<List<Map<String, dynamic>>> fetchData(
    String metric,
    DateTime start,
    DateTime end,
  ) async {
    debugPrint('Mock HealthService: fetchData($metric, $start, $end)');
    await Future.delayed(const Duration(milliseconds: 300));

    final days = end.difference(start).inDays + 1;
    final rng = Random(metric.hashCode ^ start.millisecondsSinceEpoch);

    final List<Map<String, dynamic>> out = [];

    for (var d = 0; d < days; d++) {
      final day = DateTime(
        start.year,
        start.month,
        start.day,
      ).add(Duration(days: d));

      // produce a different number of samples depending on metric
      int samples = 1;
      if (metric == 'BLOOD_GLUCOSE') samples = 3;
      if (metric == 'HEART_RATE') samples = 4;
      if (metric == 'SLEEP_ASLEEP' || metric == 'SLEEP_AWAKE') samples = 1;
      if (metric == 'STEPS') samples = 1;

      for (var i = 0; i < samples; i++) {
        final t = day.add(
          Duration(hours: rng.nextInt(24), minutes: rng.nextInt(60)),
        );
        dynamic value;
        switch (metric) {
          case 'STEPS':
            value = 1000 + rng.nextInt(9000);
            break;
          case 'HEART_RATE':
            value = 60 + rng.nextInt(60);
            break;
          case 'WEIGHT':
            value = 70.0 + rng.nextDouble() * 10.0;
            break;
          case 'BLOOD_GLUCOSE':
            value = 4.5 + rng.nextDouble() * 4.5; // mmol/L style
            value = double.parse(value.toStringAsFixed(1));
            break;
          case 'BLOOD_PRESSURE_SYSTOLIC':
            value = 110 + rng.nextInt(30);
            break;
          case 'BLOOD_PRESSURE_DIASTOLIC':
            value = 70 + rng.nextInt(20);
            break;
          case 'BODY_TEMPERATURE':
            value = 36.3 + rng.nextDouble() * 1.2;
            value = double.parse(value.toStringAsFixed(1));
            break;
          case 'BLOOD_OXYGEN':
            value = 95 + rng.nextInt(5);
            break;
          case 'ACTIVE_ENERGY_BURNED':
            value = 200 + rng.nextInt(1800);
            break;
          case 'BASAL_ENERGY_BURNED':
            value = 1200 + rng.nextInt(300);
            break;
          case 'SLEEP_ASLEEP':
            value = rng.nextInt(8) + 6; // hours asleep
            break;
          case 'SLEEP_AWAKE':
            value = rng.nextInt(2); // number of wakeups
            break;
          default:
            value = rng.nextInt(100);
        }

        out.add({
          'value': value,
          'dateFrom': t,
          'dateTo': t.add(const Duration(minutes: 1)),
        });
      }
    }

    out.sort(
      (a, b) =>
          (a['dateFrom'] as DateTime).compareTo(b['dateFrom'] as DateTime),
    );
    debugPrint(
      'Mock HealthService: fetchData($metric) -> ${out.length} points',
    );
    return out;
  }

  /// Return latest values for each metric in given range
  Future<Map<String, List<Map<String, dynamic>>>> fetchAll({
    Duration range = const Duration(days: 1),
  }) async {
    final now = DateTime.now();
    final from = now.subtract(range);

    final result = <String, List<Map<String, dynamic>>>{};

    for (final m in allMetrics) {
      result[m] = await fetchData(m, from, now);
    }

    debugPrint(
      'Mock HealthService: fetchAll(range=${range.inDays}d) completed',
    );
    return result;
  }
}
