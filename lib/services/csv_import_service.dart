// services/csv_import_service.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import '../models/glucose_reading.dart';

class CsvImportService {
  Future<List<GlucoseReading>> parseDexcomCsv(Uint8List fileBytes) async {
    try {
      // 1. Read raw text
      String csvString = String.fromCharCodes(fileBytes);
      
      // Remove BOM
      const bom = '\uFEFF';
      if (csvString.startsWith(bom)) {
        csvString = csvString.substring(bom.length);
      }
      
      // Normalize line endings (handle Windows \r\n and old Mac \r)
      csvString = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      // 2. Detect Delimiter (Tab, Comma, or Pipe)
      final lines = csvString.split('\n');
      String detectedDelimiter = ','; // Default to Comma for Clarity exports
      
      int tabCount = 0;
      int commaCount = 0;
      int pipeCount = 0;

      // Check first 5 lines
      for (var line in lines.take(5)) {
        if (line.trim().isEmpty) continue;
        tabCount += '\t'.allMatches(line).length;
        commaCount += ','.allMatches(line).length;
        pipeCount += '|'.allMatches(line).length;
      }

      if (tabCount > commaCount && tabCount > pipeCount) {
        detectedDelimiter = '\t';
      } else if (pipeCount > commaCount && pipeCount > tabCount) {
        detectedDelimiter = '|';
      }
      
      debugPrint('Detected delimiter: "$detectedDelimiter" (Tab: $tabCount, Comma: $commaCount, Pipe: $pipeCount)');

      // 3. Parse CSV with detected delimiter
      final converter = CsvToListConverter(
        fieldDelimiter: detectedDelimiter,
        eol: '\n',
        shouldParseNumbers: false,
      );
      
      final List<List<dynamic>> csvData = converter.convert(csvString);
      
      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // 4. Find Header Row using FUZZY matching
      List<String> headerRow = [];
      int headerRowIndex = -1;
      
      for (int i = 0; i < csvData.length && i < 20; i++) {
        final row = csvData[i];
        if (row.isEmpty) continue;
        
        final potentialHeaders = row.map((e) => e.toString().trim().toLowerCase()).toList();
        
        // Check if this row has words resembling our required headers
        // Support both "Timestamp" and "Timestamp (YYYY-MM-DDThh:mm:ss)"
        final hasTimestamp = potentialHeaders.any((h) => h.contains('timestamp'));
        // Support both "Glucose" and "Glucose Value (mg/dL)"
        final hasGlucose = potentialHeaders.any((h) => h.contains('glucose'));
        // Support both "Event" and "Event Type"
        final hasEvent = potentialHeaders.any((h) => h.contains('event'));

        if (hasTimestamp && hasGlucose && hasEvent) {
          headerRow = csvData[i].map((e) => e.toString().trim()).toList();
          headerRowIndex = i;
          debugPrint('Found header row at index $i with ${headerRow.length} columns');
          break;
        }
      }

      if (headerRow.isEmpty) {
        throw Exception('Could not find headers containing "Timestamp", "Glucose", or "Event". Check file format.');
      }

      // 5. Find Column Indices FUZZILY
      // For Clarity exports: "Timestamp (YYYY-MM-DDThh:mm:ss)", "Event Type", "Glucose Value (mg/dL)"
      int timestampIndex = headerRow.indexWhere((h) => h.toLowerCase().contains('timestamp'));
      
      // For Event Type - be specific to avoid matching "Event Subtype"
      int eventTypeIndex = headerRow.indexWhere((h) {
        final lower = h.toLowerCase();
        return lower == 'event type' || lower == 'event' || lower.startsWith('event type');
      });
      // Fallback: find first column containing just "event" (not subtype)
      if (eventTypeIndex == -1) {
        eventTypeIndex = headerRow.indexWhere((h) => h.toLowerCase().contains('event'));
      }
      
      // Prefer "Glucose Value" over just any "Glucose" match to avoid matching wrong columns
      int glucoseIndex = headerRow.indexWhere((h) => h.toLowerCase().contains('glucose value'));
      if (glucoseIndex == -1) {
        // Fallback to any column containing "glucose"
        glucoseIndex = headerRow.indexWhere((h) => h.toLowerCase().contains('glucose'));
      }

      if (timestampIndex == -1 || eventTypeIndex == -1 || glucoseIndex == -1) {
        debugPrint('Header Row: $headerRow');
        debugPrint('Indices: timestamp=$timestampIndex, event=$eventTypeIndex, glucose=$glucoseIndex');
        throw Exception('Could not map columns. Ensure headers contain Timestamp, Event Type, and Glucose Value.');
      }

      debugPrint('Mapped Indices -> Timestamp: $timestampIndex, Event: $eventTypeIndex, Glucose: $glucoseIndex');

      // 6. Determine Column Offset (Auto-Alignment)
      // Skip offset detection for Clarity exports - they don't have offset issues
      // Only look for offset if we find EGV rows with misaligned timestamps
      int offset = 0;
      
      // Find first EGV row to verify alignment
      for (int i = headerRowIndex + 1; i < csvData.length && i < headerRowIndex + 50; i++) {
        final row = csvData[i];
        if (row.isEmpty) continue;
        if (row.length <= eventTypeIndex) continue;
        
        // Look for an actual EGV row to test alignment
        final eventType = row[eventTypeIndex]?.toString().trim().toLowerCase() ?? '';
        if (eventType != 'egv') continue;
        
        // Found an EGV row, check if timestamp is valid at expected position
        if (row.length <= timestampIndex) continue;
        
        final checkTimestamp = row[timestampIndex]?.toString().trim() ?? '';
        if (DateTime.tryParse(checkTimestamp) != null) {
          offset = 0; // Alignment is correct
          debugPrint('Verified alignment with EGV row at index $i, offset=0');
          break;
        }
        
        // Try offset +1
        if (row.length > timestampIndex + 1) {
          final nextCheck = row[timestampIndex + 1]?.toString().trim() ?? '';
          if (DateTime.tryParse(nextCheck) != null) {
            offset = 1;
            debugPrint('Detected column offset of +1 from EGV row');
            break;
          }
        }
      }

      final List<GlucoseReading> readings = [];
      
      // 7. Process Data
      for (int i = headerRowIndex + 1; i < csvData.length; i++) {
        try {
          final row = csvData[i];
          if (row.isEmpty) continue;
          
          // Calculate required indices with offset
          final requiredEvtIdx = eventTypeIndex + offset;
          final requiredIdx = timestampIndex + offset;
          final requiredGluIdx = glucoseIndex + offset;

          // Safety check - ensure row has enough columns
          if (row.length <= requiredEvtIdx) continue;
          
          // Parse Event Type - only process EGV (Estimated Glucose Value) records
          final eventType = (row[requiredEvtIdx]?.toString().trim() ?? '');
          if (eventType.toLowerCase() != 'egv') {
            continue; 
          }

          // Now check remaining columns exist
          if (row.length <= requiredIdx || row.length <= requiredGluIdx) continue;

          // Parse Timestamp
          final timestampStr = (row[requiredIdx]?.toString().trim() ?? '');
          if (timestampStr.isEmpty) continue;

          final timestamp = DateTime.tryParse(timestampStr);
          if (timestamp == null) {
            debugPrint('Failed to parse timestamp: "$timestampStr" at row $i');
            continue;
          }

          // Parse Glucose
          final glucoseStr = (row[requiredGluIdx]?.toString().trim() ?? '');
          if (glucoseStr.isEmpty) continue;

          final glucoseValue = double.tryParse(glucoseStr);
          if (glucoseValue == null) {
            debugPrint('Failed to parse glucose: "$glucoseStr" at row $i');
            continue;
          }

          // Format Time
          final month = timestamp.month.toString().padLeft(2, '0');
          final day = timestamp.day.toString().padLeft(2, '0');
          final hour = timestamp.hour.toString().padLeft(2, '0');
          final minute = timestamp.minute.toString().padLeft(2, '0');
          
          final formattedTime = '$month-$day $hour:$minute';

          readings.add(GlucoseReading(
            time: formattedTime,
            value: glucoseValue,
          ));
        } catch (e) {
          debugPrint('Error processing row $i: $e');
          continue;
        }
      }

      readings.sort((a, b) => a.time.compareTo(b.time));

      debugPrint('Successfully parsed ${readings.length} glucose readings');
      
      if (readings.isEmpty) {
        throw Exception('No valid EGV glucose readings found. Check that your CSV contains EGV data rows.');
      }

      return readings;
    } catch (e) {
      debugPrint('CRITICAL ERROR: $e');
      throw Exception('Failed to parse CSV: $e');
    }
  }

  bool validateDexcomCsv(String csvContent) {
    // Basic validation - support both standard and Clarity formats
    final hasTimestamp = csvContent.contains('Timestamp');
    final hasGlucose = csvContent.contains('Glucose'); // Matches both "Glucose" and "Glucose Value"
    return hasTimestamp && hasGlucose;
  }

  Map<String, dynamic> getCsvStats(List<GlucoseReading> readings) {
    if (readings.isEmpty) {
      return {'count': 0, 'average': 0.0, 'min': 0.0, 'max': 0.0, 'timeInRange': 0};
    }

    final values = readings.map((r) => r.value).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final inRange = readings.where((r) => r.value >= 70 && r.value <= 180).length;
    final timeInRange = ((inRange / readings.length) * 100).round();

    return {
      'count': readings.length,
      'average': average,
      'min': min,
      'max': max,
      'timeInRange': timeInRange,
    };
  }
}
