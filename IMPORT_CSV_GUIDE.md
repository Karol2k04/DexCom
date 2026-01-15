# 📊 CSV Import Guide

## Format pliku CSV

Aplikacja akceptuje pliki CSV w następującym formacie:

### Wymagane kolumny:
1. **Timestamp** - Data i czas odczytu (format: YYYY-MM-DDTHH:MM:SS)
2. **Event Type** - Typ zdarzenia (wartość: EGV)
3. **Glucose Value (mg/dL)** - Wartość glukozy w mg/dL

### Przykładowy format:

```csv
Timestamp (YYYY-MM-DDThh:mm:ss),Event Type,Glucose Value (mg/dL)
2026-01-14T08:00:00,EGV,112
2026-01-14T08:05:00,EGV,115
2026-01-14T08:10:00,EGV,118
2026-01-14T08:15:00,EGV,120
2026-01-14T08:20:00,EGV,122
```

### Obsługiwane separatory:
- Przecinek (`,`) - domyślny
- Tabulator (`\t`)
- Pionowa kreska (`|`)

## Jak zaimportować dane?

1. **Z Dashboard Screen:**
   - Kliknij przycisk "Import CSV" (jeśli nie masz połączenia z Dexcom)
   - LUB przejdź do ekranu importu ręcznie

2. **Wybierz plik CSV:**
   - Wybierz plik CSV zawierający dane glukozy
   - Format musi zawierać kolumny wymienione powyżej

3. **Po imporcie:**
   - Dane zostaną automatycznie wyświetlone w aplikacji
   - **Statistics Screen** pokaże:
     - Średnią wartość glukozy (Average Glucose)
     - Czas w zakresie docelowym (Avg TIR)
     - Liczbę dni w zakresie
     - Wykres dzienny ze średnimi wartościami
   - **History Screen** pokaże:
     - Wpisy z godziną importu
     - Wartości glukozy z pliku CSV
     - Trend (góra/dół/stabilny)

## Co się dzieje z danymi?

### Statistics Screen:
- **Average Glucose**: Oblicza średnią ze wszystkich odczytów glukozy
- **Avg TIR** (Time In Range): Procent odczytów w zakresie 70-180 mg/dL
- **Days in Range**: Liczba dni, w których TIR był >= 70%
- **Wykres**: Pokazuje średnie dzienne wartości glukozy z ostatnich 7 dni

### History Screen:
- Każdy odczyt z CSV staje się wpisem w historii
- Godzina importu jest zapisywana przy każdym wpisie
- Wartość glukozy jest wyświetlana z odpowiednim kolorem:
  - 🔴 Czerwony: < 70 mg/dL (niska)
  - 🟢 Zielony: 70-140 mg/dL (w zakresie)
  - 🟠 Pomarańczowy: > 140 mg/dL (wysoka)

### Dashboard Screen:
- Pokazuje aktualną wartość glukozy
- Wyświetla średnią i TIR ze wszystkich danych
- Trend glukozy (stabilny/rosnący/spadający)
- Wykres z ostatnich odczytów

## Przyszłe funkcje

W przyszłości dane z CSV będą:
- Zapisywane w Firestore
- Synchronizowane między urządzeniami
- Dostępne po wylogowaniu i ponownym zalogowaniu
- Możliwe do wyeksportowania

## Dodatkowe pola (planowane)

W przyszłości CSV będzie obsługiwać również:
- **Calibration Values** - dane kalibracyjne
- **Insulin Values** - dawki insuliny
- **Meal Data** - informacje o posiłkach
- **Carbs** - węglowodany

## Wsparcie

Format CSV jest kompatybilny z eksportem Dexcom Clarity.
Jeśli masz problemy z importem, sprawdź czy:
1. Plik zawiera wymagane kolumny
2. Format daty jest poprawny (YYYY-MM-DDTHH:MM:SS)
3. Wartości glukozy są liczbami
4. Event Type = "EGV" dla odczytów glukozy
