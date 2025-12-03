import 'package:flutter/material.dart';

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
    return _isDarkMode
        ? ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blue[400]!,
              secondary: Colors.green[400]!,
            ),
          )
        : ThemeData.light(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              secondary: Colors.green[600]!,
            ),
          );
  }
}
