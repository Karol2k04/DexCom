// Model dla wpisu z CSV
class CsvDataEntry {
  final DateTime timestamp;
  final double? rawGlucoseValue;
  final double? calibrationValue;
  final double? insulinValue;
  final String? insulinType; // 'bolus' lub 'basal'

  CsvDataEntry({
    required this.timestamp,
    this.rawGlucoseValue,
    this.calibrationValue,
    this.insulinValue,
    this.insulinType,
  });

  factory CsvDataEntry.fromCsvRow(List<String> row) {
    // Format CSV: timestamp, glucose, calibration, insulin, insulin_type
    return CsvDataEntry(
      timestamp: DateTime.parse(row[0]),
      rawGlucoseValue: row.length > 1 && row[1].isNotEmpty
          ? double.tryParse(row[1])
          : null,
      calibrationValue: row.length > 2 && row[2].isNotEmpty
          ? double.tryParse(row[2])
          : null,
      insulinValue: row.length > 3 && row[3].isNotEmpty
          ? double.tryParse(row[3])
          : null,
      insulinType: row.length > 4 && row[4].isNotEmpty ? row[4] : null,
    );
  }

  // Convert to GlucoseReading for compatibility
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'rawGlucoseValue': rawGlucoseValue,
      'calibrationValue': calibrationValue,
      'insulinValue': insulinValue,
      'insulinType': insulinType,
    };
  }
}
