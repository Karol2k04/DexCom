import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/glucose_reading.dart';
import '../services/dexcom_service.dart';

// Ekran Dashboard - główny widok z aktualnym poziomem glukozy i wykresem
class DashboardScreen extends StatefulWidget {
  final VoidCallback onAddMeal;

  const DashboardScreen({super.key, required this.onAddMeal});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DexcomService _dexcomService = DexcomService();
  Future<List<GlucoseReading>>? _futureReadings;

  @override
  void initState() {
    super.initState();
    _futureReadings = _loadData();
  }

  Future<List<GlucoseReading>> _loadData() async {
    // Najpierw spróbuj pobrać dane z Dexcom, jeśli jest połączony
    if (await _dexcomService.isConnected()) {
      try {
        final data = await _dexcomService.fetchRecentGlucose();
        if (data.isNotEmpty) {
          return data;
        }
      } catch (_) {
        // w razie błędu wracamy do danych mock
      }
    }

    // Dane mock - odczyty glukozy z ostatnich 24h
    return [
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<GlucoseReading>>(
      future: _futureReadings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading glucose data: ${snapshot.error}'),
          );
        }

        final glucoseData = snapshot.data ?? [];

        // Proste statystyki oparte na danych
        final double currentGlucose =
            glucoseData.isNotEmpty ? glucoseData.last.value : 0;
        final double avgGlucose = glucoseData.isNotEmpty
            ? glucoseData
                    .map((e) => e.value)
                    .reduce((a, b) => a + b) /
                glucoseData.length
            : 0;

        // Zakładamy zakres docelowy 70–180 mg/dL
        const double lowThreshold = 70;
        const double highThreshold = 180;

        int inRangeCount = 0;
        int hypoCount = 0;
        int hyperCount = 0;

        for (final r in glucoseData) {
          if (r.value < lowThreshold) {
            hypoCount++;
          } else if (r.value > highThreshold) {
            hyperCount++;
          } else {
            inRangeCount++;
          }
        }

        final int timeInRange = glucoseData.isNotEmpty
            ? (inRangeCount / glucoseData.length * 100).round()
            : 0;

        final int hypoEpisodes = hypoCount;
        final int hyperEpisodes = hyperCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Card z aktualnym poziomem glukozy
              Card(
                elevation: 0,
                color: isDark ? Colors.grey[850] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Level',
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.monitor_heart,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Normal',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            glucoseData.isNotEmpty
                                ? currentGlucose.toStringAsFixed(0)
                                : '--',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey[900],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 8),
                            child: Text(
                              'mg/dL',
                              style: TextStyle(
                                fontSize: 20,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 16,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stable',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            glucoseData.isNotEmpty
                                ? '• Updated just now'
                                : '• No data',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Szybkie statystyki
              Row(
                children: [
                  // Średnia 24h (albo średnia z dostępnych danych)
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: isDark ? Colors.grey[850] : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '24h Average',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              glucoseData.isNotEmpty
                                  ? avgGlucose.toStringAsFixed(0)
                                  : '--',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : Colors.grey[900],
                              ),
                            ),
                            Text(
                              'mg/dL',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // TIR
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: isDark ? Colors.grey[850] : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TIR',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              glucoseData.isNotEmpty
                                  ? '$timeInRange%'
                                  : '--',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'in range',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Epizody
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: isDark ? Colors.grey[850] : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Episodes',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  glucoseData.isNotEmpty
                                      ? '$hypoEpisodes'
                                      : '--',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  ' / ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                Text(
                                  glucoseData.isNotEmpty
                                      ? '$hyperEpisodes'
                                      : '--',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'low/high',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[500],
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

              // Wykres glukozy
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
                        'Glucose level - recent readings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (glucoseData.isEmpty)
                        SizedBox(
                          height: 120,
                          child: Center(
                            child: Text(
                              'No glucose data available',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                      else
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
                                      if (value.toInt() >=
                                          glucoseData.length) {
                                        return const SizedBox();
                                      }
                                      final time =
                                          glucoseData[value.toInt()].time;
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8),
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
                                        (e) => FlSpot(
                                          e.key.toDouble(),
                                          e.value.value,
                                        ),
                                      )
                                      .toList(),
                                  isCurved: true,
                                  color: Colors.green,
                                  barWidth: 3,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) {
                                      // Pokaż większe kropki dla posiłków (jeśli są)
                                      if (index < glucoseData.length &&
                                          glucoseData[index].meal != null) {
                                        return FlDotCirclePainter(
                                          radius: 6,
                                          color: Colors.orange,
                                          strokeWidth: 2,
                                          strokeColor: Colors.white,
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
                                    color: Colors.green.withOpacity(0.1),
                                  ),
                                ),
                              ],
                              // Linie referencyjne dla zakresów
                              extraLinesData: ExtraLinesData(
                                horizontalLines: [
                                  HorizontalLine(
                                    y: 70,
                                    color: Colors.blue.withOpacity(0.5),
                                    strokeWidth: 1,
                                    dashArray: [5, 5],
                                  ),
                                  HorizontalLine(
                                    y: 140,
                                    color: Colors.red.withOpacity(0.5),
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
      },
    );
  }
}
