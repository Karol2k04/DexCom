import 'package:flutter/material.dart';
import '../models/history_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

// Ekran historii pomiarów
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectedPeriod = '24h';

  // Dane mock - historia pomiarów
  final List<HistoryEntry> mockHistory = [
    HistoryEntry(
      id: '1',
      time: '22:30',
      date: 'Today',
      glucose: 112,
      trend: 'stable',
    ),
    HistoryEntry(
      id: '2',
      time: '20:15',
      date: 'Today',
      glucose: 148,
      insulin: 8,
      trend: 'up',
    ),
    HistoryEntry(
      id: '3',
      time: '19:00',
      date: 'Today',
      glucose: 115,
      meal: 'Dinner',
      carbs: 45,
      trend: 'up',
    ),
    HistoryEntry(
      id: '4',
      time: '17:30',
      date: 'Today',
      glucose: 98,
      trend: 'stable',
    ),
    HistoryEntry(
      id: '5',
      time: '15:00',
      date: 'Today',
      glucose: 138,
      trend: 'down',
    ),
    HistoryEntry(
      id: '6',
      time: '14:30',
      date: 'Today',
      glucose: 155,
      insulin: 10,
      alert: 'high',
      trend: 'up',
    ),
    HistoryEntry(
      id: '7',
      time: '13:00',
      date: 'Today',
      glucose: 108,
      meal: 'Lunch',
      carbs: 60,
      trend: 'up',
    ),
    HistoryEntry(
      id: '8',
      time: '11:00',
      date: 'Today',
      glucose: 110,
      trend: 'down',
    ),
    HistoryEntry(
      id: '9',
      time: '09:30',
      date: 'Today',
      glucose: 145,
      insulin: 6,
      trend: 'up',
    ),
    HistoryEntry(
      id: '10',
      time: '08:00',
      date: 'Today',
      glucose: 105,
      meal: 'Breakfast',
      carbs: 50,
      trend: 'up',
    ),
  ];

  Color getGlucoseColor(double value, String? alert) {
    if (alert == 'low' || value < 70) return AppTheme.lowRed;
    if (alert == 'high' || value > 140) return AppTheme.dangerRed;
    return AppTheme.successGreen;
  }

  IconData getTrendIcon(String trend) {
    if (trend == 'up') return Icons.trending_up;
    if (trend == 'down') return Icons.trending_down;
    return Icons.trending_flat;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 Measurement History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 16),

          // Filtry czasowe
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['24h', '7 days', '14 days', '30 days'].map((filter) {
                final isSelected = selectedPeriod == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedPeriod = filter;
                      });
                    },
                    backgroundColor: isDark ? Colors.grey[850] : Colors.white,
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Lista historii
          ...mockHistory.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(12),
                blur: 6.0,
                overlayColor: isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.white.withOpacity(0.6),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Czas i data
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('🕐', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  entry.time,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.grey[900],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              entry.date,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                        // Poziom glukozy
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: getGlucoseColor(
                                  entry.glucose,
                                  entry.alert,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    AppTheme.getGlucoseStatusEmoji(
                                      entry.glucose,
                                    ),
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    entry.glucose.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: getGlucoseColor(
                                        entry.glucose,
                                        entry.alert,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.trend == 'up'
                                  ? '📈'
                                  : entry.trend == 'down'
                                  ? '📉'
                                  : '➡️',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Dodatkowe informacje
                    if (entry.meal != null || entry.insulin != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            if (entry.meal != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text('🍽️', style: TextStyle(fontSize: 14)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${entry.meal}${entry.carbs != null ? " (${entry.carbs}g)" : ""}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (entry.meal != null && entry.insulin != null)
                              const SizedBox(width: 12),
                            if (entry.insulin != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text('💉', style: TextStyle(fontSize: 14)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${entry.insulin}U',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 100), // Odstęp dla bottom navigation
        ],
      ),
    );
  }
}
