// providers/glucose_provider.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dexcom/dexcom.dart';
import '../models/glucose_reading.dart';
import '../services/dexcom_service.dart';
import '../services/csv_import_service.dart';

class GlucoseProvider with ChangeNotifier {
  final DexcomService _dexcomService = DexcomService();
  final CsvImportService _csvService = CsvImportService();
  
  List<GlucoseReading> _glucoseData = [];
  List<GlucoseReading> get glucoseData => _glucoseData;
  
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

  /// Import glucose data from CSV file
  Future<void> importFromCsv(Uint8List fileBytes, String fileName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Importing CSV file: $fileName');
      
      final readings = await _csvService.parseDexcomCsv(fileBytes);
      
      if (readings.isEmpty) {
        throw Exception('No glucose readings found in CSV file');
      }

      _glucoseData = readings;
      _dataSource = 'csv';
      _isConnected = false; // CSV data is not "connected"
      _errorMessage = null;
      
      final stats = _csvService.getCsvStats(readings);
      debugPrint('CSV imported successfully: ${stats['count']} readings');
      
    } catch (e) {
      _errorMessage = 'Failed to import CSV: $e';
      debugPrint('CSV import error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
        _errorMessage = "Failed to connect to Dexcom. Please check your credentials and region.";
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
      _errorMessage = "Not connected to Dexcom. Please connect first or import a CSV file.";
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
      _errorMessage = "Not connected to Dexcom. Please connect first or import a CSV file.";
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