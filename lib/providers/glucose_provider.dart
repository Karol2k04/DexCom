// providers/glucose_provider.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dexcom/dexcom.dart';
import '../models/glucose_reading.dart';
import '../models/csv_data_entry.dart';
import '../models/history_entry.dart';
import '../services/dexcom_service.dart';
import '../services/csv_import_service.dart';
import '../services/firestore_service.dart';

class GlucoseProvider with ChangeNotifier {
  final DexcomService _dexcomService = DexcomService();
  final CsvImportService _csvService = CsvImportService();
  final FirestoreService _firestoreService = FirestoreService();

  List<GlucoseReading> _glucoseData = [];
  List<GlucoseReading> get glucoseData => _glucoseData;

  // CSV specific data
  final List<CsvDataEntry> _csvEntries = [];
  List<CsvDataEntry> get csvEntries => _csvEntries;

  // History entries from CSV imports
  final List<HistoryEntry> _historyEntries = [];
  List<HistoryEntry> get historyEntries => _historyEntries;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Track data source
  String _dataSource = 'none'; // 'none', 'dexcom', 'csv'
  String get dataSource => _dataSource;

  GlucoseProvider() {
    // Initialize listener for the readings stream
    _dexcomService.readingsStream.listen(
      (data) {
        _glucoseData = data;
        _isLoading = false;
        _errorMessage = null;
        _isConnected = true;
        _dataSource = 'dexcom';
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Import glucose data from CSV file and save to Firestore
  Future<void> importFromCsv(Uint8List fileBytes, String fileName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Importing CSV file: $fileName');

      // 1. Parse CSV to get glucose readings
      final readings = await _csvService.parseDexcomCsv(fileBytes);

      if (readings.isEmpty) {
        throw Exception('No glucose readings found in CSV file');
      }

      // 2. Save to Firestore
      try {
        final importId = await _firestoreService.saveGlucoseReadingsFromCsv(
          readings: readings,
          fileName: fileName,
        );
        debugPrint('✅ Saved to Firestore with importId: $importId');
      } catch (firestoreError) {
        debugPrint('⚠️ Firestore save failed: $firestoreError');
        // Continue with local storage even if Firestore fails
      }

      // 3. Update local state
      _glucoseData = readings;
      _dataSource = 'csv';
      _isConnected = false;

      // 4. Create history entries from the import using actual timestamps from CSV
      _historyEntries.clear();
      for (var reading in readings) {
        final readingTime = DateTime.fromMillisecondsSinceEpoch(
          reading.timestamp,
        );

        // Format time and date from CSV timestamp
        final timeStr =
            '${readingTime.hour.toString().padLeft(2, '0')}:${readingTime.minute.toString().padLeft(2, '0')}';
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final readingDate = DateTime(
          readingTime.year,
          readingTime.month,
          readingTime.day,
        );

        String dateStr;
        if (readingDate == today) {
          dateStr = 'Today';
        } else if (readingDate == yesterday) {
          dateStr = 'Yesterday';
        } else {
          dateStr =
              '${readingTime.month.toString().padLeft(2, '0')}-${readingTime.day.toString().padLeft(2, '0')}';
        }

        final entry = HistoryEntry(
          id: reading.timestamp.toString(),
          time: timeStr,
          date: dateStr,
          glucose: reading.value,
          trend: _calculateTrend(reading.value),
          timestamp: readingTime,
        );
        _historyEntries.add(entry);
      }

      // Sort by timestamp descending (newest first)
      _historyEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _errorMessage = null;
      debugPrint('CSV imported successfully: ${readings.length} readings');
    } catch (e) {
      _errorMessage = 'Failed to import CSV: $e';
      debugPrint('CSV import error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load data from Firestore on app start (after login)
  Future<void> loadDataFromFirestore() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Loading data from Firestore...');

      // Check if user has any data
      final hasData = await _firestoreService.hasExistingData();
      if (!hasData) {
        debugPrint('No data found in Firestore');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Load all glucose readings
      final readings = await _firestoreService.getAllGlucoseReadings();
      debugPrint('Loaded ${readings.length} readings from Firestore');

      _glucoseData = readings;
      _dataSource = 'csv';

      // Create history entries
      _historyEntries.clear();
      for (var reading in readings) {
        final readingTime = DateTime.fromMillisecondsSinceEpoch(
          reading.timestamp,
        );

        final timeStr =
            '${readingTime.hour.toString().padLeft(2, '0')}:${readingTime.minute.toString().padLeft(2, '0')}';
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final readingDate = DateTime(
          readingTime.year,
          readingTime.month,
          readingTime.day,
        );

        String dateStr;
        if (readingDate == today) {
          dateStr = 'Today';
        } else if (readingDate == yesterday) {
          dateStr = 'Yesterday';
        } else {
          dateStr =
              '${readingTime.month.toString().padLeft(2, '0')}-${readingTime.day.toString().padLeft(2, '0')}';
        }

        final entry = HistoryEntry(
          id: reading.timestamp.toString(),
          time: timeStr,
          date: dateStr,
          glucose: reading.value,
          trend: _calculateTrend(reading.value),
          timestamp: readingTime,
        );
        _historyEntries.add(entry);
      }

      _historyEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      debugPrint('✅ Successfully loaded data from Firestore');
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load data from Firestore: $e';
      debugPrint('❌ Firestore load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to calculate trend
  String _calculateTrend(double glucose) {
    if (glucose < 70) return 'down';
    if (glucose > 180) return 'up';
    return 'stable';
  }

  // Calculate average glucose for statistics
  double getAverageGlucose() {
    if (_glucoseData.isEmpty) return 0;
    final sum = _glucoseData.map((r) => r.value).reduce((a, b) => a + b);
    return sum / _glucoseData.length;
  }

  // Calculate Time In Range
  int getTimeInRange() {
    if (_glucoseData.isEmpty) return 0;
    final inRange = _glucoseData
        .where((r) => r.value >= 70 && r.value <= 180)
        .length;
    return ((inRange / _glucoseData.length) * 100).round();
  }

  // Get daily statistics for charts
  Map<String, Map<String, double>> getDailyStats() {
    final Map<String, List<double>> dailyReadings = {};

    for (var reading in _glucoseData) {
      final date = DateTime.fromMillisecondsSinceEpoch(reading.timestamp);
      final dayKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      if (!dailyReadings.containsKey(dayKey)) {
        dailyReadings[dayKey] = [];
      }
      dailyReadings[dayKey]!.add(reading.value);
    }

    // Calculate averages
    final Map<String, Map<String, double>> stats = {};
    dailyReadings.forEach((day, readings) {
      final avg = readings.reduce((a, b) => a + b) / readings.length;
      final inRange = readings.where((r) => r >= 70 && r <= 180).length;
      final tirPercent = (inRange / readings.length) * 100;

      stats[day] = {
        'glucose': avg,
        'tir': tirPercent,
        'count': readings.length.toDouble(),
      };
    });

    return stats;
  }

  // Get filtered history entries based on period
  List<HistoryEntry> getFilteredHistory(String period) {
    final now = DateTime.now();
    DateTime cutoffDate;

    switch (period) {
      case '24h':
        cutoffDate = now.subtract(const Duration(hours: 24));
        break;
      case '7 days':
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case '14 days':
        cutoffDate = now.subtract(const Duration(days: 14));
        break;
      case '30 days':
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      default:
        cutoffDate = now.subtract(const Duration(hours: 24));
    }

    return _historyEntries
        .where((entry) => entry.timestamp.isAfter(cutoffDate))
        .toList();
  }

  /// Clear CSV data
  void clearCsvData() {
    if (_dataSource == 'csv') {
      _glucoseData = [];
      _dataSource = 'none';
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Connect to Dexcom with region support
  Future<void> connectDexcom(
    String username,
    String password, {
    DexcomRegion region = DexcomRegion.ous,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint("Connecting to Dexcom with region: $region");

      final success = await _dexcomService.connect(
        username: username,
        password: password,
        region: region,
      );

      if (!success) {
        _errorMessage =
            "Failed to connect to Dexcom. Please check your credentials and region.";
        _isConnected = false;
      } else {
        _isConnected = true;
        _dataSource = 'dexcom';
        _errorMessage = null;
        // Clear any CSV data when connecting to Dexcom
        if (_dataSource == 'csv') {
          _glucoseData = [];
        }
        debugPrint("Successfully connected to Dexcom");
      }
    } catch (e) {
      _errorMessage = "Connection error: $e";
      _isConnected = false;
      debugPrint("Dexcom connection error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh data - fetches last 10 days
  Future<void> refresh() async {
    if (!_isConnected) {
      _errorMessage =
          "Not connected to Dexcom. Please connect first or import a CSV file.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dexcomService.refresh();
    } catch (e) {
      _errorMessage = "Refresh error: $e";
      debugPrint("Dexcom refresh error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch historical data with custom date range
  Future<void> fetchHistoricalData({int days = 10}) async {
    if (!_isConnected) {
      _errorMessage =
          "Not connected to Dexcom. Please connect first or import a CSV file.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dexcomService.fetchHistoricalData(days: days);
    } catch (e) {
      _errorMessage = "Failed to fetch historical data: $e";
      debugPrint("Dexcom historical data error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Disconnect from Dexcom
  void disconnect() {
    _dexcomService.disconnect();
    _isConnected = false;
    _glucoseData = [];
    _dataSource = 'none';
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _dexcomService.dispose();
    super.dispose();
  }
}
