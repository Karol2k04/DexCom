import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';

class SettingsProvider with ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  bool _includeHealthGlucose = false;
  bool get includeHealthGlucose => _includeHealthGlucose;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Attempt to read from Firestore user doc settings
      final settings = await _firestore.getUserSettings();
      if (settings != null && settings.containsKey('includeHealthGlucose')) {
        _includeHealthGlucose = settings['includeHealthGlucose'] as bool;
      } else {
        _includeHealthGlucose = false;
      }
      notifyListeners();
    } catch (e) {
      // ignore errors; default to false
      _includeHealthGlucose = false;
      notifyListeners();
    }
  }

  Future<void> setIncludeHealthGlucose(bool value) async {
    _includeHealthGlucose = value;
    notifyListeners();

    try {
      await _firestore.updateUserSetting('includeHealthGlucose', value);
    } catch (e) {
      // ignore errors for now
    }
  }
}
