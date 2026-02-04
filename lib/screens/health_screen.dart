import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/health_service.dart';
import '../theme/app_theme.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with WidgetsBindingObserver {
  final HealthService _svc = HealthService();
  Map<String, List<Map<String, dynamic>>> _data = {};
  bool _loading = false;
  bool _permsGranted = false;
  bool?
  _healthConnectAvailable; // null = unknown, false = missing, true = available

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkHealthConnectAvailability();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Re-detect Health Connect after returning from Play Store / install flow
      _checkHealthConnectAvailability();
    }
  }

  Future<void> _checkHealthConnectAvailability() async {
    if (kIsWeb) return; // not applicable to web
    try {
      final avail = await _svc.isHealthConnectAvailable();
      if (mounted) setState(() => _healthConnectAvailable = avail);
    } catch (e) {
      if (mounted) setState(() => _healthConnectAvailable = false);
    }
  }

  Future<void> _requestPermissions() async {
    // Early return on web - Health APIs are not supported in web builds
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Health access is not available in the web build. Please use an Android or iOS device.',
            ),
            backgroundColor: AppTheme.warningOrange,
          ),
        );
      }
      return;
    }

    // Re-check availability (user might have just installed Health Connect)
    if (!kIsWeb) {
      await _checkHealthConnectAvailability();
      if (_healthConnectAvailable == false) {
        // Still not available -> prompt install and abort
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Google Health Connect is not available on this device.',
              ),
              action: SnackBarAction(
                label: 'Install',
                textColor: AppTheme.white,
                onPressed: () async {
                  await _svc.installHealthConnect();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Opening Play Store to install Health Connect...',
                      ),
                    ),
                  );
                  await Future.delayed(const Duration(seconds: 2));
                  await _checkHealthConnectAvailability();
                },
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() => _loading = true);
    final res = await _svc.requestPermissions();
    final ok = res['ok'] == true;
    final msg =
        res['message'] as String? ?? 'Permission denied for Health data';
    setState(() {
      _permsGranted = ok;
      _loading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Health permissions granted' : msg),
          backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
          action: (!ok && msg.contains('Health Connect'))
              ? SnackBarAction(
                  label: 'Install',
                  textColor: AppTheme.white,
                  onPressed: () => _svc.installHealthConnect(),
                )
              : null,
        ),
      );
    }
  }

  Future<void> _sync() async {
    setState(() => _loading = true);
    final all = await _svc.fetchAll(range: const Duration(days: 7));
    setState(() {
      _data = Map<String, List<Map<String, dynamic>>>.from(all);
      _loading = false;
    });

    // compute a quick summary and show to the user
    final metricsWithData = _data.entries
        .where((e) => e.value.isNotEmpty)
        .length;
    final totalPoints = _data.values.fold<int>(0, (s, v) => s + v.length);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Synced $metricsWithData metrics — $totalPoints total entries',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final metrics = HealthService.allMetrics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Data'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: kIsWeb ? 'Refresh disabled on web' : 'Refresh',
            onPressed: (_loading || kIsWeb) ? null : _sync,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (kIsWeb)
              Card(
                color: isDark ? AppTheme.darkCard : AppTheme.white,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Health access is not available in the web build. To test syncing and permissions, run the app on an Android or iOS device (emulator with Health Connect may also work).',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Card(
              elevation: 0,
              color: isDark ? AppTheme.darkCard : AppTheme.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Connect and sync health data from HealthKit / Google Fit / Health Connect',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    (_loading ||
                                        (!kIsWeb &&
                                            _healthConnectAvailable == false))
                                    ? null
                                    : _requestPermissions,
                                child: const Text('Request Permissions'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    (!_loading && _permsGranted && !kIsWeb)
                                    ? _sync
                                    : null,
                                child: const Text('Sync (7 days)'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (!kIsWeb && _healthConnectAvailable == false)
                          Card(
                            color: isDark ? AppTheme.darkCard : AppTheme.white,
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Google Health Connect is not available on this device. To use Health data on Android, please install Health Connect and grant permissions to this app.',
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await _svc.installHealthConnect();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Opening Play Store to install Health Connect...',
                                          ),
                                        ),
                                      );
                                      // re-check availability after a short delay
                                      await Future.delayed(
                                        const Duration(seconds: 2),
                                      );
                                      await _checkHealthConnectAvailability();
                                    },
                                    child: const Text('Install Health Connect'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: metrics.map((t) {
                        final points = _data[t] ?? [];
                        final subtitle = points.isEmpty
                            ? 'No data'
                            : '${points.length} entries — latest: ${points.last['value']} at ${points.last['dateFrom']}';

                        return Card(
                          elevation: 0,
                          child: ListTile(
                            title: Text(t),
                            subtitle: Text(subtitle),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
