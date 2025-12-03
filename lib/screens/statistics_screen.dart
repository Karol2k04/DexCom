import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Ekran statystyk
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dane mock dla wykresu tygodniowego
    final weeklyData = [
      {'day': 'Pn', 'glucose': 112.0, 'insulin': 45.0},
      {'day': 'Wt', 'glucose': 118.0, 'insulin': 48.0},
      {'day': 'Śr', 'glucose': 108.0, 'insulin': 42.0},
      {'day': 'Cz', 'glucose': 125.0, 'insulin': 52.0},
      {'day': 'Pt', 'glucose': 115.0, 'insulin': 46.0},
      {'day': 'Sb', 'glucose': 105.0, 'insulin': 40.0},
      {'day': 'Nd', 'glucose': 110.0, 'insulin': 44.0},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statystyki',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ostatnie 7 dni',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Karty podsumowania
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 0,
                  color: isDark ? Colors.grey[850] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.trending_up, color: Colors.green, size: 24),
                        const SizedBox(height: 8),
                        const Text(
                          '78%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'TIR średnia',
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
                  color: isDark ? Colors.grey[850] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '5',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Dni w normie',
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
                  color: isDark ? Colors.grey[850] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.show_chart, color: Colors.purple, size: 24),
                        const SizedBox(height: 8),
                        const Text(
                          '112',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Śr. glukoza',
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
          Card(
            elevation: 0,
            color: isDark ? Colors.grey[850] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Średnie dzienne glukozy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[900],
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
                                color: Colors.green,
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
                                if (value.toInt() >= weeklyData.length)
                                  return const SizedBox();
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
