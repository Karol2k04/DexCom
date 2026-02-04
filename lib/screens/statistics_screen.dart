import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../providers/glucose_provider.dart';
import '../providers/settings_provider.dart';
import '../services/health_service.dart';

// Ekran statystyk
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<GlucoseProvider, SettingsProvider>(
      builder: (context, glucoseProvider, settings, child) {
        // Base stats from provider
        final baseDailyStats = glucoseProvider.getDailyStats();

        final now = DateTime.now();
        final List<Map<String, dynamic>> weeklyData = [];
        final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        // Helper to build weekly data; maybe augmented with health readings below
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dayKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final stats = baseDailyStats[dayKey];

          weeklyData.add({
            'day': daysOfWeek[date.weekday - 1],
            'key': dayKey,
            'glucose': stats?['glucose'] ?? 0.0,
            'tir': stats?['tir'] ?? 0.0,
            'count': stats?['count']?.toInt() ?? 0,
          });
        }

        // If user enabled Health glucose inclusion, fetch and merge health BLOOD_GLUCOSE values
        final includeHealth = settings.includeHealthGlucose;
        if (includeHealth) {
          // Use a FutureBuilder to fetch health data asynchronously and merge; show loading while fetching
          return FutureBuilder<Map<String, Map<String, double>>>(
            future: _mergeHealthIntoDailyStats(baseDailyStats),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final mergedStats = snapshot.data ?? baseDailyStats;

              // Convert to weeklyData for chart
              final mergedWeekly = <Map<String, dynamic>>[];
              for (int i = 6; i >= 0; i--) {
                final date = now.subtract(Duration(days: i));
                final dayKey =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                final stats = mergedStats[dayKey];

                mergedWeekly.add({
                  'day': daysOfWeek[date.weekday - 1],
                  'glucose': stats?['glucose'] ?? 0.0,
                  'tir': stats?['tir'] ?? 0.0,
                });
              }

              return _buildStatisticsUI(context, mergedWeekly, glucoseProvider);
            },
          );
        }

        // If not including health or after async merge, display precomputed UI

        // Count days in range (TIR > 70%)
        final daysInRange = weeklyData
            .where((day) => (day['tir'] as double) >= 70)
            .length;

        // Compute overall avg glucose and avg TIR from weeklyData
        final avgGlucose = weeklyData.isEmpty
            ? 0
            : (weeklyData
                      .map((d) => d['glucose'] as double)
                      .reduce((a, b) => a + b) /
                  weeklyData.length);
        final avgTir = weeklyData.isEmpty
            ? 0
            : (weeklyData
                          .map((d) => d['tir'] as double)
                          .reduce((a, b) => a + b) /
                      weeklyData.length)
                  .round();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📊 Statistics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.white : AppTheme.darkBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Last 7 days',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 16),

              // Empty state when no data
              if (glucoseProvider.glucoseData.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bar_chart_outlined,
                          size: 64,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No statistics available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Import a CSV file to see your glucose statistics',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Karty podsumowania
              if (glucoseProvider.glucoseData.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 0,
                        color: isDark ? AppTheme.darkCard : AppTheme.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text('🎯', style: TextStyle(fontSize: 24)),
                              const SizedBox(height: 8),
                              Text(
                                '${avgTir}%',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Avg TIR',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        elevation: 0,
                        color: isDark ? AppTheme.darkCard : AppTheme.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text('📈', style: TextStyle(fontSize: 24)),
                              const SizedBox(height: 8),
                              Text(
                                '$daysInRange',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Days in range',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        elevation: 0,
                        color: isDark ? AppTheme.darkCard : AppTheme.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text('📊', style: TextStyle(fontSize: 24)),
                              const SizedBox(height: 8),
                              Text(
                                '${avgGlucose.round()}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Avg glucose',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Wykres słupkowy - średnie dzienne
              if (glucoseProvider.glucoseData.isNotEmpty)
                Card(
                  elevation: 0,
                  color: isDark ? AppTheme.darkCard : AppTheme.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily average glucose',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.white : AppTheme.darkBlue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 150,
                              minY: 80,
                              barGroups: weeklyData.asMap().entries.map((
                                entry,
                              ) {
                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value['glucose'] as double,
                                      color: AppTheme.successGreen,
                                      width: 16,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= weeklyData.length) {
                                        return const SizedBox();
                                      }
                                      return Text(
                                        weeklyData[value.toInt()]['day']
                                            as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: isDark
                                        ? Colors.grey[800]!
                                        : Colors.grey[300]!,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 100), // Odstęp dla bottom navigation
            ],
          ),
        );
      },
    );
  }

  // Merge BLOOD_GLUCOSE readings from Health services into baseDailyStats
  Future<Map<String, Map<String, double>>> _mergeHealthIntoDailyStats(
    Map<String, Map<String, double>> baseDailyStats,
  ) async {
    final HealthService svc = HealthService();
    final merged = Map<String, Map<String, double>>.from(baseDailyStats);

    try {
      final healthData = await svc.fetchAll(range: const Duration(days: 7));
      final List<Map<String, dynamic>> glucosePoints =
          (healthData['BLOOD_GLUCOSE'] ?? []).cast<Map<String, dynamic>>();

      final Map<String, List<double>> healthByDate = {};

      for (final p in glucosePoints) {
        final val = p['value'];
        final date = p['dateFrom'] as DateTime? ?? DateTime.now();
        if (val == null) continue;
        final double v = (val is num)
            ? val.toDouble()
            : double.tryParse(val.toString()) ?? 0.0;

        final dayKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        healthByDate.putIfAbsent(dayKey, () => []).add(v);
      }

      // Merge per-day
      for (final entry in healthByDate.entries) {
        final day = entry.key;
        final list = entry.value;
        final healthCount = list.length;
        final healthSum = list.reduce((a, b) => a + b);
        final healthInRange = list.where((v) => v >= 70 && v <= 180).length;

        final base = merged[day];
        final baseCount = (base?['count'] ?? 0.0);
        final baseAvg = (base?['glucose'] ?? 0.0);
        final baseTirPercent = (base?['tir'] ?? 0.0);
        final baseInRangeCount = (baseCount * baseTirPercent / 100.0);

        final combinedCount = baseCount + healthCount;
        final combinedSum = (baseAvg * baseCount) + healthSum;
        final combinedAvg = combinedCount > 0
            ? (combinedSum / combinedCount)
            : 0.0;
        final combinedInRange = baseInRangeCount + healthInRange;
        final combinedTir = combinedCount > 0
            ? (combinedInRange / combinedCount) * 100.0
            : 0.0;

        merged[day] = {
          'glucose': combinedAvg,
          'tir': combinedTir,
          'count': combinedCount,
        };
      }
    } catch (e) {
      // ignore and return base
    }

    return merged;
  }

  // Builds the UI given weekly data list and provider for other info
  Widget _buildStatisticsUI(
    BuildContext context,
    List<Map<String, dynamic>> weeklyData,
    GlucoseProvider glucoseProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final daysInRange = weeklyData
        .where((day) => (day['tir'] as double) >= 70)
        .length;
    final avgGlucose = weeklyData.isEmpty
        ? 0
        : (weeklyData
                  .map((d) => d['glucose'] as double)
                  .reduce((a, b) => a + b) /
              weeklyData.length);
    final avgTir = weeklyData.isEmpty
        ? 0
        : (weeklyData.map((d) => d['tir'] as double).reduce((a, b) => a + b) /
                  weeklyData.length)
              .round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Statistics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.white : AppTheme.darkBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last 7 days',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 16),

          // Summary cards
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 0,
                  color: isDark ? AppTheme.darkCard : AppTheme.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('🎯', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 8),
                        Text(
                          '${avgTir}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Avg TIR',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  elevation: 0,
                  color: isDark ? AppTheme.darkCard : AppTheme.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('📈', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 8),
                        Text(
                          '$daysInRange',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Days in range',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  elevation: 0,
                  color: isDark ? AppTheme.darkCard : AppTheme.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('📊', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 8),
                        Text(
                          '${avgGlucose.round()}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Avg glucose',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bar chart
          Card(
            elevation: 0,
            color: isDark ? AppTheme.darkCard : AppTheme.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily average glucose',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.white : AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 150,
                        minY: 80,
                        barGroups: weeklyData.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value['glucose'] as double,
                                color: AppTheme.successGreen,
                                width: 16,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= weeklyData.length) {
                                  return const SizedBox();
                                }
                                return Text(
                                  weeklyData[value.toInt()]['day'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100), // Odstęp dla bottom navigation
        ],
      ),
    );
  }
}
