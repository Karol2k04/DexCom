import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/health_service.dart';
import '../theme/app_theme.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final HealthService _svc = HealthService();
  Map<String, List<Map<String, dynamic>>> _data = {};
  bool _loading = false;
  bool _permsGranted = false;

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

    setState(() => _loading = true);
    final ok = await _svc.requestPermissions();
    setState(() {
      _permsGranted = ok;
      _loading = false;
    });
    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health permissions granted'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied for Health data'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
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
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loading ? null : _requestPermissions,
                            child: const Text('Request Permissions'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: (!_loading && _permsGranted && !kIsWeb)
                                ? _sync
                                : null,
                            child: const Text('Sync (7 days)'),
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
