// screens/dashboard_screen.dart - Updated version
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/glucose_reading.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../providers/glucose_provider.dart';
import 'dexcom_connect_screen.dart';
import 'csv_import_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onAddMeal;

  const DashboardScreen({super.key, required this.onAddMeal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<GlucoseProvider>(
      builder: (context, glucoseProvider, child) {
        final List<GlucoseReading> glucoseData = glucoseProvider.glucoseData;
        
        final double currentGlucose = glucoseData.isNotEmpty 
            ? glucoseData.last.value 
            : 0;
        
        // Calculate stats from actual data
        final double avgGlucose = glucoseData.isNotEmpty
            ? glucoseData.map((r) => r.value).reduce((a, b) => a + b) / glucoseData.length
            : 0;
        
        final int timeInRange = glucoseData.isNotEmpty
            ? (glucoseData.where((r) => r.value >= 70 && r.value <= 180).length / glucoseData.length * 100).round()
            : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // No data state - show options to connect or import
              if (!glucoseProvider.isConnected && glucoseData.isEmpty)
                Card(
                  elevation: 0,
                  color: AppTheme.warningOrange.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.warningOrange,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No Glucose Data Available',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.warningOrange,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Choose how you want to view your glucose data:',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const DexcomConnectScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.cloud),
                                label: const Text('Connect Dexcom'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CsvImportScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Import CSV'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.successGreen,
                                  side: const BorderSide(color: AppTheme.successGreen),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Data source indicator
              if (glucoseData.isNotEmpty)
                Card(
                  elevation: 0,
                  color: glucoseProvider.dataSource == 'dexcom'
                      ? AppTheme.successGreen.withOpacity(0.1)
                      : AppTheme.primaryBlue.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          glucoseProvider.dataSource == 'dexcom'
                              ? Icons.cloud_done
                              : Icons.description,
                          color: glucoseProvider.dataSource == 'dexcom'
                              ? AppTheme.successGreen
                              : AppTheme.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          glucoseProvider.dataSource == 'dexcom'
                              ? '🔗 Connected to Dexcom Share'
                              : '📊 Viewing CSV Data',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: glucoseProvider.dataSource == 'dexcom'
                                ? AppTheme.successGreen
                                : AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (glucoseData.isNotEmpty) const SizedBox(height: 16),

              // Action Buttons Row
              Row(
                children: [
                  if (glucoseProvider.isConnected)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: glucoseProvider.isLoading
                            ? null
                            : () => glucoseProvider.refresh(),
                        icon: glucoseProvider.isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.white,
                                ),
                              )
                            : const Icon(Icons.refresh, size: 20),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CsvImportScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.upload_file, size: 20),
                        label: Text(
                          glucoseData.isEmpty ? 'Import CSV' : 'Change CSV',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DexcomConnectScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings, size: 20),
                      label: Text(
                        glucoseProvider.isConnected ? 'Settings' : 'Connect',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Loading Indicator
              if (glucoseProvider.isLoading && glucoseData.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading glucose data...'),
                      ],
                    ),
                  ),
                ),

              // Error Message
              if (glucoseProvider.errorMessage != null)
                Card(
                  elevation: 0,
                  color: AppTheme.dangerRed.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.dangerRed,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            glucoseProvider.errorMessage!,
                            style: TextStyle(
                              color: AppTheme.dangerRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (glucoseData.isNotEmpty) ...[
                const SizedBox(height: 16),
                
                // Current Glucose Card
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
                          Text(
                            '📊 Current Level',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : AppTheme.darkGray,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.getGlucoseStatusColor(currentGlucose)
                                  .withOpacity(0.15),
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
                                    color: AppTheme.getGlucoseStatusColor(currentGlucose),
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
                                '📊 ${glucoseData.length} readings',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.successGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '🕐 ${glucoseData.last.time}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Statistics Cards
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 0,
                        color: isDark ? AppTheme.darkCard : AppTheme.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text('📈', style: TextStyle(fontSize: 24)),
                              const SizedBox(height: 8),
                              Text(
                                avgGlucose.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Avg',
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
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text('🎯', style: TextStyle(fontSize: 24)),
                              const SizedBox(height: 8),
                              Text(
                                '$timeInRange%',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'TIR',
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

                // Chart
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
                          'Glucose Levels - Last ${glucoseData.length} Readings',
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
                                    interval: glucoseData.length > 20
                                        ? (glucoseData.length / 6).ceilToDouble()
                                        : 4,
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
                              maxY: 200,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: glucoseData
                                      .asMap()
                                      .entries
                                      .map((e) => FlSpot(
                                            e.key.toDouble(),
                                            e.value.value,
                                          ))
                                      .toList(),
                                  isCurved: true,
                                  color: AppTheme.successGreen,
                                  barWidth: 3,
                                  dotData: FlDotData(show: glucoseData.length <= 50),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppTheme.successGreen.withOpacity(0.1),
                                  ),
                                ),
                              ],
                              extraLinesData: ExtraLinesData(
                                horizontalLines: [
                                  HorizontalLine(
                                    y: 70,
                                    color: AppTheme.lowRed.withOpacity(0.5),
                                    strokeWidth: 1,
                                    dashArray: [5, 5],
                                  ),
                                  HorizontalLine(
                                    y: 180,
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
              ],

              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }
}