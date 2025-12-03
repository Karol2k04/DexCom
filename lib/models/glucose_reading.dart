// Model reprezentujący pojedynczy odczyt glukozy
class GlucoseReading {
  final String time;
  final double value;
  final String? meal; // Opcjonalny typ posiłku

  GlucoseReading({required this.time, required this.value, this.meal});
}
