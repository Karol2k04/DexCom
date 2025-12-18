import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/glucose_reading.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

// Ekran Dashboard - główny widok z aktualnym poziomem glukozy i wykresem
class DashboardScreen extends StatelessWidget {
  final VoidCallback onAddMeal;

  const DashboardScreen({super.key, required this.onAddMeal});

  @override
  Widget build(BuildContext context) {
    // Dane mock - odczyty glukozy z ostatnich 24h
    final List<GlucoseReading> glucoseData = [
      GlucoseReading(time: '00:00', value: 95),
      GlucoseReading(time: '02:00', value: 88),
      GlucoseReading(time: '04:00', value: 92),
      GlucoseReading(time: '06:00', value: 98),
      GlucoseReading(time: '08:00', value: 105, meal: 'breakfast'),
      GlucoseReading(time: '09:00', value: 145),
      GlucoseReading(time: '10:00', value: 128),
      GlucoseReading(time: '11:00', value: 110),
      GlucoseReading(time: '12:00', value: 102),
      GlucoseReading(time: '13:00', value: 108, meal: 'lunch'),
      GlucoseReading(time: '14:00', value: 155),
      GlucoseReading(time: '15:00', value: 138),
      GlucoseReading(time: '16:00', value: 118),
      GlucoseReading(time: '17:00', value: 105),
      GlucoseReading(time: '18:00', value: 98),
      GlucoseReading(time: '19:00', value: 115, meal: 'dinner'),
      GlucoseReading(time: '20:00', value: 148),
      GlucoseReading(time: '21:00', value: 132),
      GlucoseReading(time: '22:00', value: 118),
      GlucoseReading(time: '23:59', value: 112),
    ];

    const double currentGlucose = 112;
    const double avgGlucose = 115;
    const int timeInRange = 78;
    const int hypoEpisodes = 0;
    const int hyperEpisodes = 3;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card z aktualnym poziomem glukozy (glass)
          GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: BorderRadius.circular(16),
            blur: 6.0,
            overlayColor: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.white.withOpacity(0.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📊 Current Level',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey[400]
                                : AppTheme.darkGray,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.getGlucoseStatusColor(
                          currentGlucose,
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            AppTheme.getGlucoseStatusEmoji(currentGlucose),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppTheme.getGlucoseStatusText(currentGlucose),
                            style: TextStyle(
                              color: AppTheme.getGlucoseStatusColor(
                                currentGlucose,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      currentGlucose.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getGlucoseStatusColor(currentGlucose),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 12),
                      child: Text(
                        'mg/dL',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : AppTheme.darkGray,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '📈 Stable',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '🕐 2 min ago',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 16,
                      color: AppTheme.successGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stable',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• Updated 2 min ago',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Szybkie statystyki
          Row(
            children: [
              // Średnia 24h (glass)
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(16),
                  blur: 6.0,
                  overlayColor: isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.white.withOpacity(0.6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('📊', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            '24h Avg',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[400]
                                  : AppTheme.darkGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        avgGlucose.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getGlucoseStatusColor(avgGlucose),
                        ),
                      ),
                      Text(
                        'mg/dL',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // TIR (glass)
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(16),
                  blur: 6.0,
                  overlayColor: isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.white.withOpacity(0.6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('🎯', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'TIR',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[400]
                                  : AppTheme.darkGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$timeInRange%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successGreen,
                        ),
                      ),
                      Text(
                        'in range',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Epizody (glass)
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(16),
                  blur: 6.0,
                  overlayColor: isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.white.withOpacity(0.6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('⚠️', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'Episodes',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[400]
                                  : AppTheme.darkGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('🔴', style: TextStyle(fontSize: 12)),
                                Text(
                                  '$hypoEpisodes',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.lowRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('⚡', style: TextStyle(fontSize: 12)),
                                Text(
                                  '$hyperEpisodes',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.dangerRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                    'Glucose level - last 24h',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.white : AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 250,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 30,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: 30,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 4,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= glucoseData.length) {
                                  return const SizedBox();
                                }
                                final time = glucoseData[value.toInt()].time;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    time,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 60,
                        maxY: 180,
                        lineBarsData: [
                          // Główna linia glukozy
                          LineChartBarData(
                            spots: glucoseData
                                .asMap()
                                .entries
                                .map(
                                  (e) =>
                                      FlSpot(e.key.toDouble(), e.value.value),
                                )
                                .toList(),
                            isCurved: true,
                            color: AppTheme.successGreen,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                // Pokaż większe kropki dla posiłków
                                if (glucoseData[index].meal != null) {
                                  return FlDotCirclePainter(
                                    radius: 6,
                                    color: AppTheme.warningOrange,
                                    strokeWidth: 2,
                                    strokeColor: AppTheme.white,
                                  );
                                }
                                return FlDotCirclePainter(
                                  radius: 0,
                                  color: Colors.transparent,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.successGreen.withOpacity(0.1),
                            ),
                          ),
                        ],
                        // Linie referencyjne dla zakresów
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: 70,
                              color: AppTheme.lowRed.withOpacity(0.5),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                            HorizontalLine(
                              y: 140,
                              color: AppTheme.dangerRed.withOpacity(0.5),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                          ],
                        ),
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
