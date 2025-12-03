// Model reprezentujący wpis w historii
class HistoryEntry {
  final String id;
  final String time;
  final String date;
  final double glucose;
  final double? insulin;
  final String? meal;
  final int? carbs;
  final String? alert; // 'low' lub 'high'
  final String trend; // 'up', 'down', 'stable'

  HistoryEntry({
    required this.id,
    required this.time,
    required this.date,
    required this.glucose,
    this.insulin,
    this.meal,
    this.carbs,
    this.alert,
    required this.trend,
  });
}
