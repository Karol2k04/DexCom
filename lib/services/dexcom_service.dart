import 'dart:async';
import 'package:dexcom/dexcom.dart';
import '../models/glucose_reading.dart';

/// COMPATIBLE Fixed DexcomService - Keeps same interface, fixes the "0 readings" issue
/// 
/// Changes from original:
/// 1. Progressive data fetching (tries 1, 3, 7, 14 days instead of jumping to 10)
/// 2. Better error messages and logging
/// 3. Data validation before returning
/// 
/// Interface remains EXACTLY the same - no breaking changes!

class DexcomService {
  Dexcom? _dexcom;
  DexcomStreamProvider? _streamProvider;
  Timer? _pollingTimer;

  final StreamController<List<GlucoseReading>> _readingsController =
      StreamController<List<GlucoseReading>>.broadcast();

  Stream<List<GlucoseReading>> get readingsStream => _readingsController.stream;

  bool get isConnected => _dexcom != null;

  /// Connect to Dexcom with proper region support
  Future<bool> connect({
    required String username,
    required String password,
    DexcomRegion region = DexcomRegion.ous,
  }) async {
    try {
      print("🔌 Connecting to Dexcom with region: $region");

      // Initialize Dexcom object with region support
      _dexcom = Dexcom(
        username: username,
        password: password,
        region: region,
        debug: true,
        onStatusUpdate: (status, finished) {
          print(
            "Dexcom status: ${status.pretty} ${finished ? '(Complete)' : ''}",
          );
        },
      );

      // Verify credentials
      final result = await _dexcom!.verify();
      print("Dexcom verification result: ${result.status}");

      if (!result.status) {
        print("❌ Verification failed: ${result.error}");
        _dexcom = null;
        return false;
      }

      print("✅ Credentials verified");

      // Start listening for real-time updates
      _startStreamListener();

      // PROGRESSIVE FETCHING: Try smaller date ranges first
      bool hasData = false;
      
      // Try 1 day first
      print("📥 Trying to fetch 1 day of data...");
      hasData = await _tryFetchHistoricalData(days: 1);
      
      if (!hasData) {
        print("⚠️ No data in 1 day, trying 3 days...");
        hasData = await _tryFetchHistoricalData(days: 3);
      }
      
      if (!hasData) {
        print("⚠️ No data in 3 days, trying 7 days...");
        hasData = await _tryFetchHistoricalData(days: 7);
      }
      
      if (!hasData) {
        print("⚠️ No data in 7 days, trying 14 days...");
        hasData = await _tryFetchHistoricalData(days: 14);
      }

      if (!hasData) {
        print("❌ No glucose data found in the last 14 days");
        _readingsController.addError(
          "No glucose data found in your DexCom account for the last 14 days.\n\n"
          "Please check:\n"
          "• Your G7 sensor is active and transmitting\n"
          "• Share is enabled in DexCom app (Settings → Share)\n"
          "• You have at least one follower added\n"
          "• Your DexCom app shows recent readings"
        );
        return false;
      }

      print("✅ Successfully connected with ${hasData ? 'data' : 'no data'}");
      return true;

    } catch (e) {
      print("❌ Error connecting to Dexcom: $e");
      _dexcom = null;
      rethrow;
    }
  }

  /// Try to fetch historical data for a specific number of days
  /// Returns true if data was found, false otherwise
  Future<bool> _tryFetchHistoricalData({required int days}) async {
    if (_dexcom == null) return false;

    try {
      final minutes = days * 24 * 60;
      final maxCount = (days * 300).clamp(100, 5000); // Safety limits
      
      print("   Requesting: minutes=$minutes, maxCount=$maxCount");

      final response = await _dexcom!.getGlucoseReadings(
        minutes: minutes,
        maxCount: maxCount,
      );

      print("   Received ${response?.length ?? 0} readings from API");

      if (response == null || response.isEmpty) {
        return false;
      }

      final List<GlucoseReading> readings = _mapToGlucoseReadings(response);
      
      if (readings.isEmpty) {
        print("   No valid readings after mapping");
        return false;
      }

      print("   ✅ Mapped ${readings.length} valid readings");
      _readingsController.add(readings);
      return true;

    } catch (e) {
      print("   ❌ Error fetching $days day(s): $e");
      return false;
    }
  }

  /// Start the stream provider for real-time updates
  void _startStreamListener() {
    if (_dexcom == null) return;

    _streamProvider = DexcomStreamProvider(_dexcom!, debug: true);

    _streamProvider!.listen(
      onData: (data) {
        final readings = _mapToGlucoseReadings(data.cast<DexcomReading>());
        print("Stream received ${readings.length} readings");
        if (readings.isNotEmpty) {
          _readingsController.add(readings);
        }
      },
      onError: (error) {
        print("Stream error: $error");
        _readingsController.addError("Stream error: $error");
      },
      onRefresh: () {
        print("Stream refreshing...");
      },
      onRefreshEnd: (duration) {
        print("Stream refreshed in ${duration.inMilliseconds}ms");
      },
    );
  }

  /// Fetch historical data with flexible date range
  Future<void> fetchHistoricalData({int days = 10}) async {
    if (_dexcom == null) {
      throw Exception("Not connected to Dexcom");
    }

    // Use progressive fetching
    await _tryFetchHistoricalData(days: days);
  }

  /// Map Dexcom readings to app's GlucoseReading model
  List<GlucoseReading> _mapToGlucoseReadings(List<DexcomReading> data) {
    try {
      // Filter out invalid readings
      final validData = data.where((reading) {
        final mgdL = reading.mgdL;
        return mgdL > 0 && mgdL <= 400; // Valid glucose range
      }).toList();

      if (validData.isEmpty) {
        return [];
      }

      // API returns NEWEST first, so reverse to get chronological order
      final sortedData = validData.reversed.toList();

      final list = sortedData.map((reading) {
        final value = reading.mgdL.toDouble();
        final timestamp = reading.displayTime;

        final formattedTime =
            '${timestamp.hour.toString().padLeft(2, '0')}:'
            '${timestamp.minute.toString().padLeft(2, '0')}';

        return GlucoseReading(
          time: formattedTime,
          value: value,
          timestamp: timestamp.millisecondsSinceEpoch,
        );
      }).toList();

      // Debug: Print sample readings
      if (list.isNotEmpty) {
        print("Sample readings (first 3):");
        for (var i = 0; i < list.length && i < 3; i++) {
          print("  ${i + 1}. Time: ${list[i].time}, Value: ${list[i].value}");
        }
      }

      return list;
    } catch (e) {
      print("Error mapping glucose readings: $e");
      return [];
    }
  }

  /// Refresh data manually
  Future<void> refresh() async {
    print("Manual refresh triggered");

    // If we have a stream provider, use it
    if (_streamProvider != null) {
      _streamProvider!.refresh();
    }

    // Also fetch recent historical data
    await _tryFetchHistoricalData(days: 3);
  }

  /// Disconnect from Dexcom
  void disconnect() {
    print("Disconnecting from Dexcom");
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _streamProvider?.close();
    _streamProvider = null;
    _dexcom = null;
  }

  /// Dispose of all resources
  void dispose() {
    disconnect();
    _readingsController.close();
  }
}