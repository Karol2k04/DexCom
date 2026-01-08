import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Provider zarządzający motywem aplikacji (jasny/ciemny)
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  // Przełącznik między trybem jasnym a ciemnym
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Zwraca odpowiedni ThemeData w zależności od trybu
  ThemeData get themeData {
    return _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
  }
}
