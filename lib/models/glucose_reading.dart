// Model reprezentujący pojedynczy odczyt glukozy
class GlucoseReading {
  final String time;
  final double value;
  final String? meal;
  final int timestamp; // milliseconds since epoch

  GlucoseReading({
    required this.time,
    required this.value,
    this.meal,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory GlucoseReading.fromDexcom(Map<String, dynamic> json) {
    final rawValue = json['Value'];
    if (rawValue == null) {
      throw Exception('Missing glucose value');
    }

    final DateTime? timestamp =
        _parseDexcomTimestamp(json['WT'] ?? json['DT']);

    if (timestamp == null) {
      throw Exception('Invalid Dexcom timestamp');
    }

    return GlucoseReading(
      time:
          '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
      value: double.tryParse(rawValue.toString()) ?? 0.0,
      timestamp: timestamp.millisecondsSinceEpoch,
    );
  }
}


DateTime? _parseDexcomTimestamp(dynamic raw) {
  if (raw == null) return null;

  final match = RegExp(r'(\d{10,})').firstMatch(raw.toString());
  if (match == null) return null;

  final millis = int.parse(match.group(1)!);
  return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
}