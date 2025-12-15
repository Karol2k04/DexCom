import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/glucose_reading.dart';

class DexcomService {
  // Your backend base URL (ngrok or deployed server)
  static const String _backendBase = 'https://whackier-deshawn-untruthful.ngrok-free.dev';

  Future<void> connect(String userId) async {
    final uri = Uri.parse('$_backendBase/dexcom/login?userId=$userId');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch Dexcom login URL');
    }
  }

  Future<bool> isConnected(String userId) async {
    final uri = Uri.parse('$_backendBase/dexcom/status?userId=$userId');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) return false;
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return json['connected'] == true;
  }

  Future<List<GlucoseReading>> fetchRecentGlucose(String userId,
      {int hours = 3}) async {
    final uri = Uri.parse(
        '$_backendBase/dexcom/egvs?userId=$userId&hours=$hours');
    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('Dexcom backend error: ${resp.statusCode} ${resp.body}');
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final egvs = (decoded['egvs'] as List<dynamic>? ?? []);

    return egvs.map((e) {
      final map = e as Map<String, dynamic>;
      final value = (map['value'] as num).toDouble();
      final displayTime = (map['displayTime'] ?? map['systemTime']) as String;
      final dt = DateTime.tryParse(displayTime);
      final timeLabel = dt != null
          ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
          : '';

      return GlucoseReading(time: timeLabel, value: value, meal: null);
    }).toList();
  }
}
