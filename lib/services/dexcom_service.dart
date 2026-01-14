import 'dart:async';
import 'package:dexcom/dexcom.dart';
import '../models/glucose_reading.dart';

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
    DexcomRegion region = DexcomRegion.ous, // Default to OUS (includes EU)
  }) async {
    try {
      print("Connecting to Dexcom with region: $region");
      
      // Initialize Dexcom object with region support
      _dexcom = Dexcom(
        username: username,
        password: password,
        region: region, // IMPORTANT: Specify the correct region
        debug: true,
        onStatusUpdate: (status, finished) {
          print("Dexcom status: ${status.pretty} ${finished ? '(Complete)' : ''}");
        },
      );

      // Verify credentials
      final result = await _dexcom!.verify();
      print("Dexcom verification result: ${result.status}");

      if (!result.status) {
        print("Verification failed: ${result.error}");
        _dexcom = null;
        return false;
      }

      // Start listening for real-time updates
      _startStreamListener();

      // Fetch initial data - 10 days
      await fetchHistoricalData(days: 10);

      return true;
    } catch (e) {
      print("Error connecting to Dexcom: $e");
      _dexcom = null;
      rethrow;
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
        _readingsController.add(readings);
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
  /// 
  /// The Dexcom API returns readings with the LATEST reading FIRST.
  /// Each day has ~288 readings (24 hours × 12 readings/hour at 5-min intervals).
  Future<void> fetchHistoricalData({int days = 10}) async {
    if (_dexcom == null) {
      throw Exception("Not connected to Dexcom");
    }

    try {
      print("Fetching glucose readings for the last $days days");

      // Calculate minutes and maxCount for the requested days
      final minutes = days * 24 * 60;
      // Each day has ~288 readings (24 hours × 12 per hour)
      // Add 20% buffer for safety
      final maxCount = (days * 288 * 1.2).ceil();

      print("Requesting: minutes=$minutes, maxCount=$maxCount");

      final response = await _dexcom!.getGlucoseReadings(
        minutes: minutes,
        maxCount: maxCount,
      );

      print("Received ${response?.length ?? 0} readings from API");

      if (response == null || response.isEmpty) {
        print("No data available for the last $days days");
        _readingsController.addError(
          "No glucose data found for the last $days days. "
          "Your Dexcom account may not have measurements in this time range."
        );
        return;
      }

      final List<GlucoseReading> readings = _mapToGlucoseReadings(response);
      print("Mapped ${readings.length} readings");
      
      if (readings.isNotEmpty) {
        print("Date range: ${readings.first.time} to ${readings.last.time}");
        _readingsController.add(readings);
      } else {
        _readingsController.addError("No valid readings found");
      }
    } catch (e) {
      print("Error fetching glucose readings: $e");
      _readingsController.addError("Failed to fetch data: $e");
      rethrow;
    }
  }

  /// Map Dexcom readings to app's GlucoseReading model
  List<GlucoseReading> _mapToGlucoseReadings(List<DexcomReading> data) {
    try {
      // API returns NEWEST first, so reverse to get chronological order
      final sortedData = data.reversed.toList();

      final list = sortedData.map((reading) {
        final value = reading.mgdL.toDouble();
        final timestamp = reading.displayTime;

        final formattedTime = 
            '${timestamp.hour.toString().padLeft(2, '0')}:'
            '${timestamp.minute.toString().padLeft(2, '0')}';

        return GlucoseReading(
          time: formattedTime,
          value: value,
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
    
    // Also fetch historical data
    await fetchHistoricalData(days: 10);
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