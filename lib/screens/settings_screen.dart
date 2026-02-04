import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'health_screen.dart';
import '../providers/settings_provider.dart';

// Ekran ustawień
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double targetMin = 70;
  double targetMax = 140;
  String unit = 'mg/dL';
  Map<String, bool> notifications = {
    'low': true,
    'high': true,
    'meals': true,
    'insulin': false,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚙️ Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.white : AppTheme.darkBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Personalize your app',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 24),

          // Zakres docelowy
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
                  Row(
                    children: [
                      Text('🎯', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        'Target Range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.white : AppTheme.darkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dolna granica
                  Text(
                    'Lower limit',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : AppTheme.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: targetMin,
                          min: 60,
                          max: 100,
                          divisions: 40,
                          label: targetMin.round().toString(),
                          activeColor: AppTheme.successGreen,
                          onChanged: (value) {
                            setState(() {
                              targetMin = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '${targetMin.round()} mg/dL',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: isDark ? AppTheme.white : AppTheme.darkBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Górna granica
                  Text(
                    'Upper limit',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : AppTheme.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: targetMax,
                          min: 120,
                          max: 180,
                          divisions: 60,
                          label: targetMax.round().toString(),
                          activeColor: AppTheme.warningOrange,
                          onChanged: (value) {
                            setState(() {
                              targetMax = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '${targetMax.round()} mg/dL',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: isDark ? AppTheme.white : AppTheme.darkBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your target range',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey[300]
                                : AppTheme.darkGray,
                          ),
                        ),
                        Text(
                          '${targetMin.round()} - ${targetMax.round()} mg/dL',
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Jednostki
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
                  Row(
                    children: [
                      Text('📏', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        'Units',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.white : AppTheme.darkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              unit = 'mg/dL';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: unit == 'mg/dL'
                                ? AppTheme.primaryBlue
                                : (isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[200]),
                            foregroundColor: unit == 'mg/dL'
                                ? AppTheme.white
                                : (isDark
                                      ? Colors.grey[300]
                                      : AppTheme.darkGray),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('mg/dL'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              unit = 'mmol/L';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: unit == 'mmol/L'
                                ? AppTheme.primaryBlue
                                : (isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[200]),
                            foregroundColor: unit == 'mmol/L'
                                ? AppTheme.white
                                : (isDark
                                      ? Colors.grey[300]
                                      : AppTheme.darkGray),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('mmol/L'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Powiadomienia
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
                  Row(
                    children: [
                      Text('🔔', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.white : AppTheme.darkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Row(
                      children: [
                        Text('🔴', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Low glucose level')),
                      ],
                    ),
                    subtitle: const Text('Alert for hypoglycemia'),
                    value: notifications['low']!,
                    onChanged: (value) {
                      setState(() {
                        notifications['low'] = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: Row(
                      children: [
                        Text('⚡', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('High glucose level')),
                      ],
                    ),
                    subtitle: const Text('Alert for hyperglycemia'),
                    value: notifications['high']!,
                    onChanged: (value) {
                      setState(() {
                        notifications['high'] = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Meal reminders'),
                    subtitle: const Text('Notifications about regular meals'),
                    value: notifications['meals']!,
                    onChanged: (value) {
                      setState(() {
                        notifications['meals'] = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Insulin reminders'),
                    subtitle: const Text('Dose notifications'),
                    value: notifications['insulin']!,
                    onChanged: (value) {
                      setState(() {
                        notifications['insulin'] = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Health integration (independent from Dexcom/CSV)
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
                  Row(
                    children: [
                      Text('💓', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        'Health Data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.white : AppTheme.darkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'View metrics synced from your phone or wearable (HealthKit / Google Fit / Health Connect). These metrics are shown independently from Dexcom or imported CSV data.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HealthScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.health_and_safety),
                      label: const Text('Open Health Data'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: const BorderSide(color: AppTheme.primaryBlue),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Toggle to include Health glucose into Statistics
                  Consumer<SettingsProvider>(
                    builder: (context, settings, child) {
                      return SwitchListTile(
                        title: const Text(
                          'Include health glucose in statistics',
                        ),
                        subtitle: const Text(
                          'Pull BLOOD_GLUCOSE from Health services and include in stats',
                        ),
                        value: settings.includeHealthGlucose,
                        onChanged: (val) =>
                            settings.setIncludeHealthGlucose(val),
                        contentPadding: EdgeInsets.zero,
                      );
                    },
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
