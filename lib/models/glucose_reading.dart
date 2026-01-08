// Model reprezentujący pojedynczy odczyt glukozy
class GlucoseReading {
  final String time;
  final double value;
  final String? meal;

  GlucoseReading({required this.time, required this.value, this.meal});

  // Factory constructor to parse from Dexcom API response
  factory GlucoseReading.fromDexcom(Map<String, dynamic> json) {
    // The API usually returns 'Value' as a string or int, and 'DT' as a date string
    final rawValue = json['Value'] ?? 0;
    final DateTime timestamp = DateTime.parse(json['DT'].toString().replaceAll('/Date(', '').replaceAll(')/', ''));

    return GlucoseReading(
      time: '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
      value: double.tryParse(rawValue.toString()) ?? 0.0,
    );
  }
}
