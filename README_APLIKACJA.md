# GlucoTrack - Aplikacja do Monitorowania Glukozy

Aplikacja Flutter do monitorowania poziomu glukozy we krwi, która została przekonwertowana z React/TypeScript do Flutter/Dart.

## 🎯 Funkcje

### ✅ Już zaimplementowane:

1. **Login Page** - Strona logowania z:
   - Polami login i hasło
   - Przyciskiem "Login with Google"
   - Opcjami "Sign Up" i "Forgot Password"
   - Gradientowym tłem zielono-białym

2. **Dashboard** - Główny ekran z:
   - Aktualnym poziomem glukozy
   - Szybkimi statystykami (średnia 24h, TIR, epizody)
   - Wykresem liniowym poziomu glukozy (24h)
   - Oznaczeniami posiłków na wykresie
   - Liniami referencyjnymi dla zakresów

3. **Historia** - Ekran historii z:
   - Listą wszystkich pomiarów
   - Filtrami czasowymi (24h, 7dni, 14dni, 30dni)
   - Informacjami o posiłkach i insulinie
   - Wskaźnikami trendów (↑↓→)

4. **Statystyki** - Ekran analizy z:
   - Podsumowaniem tygodniowym
   - Wykresem słupkowym średnich dziennych
   - Kartami statystycznymi (TIR, dni w normie, średnia)

5. **Dodaj Posiłek** - Formularz z:
   - Wyborem typu posiłku (ikony)
   - Polem nazwy posiłku
   - Polem węglowodanów
   - Wyborem czasu
   - Animacją potwierdzenia

6. **Ustawienia** - Panel konfiguracji z:
   - Zakresem docelowym (suwaki)
   - Jednostkami (mg/dL / mmol/L)
   - Powiadomieniami (przełączniki)

7. **Bottom Navigation** - Dolna nawigacja z:
   - 5 zakładkami
   - Centralnym FAB (Floating Action Button)
   - Animacjami przejść

8. **Dark/Light Mode** - Przełącznik motywów

## 📁 Struktura Projektu

```
lib/
├── main.dart                      # Punkt wejścia + Login Page
├── models/                        # Modele danych
│   ├── glucose_reading.dart
│   └── history_entry.dart
├── providers/                     # Zarządzanie stanem
│   └── theme_provider.dart
├── screens/                       # Ekrany aplikacji
│   ├── dashboard_screen.dart
│   ├── history_screen.dart
│   ├── statistics_screen.dart
│   ├── add_meal_screen.dart
│   ├── settings_screen.dart
│   └── home_screen.dart          # Główny ekran z navigation
└── widgets/                       # Reużywalne komponenty (puste na razie)
```

## 🚀 Jak uruchomić

1. **Upewnij się, że masz zainstalowany Flutter**
   ```bash
   flutter doctor
   ```

2. **Pobierz zależności** (już wykonane)
   ```bash
   flutter pub get
   ```

3. **Uruchom aplikację**
   ```bash
   flutter run
   ```

4. **Lub uruchom na konkretnym urządzeniu**
   ```bash
   flutter run -d chrome        # Web
   flutter run -d windows       # Windows
   flutter run -d <device-id>   # Android/iOS
   ```

## 📦 Zależności

- `fl_chart: ^0.69.0` - Wykresy i wizualizacje
- `provider: ^6.1.2` - Zarządzanie stanem
- `font_awesome_flutter: ^10.7.0` - Ikony
- `go_router: ^14.6.2` - Routing
- `intl: ^0.19.0` - Formatowanie dat i liczb

## 🎨 Zmiany z React na Flutter

| React/TypeScript | Flutter/Dart |
|-----------------|--------------|
| `useState` | `StatefulWidget` + `setState` |
| `recharts` | `fl_chart` |
| `lucide-react` | `Icons` (Material) + `font_awesome_flutter` |
| Tailwind CSS | `BoxDecoration`, `Container`, `Card` |
| `motion/react` | Wbudowane animacje Flutter |
| CSS Gradient | `LinearGradient` |
| `onClick` | `onTap` / `onPressed` |

## 🔄 Nawigacja

- **Login** → Po zalogowaniu → **Home Screen**
- **Home Screen** zawiera:
  - Tab 0: Dashboard
  - Tab 1: Historia
  - Tab 2: Dodaj Posiłek (FAB)
  - Tab 3: Statystyki
  - Tab 4: Ustawienia

## 💡 Dalszy rozwój

Możesz rozbudować aplikację o:
- [ ] Integrację z Firebase (autentykacja, baza danych)
- [ ] Lokalne przechowywanie danych (SQLite, Hive)
- [ ] Synchronizację z urządzeniami do pomiaru glukozy
- [ ] Eksport danych do PDF
- [ ] Powiadomienia push
- [ ] Wielojęzyczność (i18n)
- [ ] Testy jednostkowe i widgetowe

## 📱 Obsługiwane platformy

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

---

**Uwaga:** Dane w aplikacji są obecnie mock'owane (testowe). Aby aplikacja działała z prawdziwymi danymi, należy podłączyć backend lub bazę danych.
