import 'package:flutter/material.dart';
import '../services/dexcom_service.dart';

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

  // Dexcom
  final DexcomService _dexcomService = DexcomService();
  bool _dexcomConnected = false;
  bool _loadingDexcom = false;

  @override
  void initState() {
    super.initState();
    _initDexcomStatus();
  }

  Future<void> _initDexcomStatus() async {
    final connected = await _dexcomService.isConnected();
    if (!mounted) return;
    setState(() {
      _dexcomConnected = connected;
    });
  }

  Future<void> _handleDexcomButton() async {
    setState(() {
      _loadingDexcom = true;
    });

    if (_dexcomConnected) {
      // disconnect
      await _dexcomService.disconnect();
      if (!mounted) return;
      setState(() {
        _dexcomConnected = false;
        _loadingDexcom = false;
      });
    } else {
      // connect (OAuth flow)
      final ok = await _dexcomService.connect();
      if (!mounted) return;
      setState(() {
        _dexcomConnected = ok;
        _loadingDexcom = false;
      });

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dexcom connection failed')),
        );
      }
    }
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
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Personalize your app',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // === DEXCOM CARD ===
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
                  Row(
                    children: [
                      const Icon(Icons.bluetooth, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Dexcom Integration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _dexcomConnected
                        ? 'Dexcom is connected. Data from sensor can be used on dashboard.'
                        : 'Dexcom is not connected. Connect to read real glucose values.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loadingDexcom ? null : _handleDexcomButton,
                      child: _loadingDexcom
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _dexcomConnected
                                  ? 'Disconnect Dexcom'
                                  : 'Connect Dexcom',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Zakres docelowy
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
                  Row(
                    children: [
                      Icon(Icons.adjust, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Target Range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.grey[900],
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
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                            color: isDark ? Colors.white : Colors.grey[900],
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
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your target range',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${targetMin.round()} - ${targetMax.round()} mg/dL',
                          style: const TextStyle(
                            color: Colors.blue,
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
                    'Units',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
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
                                ? Colors.blue
                                : (isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[200]),
                            foregroundColor: unit == 'mg/dL'
                                ? Colors.white
                                : (isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700]),
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
                                ? Colors.blue
                                : (isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[200]),
                            foregroundColor: unit == 'mmol/L'
                                ? Colors.white
                                : (isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700]),
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
            color: isDark ? Colors.grey[850] : Colors.white,
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
                      Icon(Icons.notifications, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Low glucose level'),
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
                    title: const Text('High glucose level'),
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
          const SizedBox(height: 100), // Odstęp dla bottom navigation
        ],
      ),
    );
  }
}
