import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../providers/glucose_provider.dart';

// Ekran statystyk
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<GlucoseProvider>(
      builder: (context, glucoseProvider, child) {
        // Get real data from provider
        final dailyStats = glucoseProvider.getDailyStats();
        final avgGlucose = glucoseProvider.getAverageGlucose();
        final avgTir = glucoseProvider.getTimeInRange();

        // Convert daily stats to chart data (last 7 days)
        final now = DateTime.now();
        final List<Map<String, dynamic>> weeklyData = [];
        final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dayKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final stats = dailyStats[dayKey];

          weeklyData.add({
            'day': daysOfWeek[date.weekday - 1],
            'glucose': stats?['glucose'] ?? 0.0,
            'tir': stats?['tir'] ?? 0.0,
          });
        }

        // Count days in range (TIR > 70%)
        final daysInRange = weeklyData
            .where((day) => (day['tir'] as double) >= 70)
            .length;

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
}
